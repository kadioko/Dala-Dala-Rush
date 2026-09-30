CREATE TABLE IF NOT EXISTS leaderboard_profiles (
  installation_id UUID PRIMARY KEY REFERENCES installations(id) ON DELETE CASCADE,
  display_name VARCHAR(16) NOT NULL CHECK (char_length(display_name) BETWEEN 2 AND 16),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS leaderboard_scores_route_installation_score_idx
  ON leaderboard_scores (route_id, installation_id, score DESC, created_at ASC);

CREATE TABLE IF NOT EXISTS leaderboard_friend_invites (
  code_hash TEXT PRIMARY KEY,
  owner_installation_id UUID NOT NULL REFERENCES installations(id) ON DELETE CASCADE,
  expires_at TIMESTAMPTZ NOT NULL,
  claimed_by_installation_id UUID REFERENCES installations(id) ON DELETE SET NULL,
  claimed_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS leaderboard_friend_invites_expiry_idx
  ON leaderboard_friend_invites (expires_at);

CREATE TABLE IF NOT EXISTS leaderboard_friendships (
  first_installation_id UUID NOT NULL REFERENCES installations(id) ON DELETE CASCADE,
  second_installation_id UUID NOT NULL REFERENCES installations(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (first_installation_id, second_installation_id),
  CHECK (first_installation_id < second_installation_id)
);
CREATE INDEX IF NOT EXISTS leaderboard_friendships_second_idx
  ON leaderboard_friendships (second_installation_id);
