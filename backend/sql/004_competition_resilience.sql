-- Wave 29: server-side support for social leaderboard controls and a minimal,
-- consented product-friction event stream. Telemetry is intentionally not tied
-- to names, friend codes, advertising IDs, or cloud-save content.

CREATE TABLE IF NOT EXISTS telemetry_events (
  id BIGSERIAL PRIMARY KEY,
  installation_id UUID NOT NULL REFERENCES installations(id) ON DELETE CASCADE,
  event_name VARCHAR(40) NOT NULL,
  route_id VARCHAR(24),
  properties JSONB NOT NULL DEFAULT '{}'::jsonb,
  occurred_at TIMESTAMPTZ NOT NULL,
  received_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS telemetry_events_name_received_idx
  ON telemetry_events (event_name, received_at DESC);
CREATE INDEX IF NOT EXISTS telemetry_events_route_received_idx
  ON telemetry_events (route_id, received_at DESC);
CREATE INDEX IF NOT EXISTS telemetry_events_retention_idx
  ON telemetry_events (received_at, id);
