# Content Guide

Last verified: August 19, 2026.

This project is designed so most new content can be added through small data/script edits.

## Add a Route

1. Add a route entry in `data/routes.gd`.
2. Add a route name key in both locale dictionaries in `autoload/locale_manager.gd`.
3. If the route needs a unique visual identity, update `scripts/entities/road.gd`.
4. Optional unlock gate: add `"unlock_goals": N` (total route-goal
   completions needed) and `"unlock_price": C` (instant coin unlock).
   Omit both for a free route.

Example:

```gdscript
{
	"id": "temeke",
	"name_key": "ROUTE_TEMEKE",
	"difficulty": 1.35,
	"spawn_interval_mult": 0.98,
	"sky": Color("#f8c291"),
	"road": Color("#30336b"),
	"flavor_key": "ROUTE_TEMEKE_D",
	"goal_key": "GOAL_TEMEKE",
	"goal_type": "score",
	"goal_target": 900,
	"goal_reward": 60,
	"obstacle_weights": {
		"bodaboda": 12, "bajaji": 12, "car": 14, "pothole": 12, "cone": 8,
		"police": 6, "barrier": 8, "truck": 10, "pedestrian": 8, "tire": 10,
	},
	"collectible_weights": {
		"coin": 55, "passenger": 20, "fuel": 10, "shield": 5,
		"magnet": 4, "speed_boost": 3, "slow": 3,
	},
}
```

`obstacle_weights` and `collectible_weights` do not need to add to 100. They are relative weights.
For example, if `truck` is twice as high as `car`, trucks are roughly twice as likely as cars.
Use `spawn_interval_mult` above `1.0` for calmer routes and below `1.0` for busier routes.

Route goals support these `goal_type` values:

- `score`
- `coins`
- `distance`
- `near_misses`
- `passengers`

Add the matching `goal_key` text in both Swahili and English locale dictionaries.

## Fairness And Localization Rules

- Keep at least one lane free in each obstacle wave. `game.gd` enforces this;
  do not add a route rule that blocks all three lanes.
- Keep new obstacle weights compatible with the 12-second beginner window.
  Add early hazards to the starter allow-list only after playtesting.
- New direct UI copy needs entries in both `"sw"` and `"en"` dictionaries.
  Swahili is the runtime fallback, but both entries are required before release.
- Keep central launch copy at 10 characters or fewer and preparation copy at
  16 or fewer. Test both languages before changing `PREP`, `GO_TEXT`, route
  goals, or early-run status messages.
- Pickups spawned independently of a wave use a clear lane check. Preserve that
  behavior when adding collectible types or movement patterns.
- Forced two-lane waves must keep the next safe lane current or adjacent; do
  not introduce patterns that require an instant far-left to far-right move.
- Pool setup must reset transform, modulation, depth, and animation state. New
  entity effects cannot assume they start from constructor defaults.
- Only coins respond to the magnet unless the design and localized copy are
  intentionally changed together.

## Add a Daily Challenge

Open `data/daily_challenges.gd` and append to `LIST`:

```gdscript
{
	"id": "daily_fuel_run",
	"key": "DAILY_FUEL_RUN",
	"type": "distance",
	"target": 2500,
	"reward": 90,
}
```

Supported `type` values are the same as route goals: `score`, `coins`, `distance`, `near_misses`, and `passengers`.
Add the `key` text in both locale dictionaries.

## Add a Vehicle

1. Add a vehicle entry in `data/vehicles.gd`.
2. Add the vehicle name key in Swahili and English in `autoload/locale_manager.gd`.
3. Pick a fair coin price. Early unlocks should stay cheap so players feel progress quickly.

Example:

```gdscript
{
	"id": "temeke_green",
	"name_key": "VEH_TEMEKE_GREEN",
	"price": 1200,
	"body": Color("#00b894"),
	"accent": Color("#fdcb6e"),
	"lane_time": 0.13,
	"fuel_drain_mult": 0.95,
	"coin_mult": 1.08,
	"horn_charges": 3,
}
```

Vehicle perk fields:

- `lane_time`: lower means faster lane changes.
- `fuel_drain_mult`: lower means better fuel economy.
- `coin_mult`: higher means more coins per coin pickup.
- `horn_charges`: starting and maximum horn uses.

## Add an Obstacle

1. Add a type to `scripts/entities/obstacle.gd` in `TYPES`.
2. Add a drawing case in `_draw()` if the generic vehicle shape is not enough.
3. Add the id to `OBSTACLE_TYPES` in `scripts/game.gd`.
4. Add How To Play copy if players need to recognize it quickly.

## Add a Collectible or Power-up

1. Add a type to `scripts/entities/collectible.gd`.
2. Add the effect in `scripts/game.gd` inside `_on_collect()`.
3. Add labels/descriptions in `autoload/locale_manager.gd`.
4. Consider haptics: call `FeedbackManager.collect()` or `FeedbackManager.powerup()`.
5. Keep pickup corridors clear of active obstacles and reset all visual state
   when pooled instances are reused.

## Add a Language

1. Add a new locale block in `autoload/locale_manager.gd`.
2. Copy all keys from `en` first, then translate.
3. Update Settings if you want a third button instead of the current Swahili/English selector.
4. Test every menu after switching language.

## Add a Mission

Open `data/missions.gd` and append to `TEMPLATES`:

```gdscript
{"id": "m_drop_30", "key": "MIS_DROPOFFS", "type": "dropoffs",
 "target": 30, "reward": 90, "xp": 60},
```

Mission `type` values: `coins`, `passengers`, `distance`, `near_misses`,
`dropoffs`, `fares`, `horn_uses`, `boosts` (cumulative across runs), and
`score_best` (best single run). Reuse an existing `key` or add a new one
to both locales (use `{n}` for the target).

## Add a Consumable (one-run item)

1. Append to `LIST` in `data/consumables.gd` (id, name/desc keys, price, icon).
2. Apply its effect in `scripts/game.gd` → `_apply_consumables()`.
3. Add locale keys. It appears in the shop automatically.

## Add a Bus Upgrade

1. Append to `UPGRADES` in `data/career.gd` (id, keys, icon, 3 costs).
2. Read `Career.upgrade_level("your_id")` in `game.gd` and apply the effect.
3. Add locale keys. The shop row renders automatically.

## Add a Career Rank

Append to `RANKS` in `data/career.gd` with an XP threshold and add the
`RANK_N` key to both locales. XP sources are defined in `career_xp()`.

## Add Livery Options

`scripts/livery_lib.gd`: extend `BODY_PALETTE` / `ACCENT_PALETTE` /
`SLOGAN_PRESETS` freely. New patterns need an entry in `PATTERNS`, a
draw case in `draw_bus()`, and a `PATTERN_X` locale key.

## Add a Voice Line

Drop `audio/voice_yourkey.ogg`, add `"voice_yourkey"` to `VOICE_KEYS` in
`autoload/audio_manager.gd`, and call
`AudioManager.play_sfx("voice_yourkey")` at the trigger point. Voice keys
are file-only — silent until the recording exists.

## Remote-Tunable Values

To make any number tunable without an app update: add a default to
`DEFAULTS` in `autoload/remote_config.gd` and read it at the point of use
with `RemoteConfig.get_value("key", default)`. See docs/LIVE_OPS.md.

## Save Mutations

Single changes can call `SaveSystem.set_value()` or another typed helper
directly. Wrap multi-step rewards, purchases, unlocks, or migrations with
`SaveSystem.begin_batch()` and `SaveSystem.end_batch()` so they commit once.
Every success and failure return path must close the batch. Batches may nest.

## Ghost Data

Treat imported ghost codes as untrusted input. Encode and decode only through
`data/ghost_data.gd`; do not parse clipboard JSON directly. New ghost event
fields must retain duration, count, lane-range, numeric, and ordering limits,
and must be covered by `tests/logic_contracts.gd`.

## Referral Rewards

Referral rules live in `data/referrals.gd`; the screen only presents results.
Keep welcome and inviter rewards positive, keep `MAX_REFERRAL_REWARDS` at 20 or
below for an offline build, and update both locale dictionaries when changing
the explanation. Never pay for tapping Share alone.

Treat invite and confirmation codes as untrusted text. Always normalize and
validate through `Referrals`, preserve self/duplicate/owner checks, and wrap
multi-field rewards in a save batch. Add matching cases to
`tests/logic_contracts.gd` whenever the code format or payout rules change.

For uncapped campaigns, valuable rewards, or automatic install attribution,
replace local confirmation with server verification. Do not collect contacts or
phone numbers merely to simplify referrals.

## Content Tone

- Keep names local and playful.
- Do not use real bus company logos or copyrighted brands.
- Keep police/checkpoint jokes family-friendly.
- Short Swahili UI strings work best on small phones.
