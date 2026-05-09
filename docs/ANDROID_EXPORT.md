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

## Ad SDK Note

`autoload/ad_service.gd` is intentionally a no-network placeholder. When adding a real rewarded-ad SDK:

1. Keep all SDK-specific code inside `AdService`.
2. Make `show_rewarded_continue()` return true only after the reward callback fires.
3. Make `show_rewarded_double_coins()` return true only after the reward callback fires.
4. Do not block the main thread while waiting for ads.
