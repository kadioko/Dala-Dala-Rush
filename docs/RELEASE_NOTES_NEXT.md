# Dala Dala Rush TZ - Next Release Notes (Draft)

Prepared August 19, 2026 for the next build from current source.

Proposed release: version `1.0.6`, version code `7` or higher, target API `36`.
Confirm the final version and artifact details after export; never reuse a code
that has appeared in any Google Play track.

## English

- Rebuilt the pause flow with live run stats and confirmation before leaving.
- Rebuilt the opening route briefing and countdown with centered, responsive
  `GET READY / GO` and natural Swahili `JIANDOE / TWENDE` cues. The live HUD
  stays hidden until driving begins.
- Improved the pre-run route briefing, How to Play guide, HUD controls, and
  contextual crash tips in both Swahili and English.
- Added fairer late-run traffic waves, clearer speed-ramp feedback, safer
  shield recovery, and better collectible placement.
- Fixed distance progression so route goals and achievements take meaningful
  survival time.
- Rewarded revive and Double Coins are now mutually exclusive and pay exactly
  once per run.
- Hardened scene transitions, saved selections, backup recovery, leaderboard
  data, and imported ghost codes.
- Improved stability with repeatable automated logic checks for core game data,
  localization, rewards, saves, ghosts, and progression.

## Kiswahili

- Pause sasa inaonyesha hali ya run na inaomba uthibitisho kabla ya kuondoka.
- Mwanzo wa route na countdown sasa uko katikati na unatumia maneno ya kawaida
  `JIANDOE / TWENDE`; HUD inaonekana baada ya kuanza kuendesha.
- Tumeboresha maelezo ya route kabla ya kuanza, Jinsi ya Kucheza, controls za
  HUD, na ushauri wa ajali kwa Kiswahili na English.
- Traffic ya baadaye sasa ni ya haki zaidi, ongezeko la speed linaonekana wazi,
  shield ina muda salama wa kurejea, na pickups zinawekwa vizuri zaidi.
- Distance sasa inahesabiwa vizuri ili malengo ya route na achievements
  yachukue muda wenye maana.
- Revive na Double Coins haziwezi kutumika pamoja na zawadi inalipwa mara moja.
- Tumeboresha usalama wa kubadilisha screens, save backup, route/vehicle
  selection, leaderboard, na ghost codes zinazoingizwa.
- Automated logic checks mpya zinalinda data, lugha, zawadi, save, ghost, na
  progression ya mchezo.

## Play Console Copy

English:

```text
Improved the centered bilingual route countdown, pause, How to Play, HUD controls and crash tips. Traffic is fairer, goals are better paced, rewards pay once, and save, navigation and ghost-code reliability are stronger.
```

Kiswahili:

```text
Tumeboresha countdown ya route kwa JIANDAE/TWENDE, pause, Jinsi ya Kucheza, HUD controls na ushauri wa ajali. Traffic ni ya haki zaidi, distance imepangwa vizuri, rewards hulipa mara moja, na save pamoja na ghost codes ni salama zaidi.
```

## Final Artifact Details

- Version name: confirm before export
- Version code: `7` or higher
- Target SDK: Android 16 / API 36
- Artifact: use a unique versioned `.aab` filename
- Size: record after export
- SHA-256: record after export
- Signature: verify with `jarsigner`
- Manifest: verify AdMob App ID and
  `com.google.android.gms.permission.AD_ID`
