param(
	[string]$GodotPath,
	[string]$BundlePath,
	[string]$BundletoolJar,
	[string]$ExpectedVersionName,
	[int]$ExpectedVersionCode = 0,
	[int]$ExpectedTargetSdk = 0
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot

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

	Write-Output "Project release gates: PASS"
} finally {
	Pop-Location
}
