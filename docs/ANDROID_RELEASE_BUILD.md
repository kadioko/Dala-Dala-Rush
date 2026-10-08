# Android Release Build Runbook

Last updated: October 8, 2026.

Use this document to create and validate a signed Android App Bundle for Google
Play production-track updates. Store-listing work and Play Console declarations are in
`PLAY_STORE_RELEASE_CHECKLIST.md`.

## Current Configuration

| Setting | Value |
|---|---|
| Godot | 4.7.1 stable |
| Android template | `android/.build_version` = `4.7.1.stable` |
| Release preset | `Android AAB Release` |
| Package | `com.kadioko.daladalarush` |
| Minimum SDK | API 24 / Android 7.0 |
| Target SDK | API 36 / Android 16 |
| Architectures | `armeabi-v7a`, `arm64-v8a` |
| Build system | Gradle custom build |
| Format | Android App Bundle (`.aab`) |
| Current production release | Version 1.0.13, code 14 |
| Last exported candidate | Version 1.0.16, code 17 |
| Artifact status | Signed candidate built and bundle-validated from current source. A21s/second-phone QA and Play processing remain before rollout. |
| Artifact path | `exports/android/DalaDalaRushTZ-production-v16.aab` |
| Version rule | Use a never-before-used code higher than every artifact in every Play track |

API 36 satisfies Google Play's mobile app-update requirement beginning August
31, 2026. Recheck the current policy before future releases:
https://support.google.com/googleplay/android-developer/answer/11926878

## Release Gates

Complete these before rolling the verified bundle out to testers:

- [ ] All intended code and documentation changes are present.
- [ ] Settings includes an in-app Privacy Policy link.
- [ ] Final launcher and adaptive icons replace the generic `icon.svg`.
- [ ] Swahili and English menus have been checked at 540x960 and on a phone.
- [ ] Railway hardening is deployed separately, migration 005 completed, and
  the live leaderboard write/read behavior has been smoke-tested.
- [x] Shared limiter migration 006 and matching API revision are deployed;
  the updated privacy policy is published.
- [ ] Complete the small-phone and two-phone competition checks in
  `DEVICE_QA.md`; update the privacy policy and review Play Data Safety before
  rollout.
- [ ] Rewarded, interstitial, banner, and consent behavior have been tested on
  a registered AdMob test device.
- [ ] The support email is monitored.
- [ ] Store screenshots have been recaptured from this release candidate.
- [ ] The release keystore and credentials have a private backup.

Do not put keystore passwords, key passwords, or credentials in source files,
Markdown, commits, screenshots, terminal transcripts, or Play release notes.
`export_presets.cfg` is intentionally ignored by Git because it contains local
signing configuration.

## 1. Confirm The Version

The current release candidate is exported from the Android AAB preset with:

```text
Version name: 1.0.16
Version code: 17
```

The code must be greater than every active artifact in every Play track,
including internal, closed, open, and production tracks. If code 8 has already
been uploaded, use a never-before-used code higher than 8 for a replacement
build even if code 8 was never promoted.

Confirm the local preset without displaying signing values:

```powershell
Select-String -Path export_presets.cfg `
  -Pattern 'version/code=|version/name=|gradle_build/min_sdk=|gradle_build/target_sdk=|architectures/'
```

## 2. Validate The Project

Close any running game instance, then run the full Godot editor parse:

```powershell
$godot = 'C:\Users\USER\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe'
& $godot --headless --editor --path '.' --quit
```

The command must exit with code 0 and show no parser errors or warnings treated
as errors.

Also check the worktree for whitespace errors:

```powershell
git diff --check
```

Run the core logic contracts:

```powershell
& $godot --headless --path '.' res://tests/logic_contracts.tscn -- --logic-contracts
```

This must print `LOGIC CONTRACTS: PASS` and exit with code 0.

## 3. Confirm Android And Signing Setup

In Godot, open `Editor > Editor Settings > Export > Android` and verify:

- Android SDK points to the installed SDK.
- Java points to JDK 17 or Android Studio's bundled JBR.
- The release preset reports a valid release keystore and alias.
- Gradle/custom build is enabled.
- Target SDK is 36 and minimum SDK is 24.
- Both ARM architectures are enabled.
- The Poing Studios AdMob plugin is enabled.

Never print or paste signing passwords into a command used for documentation or
support. Let Godot read the local ignored preset or a private password file.

## 4. Export The Signed AAB

Preferred editor path:

```text
Project > Export > Android AAB Release > Export Project
```

The current test candidate is:

```text
exports/android/DalaDalaRushTZ-production-v16.aab
```

Equivalent command-line export:

```powershell
$godot = 'C:\Users\USER\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe'
& $godot --headless --path '.' `
  --export-release 'Android AAB Release' `
  'exports/android/DalaDalaRushTZ-production-v16.aab'
```

Do not interrupt the process. A successful command must return exit code 0 and
the requested AAB must have a new modification time.

## 5. Verify The Artifact

Run the repeatable source/backend gate before exporting or uploading:

```powershell
.\tools\verify_project.ps1 -GodotPath 'C:\path\to\Godot_v4.7.1-stable_win64_console.exe'
```

The source gate includes locale/data contracts and headless responsive UI bounds
across the documented portrait sizes. Screenshot review still requires the
normal renderer or a phone.

Pass `-BundlePath`, `-BundletoolJar`, `-ExpectedVersionName`,
`-ExpectedVersionCode`, and `-ExpectedTargetSdk` to include signed artifact
verification in the same run. The script intentionally does not claim that
physical-device QA or Play Console review has passed.

Set the artifact path once:

```powershell
$aab = 'exports/android/DalaDalaRushTZ-production-v16.aab'
```

Confirm it exists, record its size, and create a checksum:

```powershell
Get-Item $aab | Select-Object FullName, Length, LastWriteTime
Get-FileHash $aab -Algorithm SHA256
```

Verify the JAR signature:

```powershell
& "$env:JAVA_HOME\bin\jarsigner.exe" -verify -verbose -certs $aab
```

The final output should report that the JAR is verified. Certificate-chain
warnings about a self-signed upload key can be expected; a failed signature is
not acceptable.

After export, verify the merged release manifest generated by Gradle:

```powershell
Get-ChildItem 'android/build/build/intermediates' -Recurse `
  -Filter AndroidManifest.xml | Select-String `
  -Pattern 'com.google.android.gms.permission.AD_ID|com.google.android.gms.ads.APPLICATION_ID'
```

Both the advertising-ID permission and AdMob application-ID metadata must be
present. This prevents the Advertising ID mismatch seen in earlier artifacts.

Optional, when Google's `bundletool` is installed:

```powershell
java -jar bundletool-all.jar validate --bundle $aab
```

Run the reusable artifact check after export. It verifies the JAR signature and
bundle structure; pass `bundletool-all.jar` to also inspect version, target SDK,
AdMob metadata, and the Advertising ID permission:

```powershell
.\tools\verify_android_release.ps1 `
  -BundlePath $aab `
  -BundletoolJar 'C:\path\to\bundletool-all.jar' `
  -ExpectedVersionName '1.0.16' `
  -ExpectedVersionCode 17 `
  -ExpectedTargetSdk 36
```

### Previous Code 14 Verification Record

- Artifact: `exports/android/DalaDalaRushTZ-production-v13.aab`
- Size: `61,525,651` bytes
- SHA-256: `7170353AF393A549BB334A62531DEF90883F35EFEA0C78FDA9D58993FD97813E`
- Bundle structure contains the base manifest/resources and release signature
  entries. Google Play processing remains the authoritative AAB validation.

### Code 15 Verification Record

- Artifact: `exports/android/DalaDalaRushTZ-production-v14.aab`
- Size: `61,541,199` bytes
- SHA-256: `A6D497DCBB6C2EE4DDBD5FC673C341D70C55C01128EA08348B228C54F4A6CC7B`
- `jarsigner` reports `jar verified`.
- The release manifest reports version `1.0.14`, code `15`, target API `36`,
  the AdMob application ID metadata, and `com.google.android.gms.permission.AD_ID`.
- Godot 4.7.1 printed export completion and produced the verified artifact; its
  headless process did not exit normally and was stopped after artifact checks.

These checks verify bundle structure and signing only. They do not replace the
physical-device, consent, or Play pre-launch checks below.

### Code 16 Verification Record

- Artifact: `exports/android/DalaDalaRushTZ-production-v15.aab`
- Size: `61,551,226` bytes.
- SHA-256: `834DCB20E7C0A7CC0229C765DC5037F0BCC80A44B6FC7F32B4331F470DA72153`.
- `jarsigner` reports `jar verified` and the reusable verifier confirms the
  AAB structure.
- The generated Gradle bundle manifest reports version `1.0.15`, code `16`,
  target API `36`, AdMob application-ID metadata, and
  `com.google.android.gms.permission.AD_ID`.
- Godot 4.7.1 export completed. Physical-device and Play Console validation
  remain outstanding.

### Code 17 Test Candidate

- Artifact: `exports/android/DalaDalaRushTZ-production-v16.aab`
- Size: `61,572,416` bytes.
- SHA-256: `35B5EBD8D3EFA454CF21118918754342A21FD17DDA64FBE80C42379EBC4B527F`.
- `jarsigner` reports `jar verified`; bundletool 1.18.3 validation passes.
- Manifest confirms version `1.0.16`, code `17`, minimum API `24`, target API
  `36`, `armeabi-v7a` and `arm64-v8a`, AdMob application-ID metadata, and both
  Advertising ID permissions.
- This is a test candidate, not a phone-validated production rollout. Install
  through the intended Play testing track and complete `DEVICE_QA.md` first.

## 6. Install Through Play Testing

An AAB is not installed directly like an APK. Upload it to the intended Play
track, wait for processing, then install through Play delivery. This tests the
same split APK delivery users receive.

On the installed build, verify:

- Splash, main menu, Play transition, gameplay, pause, crash, and results.
- Route briefing/countdown is centered in both languages and the live HUD
  appears only after driving begins.
- Left, horn, and right controls do not overlap or trigger each other.
- Swahili/English switching and all saved settings survive restart.
- Rewarded revive restores the complete run state exactly once.
- Double Coins cannot be combined with revive on the same result.
- Interstitial cadence survives restart and remains every 2-3 completed runs.
- Banners appear only on menu/results.
- Save data survives a force-close after a reward-heavy result.
- World standings clearly show loading, empty, cached, offline, and retry
  states in Swahili and English. Friend standings remain consent-gated.
- A pending score survives offline/relaunch, Retry visibly uploads it after
  connectivity returns, and successful or already-surpassed responses clear
  the queue while the local confirmation survives restart.
- The name field remains visible above the keyboard on 360px and 393px phones;
  long names do not collide with rank or score.
- With two phones, an opted-in test score appears on the public World board,
  while the second phone can view without joining. Friend features require both
  profiles to opt in.
- Performance and thermals remain acceptable for at least 10 minutes.

Use the complete device matrix in `ANDROID_EXPORT.md`.

## 7. Upload Checklist

- [ ] Upload the newly verified versioned AAB to the intended Play track.
- [ ] Confirm Play Console reads version code 17 and target API 36.
- [ ] Confirm the Advertising ID warning is absent for the new artifact.
- [ ] Review native-code debug-symbol and deobfuscation notices. These are
  warnings unless obfuscation is enabled, but record the decision.
- [ ] Add finalized localized notes from `RELEASE_NOTES_1.0.16.md`.
- [ ] Recheck Ads, Data safety, target audience, content rating, app access,
  financial, health, and government declarations.
- [ ] Confirm the public privacy URL opens:
  `https://kadioko.github.io/Dala-Dala-Rush/privacy-policy.html`.
- [ ] Save the SHA-256 checksum with the private release record.
- [ ] Roll out to testers only after Play's artifact checks pass.

## Common Failures

### Export template is missing or mismatched

The installed template and engine must both be 4.7.1. Check:

```powershell
Get-Content android/.build_version
```

Regenerate the Android build template from Godot only if it is genuinely
missing or mismatched; preserve the AdMob plugin configuration when doing so.

### Play says the version code already exists

Increase the version code in both Android presets, rebuild, and upload the new
artifact. Version codes can never be reused.

### Advertising ID warning returns

Inspect the merged release manifest from the exact new export. Confirm Gradle
custom build and the AdMob Android library are enabled, then rebuild. Do not
choose “release without permission” when Play Console declares Advertising ID
usage.

### AdMob singleton is absent on Android

Confirm the editor plugin is enabled, Gradle custom build is enabled, the
Android AdMob library is present, and the build was exported after plugin
installation. Editor simulation does not prove the Android singleton works.

### Signing fails

Confirm the private keystore path, alias, and passwords in the ignored local
preset. Do not generate a replacement upload key casually; verify the key used
for the previous accepted Play artifact first.

## Definition Of Done

The Android release build is complete only when the signed AAB passes local
checks, uploads as a new Play artifact, installs through Play delivery,
completes the device/ad/save test pass, and has no blocking Play Console errors.
