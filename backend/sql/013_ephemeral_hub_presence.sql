CREATE TABLE IF NOT EXISTS hub_presence (
  installation_id UUID PRIMARY KEY REFERENCES installations(id) ON DELETE CASCADE,
  district_id TEXT NOT NULL CHECK (district_id IN ('kariakoo')),
  player_x SMALLINT NOT NULL CHECK (player_x BETWEEN 0 AND 1000),
  player_y SMALLINT NOT NULL CHECK (player_y BETWEEN 0 AND 1000),
  vehicle_id TEXT NOT NULL CHECK (vehicle_id IN (
    'classic_blue', 'kariakoo_yellow', 'mwendokasi_red', 'night_bus',
    'vip', 'old_school', 'simba_express', 'bongo_flava'
  )),
  last_emote TEXT NOT NULL DEFAULT '',
  emote_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (last_emote IN ('', 'wave', 'horn', 'dance'))
);

CREATE INDEX IF NOT EXISTS hub_presence_district_seen_idx
  ON hub_presence (district_id, updated_at DESC);
