# Dala Dala Rush TZ 🚌

A Tanzanian daladala endless runner built with **Godot 4.6**.
Drive your dala dala through Dar es Salaam: board abiria, stop at **vituo**
for fares, overload at your own risk, dodge bodabodas and goats, escape
police chases — then paint your bus with a proper slogan and share it.

**Offline-first**: the whole game runs with zero network and zero binary
assets. All art is code-drawn and all audio is synthesized; drop real
sprites/sounds into `sprites/` and `audio/` and they're used automatically.

---

## Feature Overview

### Core loop — the daladala fantasy
- 3-lane runner: swipe / lane buttons / keyboard.
- **Passenger system**: riders board your bus (8 seats, HUD shows 👤 X/12).
  Roadside **bus stops (vituo)** appear with a pulsing marker — drive the
  adjacent lane as you pass to drop everyone for fares and board the queue.
- **Overloading**: roadside pickups beyond 8 seats pay premium fares but
  steering gets heavier, fuel burns faster, and passing a police checkpoint
  costs a fine per excess passenger. Risk vs reward every run.
- 11 obstacle types incl. weaving bodabodas and road-crossing **mbuzi**
  (goats); coin trails; near-miss bonuses; combo multipliers.
- Power-ups: shield, magnet, slow-mo, and a speed boost that smashes traffic.
- **Horn (pembe)** with charges that clears your lane.
- Fuel management with low-fuel warnings.
- **Police chase boss moments**: weave to escape for a reward, get caught
  for a fine.
- **Living city**: each run rolls day/dusk/night/rain (+25% rush hour) —
  night headlights, slippery rain, denser rush traffic. Per-route parallax
  scenery (Kariakoo stalls, Posta offices, Kigamboni palms, Ubungo overpass).
- Juice: hit-stop, particles, camera shake, lane-tilt, countdown, music
  that intensifies with speed.

### Progression & retention
- **6 routes** with unique traffic, goals, and unlock gates (goal progress
  or coin purchase).
- **8 vehicles** with perks + permanent **bus upgrades** (engine / brakes /
  sound system, 3 levels each).
- **Livery editor**: body/accent colors, patterns (stripe/flames/checker),
  slogans ("MUNGU ATUBARIKI", "SIMBA DAMU"…), WhatsApp share.
- **Career ranks**: Konda → Mfalme wa Barabara with rank-up rewards.
- **Missions** (3 rotating) + **season XP track** with level rewards.
- **Daily challenge** + **login streak** with a 7-day reward calendar.
- **Ghost racing**: race your best run's ghost; share/import **ghost codes**
  via clipboard/WhatsApp — competitive play with zero servers.
- 14 achievements with toasts, local top-5 leaderboard, lifetime stats.
- One-run **consumables** in the shop (head-start shield, extra horn,
  reserve fuel).
- Full **Swahili (default) + English** localization, switchable live.

### Monetization & live ops (scaffolded, offline-safe)
- Rewarded ads: continue-after-crash (restores your run!) and double-coins.
  AdMob adapter with editor simulation — `docs/ADMOB_SETUP.md`.
- IAP catalog + Play Billing seam, incl. **TZ carrier billing** notes —
  `docs/MONETIZATION.md`.
- Remote config (hosted JSON, cached) + offline analytics event queue —
  `docs/LIVE_OPS.md`.

---

## Quick Start

| Tool | Version |
|------|---------|
| Godot Engine | 4.6+ (standard GDScript build) |
| Android SDK | API 21+ (export only) |
| JDK | 17+ (export only) |

1. [Download Godot 4](https://godotengine.org/download/), **Import** this
   folder's `project.godot`, press **F5**.
2. Keyboard: **A/D** or **←/→** to steer, **Esc** to pause.
3. Android: see `docs/ANDROID_EXPORT.md` (incl. on-device test checklist,
   back-button behavior, notch safe-areas).

---

## Project Structure

```
├── project.godot          # Config, autoloads, input map
├── autoload/              # Singletons
│   ├── save_system.gd     #   JSON save + .bak corruption recovery
│   ├── locale_manager.gd  #   sw/en strings (single source of truth)
│   ├── audio_manager.gd   #   file-based audio w/ procedural fallback + music loop
│   ├── game_state.gd      #   run results, ad-continue state, mission hookup
│   ├── achievement_manager.gd  # unlocks + toast queue
│   ├── transition_manager.gd   # scene fades + Android back button
│   ├── feedback_manager.gd     # haptics
│   ├── ad_service.gd      #   AdMob seam (simulated in debug builds)
│   ├── iap_service.gd     #   Play Billing seam
│   ├── analytics_service.gd    # offline event queue → SDK seam
│   └── remote_config.gd   #   hosted-JSON tuning w/ local cache
├── data/                  # Pure data catalogs
│   ├── routes.gd          #   6 routes: weights, goals, unlock gates
│   ├── vehicles.gd        #   8 vehicles with perks
│   ├── consumables.gd     #   one-run shop items
│   ├── missions.gd        #   mission templates + season track
│   ├── career.gd          #   ranks + bus upgrades
│   ├── daily_challenges.gd
│   └── login_streak.gd
├── scripts/
│   ├── game.gd            # ← core loop: vituo, chase, ghost, conditions, spawning
│   ├── livery_lib.gd      #   shared bus painter (player + editor + ghost)
│   ├── sprite_lib.gd      #   optional PNG override loader
│   ├── entities/          #   player, obstacle, collectible, kituo, road
│   ├── effects/           #   speed lines
│   └── *_screen.gd        #   menu, garage, livery, shop, routes, missions,
│                          #   stats, leaderboard (ghost codes), settings, etc.
├── scenes/                # Minimal .tscn files (UI is built in code)
├── docs/                  # All guides — see index below
├── sprites/               # (optional) PNG overrides — docs/SPRITES.md
└── audio/                 # (optional) real audio — docs/AUDIO_ASSETS.md
```

## Docs Index

| Doc | What's in it |
|-----|--------------|
| `docs/ROADMAP.md` | Status by area + path to launch |
| `docs/UPGRADES.md` | Changelog of implemented systems + balancing notes |
| `docs/CONTENT_GUIDE.md` | How to add routes/vehicles/obstacles/missions/etc. |
| `docs/ANDROID_EXPORT.md` | Export setup + on-device QA checklist |
| `docs/ADMOB_SETUP.md` | Rewarded ads go-live steps |
| `docs/MONETIZATION.md` | IAP, carrier billing (TZ), season pass plan |
| `docs/LIVE_OPS.md` | Remote config, analytics, cloud save path |
| `docs/SPRITES.md` | Sprite filenames/sizes for the art pass |
| `docs/AUDIO_ASSETS.md` | Audio filenames/specs incl. Swahili voice lines |

---

## Replacing Placeholder Art & Audio

Both systems are **drop-in** — no code changes:

- **Sprites**: put PNGs in `sprites/` named like `vehicle_classic_blue.png`,
  `obstacle_mbuzi.png`, `collectible_coin.png`, `obstacle_kituo.png`.
  Anything missing keeps its vector art. Full list: `docs/SPRITES.md`.
- **Audio**: put OGGs in `audio/` named `coin.ogg`, `horn.ogg`, `music.ogg`,
  `voice_mwisho.ogg`… Anything missing keeps its synthesized fallback.
  Full list: `docs/AUDIO_ASSETS.md`.

## Tuning

Gameplay constants are named and grouped at the top of `scripts/game.gd`
(fares, overload penalties, chase timing, kituo cadence, boost, fuel).
Catalog numbers live in `data/`. Remote-tunable knobs go through
`autoload/remote_config.gd`.

## Save Data

`user://save.json` with automatic `.bak` rotation and corruption recovery.
On Windows during development:
`%APPDATA%\Godot\app_userdata\Dala Dala Rush TZ\save.json`.

---

*Godot 4 · GDScript · No third-party dependencies · Works fully offline ·
Swahili-first · No brands, no gambling, family-friendly*
