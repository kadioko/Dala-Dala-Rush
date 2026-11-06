CREATE TABLE IF NOT EXISTS hub_elections (
  election_id TEXT PRIMARY KEY,
  title_key TEXT NOT NULL,
  opens_at TIMESTAMPTZ NOT NULL,
  closes_at TIMESTAMPTZ NOT NULL,
  candidates JSONB NOT NULL CHECK (jsonb_typeof(candidates) = 'array'),
  CHECK (closes_at > opens_at)
);

INSERT INTO hub_elections (election_id, title_key, opens_at, closes_at, candidates)
VALUES (
  'dala_world_head_s1',
  'ELECTION_TITLE_S1',
  NOW(),
  NOW() + INTERVAL '30 days',
  '[
    {"id":"konda_juma","nameKey":"ELECTION_CANDIDATE_JUMA","roleKey":"ELECTION_ROLE_CONDUCTOR"},
    {"id":"fundi_rehema","nameKey":"ELECTION_CANDIDATE_REHEMA","roleKey":"ELECTION_ROLE_MECHANIC"},
    {"id":"mama_tunu","nameKey":"ELECTION_CANDIDATE_TUNU","roleKey":"ELECTION_ROLE_VENDOR"}
  ]'::jsonb
)
ON CONFLICT (election_id) DO NOTHING;

CREATE TABLE IF NOT EXISTS hub_election_votes (
  election_id TEXT NOT NULL REFERENCES hub_elections(election_id) ON DELETE CASCADE,
  installation_id UUID NOT NULL REFERENCES installations(id) ON DELETE CASCADE,
  candidate_id TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (election_id, installation_id)
);

CREATE INDEX IF NOT EXISTS hub_election_tally_idx
  ON hub_election_votes (election_id, candidate_id);

CREATE INDEX IF NOT EXISTS hub_elections_retention_idx
  ON hub_elections (closes_at);
