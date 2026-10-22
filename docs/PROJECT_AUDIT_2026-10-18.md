# Game Improvement Audit - October 18, 2026

Baseline: `cf8c072`, production project, last documented Android candidate
1.0.17 / code 18. This report records findings and proposed work; it does not
mark the proposed fixes as implemented.

Follow-up: the nine-priority source implementation and its acceptance limits
are tracked in [RECOVERY_UPDATE.md](RECOVERY_UPDATE.md). Findings below describe
the original baseline, not the current working tree.

## Recommendation

Make the next development batch a responsive-screen and recovery update.
Secondary menus still clip, ad availability does not recover reliably, and a
lost cloud-upload response can leave subsequent backups stuck. Fix these
player-visible issues alongside their missing regression coverage.

## Evidence Gathered

- `tools/verify_project.ps1` passed Godot 4.7.1 parsing, logic contracts,
  headless menu/HUD bounds, and all 14 backend tests.
- The normal OpenGL renderer generated the existing suite's 60 screenshots
  across six portrait sizes in Swahili and English. Its bounds checks passed.
  Representative compact-menu and compact/tall HUD captures were inspected.
- An additional temporary diagnostic captured 11 secondary screens in both
  languages at widths 320, 360, and 540, each at height 640: 66 captures.
  It exercised a returning-player profile and a new-record results state
  (score 54,321; 40 coins; 12 passengers). It found horizontal overflow that
  the current release gate does not exercise. The diagnostic files were
  removed after use; screenshots remain in `user://audit_2026_10_18/`.
- Live read-only checks on October 18 found `/health` healthy and all seven
  World route endpoints returning valid `unverified` responses. Mwenge had
  one public row; the other routes were empty. No production test scores,
  reports, accounts, or database changes were created by the audit.
- Phone touch, native ad callbacks, Android keyboard, thermals, and Play
  delivery were not tested in this pass.

## Highest-Priority Findings

### 1. Secondary Screens Still Overflow - P1, Reproduced

Settings fixes its content at 410 units and centers a 410-unit scroll area
(`scripts/settings_screen.gd:46`). Results contains unwrapped labels and
horizontal action rows whose combined minimum widths expand the content
(`scripts/game_over.gd:292`). Garage/Routes put multiple lines of descriptive
text inside buttons without responsive wrapping (`scripts/garage.gd:80`,
`scripts/routes_screen.gd:111`). Similar minimum-width propagation affects
competition and other menus.

| Screen | 320/360 Width Findings | 540 Width Findings |
|---|---|---|
| Results | Overflow in both languages | Animated record label can exceed bounds |
| Settings | Overflow in both languages | No horizontal overflow observed |
| Garage | Overflow in both languages | Swahili overflow |
| Routes | Overflow in both languages | English overflow, right edge about 607 |
| Shop | Overflow in both languages | No horizontal overflow observed |
| Leaderboard | Overflow in both languages | Small English overflow |
| Referrals and Livery | Overflow in both languages | No horizontal overflow observed |
| Missions | Swahili overflow at 320 | No horizontal overflow observed |
| Stats | English overflow at 320 | No horizontal overflow observed |
| How to Play | No horizontal overflow observed | No horizontal overflow observed |

Fix: constrain every page to available viewport width; wrap descriptive labels;
stack multi-action rows below a breakpoint; let repeated entries grow vertically;
bound animated labels. Use content-aware labels inside route/vehicle entries
instead of one oversized text button. Extend permanent UI QA to every screen,
locked/unlocked states, large numbers, record animations, and relevant dialogs.

Acceptance: every interactive target and visible line fits in both languages
at all six existing test sizes, followed by A21s and a second-phone checks.

### 2. Cloud Backup Can Become Stuck After A Lost Response - P1, Code Path

`autoload/online_service.gd:67` derives the next revision from the last response
saved locally. If upload revision N reaches the database but its response is
lost, local revision stays N-1. Repeated retries send N again, and the server
rejects them with `stale_revision` (`backend/src/server.js:385`). Settings only
shows `CLOUD_ERROR` (`scripts/settings_screen.gd:440`). Restoring the remote
save is currently the visible way to advance the revision, which can replace
newer local progress. Uploads also lack an in-flight guard.

Fix: persist an upload operation ID, accept a retry of the same completed
operation, serialize backup writes, and return useful conflict metadata.
Offer explicit conflict resolution while preserving local progress.

Acceptance: lost responses, duplicate taps, concurrent uploads, and transferred
phones recover without replacing newer progress or leaving backups stuck.

### 3. Ad Availability Does Not Recover Or Refresh Results - P1, Code Path

The failure callbacks in `autoload/ad_service.gd:221` and `:252` clear loaded
flags but schedule no retry. Loading normally starts at SDK initialization and
after dismissal/show failures. An offline launch can therefore leave rewarded
and interstitial ads unavailable until restart.

Results hides reward actions when it opens without a loaded ad
(`scripts/game_over.gd:466`). AdService has no availability-change signal, and
successful later loading does not refresh those actions on the open screen.

Fix: add bounded retry/backoff, resume recovery, a single load in flight per
format, and an availability signal consumed by Results. Preserve existing
one-choice-per-run reward guards.

Acceptance: start offline, reconnect on Results, load successfully, and see the
available reward choices without leaving the page. Exercise dismissal, failed
shows, duplicate reward callbacks, and background/resume on a test-ad phone.

## Reliability And Competition Findings

| Priority | Finding And Source | Proposed Work And Validation |
|---|---|---|
| P2 | A hidden profile can be deleted by its owner and recreated with the default active state. `backend/src/server.js:489`, `:519`; migration 009. | Keep a moderation disposition at installation level with an explicit lifecycle; preserve the public-profile deletion flow. Test hide, leave, rejoin, rename, submit, restore, and full-account deletion. New-install abuse remains a separate issue. |
| P2 | Tutorial stages are marked complete at run end even when their required steps were never performed. `scripts/game.gd:2670`. | Record successful lesson steps separately from attempted runs; repeat unfinished guidance and provide an explicit skip. Validate immediate crashes, fuel endings, resume, and returning profiles. |
| P2 | Equal Daily Run seeds do not establish identical courses. Wave planning uses the player's current lane and active traffic, and timers reset in variable-delta `_process`. `scripts/game.gd:1365`, `:2137`, `:2179`. | Define a fixed simulation tick and an input-independent challenge course. Compare event traces under the same inputs at 30/60/120 FPS and multiple viewport sizes. Preserve adaptive traffic for regular runs. |
| P2 | Replay compatibility matches date/route/vehicle/seed without a gameplay-rules version. `data/ghost_data.gd:90`. | Include a rules/configuration version in the challenge and replay; reject incompatible rivals with a localized explanation. Test old/new build combinations. |
| P2 | Telemetry batches can duplicate events. The client has no flush-in-flight guard; the server inserts each row without a batch transaction or event ID. `autoload/online_service.gd:242`, `backend/src/server.js:850`. | Add event IDs, unique ingestion, transactional batches, and one client flush at a time. Test partial failure, concurrent flush, and lost acknowledgement before using counts for balancing. |
| P2 | Save success is reported after writing without checking write/close errors; backup-copy errors are ignored. `autoload/save_system.gd:345`. | Write and verify a temporary save before replacing the primary; preserve the last good backup and surface failure. Test low storage, interrupted writes, failed copies, and migration fixtures from prior releases. |
| P2 | General online JSON requests have a timeout but no response-size cap or operation-specific response validation. `autoload/online_service.gd:281`. | Bound response bodies and validate required fields before applying identity, revision, cache, or deletion success. Test malformed, oversized, empty, and unexpected 2xx responses. |
| P2 | Every deployment reruns every SQL file, including constraint replacement. There is no applied-migration ledger or migration lock. `backend/src/migrate.js:9`. | Adopt a migration ledger/checksums and an advisory lock, with transactional application where supported. Baseline the deployed schema carefully; test fresh setup, repeated deploy, failed migration, and future route additions on disposable PostgreSQL. |
| P2 | Release verification checks that a signature exists but does not pin the expected signing certificate or package. `tools/verify_android_release.ps1:16`. | Verify package identity and expected upload-certificate fingerprint as well as version, SDK, permissions, and packaged production switches. Test rejection of a wrong-package or wrong-key bundle. |

These are source findings unless explicitly marked reproduced. They need
focused regression tests when implemented; passing the current suite does not
exercise the missing paths above.

## Gameplay And Product Upgrades

1. Put score, total reward, and Play Again near the top of Results. Place the
   detailed ledger, reputation breakdown, and secondary sharing actions under
   expandable details. The current screen places replay/retry actions after a
   long sequence of explanatory content (`scripts/game_over.gd:74`).
2. Render the actual customized bus in Garage instead of a plain color square
   (`scripts/garage.gd:74`). Show one main perk and a compact comparison with
   the equipped bus, with the full stats available on demand.
3. Make route selection a short readable job summary: route, difficulty,
   objective, reward, and selected state. Open mastery/contracts/signature
   details separately so unlocking content does not keep widening the rows.
4. Consider a single buffered steering input. `Player.move_left/right` discards
   taps while a lane tween is active (`scripts/entities/player.gd:40`). Validate
   quick two-tap turns, opposite-direction cancellation, and pause/resume.
5. Check collision continuity under long frames: movement precedes a discrete
   rectangle-intersection check (`scripts/game.gd:1551`, `:1609`). Use swept
   collision or fixed simulation steps if stalled-frame tests show tunneling.
6. Make bus-stop service depend on the visual/collision position. It currently
   uses `current_lane`, which changes as soon as steering starts, before the
   bus arrives (`scripts/game.gd:1534`, `scripts/entities/player.gd:40`).
7. Reduce inactive HUD clutter and keep icon feedback distinct from the bus.
   Preserve the large independent driving targets while refining the compact
   layout through actual phone observations.
8. Expand consented learning only after ingestion is reliable: build/rules
   version, tutorial start/steps, ad outcomes, and useful upload failure reason.
   These signals are absent from the current Railway event allowlist. Report
   route fuel failures, goal completion, and first unlocks by build.
9. Batch local event-journal writes (`autoload/analytics_service.gd:148`) and
   profile HUD/particle allocations on a low-end phone. Establish frame-time,
   memory, and thermal evidence before choosing rendering optimizations.
10. Improve route identity through existing roadside cues, distinct bus
    silhouettes, and original short audio recordings. Keep the existing coin
    economy and measure unlock time before changing prices or adding systems.

## Development Sequence

1. Responsive secondary screens, permanent all-screen regression coverage,
   and a simpler Results action hierarchy.
2. Ad recovery, cloud-upload idempotency/conflicts, durable saves, and tutorial
   completion rules.
3. Moderation persistence, telemetry ingestion, migration tracking, real
   PostgreSQL integration tests, and stronger AAB identity checks.
4. Fixed-step challenge/replay rules, long-frame collision tests, Garage bus
   previews, steering polish, and phone-derived balance/audio refinements.

Server-authoritative score verification remains a separate larger project in
`SCORE_VERIFICATION.md`. Public scores should retain their current unverified,
reward-free status until that protocol is implemented and validated.
