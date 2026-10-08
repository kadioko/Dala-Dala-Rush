# Dala Dala Rush TZ - Upgrade Notes (Changelog)

Google Play production is active. The latest locally verified signed test
candidate is version 1.0.16 (code 17), built with Godot 4.7.1 / API 36.
Physical-device and Play testing remain outstanding; do not treat this
candidate as approved for production rollout.
Cloud sync, online leaderboards, and Gameplay Insights are enabled only after
their separate in-app consents; complete phone QA and Play declarations before
broad rollout. This is a historical implementation log; release readiness is
tracked in `ROADMAP.md`.

## Unreleased - Live Event Banner Refresh (October 8, 2026)

- Added a remote-config update signal so the main-menu event banner refreshes
  when the network response arrives after the menu has already opened.
- Reject malformed/non-integer network revisions, preserve monotonic revisions,
  and ignore oversized local config caches before reading/parsing them.
- Added contracts for banner refresh notification and invalid/stale revisions.

## Unreleased - Intro Pause And Resume Safety (October 8, 2026)

- Backgrounding the app during the route briefing now suspends the run and
  restarts the briefing when the player returns, instead of letting the start
  countdown and first gameplay seconds pass unseen.
- Added a lifecycle regression check to the compact-phone UI suite.

## Unreleased - Movement-Aware Safe-Lane Checks (October 8, 2026)

- Wave generation now marks an escape lane unsafe when the obstacle's collision
  width and the player's collision width overlap it, rather than comparing only
  the obstacle's current center lane.
- Bodaboda weaving is included as a horizontal drift envelope, and a wandering
  goat conservatively reserves the road while it is in the next decision
  corridor. The generator still defers waves when no one-swipe escape exists.
- Lane warning cues now trigger about one second before contact based on actual
  obstacle speed, keeping them useful on both short and tall screens and during
  slow-motion or boost effects.
- Added contracts for stationary traffic, bodaboda drift boundaries, and
  cross-road goat behavior, plus warning timing at multiple screen heights and
  speeds. Physical device balance checks remain necessary.

## Unreleased - Compact Menu Pulse And Deterministic Layout QA (October 8, 2026)

- Reduced the daily streak reward pulse from 110% to 103% so it remains inside
  the viewport on compact portrait screens.
- Made the layout runner seed an unclaimed daily streak for each locale/size,
  and include overflowing control text and parent bounds in failure messages.
- Bounded near-miss bonuses and overloaded police fines to the actual crossing
  window, preventing delayed rewards when the player changes lanes after a hazard
  has passed. Added contracts for close passes, late passes, and collisions.
- Normalized Daily Run pacing and scoring inputs across profiles: live balance
  overrides and career upgrades are ignored, onboarding and personal ghosts are
  suppressed, and account-gated police chases are omitted from the challenge.
- Added a migrated regular-run counter so playing Daily Run never skips the
  first-session tutorial for a brand-new profile; existing save progress stays
  intact through schema 14.
- Removed per-frame active-array copies from entity movement and collision
  checks while preserving oldest-first collision processing and safe pooling.
- Paused shared music and sound effects with the game, and restore audio on
  resume, app backgrounding, or leaving the gameplay scene.
- Made the live driving dock responsive below 412 px and added width contracts
  for small and standard portrait phones so controls stay on-screen. The pause
  panel now follows the same width limits.
- Lifted the player's vehicle slightly to give its silhouette clearer space
  from the power-up row and bottom driving dock on compact screens.
- These changes are included in the signed version 1.0.16 / code 17 test
  candidate. Bundle validation passed; physical phone QA remains before
  production rollout.

## Unreleased - Online State And Daily Run Reliability (September 28, 2026)

- Normalized new and previously queued Gameplay Insights timestamps to whole
  seconds, and skipped events outside Railway's 14-day acceptance window.
- Kept Daily Run lane order, collectible types, and obstacle motion on the
  seeded gameplay generator. Screen shake and obstacle colors use a separate
  visual generator, so Reduced Effects does not alter traffic choices.
- Made each route's saved personal best visible even when it falls outside the
  overall local Top-5.
- Reset leaderboard and insights consent, pending score uploads, cached boards,
  and the cloud identity after confirmed online-account deletion. Local game
  progress remains on the phone.
- Shared one registration request across simultaneous cloud and insights
  opt-ins; a switch turned off during a pending request stays off.
- Added Godot contracts and a Railway telemetry endpoint test. These source
  changes are not in the existing 1.0.13 / code 14 AAB.

## Wave 29 - Competition Reliability And Fair Daily Runs (September 8, 2026)

- Separated local Top-5 display rules from online submission rules: every
  route personal best can be saved as a pending upload, retried after restart,
  and backfilled once the player explicitly joins online competition.
- Added route/tab request correlation, a 12-second request timeout, manual
  refresh, cached standings with an age label, and stale-response rejection.
- Added friend-list management, two-way remove controls, a compact target to
  beat the next friend, and a clear Leave Online action that deletes the public
  profile, scores, friend links, and friend codes without touching phone saves.
- Added the daily equal-rules run: deterministic route/traffic seed, Classic
  Blue starter dala, no consumables, and no rewarded revive.
- Results now name the next locked dala, its primary perk, and the remaining
  coin cost. Leaderboard rows use stable 52px mobile touch-friendly spacing,
  clipped long-name presentation, and full-name tooltips.
- Added a separate Gameplay Insights opt-in and a Railway event endpoint which
  accepts only sanitized tutorial/run/retention/leaderboard-friction events.
  It remains independently opt-in with the rest of Railway online features.

## Wave 28 - Social Leaderboards (September 4, 2026)

- Replaced the static local top-five view with route-aware Personal, Friends,
  and World leaderboard tabs, a persistent driver name, and clear offline
  fallback behavior.
- Added opt-in-only profile/score requests, short-lived friend codes, and
  server ranking queries that use each driver's single best score per route.
- Added schema 11 save repair, backend migration `003_social_leaderboards.sql`,
  bilingual copy, and privacy documentation. The Railway migration and
  disposable two-account server smoke test passed. The release guard remains
  off: physical two-phone QA and Play declarations are required before public use.

## Wave 27 - Railway Cloud Pilot (September 2, 2026)

- Deployed the Railway/PostgreSQL API, completed private-network migrations,
  assigned and verified its public health endpoint, and smoke-tested anonymous
  registration, cloud backup, phone transfer, and cascading account deletion.
- Added bilingual Settings consent, one-off backup/restore, delete-cloud-data,
  and short-lived phone-move controls. The Settings layout now scrolls within
  Android safe areas rather than clipping on shorter screens.
- Bumped save repair to schema 10. Release cloud sync is deliberately disabled:
  debug builds can exercise the pilot; this code-10 build keeps it off until
  two physical-phone results and final Play declarations are complete.

## Wave 26 - Railway Online Services Foundation (September 2, 2026)

- Replaced the Firebase-as-database direction with a source-ready Railway +
  PostgreSQL service for optional cloud saves, server-side referral gates, and
  an explicitly unverified leaderboard.
- Added a disabled-by-default Godot `OnlineService` seam, filtered cloud-save
  snapshots, anonymous server-issued device credentials, and schema 9 repair.
  Nothing uploads until a reviewed HTTPS Railway URL and explicit future opt-in
  UI are deliberately added to a later build.
- Added backend validation tests, idempotent SQL migration, deployment runbook,
  and safeguards against uploading referral codes, names, analytics history,
  sync secrets, or advertising identifiers.

## Wave 24 - Release Evidence And Live Balance (September 2, 2026)

- Added a GitHub Pages remote-config source with strict allow-listed values,
  conservative route corrections, offline cache fallback, and new controls for
  passenger cadence, stop spacing, and rush-hour likelihood.
- Fixed the offline analytics journal to persist each event instead of waiting
  for its 500-event cap, protecting phone-QA evidence during short test runs.
- Added a two-device QA worksheet and a Firebase production handoff that keeps
  the app honest about the current offline-only telemetry state.
- Created and verified the signed `1.0.8` / code `9` AAB: JAR signature passes
  and its generated release manifest includes the AdMob App ID and Android
  Advertising ID permission. Physical-device QA remains required before upload.

## Wave 25 - Route Contracts And Seasonal Events (September 2, 2026)

- Source-only after the code-9 AAB: added compact rotating daily Route Contracts to every route. They unlock only
  after onboarding, have route-appropriate skill goals, reward once per route
  per local day, and appear on route selection/results instead of distracting
  the driving HUD.
- Turned seasonal-event scaffolding into working product behavior: main-menu
  event copy is bilingual and the remote daily multiplier now affects daily
  challenge and streak rewards, with a conservative `1x` to `2x` guard.
- Bumped save normalization to schema 8 for route-contract claim dates and
  added catalog, claim-idempotency, localization, and migration contracts.

## Wave 23 - Route Job Profiles (September 2, 2026)

- Moved route identity further into the actual driving rules. Kariakoo now
  creates faster passenger and stop opportunities; Mwenge stays reaction-led;
  Mbezi gives longer truck-road spacing and gentler fuel use; Posta remains
  controlled; Kigamboni has meaningful rain and fuel pressure; and Ubungo has
  a much higher rush-hour likelihood with tighter service rhythm.
- Route conditions are now selected from catalog weights after onboarding, so
  a route can have a recognizable road character without hard-coding another
  conditional chain in the game loop. Guided runs and rewarded continues stay
  deterministic and fair.
- Driver Reputation now records an ordinary collision as a visible 10-point
  service cost. Results localize that cost in the ledger, making the rating
  agree with the player's driving outcome instead of treating a crash as free.
- Added contracts for job profile ranges, weighted route conditions, and the
  crash reputation cost.
- A newly unlocked vehicle now names its strongest practical benefit in the
  Garage in Swahili or English, turning the first vehicle purchase into a
  small, self-explanatory progression moment.

## Wave 18 - Route Mastery (September 2, 2026)

- Added a permanent three-star mastery track to every route. One star requires
  the route score target, two adds the route goal, and three adds an A Driver
  Reputation. The next requirement is visible in Swahili and English on route
  cards, in the pre-run briefing, and after each run.
- New stars pay a small, one-time coin reward. Star state is saved per route,
  results call out the exact reward, route selection totals all 18 available
  stars, and Career Stats shows each route's score beside its current stars.
- Bumped local save normalization to schema 6 with strict 0-3 route-mastery
  repair. Added catalog threshold/reward, progression, idempotency, and save
  repair logic contracts.

## Wave 19 - Clear Driver Feedback (September 2, 2026)

- Turned the Driver Reputation result into a bilingual service report. It now
  shows the 50-point base, exact gains for service and skilled driving, and
  exact costs from missed stops, fines, and fuel failure.
- Centralized the score ledger in `GameState.calculate_reputation()` with
  explicit positive/negative totals. The displayed rating remains capped at
  0-100 and has a logic contract to prevent the explanation drifting from the
  actual score.

## Wave 20 - Signature Route Jobs (September 2, 2026)

- Made every route moment a clear mini-job with a bilingual live action prompt.
  Fare Rush requests a nearby stop, Boda Watch, Truck Line, and Clean
  Checkpoint offer their specific readable traffic target, Fuel Scout offers a
  safe can, and Jam Breaker now requires a horn press instead of completing
  automatically.
- Clean Checkpoint is only offered while the dala dala is not overloaded.
  Moment opportunities are tracked when they time out, and contracts now ensure
  every route has its required title, announcement, and action copy in both
  supported languages.

## Wave 21 - Guided City Discovery (September 2, 2026)

- Added a persistent, one-at-a-time discovery sequence for the first-session
  journey. Players are now introduced to the full city, Mwenge, Route Mastery,
  weather/rush-hour conditions, ghost races, and police chases only as those
  systems become relevant.
- Bumped save normalization to schema 7 with a strict allow-list for seen
  discoveries and idempotency coverage. Fixed the police-chase update branch so
  it only advances while a chase actually exists.

## Wave 22 - Driving Flow (September 2, 2026)

- Reworked the old coin-only combo into a capped `x8` Driving Flow. Coins,
  close calls, and serving a kituo now connect into one small, readable reward
  loop that celebrates skilled daladala driving instead of random collection.
- Coin value remains the only scaled reward, protecting fare, goal, mastery,
  mission, and ad economies. Best Flow appears on results and survives a
  rewarded continue; contracts cover its action math and hard cap.

## Wave 17 - Route Operator Loop (September 2, 2026)

- Turned the six routes into more distinct jobs with a single readable,
  favorable signature moment each: Kariakoo Fare Rush, Mwenge Boda Watch,
  Mbezi Truck Line, Posta Clean Checkpoint, Kigamboni Fuel Scout, and Ubungo
  Jam Breaker. Moments award a small skill bonus, never add an unavoidable
  hazard, and are tracked locally for tuning.
- Added the offline Driver Reputation result (A-D / 0-100). It combines safe
  drop-offs, passengers, near misses, goals, clean checkpoints, and signature
  moments; missed stops, fines, and fuel failure reduce it. It is a feedback
  score, not a new currency or monetization lever.
- Added a compact Run Highlights treatment at results, personal best delta,
  progressive discovery messages after the third guided run and first Kariakoo
  route goal, plus delayed weather/ghost/chase exposure for new profiles.
- Made route personality legible in the actual player flow: the route selector
  previews each signature moment, the live HUD shows its short countdown only
  when no urgent warning is present, and results tint the A-D reputation grade
  by service quality.
- Added subtle route-specific procedural horn pitch, local session/return
  markers, route-moment and vehicle-unlock analytics events. Data stays in the
  privacy-filtered offline journal until Firebase/Crashlytics is deliberately
  installed and verified.
- Bumped save normalization to schema 5 for best reputation and aggregate
  lifecycle markers. Added route-signature and reputation logic contracts;
  Godot 4.7.1 parser and headless contracts pass.

## Wave 16 - First Route, Better Signals (August 28, 2026)

- Added a persistent, non-modal three-run first-session journey for fresh
  installs: lane change and coin collection, passenger pickup and a guided
  kituo, then horn use and slow motion. Existing saves skip the lessons, and a
  rewarded continue never restarts one.
- The route briefing now introduces the current lesson when it is active; the
  live HUD keeps its normal goal but gives the compact lesson instruction the
  top priority until the player completes it.
- Added a results `Next Step` line: complete a route goal to explore/improve,
  refill earlier after a fuel finish, or retry with the crash coaching advice.
- Moved safe balance controls into validated remote config: global and
  per-route spawn/fuel/coin values, speed-ramp scale, and kituo cadence.
  Defaults are gentler for new drivers: 10% lower fuel drain, 5% slower ramps,
  and 18-28 second stops.
- Rebalanced all six route multipliers conservatively and reduced vehicle
  prices to 125-1400 coins so the first garage unlock arrives through ordinary
  play rather than a long early grind.
- Added visible near-miss shake plus a light haptic, and a dedicated horn
  haptic so these two driving decisions have distinct mobile feedback.
- Fixed the offline analytics journal to persist every event, sanitize values,
  exclude names/codes, and capture app open, run funnel, tutorial funnel,
  route selection, config source, and ad funnel events. Firebase/Crashlytics
  delivery remains intentionally unimplemented until a tested plugin is added.
- Bumped local save normalization to schema 4 for tutorial progress. Added
  tutorial migration and remote-config guard contracts; Godot 4.7.1 parser and
  headless logic contracts pass.

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
- Kituo gap 18–28 s by default (remote-tunable); waiting 2–5; boards up to 8 (overload only via
  roadside pickups — deliberate player choice).

Chase: every 35–55 s @50% after 40 s; 10 s duration; caught after 2.2 s
in-lane = 15 + overload fines; escape = +25.

Conditions: day 40% / dusk 20% / night 20% / rain 20%; rush 25%
(spawn ×0.85). Rain lane-time ×1.18.

Power-ups: magnet 6 s, slow 4 s (+1 s/brake lvl), boost 3 s ×1.45.

Economy sinks: vehicles 125–1400, route unlocks 150–1400, upgrades
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
- New-player path: Kariakoo (the only unlocked route) → guided lane/coin run
  → passenger/kituo run → horn/power-up run → regular route goals unlock Mwenge.
