import crypto from 'node:crypto';
import { isUuid } from './validation.js';

const hash = value => crypto.createHash('sha256').update(value).digest('hex');
const validToken = value => typeof value === 'string' && /^[A-Za-z0-9_-]{40,128}$/.test(value);

export function installTransferRoutes(app, pool, limit, problem) {
  // Old clients cannot safely receive a new secret after a lost HTTP response.
  app.post('/v1/account/claim-transfer', (_req, res) => problem(res, 426, 'transfer_upgrade_required'));
  app.post('/v2/account/claim-transfer', limit, async (req, res) => {
    const { transferCode, operationId, syncToken } = req.body || {};
    if (typeof transferCode !== 'string' || !/^DDR-T-[A-Z0-9_-]{8,32}$/.test(transferCode)
      || !isUuid(operationId) || !validToken(syncToken)) return problem(res, 400, 'invalid_transfer');
    let client;
    try {
      client = await pool.connect(); await client.query('BEGIN');
      const lookup = await client.query('SELECT installation_id FROM account_transfers WHERE code_hash = $1', [hash(transferCode)]);
      if (!lookup.rowCount) { await client.query('ROLLBACK'); return problem(res, 404, 'transfer_not_found'); }
      const id = lookup.rows[0].installation_id;
      await client.query('SELECT id FROM installations WHERE id = $1 FOR UPDATE', [id]);
      const result = await client.query('SELECT * FROM account_transfers WHERE code_hash = $1 AND expires_at > NOW() FOR UPDATE', [hash(transferCode)]);
      if (!result.rowCount) { await client.query('ROLLBACK'); return problem(res, 404, 'transfer_not_found'); }
      const row = result.rows[0];
      if (row.claim_operation_id && (row.claim_operation_id !== operationId || row.claim_token_hash !== hash(syncToken))) {
        await client.query('ROLLBACK'); return problem(res, 409, 'transfer_claim_in_progress');
      }
      if (!row.claim_operation_id) {
        await client.query('UPDATE account_transfers SET claim_operation_id = $1, claim_token_hash = $2 WHERE code_hash = $3',
          [operationId, hash(syncToken), hash(transferCode)]);
      }
      await client.query('COMMIT');
      return res.json({ installationId: id, operationId, requiresAcknowledgement: true });
    } catch {
      if (client) await client.query('ROLLBACK').catch(() => {});
      return problem(res, 503, 'transfer_unavailable');
    } finally { client?.release(); }
  });

  app.post('/v2/account/acknowledge-transfer', limit, async (req, res) => {
    const { installationId, operationId, syncToken } = req.body || {};
    if (!isUuid(installationId) || !isUuid(operationId) || !validToken(syncToken)) return problem(res, 400, 'invalid_transfer');
    let client;
    try {
      client = await pool.connect(); await client.query('BEGIN');
      const owner = await client.query('SELECT sync_token_hash FROM installations WHERE id = $1 FOR UPDATE', [installationId]);
      if (!owner.rowCount) { await client.query('ROLLBACK'); return problem(res, 404, 'transfer_not_found'); }
      const tokenHash = hash(syncToken);
      const result = await client.query(`SELECT * FROM account_transfers WHERE installation_id = $1
        AND claim_operation_id = $2 AND claim_token_hash = $3 AND expires_at > NOW() FOR UPDATE`,
        [installationId, operationId, tokenHash]);
      // After an acknowledged row expires, the durably held active credential
      // is still sufficient to recover a lost acknowledgement, without rotation.
      if (!result.rowCount && owner.rows[0].sync_token_hash !== tokenHash) {
        await client.query('ROLLBACK'); return problem(res, 404, 'transfer_not_found');
      }
      if (result.rowCount && !result.rows[0].acknowledged_at) {
        await client.query('UPDATE installations SET sync_token_hash = $1, last_seen_at = NOW() WHERE id = $2', [tokenHash, installationId]);
        await client.query(`UPDATE account_transfers SET acknowledged_at = NOW(), claimed_at = NOW(),
          expires_at = NOW() + INTERVAL '24 hours' WHERE claim_operation_id = $1`, [operationId]);
        await client.query('DELETE FROM account_transfers WHERE installation_id = $1 AND claim_operation_id IS DISTINCT FROM $2', [installationId, operationId]);
      } else if (owner.rows[0].sync_token_hash !== tokenHash) {
        await client.query('ROLLBACK'); return problem(res, 401, 'transfer_superseded');
      }
      await client.query('COMMIT');
      return res.json({ installationId, operationId, acknowledged: true });
    } catch {
      if (client) await client.query('ROLLBACK').catch(() => {});
      return problem(res, 503, 'transfer_unavailable');
    } finally { client?.release(); }
  });
}
