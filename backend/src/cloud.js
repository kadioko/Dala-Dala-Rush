import { isDeepStrictEqual } from "node:util";
import { boundedInteger, isUuid, jsonByteLength } from "./validation.js";

export function installCloudRoutes(app, pool, requireInstallation, problem) {
	app.get("/v1/cloud-save", requireInstallation, async (req, res) => {
		try {
			const result = await pool.query("SELECT revision, save_data, updated_at FROM cloud_saves WHERE installation_id = $1", [req.installationId]);
			if (!result.rowCount) return problem(res, 404, "not_found");
			const row = result.rows[0];
			return res.json({ revision: Number(row.revision), save: row.save_data, updatedAt: row.updated_at });
		} catch { return problem(res, 503, "database_unavailable"); }
	});
	app.post("/v1/cloud-save", requireInstallation, async (req, res) => {
		const { revision, save, operationId, baseRevision } = req.body || {};
		const modern = operationId !== undefined || baseRevision !== undefined;
		if (!boundedInteger(revision, 0, 2_147_483_647) || !save || typeof save !== "object" || Array.isArray(save)
			|| (modern && (!isUuid(operationId) || !boundedInteger(baseRevision, 0, 2_147_483_646) || revision !== baseRevision + 1))) {
			return problem(res, 400, "invalid_save");
		}
		if (jsonByteLength(save) > 64 * 1024) return problem(res, 413, "save_too_large");
		let client;
		try {
			client = await pool.connect();
			await client.query("BEGIN");
			// Serialize a device's first save as well as updates to an existing row.
			const owner = await client.query("SELECT id FROM installations WHERE id = $1 FOR UPDATE", [req.installationId]);
			if (!owner.rowCount) {
				await client.query("ROLLBACK");
				return problem(res, 401, "unauthorized");
			}
			const current = (await client.query("SELECT revision, operation_id, save_data, updated_at FROM cloud_saves WHERE installation_id = $1", [req.installationId])).rows[0];
			if (modern && current?.operation_id === operationId) {
				await client.query("ROLLBACK");
				if (!isDeepStrictEqual(current.save_data, save)) return problem(res, 409, "operation_conflict");
				return res.json({ revision: Number(current.revision), operationId, replayed: true });
			}
			const currentRevision = Number(current?.revision || 0);
			if ((modern && baseRevision !== currentRevision) || (!modern && current && revision <= currentRevision)) {
				await client.query("ROLLBACK");
				return res.status(409).json({ error: "stale_revision", currentRevision, updatedAt: current?.updated_at });
			}
			await client.query(`INSERT INTO cloud_saves (installation_id, revision, save_data, operation_id)
				VALUES ($1, $2, $3::jsonb, $4) ON CONFLICT (installation_id) DO UPDATE
				SET revision = EXCLUDED.revision, save_data = EXCLUDED.save_data,
				operation_id = EXCLUDED.operation_id, updated_at = NOW()`,
			[req.installationId, revision, JSON.stringify(save), modern ? operationId : null]);
			await client.query("COMMIT");
			return res.json({ revision, ...(modern ? { operationId } : {}) });
		} catch {
			if (client) await client.query("ROLLBACK").catch(() => {});
			return problem(res, 503, "database_unavailable");
		} finally { client?.release(); }
	});
}
