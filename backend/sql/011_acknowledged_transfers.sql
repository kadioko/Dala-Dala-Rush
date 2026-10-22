ALTER TABLE account_transfers ADD COLUMN IF NOT EXISTS claim_operation_id UUID;
ALTER TABLE account_transfers ADD COLUMN IF NOT EXISTS claim_token_hash TEXT;
ALTER TABLE account_transfers ADD COLUMN IF NOT EXISTS acknowledged_at TIMESTAMPTZ;
CREATE UNIQUE INDEX IF NOT EXISTS account_transfers_claim_operation_idx
  ON account_transfers (claim_operation_id) WHERE claim_operation_id IS NOT NULL;
