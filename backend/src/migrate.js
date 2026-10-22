import { readFile, readdir } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import path from "node:path";
import pg from "pg";
import { createHash } from "node:crypto";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const migrationsDirectory = path.join(__dirname, "..", "sql");

export async function migrate(pool, { directory = migrationsDirectory, onApplied = () => {} } = {}) {
	const client = await pool.connect();
	try {
		await client.query("SELECT pg_advisory_lock(88430317)");
		await client.query(`CREATE TABLE IF NOT EXISTS schema_migrations (
			version TEXT PRIMARY KEY, checksum TEXT NOT NULL,
			applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW())`);
		const applied = new Map((await client.query("SELECT version, checksum FROM schema_migrations"))
			.rows.map((row) => [row.version, row.checksum]));
		const names = (await readdir(directory)).filter((name) => /^\d+_.*\.sql$/.test(name)).sort();
		for (const name of names) {
			const sql = await readFile(path.join(directory, name), "utf8");
			// Git may check out CRLF on Windows; line endings are not a schema change.
			const checksum = createHash("sha256").update(sql.replace(/\r\n/g, "\n")).digest("hex");
			if (applied.has(name)) {
				if (applied.get(name) !== checksum) throw new Error(`Applied migration changed: ${name}`);
				continue;
			}
			await client.query("BEGIN");
			try {
				await client.query(sql);
				await client.query("INSERT INTO schema_migrations (version, checksum) VALUES ($1, $2)", [name, checksum]);
				await client.query("COMMIT");
				onApplied(name);
			} catch (error) {
				await client.query("ROLLBACK");
				throw error;
			}
		}
	} finally {
		try { await client.query("SELECT pg_advisory_unlock(88430317)"); }
		finally { client.release(); }
	}
}

async function runFromCommandLine() {
	if (!process.env.DATABASE_URL) {
		throw new Error("DATABASE_URL is required to run migrations.");
	}
	const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });
	try {
		await migrate(pool, { onApplied: name => console.log("Migration applied: " + name) });
		console.log("Database migration completed.");
	} finally {
		await pool.end();
	}
}

if (process.argv[1] === fileURLToPath(import.meta.url)) runFromCommandLine();
