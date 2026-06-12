# Dala Dala Rush TZ - Upgrade Notes (Changelog)

## Wave 3 — "10x" feature wave (latest)

**Core loop rework — vituo:**
- Passengers now board the bus (capacity 8 + overload 4, HUD 👤 X/12).
- Roadside bus stops (vituo) every 20–32 s: stop in the adjacent lane to
  drop all passengers for fares (+overload premium) and board the queue.
- Overload effects: heavier lane switching, faster fuel drain, police
  checkpoint fines per excess passenger.
- Game over shows dropoffs + fares; first kituo arrives at 9 s to teach.

**New systems:**
- Missions: 3 rotating from a 12-template pool, persistent progress,
  coin + season-XP rewards; season levels pay coins; missions screen.
- Livery editor: body/accent palettes, 4 patterns, slogan presets +
  custom, per-vehicle persistence, WhatsApp share, drawn in-game.
- Living city: per-run day/dusk/night/rain + rush hour; headlight cones,
  rain particles + slippery steering, denser rush traffic, condition
  banner during countdown; music pitch rises with run intensity.
- Police chase boss event (~every 35–55 s, 50%): cop tracks your lane for
  10 s; caught = fine, escape = reward + achievement.
- Ghost racing: best-run lane timeline recorded; translucent ghost bus;
  beat it for +150; export/import ghost codes (clipboard, offline) from
  the Leaderboard screen; Settings toggle.
- Career: 6 ranks (Konda → Mfalme wa Barabara) from lifetime XP with
  rank-up coin rewards on the menu; 3-level bus upgrades in the shop
  (Engine +4% score/lvl, Brakes +1 s slow-mo/lvl, Sound +2 coins/kituo/lvl).
- Scaffolds: IapService (Play Billing seam + carrier billing docs),
  AnalyticsService (offline event queue, run_end instrumented),
  RemoteConfig (hosted JSON + cache). Registered as autoloads.
- 2 new achievements (People's Champion, The Great Escape); voice-line
  hooks (voice_twende/mwisho/mafuta/kituo); How-To-Play tips 7–8.

## Wave 2 — polish/retention wave

- Audio: file-based loading (`audio/*.ogg`) with improved procedural
  fallbacks (two-tone horn, noise crash, arpeggio coin) + generated
  looping chiptune music + 5-voice SFX polyphony.
- Ads: async AdMob adapter w/ signals, editor simulation mode, buttons
  hide when unavailable; real continue restores run state + grace shield.
- Sprites: drop-in PNG override pipeline (`sprites/`, SpriteLib).
- Android: hardware back button routing, notch safe-area insets, expanded
  device-QA checklist.
- Route progression: unlock gates (route-goal totals or coin price),
  grandfathering migration, locked-route UI.
- Obstacle movement: bodabodas weave, goats wander across the road.
- Coin trails (4–6 coin runs, 35% of pickup spawns).
- Streak: 7-day reward calendar popup.
- Shop consumables: head-start shield / extra horn / reserve fuel,
  auto-used next run.
- Save hardening: .bak rotation + corruption recovery.

## Wave 1 — gameplay/UX wave

- Real ad-continue with banked-stat accounting (no double counting).
- Real speed boost (3 s, +45%, smash-through), goat obstacle (mbuzi),
  Simba Express + Bongo Flava vehicles, boost/streak achievements.
- Juice: lane-change tilt, crash hit-stop + particle bursts, coin
  sparkles, combo label punch.
- Daily login streak with escalating rewards.
- Fixes: `seed` shadowing, screen-shake tween overlap, dead code.

## Pre-wave MVP (original)

- 3-lane runner, 6 routes with weights/goals, 6 vehicles with perks,
  daily challenges, achievements, local leaderboard, stats, sw/en
  localization, haptics, ad placeholders, procedural everything.

---

## Balancing Notes (current values)

Run economy:
- Base speed `340 × route.difficulty`, +15% every 20 s.
- Score = distance × 0.1; engine upgrade adds +4%/lvl to distance gain.
- Coin pickups: 1 + combo bonus, × vehicle `coin_mult`.

Vituo loop (constants atop `scripts/game.gd`):
- `CAPACITY 8`, `OVERLOAD_MAX 4`.
- Fares: `FARE_NORMAL 2`, `FARE_OVERLOAD 3` (+2/lvl sound upgrade per stop).
- Overload: `OVERLOAD_HANDLING 0.07` lane-time/excess,
  `OVERLOAD_FUEL 0.04` drain/excess, `POLICE_FINE_PER_EXCESS 5`.
- Kituo gap 20–32 s; waiting 2–5; boards up to 8 (overload only via
  roadside pickups — deliberate player choice).

Chase: every 35–55 s @50% after 40 s; 10 s duration; caught after 2.2 s
in-lane = 15 + overload fines; escape = +25.

Conditions: day 40% / dusk 20% / night 20% / rain 20%; rush 25%
(spawn ×0.85). Rain lane-time ×1.18.

Power-ups: magnet 6 s, slow 4 s (+1 s/brake lvl), boost 3 s ×1.45.

Economy sinks: vehicles 150–1600, route unlocks 150–1400, upgrades
150–1100, consumables 25–40. Sources: pickups, fares, goals 35–100,
daily 60–100, missions 25–80, streak 10–60, season levels 30×level,
rank-ups 50×rank.

## Route Personality & Goals

Unchanged from MVP (see `data/routes.gd`): Kariakoo passengers/bajaji,
Mwenge bodaboda, Mbezi trucks/distance, Posta checkpoints/score,
Kigamboni potholes/coins (+goats), Ubungo jams/score. Goats also roam
Kariakoo.

## UX Notes

- Swahili remains default; humor in short lines.
- No real brands/operators/logos; police content family-friendly.
- New-player path: Kariakoo (the only unlocked route) → first kituo at
  9 s teaches the loop → goal completion unlocks Mwenge.
