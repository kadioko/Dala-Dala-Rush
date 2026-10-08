# Dependency and Toolchain Maintenance

Last checked: October 1, 2026

This inventory records the versions used to maintain the production game and
backend. Keep Android release builds reproducible: upgrade the engine, export
templates, and Android plugin as one reviewed change, then run the full export
and device QA before uploading a new AAB.

## Updated and Verified

| Component | Version | Status |
| --- | --- | --- |
| Godot Engine | 4.7.1 stable | Project/release baseline; headless executable verified |
| Godot Android export templates | 4.7.1 stable | Matches the release baseline |
| Godot AdMob plugin | 4.3.1 | Kept in place; production ads depend on this integration |
| Java | 21.0.10 | Installed Android Studio runtime |
| Gradle wrapper | 8.11.1 | Project-generated Android build wrapper |
| Android platform tools (ADB) | 37.0.0-14910828 | Installed and available on PATH |
| Android target SDK | 36 | Current project export target |
| Node.js | 24.19.0 LTS | Updated local backend runtime; package requires Node >=20 |
| npm | 11.19.0 | Local package manager |
| Express | 5.2.1 | Resolved backend dependency |
| node-postgres (`pg`) | 8.23.1 | Updated backend dependency and lockfile |
| Railway CLI | 5.63.1 | Updated global CLI |
| Git | 2.54.0.windows.1 | Installed client |

Verification on this check: backend test suite passed (9/9), and
`npm audit --omit=dev` reported zero vulnerabilities.

## Deliberately Deferred

- **Godot 4.7.2:** a newer patch is available, but the machine currently has
  only the 4.7.1 editor and matching templates installed. Install the matching
  new export templates and verify the project and Android export together
  before changing the documented release baseline. Do not mix 4.7.2 with 4.7.1
  templates for release builds.
- **AdMob plugin 5.x:** the current 4.3.1 to 5.x change is a major integration
  migration, not a routine patch. Review its migration guide, update the Android
  dependency/configuration and GDScript bridge, then test banner, interstitial,
  rewarded ads, consent, resume, and offline behavior on physical Android
  devices before shipping it.
- **Other global CLIs:** unrelated global tools may have newer releases. They
  are not project dependencies and were intentionally not mass-upgraded.

## Routine Checks

Run these from `backend/` after backend dependency changes:

```powershell
npm ci
npm test
npm audit --omit=dev
npm outdated
```

Update compatible backend packages and commit both `package.json` (if it
changes) and `package-lock.json`:

```powershell
npm update
npm test
npm audit --omit=dev
```

For an engine upgrade, install that exact Godot version's export templates,
parse and run the headless contract/UI suites, export a signed test AAB, inspect
its merged manifest and permissions, and complete device QA before calling the
upgrade release-ready. Keep signing material and `export_presets.cfg` out of
Git.
