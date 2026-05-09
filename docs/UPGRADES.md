# Dala Dala Rush TZ - Upgrade Notes

## Implemented Improvements

- Settings now has a two-button language selector for Kiswahili and English.
- Added `FeedbackManager` for optional Android vibration on lane changes, pickups, power-ups, shield hits, horn use, and crashes.
- Added `haptics_on` to saved settings.
- Added `AdService` as a safe rewarded-ad placeholder. It does not ship an ad SDK or call a network.
- Game Over now exposes placeholder actions for continue-after-crash and double-coins rewards.
- Android share text is URI-encoded before opening the share intent.
- Shop purchases now use `SaveSystem.spend_coins()` so coin deduction is centralized.
- Routes now have obstacle and collectible weight profiles, so each road has different traffic behavior.
- Route selection now shows route flavor, difficulty marks, and per-route best score.
- Routes now include one run goal each. Completing it awards bonus coins at Game Over.
- Vehicle skins now have light gameplay perks for handling, fuel efficiency, coin gain, and horn charges.
- Added offline daily challenges that rotate by local date and reward coins once per day.

## Recommended Next Upgrades

1. Replace procedural icons with a tiny sprite atlas.
   Keep each vehicle/obstacle around 128x128 or smaller and use Android-friendly import compression.

2. Add progressive route mastery.
   Example: bronze/silver/gold route goals that unlock after the first goal is completed.

3. Add a proper continue-after-crash flow.
   Current placeholder starts from Game Over. A real version should save the active run state before ending, then resume once after a rewarded ad.

4. Add lightweight background music.
   Use mono `.ogg` at 22,050 Hz. Keep loops short and local.

5. Add device testing presets.
   Test 540x960, 720x1280, and 1080x1920 portrait layouts before Android export.

## Balancing Notes

- Base speed starts at `340 * route.difficulty`.
- Speed increases by 15% every 20 seconds.
- Spawn interval tightens over time and is divided by route difficulty.
- Route traffic comes from `obstacle_weights` in `data/routes.gd`.
- Route pickups come from `collectible_weights` in `data/routes.gd`.
- Route goals use `goal_type`, `goal_target`, and `goal_reward` in `data/routes.gd`.
- Vehicle perks use `lane_time`, `fuel_drain_mult`, `coin_mult`, and `horn_charges` in `data/vehicles.gd`.
- Daily challenges live in `data/daily_challenges.gd` and reuse score/coins/distance/near-miss/passenger stats.
- Fuel drain is intentionally slow for MVP. Tune `FUEL_DRAIN` only after testing on real phones.
- Magnet lasts 6 seconds and slow motion lasts 4 seconds.

## Route Personality

- Kariakoo: more bajajis, pedestrians, and passengers.
- Mwenge: more bodabodas and sudden road clutter.
- Mbezi: more cars, trucks, tires, and useful fuel.
- Posta: more cones, barriers, police checkpoints, shields, and slow motion.
- Kigamboni: more potholes, tires, fuel cans, and speed boosts.
- Ubungo: more trucks, jam pressure, shields, and slow motion.

## Route Goals

- Kariakoo: pick up 8 passengers.
- Mwenge: score 6 near misses.
- Mbezi: drive 1,800 meters.
- Posta: score 700 points.
- Kigamboni: collect 18 coins.
- Ubungo: score 1,200 points.

## UX Notes

- Swahili should remain the default locale.
- English is useful for testing, store pages, and wider player reach.
- Keep humor in short UI lines, not long paragraphs.
- Avoid real brands, real operators, and copyrighted logos.
