# Dala Dala Rush TZ 🚌

A Tanzanian daladala endless runner built with **Godot 4.7.1**.
Drive your dala dala through Dar es Salaam: board abiria, stop at **vituo**
for fares, overload at your own risk, dodge bodabodas and goats, escape
police chases — then paint your bus with a proper slogan and share it.

**Offline-first**: the whole game runs with zero network and zero binary
assets. All art is code-drawn and all audio is synthesized; drop real
sprites/sounds into `sprites/` and `audio/` and they're used automatically.

---

## Feature Overview

### Core loop — the daladala fantasy
- 3-lane runner: swipe / lane buttons / keyboard. The bottom driving dock
  keeps steering, horn, power-up state, and the bus visually separated on
  portrait screens.
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
- Juice: hit-stop, particles, camera shake, lane-tilt, a centered bilingual
  route briefing/countdown, and music
  that intensifies with speed.

### Progression & retention
- **7 routes across Dar and Arusha city packs** with unique traffic, goals, and unlock gates (goal progress
  or coin purchase), each with a favorable signature moment: fare rush,
  boda watch, truck line, clean checkpoint, fuel scout, jam breaker, or
  Arusha's Highland Pass.
- **8 vehicles** with perks + permanent **bus upgrades** (engine / brakes /
  sound system, 3 levels each).
- **Livery editor**: body/accent colors, patterns (stripe/flames/checker),
  slogans ("MUNGU ATUBARIKI", "SIMBA DAMU"…), WhatsApp share.
- **Career ranks**: Konda → Mfalme wa Barabara with rank-up rewards.
- **Missions** (3 rotating) + **persistent season chapters** and level/milestone
  rewards. Chapters do not expire; no premium pass or extra currency exists.
- **Daily challenge** + **login streak** with a 7-day reward calendar.
- **Ghost racing**: race your best run's ghost; share/import **ghost codes**
  via clipboard/WhatsApp — competitive play with zero servers. Daily rivals
  must match the date, route, starter vehicle, and traffic seed; daily passes
  give no extra score. Clips are friendly comparisons, not verified score proof.
- **Leaderboards**: set a real driver name once, view route-specific personal
  bests offline, then optionally join Friends and World boards. Friend codes
  last 24 hours; online scores are never reward-bearing and remain labelled
  unverified until server-side run validation exists. Route-best uploads retry
  safely, standings are cached, and public competition can be left and deleted
  without affecting offline progress.
- **Daily Run**: a same-rules daily route with a shared traffic seed, starter
  dala, and no-revive policy makes local score comparisons more meaningful.
- **Invite & Earn**: offline referral codes reward the invited player with 75
  coins and the inviter with 125 after a one-time confirmation. Self-referrals,
  duplicate confirmations, and repeated welcome claims are blocked locally;
  confirmed-friend milestones add 100, 200, and 500 coins at 3, 5, and 10.
- 14 achievements with toasts, local top-5 leaderboard, lifetime stats.
- One-run **consumables** in the shop (head-start shield, extra horn,
  reserve fuel).
- Full **Swahili (default) + English** localization, switchable live.
- Compact settings with a saved **Reduced Effects** mode for motion comfort,
  battery life, and lower-end Android phones.
- Three persistent, non-modal first-session lessons: steering and coins, then
  passengers and a stop, then horn and slow motion. Existing player saves skip
  them automatically.
- **Driver Reputation** turns passenger service, close calls, clean checkpoints,
  route moments, missed stops, and fines into a simple A-D end-of-run rating.
- **Route Mastery** gives every route three permanent performance stars and a
  one-time coin reward per star: score, score plus route goal, then score plus
  route goal with an A Driver Reputation.
- The next Route Mastery target stays visible on the route card, in the pre-run
  briefing, and on results so the player always knows what the next run is for.

### Monetization and live ops
- AdMob is integrated for rewarded revive, rewarded double coins,
  interstitials after 2-3 completed runs, and banners on menu/results only.
  Editor debug builds simulate ads; Android builds use the installed SDK.
- Deferred IAP catalog + Play Billing seam, including **TZ carrier billing**
  notes. No real-money purchases are enabled — `docs/MONETIZATION.md`.
- Remote config (hosted JSON, cached) + privacy-filtered offline analytics
  journal — `docs/LIVE_OPS.md`.

---

## Quick Start

| Tool | Version |
|------|---------|
| Godot Engine | 4.7.1 (standard GDScript build) |
| Android SDK | Min API 24, target API 36 (export only) |
| JDK | 17+ (export only) |

1. [Download Godot 4](https://godotengine.org/download/), **Import** this
   folder's `project.godot`, press **F5**.
2. Keyboard: **A/D** or arrow keys to steer, **H** for horn, **Esc** to pause.
3. Android: see `docs/ANDROID_EXPORT.md` (incl. on-device test checklist,
   back-button behavior, notch safe-areas).

## Current Build Notes

- The project is validated with Godot 4.7.1 in headless scene startup checks.
- A headless logic-contract suite now verifies localization parity, catalog
  integrity, save repair, selection guards, rewarded-claim idempotency, ghost
  validation, referral reward integrity, tutorial progression, remote-tuning
  safeguards, and the gameplay distance scale.
- Google Play production is active. The current signed production-track update
  is version `1.0.13`, code `14`. The next release candidate is `1.0.14`, code
  `15`, with the signed bundle at `exports/android/DalaDalaRushTZ-production-v14.aab`. It adds reliable
  leaderboard upload states, request/score safeguards, daily-run and route
  progression polish, and the remote-config URL fix. Play processing and phone
  checks remain release gates for this candidate.
- Android export is configured for package `com.kadioko.daladalarush`, minimum
  API 24, target API 36, Gradle custom build, and AAB output.
- AdMob is wired with production unit IDs; real-device loading, consent, and
  placement QA remain release checks.
- Swahili and English are complete locale sets; English falls back to Swahili
  if a future key is missing.
- The match start uses natural `JIANDOE / TWENDE` and `GET READY / GO` cues,
  hides the live HUD until control begins, and scales safely on narrow screens.
- Route Contracts, seasonal events, and daily equal-rules runs are included in
  this build. The optional online services are enabled for phone validation,
  but remain opt-in and must complete the two-phone checklist before broad
  rollout.
- Wave 27 adds deployed Railway cloud backup with explicit consent, restore,
  deletion, and phone transfer. It never uploads a save until the player turns
  on Cloud Backup in Settings.
- Wave 28 adds Personal, Friends, and World leaderboard support with a separate
  competition consent and public driver name. Rankings are unverified and have
  no prizes; players can leave competition and delete their public profile.
- Store-listing drafts are under `assets/store_listing/`; recapture screenshots
  after the final UI pass before uploading the next release.
- See `docs/ROADMAP.md` for launch work remaining and `docs/UPGRADES.md` for
  the current implementation changelog.

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
│   ├── ad_service.gd      #   AdMob SDK bridge + placement policy
│   ├── iap_service.gd     #   Play Billing seam
│   ├── analytics_service.gd    # offline event queue → SDK seam
│   └── remote_config.gd   #   hosted-JSON tuning w/ local cache
│   └── online_service.gd  #   consent-gated Railway cloud/referral/leaderboard seam
├── data/                  # Pure data catalogs
│   ├── routes.gd          #   7 routes: weights, goals, unlock gates
│   ├── vehicles.gd        #   8 vehicles with perks
│   ├── consumables.gd     #   one-run shop items
│   ├── missions.gd        #   mission templates + season track
│   ├── career.gd          #   ranks + bus upgrades
│   ├── ghost_data.gd      #   bounded validation + sharing codec
│   ├── referrals.gd       #   offline invite + confirmation reward rules
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
├── tests/                 # Headless gameplay/data contract checks
├── docs/                  # All guides — see index below
├── sprites/               # (optional) PNG overrides — docs/SPRITES.md
└── audio/                 # (optional) real audio — docs/AUDIO_ASSETS.md
```

## Docs Index

| Doc | What's in it |
|-----|--------------|
| `docs/ROADMAP.md` | Current status, release priorities, and remaining work |
| `docs/UPGRADES.md` | Changelog of implemented systems + balancing notes |
| `docs/SACCO_CREWS_DESIGN.md` | Privacy-first design and release gates for future crews |
| `docs/DEVICE_QA.md` | Physical phone QA worksheet, including Arusha/replay/season checks |
| `docs/CONTENT_GUIDE.md` | How to add routes/vehicles/obstacles/missions/etc. |
| `docs/ANDROID_EXPORT.md` | Export setup + on-device QA checklist |
| `docs/ANDROID_RELEASE_BUILD.md` | Signed AAB build, verification, and upload runbook |
| `docs/DEPENDENCY_MAINTENANCE.md` | Checked engine, Android, backend, and CLI versions; safe upgrade workflow |
| `docs/ADMOB_SETUP.md` | Installed AdMob integration and release QA |
| `docs/MONETIZATION.md` | IAP, carrier billing (TZ), season pass plan |
| `docs/LIVE_OPS.md` | Remote config, analytics, cloud save path |
| `docs/RAILWAY_BACKEND.md` | Railway/PostgreSQL deployment and safety runbook |
| `docs/SCORE_VERIFICATION.md` | Current score-trust limits and authoritative replay-validation plan |
| `docs/RELEASE_NOTES_1.0.17.md` | Bilingual production update notes for version 1.0.17 / code 18 |
| `docs/RELEASE_NOTES_1.0.14.md` | Bilingual release notes for code 15 |
| `docs/RELEASE_NOTES_1.0.13.md` | Historical production notes for code 14 |
| `docs/SPRITES.md` | Sprite filenames/sizes for the art pass |
| `docs/AUDIO_ASSETS.md` | Audio filenames/specs incl. Swahili voice lines |
| `docs/PLAY_STORE_RELEASE_CHECKLIST.md` | Production-track artifact, store assets, and upload checklist |
| `docs/PLAY_CONSOLE_APP_CONTENT_ANSWERS.md` | Current Play policy-form answers |
| `docs/PRIVACY_POLICY_DRAFT.md` | Source copy for the public privacy page |
| `docs/RELEASE_NOTES_1.0.6.md` | Final bilingual notes and verification record for code 7 |
| `docs/RELEASE_NOTES_1.0.7.md` | Final bilingual notes and verification record for code 8 |
| `docs/RELEASE_NOTES_1.0.5.md` | Historical bilingual notes for the code 6 artifact |
| `docs/PLAY_CONSOLE_APP_CONTENT_ANSWERS.md` | Suggested Play Console declarations |

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

World movement stays visually fast, while distance uses
`METERS_PER_WORLD_UNIT = 0.15`. At the opening speed this is about 51 m/s,
so distance goals and the 1 km achievement take meaningful play time.

## Logic Validation

Run the strict Godot 4.7.1 parser and headless contract suite before a build:

```powershell
godot --headless --editor --path . --quit
godot --headless --path . res://tests/logic_contracts.tscn -- --logic-contracts
```

The second command exits non-zero when a core data or progression contract is
broken, making it suitable for a future CI check.

## Save Data

`user://save.json` with batched multi-reward commits, automatic `.bak` rotation,
type/range normalization, and corruption recovery. Loading the backup repairs
the primary immediately without rotating the corrupt primary over the known-good
backup. Schema 9 includes first-session lessons, Driver Reputation, route
contracts, and aggregate local analytics lifecycle markers. It also reserves a
filtered, disabled-by-default Railway cloud-sync identity; no cloud transfer
occurs until a future explicit opt-in. Local referral identifiers and one-time
claim history contain no name, phone number, contact list, advertising
identifier, or account data.
On Windows during development:
`%APPDATA%\Godot\app_userdata\Dala Dala Rush TZ\save.json`.

---

*Godot 4 · GDScript · AdMob-integrated · Gameplay works offline ·
Swahili-first · No brands, no gambling, family-friendly*
