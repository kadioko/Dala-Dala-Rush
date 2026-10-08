import test from "node:test";
import assert from "node:assert/strict";
import { once } from "node:events";
import { createApp } from "../src/server.js";

const INSTALLATION_ID = "f47ac10b-58cc-4372-a567-0e02b2c3d479";
const HEADERS = {
	"Content-Type": "application/json",
	"X-Installation-Id": INSTALLATION_ID,
	"X-Sync-Token": "a".repeat(32),
};

async function withServer(pool, run) {
	const server = createApp(pool).listen(0, "127.0.0.1");
	await once(server, "listening");
	try {
		await run(`http://127.0.0.1:${server.address().port}`);
	} finally {
		server.closeAllConnections();
		await new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
	}
}

function leaderboardPool() {
	const scores = new Map();
	const rateLimits = new Map();
	return {
		scores,
		async query(sql, params = []) {
			if (sql.includes("INSERT INTO api_rate_limits")) {
				const key = `${params[0]}:${params[1]}:${params[2]}`;
				const count = Math.min((rateLimits.get(key) || 0) + 1, Number(params[4]));
				rateLimits.set(key, count);
				return { rowCount: 1, rows: [{ request_count: count }] };
			}
			if (sql.startsWith("DELETE FROM api_rate_limits")) return { rowCount: 0, rows: [] };
			if (sql.startsWith("UPDATE installations")) return { rowCount: 1 };
			if (sql.includes("INSERT INTO leaderboard_profiles")) return { rowCount: 1 };
			if (sql.includes("INSERT INTO leaderboard_scores")) {
				const key = `${params[0]}:${params[1]}`;
				const score = Number(params[2]);
				if (scores.has(key) && scores.get(key) >= score) return { rowCount: 0, rows: [] };
				scores.set(key, score);
				return { rowCount: 1, rows: [{ score }] };
			}
			if (sql.includes("WITH best_scores")) {
				assert.match(sql, /moderation_status = 'active'/);
				return { rowCount: 0, rows: [] };
			}
			throw new Error(`Unexpected SQL in test: ${sql}`);
		},
	};
}

test("leaderboard stores only a strictly improved best score per device and route", async () => {
	const pool = leaderboardPool();
	await withServer(pool, async (base) => {
		const submit = (score) => fetch(`${base}/v1/leaderboards/unverified`, {
			method: "POST",
			headers: HEADERS,
			body: JSON.stringify({ routeId: "kariakoo", score, displayName: "Konda Juma" }),
		});

		const first = await submit(800);
		assert.equal(first.status, 200);
		assert.equal((await first.json()).accepted, true);

		const lower = await submit(700);
		assert.equal(lower.status, 200);
		assert.equal((await lower.json()).accepted, false);

		const improved = await submit(900);
		assert.equal(improved.status, 200);
		assert.equal((await improved.json()).accepted, true);
		assert.equal(pool.scores.size, 1);
		assert.equal(pool.scores.get(`${INSTALLATION_ID}:kariakoo`), 900);
	});
});

test("leaderboard score bursts are rate limited per installation", async () => {
	const pool = leaderboardPool();
	await withServer(pool, async (base) => {
		const submit = (score) => fetch(`${base}/v1/leaderboards/unverified`, {
			method: "POST",
			headers: HEADERS,
			body: JSON.stringify({ routeId: "kariakoo", score, displayName: "Konda Juma" }),
		});
		for (let score = 1; score <= 8; score += 1) {
			const response = await submit(score);
			assert.equal(response.status, 200);
			await response.arrayBuffer();
		}
	});
	await withServer(pool, async (base) => {
		const submit = (score) => fetch(`${base}/v1/leaderboards/unverified`, {
			method: "POST",
			headers: HEADERS,
			body: JSON.stringify({ routeId: "kariakoo", score, displayName: "Konda Juma" }),
		});
		const limited = await submit(9);
		assert.equal(limited.status, 429);
		assert.equal((await limited.json()).error, "rate_limited");
		assert.ok(Number(limited.headers.get("retry-after")) > 0);
	});
});

test("leaderboard rejects reserved staff-like names before writing scores", async () => {
	const pool = leaderboardPool();
	await withServer(pool, async (base) => {
		const response = await fetch(`${base}/v1/leaderboards/unverified`, {
			method: "POST",
			headers: HEADERS,
			body: JSON.stringify({ routeId: "kariakoo", score: 500, displayName: "Official_Dereva" }),
		});
		assert.equal(response.status, 400);
		assert.equal((await response.json()).error, "invalid_display_name");
		assert.equal(pool.scores.size, 0);
	});
});

test("public world standings reads have a per-IP burst limit", async () => {
	const rateLimits = new Map();
	const pool = {
		async query(sql, params = []) {
			if (sql.includes("INSERT INTO api_rate_limits")) {
				const key = `${params[0]}:${params[1]}`;
				const count = Math.min((rateLimits.get(key) || 0) + 1, Number(params[4]));
				rateLimits.set(key, count);
				return { rowCount: 1, rows: [{ request_count: count }] };
			}
			if (sql.startsWith("DELETE FROM api_rate_limits")) return { rowCount: 0, rows: [] };
			if (sql.includes("WITH best_scores")) {
				assert.match(sql, /moderation_status = 'active'/);
				return { rowCount: 0, rows: [] };
			}
			throw new Error(`Unexpected SQL in test: ${sql}`);
		},
	};
	await withServer(pool, async (base) => {
		for (let index = 0; index < 90; index += 1) {
			const response = await fetch(`${base}/v1/leaderboards/unverified/kariakoo`);
			assert.equal(response.status, 200);
			await response.arrayBuffer();
		}
		const limited = await fetch(`${base}/v1/leaderboards/unverified/kariakoo`);
		assert.equal(limited.status, 429);
		assert.equal((await limited.json()).error, "rate_limited");
	});
});

test("leaderboard reports use opaque public references and accept one report per target", async () => {
	const targetId = "b47ac10b-58cc-4372-a567-0e02b2c3d479";
	const reportRef = "c47ac10b-58cc-4372-a567-0e02b2c3d479";
	let reportRows = 0;
	const limits = new Map();
	const pool = {
		async query(sql, params = []) {
			if (sql.includes("INSERT INTO api_rate_limits")) {
				const key = `${params[0]}:${params[1]}`;
				const count = Math.min((limits.get(key) || 0) + 1, Number(params[4]));
				limits.set(key, count);
				return { rowCount: 1, rows: [{ request_count: count }] };
			}
			if (sql.startsWith("DELETE FROM api_rate_limits")) return { rowCount: 0 };
			if (sql.startsWith("UPDATE installations")) return { rowCount: 1 };
			if (sql.includes("SELECT profile.installation_id, profile.display_name")) {
				assert.equal(params[0], reportRef);
				return { rowCount: 1, rows: [{ installation_id: targetId, display_name: "Konda Juma" }] };
			}
			if (sql.includes("INSERT INTO leaderboard_reports")) {
				reportRows += 1;
				return { rowCount: reportRows === 1 ? 1 : 0, rows: reportRows === 1 ? [{ id: 1 }] : [] };
			}
			throw new Error(`Unexpected SQL in report test: ${sql}`);
		},
	};
	await withServer(pool, async (base) => {
		const submit = () => fetch(`${base}/v1/leaderboards/reports`, {
			method: "POST",
			headers: HEADERS,
			body: JSON.stringify({ reportRef, routeId: "kariakoo", reason: "impersonation" }),
		});
		const first = await submit();
		assert.equal(first.status, 201);
		assert.deepEqual(await first.json(), { accepted: true, duplicate: false });
		const duplicate = await submit();
		assert.equal(duplicate.status, 200);
		assert.deepEqual(await duplicate.json(), { accepted: true, duplicate: true });
		const invalid = await fetch(`${base}/v1/leaderboards/reports`, {
			method: "POST", headers: HEADERS,
			body: JSON.stringify({ reportRef, routeId: "kariakoo", reason: "free text" }),
		});
		assert.equal(invalid.status, 400);
	});
});

test("moderation console requires a configured secret and lists reports only to its operator", async () => {
	const previousToken = process.env.MODERATION_ADMIN_TOKEN;
	const adminToken = "moderation-test-token-".padEnd(40, "x");
	process.env.MODERATION_ADMIN_TOKEN = adminToken;
	const pool = {
		async query(sql) {
			assert.match(sql, /FROM leaderboard_reports/);
			return { rowCount: 1, rows: [{
				id: 7, target_id: "b47ac10b-58cc-4372-a567-0e02b2c3d479",
				reported_name: "Konda Juma", reason: "impersonation", route_id: "kariakoo",
				created_at: "2026-10-08T00:00:00Z", review_status: "open",
				review_action: null, reviewed_at: null, target_report_count: 2,
			}] };
		},
	};
	try {
		await withServer(pool, async (base) => {
			const page = await fetch(`${base}/admin`);
			assert.equal(page.status, 200);
			assert.match(page.headers.get("content-security-policy"), /frame-ancestors 'none'/);
			assert.match(await page.text(), /Leaderboard moderation/);
			assert.equal((await fetch(`${base}/admin.css`)).status, 200);
			assert.equal((await fetch(`${base}/admin.js`)).status, 200);

			delete process.env.MODERATION_ADMIN_TOKEN;
			const denied = await fetch(`${base}/v1/admin/reports`);
			assert.equal(denied.status, 503);
			process.env.MODERATION_ADMIN_TOKEN = adminToken;
			const wrong = await fetch(`${base}/v1/admin/reports`, {
				headers: { "X-Admin-Token": "wrong" },
			});
			assert.equal(wrong.status, 401);
			const response = await fetch(`${base}/v1/admin/reports`, {
				headers: { "X-Admin-Token": adminToken },
			});
			assert.equal(response.status, 200);
			const result = await response.json();
			assert.equal(result.reports[0].displayName, "Konda Juma");
			assert.equal(result.reports[0].reportCount, 2);
		});
	} finally {
		if (previousToken === undefined) delete process.env.MODERATION_ADMIN_TOKEN;
		else process.env.MODERATION_ADMIN_TOKEN = previousToken;
	}
});

test("moderation can dismiss a report or hide and restore a public profile", async () => {
	const previousToken = process.env.MODERATION_ADMIN_TOKEN;
	const adminToken = "moderation-test-token-".padEnd(40, "x");
	const targetId = "b47ac10b-58cc-4372-a567-0e02b2c3d479";
	process.env.MODERATION_ADMIN_TOKEN = adminToken;
	const statements = [];
	const pool = {
		async query(sql) {
			statements.push(sql);
			if (sql.includes("WITH restored_profile")) return { rowCount: 1, rows: [{ display_name: "Konda Juma" }] };
			throw new Error(`Unexpected query: ${sql}`);
		},
		async connect() {
			return {
				async query(sql) {
					statements.push(sql);
					if (sql.startsWith("SELECT reported_installation_id")) {
						return { rowCount: 1, rows: [{ reported_installation_id: targetId, review_status: "open" }] };
					}
				return { rowCount: 1, rows: [] };
				},
				release() {},
			};
		},
	};
	try {
		await withServer(pool, async (base) => {
			const response = await fetch(`${base}/v1/admin/reports/8/resolve`, {
				method: "POST",
				headers: { "X-Admin-Token": adminToken, "Content-Type": "application/json" },
				body: JSON.stringify({ action: "hide_profile" }),
			});
			assert.equal(response.status, 200);
			assert.deepEqual(await response.json(), { resolved: true, action: "hide_profile" });
			assert.ok(statements.includes("BEGIN"));
			assert.ok(statements.some((sql) => sql.includes("moderation_status = 'hidden'")));
			assert.ok(statements.includes("COMMIT"));

			const restored = await fetch(`${base}/v1/admin/profiles/${targetId}/restore`, {
				method: "POST", headers: { "X-Admin-Token": adminToken },
			});
			assert.deepEqual(await restored.json(), { restored: true });
			assert.ok(statements.some((sql) => sql.includes("WITH restored_profile")));
		});
	} finally {
		if (previousToken === undefined) delete process.env.MODERATION_ADMIN_TOKEN;
		else process.env.MODERATION_ADMIN_TOKEN = previousToken;
	}
});

test("blocking a friend severs the link and supports unblocking", async () => {
	const friendId = "b47ac10b-58cc-4372-a567-0e02b2c3d479";
	const statements = [];
	let isBlocked = false;
	const pool = {
		async query(sql) {
			if (sql.startsWith("UPDATE installations")) return { rowCount: 1 };
			if (sql.startsWith("DELETE FROM leaderboard_blocks")) {
				const wasBlocked = isBlocked;
				isBlocked = false;
				return { rowCount: wasBlocked ? 1 : 0 };
			}
			if (sql.includes("FROM leaderboard_blocks AS block")) {
				return { rowCount: isBlocked ? 1 : 0, rows: isBlocked ? [{
					installation_id: friendId, display_name: "Konda Juma", created_at: "2026-10-08T00:00:00Z",
				}] : [] };
			}
			throw new Error(`Unexpected SQL in block test: ${sql}`);
		},
		async connect() {
			return {
				async query(sql) {
					statements.push(sql);
					if (sql.startsWith("INSERT INTO leaderboard_blocks")) isBlocked = true;
					return { rowCount: 1, rows: [] };
				},
				release() {},
			};
		},
	};
	await withServer(pool, async (base) => {
		const blocked = await fetch(`${base}/v1/leaderboards/blocks/${friendId}`, {
			method: "POST", headers: HEADERS,
		});
		assert.equal(blocked.status, 200);
		assert.deepEqual(await blocked.json(), { blocked: true });
		assert.ok(statements.includes("BEGIN"));
		assert.ok(statements.some((sql) => sql.startsWith("DELETE FROM leaderboard_friendships")));
		assert.ok(statements.includes("COMMIT"));

		const listed = await fetch(`${base}/v1/leaderboards/blocks`, { headers: HEADERS });
		assert.deepEqual((await listed.json()).blocks.map((row) => row.friendId), [friendId]);

		const unblocked = await fetch(`${base}/v1/leaderboards/blocks/${friendId}`, {
			method: "DELETE", headers: HEADERS,
		});
		assert.deepEqual(await unblocked.json(), { unblocked: true });
		const empty = await fetch(`${base}/v1/leaderboards/blocks`, { headers: HEADERS });
		assert.deepEqual((await empty.json()).blocks, []);
	});
});
