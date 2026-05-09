# Dala Dala Rush TZ 🚌

A Tanzanian-style 2D endless driving game built with **Godot 4**.  
Dodge bodabodas, bajajis, potholes, and police checkpoints while collecting passengers and coins through the streets of Dar es Salaam.

## Current Prototype Status

This repo is now a playable offline MVP with:
- Swahili and English UI text selectable from Settings.
- Saved progress: high score, route bests, total coins, unlocks, settings, achievements, and local leaderboard.
- Mobile-first controls: swipe, lane buttons, pause, horn, and optional vibration.
- Procedural 2D visuals and synthesized placeholder SFX, so the project runs without external assets.
- Rewarded-ad placeholder hooks for "continue after crash" and "double coins" without shipping any real ad SDK.
- Route-specific traffic profiles, so Kariakoo, Posta, Kigamboni, and Ubungo do not spawn the same mix of hazards.
- Route-specific run goals with bonus coin rewards.
- Vehicle skins with light gameplay perks: handling, fuel efficiency, coin gain, and horn charges.
- Offline daily challenges that rotate by local date and reward bonus coins once per day.

Extra docs live in `docs/`:
- `docs/UPGRADES.md` - current improvements, next upgrade plan, and balancing notes.
- `docs/CONTENT_GUIDE.md` - how to add routes, obstacles, collectibles, vehicles, and localization keys.
- `docs/ANDROID_EXPORT.md` - Android export checklist and low-end phone optimization notes.

---

## Quick Start

### Requirements
| Tool | Version |
|------|---------|
| Godot Engine | 4.2+ (Standard or Mono) |
| Android SDK | API 21+ (for Android export) |
| JDK | 17+ |

### Run in Editor
1. Download [Godot 4](https://godotengine.org/download/) (the plain GDScript version, not .NET).
2. Open Godot → **Import** → select this folder's `project.godot`.
3. Press **F5** or click the Play button.

The game runs entirely without external art or audio files — all graphics are drawn procedurally via GDScript `_draw()` and sounds are synthesised at runtime.

---

## Project Structure

```
Dala Dala Rush TZ/
├── project.godot              # Godot project config, autoloads, display settings
├── icon.svg                   # App icon
│
├── autoload/                  # Singletons (always in memory)
│   ├── save_system.gd         # JSON save/load (high score, coins, unlocks, settings)
│   ├── locale_manager.gd      # Swahili / English selector + all UI strings
│   ├── audio_manager.gd       # SFX/music hub (procedural beeps, swap in real .ogg later)
│   ├── feedback_manager.gd    # Optional Android vibration / haptics
│   ├── ad_service.gd          # Rewarded-ad placeholder hooks, no real SDK
│   └── game_state.gd          # Selected vehicle, route, and last-run stats
│
├── data/
│   ├── vehicles.gd            # Vehicle catalog (id, price, colors)
│   └── routes.gd              # Route catalog (id, difficulty, colors)
│
├── docs/                      # Upgrade notes, Android guide, content guide
│
├── scenes/                    # .tscn scene files (minimal — scripts build UI in code)
│   ├── splash.tscn
│   ├── main_menu.tscn
│   ├── garage.tscn
│   ├── routes.tscn
│   ├── shop.tscn
│   ├── settings.tscn
│   ├── how_to_play.tscn
│   ├── game.tscn              # ← main gameplay scene
│   └── game_over.tscn
│
├── scripts/
│   ├── splash.gd
│   ├── main_menu.gd
│   ├── garage.gd
│   ├── routes_screen.gd
│   ├── shop.gd
│   ├── settings_screen.gd
│   ├── how_to_play.gd
│   ├── game.gd                # Core loop: spawning, pooling, collisions, input
│   ├── game_over.gd
│   └── entities/
│       ├── player.gd          # Dala dala: lanes, tween movement, AABB
│       ├── obstacle.gd        # 10 obstacle types drawn procedurally
│       ├── collectible.gd     # 7 collectible types with animated draw
│       └── road.gd            # Scrolling road with lanes, side decor
│
├── ui/
│   └── ui_factory.gd          # Helper: themed buttons, labels, panels, backgrounds
│
├── assets/                    # Drop real sprite PNGs here (see "Adding Real Art" below)
└── audio/                     # Drop real .ogg/.wav SFX here (see "Adding Real Audio")
```

---

## Controls

| Input | Action |
|-------|--------|
| Swipe left / tap ◀ | Move dala dala left one lane |
| Swipe right / tap ▶ | Move dala dala right one lane |
| A / ← arrow | Move left (keyboard, editor testing) |
| D / → arrow | Move right (keyboard, editor testing) |
| Escape | Pause |
| Touch anywhere (splash) | Skip to menu |

Optional vibration can be enabled or disabled in **Settings → Vibration**. It is used only on mobile builds.

---

## Gameplay Systems

### Speed & Difficulty
- Base speed increases with each route's `difficulty` multiplier.
- Speed ramps up by **15 % every 20 seconds** during a run.
- After 60 s two or more lanes can be blocked simultaneously.
- Every route has its own `obstacle_weights` and `collectible_weights` in `data/routes.gd`.
- Every route has a `goal_type`, `goal_target`, and `goal_reward`.

### Scoring
| Event | Points |
|-------|--------|
| Distance traveled | `distance × 0.1` |
| Passenger collected | +200 distance bonus |
| Fuel can | +300 distance bonus |
| Speed boost | +400 distance bonus |
| Near-miss obstacle | +80 distance bonus |
| Route goal completed | Bonus coins at Game Over |

### Power-Ups
| Item | Effect | Duration |
|------|--------|---------|
| Shield 🛡 | Absorbs one crash | Until hit |
| Magnet 🧲 | Attracts nearby coins | 6 s |
| Slow ❄️ | Halves obstacle speed | 4 s |
| Fuel ⛽ | Bonus score | Instant |
| Speed Boost ⚡ | Bonus score | Instant |

### Vehicle Perks
- `lane_time`: controls lane-switch speed.
- `fuel_drain_mult`: modifies fuel drain.
- `coin_mult`: modifies coin pickup value.
- `horn_charges`: controls starting and maximum horn charges.

### Daily Challenge
- `data/daily_challenges.gd` picks one challenge from the local date.
- Challenges work offline and do not need an account.
- Rewards can be claimed once per calendar day.

### Object Pooling
Obstacles and collectibles are pooled (24 obstacles, 16 collectibles).  
Spawned items are moved back to the free pool when they scroll off-screen.  
This prevents GC spikes on low-RAM Android devices.

---

## Language Switch

Open **Settings → Choose Language** and select **Kiswahili** or **English**.  
The setting is saved and restored on next launch.

To add a new language:
1. Add a new locale key (`"fr"`, `"de"`, etc.) to `autoload/locale_manager.gd` → `strings` dictionary.
2. Fill in all translation keys (copy the `"en"` block as a template).
3. Add a selector button in `scripts/settings_screen.gd` if you want it visible in Settings.

---

## Adding New Content

### New Route
Open `data/routes.gd` and append to `LIST`:
```gdscript
{
    "id": "temeke",
    "name_key": "ROUTE_TEMEKE",          # add to locale_manager.gd too
    "difficulty": 2.0,
    "sky": Color("#dfe6e9"),
    "road": Color("#1a1a2e"),
},
```

### New Vehicle
Open `data/vehicles.gd` and append to `LIST`:
```gdscript
{
    "id": "green_daladala",
    "name_key": "VEH_GREEN",             # add to locale_manager.gd too
    "price": 2000,
    "body": Color("#00b894"),
    "accent": Color("#fdcb6e"),
},
```
All drawing is automatic — no sprite files needed.

### New Obstacle Type
Open `scripts/entities/obstacle.gd` → add to `TYPES`:
```gdscript
"ambulance": {"color": Color("#ffffff"), "size": Vector2(70, 110)},
```
Then add a draw case inside `_draw()` (or it will fall through to the generic vehicle shape).  
Finally add `"ambulance"` to `OBSTACLE_TYPES` in `scripts/game.gd`.

### New Collectible Type
Open `scripts/entities/collectible.gd` → add to `TYPES` and add a draw case in `_draw()`.  
Handle its effect in `scripts/game.gd` → `_on_collect()`.

---

## Adding Real Art

Replace procedural drawing with sprites:
1. Drop PNG files into `assets/` (recommended atlas: one .png per entity).
2. In the entity script's `_ready()` create a `Sprite2D`, assign `texture = load("res://assets/player.png")`.
3. Comment out or remove the `_draw()` override.

Keep sprites small: 128×128 px max for vehicles/obstacles. Use `.import` settings: `compress/mode=2` (lossy VRAM) for Android.

---

## Adding Real Audio

1. Export audio as `.ogg` (Vorbis, mono, 22 050 Hz, ~64 kbps).
2. Drop files into `audio/` — e.g. `audio/coin.ogg`.
3. In `autoload/audio_manager.gd` → `_load_streams()`, replace:
   ```gdscript
   "coin": _make_tone(880.0, 0.08),
   ```
   with:
   ```gdscript
   "coin": load("res://audio/coin.ogg"),
   ```

---

## Android Export

### One-time setup
1. In Godot Editor → **Editor → Export** → **Add → Android**.
2. Fill in:
   - **Package**: `com.yourname.daladarush`
   - **Version Name** / **Version Code**: `1.0` / `1`
3. Under **Signing**, generate a keystore (`keytool -genkey ...`) and link it.
4. Enable **Use Custom Build** (requires Android SDK path set in Editor Settings).
5. Set **Orientation** → **Portrait**.

### Build
```
# From Editor:
Project → Export → Android → Export Project (APK)
```

Or with CLI:
```bash
godot --export-release "Android" bin/DalaDalaRush.apk
```

### Minimum spec target
- **minSdkVersion**: 21 (Android 5.0)
- **targetSdkVersion**: 34
- Runs on 1 GB RAM phones; tested at 540 × 960 resolution.

---

## Monetisation Placeholders

The codebase is ready for ads; no real SDK is wired in the MVP.

| Placement | Where to add |
|-----------|-------------|
| Rewarded ad: continue after crash | `autoload/ad_service.gd` → `show_rewarded_continue()` |
| Rewarded ad: double coins | `autoload/ad_service.gd` → `show_rewarded_double_coins()` |
| Remove Ads IAP | `shop.gd` — add a product row |

Integrate the [Godot AdMob plugin](https://github.com/Shin-NiL/Godot-Android-Admob-Plugin) or GodotGooglePlayBilling for IAP.

---

## Save File Location

| Platform | Path |
|----------|------|
| Android | `/data/data/<package>/files/save.json` |
| Windows (dev) | `%APPDATA%\Godot\app_userdata\Dala Dala Rush TZ\save.json` |
| Linux (dev) | `~/.local/share/godot/app_userdata/Dala Dala Rush TZ/save.json` |

---

## Extending the Project

| Feature | Suggested approach |
|---------|--------------------|
| Background music | `AudioManager` already has `_music_player`; load a looping `.ogg` and call `_music_player.play()` |
| Leaderboard | Add a `leaderboard.gd` autoload; POST score to a Firebase Realtime DB REST endpoint |
| Daily challenges | Store challenge seed + target in `save_system.gd`; check on `_ready()` in `main_menu.gd` |
| Haptic feedback | `Input.vibrate_handheld(80)` on coin/crash |
| Animated sprites | Swap `_draw()` overrides for `AnimatedSprite2D` nodes in entity scripts |

---

*Built with Godot 4 · GDScript · No third-party dependencies · Works offline*
