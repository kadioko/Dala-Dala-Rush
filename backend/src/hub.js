const DISTRICTS = new Set(["kariakoo"]);
const VEHICLES = new Set([
	"classic_blue", "kariakoo_yellow", "mwendokasi_red", "night_bus",
	"vip", "old_school", "simba_express", "bongo_flava",
]);
const EMOTES = new Set(["", "wave", "horn", "dance", "chat_hello", "chat_route",
	"chat_business", "chat_drive", "chat_thanks"]);
const ELECTION_ID_PATTERN = /^dala_world_head_s[1-9][0-9]*$/;

function electionPayload(election, tally, hasVoted) {
	return {
		electionId: election.election_id,
		titleKey: election.title_key,
		opensAt: election.opens_at,
		closesAt: election.closes_at,
		candidates: election.candidates,
		results: tally,
		hasVoted,
		isOpen: new Date(election.closes_at).getTime() > Date.now(),
	};
}

async function readElection(pool, installationId) {
	const electionResult = await pool.query(
		`SELECT election.election_id, election.title_key, election.opens_at, election.closes_at,
		 election.candidates, EXISTS (
		   SELECT 1 FROM hub_election_votes AS own_vote
		   WHERE own_vote.election_id = election.election_id AND own_vote.installation_id = $1
		 ) AS has_voted
		 FROM hub_elections AS election
		 WHERE election.opens_at <= NOW()
		   AND election.closes_at > NOW() - INTERVAL '1 year'
		 ORDER BY (election.closes_at > NOW()) DESC, election.opens_at DESC LIMIT 1`,
		[installationId],
	);
	if (electionResult.rowCount !== 1) return null;
	const election = electionResult.rows[0];
	const tallyResult = await pool.query(
		`SELECT candidate->>'id' AS candidate_id, COUNT(vote.installation_id)::int AS vote_count
		 FROM hub_elections AS election
		 CROSS JOIN LATERAL jsonb_array_elements(election.candidates) AS entries(candidate)
		 LEFT JOIN hub_election_votes AS vote ON vote.election_id = election.election_id
		   AND vote.candidate_id = candidate->>'id'
		 WHERE election.election_id = $1
		 GROUP BY candidate->>'id'`,
		[election.election_id],
	);
	return electionPayload(election, tallyResult.rows.map((row) => ({
		candidateId: row.candidate_id,
		votes: Number(row.vote_count),
	})), election.has_voted === true);
}

export function installHubRoutes(app, pool, requireInstallation, limitHubPresence,
		limitHubElectionVotes, limitWorldReads, problem) {
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
				 last_emote = CASE WHEN EXCLUDED.last_emote <> '' THEN EXCLUDED.last_emote
				   WHEN hub_presence.emote_at <= NOW() - INTERVAL '15 seconds' THEN '' ELSE hub_presence.last_emote END,
				 emote_at = CASE WHEN EXCLUDED.last_emote <> '' THEN NOW()
				   WHEN hub_presence.emote_at <= NOW() - INTERVAL '15 seconds' THEN NULL ELSE hub_presence.emote_at END,
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
				 presence.vehicle_id,
				 CASE WHEN presence.emote_at > NOW() - INTERVAL '15 seconds' THEN presence.last_emote ELSE '' END AS last_emote,
				 presence.emote_at, presence.updated_at
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

	app.get("/v1/hub/election", requireInstallation, limitWorldReads, async (req, res) => {
		try {
			const election = await readElection(pool, req.installationId);
			if (!election) return problem(res, 404, "election_unavailable");
			return res.json(election);
		} catch {
			return problem(res, 503, "election_unavailable");
		}
	});

	app.post("/v1/hub/election/vote", requireInstallation, limitHubElectionVotes, async (req, res) => {
		const electionId = req.body?.electionId;
		const candidateId = req.body?.candidateId;
		if (typeof electionId !== "string" || !ELECTION_ID_PATTERN.test(electionId)
			|| typeof candidateId !== "string" || !/^[a-z0-9_]{3,40}$/.test(candidateId)) {
			return problem(res, 400, "invalid_election_vote");
		}
		try {
			const inserted = await pool.query(
				`INSERT INTO hub_election_votes (election_id, installation_id, candidate_id)
				 SELECT election.election_id, $2, $3 FROM hub_elections AS election
				 WHERE election.election_id = $1 AND election.opens_at <= NOW()
				 AND election.closes_at > NOW()
				 AND EXISTS (SELECT 1 FROM jsonb_array_elements(election.candidates) AS entries(candidate)
				   WHERE candidate->>'id' = $3)
				 ON CONFLICT (election_id, installation_id) DO NOTHING
				 RETURNING installation_id`,
				[electionId, req.installationId, candidateId],
			);
			if (inserted.rowCount !== 1) {
				const current = await readElection(pool, req.installationId);
				if (!current || current.electionId !== electionId) return problem(res, 409, "election_closed_or_unknown");
				if (!current.isOpen) return problem(res, 409, "election_closed");
				if (current.hasVoted) return problem(res, 409, "already_voted");
				return problem(res, 400, "invalid_election_candidate");
			}
			const election = await readElection(pool, req.installationId);
			if (!election) return problem(res, 503, "election_unavailable");
			return res.status(201).json(election);
		} catch {
			return problem(res, 503, "election_unavailable");
		}
	});
}
