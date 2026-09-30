import { readFile, readdir } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import path from "node:path";
import pg from "pg";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const migrationsDirectory = path.join(__dirname, "..", "sql");

export async function migrate(pool) {
	const migrationNames = (await readdir(migrationsDirectory))
		.filter((name) => name.endsWith(".sql"))
		.sort();
	for (const name of migrationNames) {
		const sql = await readFile(path.join(migrationsDirectory, name), "utf8");
		await pool.query(sql);
	}
}

async function runFromCommandLine() {
	if (!process.env.DATABASE_URL) {
		throw new Error("DATABASE_URL is required to run migrations.");
	}
	const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });
	try {
		await migrate(pool);
		console.log("Database migration completed.");
	} finally {
		await pool.end();
	}
}

if (process.argv[1] === fileURLToPath(import.meta.url)) runFromCommandLine();
