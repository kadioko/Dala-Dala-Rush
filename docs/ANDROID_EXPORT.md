# Android Export Guide

Last verified: August 9, 2026 with Godot 4.7.1.

For the exact signed AAB procedure, artifact verification commands, and Play
upload handoff, use `docs/ANDROID_RELEASE_BUILD.md`.

## Target

- Orientation: portrait.
- Minimum SDK: Android 7.0 / API 24.
- Target SDK: Android 16 / API 36.
- Renderer: GL Compatibility.
- Offline-first: no required network access for MVP.
- Target phones: low to mid-range Android devices common in Tanzania.
- Package: `com.kadioko.daladalarush`.
- Current closed-testing baseline: `1.0.4` / version code `5`.
- Next planned release: `1.0.5` / version code `6`.

API 36 meets Google Play's Android 16 requirement for new apps and app updates
starting August 31, 2026. Recheck the policy before later releases:
https://support.google.com/googleplay/android-developer/answer/11926878

## Godot Setup

1. Open `project.godot` in Godot 4.7.1.
2. Go to `Editor > Editor Settings > Export > Android`.
3. Set the Android SDK path, JDK path, and debug keystore path.
4. Go to `Project > Export`.
5. Use the existing `Android AAB Release` or `Android APK Debug` preset.
6. Confirm package name: `com.kadioko.daladalarush`.
7. Set orientation to portrait.
8. Keep Gradle/custom build enabled and export **AAB** for Google Play. The current
   release preset writes `exports/android/DalaDalaRushTZ-release.aab`.
9. Before the next upload, set version name `1.0.5` and version code `6` in
   both Android presets. Every Play upload needs a higher version code.

The 4.7.1 Android template is installed and identified by
`android/.build_version`. Both `armeabi-v7a` and `arm64-v8a` are enabled in the
current presets. Release signing files stay outside Git.

## Build

From the editor:

```text
Project > Export > Android > Export Project
```

From CLI if Godot is on PATH:

```bash
godot --export-release "Android AAB Release" exports/android/DalaDalaRushTZ-release.aab
```

The editor export is preferred when signing settings or plugin state have
changed.

## Low-End Phone Checklist

- Keep sprite sizes small.
- Prefer `.ogg` mono audio at 22,050 Hz.
- Keep the object pools in `scripts/game.gd`; avoid spawning and freeing entities every frame.
- Keep Reduced Effects available; it lowers particles, flashes, tilt, shake,
  and hit-stop without changing scoring or collision timing.
- Test with sound and vibration enabled.
- Test with Swahili and English text.
- Check 540x960 and 720x1280 portrait layouts.

## On-Device Test Checklist

Run through this on a real phone before each release:

- [ ] Swipe left/right feels responsive at high speed (adjust `swipe_threshold` in game.gd if not).
- [ ] On-screen left / horn / right controls are reachable with a thumb and
  do not move the bus when Horn is tapped.
- [ ] Android gesture bar and camera cutout do not cover gameplay HUD or any
  secondary-screen button.
- [ ] Hardware back button: pauses during a run, returns to menu from sub-screens, quits from main menu (handled in `transition_manager.gd`).
- [ ] HUD clears the notch/camera cutout (`UIFactory.safe_top_inset` — verify on a notched phone).
- [ ] Haptics fire on tap/crash/powerup (FeedbackManager).
- [ ] Audio works after minimizing and restoring the app.
- [ ] Toggle Reduced Effects in both languages; verify the setting survives a
  restart and rain/boost/crash gameplay remains readable.
- [ ] Save survives force-killing the app (`save.json` + `.bak` recovery).
- [ ] Complete a reward-heavy run, close from results, and verify coins, score,
  missions, daily progress, and lifetime stats restore together after restart.
- [ ] Daily streak grants once per calendar day (change device date to test).
- [ ] Continue-after-crash restores score/coins and grants brief invulnerability.
- [ ] Only one rewarded continue is available per run; Double Coins and
  Continue cannot both be claimed from the same result screen.
- [ ] Performance: steady frame rate after 3+ minutes of play (pools, no leaks).
- [ ] Battery/thermals acceptable after a 10-minute session.
- [ ] Release manifest contains `com.google.android.gms.permission.AD_ID` and
  the AdMob application ID.
- [ ] Rewarded, interstitial, and banner ads are tested with a registered test
  device; no live ads are clicked during QA.

## Ads

See `docs/ADMOB_SETUP.md`. `autoload/ad_service.gd` is the single integration
point. The plugin bridge is wired; editor builds can simulate the flow while
Android builds use the installed SDK.

## Online Leaderboard (later)

The local top-5 leaderboard lives in `save_system.gd`. To go online, the recommended path is **Google Play Games Services v2** via a Godot plugin:

1. Create the game in Google Play Console > Play Games Services.
2. Add a leaderboard, note its ID.
3. Install a GPGS plugin for Godot 4 and submit scores where `SaveSystem.add_to_leaderboard()` is called (game_over.gd `_on_submit_score`).
4. Keep the local leaderboard as offline fallback.
