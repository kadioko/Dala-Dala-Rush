import test from "node:test";
import assert from "node:assert/strict";
import { once } from "node:events";
import { createApp, purgeExpiredHubPresence } from "../src/server.js";

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

function hubPool({ profile = true } = {}) {
	const statements = [];
	return {
		statements,
		async query(sql, params = []) {
			statements.push({ sql, params });
			if (sql.includes("INSERT INTO api_rate_limits")) return { rowCount: 1, rows: [{ request_count: 1 }] };
			if (sql.startsWith("DELETE FROM api_rate_limits")) return { rowCount: 0, rows: [] };
			if (sql.startsWith("UPDATE installations SET last_seen_at")) return { rowCount: 1, rows: [{ id: ID }] };
			if (sql.includes("INSERT INTO hub_presence")) return { rowCount: profile ? 1 : 0, rows: profile ? [{ installation_id: ID }] : [] };
			if (sql.startsWith("DELETE FROM hub_presence")) return { rowCount: 0, rows: [] };
			if (sql.includes("SELECT presence.installation_id")) return { rowCount: 1, rows: [{
				installation_id: "d29b1349-6132-4730-9bd0-b9db68277eaf", display_name: "Konda Juma",
				player_x: 450, player_y: 510, vehicle_id: "classic_blue", last_emote: "wave",
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
			body: JSON.stringify({ districtId: "kariakoo", x: 420, y: 700, vehicleId: "classic_blue", emote: "wave" }) });
		assert.equal(response.status, 200);
		assert.deepEqual(await response.json(), { present: true, expiresInSeconds: 45 });
		const crowd = await fetch(`${base}/v1/hub/crowd/kariakoo`, { headers: HEADERS });
		const payload = await crowd.json();
		assert.equal(crowd.status, 200);
		assert.equal(payload.players[0].displayName, "Konda Juma");
		assert.equal(payload.players[0].x, 450);
		const crowdQuery = pool.statements.find((entry) => entry.sql.includes("SELECT presence.installation_id"));
		assert.match(crowdQuery.sql, /NOT EXISTS/);
		assert.match(crowdQuery.sql, /INTERVAL '45 seconds'/);
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
	let observed = "";
	const removed = await purgeExpiredHubPresence({
		async query(sql) { observed = sql; return { rowCount: 3, rows: [] }; },
	});
	assert.equal(removed, 3);
	assert.match(observed, /updated_at <= NOW\(\) - INTERVAL '45 seconds'/);
});
