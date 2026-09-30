import crypto from "node:crypto";
import { fileURLToPath } from "node:url";
import express from "express";
import pg from "pg";
import {
	boundedInteger, isUuid, jsonByteLength, validDisplayName, validRoute, validTelemetryEvent,
} from "./validation.js";
import { migrate } from "./migrate.js";

const MAX_SAVE_BYTES = 64 * 1024;
const MAX_SCORE = 2_000_000;
const MIN_MEANINGFUL_DISTANCE = 300;
const MIN_MEANINGFUL_DURATION = 25;
const TRANSFER_TTL_SECONDS = 15 * 60;
const FRIEND_INVITE_TTL_SECONDS = 24 * 60 * 60;
const MAX_TELEMETRY_EVENTS_PER_REQUEST = 25;
const MAX_TELEMETRY_AGE_SECONDS = 14 * 24 * 60 * 60;

function fixedWindowRateLimit(pool, { windowMs, max, key, scope, error = "rate_limited" }) {
	let lastCleanup = 0;
	const hashSecret = process.env.RATE_LIMIT_HASH_KEY || process.env.DATABASE_URL || "local-development-only";
	return async (req, res, next) => {
		const now = Date.now();
		const windowStartedAt = Math.floor(now / windowMs) * windowMs;
		const subject = String(key(req) || "unknown");
		const subjectHash = crypto.createHmac("sha256", hashSecret).update(`${scope}:${subject}`).digest("hex");
		try {
			const countResult = await pool.query(
				`INSERT INTO api_rate_limits (scope, subject_hash, window_started_at, request_count, expires_at)
				 VALUES ($1, $2, to_timestamp($3::double precision / 1000.0), 1,
				         to_timestamp(($3::double precision + $4::double precision) / 1000.0))
				 ON CONFLICT (scope, subject_hash, window_started_at)
				 DO UPDATE SET request_count = LEAST(api_rate_limits.request_count + 1, $5)
				 RETURNING request_count`,
				[scope, subjectHash, windowStartedAt, windowMs, max + 1],
			);
			if (!Number.isSafeInteger(Number(countResult.rows[0]?.request_count))) {
				throw new Error("rate_limit_counter_missing");
			}
			if (now - lastCleanup >= 60_000) {
				lastCleanup = now;
				void pool.query("DELETE FROM api_rate_limits WHERE expires_at <= NOW()").catch(() => {});
			}
			if (Number(countResult.rows[0]?.request_count || 0) > max) {
				const retryAfterSeconds = Math.max(1, Math.ceil((windowStartedAt + windowMs - now) / 1000));
				res.set("Retry-After", String(retryAfterSeconds));
				return res.status(429).json({ error, retryAfterSeconds });
			}
			return next();
		} catch {
			return problem(res, 503, "rate_limit_unavailable");
		}
	};
}

function problem(res, status, code) {
  return res.status(status).json({ error: code });
}

function tokenHash(token) {
  return crypto.createHash("sha256").update(token).digest("hex");
}

function newInviteCode() {
	return crypto.randomBytes(9).toString("base64url").toUpperCase();
}

function newTransferCode() {
	return `DDR-T-${crypto.randomBytes(9).toString("base64url").toUpperCase()}`;
}

function newFriendCode() {
	return `DDR-F-${crypto.randomBytes(9).toString("base64url").toUpperCase()}`;
}

function friendshipPair(firstId, secondId) {
	return firstId < secondId ? [firstId, secondId] : [secondId, firstId];
}

function sanitizeTelemetryProperties(value) {
	if (!value || typeof value !== "object" || Array.isArray(value)) return null;
	const clean = {};
	for (const [rawKey, rawValue] of Object.entries(value)) {
		const key = String(rawKey).toLowerCase();
		if (!/^[a-z0-9_]{1,32}$/.test(key) || key.includes("name") || key.includes("code")
			|| key.includes("token") || key.includes("id")) continue;
		if (typeof rawValue === "boolean" || (typeof rawValue === "number" && Number.isFinite(rawValue))) {
			clean[key] = rawValue;
		} else if (typeof rawValue === "string" && rawValue.length <= 64) {
			clean[key] = rawValue;
		}
	}
	return clean;
}

export function createApp(pool) {
  const app = express();
  app.disable("x-powered-by");
  app.set("trust proxy", 1);
  app.use(express.json({ limit: "96kb" }));
	const limitInstallations = fixedWindowRateLimit(pool, {
		windowMs: 60 * 60 * 1000, max: 20, key: (req) => req.ip, scope: "installations", error: "registration_rate_limited",
	});
	const limitWorldReads = fixedWindowRateLimit(pool, {
		windowMs: 60 * 1000, max: 90, key: (req) => req.ip, scope: "world_reads",
	});
	const limitScoreSubmissions = fixedWindowRateLimit(pool, {
		windowMs: 5 * 60 * 1000, max: 8, key: (req) => req.installationId, scope: "score_submissions",
	});
	const limitProfileChanges = fixedWindowRateLimit(pool, {
		windowMs: 60 * 60 * 1000, max: 8, key: (req) => req.installationId, scope: "profile_changes",
	});

  app.get("/health", async (_req, res) => {
    try {
      await pool.query("SELECT 1");
      res.json({ ok: true });
    } catch {
      problem(res, 503, "database_unavailable");
    }
  });

  async function requireInstallation(req, res, next) {
    const installationId = String(req.get("X-Installation-Id") || "");
    const syncToken = String(req.get("X-Sync-Token") || "");
    if (!isUuid(installationId) || syncToken.length < 32 || syncToken.length > 128) {
      return problem(res, 401, "unauthorized");
    }
    try {
      const result = await pool.query(
        "UPDATE installations SET last_seen_at = NOW() WHERE id = $1 AND sync_token_hash = $2 RETURNING id",
        [installationId, tokenHash(syncToken)],
      );
      if (result.rowCount !== 1) return problem(res, 401, "unauthorized");
      req.installationId = installationId;
      return next();
    } catch {
      return problem(res, 503, "database_unavailable");
    }
  }

  app.post("/v1/installations", limitInstallations, async (_req, res) => {
    const installationId = crypto.randomUUID();
    const syncToken = crypto.randomBytes(32).toString("base64url");
    try {
      await pool.query(
        "INSERT INTO installations (id, sync_token_hash) VALUES ($1, $2)",
        [installationId, tokenHash(syncToken)],
      );
      res.status(201).json({ installationId, syncToken });
    } catch {
      problem(res, 503, "database_unavailable");
    }
  });

  app.get("/v1/cloud-save", requireInstallation, async (req, res) => {
    try {
      const result = await pool.query(
        "SELECT revision, save_data, updated_at FROM cloud_saves WHERE installation_id = $1",
        [req.installationId],
      );
      if (result.rowCount === 0) return res.status(404).json({ error: "not_found" });
      const row = result.rows[0];
      return res.json({ revision: Number(row.revision), save: row.save_data, updatedAt: row.updated_at });
    } catch {
      return problem(res, 503, "database_unavailable");
    }
  });

	app.post("/v1/cloud-save", requireInstallation, async (req, res) => {
    const { revision, save } = req.body || {};
    if (!boundedInteger(revision, 0, 2_147_483_647) || !save || typeof save !== "object" || Array.isArray(save)) {
      return problem(res, 400, "invalid_save");
    }
    if (jsonByteLength(save) > MAX_SAVE_BYTES) return problem(res, 413, "save_too_large");
    try {
      const result = await pool.query(
        `INSERT INTO cloud_saves (installation_id, revision, save_data)
         VALUES ($1, $2, $3::jsonb)
         ON CONFLICT (installation_id) DO UPDATE SET revision = EXCLUDED.revision,
           save_data = EXCLUDED.save_data, updated_at = NOW()
         WHERE EXCLUDED.revision > cloud_saves.revision
         RETURNING revision`,
        [req.installationId, revision, JSON.stringify(save)],
      );
      if (result.rowCount === 0) return res.status(409).json({ error: "stale_revision" });
      return res.json({ revision: Number(result.rows[0].revision) });
    } catch {
      return problem(res, 503, "database_unavailable");
    }
	});

	app.delete("/v1/account", requireInstallation, async (req, res) => {
		try {
			await pool.query("DELETE FROM installations WHERE id = $1", [req.installationId]);
			return res.json({ deleted: true });
		} catch {
			return problem(res, 503, "database_unavailable");
		}
	});

	app.post("/v1/account/transfer-code", requireInstallation, async (req, res) => {
		try {
			await pool.query("DELETE FROM account_transfers WHERE expires_at <= NOW() OR claimed_at IS NOT NULL");
			for (let attempt = 0; attempt < 4; attempt += 1) {
				const transferCode = newTransferCode();
				try {
					await pool.query(
						`INSERT INTO account_transfers (code_hash, installation_id, expires_at)
						 VALUES ($1, $2, NOW() + INTERVAL '15 minutes')`,
						[tokenHash(transferCode), req.installationId],
					);
					return res.status(201).json({ transferCode, expiresInSeconds: TRANSFER_TTL_SECONDS });
				} catch (error) {
					if (error.code !== "23505") throw error;
				}
			}
			return problem(res, 503, "transfer_unavailable");
		} catch {
			return problem(res, 503, "database_unavailable");
		}
	});

	app.post("/v1/account/claim-transfer", async (req, res) => {
		const transferCode = String(req.body?.transferCode || "").trim().toUpperCase();
		if (!/^DDR-T-[A-Z0-9_-]{8,32}$/.test(transferCode)) return problem(res, 400, "invalid_transfer");
		let client;
		let transactionStarted = false;
		try {
			client = await pool.connect();
			await client.query("BEGIN");
			transactionStarted = true;
			const transfer = await client.query(
				`SELECT installation_id FROM account_transfers
				 WHERE code_hash = $1 AND claimed_at IS NULL AND expires_at > NOW() FOR UPDATE`,
				[tokenHash(transferCode)],
			);
			if (transfer.rowCount !== 1) {
				await client.query("ROLLBACK");
				transactionStarted = false;
				return problem(res, 404, "transfer_not_found");
			}
			const installationId = transfer.rows[0].installation_id;
			const syncToken = crypto.randomBytes(32).toString("base64url");
			await client.query(
				"UPDATE installations SET sync_token_hash = $1, last_seen_at = NOW() WHERE id = $2",
				[tokenHash(syncToken), installationId],
			);
			await client.query(
				"UPDATE account_transfers SET claimed_at = NOW() WHERE code_hash = $1",
				[tokenHash(transferCode)],
			);
			await client.query("COMMIT");
			transactionStarted = false;
			return res.json({ installationId, syncToken });
		} catch {
			if (client != null && transactionStarted) {
				await client.query("ROLLBACK");
			}
			return problem(res, 503, "database_unavailable");
		} finally {
			if (client != null) {
				client.release();
			}
		}
	});

	app.put("/v1/leaderboard-profile", requireInstallation, limitProfileChanges, async (req, res) => {
		const displayName = String(req.body?.displayName || "").trim();
		if (!validDisplayName(displayName)) return problem(res, 400, "invalid_display_name");
		try {
			await pool.query(
				`INSERT INTO leaderboard_profiles (installation_id, display_name)
				 VALUES ($1, $2)
				 ON CONFLICT (installation_id) DO UPDATE SET display_name = EXCLUDED.display_name,
				 updated_at = NOW()`,
				[req.installationId, displayName],
			);
			return res.json({ displayName });
		} catch {
			return problem(res, 503, "database_unavailable");
		}
	});

	// Leaving public competition is deliberately narrower than deleting the
	// complete cloud account: it removes public scores, profile, friend links,
	// and outstanding friend codes while keeping an opted-in backup intact.
	app.delete("/v1/leaderboard-profile", requireInstallation, async (req, res) => {
		let client;
		let transactionStarted = false;
		try {
			client = await pool.connect();
			await client.query("BEGIN");
			transactionStarted = true;
			await client.query("DELETE FROM leaderboard_scores WHERE installation_id = $1", [req.installationId]);
			await client.query("DELETE FROM leaderboard_friend_invites WHERE owner_installation_id = $1 OR claimed_by_installation_id = $1", [req.installationId]);
			await client.query("DELETE FROM leaderboard_friendships WHERE first_installation_id = $1 OR second_installation_id = $1", [req.installationId]);
			await client.query("DELETE FROM leaderboard_profiles WHERE installation_id = $1", [req.installationId]);
			await client.query("COMMIT");
			transactionStarted = false;
			return res.json({ deleted: true });
		} catch {
			if (client != null && transactionStarted) await client.query("ROLLBACK");
			return problem(res, 503, "database_unavailable");
		} finally {
			if (client != null) client.release();
		}
	});

	app.post("/v1/leaderboards/unverified", requireInstallation, limitScoreSubmissions, async (req, res) => {
    const { routeId, score } = req.body || {};
		const displayName = String(req.body?.displayName || "").trim();
		if (!validDisplayName(displayName)) return problem(res, 400, "invalid_display_name");
		if (!validRoute(routeId) || !boundedInteger(score, 0, MAX_SCORE)) return problem(res, 400, "invalid_score");
    try {
			await pool.query(
				`INSERT INTO leaderboard_profiles (installation_id, display_name)
				 VALUES ($1, $2)
				 ON CONFLICT (installation_id) DO UPDATE SET display_name = EXCLUDED.display_name,
				 updated_at = NOW()`,
				[req.installationId, displayName],
			);
		const scoreResult = await pool.query(
			`INSERT INTO leaderboard_scores (installation_id, route_id, score)
			 VALUES ($1, $2, $3)
			 ON CONFLICT (installation_id, route_id) DO UPDATE
			 SET score = EXCLUDED.score, created_at = NOW()
			 WHERE EXCLUDED.score > leaderboard_scores.score
			 RETURNING score`,
			[req.installationId, routeId, score],
		);
		return res.status(200).json({ accepted: scoreResult.rowCount === 1, verification: "unverified" });
    } catch {
      return problem(res, 503, "database_unavailable");
    }
  });

	app.get("/v1/leaderboards/unverified/:routeId", limitWorldReads, async (req, res) => {
    if (!validRoute(req.params.routeId)) return problem(res, 400, "invalid_route");
    try {
      const result = await pool.query(
        `WITH best_scores AS (
           SELECT DISTINCT ON (score.installation_id)
             score.installation_id, score.score, score.created_at
           FROM leaderboard_scores AS score
           INNER JOIN leaderboard_profiles AS profile
             ON profile.installation_id = score.installation_id
           WHERE score.route_id = $1
           ORDER BY score.installation_id, score.score DESC, score.created_at ASC
         )
         SELECT best_scores.score, best_scores.created_at, profile.display_name
         FROM best_scores
         INNER JOIN leaderboard_profiles AS profile
           ON profile.installation_id = best_scores.installation_id
         ORDER BY best_scores.score DESC, best_scores.created_at ASC LIMIT 25`,
        [req.params.routeId],
      );
      return res.json({ verification: "unverified", scores: result.rows.map((row, index) => ({
        rank: index + 1, displayName: row.display_name, score: row.score, submittedAt: row.created_at,
      })) });
    } catch {
      return problem(res, 503, "database_unavailable");
    }
  });

	app.post("/v1/leaderboards/friends/invite", requireInstallation, async (req, res) => {
		try {
			await pool.query(
				"DELETE FROM leaderboard_friend_invites WHERE expires_at <= NOW() OR claimed_at IS NOT NULL OR owner_installation_id = $1",
				[req.installationId],
			);
			for (let attempt = 0; attempt < 4; attempt += 1) {
				const inviteCode = newFriendCode();
				try {
					await pool.query(
						`INSERT INTO leaderboard_friend_invites (code_hash, owner_installation_id, expires_at)
						 VALUES ($1, $2, NOW() + INTERVAL '24 hours')`,
						[tokenHash(inviteCode), req.installationId],
					);
					return res.status(201).json({ inviteCode, expiresInSeconds: FRIEND_INVITE_TTL_SECONDS });
				} catch (error) {
					if (error.code !== "23505") throw error;
				}
			}
			return problem(res, 503, "friend_invite_unavailable");
		} catch {
			return problem(res, 503, "database_unavailable");
		}
	});

	app.post("/v1/leaderboards/friends/claim", requireInstallation, async (req, res) => {
		const inviteCode = String(req.body?.inviteCode || "").trim().toUpperCase();
		if (!/^DDR-F-[A-Z0-9_-]{8,32}$/.test(inviteCode)) return problem(res, 400, "invalid_invite");
		let client;
		let transactionStarted = false;
		try {
			client = await pool.connect();
			await client.query("BEGIN");
			transactionStarted = true;
			const invite = await client.query(
				`SELECT owner_installation_id FROM leaderboard_friend_invites
				 WHERE code_hash = $1 AND claimed_at IS NULL AND expires_at > NOW() FOR UPDATE`,
				[tokenHash(inviteCode)],
			);
			if (invite.rowCount !== 1) {
				await client.query("ROLLBACK");
				transactionStarted = false;
				return problem(res, 404, "friend_invite_not_found");
			}
			const ownerId = invite.rows[0].owner_installation_id;
			if (ownerId === req.installationId) {
				await client.query("ROLLBACK");
				transactionStarted = false;
				return problem(res, 400, "self_friend");
			}
			const [firstId, secondId] = friendshipPair(ownerId, req.installationId);
			const friendship = await client.query(
				`INSERT INTO leaderboard_friendships (first_installation_id, second_installation_id)
				 VALUES ($1, $2) ON CONFLICT DO NOTHING`, [firstId, secondId],
			);
			await client.query(
				"UPDATE leaderboard_friend_invites SET claimed_at = NOW(), claimed_by_installation_id = $1 WHERE code_hash = $2",
				[req.installationId, tokenHash(inviteCode)],
			);
			await client.query("COMMIT");
			transactionStarted = false;
			return res.status(201).json({ added: friendship.rowCount === 1 });
		} catch {
			if (client != null && transactionStarted) await client.query("ROLLBACK");
			return problem(res, 503, "database_unavailable");
		} finally {
			if (client != null) client.release();
		}
	});

	app.get("/v1/leaderboards/friends", requireInstallation, async (req, res) => {
		try {
			const result = await pool.query(
				`SELECT CASE WHEN friendship.first_installation_id = $1
					THEN friendship.second_installation_id ELSE friendship.first_installation_id END AS installation_id,
					profile.display_name, friendship.created_at
				FROM leaderboard_friendships AS friendship
				INNER JOIN leaderboard_profiles AS profile ON profile.installation_id =
					CASE WHEN friendship.first_installation_id = $1
					THEN friendship.second_installation_id ELSE friendship.first_installation_id END
				WHERE friendship.first_installation_id = $1 OR friendship.second_installation_id = $1
				ORDER BY profile.display_name ASC LIMIT 100`,
				[req.installationId],
			);
			return res.json({ friends: result.rows.map((row) => ({
				friendId: row.installation_id, displayName: row.display_name, addedAt: row.created_at,
			})) });
		} catch {
			return problem(res, 503, "database_unavailable");
		}
	});

	app.delete("/v1/leaderboards/friends/:friendId", requireInstallation, async (req, res) => {
		if (!isUuid(req.params.friendId) || req.params.friendId === req.installationId) {
			return problem(res, 400, "invalid_friend");
		}
		const [firstId, secondId] = friendshipPair(req.installationId, req.params.friendId);
		try {
			const result = await pool.query(
				"DELETE FROM leaderboard_friendships WHERE first_installation_id = $1 AND second_installation_id = $2",
				[firstId, secondId],
			);
			return res.json({ removed: result.rowCount === 1 });
		} catch {
			return problem(res, 503, "database_unavailable");
		}
	});

	app.get("/v1/leaderboards/friends/:routeId", requireInstallation, async (req, res) => {
		if (!validRoute(req.params.routeId)) return problem(res, 400, "invalid_route");
		try {
			const result = await pool.query(
				`WITH rivals AS (
					SELECT $1::uuid AS installation_id
					UNION
					SELECT CASE WHEN first_installation_id = $1 THEN second_installation_id ELSE first_installation_id END
					FROM leaderboard_friendships
					WHERE first_installation_id = $1 OR second_installation_id = $1
				), best_scores AS (
					SELECT DISTINCT ON (score.installation_id)
						score.installation_id, score.score, score.created_at
					FROM leaderboard_scores AS score
					INNER JOIN rivals ON rivals.installation_id = score.installation_id
					WHERE score.route_id = $2
					ORDER BY score.installation_id, score.score DESC, score.created_at ASC
				)
				SELECT best_scores.installation_id, best_scores.score, best_scores.created_at, profile.display_name
				FROM best_scores INNER JOIN leaderboard_profiles AS profile
					ON profile.installation_id = best_scores.installation_id
				ORDER BY best_scores.score DESC, best_scores.created_at ASC LIMIT 25`,
				[req.installationId, req.params.routeId],
			);
			return res.json({ verification: "unverified", scores: result.rows.map((row, index) => ({
				rank: index + 1,
				displayName: row.display_name,
				score: row.score,
				isYou: row.installation_id === req.installationId,
			})) });
		} catch {
			return problem(res, 503, "database_unavailable");
		}
	});

	app.post("/v1/telemetry", requireInstallation, async (req, res) => {
		const events = req.body?.events;
		if (!Array.isArray(events) || events.length < 1 || events.length > MAX_TELEMETRY_EVENTS_PER_REQUEST) {
			return problem(res, 400, "invalid_events");
		}
		const nowSeconds = Math.floor(Date.now() / 1000);
		const rows = [];
		for (const event of events) {
			if (!event || typeof event !== "object" || Array.isArray(event)) return problem(res, 400, "invalid_event");
			const name = event.e;
			const occurredAt = event.t;
			const properties = sanitizeTelemetryProperties(event.p || {});
			const routeId = typeof properties.route === "string" && validRoute(properties.route) ? properties.route : null;
			if (!validTelemetryEvent(name) || !boundedInteger(occurredAt, nowSeconds - MAX_TELEMETRY_AGE_SECONDS, nowSeconds + 300)
				|| properties == null || jsonByteLength(properties) > 2048) {
				return problem(res, 400, "invalid_event");
			}
			rows.push([req.installationId, name, routeId, JSON.stringify(properties), new Date(occurredAt * 1000)]);
		}
		try {
			for (const row of rows) {
				await pool.query(
					`INSERT INTO telemetry_events (installation_id, event_name, route_id, properties, occurred_at)
					 VALUES ($1, $2, $3, $4::jsonb, $5)`, row,
				);
			}
			return res.status(201).json({ accepted: rows.length });
		} catch {
			return problem(res, 503, "database_unavailable");
		}
	});

  app.post("/v1/runs/meaningful", requireInstallation, async (req, res) => {
    const { routeId, distance, durationSeconds } = req.body || {};
    if (!validRoute(routeId) || !boundedInteger(distance, 0, 100_000)
      || !boundedInteger(durationSeconds, 0, 7_200)) return problem(res, 400, "invalid_run");
    if (distance < MIN_MEANINGFUL_DISTANCE || durationSeconds < MIN_MEANINGFUL_DURATION) {
      return problem(res, 400, "run_not_qualified");
    }
    try {
      await pool.query(
        `INSERT INTO meaningful_runs (installation_id, route_id, distance, duration_seconds)
         VALUES ($1, $2, $3, $4)
         ON CONFLICT (installation_id) DO NOTHING`,
        [req.installationId, routeId, distance, durationSeconds],
      );
      return res.json({ qualified: true });
    } catch {
      return problem(res, 503, "database_unavailable");
    }
  });

  app.post("/v1/referrals/invites", requireInstallation, async (req, res) => {
    try {
      let code = newInviteCode();
      for (let attempt = 0; attempt < 4; attempt += 1) {
        try {
          await pool.query(
            "INSERT INTO referral_invites (code, owner_installation_id) VALUES ($1, $2)",
            [code, req.installationId],
          );
          return res.status(201).json({ inviteCode: code });
        } catch (error) {
          if (error.code !== "23505") throw error;
          code = newInviteCode();
        }
      }
      return problem(res, 503, "invite_unavailable");
    } catch {
      return problem(res, 503, "database_unavailable");
    }
  });

  app.post("/v1/referrals/activate", requireInstallation, async (req, res) => {
    const inviteCode = String(req.body?.inviteCode || "").trim().toUpperCase();
    if (!/^[A-Z0-9_-]{8,32}$/.test(inviteCode)) return problem(res, 400, "invalid_invite");
    try {
      const qualified = await pool.query(
        "SELECT 1 FROM meaningful_runs WHERE installation_id = $1",
        [req.installationId],
      );
      if (qualified.rowCount !== 1) return problem(res, 409, "meaningful_run_required");
      const invite = await pool.query(
        "SELECT owner_installation_id FROM referral_invites WHERE code = $1 AND disabled_at IS NULL",
        [inviteCode],
      );
      if (invite.rowCount !== 1) return problem(res, 404, "invite_not_found");
      const inviterId = invite.rows[0].owner_installation_id;
      if (inviterId === req.installationId) return problem(res, 400, "self_referral");
      await pool.query(
        `INSERT INTO referral_activations (invite_code, inviter_installation_id, invitee_installation_id)
         VALUES ($1, $2, $3)`,
        [inviteCode, inviterId, req.installationId],
      );
      return res.status(201).json({ status: "activated", reward: "pending_review" });
    } catch (error) {
      if (error.code === "23505") return problem(res, 409, "already_activated");
      return problem(res, 503, "database_unavailable");
    }
  });

  return app;
}

async function start() {
	if (!process.env.DATABASE_URL) throw new Error("DATABASE_URL is required.");
	const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });
	if (process.env.RUN_MIGRATIONS_ON_START === "true") {
		await migrate(pool);
		console.log("Database migration completed during deployment bootstrap.");
	}
	const app = createApp(pool);
  const port = Number.parseInt(process.env.PORT || "3000", 10);
  const server = app.listen(port, "0.0.0.0", () => console.log(`Dala Dala Rush service on ${port}`));
  const close = async () => { server.close(); await pool.end(); };
  process.once("SIGINT", close);
  process.once("SIGTERM", close);
}

if (process.argv[1] === fileURLToPath(import.meta.url)) start();
