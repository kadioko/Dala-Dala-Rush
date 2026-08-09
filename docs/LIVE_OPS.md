# Live Ops Foundation

Last verified: August 9, 2026. These systems are offline scaffolds and are not
connected to production services in the current closed-testing build.

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

Current status: `REMOTE_URL` is empty, so no network fetch occurs. Local cached
JSON remains available for development tests.

## Analytics (`autoload/analytics_service.gd`)
`AnalyticsService.log_event(name, params)` queues events to a local log
(offline-first, capped at 500). `run_end` is already instrumented with
score/coins/dropoffs/route/condition. To go live, install a Firebase
Analytics plugin for Godot 4 and forward in `_send_to_sdk()`. Crashlytics
comes with the same plugin family.

Current status: `_send_to_sdk()` is a no-op. The capped event queue remains on
the device and is not uploaded by this project.

Events worth adding as you tune: `route_unlocked`, `upgrade_bought`,
`mission_complete`, `ad_continue_used`, `iap_purchase`.

## Release Guardrails

- Keep remote config optional: the shipped gameplay must remain playable with
  no network connection and with the cached defaults only.
- Do not use remote config to remove the one-revive-per-run rule or to add
  gameplay banners. Ads remain menu/results-only by policy.
- Test a remote-config change on a debug build before publishing it; malformed
  values should always fall back to the local defaults.

## Cloud save (later)
The whole save is one JSON dict (save_system.gd `data`). Cloud save =
serialize that dict to any per-user storage (Play Games Saved Games API,
or Firebase). Conflict rule suggestion: keep the save with more
`total_distance_ever`.

## Online leaderboards (later)
See docs/ANDROID_EXPORT.md — Play Games Services v2. The ghost-code system
(leaderboard screen) already gives social competition offline; GPGS adds
the global table.

## Download Size Budget

The latest local AABs are approximately 57-59 MB before Play delivery splits.
Measure Play Console's reported download size rather than promising a 30 MB
bundle. Biggest future growth risks are audio, duplicate assets, debug symbols,
and uncompressed textures. Keep audio compressed, keep textures modest, and
review the final bundle with Play Console's bundle explorer.
