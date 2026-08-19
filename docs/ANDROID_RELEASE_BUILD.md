# Android Release Build Runbook

Last verified: August 19, 2026.

Use this document to create and validate a signed Android App Bundle for Google
Play closed testing. Store-listing work and Play Console declarations are in
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
| Latest local closed-testing artifact | Version 1.0.5, code 6 |
| Artifact status | Built and locally verified, but older than current source |
| Next source build | Version code 7 or higher; proposed version name 1.0.6 |

API 36 satisfies Google Play's mobile app-update requirement beginning August
31, 2026. Recheck the current policy before future releases:
https://support.google.com/googleplay/android-developer/answer/11926878

## Release Gates

Complete these before rolling the verified bundle out to testers:

- [ ] All intended code and documentation changes are present.
- [ ] Settings includes an in-app Privacy Policy link.
- [ ] Final launcher and adaptive icons replace the generic `icon.svg`.
- [ ] Swahili and English menus have been checked at 540x960 and on a phone.
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

The current verified local artifact was exported from both Android presets with:

```text
Version name: 1.0.5
Version code: 6
```

The code must be greater than every active artifact in every Play track,
including internal, closed, open, and production tracks. If code 6 has already
been uploaded, use code 7 for a replacement build even if code 6 was never
promoted.

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

The next source build should use a new filename:

```text
exports/android/DalaDalaRushTZ-closed-testing-v7.aab
```

Equivalent command-line export:

```powershell
$godot = 'C:\Users\USER\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe'
& $godot --headless --path '.' `
  --export-release 'Android AAB Release' `
  'exports/android/DalaDalaRushTZ-closed-testing-v7.aab'
```

Do not interrupt the process. A successful command must return exit code 0 and
the requested AAB must have a new modification time.

## 5. Verify The Artifact

Set the artifact path once:

```powershell
$aab = 'exports/android/DalaDalaRushTZ-closed-testing-v7.aab'
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

## 6. Install Through Play Testing

An AAB is not installed directly like an APK. Upload it to the closed-testing
track, wait for processing, then install from the tester opt-in link. This tests
the same split APK delivery users receive.

On the installed build, verify:

- Splash, main menu, Play transition, gameplay, pause, crash, and results.
- Left, horn, and right controls do not overlap or trigger each other.
- Swahili/English switching and all saved settings survive restart.
- Rewarded revive restores the complete run state exactly once.
- Double Coins cannot be combined with revive on the same result.
- Interstitial cadence survives restart and remains every 2-3 completed runs.
- Banners appear only on menu/results.
- Save data survives a force-close after a reward-heavy result.
- Performance and thermals remain acceptable for at least 10 minutes.

Use the complete device matrix in `ANDROID_EXPORT.md`.

## 7. Upload Checklist

- [ ] Upload the newly verified versioned AAB to the intended Play track.
- [ ] Confirm Play Console reads version code 7 or higher and target API 36.
- [ ] Confirm the Advertising ID warning is absent for the new artifact.
- [ ] Review native-code debug-symbol and deobfuscation notices. These are
  warnings unless obfuscation is enabled, but record the decision.
- [ ] Finalize and add localized notes from `RELEASE_NOTES_NEXT.md`.
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
signature/manifest checks, uploads as a new Play artifact, installs through the
closed-testing link, completes the device/ad/save test pass, and has no blocking
Play Console errors.
