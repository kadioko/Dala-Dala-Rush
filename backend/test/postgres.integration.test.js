import test from "node:test";
import assert from "node:assert/strict";
import crypto from "node:crypto";
import { once } from "node:events";
import { mkdtemp, readFile, readdir, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import pg from "pg";
import { migrate } from "../src/migrate.js";
import { createApp } from "../src/server.js";

const url = process.env.TEST_DATABASE_URL;

test("real PostgreSQL migrations, recovery, moderation, and ingestion", {
	skip: !url, timeout: 90_000,
}, async (t) => {
	assert.match(new URL(url).pathname, /_test$/, "Integration tests require a dedicated database ending in _test");
	const schema = `ddrtz_${crypto.randomBytes(8).toString("hex")}`;
	const control = new pg.Pool({ connectionString: url });
	await control.query(`CREATE SCHEMA ${schema}`);
	const pool = new pg.Pool({ connectionString: url, options: `-c search_path=${schema}` });
	const oldAdmin = process.env.MODERATION_ADMIN_TOKEN;
	const adminToken = "integration-only-moderator-token-".padEnd(48, "x");
	process.env.MODERATION_ADMIN_TOKEN = adminToken;
	let server;
	try {
		await t.test("migration ledger serializes first setup and repeated deploys", async () => {
			await Promise.all([migrate(pool), migrate(pool)]);
			assert.equal(Number((await pool.query("SELECT COUNT(*) FROM schema_migrations")).rows[0].count), 15);
		});
		server = createApp(pool).listen(0, "127.0.0.1");
		await once(server, "listening");
		const base = `http://127.0.0.1:${server.address().port}`;
		const request = async (endpoint, method = "GET", body, headers = {}) => {
			const response = await fetch(base + endpoint, { method,
				headers: { "Content-Type": "application/json", ...headers },
				...(body === undefined ? {} : { body: JSON.stringify(body) }) });
			return { status: response.status, body: await response.json() };
		};
		const register = async () => {
			const result = await request("/v1/installations", "POST", {});
			assert.equal(result.status, 201);
			return { id: result.body.installationId, headers: {
				"X-Installation-Id": result.body.installationId, "X-Sync-Token": result.body.syncToken } };
		};
		const player = await register();
		const reporter = await register();
		assert.equal((await request("/v1/leaderboard-profile", "PUT", { displayName: "Lounge Player" }, player.headers)).status, 200);
		assert.equal((await request("/v1/leaderboard-profile", "PUT", { displayName: "Lounge Visitor" }, reporter.headers)).status, 200);
		const adminHeaders = { "X-Admin-Token": adminToken };
		await t.test("lounge messages persist only the fixed phrase allowlist", async () => {
			await pool.query(`INSERT INTO hub_presence
				(installation_id, district_id, player_x, player_y, vehicle_id, last_emote, emote_at)
				VALUES ($1, 'kariakoo', 500, 500, 'classic_blue', 'chat_hello', NOW())`, [player.id]);
			await assert.rejects(pool.query("UPDATE hub_presence SET last_emote = 'free_text' WHERE installation_id = $1", [player.id]), /violates check constraint/);
			await pool.query("UPDATE hub_presence SET emote_at = NOW() - INTERVAL '16 seconds' WHERE installation_id = $1", [player.id]);
			const crowd = await request("/v1/hub/crowd/kariakoo", "GET", undefined, reporter.headers);
			assert.equal(crowd.status, 200);
			assert.equal(crowd.body.players.find((entry) => entry.playerId === player.id)?.emote, "",
				"expired phrases must not be returned to other players");
			await pool.query("DELETE FROM hub_presence WHERE installation_id = $1", [player.id]);
		});
		await t.test("fictional election accepts one vote per installation and exposes totals only", async () => {
			const current = await request('/v1/hub/election', 'GET', undefined, player.headers);
			assert.equal(current.status, 200);
			assert.equal(current.body.hasVoted, false);
			assert.equal(current.body.candidates.length, 3);
			const choice = current.body.candidates[0].id;
			const vote = await request('/v1/hub/election/vote', 'POST', {
				electionId: current.body.electionId, candidateId: choice,
			}, player.headers);
			assert.equal(vote.status, 201);
			assert.equal(vote.body.hasVoted, true);
			assert.equal(vote.body.results.find(row => row.candidateId === choice).votes, 1);
			assert.equal(JSON.stringify(vote.body).includes(player.id), false);
			assert.equal((await request('/v1/hub/election/vote', 'POST', {
				electionId: current.body.electionId, candidateId: current.body.candidates[1].id,
			}, player.headers)).status, 409);
			assert.equal((await pool.query('SELECT COUNT(*) FROM hub_election_votes WHERE installation_id = $1', [player.id])).rows[0].count, '1');
			await pool.query(`UPDATE hub_elections SET opens_at = NOW() - INTERVAL '2 seconds',
				closes_at = NOW() - INTERVAL '1 second' WHERE election_id = $1`, [current.body.electionId]);
			const final = await request('/v1/hub/election', 'GET', undefined, player.headers);
			assert.equal(final.status, 200);
			assert.equal(final.body.isOpen, false);
			assert.equal(final.body.results.find(row => row.candidateId === choice).votes, 1);
			assert.equal((await request('/v1/hub/election/vote', 'POST', {
				electionId: current.body.electionId, candidateId: current.body.candidates[1].id,
			}, player.headers)).status, 409);
		});
		await t.test("acknowledged transfer survives both lost responses and revokes other codes", async () => {
			const source = await register();
			const code = await request("/v1/account/transfer-code", "POST", {}, source.headers);
			const body = { transferCode: code.body.transferCode, operationId: crypto.randomUUID(), syncToken: crypto.randomBytes(32).toString("base64url") };
			assert.equal((await request("/v1/account/claim-transfer", "POST", body)).status, 426);
			assert.equal((await request("/v2/account/claim-transfer", "POST", body)).status, 200);
			assert.equal((await request("/v2/account/claim-transfer", "POST", body)).body.installationId, source.id);
			assert.equal((await request("/v1/cloud-save", "GET", undefined, source.headers)).status, 404, "Source remains authorized before acknowledgement");
			assert.equal((await request("/v2/account/claim-transfer", "POST", { ...body, operationId: crypto.randomUUID() })).status, 409);
			const secondCode = `DDR-T-${crypto.randomBytes(9).toString('hex').toUpperCase()}`;
			await pool.query("INSERT INTO account_transfers (code_hash, installation_id, expires_at) VALUES ($1, $2, NOW() + INTERVAL '15 minutes')", [crypto.createHash('sha256').update(secondCode).digest('hex'), source.id]);
			const ack = { installationId: source.id, operationId: body.operationId, syncToken: body.syncToken };
			for (let retry = 0; retry < 2; retry++) assert.equal((await request("/v2/account/acknowledge-transfer", "POST", ack)).body.acknowledged, true);
			assert.equal((await request("/v1/cloud-save", "GET", undefined, source.headers)).status, 401);
			assert.equal((await request("/v2/account/claim-transfer", "POST", { ...body, transferCode: secondCode })).status, 404);
			await pool.query("DELETE FROM account_transfers WHERE installation_id = $1", [source.id]);
			assert.equal((await request("/v2/account/acknowledge-transfer", "POST", ack)).body.acknowledged, true, "Active credential recovers after claim-row cleanup");
		});
		await t.test("a target cannot erase another player's block by leaving rankings", async () => {
			const target = await register();
			await request('/v1/leaderboard-profile', 'PUT', { displayName: 'Block Target' }, target.headers);
			await request('/v1/leaderboards/blocks/' + target.id, 'POST', {}, reporter.headers);
			await request('/v1/leaderboard-profile', 'DELETE', undefined, target.headers);
			await request('/v1/leaderboard-profile', 'PUT', { displayName: 'Block Target' }, target.headers);
			const blocked = await request('/v1/leaderboards/blocks', 'GET', undefined, reporter.headers);
			assert.ok(blocked.body.blocks.some(row => row.friendId === target.id));
		});
		await t.test("an expired unacknowledged transfer preserves the source credential", async () => {
			const source = await register();
			const code = await request('/v1/account/transfer-code', 'POST', {}, source.headers);
			const body = { transferCode: code.body.transferCode, operationId: crypto.randomUUID(), syncToken: crypto.randomBytes(32).toString('base64url') };
			assert.equal((await request('/v2/account/claim-transfer', 'POST', body)).status, 200);
			await pool.query("UPDATE account_transfers SET expires_at = NOW() - INTERVAL '1 second' WHERE installation_id = $1", [source.id]);
			assert.equal((await request('/v2/account/acknowledge-transfer', 'POST', { installationId: source.id, operationId: body.operationId, syncToken: body.syncToken })).status, 404);
			assert.equal((await request('/v1/cloud-save', 'GET', undefined, source.headers)).status, 404, 'Authorized source without a backup returns 404, not 401');
		});
		await t.test("own rank and nearby drivers work below the public top 25", async () => {
			const ids = Array.from({ length: 35 }, () => crypto.randomUUID());
			const token = crypto.randomBytes(32).toString('base64url');
			await pool.query('INSERT INTO installations (id, sync_token_hash) SELECT id, md5(id::text) || md5(id::text) FROM unnest($1::uuid[]) AS id', [ids]);
			await pool.query('UPDATE installations SET sync_token_hash = $1 WHERE id = $2', [crypto.createHash('sha256').update(token).digest('hex'), ids[2]]);
			await pool.query("INSERT INTO leaderboard_profiles (installation_id, display_name) SELECT id, 'Rank Driver ' || n FROM unnest($1::uuid[]) WITH ORDINALITY AS x(id, n)", [ids]);
			await pool.query("INSERT INTO leaderboard_scores (installation_id, route_id, score) SELECT id, 'posta', 1000 + n FROM unnest($1::uuid[]) WITH ORDINALITY AS x(id, n)", [ids]);
			const headers = { 'X-Installation-Id': ids[2], 'X-Sync-Token': token };
			const board = await request('/v1/leaderboards/nearby/posta', 'GET', undefined, headers);
			assert.equal(board.body.own.rank, 33);
			assert.ok(board.body.nearby.some(row => row.isYou && row.rank === 33));
			assert.ok(board.body.nearby.length <= 7);
			assert.equal((await request('/v1/leaderboards/nearby/kigamboni', 'GET', undefined, headers)).body.own, null);
		});
		await t.test("lost cloud acknowledgements replay; stale concurrent backups preserve the winner", async () => {
			const body = { operationId: crypto.randomUUID(), baseRevision: 0, revision: 1,
				save: { total_coins: 125, selected_vehicle: "classic_blue" } };
			assert.equal((await request("/v1/cloud-save", "POST", body, player.headers)).status, 200);
			const retried = await request("/v1/cloud-save", "POST", body, player.headers);
			assert.equal(retried.body.replayed, true);
			assert.equal(retried.body.revision, 1);
			assert.equal((await request("/v1/cloud-save", "POST", { ...body, save: { total_coins: 999 } }, player.headers)).status, 409);
			const uploads = [250, 500].map((coins) => request("/v1/cloud-save", "POST", {
				operationId: crypto.randomUUID(), baseRevision: 1, revision: 2, save: { total_coins: coins },
			}, player.headers));
			const results = await Promise.all(uploads);
			assert.deepEqual(results.map((r) => r.status).sort(), [200, 409]);
			assert.equal(results.find((r) => r.status === 409).body.currentRevision, 2);
			const backup = await request("/v1/cloud-save", "GET", undefined, player.headers);
			assert.equal(backup.body.revision, 2);
			assert.ok([250, 500].includes(backup.body.save.total_coins));
			const legacy = { revision: 3, save: { total_coins: 600 } };
			assert.equal((await request("/v1/cloud-save", "POST", legacy, player.headers)).status, 200,
				"Already-distributed clients must still upload their legacy backup body");
			assert.equal((await request("/v1/cloud-save", "POST", legacy, player.headers)).status, 409);
		});
		await t.test("moderation survives leaving/rejoining and supports restore after profile removal", async () => {
			const score = { displayName: "Konda Juma", routeId: "arusha", score: 100 };
			assert.equal((await request("/v1/leaderboards/unverified", "POST", score, player.headers)).status, 200);
			const world = await request("/v1/leaderboards/unverified/arusha");
			assert.equal(world.body.scores.length, 1);
			assert.equal((await request("/v1/leaderboards/reports", "POST", {
				reportRef: world.body.scores[0].reportRef, routeId: "arusha", reason: "other",
			}, reporter.headers)).status, 201);
			const reports = await request("/v1/admin/reports", "GET", undefined, adminHeaders);
			const reportId = reports.body.reports[0].reportId;
			assert.equal((await request(`/v1/admin/reports/${reportId}/resolve`, "POST", { action: "hide_profile" }, adminHeaders)).status, 200);
			assert.equal((await request("/v1/leaderboards/unverified/arusha")).body.scores.length, 0);
			assert.equal((await request("/v1/leaderboard-profile", "DELETE", undefined, player.headers)).status, 200);
			assert.equal((await request("/v1/leaderboard-profile", "PUT", { displayName: "Another Name" }, player.headers)).status, 403);
			assert.equal((await request("/v1/leaderboards/unverified", "POST", score, player.headers)).status, 403);
			const hidden = await request("/v1/admin/profiles/hidden", "GET", undefined, adminHeaders);
			assert.equal(hidden.body.profiles[0].targetId, player.id);
			assert.equal((await request(`/v1/admin/profiles/${player.id}/restore`, "POST", {}, adminHeaders)).body.restored, true);
			assert.equal((await request("/v1/leaderboard-profile", "PUT", { displayName: "Konda Juma" }, player.headers)).status, 200);
			assert.equal((await request("/v1/leaderboards/unverified", "POST", score, player.headers)).status, 200);
		});
		await t.test("event IDs deduplicate retries and a failed batch rolls back every row", async () => {
			const makeEvent = (properties = {}) => ({ id: crypto.randomUUID(), e: "run_end", t: Math.floor(Date.now() / 1000), p: properties });
			const events = [makeEvent({ route: "arusha" }), makeEvent({ score: 100 })];
			for (let attempt = 0; attempt < 2; attempt++) {
				assert.equal((await request("/v1/telemetry", "POST", { events }, player.headers)).status, 201);
			}
			assert.equal(Number((await pool.query("SELECT COUNT(*) FROM telemetry_events")).rows[0].count), 2);
			await pool.query(`CREATE FUNCTION fail_test_event() RETURNS trigger LANGUAGE plpgsql AS $$
				BEGIN IF NEW.properties->>'score' = '987654321' THEN RAISE EXCEPTION 'test failure'; END IF; RETURN NEW; END $$;
				CREATE TRIGGER fail_event BEFORE INSERT ON telemetry_events FOR EACH ROW EXECUTE FUNCTION fail_test_event()`);
			const failed = [makeEvent(), makeEvent({ score: 987654321 })];
			assert.equal((await request("/v1/telemetry", "POST", { events: failed }, player.headers)).status, 503);
			assert.equal(Number((await pool.query("SELECT COUNT(*) FROM telemetry_events")).rows[0].count), 2);
			await pool.query("DROP TRIGGER fail_event ON telemetry_events");
			assert.equal((await request("/v1/telemetry", "POST", { events: failed }, player.headers)).status, 201);
			assert.equal(Number((await pool.query("SELECT COUNT(*) FROM telemetry_events")).rows[0].count), 4);
		});
		await t.test("logical run settlement deduplicates across new transport IDs", async () => {
			const run = crypto.randomUUID();
			const event = () => ({ id: crypto.randomUUID(), v: 2, e: 'run_settled', t: Math.floor(Date.now() / 1000),
				p: { run_ref: run, route: 'kariakoo', score: 200, coins: 12, continued: true } });
			for (let i = 0; i < 2; i++) {
				const result = await request('/v1/telemetry', 'POST', { events: [event()] }, player.headers);
				assert.equal(result.status, 201);
				assert.equal(result.body.accepted, 1);
			}
			assert.equal(Number((await pool.query("SELECT COUNT(*) FROM telemetry_events WHERE event_name = 'run_settled' AND run_ref = $1", [run])).rows[0].count), 1);
			assert.equal((await request('/v1/telemetry', 'POST', { events: [{ ...event(), p: { run_ref: run, route: 'kariakoo', score: 200, private_name: 'reject' } }] }, player.headers)).status, 400);
		});
		await t.test("full account deletion removes backup, public records, and moderation disposition", async () => {
			assert.equal((await request("/v1/account", "DELETE", undefined, player.headers)).status, 200);
			assert.equal((await pool.query("SELECT id FROM installations WHERE id = $1", [player.id])).rowCount, 0);
			assert.equal((await pool.query("SELECT revision FROM cloud_saves WHERE installation_id = $1", [player.id])).rowCount, 0);
			assert.equal((await pool.query("SELECT election_id FROM hub_election_votes WHERE installation_id = $1", [player.id])).rowCount, 0);
		});
		await t.test("failed migrations roll back and checksum drift stops deployment", async () => {
			const folder = await mkdtemp(path.join(tmpdir(), "ddrtz-migrate-"));
			try {
				const filename = path.join(folder, "999_regression.sql");
				await writeFile(filename, "CREATE TABLE should_rollback (id INT); SELECT missing_test_column;");
				await assert.rejects(migrate(pool, { directory: folder }));
				assert.equal((await pool.query("SELECT to_regclass('should_rollback') AS name")).rows[0].name, null);
				await writeFile(filename, "CREATE TABLE checksum_probe (id INT);");
				await migrate(pool, { directory: folder });
				await writeFile(filename, "CREATE TABLE checksum_probe (other INT);");
				await assert.rejects(migrate(pool, { directory: folder }), /Applied migration changed/);
			} finally { await rm(folder, { recursive: true, force: true }); }
		});
		await t.test("adopting a pre-ledger schema preserves player backups", async () => {
			const legacySchema = `${schema}_legacy`;
			await control.query(`CREATE SCHEMA ${legacySchema}`);
			const legacy = new pg.Pool({ connectionString: url, options: `-c search_path=${legacySchema}` });
			try {
				const directory = new URL("../sql/", import.meta.url);
				for (const name of (await readdir(directory)).filter((name) => name.endsWith(".sql") && name < "010").sort()) {
					await legacy.query(await readFile(new URL(name, directory), "utf8"));
				}
				await legacy.query("INSERT INTO installations (id, sync_token_hash) VALUES ($1, 'legacy-test')", [reporter.id]);
				await legacy.query("INSERT INTO cloud_saves (installation_id, revision, save_data) VALUES ($1, 7, '{\"total_coins\":321}')", [reporter.id]);
				await migrate(legacy);
				const row = (await legacy.query("SELECT revision, save_data FROM cloud_saves")).rows[0];
				assert.equal(Number(row.revision), 7);
				assert.equal(row.save_data.total_coins, 321);
			} finally {
				await legacy.end();
				await control.query(`DROP SCHEMA ${legacySchema} CASCADE`);
			}
		});
	} finally {
		if (oldAdmin === undefined) delete process.env.MODERATION_ADMIN_TOKEN;
		else process.env.MODERATION_ADMIN_TOKEN = oldAdmin;
		if (server) { server.closeAllConnections(); await new Promise((resolve) => server.close(resolve)); }
		await pool.end();
		await control.query(`DROP SCHEMA ${schema} CASCADE`);
		await control.end();
	}
});
