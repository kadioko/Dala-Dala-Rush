# Dala Dala Rush TZ - Upgrade Notes (Changelog)

Current local closed-testing artifact: version 1.0.7 (code 8). Waves 5-15 are
included in the signed, locally verified Godot 4.7.1 / API 36 bundle. This is a
historical implementation log; release readiness is tracked in `ROADMAP.md`.

## Wave 15 - Offline Invite & Earn (August 24, 2026)

- Added a portrait-first, bilingual Invite & Earn screen reachable from the
  main menu, with current balance, invite code, claim progress, welcome claim,
  returned confirmation claim, clear status copy, and Android sharing.
- Added a fair two-player handshake: the invited player may enter one friend's
  code for 75 coins, then returns a one-time confirmation so the inviter earns
  125 coins. Inviter rewards are capped at 10 per local save.
- Added automatic milestone bonuses of 100, 200, and 500 coins at 3, 5, and 10
  confirmed friends, with the next target shown directly on the referral hub.
- Blocked self-referrals, repeated welcome claims, duplicate invitees,
  confirmations belonging to another inviter, malformed codes, and checksum
  tampering. Multi-field payouts commit through one save batch.
- Added schema-3 referral persistence using random game codes only. The feature
  does not read contacts, phone numbers, names, accounts, or precise location.
- Added referral normalization, tamper, ownership, reward-amount, and
  idempotency contracts; Godot 4.7.1 parsing and all logic contracts pass.
- Visually checked the complete screen at 540x960, including lower actions and
  Android safe-area clearance. A real two-phone share/return test remains.
- Android sharing now falls back to copying the full message if the share
  intent cannot open, so an invite or confirmation is never silently lost.
- Promoted Invite & Earn on the main menu with a distinct green reward action
  that shows the current 125-coin inviter reward without adding menu clutter.
- The signed code 8 AAB now includes this wave.

## Wave 14 - Professional bilingual match start (August 19, 2026)

- Rebuilt the route opening as a focused `JIANDOE / 3 / 2 / 1 / TWENDE`
  sequence in Swahili and `GET READY / 3 / 2 / 1 / GO` in English.
- Replaced the clipped 240 px launch label with a portrait-width-aware label,
  centered pivot, restrained scale animation, responsive route copy, and a
  strong outline that remains readable over every road condition.
- Hid the live score HUD, fuel meter, power-up row, and drive controls during
  the briefing; they now appear only when the player receives control.
- Delayed one-run consumable notices until driving begins so they are visible
  rather than expiring behind the countdown overlay.
- Added context to dusk/night/rain/rush-hour copy with a `HALI / CONDITION`
  prefix and polished early-run, fuel, horn, lane-warning, and route-goal text.
- Added launch-copy length contracts and visually verified the opening plus the
  first steering hint at a 496x883 debug window.

## Wave 13 - Core logic and data-contract audit (August 19, 2026)

- Made scene transitions single-owner: repeated navigation input is ignored
  while a fade is active, the overlay blocks touches during the handoff, and a
  failed scene change restores input instead of leaving the app stuck.
- Hardened save recovery so a valid backup repairs the primary immediately
  without copying a corrupt primary over the good backup on the next write.
- Added load-time type/range normalization for core totals, starter unlocks,
  locale, consumables, achievements, and leaderboard rows. Negative reward
  mutations and empty unlock IDs are now rejected.
- Validated saved route and vehicle selections against both catalog existence
  and unlock state, preventing invalid personal-best keys and locked starts.
- Centralized ghost-code validation with bounds for code size, event count,
  duration, lane values, ordering, and numeric values before playback.
- Made results navigation single-fire and applied the same completed-run
  interstitial policy to Leaderboard navigation as Replay and Main Menu.
- A purchased route is selected immediately, matching the garage unlock flow.
- Separated visual world speed from measured distance with a `0.15` conversion;
  the opening rate is now about 51 m/s instead of 340 m/s, giving route goals
  and the 1 km achievement meaningful duration.
- Added a clean headless logic-contract suite for locales, catalogs, save repair,
  invalid selections, rewarded idempotency, ghost codes, and distance tuning.

## Wave 12 - Interruption-safe pause flow (August 18, 2026)

- Rebuilt Pause as a focused driver-break screen with the current route,
  distance, collected coins, and onboard passenger load visible at a glance.
- Restart and Main Menu no longer discard a live run immediately. Both now
  open a clear confirmation state explaining exactly what will not be saved.
- Android Back first closes an open exit confirmation, then resumes the run on
  the next press, preventing an accidental navigation chain.
- Fixed the matching desktop/emulator Escape path: pause input is now handled
  before gameplay's paused-input guard, so the same key can pause and resume.
- Escape now accepts logical and physical keycodes, covering USB keyboards and
  emulator/desktop input layers that report the same key differently.
- Automatic pause after app backgrounding or focus loss always returns to the
  safe main pause state rather than preserving a stale destructive prompt.
- Added complete Swahili and English interruption and confirmation copy.

## Wave 11 - Rewarded-ad integrity (August 18, 2026)

- Enforced one rewarded choice per run across scene changes: a player can use
  either the one-time revive or Double Coins, never both on the same journey.
- Moved the Double Coins grant into `GameState`, where the claim is atomic and
  duplicate SDK reward callbacks cannot pay the same run twice.
- Zero-coin runs no longer offer a Double Coins ad, avoiding a worthless reward
  and protecting player trust.
- Replaced the debug placeholder message on results with concise bilingual
  guidance that clearly explains the one-reward choice and shows the exact
  coin amount that will be doubled.
- Failed ad attempts do not consume the choice; the valid actions are restored
  so the player can retry safely.

## Wave 10 - Route intent and crash coaching (August 18, 2026)

- Added the selected route objective and coin reward to the pre-run countdown,
  so every route begins with a clear purpose before traffic starts moving.
- The run now records the exact obstacle or fuel state that ended it and carries
  that context into the results screen.
- Added a compact `Driver Note` panel to Game Over with practical guidance for
  bodabodas, bajajis, cars, potholes, road works, checkpoints, trucks,
  pedestrians, loose tires, roadside goats, and empty fuel.
- Added scroll-safe clearance beneath the final results action so every button
  can sit fully above the fixed menu/results banner on short portrait phones.
- Added complete Swahili and English copy for the new coaching flow. Unknown or
  future hazards safely fall back to general lane-reading advice.

## Wave 9 - How To Play route briefing (August 18, 2026)

- Rebuilt How To Play as a focused portrait-first route briefing rather than a
  plain reference list. The Controls tab now presents a three-step run plan,
  a clearer three-lane road view, and a miniature representation of the live
  left, horn, and right driving dock.
- Replaced text-symbol placeholders with lightweight drawn control and tip
  glyphs. They are consistent with the vehicle and pickup previews already
  used elsewhere in the screen and need no additional art downloads.
- Added concise bilingual context panels to the Avoid and Collect tabs, plus
  explicit `DODGE` / `PICK UP` markers so the player understands the purpose
  of each item while scanning it.
- Reworked Tips into a practical pre-run checklist followed by color-coded
  driving, safety, and dala dala-life guidance. All new copy is localized for
  Swahili and English.
- Centered the screen title and turned the return control into a familiar
  compact back icon with a localized tooltip, giving the header more room on
  narrow Android devices.

## Wave 8 - Touch fidelity and fair late-run traffic (August 18, 2026)

- Added a compact live route-goal chip to the driving HUD. It shows the
  selected route's current run progress and coin reward, yields to urgent
  driving messages, and celebrates when the run reaches the goal.
- Added a one-time first-run practice shield. It gives a brand-new driver one
  protected mistake while they learn the road and is clearly identified as an
  onboarding assist rather than a rewarded-ad continue.
- Every 20-second speed increase now has a localized status cue, floating
  feedback, a light haptic, and a small audio signal so escalation feels fair.
- Shield hits now grant a short visible recovery window and delay the next
  hazard wave, preventing clustered traffic from causing an immediate second
  crash after the shield correctly absorbed the first one.
- Reframed the fuel meter as a compact upper-left gauge, freeing the road edge
  for traffic readability on portrait phones.
- Floating score and pickup feedback now stays above the power-up and driving
  dock, is centered to its real label width, and uses an outline for contrast.
- Shortened the opening steering hint in Swahili and English so it stays clean
  within the narrow portrait HUD.
- The entire lower driving dock is now a no-swipe zone, including the spacing
  around the left, horn, and right buttons. A thumb beginning inside the dock
  cannot leak into a steering gesture.
- Lane changes are now atomic: while the bus is completing its one-lane move,
  another steer cannot cancel or reverse it. The direction buttons dim briefly
  to show that the input has been accepted.
- Two-lane traffic waves now reserve a clear lane that is reachable in one
  deliberate move from the player's current lane and the prior safe lane.
- When existing traffic occupies every valid decision corridor, the game
  defers the next wave instead of manufacturing an impossible road choice.

## Wave 7 - Save integrity and low-end storage performance (August 9, 2026)

- Added nested save batching so a run result is committed as one coherent disk
  write after scores, route goals, daily challenges, missions, season rewards,
  coins, and lifetime statistics have all settled.
- Batched multi-step login streaks, career rewards, upgrades, vehicle and route
  unlocks, shop purchases, consumable use, ad pacing, and purchase grants.
- In-memory values still update immediately inside a batch; only repeated JSON
  serialization and backup rotation are deferred.
- Failed writes remain marked for a later retry, while the existing last-good
  `.bak` recovery remains intact.
- This removes result-screen storage bursts that could cause a visible hitch on
  low-end Android phones and reduces the chance of partially settled rewards.

## Wave 6 - Fair traffic and reliable pooling (August 9, 2026)

- Fixed the magnet so it attracts coins only, matching its description and
  preventing unintended passenger, fuel, shield, and power-up collection.
- Horn-cleared obstacles stop colliding immediately while their exit animation
  finishes, removing the chance of crashing into something already "cleared."
- Pickups and coin trails are skipped when their entrance corridor overlaps an
  obstacle; the game no longer falls back to a knowingly blocked lane.
- Late two-lane traffic waves keep the next safe lane current or adjacent, so
  touch players are never forced from the far-left lane directly to far-right.
- Pooled obstacles, collectibles, and vituo now reset transform, color, depth,
  and animation state whenever reused.
- Horn feedback is localized as "PEMBE!" and "HONK!".

## Wave 5 - Fair scoring and Android playability (August 9, 2026)

- Corrected bonus-score accounting: near misses, passengers, fuel cans,
  boosts, obstacle smashes, ghost wins, and kituo service now award the exact
  score shown to the player instead of being divided by the distance formula.
- Rewarded revives now preserve bonus score as well as distance, coins,
  passengers, fares, and near misses.
- Limited each touch swipe to one lane change for predictable phone controls;
  deliberate second swipes are still accepted immediately.
- Forced the first two completed runs to daytime without rush hour so new
  players learn the road before rain, darkness, and dense traffic appear.
- Added automatic pause when Android backgrounds the game or the window loses
  focus, protecting runs during calls, notifications, and app switching.
- Removed repeated fuel-bar style allocation from the frame loop to reduce
  avoidable UI work on low-end Android devices.
- Updated the opening control hint in both Swahili and English.
- Rebuilt rewarded-revive continuity: onboard passengers, exact elapsed time,
  weather, rush hour, fuel and fuel-saver state, horn capacity/charges/recharge,
  plus cumulative horn and boost mission progress now survive the revive.
- Revives restore at least 60% fuel without reducing a healthier fuel tank.
- Rebuilt Settings as compact switch rows so all options remain readable on
  small portrait screens in both Swahili and English.
- Added a saved Reduced Effects / Athari Chache option for motion comfort,
  battery life, and low-end phones. It reduces rain particles, speed lines,
  screen flashes, bus tilt, impact particles, camera shake, and hit-stop while
  leaving gameplay timing, warnings, collisions, and scoring unchanged.
## Wave 4 - Mobile stability and release polish (July 22, 2026)

- Rebuilt the portrait driving dock: clear bus-to-HUD spacing, grouped
  left/horn/right controls, gesture-bar clearance, and visible horn-charge
  state. Desktop controls are A/left, D/right, H/horn, and Esc/pause.
- Fixed emulator mouse input so a Horn click cannot end as a lane swipe;
  Android touch controls follow the same HUD exclusion path.
- Added a safe start: route intro, bus roll-in, first-traffic delay, and a
  beginner-friendly obstacle pool.
- Tuned long runs: speed ramps cap after seven steps and obstacle waves never
  fall below the readable spawn interval floor.
- Added pickup lane checks so independent collectibles do not spawn inside a
  nearby obstacle.
- Reward-result state is protected: one revive per run and one rewarded action
  at a time; Double Coins hides the exhausted reward row.
- Applied notch and gesture-bar safe areas to Garage, Shop, Routes, Stats,
  Settings, Livery, Leaderboard, and Missions.
- Reworked How to Play entity previews and grouped the Tips tab. Locale sets
  are aligned and English falls back to Swahili for future missing keys.

## Wave 3 — "10x" feature wave

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
- Visual speed `340 × route.difficulty`, +15% every 20 s; measured distance is
  visual travel × `0.15` (about 51 m/s on the starter route).
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
