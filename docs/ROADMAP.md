# Dala Dala Rush TZ - Product Roadmap

This roadmap tracks what remains before the prototype becomes a polished Android-ready game. The project is currently a playable offline MVP with procedural visuals, Swahili/English UI, route goals, vehicle perks, local saves, achievements, local leaderboard, daily challenges, and ad placeholders.

## Roadmap Status

| Area | Status | Notes |
|------|--------|-------|
| Core driving loop | In progress | Playable, but needs balance testing and better feedback. |
| Android readiness | In progress | Portrait + lightweight rendering configured, export still needs device testing. |
| Visual identity | Prototype | Procedural art works, but needs a small sprite/UI polish pass. |
| Audio | Prototype | Procedural SFX exist, music and real SFX are not done. |
| Progression | In progress | Coins, unlocks, goals, achievements, daily challenges exist. |
| Monetization | Placeholder | No real ads/IAP; safe placeholder hooks only. |
| QA/testing | Not started | Needs real Godot validation and Android device testing. |
| Store launch | Not started | Needs package, icon, screenshots, privacy policy, and release build. |

## Milestone 1 - Stabilize The MVP

Goal: make the existing game loop reliable, readable, and fun for repeated short sessions.

Recent progress:

- Fixed a strict GDScript Variant inference error in route progress calculation.
- Reduced fuel drain and increased fuel pickup restore.
- Added route-specific spawn interval multipliers.
- Lowered early vehicle unlock prices to make the first upgrades more achievable.
- Ran a static localization key coverage check for menu/runtime text.

Priority work:

- Run the project in Godot 4 and clear all warnings/errors.
- Tune lane-switch feel across all vehicle perks.
- Playtest fuel drain on real Android hardware.
- Playtest obstacle spawn intervals on all six routes.
- Playtest coin economy and adjust with real average coins/run.
- Verify all menus visually in Swahili and English inside Godot.
- Make Game Over layout fit on small portrait screens.
- Make Route, Garage, and Shop text fit on 540x960 devices.
- Add a simple pause/resume smoke test checklist.
- Review save migration behavior with old `user://save.json` files.

Definition of done:

- A new player can launch, select a route, play, crash, see Game Over, earn coins, unlock/select a vehicle, switch language, and quit/reopen with progress saved.

## Milestone 2 - Android Build Readiness

Goal: produce a stable debug APK and test it on low/mid-range Android phones.

Priority work:

- Install/configure Godot Android export templates.
- Create Android export preset.
- Set package id, version name, and version code.
- Confirm portrait orientation on device.
- Test touch input: swipe, left/right buttons, horn, pause.
- Test haptics toggle on real Android hardware.
- Test audio mute toggles.
- Check performance on 540x960 and 720x1280 screens.
- Confirm `.godot/`, APKs, AABs, and build folders stay ignored by git.
- Add screenshots or notes from device tests.

Definition of done:

- A debug APK installs, launches, plays smoothly, saves data, and has no blocking device-specific issues.

## Milestone 3 - Visual And Audio Polish

Goal: make the game feel more local, funny, and memorable without increasing file size too much.

Priority work:

- Replace procedural vehicle/obstacle shapes with a tiny sprite atlas.
- Create unique readable silhouettes for dala dala, bodaboda, bajaji, truck, police, pothole, tire, and cones.
- Add simple UI icons for coins, passengers, fuel, shield, magnet, slow motion, and horn.
- Add a small app icon and adaptive Android icon.
- Add real lightweight SFX as mono `.ogg` files.
- Add one short looping menu/game music track with mute support.
- Add a few Swahili floating phrases for near misses, horn use, and route goals.
- Add a small visual reward for completing a daily challenge.

Definition of done:

- Screenshots clearly read as a Tanzanian dala dala game even without reading the title.

## Milestone 4 - Progression And Retention

Goal: give players clear reasons to keep replaying while staying offline-friendly.

Priority work:

- Add bronze/silver/gold route mastery tiers.
- Add achievement descriptions to Game Over when newly unlocked.
- Add a daily challenge completion counter on Stats.
- Add a weekly challenge placeholder, still offline.
- Add vehicle previews with perk badges.
- Add a first-run tutorial overlay.
- Add route unlock pacing or recommended route order.
- Add coin rewards for achievements if needed.
- Review economy: unlock prices vs average coins per run.

Definition of done:

- The player understands what to do next after every run.

## Milestone 5 - Monetization-Ready Hooks

Goal: keep the MVP family-friendly and safe while preparing for optional future monetization.

Priority work:

- Keep fake coins separate from real-money systems.
- Keep `AdService` as the only place that talks to ad SDKs.
- Implement real rewarded-ad callbacks only after SDK choice.
- Add one continue-after-crash use per run.
- Add double-coins reward only after Game Over.
- Add clear failure messaging when ads are unavailable.
- Add a future "remove ads" product placeholder in Shop only after IAP is planned.
- Confirm no gambling, betting, loot boxes, or paid random rewards.

Definition of done:

- Ad/IAP integration can be added without rewriting game flow or save logic.

## Milestone 6 - QA And Release Candidate

Goal: prepare a build that can be shared with testers.

Priority work:

- Create a manual QA checklist.
- Test all screens in Swahili and English.
- Test new save, existing save, and corrupted save file behavior.
- Test route goals and daily challenge reward once-per-day behavior.
- Test leaderboard name entry.
- Test share text on Android.
- Test mute settings persist across restart.
- Test all vehicle unlock paths from Garage and Shop.
- Confirm no copyrighted brands/logos are present.
- Run at least 20 minutes of repeated play on device.

Definition of done:

- Tester build has no known crash/blocker bugs and all core flows pass manually.

## Milestone 7 - Store Launch Prep

Goal: prepare the app for a small public or closed Android release.

Priority work:

- Finalize app name, package id, version code, and version name.
- Create release keystore and document safe storage.
- Export signed APK/AAB.
- Create Play Store short and full descriptions.
- Create screenshots for menu, route select, gameplay, garage, and Game Over.
- Create feature graphic.
- Draft privacy policy, especially if ads/analytics are added later.
- Confirm offline behavior and data storage claims.
- Prepare a short tester feedback form.

Definition of done:

- Release artifacts and store assets are ready for closed testing.

## Backlog

Gameplay:

- Add lane-specific warning polish.
- Add route-specific background decorations.
- Add weather/time-of-day variants.
- Add boss-style traffic moments every few minutes.
- Add safer spawn rules to avoid unfair unavoidable walls.
- Add optional beginner assist for first few runs.

UI/UX:

- Add onboarding/tutorial screen before first run.
- Add better selected/locked vehicle visual states.
- Add compact screen-safe layouts for smaller phones.
- Add clear reward animation for coins and route goals.
- Add stronger visual feedback for shield and magnet states.

Content:

- Add more Swahili humor lines.
- Add extra dala dala skins.
- Add more route variants.
- Add more achievements.
- Add route mastery badges.

Technical:

- Add `.gitattributes` for consistent line endings if needed.
- Add export preset template once signing details are known.
- Add automated GDScript lint/check command if Godot CLI is available.
- Add save schema migration utilities.
- Reduce repeated `_vehicle_stats()` formatting between Garage and Shop.
- Consider moving shared UI text formatting helpers into `ui_factory.gd`.

## Current Recommended Next Steps

1. Open the project in Godot 4 and clear runtime/editor warnings.
2. Build and install a debug APK on at least one Android phone.
3. Tune route difficulty, fuel drain, and vehicle perks from real play sessions.
4. Polish small-screen UI fit for Main Menu, Routes, Garage, Shop, and Game Over.
5. Replace procedural placeholders with a tiny sprite atlas.
6. Create the first real audio pass.

## Risk Register

| Risk | Impact | Mitigation |
|------|--------|------------|
| Godot warnings hidden until editor run | Medium | Run Godot editor/headless checks regularly. |
| Small Android screens may clip text | High | Test 540x960 and reduce labels where needed. |
| Coin economy may feel slow or too generous | Medium | Track average coins/run and adjust prices/rewards. |
| Procedural art may feel too placeholder | Medium | Add tiny sprite atlas before public testing. |
| Ad integration can destabilize Android build | Medium | Keep SDK code isolated in `AdService`. |
| Save changes can break old saves | Medium | Add migration checks before public release. |

## Shipping Philosophy

- Offline-first.
- Swahili-first, English-supported.
- Lightweight enough for low/mid-range Android phones.
- Funny and local, but family-friendly.
- No real brands, no copyrighted logos, no gambling.
- Keep every system easy for a beginner Godot developer to extend.
