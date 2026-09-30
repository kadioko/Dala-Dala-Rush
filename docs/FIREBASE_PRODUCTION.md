# Optional Firebase Telemetry Handoff (Not The Game Database)

Firebase is not required for Dala Dala Rush TZ's game data. Railway + PostgreSQL
is the planned backend for optional cloud saves, server-verified referrals, and
online leaderboards; see `docs/RAILWAY_BACKEND.md`.

The project deliberately has no Firebase SDK dependency yet. `AnalyticsService`
persists privacy-filtered events locally and `report_nonfatal()` records a local
breadcrumb; neither sends data off-device. Firebase remains an optional future
choice for analytics and crash reports only. Do not declare Firebase Analytics
or Crashlytics as active until this checklist is complete.

## Required Decisions

1. Create or select the Firebase project for package
   `com.kadioko.daladalarush`.
2. Select one maintained Godot 4 Android bridge that supports both Firebase
   Analytics and Crashlytics on Godot 4.7.1. Audit its Android Gradle,
   dependency, privacy, and target-SDK support before adding it.
3. Add the Firebase Android configuration file through the bridge's documented
   path. Treat it as environment configuration; never place API secrets or
   service-account credentials in this repository.
4. Implement the exact bridge calls only inside
   `autoload/analytics_service.gd` → `_send_to_sdk()` and
   `report_nonfatal()`. Keep the local journal as an offline fallback.

## Acceptance Tests

- A release build reports `app_open`, `run_start`, `run_end`, tutorial stages,
  route moments, reputation, ads, and referral funnel actions in Firebase.
- Invite codes, player-entered names, ghost payloads, and precise location do
  not appear in Analytics or Crashlytics.
- Trigger one controlled nonfatal and verify it appears in Crashlytics with no
  secret data.
- Verify reports from a real Play-delivered build, then update the Play Data
  safety form and Privacy Policy if the selected SDK's actual collection or
  sharing behavior requires it.

## Useful First Dashboard

Create funnels for first run, tutorial run 1-3, first route goal, first vehicle
unlock, and first rewarded choice. Add breakdowns by route and end reason for
fuel finishes/collisions. Wait for this evidence before adding crews, a premium
season, or additional currencies.
