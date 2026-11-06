import test from "node:test";
import assert from "node:assert/strict";
import { once } from "node:events";
import { createApp, purgeExpiredHubElectionVotes, purgeExpiredHubPresence } from "../src/server.js";

const ID = "f47ac10b-58cc-4372-a567-0e02b2c3d479";
const HEADERS = { "Content-Type": "application/json", "X-Installation-Id": ID, "X-Sync-Token": "a".repeat(32) };

async function withServer(pool, run) {
	const server = createApp(pool).listen(0, "127.0.0.1");
	await once(server, "listening");
	try { await run(`http://127.0.0.1:${server.address().port}`); }
	finally {
		server.closeAllConnections();
		await new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
	}
}

function hubPool({ profile = true, closed = false } = {}) {
	const statements = [];
	let hasVoted = false;
	const candidates = [
		{ id: "konda_juma", nameKey: "ELECTION_CANDIDATE_JUMA", roleKey: "ELECTION_ROLE_CONDUCTOR" },
		{ id: "fundi_rehema", nameKey: "ELECTION_CANDIDATE_REHEMA", roleKey: "ELECTION_ROLE_MECHANIC" },
		{ id: "mama_tunu", nameKey: "ELECTION_CANDIDATE_TUNU", roleKey: "ELECTION_ROLE_VENDOR" },
	];
	return {
		statements,
		async query(sql, params = []) {
			statements.push({ sql, params });
			if (sql.includes("INSERT INTO hub_election_votes")) {
				if (closed || hasVoted || !candidates.some((candidate) => candidate.id === params[2])) return { rowCount: 0, rows: [] };
				hasVoted = true;
				return { rowCount: 1, rows: [{ installation_id: ID }] };
			}
			if (sql.includes("SELECT election.election_id")) return { rowCount: 1, rows: [{
				election_id: "dala_world_head_s1", title_key: "ELECTION_TITLE_S1",
				opens_at: new Date(Date.now() - 86400000).toISOString(),
				closes_at: new Date(Date.now() + (closed ? -1000 : 86400000)).toISOString(),
				candidates, has_voted: hasVoted,
			}] };
			if (sql.includes("CROSS JOIN LATERAL jsonb_array_elements(election.candidates)")) return { rowCount: 3, rows: candidates.map((candidate) => ({
				candidate_id: candidate.id, vote_count: Number(hasVoted && candidate.id === "konda_juma"),
			})) };
			if (sql.includes("INSERT INTO api_rate_limits")) return { rowCount: 1, rows: [{ request_count: 1 }] };
			if (sql.startsWith("DELETE FROM api_rate_limits")) return { rowCount: 0, rows: [] };
			if (sql.startsWith("UPDATE installations SET last_seen_at")) return { rowCount: 1, rows: [{ id: ID }] };
			if (sql.includes("INSERT INTO hub_presence")) return { rowCount: profile ? 1 : 0, rows: profile ? [{ installation_id: ID }] : [] };
			if (sql.startsWith("DELETE FROM hub_presence")) return { rowCount: 0, rows: [] };
			if (sql.includes("SELECT presence.installation_id")) return { rowCount: 1, rows: [{
				installation_id: "d29b1349-6132-4730-9bd0-b9db68277eaf", display_name: "Konda Juma",
				player_x: 450, player_y: 510, vehicle_id: "classic_blue", last_emote: "chat_hello",
				emote_at: new Date().toISOString(), updated_at: new Date().toISOString(),
			}] };
			throw new Error(`Unexpected SQL: ${sql}`);
		},
	};
}

test("hub presence accepts bounded, whitelisted activity for a joined public profile", async () => {
	const pool = hubPool();
	await withServer(pool, async (base) => {
		const response = await fetch(`${base}/v1/hub/presence`, { method: "PUT", headers: HEADERS,
			body: JSON.stringify({ districtId: "kariakoo", x: 420, y: 700, vehicleId: "classic_blue", emote: "chat_hello" }) });
		assert.equal(response.status, 200);
		assert.deepEqual(await response.json(), { present: true, expiresInSeconds: 45 });
		const crowd = await fetch(`${base}/v1/hub/crowd/kariakoo`, { headers: HEADERS });
		const payload = await crowd.json();
		assert.equal(crowd.status, 200);
		assert.equal(payload.players[0].displayName, "Konda Juma");
		assert.equal(payload.players[0].x, 450);
		assert.equal(payload.players[0].emote, "chat_hello");
		const crowdQuery = pool.statements.find((entry) => entry.sql.includes("SELECT presence.installation_id"));
		assert.match(crowdQuery.sql, /NOT EXISTS/);
		assert.match(crowdQuery.sql, /INTERVAL '45 seconds'/);
		assert.match(crowdQuery.sql, /CASE WHEN presence\.emote_at > NOW\(\) - INTERVAL '15 seconds' THEN presence\.last_emote ELSE '' END/);
		const presenceWrite = pool.statements.find((entry) => entry.sql.includes("INSERT INTO hub_presence"));
		assert.match(presenceWrite.sql, /INTERVAL '15 seconds'/, "preset phrase content should be cleared promptly");
		assert.equal(pool.statements.some((entry) => entry.sql.includes("hub_presence_district_seen_idx")), false);
	});
});

test("hub rejects invalid coordinates and requires an active public profile", async () => {
	const pool = hubPool({ profile: false });
	await withServer(pool, async (base) => {
		const bad = await fetch(`${base}/v1/hub/presence`, { method: "PUT", headers: HEADERS,
			body: JSON.stringify({ districtId: "kariakoo", x: 1001, y: 20, vehicleId: "classic_blue", emote: "wave" }) });
		assert.equal(bad.status, 400);
		const noProfile = await fetch(`${base}/v1/hub/presence`, { method: "PUT", headers: HEADERS,
			body: JSON.stringify({ districtId: "kariakoo", x: 100, y: 200, vehicleId: "classic_blue", emote: "" }) });
		assert.equal(noProfile.status, 403);
		const unknownArea = await fetch(`${base}/v1/hub/crowd/posta`, { headers: HEADERS });
		assert.equal(unknownArea.status, 404);
	});
});

test("players can leave presence and unknown emotes are rejected", async () => {
	const pool = hubPool();
	await withServer(pool, async (base) => {
		const badEmote = await fetch(`${base}/v1/hub/presence`, { method: "PUT", headers: HEADERS,
			body: JSON.stringify({ districtId: "kariakoo", x: 100, y: 200, vehicleId: "classic_blue", emote: "chat" }) });
		assert.equal(badEmote.status, 400);
		const left = await fetch(`${base}/v1/hub/presence`, { method: "DELETE", headers: HEADERS });
		assert.equal(left.status, 200);
		assert.deepEqual(await left.json(), { left: true });
	});
});

test("presence expiry cleanup removes only stale latest-position rows", async () => {
	const statements = [];
	const removed = await purgeExpiredHubPresence({
		async query(sql) { statements.push(sql); return { rowCount: 3, rows: [] }; },
	});
	assert.equal(removed, 3);
	assert.match(statements[0], /last_emote = '', emote_at = NULL WHERE emote_at <= NOW\(\) - INTERVAL '15 seconds'/);
	assert.match(statements[1], /updated_at <= NOW\(\) - INTERVAL '45 seconds'/);
});

test("closed election votes are retained for one year then eligible for deletion", async () => {
	let statement = "";
	const removed = await purgeExpiredHubElectionVotes({
		async query(sql) { statement = sql; return { rowCount: 2, rows: [] }; },
	});
	assert.equal(removed, 2);
	assert.match(statement, /closes_at <= NOW\(\) - INTERVAL '1 year'/);
});

test("fictional election permits one anonymous installation vote and aggregate-only results", async () => {
	const pool = hubPool();
	await withServer(pool, async (base) => {
		const before = await fetch(`${base}/v1/hub/election`, { headers: HEADERS });
		const ballot = await before.json();
		assert.equal(before.status, 200);
		assert.equal(ballot.hasVoted, false);
		assert.equal(ballot.candidates.length, 3);
		assert.equal(ballot.results.reduce((sum, entry) => sum + entry.votes, 0), 0);
		const vote = await fetch(`${base}/v1/hub/election/vote`, { method: "POST", headers: HEADERS,
			body: JSON.stringify({ electionId: ballot.electionId, candidateId: "konda_juma" }) });
		assert.equal(vote.status, 201);
		const receipt = await vote.json();
		assert.equal(receipt.hasVoted, true);
		assert.equal(receipt.results.find((entry) => entry.candidateId === "konda_juma").votes, 1);
		assert.equal(JSON.stringify(receipt).includes(ID), false, "responses never expose voter identity");
		const duplicate = await fetch(`${base}/v1/hub/election/vote`, { method: "POST", headers: HEADERS,
			body: JSON.stringify({ electionId: ballot.electionId, candidateId: "mama_tunu" }) });
		assert.equal(duplicate.status, 409);
	});
});

test("closed fictional election keeps final totals readable but rejects new votes", async () => {
	const pool = hubPool({ closed: true });
	await withServer(pool, async (base) => {
		const response = await fetch(`${base}/v1/hub/election`, { headers: HEADERS });
		const ballot = await response.json();
		assert.equal(response.status, 200);
		assert.equal(ballot.isOpen, false);
		const vote = await fetch(`${base}/v1/hub/election/vote`, { method: "POST", headers: HEADERS,
			body: JSON.stringify({ electionId: ballot.electionId, candidateId: "konda_juma" }) });
		assert.equal(vote.status, 409);
		assert.equal((await vote.json()).error, "election_closed");
	});
});
