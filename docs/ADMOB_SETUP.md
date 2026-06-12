# AdMob Setup

`autoload/ad_service.gd` is the single integration point for rewarded ads.
It currently runs in **simulation mode** in debug builds (ads "succeed" after
0.4 s) so the continue / double-coins flows are testable without an SDK.

## Steps

1. **AdMob account**: create an app at https://apps.admob.com, add one
   *Rewarded* ad unit. Note the App ID (`ca-app-pub-xxx~yyy`) and the
   Rewarded unit ID (`ca-app-pub-xxx/zzz`).

2. **Install the plugin**: the maintained Godot 4 plugin is
   **poing-studios/godot-admob-android** (also has iOS).
   - Download the release matching your Godot version.
   - Copy `addons/admob/` into the project, enable it in
     Project Settings > Plugins.
   - Install the Android build template (Project > Install Android Build
     Template) and enable Gradle build in the export preset.
   - Put your App ID in the plugin's Android config (it injects it into the
     manifest).

3. **Wire ad_service.gd**: replace the three `_plugin_*` stubs:
   - `_plugin_init()` — initialize MobileAds, connect the plugin's
     loaded / earned-reward / dismissed signals, call `_plugin_load()`.
   - `_plugin_load()` — load a rewarded ad with `ADMOB_REWARDED_ID`
     (set the real ID in the const at the top); set `_ad_loaded = true`
     in the loaded callback.
   - `_plugin_show()` — show the ad; emit
     `rewarded_result(_pending_placement, true)` on earned reward,
     `(…, false)` on dismiss without reward; then reload the next ad.

4. **Before release**:
   - Replace `ADMOB_REWARDED_ID` (currently Google's public *test* ID).
   - Set `SIMULATE_IN_DEBUG := false` or rely on release builds.
   - Test with test ads on a real device first — clicking real ads in
     development can get the account banned.

## Placements already wired in the game

| Placement | Where | Reward |
|---|---|---|
| `continue_after_crash` | Game-over screen | Resume the run with restored progress + 2.5 s shield |
| `double_coins` | Game-over screen | Doubles the run's coins |

Both buttons hide automatically when no ad is available.
