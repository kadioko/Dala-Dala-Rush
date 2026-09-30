-- Shared fixed-window counters survive API restarts and work across replicas.
-- subject_hash is an HMAC; source IP addresses are never stored in this table.
CREATE TABLE IF NOT EXISTS api_rate_limits (
  scope VARCHAR(32) NOT NULL,
  subject_hash CHAR(64) NOT NULL,
  window_started_at TIMESTAMPTZ NOT NULL,
  request_count INTEGER NOT NULL CHECK (request_count > 0),
  expires_at TIMESTAMPTZ NOT NULL,
  PRIMARY KEY (scope, subject_hash, window_started_at)
);

CREATE INDEX IF NOT EXISTS api_rate_limits_expiry_idx
  ON api_rate_limits (expires_at);
