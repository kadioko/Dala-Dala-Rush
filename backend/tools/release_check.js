import pg from 'pg';

// Read-only deployment proof. Never print credentials, scores, or player data.
const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });
try {
  const versions = (await pool.query('SELECT version FROM schema_migrations ORDER BY version')).rows.map(row => row.version);
  const required = ['010_service_recovery.sql', '011_acknowledged_transfers.sql', '012_rank_and_run_reporting.sql', '013_ephemeral_hub_presence.sql', '014_mtaa_election.sql', '015_hub_preset_lounge.sql'];
  const missing = required.filter(name => !versions.includes(name));
  const columns = (await pool.query(`SELECT table_name, column_name FROM information_schema.columns
    WHERE table_schema = current_schema() AND
    ((table_name = 'account_transfers' AND column_name IN ('claim_operation_id', 'claim_token_hash', 'acknowledged_at'))
      OR (table_name = 'telemetry_events' AND column_name IN ('event_id', 'schema_version', 'run_ref'))
      OR (table_name = 'hub_presence' AND column_name IN ('district_id', 'player_x', 'player_y', 'vehicle_id', 'last_emote', 'emote_at', 'updated_at'))
      OR (table_name = 'hub_elections' AND column_name IN ('election_id', 'title_key', 'opens_at', 'closes_at', 'candidates'))
      OR (table_name = 'hub_election_votes' AND column_name IN ('election_id', 'installation_id', 'candidate_id', 'created_at')))`)).rows;
  const indexes = (await pool.query(`SELECT indexname FROM pg_indexes WHERE schemaname = current_schema()
    AND indexname IN ('account_transfers_claim_operation_idx', 'telemetry_final_run_idx', 'leaderboard_route_rank_idx', 'hub_presence_district_seen_idx', 'hub_election_tally_idx', 'hub_elections_retention_idx')`)).rows;
  const ok = missing.length === 0 && columns.length === 22 && indexes.length === 6;
  console.log(JSON.stringify({ ok, migrations: versions, missing, checkedColumns: columns.length, checkedIndexes: indexes.length }));
  if (!ok) process.exitCode = 1;
} catch (error) {
  console.error('Deployment schema check failed:', error.code || 'database_unavailable');
  process.exitCode = 1;
} finally { await pool.end(); }
