# Responsive Menus And Recovery Update

Follow-up: `TRUST_UPDATE.md` supersedes this pass's schema/deployment status.
Current source is schema 18 and requires backend migrations 010-012. The
historical measurements below remain evidence for the earlier recovery pass.

Source implementation: October 18, 2026. These changes are **not** in the
existing 1.0.17 / code 18 AAB. No new Android bundle was exported for this pass.
Migration 010 and the matching backend must be deployed before distributing
the updated client. Physical-phone acceptance remains open.

## Nine Requested Priorities

| Priority | Implementation | Remaining Acceptance |
|---|---|---|
| Responsive menus | Shared word wrapping, width-aware action grids, viewport-bound Settings/dialogs, scrollable Missions/Livery, bounded splash title; compact HUD counters explicitly do not wrap. | Native keyboard, display cutouts, banners, A21s and second phone. |
| Reliable ads | One bounded exponential retry timer per format, resume reload, live rewarded-availability signal for Results, fullscreen overlap guard. | Real SDK callbacks, reconnect, consent and backgrounding on an AdMob test device. |
| Cloud recovery | Save an immutable upload operation ID/body before sending; server replays an acknowledged operation; serialize writes and return current revision on conflict. Settings offers an explicit local-overwrite choice or the existing confirmed restore. | Deployment and two-phone transfer/restore/reconnect acceptance. |
| Onboarding | Advance only after both lesson steps; unfinished attempts repeat, existing profiles stay grandfathered, explicit Skip Lessons confirmation. | Fresh-profile lessons and skip/relaunch on phones. |
| Competition | Hidden moderation decision retained on installation for its existing 90-day window, even after public profile removal; explicit rejoining is required after leaving. Daily replay compatibility includes rules version. | Two-phone friends, deletion and incompatible-rival UI checks. Scores remain unverified/reward-free. |
| Saves/reporting | Checked temporary writes and backup rotation, write-error signal/Settings notice, schema 17; stable event UUIDs and transactional ingestion with a unique database guard. | Low-storage/device interruption testing and privacy publication. Legacy telemetry without IDs cannot be deduplicated. |
| Driving feel | Physics-tick movement/tweens; one buffered steering command, canceled on pause; actual lane alignment at stops; swept relative collisions and crossed stop windows; cleanup after collision checks. | Real frame pacing, touch timing and long runs on low/mid-range phones. |
| Presentation | Garage renders each bus/livery; Results places score, coins, Play Again and optional ad choices ahead of expandable run details. | Final phone visual review, including large rewards and native banner height. |
| Release checks | Every scene included across the menu/HUD and secondary suites; real PostgreSQL CI/service tests; AAB package, signature and pinned upload-certificate checks. | GitHub-hosted CI execution and verification of the next actual exported artifact. |

## Regression Commands

```powershell
.\tools\verify_project.ps1
.\tools\test_postgres.ps1
.\tools\test_postgres.ps1 -VerifyProject
godot --path . res://tests/ui_layout_qa.tscn
godot --path . res://tests/secondary_ui_qa.tscn
```

`test_postgres.ps1` starts an isolated PostgreSQL 17 Docker container on a random
loopback port and removes it afterward. Alternatively, set `TEST_DATABASE_URL`
to a dedicated database whose name ends in `_test`, then run `npm test` in
`backend/`. It creates/drops its own random schema. Never point tests at a
production database. Without this variable, the integration suite is skipped.
GitHub Actions provisions its own PostgreSQL service and sets the variable.
`-VerifyProject` runs the entire source gate against the disposable database.
Artifact-bearing verification refuses to run with database tests skipped.

The secondary suite checks 12 screens, two profile states, both languages,
and six sizes: **288 combinations**. The regular suite covers main menu,
gameplay HUD, intro, pause and confirmation states. Rendered captures go to
`user://secondary_ui_qa/` and `user://ui_qa/`; headless mode checks bounds only.
Bounds checks do not prove text quality or native Android behavior.

Recovery contracts cover interrupted writes, prior-schema fixtures, stable
cloud operations, invalid responses, tutorial retry/skip, continuous collision,
stop timing, buffered steering/pause and duplicate ad-reward callbacks.
The live entity pipeline also checks that objects crossing the entire bus in
one large movement are detected before offscreen cleanup/pooling.
Fixtures for schema 2/8/16 are sanitized representative inputs, **not** evidence
that every real historical user save was tested. Existing short-lived test
runners still report ObjectDB cleanup warnings at exit; a pass is not a
production memory-leak assessment. The ad-failure warnings are deliberately
injected regression cases.

Real PostgreSQL tests cover concurrent/repeated migrations, pre-ledger schema
adoption, lost cloud acknowledgements, concurrent backups, moderation after
leaving/rejoining, restore after profile removal, telemetry duplicates, failed
batch rollback, account deletion, failed migration rollback and checksum drift.

## Recorded Local Results - October 18

- `tools/test_postgres.ps1 -VerifyProject`: PASS, Godot 4.7.1 parse/import,
  logic contracts, both headless UI suites and recovery contracts; all 22
  backend tests passed with real PostgreSQL 17 and no skips.
- Rendered UI runs: 60 primary and 156 secondary captures; all 288 secondary
  combinations passed bounds. Representative small-phone menu, HUD, Garage,
  Settings, Results, splash and Livery captures were inspected. This is not a
  claim that every generated capture received human review.
- Existing code 18 AAB: correct package, upload certificate, signature,
  version and target SDK accepted. Wrong-package and wrong-certificate probes
  both rejected. This does not verify a newly exported artifact.
- `git diff --check`: PASS. ADB listed no attached devices. The disposable
  PostgreSQL containers were stopped after the tests.

## Release Identity Checks

```powershell
.\tools\verify_android_release.ps1 `
  -BundlePath 'exports/android/YOUR-NEW-BUILD.aab' `
  -BundletoolJar 'C:\path\to\bundletool-all-1.18.3.jar' `
  -ExpectedVersionName 'YOUR-VERSION' -ExpectedVersionCode 19 `
  -ExpectedTargetSdk 36
```

Choose a never-used Play version code; 19 is only an example, not a reserved
code. `data/release_identity.json` contains the public package and upload
certificate SHA-256, not a private key. The upload certificate is distinct from
Google Play's distribution signing certificate. Update its pin deliberately
only after a verified upload-key change. Bundletool is now mandatory; a
well-signed bundle for a different package or upload certificate is rejected.

## Deployment Order

1. Deploy the tested backend and run `010_service_recovery.sql` via the existing
   Railway pre-deploy command. The runner adopts prior idempotent migrations
   into a checksum ledger, uses an advisory lock and transaction per migration,
   and refuses changes to already-applied SQL files.
2. Check pre-deploy success and public health/World reads. Use disposable
   consented identities for any live write tests, then delete them.
3. Publish the amended privacy page before enabling the expanded tutorial/ad
   event upload set in a distributed client; review Play declarations.
4. Export a new higher-version AAB, run full source/database/artifact gates,
   then record both phone results in `DEVICE_QA.md` before rollout.

Daily rules matching prevents incompatible local rival clips, not cheating.
Fixed physics does not make adaptive traffic server-verifiable. Server-side
run validation, licensed audio and reliable physical-device evidence remain
separate work; do not promote the leaderboard as authoritative.
