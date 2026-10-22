param()
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$gradle = Join-Path $root 'android/build/gradlew.bat'
$native = Join-Path $root 'native/consent'
if (-not (Test-Path -LiteralPath $gradle)) { throw 'Install the Godot Android template first.' }
$env:ANDROID_HOME = Join-Path $env:LOCALAPPDATA 'Android/Sdk'
& $gradle -p $native assembleRelease --console=plain
if ($LASTEXITCODE -ne 0) { throw 'Native consent bridge build failed.' }
$destination = Join-Path $root 'addons/dala_consent/libs'
New-Item -ItemType Directory -Path $destination -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $native 'build/outputs/aar/dala-consent-release.aar') -Destination $destination
Write-Output 'Consent bridge built. Test SDK consent on a registered Android device.'
