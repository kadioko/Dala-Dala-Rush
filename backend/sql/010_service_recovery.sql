ALTER TABLE cloud_saves ADD COLUMN IF NOT EXISTS operation_id UUID;

ALTER TABLE installations ADD COLUMN IF NOT EXISTS leaderboard_hidden_until TIMESTAMPTZ;
ALTER TABLE installations ADD COLUMN IF NOT EXISTS leaderboard_left BOOLEAN NOT NULL DEFAULT FALSE;
UPDATE installations AS installation
SET leaderboard_hidden_until = COALESCE(profile.moderated_at, NOW()) + INTERVAL '90 days'
FROM leaderboard_profiles AS profile
WHERE profile.installation_id = installation.id
  AND profile.moderation_status = 'hidden'
  AND installation.leaderboard_hidden_until IS NULL;

ALTER TABLE telemetry_events ADD COLUMN IF NOT EXISTS event_id UUID;
CREATE UNIQUE INDEX IF NOT EXISTS telemetry_events_installation_event_idx
  ON telemetry_events (installation_id, event_id);
