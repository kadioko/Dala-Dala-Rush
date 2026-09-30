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
			if (sql.includes("WITH best_scores")) return { rowCount: 0, rows: [] };
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
				const key = `${params[0]}:${params[1]}:${params[2]}`;
				const count = Math.min((rateLimits.get(key) || 0) + 1, Number(params[4]));
				rateLimits.set(key, count);
				return { rowCount: 1, rows: [{ request_count: count }] };
			}
			if (sql.startsWith("DELETE FROM api_rate_limits")) return { rowCount: 0, rows: [] };
			if (sql.includes("WITH best_scores")) return { rowCount: 0, rows: [] };
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
