ALTER TABLE leaderboard_profiles
  ADD COLUMN IF NOT EXISTS moderation_status TEXT NOT NULL DEFAULT 'active',
  ADD COLUMN IF NOT EXISTS moderated_at TIMESTAMPTZ;

ALTER TABLE leaderboard_profiles
  DROP CONSTRAINT IF EXISTS leaderboard_profiles_moderation_status_check;
ALTER TABLE leaderboard_profiles
  ADD CONSTRAINT leaderboard_profiles_moderation_status_check
  CHECK (moderation_status IN ('active', 'hidden'));

ALTER TABLE leaderboard_reports
  ADD COLUMN IF NOT EXISTS review_status TEXT NOT NULL DEFAULT 'open',
  ADD COLUMN IF NOT EXISTS review_action TEXT,
  ADD COLUMN IF NOT EXISTS reviewed_at TIMESTAMPTZ;

ALTER TABLE leaderboard_reports
  DROP CONSTRAINT IF EXISTS leaderboard_reports_review_status_check;
ALTER TABLE leaderboard_reports
  ADD CONSTRAINT leaderboard_reports_review_status_check
  CHECK (review_status IN ('open', 'dismissed', 'actioned'));

ALTER TABLE leaderboard_reports
  DROP CONSTRAINT IF EXISTS leaderboard_reports_review_action_check;
ALTER TABLE leaderboard_reports
  ADD CONSTRAINT leaderboard_reports_review_action_check
  CHECK (review_action IS NULL OR review_action IN ('dismissed', 'profile_hidden', 'profile_restored'));

CREATE INDEX IF NOT EXISTS leaderboard_reports_queue_idx
  ON leaderboard_reports (review_status, created_at DESC);
CREATE INDEX IF NOT EXISTS leaderboard_profiles_moderation_idx
  ON leaderboard_profiles (moderation_status, moderated_at DESC);
