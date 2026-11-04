param(
	[string]$GodotPath,
	[string]$BundlePath,
	[string]$BundletoolJar,
	[string]$ExpectedVersionName,
	[int]$ExpectedVersionCode = 0,
	[int]$ExpectedTargetSdk = 0,
	[switch]$RequirePostgres
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
if (($BundlePath -or $RequirePostgres) -and -not $env:TEST_DATABASE_URL) {
	throw 'A full release gate requires an isolated TEST_DATABASE_URL ending in _test. Use tools/test_postgres.ps1 -VerifyProject for source gates.'
}

if (-not $GodotPath) {
	$command = Get-Command godot -ErrorAction SilentlyContinue
	if ($command) {
		$GodotPath = $command.Source
	} else {
		$GodotPath = Join-Path $env:USERPROFILE "Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe"
	}
}
if (-not (Test-Path -LiteralPath $GodotPath)) {
	throw "Godot 4.7.1 console executable not found. Pass -GodotPath."
}

Push-Location $projectRoot
try {
	& $GodotPath --headless --editor --path . --quit
	if ($LASTEXITCODE -ne 0) { throw "Godot editor parse/import gate failed." }

	& $GodotPath --headless --path . res://tests/logic_contracts.tscn
	if ($LASTEXITCODE -ne 0) { throw "Godot logic contracts failed." }

	& $GodotPath --headless --path . res://tests/ui_layout_qa.tscn
	if ($LASTEXITCODE -ne 0) { throw "Godot responsive UI bounds checks failed." }
	& $GodotPath --headless --path . res://tests/secondary_ui_qa.tscn
	if ($LASTEXITCODE -ne 0) { throw "Godot secondary-screen bounds checks failed." }
	& $GodotPath --headless --path . res://tests/world_hub_contracts.tscn
	if ($LASTEXITCODE -ne 0) { throw "Godot neighborhood hub economy checks failed." }
	& $GodotPath --headless --path . res://tests/recovery_contracts.tscn
	if ($LASTEXITCODE -ne 0) { throw "Godot recovery/input/save regressions failed." }
	& $GodotPath --headless --path . res://tests/trust_contracts.tscn
	if ($LASTEXITCODE -ne 0) { throw "Godot consent/reward/GUI trust regressions failed." }

	Push-Location (Join-Path $projectRoot "backend")
	try {
		& npm test
		if ($LASTEXITCODE -ne 0) { throw "Backend tests failed." }
	} finally {
		Pop-Location
	}

	if ($BundlePath) {
		$verify = Join-Path $projectRoot "tools\verify_android_release.ps1"
		$params = @{ BundlePath = $BundlePath }
		if ($BundletoolJar) { $params.BundletoolJar = $BundletoolJar }
		if ($ExpectedVersionName) { $params.ExpectedVersionName = $ExpectedVersionName }
		if ($ExpectedVersionCode -gt 0) { $params.ExpectedVersionCode = $ExpectedVersionCode }
		if ($ExpectedTargetSdk -gt 0) { $params.ExpectedTargetSdk = $ExpectedTargetSdk }
		& $verify @params
		if ($LASTEXITCODE -ne 0) { throw "Android bundle verification failed." }
	}

	if ($env:TEST_DATABASE_URL) {
		Write-Output "Project release gates: PASS (including real PostgreSQL)"
	} else {
		Write-Output "Project source gates: PASS (PostgreSQL integration skipped; not a full release gate)"
	}
} finally {
	Pop-Location
}
