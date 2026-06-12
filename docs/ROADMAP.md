# Dala Dala Rush TZ - Product Roadmap

Updated after the two major upgrade waves (gameplay/UX wave + 10x feature
wave). The project is now a feature-complete offline game: the remaining
path to launch is **assets, SDK go-lives, device QA, and store prep** —
not new systems.

## Status by Area

| Area | Status | Notes |
|------|--------|-------|
| Core driving loop | **Done** | Vituo passenger loop, overload risk/reward, horn, fuel, combos, near-miss, boost, police chases, living-city conditions. Needs play-balancing only. |
| Progression | **Done** | Route unlock gates, career ranks, bus upgrades, missions + season, daily challenge, login streak, achievements, consumables. |
| Social/competitive | **Done (offline)** | Ghost racing w/ shareable codes, local leaderboard, livery + slogan sharing. Online (GPGS) is a later add. |
| Visual identity | **Systems done, assets pending** | Sprite override pipeline ready (`sprites/`); procedural art ships fine but a sprite pass is the biggest perceived-quality lever. |
| Audio | **Systems done, assets pending** | File-based loading w/ procedural fallback, music loop, voice-line hooks wired. Needs real recordings (`docs/AUDIO_ASSETS.md`). |
| Android readiness | **Code done, device QA pending** | Back button, safe-areas, haptics, share intents. Needs real-device passes (`docs/ANDROID_EXPORT.md` checklist). |
| Monetization | **Scaffolded** | AdMob adapter (simulated in debug), IAP catalog + billing seam, carrier-billing plan. Needs accounts + plugins to go live. |
| Live ops | **Scaffolded** | Remote config + offline analytics queue. Needs hosting URL + Firebase plugin. |
| QA/testing | Not started | Manual checklist exists in ANDROID_EXPORT.md. |
| Store launch | Not started | Package id, keystore, listing assets, privacy policy. |

## Milestone A — Balance & Editor QA (now)

- Open in Godot 4.6, clear any warnings, play 20+ runs.
- Tune: fares (`FARE_*`), overload penalties, kituo cadence, chase
  frequency/fine, condition modifiers, coin economy vs upgrade prices.
- Verify all screens in both languages at 540x960.
- Verify ad-continue flow (simulated ads in debug builds), ghost code
  export/import round-trip, livery persistence per vehicle.

## Milestone B — Asset Pass

- Sprite set per `docs/SPRITES.md` (vehicles → obstacles → collectibles → kituo).
- Audio set per `docs/AUDIO_ASSETS.md` (horn + crash + coin first, then
  music loop, then Swahili voice lines — record locally, it's the soul of
  the game).
- App icon + adaptive icon.

## Milestone C — Device QA

- Debug APK on at least one low-end + one mid-range phone.
- Run the full checklist in `docs/ANDROID_EXPORT.md`.
- Watch: swipe feel at speed, notch insets, battery/thermals, save
  integrity after force-kill.

## Milestone D — Monetization Go-Live

- AdMob app + rewarded unit, plugin install, fill the 3 stubs in
  `ad_service.gd`, switch off debug simulation. (`docs/ADMOB_SETUP.md`)
- Optional at launch: Play Billing for coin packs (`docs/MONETIZATION.md`).

## Milestone E — Store Launch

- Package id, version, release keystore (document storage!).
- Signed AAB, closed-testing track.
- Listing: SW+EN descriptions, screenshots (menu, vituo stop, night run,
  livery editor, chase), feature graphic, privacy policy (required once
  ads/analytics are live).
- Advertise: "Inacheza bila intaneti" — offline play is a selling point.

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
| Ad SDK destabilizes build | Medium | All SDK code isolated in AdService; simulation mode for flows. |
| Save schema growth breaks old saves | Medium | All reads use defaults; .bak recovery shipped; grandfathering migration in GameState. |
| Scope creep before launch | High | Systems are done — freeze features, ship Milestones A–E. |

## Shipping Philosophy

- Offline-first. Swahili-first, English-supported.
- Light enough for 1 GB RAM phones; APK under 30 MB.
- Funny and local, family-friendly. No brands, no gambling.
- Every system data-driven and beginner-extendable (`docs/CONTENT_GUIDE.md`).
