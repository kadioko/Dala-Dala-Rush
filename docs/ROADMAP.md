# Dala Dala Rush TZ - Product Roadmap

Updated August 9, 2026 after the scoring, Android playability, traffic fairness,
and save-integrity passes. The immediate goal is a stable `1.0.5` / code `6`
closed-testing bundle, not another feature expansion.

## Status by Area

| Area | Status | Notes |
|------|--------|-------|
| Core driving loop | **Done** | Vituo passenger loop, overload risk/reward, horn, fuel, combos, exact bonus scoring, near-miss, boost, police chases, and beginner-safe living-city conditions. Needs play-balancing only. |
| Progression | **Done** | Route unlock gates, career ranks, bus upgrades, missions + season, daily challenge, login streak, achievements, consumables. |
| Social/competitive | **Done (offline)** | Ghost racing w/ shareable codes, local leaderboard, livery + slogan sharing. Online (GPGS) is a later add. |
| Visual identity | **Procedural pass done** | Improved code-drawn vehicles, roads, hazards, collectibles, HUD icons, intro, and How to Play ship without external gameplay PNGs. Optional sprite overrides remain available. Store graphics exist as drafts. |
| Audio | **Functional, recordings optional** | Procedural music/SFX and improved horn work. File override hooks and Swahili voice triggers are ready; licensed recordings remain a polish task. |
| Android readiness | **Code 6 AAB built, QA pending** | Godot 4.7.1, API 36, both ARM ABIs, AdMob manifest entries, signing, and local artifact checks pass. Needs Play-delivered device QA. |
| Monetization | **AdMob integrated** | Production IDs and Poing Studios bridge are wired for rewarded/interstitial/banner. Real-device test-ad and consent validation remain. Play Billing is deferred. |
| Live ops | **Scaffolded** | Remote config + offline analytics queue. Needs hosting URL + Firebase plugin. |
| QA/testing | **In progress** | Project parses cleanly in Godot 4.7.1 and controls have been phone-tested. Full matrix and long-run testing remain. |
| Store launch | **Closed testing active** | Version 1.0.4/code 5 is the Play baseline. The signed 1.0.5/code 6 AAB is built locally; upload and tester rollout remain. |

## Milestone A — Version 1.0.5 Release Candidate (now)

- Set version `1.0.5`, code `6`, then run Godot 4.7.1 parser validation.
- Play 20+ runs across all six routes and both languages.
- Tune: fares (`FARE_*`), overload penalties, kituo cadence, chase
  frequency/fine, condition modifiers, coin economy vs upgrade prices.
- Verify all screens in both languages at 540x960.
- Verify ad-continue flow (simulated ads in debug builds), ghost code
  export/import round-trip, livery persistence per vehicle.
- Verify one revive maximum per run and that Double Coins cannot be combined
  with a revive from the same result screen.
- Verify pickups do not enter inside a nearby obstacle and late-run traffic
  remains readable at the capped pace.
- Verify consecutive two-lane waves never require a direct far-left to
  far-right move, especially with swipe controls enabled.
- Confirm displayed bonus values match score changes and survive one rewarded
  revive without duplication.
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
  a dedicated adaptive foreground/background pair before production.
- Review the generated 512 icon and feature graphic.
- Recapture portrait screenshots from the final code 6 build, including current
  gameplay HUD and How to Play visuals.
- Verify the localized Privacy Policy button opens the active public page from
  Settings on a real phone.
- Confirm the support mailbox is monitored.

## Milestone D — Closed Testing Upload

- Export the signed API 36 AAB with version code 6.
- Upload to closed testing and resolve artifact-specific warnings.
- Recheck Advertising ID, Data safety, Ads, target audience, content rating,
  and privacy policy declarations.
- Add release notes from `docs/RELEASE_NOTES_1.0.5_DRAFT.md`.

## Milestone E — Production Readiness

- Collect tester feedback and crash/ANR/pre-launch reports.
- Fix blockers, increment the version code again for any replacement artifact,
  and complete staged rollout checks.
- Keep Play Billing, Firebase, online leaderboard, and premium season out of the
  launch scope unless they are fully implemented and declared.

## Post-Launch Backlog

- Online leaderboards via Play Games Services v2; cloud save (one JSON dict — see `docs/LIVE_OPS.md`).
- SACCO crews (team competitions) — needs a tiny backend.
- New cities as route packs: Mwanza, Arusha, Zanzibar; Kigamboni ferry segment.
- Rival daladala racing you to the kituo (chase system can be extended).
- Replay GIF export for TikTok (ghost timeline is already recorded; needs a GIF encoder plugin).
- Season pass premium track (season XP system already in).
- Seasonal events via remote config (`event_banner`, reward multipliers).

## Risk Register

| Risk | Impact | Mitigation |
|------|--------|------------|
| Balance feels off after vituo rework | High | Constants centralized in game.gd; playtest Milestone A. |
| Small screens clip new HUD/UI | Medium | Test 540x960 first; safe-area helper already applied. |
| Ad SDK fails or policy state differs by region | High | SDK code is isolated; use registered test devices, validate UMP/consent, and inspect every release artifact. |
| Store media no longer matches current UI | Medium | Recapture screenshots from the final code 6 build. |
| Save schema growth breaks old saves | Medium | All reads use defaults; batched commits, .bak recovery, and grandfathering migration are shipped. |
| Scope creep before launch | High | Systems are done — freeze features, ship Milestones A–E. |

## Shipping Philosophy

- Offline-first. Swahili-first, English-supported.
- Optimize for low-memory phones and monitor Play-delivered download size; the
  current local AAB is roughly 57-59 MB before delivery splits.
- Funny and local, family-friendly. No brands, no gambling.
- Every system data-driven and beginner-extendable (`docs/CONTENT_GUIDE.md`).
