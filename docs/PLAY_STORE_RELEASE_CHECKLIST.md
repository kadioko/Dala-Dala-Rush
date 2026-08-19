# Play Store Release Checklist

Use this as the launch checklist for Dala Dala Rush TZ.

Last verified against local configuration: August 19, 2026.

Build the signed bundle with `docs/ANDROID_RELEASE_BUILD.md`, then return here
for store assets, declarations, and rollout checks.

## Build Status

- Package name: `com.kadioko.daladalarush`
- Current local closed-testing artifact: `1.0.5`
- Current local version code: `6`
- Artifact status: signed and locally verified; not tracked in Git
- Local artifact: `exports/android/DalaDalaRushTZ-closed-testing-v6.aab`
- Min SDK: `24`
- Target SDK: `36`
- Export format: Android App Bundle (`.aab`)
- Gradle/custom build: enabled for AdMob
- Next release AAB path: `exports/android/DalaDalaRushTZ-closed-testing-v7.aab`
- Debug APK path: `exports/android/DalaDalaRushTZ-debug.apk`
- Enabled ABIs for the next export: `armeabi-v7a` and `arm64-v8a`
- Source status: Waves 8-14 are newer than code 6; the next upload requires
  version code `7` or higher and a newly exported AAB.

Before a replacement upload, check every Play track first. Google Play rejects
a bundle whose code is not higher than every previously uploaded artifact. If
code `6` has reached Play, use code `7` or higher for a replacement.

Starting August 31, 2026, new mobile apps and updates must target Android 16 /
API 36 or higher. This project already targets API 36. Recheck the official
policy before later releases:
https://support.google.com/googleplay/android-developer/answer/11926878

## Signing

Release signing is stored outside the repository:

- Keystore: `C:/Users/USER/Documents/Coding/Games/DalaDalaRushTZ_release/dala_dala_rush_tz_release.jks`
- Credentials file: `C:/Users/USER/Documents/Coding/Games/DalaDalaRushTZ_release/release-signing-credentials.txt`
- Alias: `daladalarush`

Do not commit the keystore or credentials file. Keep a backup in a private,
secure location. Losing this key can block future app updates unless Play App
Signing recovery is configured.

## Store Listing Copy

### Kiswahili

Short description (80 characters maximum):

```text
Kimbiza dala dala, epuka foleni, kusanya abiria na coins Dar style!
```

Full description:

```text
Dala Dala Rush TZ ni mchezo wa 2D endless driving wenye ladha ya Tanzania.
Kimbiza dala dala yako kwenye barabara zenye foleni, bodaboda, bajaji, magari,
mashimo, traffic cones na checkpoints. Kusanya abiria, coins, fuel na power-ups
kama shield, magnet na slow motion.

Chagua route kama Kariakoo Rush, Mwenge Madness, Mbezi Express, Posta Traffic,
Kigamboni Run au Ubungo Chaos. Fungua skins za dala dala kwa kutumia coins za
ndani ya mchezo. Hakuna betting, hakuna gambling, hakuna malipo ya pesa halisi.

Vipengele:
- Uchezaji rahisi wa swipe left/right
- Lugha ya Kiswahili na English
- Offline-friendly gameplay
- Rewarded ads kwa revive na double coins
- Interstitial ads baada ya runs chache
- Banner ads kwenye menu na results pekee

Unaweza kunipita?
```

### English

Short description (80 characters maximum):

```text
Dodge Dar traffic, collect passengers and build your dala dala legend!
```

Full description:

```text
Dala Dala Rush TZ is a colorful 2D endless driving game inspired by the energy
of Tanzanian city traffic.

Steer your dala dala across three lanes, dodge bodabodas, bajajis, cars,
potholes, roadworks and checkpoints, then collect passengers, coins, fuel and
power-ups. Stop at vituo to drop off passengers for fares, but watch your fuel
and avoid overloading when traffic gets serious.

Take on Kariakoo Rush, Mwenge Madness, Mbezi Express, Posta Traffic, Kigamboni
Run and Ubungo Chaos. Unlock new dala dala styles using coins earned in the
game, complete daily challenges and missions, improve your career rank, and
chase a new high score.

Features:
- Simple swipe or button lane controls
- Swahili and English language options
- Offline-friendly gameplay
- Multiple routes, vehicles, missions and upgrades
- Optional rewarded ads for revive or double coins
- No gambling, betting, chat or real-money wagering

Traffic imekubana. Can you become the king of the road?
```

## Required Store Assets

- Draft app icon exists: `assets/store_listing/icon-512.png` (512 x 512).
- Draft feature graphic exists:
  `assets/store_listing/feature-graphic-1024x500.png` (1024 x 500).
- Four draft phone screenshots exist at 1080 x 1920 under
  `assets/store_listing/`.
- Recapture screenshots after the final UI/gameplay pass so the listing matches
  the uploaded bundle.
- The standard Android launcher icon uses the prepared 512 x 512 artwork. A
  dedicated adaptive foreground/background pair remains recommended.
- Recommended screenshots:
  - Main menu
  - Gameplay with lanes and obstacles
  - Vehicle/Garage screen
  - Route selection
  - Game over/results with score
  - Settings language switch

## Play Console Declarations

Detailed copy/paste answers are in
`docs/PLAY_CONSOLE_APP_CONTENT_ANSWERS.md`.

- App category: Game, **Racing** (Arcade is the fallback).
- Suggested tags: Endless runner, Driving, Casual, Offline, limited to tags
  currently offered by Play Console.
- Contains ads: Yes.
- App access: No login required.
- Target audience: likely general audience/family-friendly. Answer the Play
  target audience questions honestly from final game content.
- Monetization: fake in-game coins only.
- Gambling/betting: No.
- Real-money purchases: No for MVP, unless IAP is added later.
- Data safety:
  - The game stores high score, coins, unlocks, selected vehicle, settings, and
    language locally on device.
  - AdMob may collect device/ad identifiers, diagnostics, approximate location,
    and ad interaction data according to Google Mobile Ads SDK behavior.
  - Complete the Data safety form based on the final SDKs enabled at release.
- Privacy policy URL:
  `https://kadioko.github.io/Dala-Dala-Rush/privacy-policy.html`.
  It returned HTTP 200 on August 19, 2026; recheck before submission.
- Content rating: complete the Play questionnaire. Expected result should be
  low/family-friendly if no violent, sexual, gambling, or user-generated content
  is added.

## Pre-Upload QA

- Install the debug APK on a real Android phone.
- Verify launch, main menu, settings, Swahili/English switching, route select,
  garage, gameplay, pause, crash, revive, double coins, and game over.
- Verify the route briefing/countdown uses natural localized wording, remains
  centered, and hides the live HUD until control begins.
- Verify ads use test mode or test devices before public release.
- Do not click live ads during development.
- Confirm the release AAB uploads successfully to an internal testing track.
- Run a closed/internal test before production.
- Verify the merged release manifest contains
  `com.google.android.gms.permission.AD_ID` and the AdMob application ID.
- Complete a reward-heavy run, force-close from results, and confirm every
  settled reward restores together after restart.
- Test both ABIs through Play delivery where practical.

## Remaining Before The Next Tester Rollout

- Review the generated store icon/feature graphic and capture fresh screenshots
  from the next release candidate.
- Produce a dedicated adaptive foreground/background icon pair.
- Verify the in-app Privacy Policy link on the release build.
- Confirm `support@kadioko.com` is monitored.
- Test real AdMob callbacks and consent behavior on a registered test device.
- Review final Data safety answers against the exact SDK version.
- Increment to version code `7` or higher, export and verify a fresh signed AAB,
  then inspect Play Console warnings before rollout.
- Finalize bilingual notes from `docs/RELEASE_NOTES_NEXT.md`.
