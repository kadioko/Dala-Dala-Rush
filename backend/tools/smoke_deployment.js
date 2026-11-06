import assert from 'node:assert/strict';
import crypto from 'node:crypto';

if (!process.argv.includes('--allow-production')) throw new Error('Explicit --allow-production is required.');
const base = 'https://dala-dala-api-production.up.railway.app';
const report = { health: false, worldRoutes: [], cloudRecovery: false, transferRecovery: false, hubPresence: false, hubLoungePhrase: false, hubElectionRead: false, cleanup: false };
let installationId;
let sourceToken;
let receivingToken;
const headers = token => ({ 'Content-Type': 'application/json',
  'X-Installation-Id': installationId, 'X-Sync-Token': token });
async function request(path, method = 'GET', body, token) {
  const response = await fetch(base + path, { method,
    headers: token ? headers(token) : { 'Content-Type': 'application/json' },
    ...(body === undefined ? {} : { body: JSON.stringify(body) }), signal: AbortSignal.timeout(15000) });
  return { status: response.status, body: await response.json() };
}
try {
  report.health = (await request('/health')).body.ok === true;
  assert.equal(report.health, true);
  for (const route of ['kariakoo', 'mwenge', 'mbezi', 'posta', 'kigamboni', 'ubungo', 'arusha']) {
    const board = await request('/v1/leaderboards/unverified/' + route);
    assert.equal(board.status, 200);
    assert.equal(board.body.verification, 'unverified');
    assert.ok(Array.isArray(board.body.scores));
    report.worldRoutes.push({ route, scores: board.body.scores.length });
  }
  // One disposable, unnamed account; never submit fake public standings.
  const registered = await request('/v1/installations', 'POST', {});
  assert.equal(registered.status, 201);
  installationId = registered.body.installationId;
  sourceToken = registered.body.syncToken;
  const upload = { operationId: crypto.randomUUID(), baseRevision: 0, revision: 1,
    save: { schema_version: 18, total_coins: 123, best_score: 0 } };
  assert.equal((await request('/v1/cloud-save', 'POST', upload, sourceToken)).status, 200);
  const repeated = await request('/v1/cloud-save', 'POST', upload, sourceToken);
  assert.equal(repeated.body.replayed, true);
  report.cloudRecovery = true;
  const code = await request('/v1/account/transfer-code', 'POST', {}, sourceToken);
  assert.equal(code.status, 201);
  receivingToken = crypto.randomBytes(32).toString('base64url');
  const claim = { transferCode: code.body.transferCode, operationId: crypto.randomUUID(), syncToken: receivingToken };
  assert.equal((await request('/v1/account/claim-transfer', 'POST', claim)).status, 426);
  for (let retry = 0; retry < 2; retry++) {
    assert.equal((await request('/v2/account/claim-transfer', 'POST', claim)).status, 200);
  }
  assert.equal((await request('/v1/cloud-save', 'GET', undefined, sourceToken)).status, 200);
  const ack = { installationId, operationId: claim.operationId, syncToken: receivingToken };
  for (let retry = 0; retry < 2; retry++) {
    assert.equal((await request('/v2/account/acknowledge-transfer', 'POST', ack)).body.acknowledged, true);
  }
  assert.equal((await request('/v1/cloud-save', 'GET', undefined, sourceToken)).status, 401);
  assert.equal((await request('/v1/cloud-save', 'GET', undefined, receivingToken)).body.save.total_coins, 123);
  assert.equal((await request('/v1/leaderboard-profile', 'PUT', { displayName: 'Hub Smoke' }, receivingToken)).status, 200);
  const presence = await request('/v1/hub/presence', 'PUT', {
    districtId: 'kariakoo', x: 500, y: 500, vehicleId: 'classic_blue', emote: 'wave',
  }, receivingToken);
  assert.equal(presence.status, 200);
  assert.equal(presence.body.present, true);
  const lounge = await request('/v1/hub/presence', 'PUT', {
    districtId: 'kariakoo', x: 500, y: 500, vehicleId: 'classic_blue', emote: 'chat_hello',
  }, receivingToken);
  assert.equal(lounge.status, 200);
  report.hubLoungePhrase = true;
  const crowd = await request('/v1/hub/crowd/kariakoo', 'GET', undefined, receivingToken);
  assert.equal(crowd.status, 200);
  assert.deepEqual(crowd.body.players, []);
  const election = await request('/v1/hub/election', 'GET', undefined, receivingToken);
  assert.equal(election.status, 200);
  assert.ok(Array.isArray(election.body.candidates));
  assert.equal(election.body.results.length, election.body.candidates.length);
  report.hubElectionRead = true;
  assert.equal((await request('/v1/hub/presence', 'DELETE', undefined, receivingToken)).body.left, true);
  report.hubPresence = true;
  const nearby = await request('/v1/leaderboards/nearby/kariakoo', 'GET', undefined, receivingToken);
  assert.equal(nearby.status, 200);
  assert.equal(nearby.body.own, null);
  report.transferRecovery = true;
} catch (error) {
  // Assertions contain only status codes/booleans, never identity payloads.
  console.error('Deployment smoke failed:', error.message);
  process.exitCode = 1;
} finally {
  if (installationId) {
    for (const token of [receivingToken, sourceToken].filter(Boolean)) {
      try {
        if ((await request('/v1/account', 'DELETE', undefined, token)).status === 200) {
          report.cleanup = true;
          break;
        }
      } catch { /* Report cleanup failure without disclosing credentials. */ }
    }
    if (!report.cleanup) { console.error('Disposable account cleanup requires operator attention.'); process.exitCode = 1; }
  }
  console.log(JSON.stringify(report));
}
