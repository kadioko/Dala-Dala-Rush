CREATE TABLE IF NOT EXISTS account_transfers (
  code_hash TEXT PRIMARY KEY,
  installation_id UUID NOT NULL REFERENCES installations(id) ON DELETE CASCADE,
  expires_at TIMESTAMPTZ NOT NULL,
  claimed_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS account_transfers_expiry_idx
  ON account_transfers (expires_at);
