# Deep Product And Reliability Audit

**Follow-up:** the eight findings below now have source fixes or explicitly
corrected product claims. See `TRUST_UPDATE.md` for implementation, regression
results and outstanding deployment/device acceptance. This document preserves
the original audit evidence and line numbers; it is not the current bug list.

Date: October 18, 2026. Scope: current working tree, including the unreleased
responsive/recovery implementation. This is a follow-up audit, **not** a claim
that the findings below were fixed. Gameplay/backend source was not changed
for this audit. Temporary probes were removed after use.

## Summary

The next valuable update is a reliability and competition-trust release,
followed by focused driving/presentation improvements. New currencies, more
city packs and crews should not displace the issues below. Passing existing
tests does not cover lost transfer acknowledgements, nested save corruption,
large replay backups, or actual HUD-button buffering.

## Confirmed Findings

### 1. P1: Ad Consent Is Not Wired Into The Game

Evidence: `autoload/ad_service.gd:63`, `:160`, `:187`. Startup initializes Mobile
Ads and its callback immediately loads rewarded/interstitial ads. Banner loads
also bypass a consent gate. The bundled UMP API and sample exist, but no game
autoload or Settings code invokes the consent update/form/privacy-options flow.
Cloud/leaderboard/telemetry opt-ins do not substitute for advertising consent.

Action: configure applicable AdMob messages, wire a consent coordinator, check
SDK permission to request ads, and expose privacy options when required. Verify
whether the installed Godot bridge exposes the required current APIs before
choosing a compatible plugin update. Do not blindly patch vendor scripts or
replace this with a local boolean. Keep offline play available.

Acceptance: registered test devices, required/not-required regions, previous
consent, offline launch, failed consent update, privacy-option changes, and one
initialization/load sequence. AdMob console configuration was not inspected.
This is a confirmed integration gap, not a finding about every user's region
or a legal determination. Follow Google's current
[UMP integration guidance](https://developers.google.com/admob/android/privacy).

### 2. P1: A Lost Phone-Transfer Response Can Lock Out Both Phones

Evidence: `backend/src/server.js:397`, `:419`, `:423`. The transaction consumes
the transfer code and rotates the only sync token before returning the new
credential. In an isolated real PostgreSQL probe, first claim returned 200,
retrying the same code returned 404, and the source token returned 401.
If the successful response is lost, neither phone has the new credential.

Action: design an acknowledged, retry-safe handover rather than applying cloud
save idempotency mechanically to a credential response. Options include a
short-lived claim session tied to a client-generated secret and a bounded,
securely replayable result, with old-token grace/revocation rules. Never log or
store recovery credentials in plaintext for convenience.

Acceptance: response loss before/after commit, duplicate claim, concurrent
claimers, process death, expired claim, final acknowledgement and old-token
revocation. A second pre-existing transfer code also returned 200 after the
first transfer: invalidate other outstanding codes when a transfer completes.

### 3. P1: Save Validation Can Accept A Broken Primary And Unsafe Nested Data

Evidence: `autoload/save_system.gd:134`, `:143`; `data/missions.gd:29`, `:49`.
The probe confirmed `_load_from()` accepts `{}`. Backup fallback only happens
when loading returns false, so a syntactically valid but empty primary is
treated as a good save. Subsequent writes can rotate that incomplete primary
over a useful backup. Nested missions such as `["broken", {"progress":"invalid"}, {}]`
survive normalization, although mission consumers expect `tid` and numeric
`progress` on every entry.

Action: validate an envelope, supported schema, bounds and nested structures
before adopting progress. Validate missions, liveries, replays and queued
operations individually; quarantine bad primaries and preserve the good backup.
Add a future-schema/read-only recovery path rather than silently downgrading.

Acceptance: empty/unknown-only dictionaries, missing fields from genuine older
schemas, malformed mission rows, truncated writes, future schemas, bad livery
colors and bounded file size. Recovery must preserve currency and unlocks.

### 4. P2: HUD Buttons Bypass The Benefit Of Buffered Steering

Evidence: `scripts/game.gd:1204`; `scripts/entities/player.gd:53`.
The probe moved from lane 0 toward lane 1, called `_update_hud()`, and observed
both steering buttons disabled while the bus was moving. Direct Player calls
can buffer another turn, but real Button input cannot activate a disabled
button. This explains a remaining keyboard/swipe-versus-button inconsistency.

Action: represent legal buffered intentions in button state, with clear lane
edge/queued-turn feedback. Test real GUI input delivery instead of only calling
`Player.move_right()` or directly emitting a button signal.

Acceptance: rapid same/opposite taps at multiple rates, all lane edges, keyboard
parity, multi-touch horn isolation and pause/resume queue cancellation.

### 5. P2: Valid Replays Can Make Cloud Backup Too Large

Evidence: `autoload/online_service.gd:13`, `:72`, `:287`;
`data/ghost_data.gd:7`. Four valid 2,048-event clips in `ghost_best`,
`ghost_rival`, `latest_replay` and `daily_replay_best` produced an 81,483-byte
snapshot, above the 65,536-byte limit. Backup is then rejected even though
currency and unlock data remain small and valid.

Action: separate essential progression from optional replay payloads, deduplicate
identical clips, and give replays their own bounded storage/retention policy.
Prefer excluding optional clips with an explicit message over blindly raising
the server limit. Display last successful backup and actionable size errors.

Acceptance: four distinct maximum clips, duplicate clips, large liveries and
missions, old backups and uninterrupted essential-progress backup.

### 6. P2: Leaving Rankings Removes Other Players' Blocks

Evidence: `backend/src/server.js:476`. Leaving removes all block rows where the
leaving installation is either the blocker or the blocked player. The real
database probe created B-blocks-A, had A leave/rejoin, then observed B's block
list fall from one entry to zero without B choosing to unblock.

Action: preserve blocks owned by another installation across public-profile
leave/rejoin. Distinguish public profile removal from complete installation
deletion, with an explicit retention/deletion policy for private safety state.

Acceptance: target leave/rejoin, rename, renewed friend codes, blocker unblock,
moderator hide/restore and full-account deletion. Fresh anonymous identities
remain a separate abuse risk; do not promise unbreakable identity blocking.

### 7. P2: Results Navigation Remains Available During A Reward Request

Evidence: `scripts/game_over.gd:579`, `:631`, `:644`.
The debug-flow probe observed `_reward_in_progress=true` while Play Again and
Main Menu remained enabled. A transition can discard the scene that owns the
callback or race the revive transition. Native-ad overlays reduce exposure
while visible but do not solve pre-show/failure/back-button timing.

Action: centralize Results navigation/reward state, guard hardware back and
ordinary actions until dismissal/failure, and bind callbacks to a unique run
and reward operation. Current in-memory `rewarded_choice_used` prevents repeated
claims in one process, not every interruption between an earned SDK reward and
durable storage. Define the recovery guarantees honestly; fully authoritative
rewards require an appropriate server verification design.

Acceptance: navigation before show, fail-to-show, reward-before-dismissal,
duplicate callbacks, app background/kill and write failure. This probe verified
the enabled-control race, not a lost reward on a physical phone.

### 8. P2: Daily Matching Does Not Guarantee Identical Traffic

Evidence: `scripts/game.gd:2184`, `:2196` and `plan_wave_lanes()`.
Wave generation uses the actual player's current lane. With identical RNG
seeds/clear lanes, lane-0 versus lane-2 input produced different plans in
65 of 100 tested seeds. Version metadata prevents incompatible clips but does
not make their traffic an identical course.

Action: choose the product promise. Either label Daily Runs as shared settings
with adaptive traffic, or generate and validate an input-independent daily
timeline in normalized coordinates. Preserve the ordinary adaptive mode.
Different viewport geometry and input types need deterministic replay tests.
Do not describe this as anti-cheat or authoritative run verification.

### 9. P2: Long Runs Can Lose Their Shareable Replay

Evidence: `scripts/game.gd:2622`, `:1763`; `data/ghost_data.gd:22`.
Recording appends without a cap. A 2,049-move otherwise valid run was rejected
by sanitization, producing an empty replay. `_end_run()` stores that as the
latest clip. This is a recorder/validator contract mismatch.

Action: bound recording, compress input transitions or preserve a clearly
labelled replay window. Never silently replace a usable clip with an empty one.
Test the round-trip encoded-size limit as well as event count/duration limits.

### 10. P2: Telemetry Properties Need Per-Event Schemas

Evidence: `backend/src/server.js:127`, `:820`. A `run_end` event containing
`{"notes":"unexpected free text"}` returned 201 and retained that field.
Event names are allowlisted, but properties are a scalar/key blacklist rather
than typed per-event contracts. This does not prove current game code sends
personal data; it proves the API does not enforce the stronger restriction.

Action: allow only documented keys/types/ranges/enums for each event, explicitly
version schemas and reject/drop everything else. Keep legacy compatibility
intentional, and keep consent/retention declarations accurate.

### 11. P2: Logical Run Reporting Can Count A Revive Twice

Evidence: `scripts/game.gd:2649`, `:2656`, and the Run Friction query in
`docs/PRODUCTION_REPORTING.md`. Both the initial crash and continued crash emit
`run_end`, with new event IDs and cumulative distance/time/coins. Transport UUID
deduplication correctly does not merge them, but the report counts each as a
run. There is no stable logical-run/segment relationship in the event contract.

Action: distinguish run segments from final settlement, introduce a non-PII
logical run reference, and define duration/earnings deltas before building a
dashboard. Do not tune economy or route difficulty from inflated totals.

### 12. P2: Deletion Success Can Become A Permanent Error After Response Loss

Evidence: `backend/src/server.js:366`, online request/Settings handling.
The real database probe observed first deletion 200 and retry 401. The client
only clears its online identity after a successful deletion response, leaving
stale credentials and a generic error after a lost success acknowledgement.

Action: make deletion recovery explicit and retry-safe without falsely treating
all 401 responses as proof of deletion; token rotation can also cause a 401.
Test lost responses and distinguish deleted, moved, unauthorized and offline.

## Additional High-Value Engineering Work

| Upgrade | Approach And Acceptance |
|---|---|
| Consent cancellation and request ownership | Track a generation/epoch for cloud/telemetry opt-in and identity changes. Turning Cloud Backup off currently changes a flag but does not cancel requests or the upload-success follow-up. Already-sent data cannot be recalled; prevent new chained work after withdrawal. |
| Real transport fault tests | Extend tests to lose actual HTTP responses, delay/reorder them, close screens and rotate credentials. Current helper/server tests do not exercise all client lifecycle races. |
| Complete service request budgets | Add shared limits/bounded issuance for transfer claims/codes, cloud writes, telemetry and friend/referral codes. Existing score/profile/World limits do not cover every write endpoint. |
| Backend incident visibility | Sanitized request IDs, operation/error class, latency and failure counters. Current generic catch-to-503 behavior hides causes. Never log sync tokens, transfer codes, headers or save bodies. |
| Server/client compatibility and kill switches | Expose a public protocol/config revision; pause optional writes during incidents while leaving offline play, read-only status and deletion usable. Coordinate migrations before client rollout. |
| Durable reward ledger | One settlement receipt per logical run with pickup, fare, fine, goal, mission, mastery, season and ad components. Use the same receipt for persistence, Results and consented reporting. |
| Better layout gates | Add actual button-input tests, long live HUD counters, clipping/overlap checks, visible first-viewport actions, scroll reachability and rendered CI artifacts. Bounds-only checks can pass unusable layouts. |
| Save-failure recovery | Surface failure outside a deep Settings status, retry safely while idle/on lifecycle boundaries, preserve dirty state and the last good backup; test quota/storage interruption on devices. |
| Battery/performance evidence | Long low-end-phone runs with frame-time distribution, memory/pool counts, heat and battery observations; consider a capped-FPS battery option. Do not infer performance from desktop startup. |

## Product Upgrades After These Fixes

1. Nearby-rank and own-rank APIs, not just the top 25. A non-top-25 player
   should see a reachable next rival without receiving a fabricated global rank.
2. One compact final reward total/receipt, plus crash cause and next vehicle
   progress near Play Again. The new expandable details should not hide every
   useful next-step explanation behind the ad choices.
3. Stronger route-event signposting: consistent roadside marker, brief local
   callout and success feedback that does not obscure the next hazard.
4. Distinct bus silhouettes/roof details in the established procedural style,
   while preserving consistent visible collision boundaries.
5. Original/licensed horn, conductor and route ambience recordings through the
   existing file override hooks, with rights provenance and loudness checks.
6. Separate readable options for sound/music levels, motion and traffic contrast;
   keep hazard recognition independent of color alone.
7. Contextual friend rematches with explicit challenge/rules identity and a
   concise share summary; do not turn ordinary unverified scores into prizes.
8. Measured economy targets: define first-unlock time and coins/minute only
   after correcting logical-run reporting and collecting sufficient consented
   data. Preserve coins as the main currency.
9. A lightweight support diagnostics view: app/protocol version, last backup,
   upload status and an explicitly reviewed/redacted support export. No tokens.
10. Finish one release-quality update before expanding seasons, cities or SACCO
    crews. Those systems need dependable identity, privacy, moderation and data.

## Evidence And Limits

- Godot 4.7.1 temporary runtime probes reproduced findings 3-5, 7-9.
- Isolated PostgreSQL 17 HTTP probes reproduced transfer/deletion lost-response
  behavior, additional active transfer codes, block loss and unknown properties.
- Read-only production checks: `/health` healthy; all seven World boards
  returned `verification: unverified`; Mwenge had one row and the rest zero.
  No production write, account, score or moderation action was created.
- The full source gate passed: Godot parsing, logic/recovery contracts, 288
  secondary layouts and all 22 PostgreSQL tests, with no skipped backend tests.
  Its known ObjectDB-at-exit warnings do not
  establish whether a long-running phone session leaks memory.
- No new native-ad, physical-phone, keyboard, thermal or multi-device results
  are claimed. The code gaps above are separate from those remaining QA gates.
- No deployment, migration application, AAB export or Git push was performed.
  The previous recovery pass still requires migration 010 deployment, privacy
  publication and a higher-version Android build before phone acceptance.

Recommended order: consent, transfer/save recovery and block safety; then input,
backup size and reward state; then honest Daily/reporting contracts; then the
presentation/retention upgrades. Keep the next release scoped and measurable.

References: [Google UMP](https://developers.google.com/admob/android/privacy)
and [Android Vitals](https://developer.android.com/games/optimize/vitals).
