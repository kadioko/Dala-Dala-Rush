# Dala Dala Rush TZ - Product Roadmap

Updated September 30, 2026 after the Waves 16-30 first-session, route-operator,
balance, telemetry, live-ops, and contract passes. Google Play production is
active. The current signed production-track update is `1.0.13` / code `14`;
it includes all Wave 29 competition reliability and daily-run work, the A21s
main-menu fit pass, responsive narrow-width fallback, and consent-gated Railway phone validation.
The public World leaderboard read endpoint is enabled in source and live; the
current server board is empty until opted-in players submit scores. Score
submission and Friends remain opt-in, and scores are unverified. Broader
promotion still needs two-phone QA and Play declaration review.

The September 28-30 source pass fixes telemetry timestamp rejection, Daily Run
randomness leaks, missing route personal bests, account-deletion state,
simultaneous opt-in registration, reliable leaderboard uploads, and server-side
request limits. Version 1.0.14 / code 15 is the release candidate; two-phone
checks and Play declaration review remain release gates.

## Status by Area

| Area | Status | Notes |
|------|--------|-------|
| Core driving loop | **Wave 23 QA** | Vituo passenger loop, overload risk/reward, horn, fuel, Driving Flow, near-miss, boost, police chases, a three-run non-modal first-session flow, and a distinct job profile plus favorable signature moment per route. Needs phone play-balancing. |
| Progression | **Wave 25 QA** | Route unlock gates, Driver Reputation, three-star Route Mastery, compact daily Route Contracts, career ranks, bus upgrades, missions + season, daily challenge, login streak, achievements, consumables. Vehicle prices and beginner route pace were reduced conservatively. |
| Social/competitive | **World view enabled; backend hardening live** | Ghost racing, livery sharing, and two-sided Invite & Earn codes work offline. Public World standings can be read; posting and Friends are opt-in. Bilingual loading/empty/offline/cache states, queued-upload feedback, small-screen scrolling, stale-tab guards, Railway rate limits, reserved-name guards, and per-route best-score storage are live. Two-phone QA remains. Scores remain unverified. |
| Visual identity | **Procedural pass done** | Improved code-drawn vehicles, roads, hazards, collectibles, HUD icons, intro, and How to Play ship without external gameplay PNGs. Optional sprite overrides remain available. Store graphics exist as drafts. |
| Audio | **Functional, recordings optional** | Procedural music/SFX and improved horn work. File override hooks and Swahili voice triggers are ready; licensed recordings remain a polish task. |
| Android readiness | **Code 15 release candidate built** | Version 1.0.14 / code 15 is a signed API 36 AAB with both ARM ABIs. Play processing, Play pre-launch reporting, and phone QA remain required before rollout. |
| Monetization | **AdMob integrated** | Production IDs and Poing Studios bridge are wired for rewarded/interstitial/banner. Real-device test-ad and consent validation remain. Play Billing is deferred. |
| Live ops | **Railway live; public World reads enabled** | Railway/PostgreSQL serves cloud backup, phone transfer, referral gates, an unverified leaderboard, and separately consented minimal Gameplay Insights. Cloud, Friends, score posting, and insights retain their individual consent gates. Rate/name/score hardening and migration 005 are deployed. Complete two-phone QA and Play privacy review before promotion. Crash reporting remains a separate future integration. |
| QA/testing | **In progress** | Godot 4.7.1 parses cleanly; contracts cover locales, catalogs, save repair, tutorial migration, remote-tuning guards, selections, ads, ghosts, referrals, and distance. Phone handoff testing remains. |
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
- Play 20+ runs across all six routes and both languages.
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
- SACCO crews (team competitions) — needs a tiny backend.
- Replace manual referral confirmations with verified install attribution and
  server-side settlement; keep the current codes as a migration/fallback path.
- New cities as route packs: Mwanza, Arusha, Zanzibar; Kigamboni ferry segment.
- Rival daladala racing you to the kituo (chase system can be extended).
- Replay GIF export for TikTok (ghost timeline is already recorded; needs a GIF encoder plugin).
- Season pass premium track (season XP system already in).
- Expand seasonal events only after real completion and economy evidence; the
  bilingual event banner and daily-reward multiplier are now implemented.
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
