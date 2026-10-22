import test from 'node:test';
import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import { telemetryProperties } from '../src/telemetry.js';

test('typed events drop unknown legacy fields and reject new-schema free text', () => {
  assert.deepEqual(telemetryProperties('run_end', { score: 1, notes: 'private text' }), { score: 1 });
  assert.equal(telemetryProperties('run_end', { score: 1, notes: 'private text' }, 2), null);
  assert.equal(telemetryProperties('run_end', { score: -1 }, 2), null);
  assert.equal(telemetryProperties('run_end', { condition: 'unexpected' }, 2), null);
  assert.equal(telemetryProperties('run_settled', { route: 'posta', score: 100 }, 2), null);
  assert.equal(telemetryProperties('run_end', { score: Infinity }, 2), null);
  assert.ok(telemetryProperties('run_settled', { run_ref: crypto.randomUUID(), route: 'posta', score: 100, coins: 12 }, 2));
});
