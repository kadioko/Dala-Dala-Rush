# Dala Dala Rush TZ - Product Roadmap

Updated August 24, 2026 after the referral, UI-polish, and code-8 release pass.
The signed `1.0.7` / code `8` closed-testing AAB includes current Wave 15 source
and is ready for Play upload plus delivered-device testing.

## Status by Area

| Area | Status | Notes |
|------|--------|-------|
| Core driving loop | **Done** | Vituo passenger loop, overload risk/reward, horn, fuel, combos, exact bonus scoring, near-miss, boost, police chases, and beginner-safe living-city conditions. Needs play-balancing only. |
| Progression | **Done** | Route unlock gates, career ranks, bus upgrades, missions + season, daily challenge, login streak, achievements, consumables. |
| Social/competitive | **Done (offline MVP)** | Ghost racing, livery sharing, and two-sided Invite & Earn codes work without accounts. Verified install attribution and automatic referrer payouts need a backend later. |
| Visual identity | **Procedural pass done** | Improved code-drawn vehicles, roads, hazards, collectibles, HUD icons, intro, and How to Play ship without external gameplay PNGs. Optional sprite overrides remain available. Store graphics exist as drafts. |
| Audio | **Functional, recordings optional** | Procedural music/SFX and improved horn work. File override hooks and Swahili voice triggers are ready; licensed recordings remain a polish task. |
| Android readiness | **Code 8 AAB built, QA pending** | Version 1.0.7 includes Waves 8-15 and is locally verified with Godot 4.7.1, API 36, both ARM ABIs, signing metadata, AdMob metadata, and AD_ID permission. |
| Monetization | **AdMob integrated** | Production IDs and Poing Studios bridge are wired for rewarded/interstitial/banner. Real-device test-ad and consent validation remain. Play Billing is deferred. |
| Live ops | **Scaffolded** | Remote config + offline analytics queue. Needs hosting URL + Firebase plugin. |
| QA/testing | **In progress** | Godot 4.7.1 parses cleanly; contracts cover locales, catalogs, saves, selections, ad rewards, ghost codes, referral tampering/idempotency, and distance. Referral UI is portrait-verified; phone handoff testing remains. |
| Store launch | **Code 8 tester rollout pending** | Upload the verified AAB, process it through Play, roll out to testers, and review reports. |

## Milestone A — Current Source Release Candidate

- Completed: set version `1.0.7`, code `8`, and ran Godot 4.7.1 parser validation.
- Completed: added and passed the repeatable headless logic-contract suite.
- Completed: exported and independently verified the signed code 8 AAB from
  Waves 8-15.
- Play 20+ runs across all six routes and both languages.
- Tune: fares (`FARE_*`), overload penalties, kituo cadence, chase
  frequency/fine, condition modifiers, coin economy vs upgrade prices.
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
- Recapture portrait screenshots from the next release candidate, including current
  gameplay HUD and How to Play visuals.
- Verify the localized Privacy Policy button opens the active public page from
  Settings on a real phone.
- Confirm the support mailbox is monitored.

## Milestone D — Closed Testing Upload And Rollout

- Completed locally: export and signature/manifest verification of the signed
  API 36 AAB with version code 8.
- Upload to closed testing, then resolve artifact-specific warnings.
- Recheck Advertising ID, Data safety, Ads, target audience, content rating,
  and privacy policy declarations.
- Add finalized localized notes from `docs/RELEASE_NOTES_1.0.7.md`.

## Milestone E — Production Readiness

- Collect tester feedback and crash/ANR/pre-launch reports.
- Fix blockers, increment the version code again for any replacement artifact,
  and complete staged rollout checks.
- Keep Play Billing, Firebase, online leaderboard, and premium season out of the
  launch scope unless they are fully implemented and declared.

## Post-Launch Backlog

- Online leaderboards via Play Games Services v2; cloud save (one JSON dict — see `docs/LIVE_OPS.md`).
- SACCO crews (team competitions) — needs a tiny backend.
- Replace manual referral confirmations with verified install attribution and
  server-side settlement; keep the current codes as a migration/fallback path.
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
| Store media no longer matches current UI | Medium | Recapture screenshots from the next current-source release candidate. |
| Save schema growth breaks old saves | Medium | Defaults, load-time type/range repair, batched commits, safe .bak restoration, selection validation, and grandfathering migration are shipped and contract-tested. |
| Offline referral codes are forged or farmed | Medium | One welcome claim, self/duplicate guards, checksum confirmation, and a 10-referral cap limit casual abuse. Valuable or uncapped rewards require server verification. |
| Scope creep before launch | High | Systems are done — freeze features, ship Milestones A–E. |

## Shipping Philosophy

- Offline-first. Swahili-first, English-supported.
- Optimize for low-memory phones and monitor Play-delivered download size; the
  current local AAB is roughly 57-59 MB before delivery splits.
- Funny and local, family-friendly. No brands, no gambling.
- Every system data-driven and beginner-extendable (`docs/CONTENT_GUIDE.md`).
