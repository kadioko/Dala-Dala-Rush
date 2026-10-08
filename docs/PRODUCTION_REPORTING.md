# Production Gameplay Report

Use these read-only PostgreSQL queries in Railway after a player has opted in
to Gameplay Insights. They query only the allowlisted aggregate events already
accepted by `/v1/telemetry`; they do not expose player names, codes, or save data.
No report is meaningful until consented event volume is large enough to avoid
identifying individual play patterns. Do not export installation IDs.

## Daily Health

```sql
SELECT date_trunc('day', received_at)::date AS day,
       event_name,
       count(*) AS events,
       count(DISTINCT installation_id) AS opted_in_devices
FROM telemetry_events
WHERE received_at >= now() - interval '30 days'
GROUP BY 1, 2
ORDER BY 1 DESC, 2;
```

This is event volume, not users or retention by itself. The `app_open` event is
not currently in the Railway allowlist, so use `retention_return` only as an
opt-in return marker and do not treat it as a complete D1/D7 cohort report.

## Route And Run Friction

```sql
SELECT route_id,
       properties->>'end_reason' AS end_reason,
       count(*) AS runs,
       round(avg((properties->>'distance')::numeric), 0) AS avg_distance,
       round(avg((properties->>'coins')::numeric), 1) AS avg_coins,
       round(avg((properties->>'goal_met')::boolean::int), 3) AS goal_rate
FROM telemetry_events
WHERE event_name = 'run_end'
  AND received_at >= now() - interval '30 days'
GROUP BY route_id, properties->>'end_reason'
ORDER BY route_id, runs DESC;
```

Compare route results only after enough opted-in runs. A high fuel-failure or
collision share can guide a phone QA session; it does not prove the game caused
the outcome or that the route should be made easier.

## First-Session Lessons

```sql
SELECT (properties->>'stage')::int AS lesson_stage,
       count(*) AS completions,
       count(DISTINCT installation_id) AS devices
FROM telemetry_events
WHERE event_name = 'tutorial_stage_finished'
  AND received_at >= now() - interval '30 days'
GROUP BY 1
ORDER BY 1;
```

The current event is emitted only after a lesson run ends. It does not measure
every tutorial step or identify the exact point where a player leaves. Keep
the metric labelled “completed lesson runs”; instrument finer steps only when
the consent copy and data-safety disclosure are reviewed.

## Coin Pace And First Vehicle Unlock

Run-end events include run duration and earned coins; unlock events include the
vehicle, price, and number of runs completed at purchase. These are opt-in
events and should be reviewed only as aggregates.

```sql
SELECT route_id,
       round(avg((properties->>'coins')::numeric
         / NULLIF((properties->>'elapsed')::numeric / 60.0, 0)), 1) AS coins_per_minute
FROM telemetry_events
WHERE event_name = 'run_end'
  AND NULLIF(properties->>'elapsed', '') IS NOT NULL
  AND received_at >= now() - interval '30 days'
GROUP BY route_id
ORDER BY route_id;

SELECT properties->>'vehicle' AS vehicle,
       count(DISTINCT installation_id) AS opted_in_devices,
       round(avg((properties->>'runs')::numeric), 1) AS avg_runs_before_unlock,
       round(avg((properties->>'price')::numeric), 0) AS avg_coin_price
FROM telemetry_events
WHERE event_name = 'vehicle_unlocked'
  AND received_at >= now() - interval '30 days'
GROUP BY properties->>'vehicle'
ORDER BY opted_in_devices DESC;
```

## Score Upload Reliability

```sql
SELECT date_trunc('day', received_at)::date AS day,
       count(*) FILTER (WHERE event_name = 'online_leaderboard_submit') AS submits,
       count(*) FILTER (WHERE event_name = 'online_leaderboard_global') AS world_reads,
       count(*) FILTER (WHERE event_name = 'online_leaderboard_friends') AS friend_reads
FROM telemetry_events
WHERE received_at >= now() - interval '30 days'
GROUP BY 1
ORDER BY 1 DESC;
```

These counters show consented requests recorded by the client. They are not
server acceptance rates; compare with API logs and do not infer successful
publication from a client request event alone.

## Route Moments And Fuel Friction

The client now sends allowlisted `route_moment_start`,
`route_moment_complete`, `route_moment_timeout`, and `fuel_failure` events only
when the player has enabled Gameplay Insights. Use these aggregates to decide
which routes or event cues deserve a phone QA session; low counts are not proof
that an event is confusing.

```sql
SELECT route_id,
       count(*) FILTER (WHERE event_name = 'route_moment_start') AS started,
       count(*) FILTER (WHERE event_name = 'route_moment_complete') AS completed,
       count(*) FILTER (WHERE event_name = 'route_moment_timeout') AS timed_out,
       count(*) FILTER (WHERE event_name = 'fuel_failure') AS fuel_failures
FROM telemetry_events
WHERE received_at >= now() - interval '30 days'
GROUP BY route_id
ORDER BY route_id;
```

Compare started/completed only after enough opted-in runs. A timeout can mean
the target could not safely spawn, the player did not complete it, or the run
ended first; combine with run-end data and device QA before changing rewards.

## Limits And Retention

- The local event journal is capped at 500 entries; consented Railway batches
  are limited to 25 events and events older than 14 days are rejected.
- Gameplay Insights events are purged after 90 days in bounded batches. The
  cleanup runs at service startup and every six hours; transient database
  outages can delay removal until a later pass. Keep the published policy
  aligned with this window.
- Production crash/ANR reporting is not installed. Use Play Console Android
  vitals for user-perceived crashes, ANRs, and slow sessions; do not present
  this event table as crash reporting.

## Leaderboard Reports

Reports are fixed-reason, rate-limited entries for manual review. Do not
automatically remove a public profile based on one report. Review only the
minimum fields needed and record the action without exporting installation IDs.

```sql
SELECT id, reported_name, reason, route_id, created_at
FROM leaderboard_reports
WHERE reviewed_at IS NULL
ORDER BY created_at ASC
LIMIT 100;
```

After review, mark the row reviewed with a parameterized update in the Railway
database console. Reports older than 90 days are purged by the service cleanup.
