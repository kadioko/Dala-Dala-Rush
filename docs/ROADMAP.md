# Dala Dala Rush TZ - Product Roadmap

Updated October 8, 2026. Google Play production is active. Signed AAB
`1.0.16` / code `17` (API 36) is built and bundle-validated from current source
as a test candidate; A21s and second-phone QA plus Play testing remain. The
candidate includes compact-menu, daily-run, collision-envelope, projected
warning, lane-planner, and opt-in fuel/route-event telemetry changes. It is not
approved for production rollout until device QA passes.
The public World leaderboard read endpoint is enabled in source and live; the
current server board is empty until opted-in players submit scores. Score
submission and Friends remain opt-in, and scores are unverified. Broader
promotion still needs two-phone QA and Play declaration review.

The September 28-30 source pass fixes telemetry timestamp rejection, Daily Run
randomness leaks, missing route personal bests, account-deletion state,
simultaneous opt-in registration, reliable leaderboard uploads, and server-side
request limits. Version 1.0.14 / code 15 is the release candidate; two-phone
checks and Play declaration review remain release gates.

The current local quality pass simplifies the collapsed home screen, adds a
two-locale/five-size main-menu screenshot and horizontal-overflow runner,
extracts the forced-lane reachability rule into a test contract, bounds remote
config requests, and prepares shared PostgreSQL rate limits. These changes are
source-only and are not present in the previously exported code 15 bundle.

The October 8, 2026 expansion pass adds Arusha as the first route in a second
city pack, copyable run replay clips, exact-metadata matching for Daily Run
rivals, and persistent season chapters/milestone rewards. These are source
changes after code 17 and require a higher-version AAB for phone testing.
Migration `008_arusha_route_pack.sql` is committed with the client/backend
route allowlist but has not been deployed to Railway from this checkout.

## Status by Area

| Area | Status | Notes |
|------|--------|-------|
| Core driving loop | **Wave 23 QA** | Vituo passenger loop, overload risk/reward, horn, fuel, Driving Flow, near-miss, boost, police chases, a three-run non-modal first-session flow, and distinct route jobs/signature moments. Arusha adds a highland route profile. Needs phone play-balancing. |
| Progression | **Wave 35 local** | Route unlock gates, Driver Reputation, three-star Route Mastery, compact daily Route Contracts, career ranks, bus upgrades, missions, persistent city-themed season chapters/milestone rewards, daily challenge, login streak, achievements, consumables. New Arusha and season changes need phone validation. |
| Social/competitive | **Reporting/blocking deployed; phone QA pending** | Public World standings can be read; posting and Friends are opt-in. Fixed-reason name reports, friend blocking, and report-rate limits are deployed. Moderation is still a manual review queue. Two-phone QA remains. Scores remain unverified. |
| Visual identity | **Procedural pass done** | Improved code-drawn vehicles, roads, hazards, collectibles, HUD icons, intro, and How to Play ship without external gameplay PNGs. Optional sprite overrides remain available. Store graphics exist as drafts. |
| Audio | **Functional, recordings optional** | Procedural music/SFX and improved horn work. File override hooks and Swahili voice triggers are ready; licensed recordings remain a polish task. |
| Android readiness | **Code 17 test candidate built** | Version 1.0.16 / code 17 is a signed API 36 AAB with both ARM ABIs. Play processing, Play pre-launch reporting, and phone QA remain required before rollout. |
| Monetization | **AdMob integrated** | Production IDs and Poing Studios bridge are wired for rewarded/interstitial/banner. Real-device test-ad and consent validation remain. Play Billing is deferred. |
| Live ops | **Railway safety and retention deployed** | Shared PostgreSQL-backed HMAC limits, 90-day telemetry/report cleanup, and leaderboard report/block APIs are deployed. Useful reports still require consented event volume; there is no live dashboard. |
| QA/testing | **Local release gates pass; device QA pending** | Godot parse/contracts, UI bounds, and backend tests pass locally. A pinned Godot 4.7.1 GitHub Actions workflow now runs these gates. Physical phone QA, keyboard/banner/native safe-area checks remain manual. |
| Store launch | **Production active** | Monitor Play reports and staged rollout health, ship only higher version codes, and use physical-device evidence before expanding optional online services. |

## Wave 27 - Railway Cloud Pilot (Consent-Gated)

- Railway project `Dala Dala Rush TZ Backend`, Postgres, and the public API are
  deployed and health-checked. The database migration, anonymous cloud-save
  round trip, one-time phone transfer, and account deletion were smoke-tested
  against disposable records.
- Settings now has bilingual Cloud Backup consent, manual backup, restore with
  replacement warning, account deletion, and a 15-minute phone-move code.
- `RELEASE_CLOUD_SYNC_ENABLED` is enabled. The public World GET endpoint is
  readable without leaderboard opt-in; joining is still required to post a
  name/score. Complete `docs/DEVICE_QA.md` and keep Play privacy/Data Safety
  declarations aligned before broad promotion.

## Wave 28 - Public World Board And Consent-Gated Social

- Added a persistent 2-16 character driver name, a route-aware offline personal
  board, and explicit online consent before any name or score is shared.
- Added friends and world views, one best score per driver/route, and one-use
  24-hour friend codes. Scores are deliberately labelled unverified and never
  pay rewards.
- Migration `003_social_leaderboards.sql` is deployed; the live public World
  endpoint returns HTTP 200. Complete two-phone friend-code and score-submission
  QA and verify Play privacy/Data Safety declarations before broad promotion.

## Wave 30 - Leaderboard Release Readiness

- Added clear loading, empty, cached, offline, retry, pending, submitted, and
  rate-limited UI states in Swahili and English. Last upload status survives
  restart locally and is excluded from cloud saves. World remains publicly
  readable; joining is still required before publishing a name or score.
- The leaderboard page now has one mobile-friendly vertical scroll surface,
  scrolls the driver-name field above the Android keyboard, and rejects
  system-impersonating names before joining.
- Backend source adds fixed-window request limits, reserved-role name checks,
  and a migration/upsert enforcing one improved best per device and route.
  Automated coverage passes; deploy the Railway revision and run the two-phone
  worksheet before shipping/promotion. Scores remain unverified and reward-free.

## Wave 31 - Product Quality And Reliability (Local Source)

- The collapsed menu now foregrounds Play, selected route, Garage, and
  Leaderboards; secondary activities sit under a localized More control.
- World board rows now show the exact extra points needed to pass the nearest
  higher public score. The existing friend rival target is unchanged.
- Traffic generation uses one tested helper for a clear escape lane reachable
  in a single swipe on forced-choice waves. Existing active obstacles still
  defer a wave when all decision lanes are blocked.
- Remote config has a five-second timeout, a 64 KiB response cap, and monotonic
  revisions. Increase `revision` for every published edit; rollbacks must use
  an older value under a newer revision.
- Railway migration 006 and the matching shared-counter API are deployed.
  The stable HMAC key is configured; the pre-deploy migration command is
  verified. The public privacy policy and remote-config revision 2 are live.
- Added `docs/PRODUCTION_REPORTING.md` with aggregate-only queries and explicit
  limits of the current consented event stream. Crash reporting is not included.
- Added `tools/verify_android_release.ps1` for AAB signature/structure and
  optional bundletool manifest verification.
- Godot 4.7.1 editor parse, logic contracts, backend tests, PowerShell syntax
  validation, and all 30 normal-renderer menu captures passed locally. The
  screenshot set was visually reviewed at 360x640 in both locales and at
  720x1600 in Swahili; real-device rendering still needs phone QA.
- The Godot client/UI changes are included in the signed version 1.0.16 / code
  17 test candidate. Bundle validation has passed; physical phone QA and Play
  testing remain before production rollout. Railway backend changes are deployed.

## Wave 32 - Fair Traffic And Actionable Run Evidence (Code 17 Candidate)

- Hazard hitboxes now have explicit per-type scales bounded inside their art.
- Lane warnings are measured from collision-box contact, not vehicle-center
  alignment, and crossing/weaving hazards warn for projected lanes.
- Obstacles spawn farther above compact portrait viewports at higher speeds so
  they retain a reaction window. This also makes time-to-contact more
  consistent across screen heights.
- Fuel failures and route-moment start/complete/timeout events join the
  consent-gated Railway allowlist. The backend allowlist was deployed on
  October 8, 2026; no schema migration is needed. These events still require a
  client release with Gameplay Insights enabled and the player's consent.
- Automated contracts cover hitbox bounds, reaction time, crossing-lane
  predictions, and compact-screen spawn spacing. They do not replace A21s and
  second-device play QA, especially for cue visibility and route balance.

## Wave 33 - Telemetry Retention And Release Gates (Backend Deployed)

- Railway removes Gameplay Insights events older than 90 days in bounded
  batches at startup and every six hours. Migration 004 adds the cleanup index.
- The public privacy policy describes the retention schedule and deletion
  behavior.
- `tools/verify_project.ps1` runs Godot parsing/contracts, backend tests, and
  optional signed-AAB verification in one local release gate. It passed with
  Godot 4.7.1, responsive UI bounds, 12 backend tests, and the signed version
  1.0.16 / code 17 AAB. Headless mode skipped screenshots; visual review and
  physical-device validation remain.
- GitHub Actions runs the backend tests plus pinned Godot 4.7.1 parsing, logic,
  and layout bounds checks for pushes and pull requests.

## Wave 34 - Competition Safety And Measured Progression (Backend Deployed)

- Migration `007_competition_safety.sql` adds opaque report references, fixed-
  reason public-name reports, and persistent friend blocks. Railway migration
  and service deployment completed October 8, 2026.
- Reports are rate-limited and retained up to 90 days. Review is manual using
  the documented aggregate-safe query; no automated enforcement or moderator
  dashboard exists. Players can report World entries and block Friends in the
  client UI. Two-phone validation and an unblock-list UX remain.
- Consented `vehicle_unlocked` events record vehicle type, coin price, and
  number of runs at purchase. A higher-version client AAB is required before
  phones can generate these events or use the new report/block UI.
- The public privacy policy was updated for fixed-reason reporting, block
  behavior, vehicle-unlock telemetry, and the 90-day schedule. GitHub source is
  updated; recheck the Pages URL after CDN propagation.
- Current local gates pass: Godot 4.7.1 parse, logic contracts, UI bounds, and
  12 backend tests. Headless UI checks do not capture screenshots.

## Wave 35 - New Route Pack, Replay Clips, And Season Chapters (Local Source)

- Added Arusha as the first route in a separate city pack. It has its own
  highland road dressing, route goal, traffic/economy profile, contracts, horn
  tone, and Highland Pass signature event. The original six remain the only
  routes in the shared Daily Run rotation until challenge fairness is retested.
- Added route-aware shareable replay clips with vehicle, route, traffic seed,
  score, and optional daily challenge identity. Daily rivals are accepted only
  when route, starter vehicle, challenge date, and traffic seed all match.
  Daily rival passes award no extra score; online scores are still unverified.
- Added persistent Dar/Arusha season chapters and coin milestones to the
  existing season XP progression. No expiry, paid pass, or new currency was
  introduced.
- Added backend route validation and migration `008_arusha_route_pack.sql` for
  leaderboard and report route constraints. Source and tests are local until
  pushed; Railway is not linked in this checkout, so migration 008 is not
  deployed. Do not use Arusha's online board until the migration is applied.
- SACCO crews are not shipped. Their privacy, membership, moderation, and
  service design is captured in `docs/SACCO_CREWS_DESIGN.md`; implementation
  waits for reliable two-phone competition QA and an authenticated moderation
  path.

## Still Required Before Calling The Remaining Work Complete

- Physical QA on the Samsung A21s and a second Android phone: both languages,
  all seven routes, real touch, warnings, fuel, ad callbacks, resume, saves,
  brightness/contrast, and a long-run performance/thermal check. No device was
  connected during this pass.
- Tune route fuel, traffic, passenger cadence, and economy only after recording
  the real-device run worksheet and time-to-first-unlock evidence.
- Exercise report, block, friend deletion, public-name visibility, and score
  upload with two real installations. Scores remain explicitly unverified;
  server-verifiable run proofs and score rejection are not implemented.
- Review moderation reports operationally, add an authenticated moderator
  action path before meaningful scale, and test unblocking UX.
- Wait for the updated Privacy Policy GitHub Pages content to propagate, then
  check the Play Data Safety declaration and in-app link against actual SDK and
  deployment behavior.
- Generate and install a higher-version AAB before testing the new client-side
  reporting/blocking controls and vehicle-unlock event. The existing code 17
  AAB does not include these latest client changes.
- Collect enough opt-in telemetry for useful aggregate reports; monitor Play
  Console Android Vitals manually. No crash/ANR SDK or production dashboard is
  included.
- Validate old saves on a device upgraded from a real prior release. In-memory
  schema fixtures pass, but are not a substitute for a real profile backup.
- Still deferred: more city packs beyond Arusha (such as Mwanza and Zanzibar),
  server-verified reproducible rival scores, fully server-settled referrals,
  SACCO crews, replay GIF/video export, and a maintained calendar of seasonal
  events. Local replay clips, seeded Daily Run rival matching, and persistent
  season chapters now exist but need device validation and do not constitute
  server score verification or a content production pipeline.

## Milestone A — Production Update QA And Balancing

- Complete the three fresh-profile lessons on a phone in Swahili and English:
  steer/coin, passenger/kituo, horn/slow-motion. Confirm existing profiles skip
  them and rewarded continues do not restart them.
- On a fresh profile, verify result discoveries arrive one at a time: full Dar
  traffic, Mwenge, Route Mastery, changing road conditions, ghost races, then
  police chases. Confirm each message stays dismissed after relaunch.
- On a low-end phone, play 10+ runs on Kariakoo and Mwenge, then 5+ on every
  later route. Record fuel deaths, impossible traffic reads, average coins, and
  first vehicle-purchase time before changing remote defaults.
- Validate Game Over's recommendation stays visible above the results banner
  and matches goal-complete, fuel-empty, collision outcomes, reputation, and
  discovery messaging.
- On every route, trigger its signature moment at least twice and confirm it is
  readable, rewarding, localized, and never creates an unavoidable collision.
  Confirm the action prompt matches the required input and a target is offered
  whenever one is needed.
- Confirm reputation rises for safe drop-offs and clean checkpoints, and drops
  for missed stops, fines, collisions, and fuel failure as displayed on results. Check the
	point ledger against the final 0-100 rating in both languages.
- On each route, compare the actual job profile on a phone: Kariakoo's faster
  fares, Mbezi's longer stop spacing and fuel efficiency, Kigamboni rain/fuel
  pressure, and Ubungo rush-hour density should be noticeable without making a
  new-player run unfair.
- Earn every mastery tier on Kariakoo and one star on each other route. Verify
  one-time star rewards, saved star persistence, Swahili/English rules, and
  no payout from repeating an already-earned tier.
- Confirm the next mastery target agrees between the route card, pre-run
  briefing, and results. A fuel-failure result must prioritize refuelling
  advice over a progression prompt.

- Completed: set version `1.0.12`, code `13`, ran the Godot 4.7.1 contract
  scene, and received `LOGIC CONTRACTS: PASS`.
- Completed: added and passed the repeatable headless logic-contract suite.
- Completed: exported the signed code 13 AAB with the A21s main-menu fit pass and
  consent-gated Railway phone validation; its SHA-256 is recorded in
  `ANDROID_RELEASE_BUILD.md`.
- Completed: exported the signed code 14 AAB with responsive compact-menu
  stacking for narrow portrait widths; its SHA-256 is recorded in
  `ANDROID_RELEASE_BUILD.md`.
- Play 20+ runs across all seven routes and both languages.
- Tune through remote config first: global/route spawn rate, fuel drain, coin
  multiplier, speed ramp, and kituo cadence. Keep fares and police fines in a
  versioned build until their behavior has been tested.
- Verify all screens in both languages at 540x960.
- Verify the route briefing, goal, countdown, launch cue, and first steering
  hint in both languages with no HUD overlap or clipping.
- Verify ad-continue flow (simulated ads in debug builds), ghost code
  export/import round-trip, livery persistence per vehicle.
- Code-enforced: one rewarded choice per run. Revive and Double Coins are
  mutually exclusive across both the first and post-revive result screens.
- Verify pickups do not enter inside a nearby obstacle and late-run traffic
  remains readable at the capped pace.
- Verify consecutive two-lane waves never require a direct far-left to
  far-right move, especially with swipe controls enabled.
- On two phones, verify the full referral handoff: share invite, claim 75 once,
  return confirmation, claim 125 once, then retry both codes and confirm no
  second payout occurs.
- Confirm displayed bonus values match score changes and survive one rewarded
  revive without duplication.
- Verify Driving Flow on a phone: a coin, near-miss, and fare stop should extend
  the same short chain; it must reset after its timeout, cap at `x8`, and keep
  its peak on the post-revive results screen.
- Complete a reward-heavy run, close the app from the result screen, and verify
  score, coins, missions, daily progress, and lifetime stats restore together.

## Milestone B — Android And Ad QA

- Install a debug/release candidate through Play delivery on at least one
  low-end and one mid-range phone.
- Test rewarded callbacks, interstitial cadence, banners, app resume, failure
  handling, and consent with registered test devices.
- Verify the release manifest's AdMob App ID and advertising-ID permission.
- Run the full checklist in `docs/ANDROID_EXPORT.md`.

## Milestone C — Store Listing Refresh

- Standard launcher icon now uses the prepared store artwork; produce and wire
  a dedicated adaptive foreground/background pair before the next visual refresh.
- Review the generated 512 icon and feature graphic.
- Recapture portrait screenshots from the next release candidate, including current
  gameplay HUD and How to Play visuals.
- Verify the localized Privacy Policy button opens the active public page from
  Settings on a real phone.
- Confirm the support mailbox is monitored.

## Milestone D — Production Track Operations

- Completed locally: exported and verified the signed API 36 AAB with version code 15.
- Upload code 15 to the intended production track, then resolve any
  artifact-specific warnings before widening staged rollout.
- Recheck Advertising ID, Data safety, Ads, target audience, content rating,
  and privacy policy declarations.
- Add finalized localized notes from `docs/RELEASE_NOTES_1.0.14.md`.

## Milestone E — Post-Launch Readiness

- Collect tester feedback and crash/ANR/pre-launch reports.
- Fix blockers, increment the version code again for any replacement artifact,
  and complete staged rollout checks.
- Keep Play Billing, production online leaderboard, and premium season out of the
  launch scope unless they are fully implemented and declared.

## Post-Launch Backlog

- Complete two-phone cloud-save/phone-transfer QA, update Play declarations,
  then explicitly enable the optional cloud-save pilot. See
  `docs/RAILWAY_BACKEND.md`.
- SACCO crews (team competitions) — see `docs/SACCO_CREWS_DESIGN.md`; API,
  moderation operations, consent UX, and two-phone QA remain unimplemented.
- Replace manual referral confirmations with verified install attribution and
  server-side settlement; keep the current codes as a migration/fallback path.
- New city packs beyond Arusha: Mwanza, Zanzibar; Kigamboni ferry segment.
- Rival daladala racing you to the kituo (chase system can be extended).
- Replay GIF/video export for social platforms (replay codes and local ghost
  playback exist; media rendering/export is not implemented).
- Season pass premium track (season XP system already in).
- Expand seasonal events only after real completion and economy evidence; the
  event banner, daily-reward multiplier, and non-expiring chapter milestones
  exist, but there is no recurring content calendar/authoring pipeline.
- Traffic personality lines and licensed recorded horn/radio audio after
  performance and audio-mix tests on target phones.

## Risk Register

| Risk | Impact | Mitigation |
|------|--------|------------|
| Balance feels off after vituo rework | High | Constants centralized in game.gd; playtest Milestone A. |
| Small screens clip new HUD/UI | Medium | Test 540x960 first; safe-area helper already applied. |
| Ad SDK fails or policy state differs by region | High | SDK code is isolated; use registered test devices, validate UMP/consent, and inspect every release artifact. |
| Store media no longer matches current UI | Medium | Recapture screenshots from the next current-source release candidate. |
| Save schema growth breaks old saves | Medium | Defaults, load-time type/range repair, batched commits, safe .bak restoration, selection validation, discovery/history migration, and grandfathering migration are shipped and contract-tested. |
| Offline referral codes are forged or farmed | Medium | One welcome claim, self/duplicate guards, checksum confirmation, and a 10-referral cap limit casual abuse. Valuable or uncapped rewards require server verification. |
| Scope creep before launch | High | Systems are done — freeze features, ship Milestones A–E. |

## Shipping Philosophy

- Offline-first. Swahili-first, English-supported.
- Optimize for low-memory phones and monitor Play-delivered download size; the
  current local AAB is roughly 57-59 MB before delivery splits.
- Funny and local, family-friendly. No brands, no gambling.
- Every system data-driven and beginner-extendable (`docs/CONTENT_GUIDE.md`).
