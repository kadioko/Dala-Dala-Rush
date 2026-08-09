# AdMob Setup

Last verified: August 9, 2026.

`autoload/ad_service.gd` is the single integration point for ads. The Poing
Studios plugin and Android library are installed, production IDs are configured,
and the rewarded, interstitial, and banner bridges are implemented. Editor
debug builds still simulate successful ads when the Android singleton is absent.

## Ad Strategy

This is the most ad-heavy game in the portfolio, but the rules stay fair:

- Rewarded revive after crash.
- Rewarded double coins on results.
- One rewarded revive maximum per run. A player who claims Double Coins cannot
  also revive from that same result screen.
- Interstitial after every 2-3 completed runs.
- Banner only on main menu and results.
- No banner during gameplay.
- No interstitial before the player can choose revive or double coins.

## Current Integration

1. The AdMob app is created at https://apps.admob.com.

   Current AdMob App ID:

   ```text
   ca-app-pub-1484098434630929~6287913613
   ```

2. Three production ad units are configured:
   - Rewarded: shared by revive and double coins.
   - Interstitial: post-run cadence.
   - Banner: menu/results only.

3. Godot AdMob plugin status:
   - Installed: Poing Studios AdMob plugin `v4.3.1`.
   - Android package: `poing-godot-admob-android-v4.6.3`.
   - Plugin path: `addons/admob/`.
   - Android App ID config: `addons/admob/android/config.gd`.
   - The plugin is enabled in `project.godot`.

4. Production ID constants in `autoload/ad_service.gd`:
   - `ADMOB_REWARDED_ID`
   - `ADMOB_INTERSTITIAL_ID`
   - `ADMOB_BANNER_ID`

   Current ad unit IDs:

   ```text
   Rewarded:     ca-app-pub-1484098434630929/1092598111
   Interstitial: ca-app-pub-1484098434630929/3323134078
   Banner:       ca-app-pub-1484098434630929/2952474694
   ```

5. Plugin seam in `autoload/ad_service.gd`:
   - `_plugin_init()`
   - `_plugin_load_rewarded()`
   - `_plugin_show_rewarded()`
   - `_plugin_load_interstitial()`
   - `_plugin_show_interstitial()`
   - `_plugin_show_banner()`
   - `_plugin_hide_banner()`

   Status: wired to the Poing Studios API (`MobileAds`, `RewardedAdLoader`,
   `InterstitialAdLoader`, adaptive bottom `AdView`).

6. Android manifest status:
   - The generated release manifest includes the AdMob App ID.
   - The merged release manifest includes
     `com.google.android.gms.permission.AD_ID`.
   - Keep the Play Console Advertising ID declaration set to **Yes**, with
     **Advertising or marketing** selected as the reason.

## Before Every Release

1. Increment the version code before exporting.
2. Export with the `Android AAB Release` preset.
3. Verify:
   - Android export presets are configured locally in `export_presets.cfg`.
   - The Android build template is installed in `android/build/`.
   - Gradle/custom build is enabled so the plugin can add AARs, dependencies,
     and the AdMob App ID manifest entry.
   - Release output is an Android App Bundle at
     `exports/android/DalaDalaRushTZ-release.aab`.
4. Register test devices or use AdMob test mode while developing. Never click
   live ads during development.
5. On a real Android build, test ad load, close, failure, app resume, and reward
   callbacks for both rewarded placements.
6. Confirm interstitials appear only after the saved 2-3 run cadence and only
   after the player has finished with result-screen reward choices.
7. Confirm banners are absent during gameplay and pause.
8. Review consent requirements for every country where the game will be
   distributed. The plugin includes UMP APIs, but consent flow still needs
   explicit release validation/configuration.

`SIMULATE_IN_DEBUG` is an editor fallback, not the Android release ad path.

## Wired Placements

| Placement | Where | Behavior |
|---|---|---|
| `continue_after_crash` | Results screen | Rewarded revive, restores the run with shield |
| `double_coins` | Results screen | Rewarded double coins |
| `run_end_interstitial` | Leaving results | Shows after every 2-3 completed runs |
| `menu_banner` | Main menu | Banner only |
| `results_banner` | Results screen | Banner only |

Interstitials are queued by completed runs and shown when the player taps
Play Again or Main Menu from the results screen. This keeps the crash moment
clean and lets the player choose rewarded options first.
