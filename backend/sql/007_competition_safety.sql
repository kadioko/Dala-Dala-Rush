ALTER TABLE leaderboard_profiles
  ADD COLUMN IF NOT EXISTS report_token UUID;

UPDATE leaderboard_profiles
SET report_token = gen_random_uuid()
WHERE report_token IS NULL;

ALTER TABLE leaderboard_profiles
  ALTER COLUMN report_token SET DEFAULT gen_random_uuid(),
  ALTER COLUMN report_token SET NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS leaderboard_profiles_report_token_idx
  ON leaderboard_profiles (report_token);

CREATE TABLE IF NOT EXISTS leaderboard_blocks (
  blocker_installation_id UUID NOT NULL REFERENCES installations(id) ON DELETE CASCADE,
  blocked_installation_id UUID NOT NULL REFERENCES installations(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (blocker_installation_id, blocked_installation_id),
  CHECK (blocker_installation_id <> blocked_installation_id)
);

CREATE TABLE IF NOT EXISTS leaderboard_reports (
  id BIGSERIAL PRIMARY KEY,
  reporter_installation_id UUID NOT NULL REFERENCES installations(id) ON DELETE CASCADE,
  reported_installation_id UUID REFERENCES installations(id) ON DELETE SET NULL,
  reported_name VARCHAR(16) NOT NULL,
  reason VARCHAR(24) NOT NULL CHECK (reason IN ('impersonation', 'offensive_name', 'other')),
  route_id VARCHAR(24) NOT NULL CHECK (route_id IN ('kariakoo', 'mwenge', 'mbezi', 'posta', 'kigamboni', 'ubungo')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  reviewed_at TIMESTAMPTZ,
  UNIQUE (reporter_installation_id, reported_installation_id)
);

CREATE INDEX IF NOT EXISTS leaderboard_reports_review_idx
  ON leaderboard_reports (reviewed_at, created_at);
CREATE INDEX IF NOT EXISTS leaderboard_reports_retention_idx
  ON leaderboard_reports (created_at);
