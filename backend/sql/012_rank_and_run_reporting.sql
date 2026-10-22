ALTER TABLE telemetry_events ADD COLUMN IF NOT EXISTS schema_version INTEGER NOT NULL DEFAULT 1;
ALTER TABLE telemetry_events ADD COLUMN IF NOT EXISTS run_ref UUID;
CREATE UNIQUE INDEX IF NOT EXISTS telemetry_final_run_idx
  ON telemetry_events (installation_id, run_ref) WHERE event_name = 'run_settled' AND run_ref IS NOT NULL;
CREATE INDEX IF NOT EXISTS leaderboard_route_rank_idx
  ON leaderboard_scores (route_id, score DESC, created_at, installation_id);
