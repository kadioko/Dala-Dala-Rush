# Consent, Recovery And Competition Update

Source update: October 18-22, 2026. Backend migrations 010-012 are **deployed**.
Export/publication evidence is tracked in `releases/1.0.18.md`.
This follows the historical findings in `DEEP_AUDIT_2026-10-18.md`.

## Eight Fixes

| Finding | Source change | Remaining acceptance |
|---|---|---|
| Advertising consent | Native Godot v2 bridge uses UMP 4.0.0 update/form flow each launch. SDK `canRequestAds` gates every native request. Required privacy options appear in Settings; stale consent-session ad callbacks are discarded. Android never simulates a successful reward. | Configure/publish applicable messages in AdMob. Test required/not-required regions, offline/error cases, returning consent, privacy changes and ads on registered devices. |
| Lost transfer response | Receiving phone durably saves its own random credential/operation before claiming. Claim does not revoke source; acknowledgement rotates credentials. Both responses can be retried. Old codes are revoked on acknowledgement. | Deployment and HTTPS retry tests passed; two-phone kill/reconnect checks remain. Legacy receiving clients deliberately get HTTP 426 and must update. A pending unacknowledged claim expires without revoking source. |
| Broken saves | Schema 18 envelope rejects empty/unknown-only files, quarantines damaged primary, repairs from backup, sanitizes mission/livery/replay data, bounds reads, and refuses future-schema writes. | Real historical user saves and low-storage/process interruption. A future-schema file is preserved read-only, not downgraded. |
| Dropped steering taps | Legal buttons remain enabled during a turn so a second real GUI click reaches the existing one-command buffer. | Both phones: rapid/opposite taps, horn multi-touch, lane edges and pause/resume. |
| Replay backup overflow | All four optional replay blobs stay local and are excluded from essential cloud progress. Settings consent explains this. | Existing cloud restores and large real profiles on both phones. |
| Block bypass | Leaving a public profile removes blocks owned by that player, not private blocks owned by other players. Full account deletion still cascades associated records. | Two-phone rename/rejoin/block/unblock flows; a new anonymous identity remains outside this protection. |
| Results/ad race | Navigation locks before an ad request; placement and logical-run ownership are checked. SDK reward is applied only after dismissal; receipt records one choice durably with wallet changes. | Native duplicate/late/failure callbacks, resume/kill and failed disk writes. Not server-authoritative rewarded-ad verification. |
| Daily course claim | Swahili/English copy now says shared setup with adaptive traffic. Same route/vehicle/seed/no-revive rules do **not** promise an identical traffic course. | Reproducible input-independent competitive courses remain a separate feature. |

## Additional Improvements

- Authenticated own rank and up to seven nearby drivers, including below top
  25; stable tie ordering. Public viewing stays open; scores remain unverified
  and reward-free. New endpoint requires the backend update.
- One wallet-reconciled receipt: pickups, fares, chase rewards, actual fines,
  route goal, missions, season, mastery, daily/contract rewards and ad bonus.
  Revives update deltas rather than paying the same segment twice.
- Crash coaching and next-vehicle progress sit beside Play Again. Detailed
  receipts stay expandable; advertising never replaces the primary action.
- Replay input retains the latest 2,048 moves instead of becoming invalid.
  Partial windows are labelled and cannot masquerade as full ghost races.
- Typed telemetry v2 rejects unknown/invalid properties; legacy v1 unknown
  fields are dropped. A logical `run_ref` survives revive segments. Unique
  `run_settled` ingestion prevents revived runs inflating completed-run counts.
- Route events have a fixed roadside pictogram outside driving lanes. Vehicle
  roofs now distinguish VIP/night AC units, old-school racks, chevrons and
  Bongo speakers. Hitbox footprints do not change with cosmetic details.
- Battery Saver caps rendering at 30 FPS; normal cap is 60. Debug Settings
  can capture five active minutes into local `performance_last.json`, using
  constant-memory frame histograms. Capture does not upload anything.
- CI runs trust contracts and rendered bilingual screenshots with Xvfb/Mesa,
  retaining evidence for 14 days. See the release record for hosted results.

## Reproduce Verification

```powershell
.\tools\build_consent_bridge.ps1
.\tools\test_postgres.ps1 -VerifyProject
godot --path . res://tests/ui_layout_qa.tscn
godot --path . res://tests/secondary_ui_qa.tscn
```

The Java consent library compiled against the installed Godot template. Android
standard-debug dependency duplicate-class and manifest-merge checks passed;
this is not native runtime consent evidence or a release-bundle inspection.
Godot trust contracts exercise actual button input, stale consent callbacks,
an empty primary with a real backup, future-schema protection, receipt deltas,
large replay windows and bounded frame histograms. PostgreSQL tests exercise
lost/expired transfer acknowledgements, preserved blocks, nearby ranks and
logical-run telemetry deduplication in an isolated database.
The integration follows [Google's UMP flow](https://developers.google.com/admob/android/privacy),
not an app-maintained consent boolean substituted for SDK state.

Latest local verification on October 19: full source gate passed with Godot
parse/import, logic/recovery/trust contracts, both UI suites and **28 backend
tests using real PostgreSQL 17, no skips**. Rendered runs produced 60 primary
and 156 secondary captures; all 288 secondary layout cases passed. Small-screen
Swahili/English Results with populated receipts and Garage were inspected.
Some short-lived Godot test runners still report ObjectDB cleanup warnings at
exit; these are not evidence that long-run device memory behavior was proven.
ADB reported no attached devices. The performance helper passed PowerShell
parsing but has no physical-device execution evidence.
The next-release AAB gate was negatively tested against existing code 18: it
correctly rejects that older bundle for missing DalaConsent registration.

## Deploy Before Distributing

1. Back up production PostgreSQL. Deploy tested backend with the migration
   runner applying **010, 011 and 012** in order. Never edit applied migrations.
2. Verify existing-client public reads, authenticated submissions/backups,
   legacy transfer upgrade response, new transfer handover and moderation.
3. Publish the amended privacy notice before collecting expanded opt-in events.
4. Confirm AdMob messages/test devices; perform the phone matrix below.
5. Export a higher-version AAB and run package/signature/permission checks.
   The updated verifier now also requires DalaConsent manifest registration;
   the old code 18 artifact intentionally does not satisfy this new gate.

On October 22 migrations 010-012 were deployed and checked through the actual
database ledger, six required columns and three indexes. HTTPS smoke checks
passed for seven World boards, repeat cloud operations, repeat transfer claim/
acknowledgement and old-token revocation; the unnamed test account was deleted.
A private logical backup was inspected and retained outside Git. Phone QA was
explicitly deferred by the owner; API tests do not substitute for it.

## Still Requires External Evidence

- A21s plus another low/mid-range phone: touch, keyboard, banners, consent,
  native rewarded ads, transfer, deletion, backup/restore and both languages.
- At least 15 minutes per phone with the same route/settings/brightness;
  compare 60/30 FPS, frame pacing, memory growth, temperature and battery. Use
  debug Settings capture and `tools/capture_android_perf.ps1`; do not infer
  SurfaceView/game performance from Android gfxinfo alone. The ADB script is
  prepared, not device-validated. Release builds do not show the recorder.
- The owner approved synthetic Swahili placeholders on October 22. Five short
  eSpeak NG clips are bundled; `audio/SOURCES.md` records provenance. These are
  not human conductor recordings. Native-speaker/device review still remains.
- Server-verifiable runs and fully reproducible rival courses remain future
  work. This update makes no anti-cheat or identical-course guarantee.
