import test from "node:test";
import assert from "node:assert/strict";
import { once } from "node:events";
import { createApp, purgeExpiredTelemetry } from "../src/server.js";

test("telemetry retention removes expired events in bounded 90-day batches", async () => {
  const calls = [];
  const pool = {
    async query(sql, params) {
      calls.push({ sql, params });
      if (sql.includes("DELETE FROM telemetry_events")) {
        return { rowCount: 2, rows: [{ id: 1 }, { id: 2 }] };
      }
      if (sql.includes("DELETE FROM leaderboard_reports")) return { rowCount: 1 };
      throw new Error(`Unexpected SQL in retention test: ${sql}`);
    },
  };
  const deleted = await purgeExpiredTelemetry(pool);
  assert.equal(deleted, 2);
  assert.equal(calls.length, 2);
  assert.deepEqual(calls[0].params, [90, 1000]);
  assert.deepEqual(calls[1].params, [90, 1000]);
  assert.match(calls[0].sql, /received_at < NOW\(\)/);
  assert.match(calls[0].sql, /LIMIT \$2/);
});

test("telemetry endpoint accepts whole seconds and rejects fractional timestamps", async () => {
  const inserts = [];
  const pool = {
    async query(sql, params) {
      if (sql.startsWith("UPDATE installations")) return { rowCount: 1 };
      if (sql.includes("INSERT INTO telemetry_events")) {
        inserts.push(params);
        return { rowCount: 1 };
      }
      throw new Error(`Unexpected SQL in test: ${sql}`);
    },
  };
  const server = createApp(pool).listen(0, "127.0.0.1");
  await once(server, "listening");
  const url = `http://127.0.0.1:${server.address().port}/v1/telemetry`;
  const headers = {
    "Content-Type": "application/json",
    "X-Installation-Id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
    "X-Sync-Token": "a".repeat(32),
  };
  const post = (timestamp) => fetch(url, {
    method: "POST",
    headers,
    body: JSON.stringify({ events: [{ e: "run_end", p: { score: 100 }, t: timestamp }] }),
  });

  try {
    const now = Math.floor(Date.now() / 1000);
    const valid = await post(now);
    assert.equal(valid.status, 201);
    assert.equal((await valid.json()).accepted, 1);

    const fractional = await post(now + 0.25);
    assert.equal(fractional.status, 400);
    assert.equal((await fractional.json()).error, "invalid_event");
    assert.equal(inserts.length, 1);
  } finally {
    await new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
  }
});
