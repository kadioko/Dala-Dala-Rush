param(
	[Parameter(Mandatory = $true)]
	[string]$BundlePath,
	[string]$BundletoolJar,
	[string]$ExpectedVersionName,
	[int]$ExpectedVersionCode = 0,
	[int]$ExpectedTargetSdk = 0
)

$ErrorActionPreference = "Stop"
$bundle = (Resolve-Path -LiteralPath $BundlePath).Path
if ([System.IO.Path]::GetExtension($bundle) -ne ".aab") {
	throw "Expected an Android App Bundle (.aab): $bundle"
}

$jarsigner = Join-Path $env:JAVA_HOME "bin\jarsigner.exe"
if (-not (Test-Path -LiteralPath $jarsigner)) {
	throw "jarsigner not found under JAVA_HOME. Install/select JDK 17+ first."
}
$signatureOutput = & $jarsigner -verify -verbose -certs $bundle 2>&1 | Out-String
if ($LASTEXITCODE -ne 0 -or $signatureOutput -notmatch "jar verified") {
	throw "AAB signature verification failed. Review jarsigner output."
}

$archive = [System.IO.Compression.ZipFile]::OpenRead($bundle)
try {
	$entries = @($archive.Entries | ForEach-Object { $_.FullName })
	foreach ($requiredEntry in @("BundleConfig.pb", "base/manifest/AndroidManifest.xml")) {
		if ($entries -notcontains $requiredEntry) {
			throw "AAB is missing required bundle entry: $requiredEntry"
		}
	}
}
finally {
	$archive.Dispose()
}

$manifestText = ""
if ($BundletoolJar) {
	$bundletool = (Resolve-Path -LiteralPath $BundletoolJar).Path
	$manifestText = & java -jar $bundletool dump manifest "--bundle=$bundle" --module=base 2>&1 | Out-String
	if ($LASTEXITCODE -ne 0) {
		throw "bundletool could not read the AAB manifest."
	}
	foreach ($required in @("com.google.android.gms.permission.AD_ID", "com.google.android.gms.ads.APPLICATION_ID")) {
		if ($manifestText -notmatch [regex]::Escape($required)) {
			throw "Release manifest is missing $required"
		}
	}
	if ($ExpectedVersionName -and $manifestText -notmatch "android:versionName=`"$([regex]::Escape($ExpectedVersionName))`"") {
		throw "AAB versionName does not match $ExpectedVersionName"
	}
	if ($ExpectedVersionCode -gt 0 -and $manifestText -notmatch "android:versionCode=`"$ExpectedVersionCode`"") {
		throw "AAB versionCode does not match $ExpectedVersionCode"
	}
	if ($ExpectedTargetSdk -gt 0 -and $manifestText -notmatch "targetSdkVersion=`"$ExpectedTargetSdk`"") {
		throw "AAB target SDK does not match $ExpectedTargetSdk"
	}
}

Get-Item -LiteralPath $bundle | Select-Object FullName, Length, LastWriteTime
Get-FileHash -LiteralPath $bundle -Algorithm SHA256
Write-Output "AAB signature and bundle structure: verified"
if (-not $BundletoolJar) {
	Write-Output "Manifest fields: not checked (pass -BundletoolJar to verify version, SDK, AdMob ID, and AD_ID permission)"
}
