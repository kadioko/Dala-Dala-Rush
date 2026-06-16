# Play Store Release Checklist

Use this as the launch checklist for Dala Dala Rush TZ.

## Build Status

- Package name: `com.kadioko.daladalarush`
- Version name: `1.0.0`
- Version code: `1`
- Min SDK: `24`
- Target SDK: `35`
- Export format: Android App Bundle (`.aab`)
- Gradle/custom build: enabled for AdMob
- Release AAB path: `exports/android/DalaDalaRushTZ-release.aab`
- Debug APK path: `exports/android/DalaDalaRushTZ-debug.apk`

Google Play currently requires new apps and app updates to target Android 15
API 35 or higher. This project targets API 35.

## Signing

Release signing is stored outside the repository:

- Keystore: `C:/Users/USER/Documents/Coding/Games/DalaDalaRushTZ_release/dala_dala_rush_tz_release.jks`
- Credentials file: `C:/Users/USER/Documents/Coding/Games/DalaDalaRushTZ_release/release-signing-credentials.txt`
- Alias: `daladalarush`

Do not commit the keystore or credentials file. Keep a backup in a private,
secure location. Losing this key can block future app updates unless Play App
Signing recovery is configured.

## Store Listing Copy

Short description:

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

## Required Store Assets

- App icon: 512 x 512 PNG.
- Feature graphic: 1024 x 500 PNG.
- Phone screenshots: at least 2, recommended 6-8 portrait screenshots.
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

- App category: Game, Racing or Arcade.
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
- Privacy policy URL: required because the app uses ads. Host a simple privacy
  policy page before production upload.
- Content rating: complete the Play questionnaire. Expected result should be
  low/family-friendly if no violent, sexual, gambling, or user-generated content
  is added.

## Pre-Upload QA

- Install the debug APK on a real Android phone.
- Verify launch, main menu, settings, Swahili/English switching, route select,
  garage, gameplay, pause, crash, revive, double coins, and game over.
- Verify ads use test mode or test devices before public release.
- Do not click live ads during development.
- Confirm the release AAB uploads successfully to an internal testing track.
- Run a closed/internal test before production.

## Known Follow-Ups

- Replace placeholder icon with final 512 x 512 artwork.
- Capture final Play Store screenshots from the current build.
- Publish privacy policy URL.
- Review final data safety answers after testing AdMob on device.
- Consider adding 32-bit ABI support later if you want broader support for very
  old Android devices; the current release AAB was built for `arm64-v8a`.
