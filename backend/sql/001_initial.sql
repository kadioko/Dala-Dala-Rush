CREATE TABLE IF NOT EXISTS installations (
  id UUID PRIMARY KEY,
  sync_token_hash TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_seen_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS cloud_saves (
  installation_id UUID PRIMARY KEY REFERENCES installations(id) ON DELETE CASCADE,
  revision BIGINT NOT NULL CHECK (revision >= 0),
  save_data JSONB NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS leaderboard_scores (
  id BIGSERIAL PRIMARY KEY,
  installation_id UUID NOT NULL REFERENCES installations(id) ON DELETE CASCADE,
  route_id TEXT NOT NULL CHECK (route_id IN ('kariakoo', 'mwenge', 'mbezi', 'posta', 'kigamboni', 'ubungo', 'arusha')),
  score INTEGER NOT NULL CHECK (score >= 0 AND score <= 2000000),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS leaderboard_scores_route_score_idx
  ON leaderboard_scores (route_id, score DESC, created_at ASC);

CREATE TABLE IF NOT EXISTS meaningful_runs (
  installation_id UUID PRIMARY KEY REFERENCES installations(id) ON DELETE CASCADE,
  route_id TEXT NOT NULL CHECK (route_id IN ('kariakoo', 'mwenge', 'mbezi', 'posta', 'kigamboni', 'ubungo', 'arusha')),
  distance INTEGER NOT NULL CHECK (distance >= 0),
  duration_seconds INTEGER NOT NULL CHECK (duration_seconds >= 0),
  qualified_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS referral_invites (
  code TEXT PRIMARY KEY,
  owner_installation_id UUID NOT NULL REFERENCES installations(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  disabled_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS referral_activations (
  id BIGSERIAL PRIMARY KEY,
  invite_code TEXT NOT NULL REFERENCES referral_invites(code) ON DELETE CASCADE,
  inviter_installation_id UUID NOT NULL REFERENCES installations(id) ON DELETE CASCADE,
  invitee_installation_id UUID NOT NULL UNIQUE REFERENCES installations(id) ON DELETE CASCADE,
  activated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (inviter_installation_id <> invitee_installation_id)
);
