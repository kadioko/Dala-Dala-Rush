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
	"mastery_scores": [500, 1000, 1800],
	"mastery_rewards": [15, 25, 45],
	"signature_id": "fare_rush",
	"signature_key": "ROUTE_MOMENT_FARE_RUSH",
	"signature_title_key": "MOMENT_FARE_RUSH",
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

### Route Job Profile

Every route must also include a small job profile so its personality changes
the run, not just the card copy. `passenger_interval_mult` controls how often
passenger opportunities return (lower is more frequent), `kituo_gap_mult`
controls the spacing of stops (lower is closer), and `fuel_drain_route_mult`
controls route-level fuel pressure (lower is more efficient). Keep each value
between `0.70` and `1.35`; the game clamps the live values to that fair range.

`rush_hour_chance` is a `0.0` to `1.0` chance applied after the early lessons.
`condition_weights` must contain positive relative weights for `day`, `dusk`,
`night`, and `rain`. Early guided runs always stay clear daytime, and saved
continues preserve their original weather and traffic state.

Route goals support these `goal_type` values:

- `score`
- `coins`
- `distance`
- `near_misses`
- `passengers`

Add the matching `goal_key` text in both Swahili and English locale dictionaries.

Each route must also declare one supported `signature_id` plus localized
`signature_key`, `signature_title_key`, and `signature_action_key`. The shipped
IDs are `fare_rush`, `boda_watch`, `truck_line`, `checkpoint_clear`,
`fuel_scout`, and `jam_breaker`. Signature moments should create a readable,
guaranteed opportunity or relief, never an unavoidable hazard. Add the gameplay
handling in `scripts/game.gd` → `_start_route_moment()` and add a logic contract
when introducing a new ID.

Each route also needs three increasing `mastery_scores` and three matching
`mastery_rewards`. The core rule is fixed: first star meets its score,
second meets its score and the route goal, third additionally earns an A
Driver Reputation. Rewards are paid only for newly saved stars, so repeat runs
cannot farm them.

`Routes.next_mastery_target()` derives the exact next requirement from that
data. It is used by route cards, the pre-run briefing, and results; do not
duplicate or hand-write a separate mastery requirement in UI code.

## Driver Reputation

Driver Reputation is a 0-100 feedback score, not a currency. Every run starts
at 50. Passenger drop-offs, passengers, near misses, a route goal, clean
checkpoints, and signature moments add points; missed stops, police fines,
an ordinary crash, and an empty-fuel finish subtract points. The result screen shows the localized
point ledger from `GameState.calculate_reputation()` so any formula change must
keep `base`, `positive_total`, `negative_total`, and their item values aligned.
The grade bands are A (85+), B (70+), C (50+), and D (below 50).

## Progressive Discovery

`GameState._queue_progress_discovery()` introduces one durable system at a time
on the result screen: full traffic, Mwenge, Route Mastery, changing conditions,
ghost races, and police chases. Discovery keys are allow-listed in
`SaveSystem.DISCOVERY_KEYS` and saved in `seen_discoveries`, so use a new key in
both language dictionaries before adding another milestone. A later milestone
must remain eligible on subsequent runs; do not make a one-time trigger that
can be hidden by a higher-priority discovery.

## Driving Flow

Driving Flow is the short `x1`-`x8` chain shown during a run. Coin pickups,
safe near-misses, and successful fare stops extend it; a fare stop counts as
two actions because it is the central service decision. Only coin pickup value
scales from the flow, so it must not be applied to fares, route rewards,
missions, ads, or permanent progression. `Game.next_combo()` owns the hard
`x8` cap, and the peak is preserved through a rewarded continue for results.

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

## Route Contracts

`data/route_contracts.gd` defines a rotating daily contract per route. They
unlock only after the first three completed runs, pay once per route per local
day, and are deliberately shown on route selection/results rather than the
driving HUD. Use existing stats (`fares`, `passengers`, `near_misses`,
`horn_uses`, `distance`, `score`, `clean_checkpoints`, `route_moments`,
`coins`, or `boosts`), then add both-language copy for its `key`.

Do not make contracts use a new currency, a countdown, or an unavoidable
traffic requirement. The permanent route goal remains the primary in-run goal;
contracts are a small replay reason once players understand the basics.

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

The Garage surfaces the strongest positive stat immediately after a purchase.
Keep at least one positive stat on every paid vehicle so that unlock message is
useful; add any new `VEHICLE_PERK_*` copy in Swahili and English only when a
new stat category is introduced.

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
