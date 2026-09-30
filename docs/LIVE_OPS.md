# Live Ops Foundation

Last updated: October 1, 2026. Google Play production is active. Core gameplay
is offline-first; optional Railway services are enabled for consented phone
validation and must pass separate device and policy checks before broad rollout.

## Remote config (`autoload/remote_config.gd`)
Tune the game without shipping an update:

1. The production file is `docs/remote-config.json`, served after a push at
   `https://kadioko.github.io/Dala-Dala-Rush/docs/remote-config.json`.
2. Edit that file through a reviewed Git commit to run a conservative event or
   tuning change. The game keeps the last valid local cache when offline.
3. Use this shape for new values:

```json
{
  "revision": 2,
  "event_banner_sw": "Wikendi ya Sikukuu: zawadi mara mbili!",
  "event_banner_en": "Holiday weekend: double daily rewards!",
  "daily_reward_mult": 2.0,
  "spawn_interval_global": 1.05,
  "fuel_drain_global": 0.9,
  "speed_ramp_global": 0.95,
  "kituo_min_gap": 18,
  "kituo_max_gap": 28,
  "route_tuning": {
    "kariakoo": {"spawn": 1.1, "fuel": 0.92, "passengers": 0.96},
    "ubungo": {"spawn": 1.0, "coins": 1.08, "rush": 0.92}
  }
}
```

Increment `revision` with each published config edit. The client rejects a
lower revision than its cached active config, limits downloads to 64 KiB and
five seconds, and keeps the previous valid cache if a response fails. To roll
back, publish the earlier values under a **higher** revision number. Values
cache locally (`user://remote_config.json`) so the game stays
offline-first; the fetch silently no-ops without network. You can also drop
that file on a test device manually to try values before hosting.

Use `RemoteConfig.get_float()` or `get_route_float()` for gameplay numbers.
They reject non-numeric values and clamp every value to an explicit safe range.
Add defaults before wiring a new control. Route fields currently supported by
the core loop are `spawn`, `fuel`, `coins`, `kituo_min`, `kituo_max`,
`passengers`, `kituo_gap`, and `rush`. Unknown JSON fields and route values are
discarded before they can affect the game.

`event_banner_sw` and `event_banner_en` are optional localized main-menu event
messages. `daily_reward_mult` applies equally to the daily challenge and login
streak reward, clamps from `1.0` to `2.0`, and should be used for short,
announced events only. Do not use it for ad rewards, permanent route rewards,
or referrals.

Current status: the client URL now matches the GitHub Pages file path. The
published JSON is optional; failures leave cached/default values unchanged.

## Analytics (`autoload/analytics_service.gd`)
`AnalyticsService.log_event(name, params)` writes every event to a local,
offline-first JSON journal capped at 500 events on every event. It accepts only small primitive
parameters and deliberately strips keys containing `code` or `name`, so invite
codes and player-entered leaderboard text never enter the journal.

Instrumented events include `app_open`, local D1/D7 return markers, `run_start`, `run_end`, `run_reputation`, `route_mastery_earned`,
route-moment start/completion, vehicle unlocks, all three
tutorial stage/step events, route selection, remote-config source, referral
funnel actions, rewarded/interstitial requests and loads/failures, and banner
loads/failures. `run_end` records route, distance, passengers, goal result,
end reason, condition, and tutorial stage without PII.

To send these events to production analytics, connect a deliberately chosen
analytics/crash-reporting SDK and forward sanitized entries in `_send_to_sdk()`.
Firebase remains an optional telemetry-only route; it is not the game database.
Crash reporting is **not yet installed**; `report_nonfatal()` currently journals
a sanitized breadcrumb only. Do not claim production crash reporting until the
selected integration is installed, configured, and tested on an Android release
build.

Current status: `_send_to_sdk()` is a no-op. The capped event queue remains on
the device and is not uploaded by this project. Referral funnel events record
only the action, reward amount, count, and broad runtime platform; invite and
confirmation codes are never added to analytics parameters.

Events worth adding with future screens: `route_unlocked`, `upgrade_bought`,
`mission_complete`, and server-verified referral activation. Keep Play Billing
events out until billing is actually enabled.

The local lifecycle fields in `save.json` are aggregate timestamps and a session
count. They exist only to make a later retention integration possible; no data
leaves the device in the current build.

For consented Railway aggregates and caveats, see
`docs/PRODUCTION_REPORTING.md`. It includes read-only route, tutorial, and
leaderboard summaries and calls out the missing telemetry retention job.

## Release Guardrails

- Keep remote config optional: the shipped gameplay must remain playable with
  no network connection and with the cached defaults only.
- Do not use remote config to remove the one-revive-per-run rule or to add
  gameplay banners. Ads remain menu/results-only by policy.
- Test a remote-config change on a debug build before publishing it; malformed
  values should always fall back to the local defaults.

## Railway Online Services (Deployed, Consent-Gated)

`backend/` is the deployed Railway + PostgreSQL service for optional cloud save,
server-side referral activation gates, a non-reward-bearing unverified
leaderboard, and consented minimal Gameplay Insights. `OnlineService` is
enabled, but no information leaves a phone until the player opts in to the
specific feature. Deployment, migration, data boundaries, and the mandatory
validation work are in
`docs/RAILWAY_BACKEND.md`.

Backend request limits now use shared PostgreSQL counters from
`backend/sql/006_shared_rate_limits.sql`, with HMACed subjects and fixed expiry
windows. Migration 006 and the matching API are deployed; Railway's
`preDeployCommand` runs `npm run migrate` before future API deployments. The
privacy-policy update and remote-config revision 2 are published. See
`docs/RAILWAY_BACKEND.md` for production verification and remaining device QA.

Cloud sync sends a filtered snapshot, never the full local save: it omits
referral codes, local leaderboard names, analytics history, and sync tokens.
The server uses monotonic save revisions; a stale write gets a conflict instead
of overwriting a newer backup.

## Online Leaderboards (Consent-Gated Pilot)
The Railway service now supports an explicit leaderboard opt-in, a short public
driver name, one best score per driver/route, and 24-hour friend codes. The
personal board remains local and works offline. The friends and world boards
remain labelled **unverified** and have no rewards. Complete two-phone QA and
align the published privacy policy and Play Data Safety declaration before
broad rollout.

Keep the offline ghost-code system as the shareable social fallback. Add Play
Integrity or server-side run validation before describing any score as verified
or attaching rewards to a ranking.

## Download Size Budget

The latest local AABs are approximately 57-59 MB before Play delivery splits.
Measure Play Console's reported download size rather than promising a 30 MB
bundle. Biggest future growth risks are audio, duplicate assets, debug symbols,
and uncompressed textures. Keep audio compressed, keep textures modest, and
review the final bundle with Play Console's bundle explorer.
