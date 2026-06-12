# Android Export Guide

## Target

- Orientation: portrait.
- Minimum SDK: Android 5.0 / API 21.
- Renderer: GL Compatibility.
- Offline-first: no required network access for MVP.
- Target phones: low to mid-range Android devices common in Tanzania.

## Godot Setup

1. Open `project.godot` in Godot 4.2 or newer.
2. Go to `Editor > Editor Settings > Export > Android`.
3. Set the Android SDK path, JDK path, and debug keystore path.
4. Go to `Project > Export`.
5. Add an Android preset.
6. Set package name, for example `com.yourname.daladalrushtz`.
7. Set orientation to portrait.

## Build

From the editor:

```text
Project > Export > Android > Export Project
```

From CLI if Godot is on PATH:

```bash
godot --export-release "Android" bin/DalaDalaRushTZ.apk
```

## Low-End Phone Checklist

- Keep sprite sizes small.
- Prefer `.ogg` mono audio at 22,050 Hz.
- Keep the object pools in `scripts/game.gd`; avoid spawning and freeing entities every frame.
- Test with sound and vibration enabled.
- Test with Swahili and English text.
- Check 540x960 and 720x1280 portrait layouts.

## On-Device Test Checklist

Run through this on a real phone before each release:

- [ ] Swipe left/right feels responsive at high speed (adjust `swipe_threshold` in game.gd if not).
- [ ] On-screen ◀ / 📯 / ▶ buttons are reachable with a thumb.
- [ ] Hardware back button: pauses during a run, returns to menu from sub-screens, quits from main menu (handled in `transition_manager.gd`).
- [ ] HUD clears the notch/camera cutout (`UIFactory.safe_top_inset` — verify on a notched phone).
- [ ] Haptics fire on tap/crash/powerup (FeedbackManager).
- [ ] Audio works after minimizing and restoring the app.
- [ ] Save survives force-killing the app (save.json + save.json.bak rotation).
- [ ] Daily streak grants once per calendar day (change device date to test).
- [ ] Continue-after-crash restores score/coins and grants brief invulnerability.
- [ ] Performance: steady frame rate after 3+ minutes of play (pools, no leaks).
- [ ] Battery/thermals acceptable after a 10-minute session.

## Ads

See `docs/ADMOB_SETUP.md`. `autoload/ad_service.gd` is the single integration point — keep all SDK code inside it. In debug builds the service simulates successful ads so the continue/double-coins flows can be tested without a device or SDK.

## Online Leaderboard (later)

The local top-5 leaderboard lives in `save_system.gd`. To go online, the recommended path is **Google Play Games Services v2** via a Godot plugin:

1. Create the game in Google Play Console > Play Games Services.
2. Add a leaderboard, note its ID.
3. Install a GPGS plugin for Godot 4 and submit scores where `SaveSystem.add_to_leaderboard()` is called (game_over.gd `_on_submit_score`).
4. Keep the local leaderboard as offline fallback.
