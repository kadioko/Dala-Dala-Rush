# Live Ops Foundation

## Remote config (`autoload/remote_config.gd`)
Tune the game without shipping an update:

1. Host a JSON file anywhere static (GitHub Pages, Firebase Hosting, any bucket).
2. Set `REMOTE_URL` in remote_config.gd.
3. Edit the JSON to run events, e.g.:

```json
{
  "event_banner": "Wikendi ya Sikukuu: zawadi mara mbili!",
  "daily_reward_mult": 2.0,
  "spawn_interval_global": 1.05
}
```

Values cache locally (`user://remote_config.json`) so the game stays
offline-first; the fetch silently no-ops without network. You can also drop
that file on a test device manually to try values before hosting.

Wire new knobs by reading `RemoteConfig.get_value("key", default)` at the
point of use and adding a default to `DEFAULTS`.

## Analytics (`autoload/analytics_service.gd`)
`AnalyticsService.log_event(name, params)` queues events to a local log
(offline-first, capped at 500). `run_end` is already instrumented with
score/coins/dropoffs/route/condition. To go live, install a Firebase
Analytics plugin for Godot 4 and forward in `_send_to_sdk()`. Crashlytics
comes with the same plugin family.

Events worth adding as you tune: `route_unlocked`, `upgrade_bought`,
`mission_complete`, `ad_continue_used`, `iap_purchase`.

## Cloud save (later)
The whole save is one JSON dict (save_system.gd `data`). Cloud save =
serialize that dict to any per-user storage (Play Games Saved Games API,
or Firebase). Conflict rule suggestion: keep the save with more
`total_distance_ever`.

## Online leaderboards (later)
See docs/ANDROID_EXPORT.md — Play Games Services v2. The ghost-code system
(leaderboard screen) already gives social competition offline; GPGS adds
the global table.

## APK size budget
Stay under 30 MB and advertise offline play on the store listing. Current
build is tiny (procedural art/audio). Biggest future risks: audio files
(keep OGG mono 22 kHz) and sprite sheets (keep PNGs small, let Godot
compress with ETC2).
