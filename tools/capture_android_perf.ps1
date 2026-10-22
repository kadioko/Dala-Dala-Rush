param(
    [string]$Serial,
    [ValidateRange(30, 1800)][int]$DurationSeconds = 300,
    [string]$AdbPath = "$env:LOCALAPPDATA/Android/Sdk/platform-tools/adb.exe"
)
$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $AdbPath)) { throw 'ADB not found. Pass -AdbPath.' }
$devices = @(& $AdbPath devices | Select-String '^([^\s]+)\s+device$' | ForEach-Object { $_.Matches[0].Groups[1].Value })
if (-not $Serial) {
    if ($devices.Count -ne 1) { throw 'Connect one authorized phone or pass -Serial explicitly.' }
    $Serial = $devices[0]
}
if ($Serial -notin $devices) { throw 'Selected phone is not connected and authorized.' }
$package = 'com.kadioko.daladalarush'
$root = Split-Path -Parent $PSScriptRoot
$output = Join-Path $root ('exports/device-qa/perf-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Path $output -Force | Out-Null
$samples = [System.Collections.Generic.List[object]]::new()
$startedUnix = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$timer = [System.Diagnostics.Stopwatch]::StartNew()
Write-Output 'Play the same route continuously. Keep brightness, network and charger state fixed. No game settings will be changed.'
do {
    $samples.Add([ordered]@{
        elapsed_seconds = [math]::Round($timer.Elapsed.TotalSeconds, 1)
        memory = @(& $AdbPath -s $Serial shell dumpsys meminfo $package)
        battery = @(& $AdbPath -s $Serial shell dumpsys battery)
        thermal = @(& $AdbPath -s $Serial shell dumpsys thermalservice)
    })
    $remaining = $DurationSeconds - $timer.Elapsed.TotalSeconds
    if ($remaining -gt 0) { Start-Sleep -Seconds ([math]::Min(15, [math]::Ceiling($remaining))) }
} while ($timer.Elapsed.TotalSeconds -lt $DurationSeconds)
$samples | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $output 'samples.json') -Encoding utf8
& $AdbPath -s $Serial shell dumpsys gfxinfo $package | Set-Content -LiteralPath (Join-Path $output 'android-gfxinfo.txt') -Encoding utf8
$engineReport = & $AdbPath -s $Serial shell run-as $package cat files/performance_last.json 2>$null
if ($LASTEXITCODE -eq 0) {
    try { $report = $engineReport | ConvertFrom-Json } catch { $report = $null }
    if ($report -and $report.finished_at_unix -ge $startedUnix -and $report.frames -gt 0) {
        $engineReport | Set-Content -LiteralPath (Join-Path $output 'engine-frame-report.json') -Encoding utf8
    } else {
        Write-Warning 'No fresh completed engine report. Finish the debug capture and retrieve it separately; old results were not copied.'
    }
}
Write-Output "Local evidence: $output"
Write-Output 'Godot frames, Android gfxinfo and battery samples measure different things. A SurfaceView gfxinfo result alone does not prove gameplay frame pacing.'
