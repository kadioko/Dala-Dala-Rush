# Device QA Worksheet

Use this worksheet for production-update QA and for the separately gated online
pilot. Record the exact version code under test.
Capture one completed form for a low-end phone and one for a mid-range phone;
test both Swahili and English.

## Automated Main-Menu Pass

Run the project contract checks and the portrait screenshot/overflow runner:

```powershell
& 'C:\Users\USER\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --headless --path . res://tests/logic_contracts.tscn
& 'C:\Users\USER\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe' --path . res://tests/ui_layout_qa.tscn
```

The second command uses the normal renderer to capture collapsed,
expanded-top, and expanded-bottom menu states in both locales at 360x640,
393x873, 412x915, 540x960, and 720x1600. Screenshots are written to
`user://ui_qa/`. It fails if visible controls extend beyond the horizontal
viewport. Open every capture once before treating the automated pass as visual
approval; it cannot validate touch accuracy, Android keyboard behavior, safe
areas, native banners, or actual phone rendering.

## Device Record

| Field | Record |
|---|---|
| Tester / date | |
| Device model / Android version | |
| RAM / free storage | |
| App version / Play track | |
| Language | |
| Network state | Offline / Wi-Fi / mobile data |

## First Session

- [ ] Run 1 teaches steering and coins without blocking the road view.
- [ ] Run 2 teaches passenger pickup and a kituo.
- [ ] Run 3 teaches horn and slow motion.
- [ ] Full-city, Mwenge, Mastery, conditions, ghost, and police discoveries
  appear one at a time and do not repeat after relaunch.
- [ ] Menu, Route, Garage, Shop, How to Play, Settings, pause, and results fit
  cleanly with no clipped Swahili or English copy.
- [ ] Check the main menu at 360x640, 393x873, 412x915, 540x960, and 720x1600
  portrait classes. Play, selected route, Garage, and Leaderboards should be
  immediately visible; daily, stats, missions, referrals, shop, settings, and
  How to Play should be under More. No horizontal clipping is acceptable.
- [ ] Expand More and verify every secondary action in both languages.
- [ ] Attach the 30 generated menu captures or record their review result with
  the tester sheet. The automated check does not replace this visual review.

## Route Balance

Play at least ten Kariakoo/Mwenge runs and five on every other route. Record
the result values below before changing `docs/remote-config.json`.

| Route | Runs | Fuel finishes | Collisions | Goal wins | Avg coins | First notable moment | Notes |
|---|---:|---:|---:|---:|---:|---|---|
| Kariakoo | | | | | | Fare Rush | Fast, frequent fares should feel rewarding. |
| Mwenge | | | | | | Boda Watch | Lane decisions should be readable. |
| Mbezi | | | | | | Truck Line | Longer road and fuel efficiency should register. |
| Posta | | | | | | Clean Checkpoint | Controlled driving should be rewarded. |
| Kigamboni | | | | | | Fuel Scout | Rain/fuel pressure must remain fair. |
| Ubungo | | | | | | Jam Breaker | Dense traffic must remain escapable. |

## Ads, Saves, and Resume

- [ ] Register the device for AdMob test ads. Do not click live ads.
- [ ] Test rewarded revive and confirm it pays once and restores one run only.
- [ ] Test rewarded Double Coins and confirm it cannot combine with revive.
- [ ] Complete 2-3 runs and confirm the interstitial occurs only after results.
- [ ] Confirm banners appear only on menu/results, never driving or pause.
- [ ] Minimize and restore during menu, gameplay, and an ad callback.
- [ ] Force-close after a reward-heavy result; confirm coins, progression, and
  save backup recover after restart.
- [ ] Open Settings > Privacy Policy and confirm the public page loads.

## Performance And Release Decision

- [ ] Play ten continuous minutes with sound/haptics enabled.
- [ ] Note visible stutters, warm device state, battery drain, crashes, or ANRs.
- [ ] Check controls, HUD, safe areas, and horn separation on a notched device.
- [ ] Record any blocker with route, language, reproduction steps, and a
  screenshot/video.

Only raise difficulty or economy values through `docs/remote-config.json` after
this data is reviewed. A fuel finish or unreadable collision is a balance issue,
not an ad-placement opportunity.
## Cloud Sync Pilot

Cloud sync is enabled for this phone-validation build, but remains opt-in. Run
this checklist with two different Android phones before broad rollout.

## Phone A - Backup

1. Start with a fresh profile, complete a run, and change route/vehicle/language.
2. In Settings, read the Cloud Backup consent copy and select **Enable Cloud**.
3. Confirm one backup completes. Turn the switch off; verify no automatic backup
   occurs afterward and the game remains playable in airplane mode.
4. Turn it back on and use **Back Up Now**. Kill/reopen the app and confirm the
   local save still works without a connection.

## Phone B - Restore And Delete

1. Install the same debug build. On Phone A select **Move Phone**, then enter
   its temporary code on Phone B with **Receive Move** within 15 minutes.
2. Confirm Restore warns that it replaces local progress, then verify route,
   coins, unlocks, and locale match the selected backup.
3. Select **Delete Cloud Data**, confirm the destructive dialog, and verify the
   game still retains its local progress while Cloud Backup shows disconnected.
   The online leaderboard must show Join again; pending uploads and cached
   Friends standings must be gone, and Gameplay Insights must show Off.
4. Re-enable cloud backup and confirm a new anonymous identity/back-up works.
5. On a fresh profile, turn Cloud Backup and Gameplay Insights on before the
   first registration completes. Both should finish from one registration.
   Repeat, turning each switch off while the request is pending; a late
   response must not re-enable it.

## Release Gate

- Verify Swahili and English copy at 540x960 with no clipping.
- Test airplane mode, weak connection, app background/resume, and server 503.
- Confirm delete removes online data, not the phone save.
- Record the two-device results in the tester sheet. Keep the matching Privacy
  Policy and Play Data Safety declaration up to date before broadly rolling out
  this online-enabled build.

## Competition And Insights Pilot

Run this section with two non-primary test profiles. Do not promote an
online-enabled build broadly until every item passes and the Play Data Safety
declaration matches the published privacy policy.

- [ ] Enter a 16-character Swahili name and a 16-character English name. Open
  the keyboard on 360x640 and 393x873 phones. Confirm the page scrolls the field
  into view and Save/Join do not clip, overlap, or leave the keyboard covering
  the status text.
- [ ] Check the World tab without joining: its public/read-only and
  unverified-score explanation is clear in Swahili and English. The Friends
  tab explains that joining is required.
- [ ] Verify all board states: loading, a real empty response, cached standings
  while refreshing, cached standings offline, and no-cache network failure.
  Confirm the empty-board message never appears as though it were fresh data
  during a failed request.
- [ ] Set a route personal best that does not enter the local Top-5. Confirm it
  appears as pending, survives force-close/airplane mode, shows retry-needed
  after an upload failure, and changes to submitted after connectivity returns.
  Force-close after success and confirm the local last-upload confirmation
  remains visible when the leaderboard is reopened.
- [ ] Tap Retry repeatedly with a pending upload. Confirm only one request is
  in flight, the UI respects a server rate-limit response, and the queue clears
  only after accepted or already-surpassed confirmation.
- [ ] On Phone A opt in and submit one score. On Phone B, without opting in,
  open the same route's World board, refresh, and confirm the public name/score
  appears. Then test friend-code linking and the Friends board with two opted-in
  profiles. Use disposable test names only.
- [ ] Submit the same score twice and then a lower score for the same route.
  Confirm the server retains one best row per installation/route. Try an
  official-looking name such as `Admin` and confirm it is rejected with a
  Swahili/English explanation; ordinary local names must remain accepted.
- [ ] Change routes repeatedly while Friends/World data is loading. Confirm an
  older response never replaces the newly selected route.
- [ ] Verify Refresh, saved-standings age copy, long-name truncation, friend
  add/remove, the friend score target, the World next-rival points gap, and
  Leave Online. Confirm Leave Online removes public data but not local progress.
- [ ] On both phones, open the same Daily Run and confirm route, Classic Blue
  vehicle, day condition, traffic pattern, no consumables, and no revive rule
  match. Record any device-specific divergence.
- [ ] Enable Gameplay Insights only after reading its consent text. Confirm the
  switch is independent of Cloud Backup and turning it off prevents new
  requests. Confirm a consented run uploads successfully, including after
  upgrading from an older local analytics log. Do not inspect or copy player
  data from the service.
