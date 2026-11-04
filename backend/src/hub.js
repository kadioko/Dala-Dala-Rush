const DISTRICTS = new Set(["kariakoo"]);
const VEHICLES = new Set([
	"classic_blue", "kariakoo_yellow", "mwendokasi_red", "night_bus",
	"vip", "old_school", "simba_express", "bongo_flava",
]);
const EMOTES = new Set(["", "wave", "horn", "dance"]);

export function installHubRoutes(app, pool, requireInstallation, limitHubPresence, limitWorldReads, problem) {
	app.put("/v1/hub/presence", requireInstallation, limitHubPresence, async (req, res) => {
		const { districtId, x, y, vehicleId, emote = "" } = req.body || {};
		if (!DISTRICTS.has(districtId) || !Number.isInteger(x) || x < 0 || x > 1000
			|| !Number.isInteger(y) || y < 0 || y > 1000
			|| !VEHICLES.has(vehicleId) || !EMOTES.has(emote)) {
			return problem(res, 400, "invalid_hub_presence");
		}
		try {
			const result = await pool.query(
				`INSERT INTO hub_presence
				 (installation_id, district_id, player_x, player_y, vehicle_id, last_emote, emote_at, updated_at)
				 SELECT $1, $2, $3, $4, $5, $6, CASE WHEN $6 = '' THEN NULL ELSE NOW() END, NOW()
				 FROM leaderboard_profiles AS profile
				 INNER JOIN installations AS installation ON installation.id = profile.installation_id
				 WHERE profile.installation_id = $1 AND profile.moderation_status = 'active'
				 AND installation.leaderboard_left = FALSE
				 AND (installation.leaderboard_hidden_until IS NULL OR installation.leaderboard_hidden_until <= NOW())
				 ON CONFLICT (installation_id) DO UPDATE SET district_id = EXCLUDED.district_id,
				 player_x = EXCLUDED.player_x, player_y = EXCLUDED.player_y, vehicle_id = EXCLUDED.vehicle_id,
				 last_emote = CASE WHEN EXCLUDED.last_emote = '' THEN hub_presence.last_emote ELSE EXCLUDED.last_emote END,
				 emote_at = CASE WHEN EXCLUDED.last_emote = '' THEN hub_presence.emote_at ELSE NOW() END,
				 updated_at = NOW()
				 RETURNING installation_id`,
				[req.installationId, districtId, x, y, vehicleId, emote],
			);
			if (result.rowCount !== 1) return problem(res, 403, "leaderboard_profile_required");
			await pool.query("DELETE FROM hub_presence WHERE updated_at < NOW() - INTERVAL '45 seconds'");
			return res.json({ present: true, expiresInSeconds: 45 });
		} catch {
			return problem(res, 503, "hub_unavailable");
		}
	});

	app.delete("/v1/hub/presence", requireInstallation, limitHubPresence, async (req, res) => {
		try {
			await pool.query("DELETE FROM hub_presence WHERE installation_id = $1", [req.installationId]);
			return res.json({ left: true });
		} catch {
			return problem(res, 503, "hub_unavailable");
		}
	});

	app.get("/v1/hub/crowd/:districtId", requireInstallation, limitWorldReads, async (req, res) => {
		if (!DISTRICTS.has(req.params.districtId)) return problem(res, 404, "hub_not_found");
		try {
			const result = await pool.query(
				`SELECT presence.installation_id, profile.display_name, presence.player_x, presence.player_y,
				 presence.vehicle_id, presence.last_emote, presence.emote_at, presence.updated_at
				 FROM hub_presence AS presence
				 INNER JOIN leaderboard_profiles AS profile ON profile.installation_id = presence.installation_id
				 INNER JOIN installations AS installation ON installation.id = presence.installation_id
				 WHERE presence.district_id = $1 AND presence.installation_id <> $2
				 AND presence.updated_at > NOW() - INTERVAL '45 seconds'
				 AND profile.moderation_status = 'active' AND installation.leaderboard_left = FALSE
				 AND (installation.leaderboard_hidden_until IS NULL OR installation.leaderboard_hidden_until <= NOW())
				 AND NOT EXISTS (
				   SELECT 1 FROM leaderboard_blocks AS block
				   WHERE (block.blocker_installation_id = $2 AND block.blocked_installation_id = presence.installation_id)
				      OR (block.blocker_installation_id = presence.installation_id AND block.blocked_installation_id = $2)
				 )
				 ORDER BY presence.updated_at DESC LIMIT 20`,
				[req.params.districtId, req.installationId],
			);
			const players = result.rows.map((row) => ({
				playerId: row.installation_id,
				displayName: row.display_name,
				x: row.player_x,
				y: row.player_y,
				vehicleId: row.vehicle_id,
				emote: row.last_emote,
				emoteAt: row.emote_at,
				lastSeen: row.updated_at,
			}));
			return res.json({ districtId: req.params.districtId, players });
		} catch {
			return problem(res, 503, "hub_unavailable");
		}
	});
}
