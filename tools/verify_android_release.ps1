param(
	[Parameter(Mandatory = $true)]
	[string]$BundlePath,
	[string]$BundletoolJar,
	[string]$ExpectedVersionName,
	[int]$ExpectedVersionCode = 0,
	[int]$ExpectedTargetSdk = 0,
	[string]$ExpectedPackage,
	[string]$ExpectedSignerSha256
)

$ErrorActionPreference = "Stop"
$identity = Get-Content -LiteralPath (Join-Path $PSScriptRoot '..\data\release_identity.json') -Raw | ConvertFrom-Json
if (-not $ExpectedPackage) { $ExpectedPackage = $identity.package_name }
if (-not $ExpectedSignerSha256) { $ExpectedSignerSha256 = $identity.upload_certificate_sha256 }
$ExpectedSignerSha256 = $ExpectedSignerSha256.Replace(':', '').ToUpperInvariant()
if ($ExpectedSignerSha256 -notmatch '^[A-F0-9]{64}$') { throw 'Expected upload-certificate SHA-256 is invalid.' }
if (-not $BundletoolJar) { throw 'BundletoolJar is required for release package and manifest verification.' }
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
	Add-Type -AssemblyName System.Security.Cryptography.Pkcs
	$signatureEntries = @($archive.Entries | Where-Object { $_.FullName -match '^META-INF/[^/]+\.(RSA|DSA|EC)$' })
	if ($signatureEntries.Count -eq 0) { throw 'AAB contains no signing certificate block.' }
	foreach ($signatureEntry in $signatureEntries) {
		$stream = $signatureEntry.Open()
		$buffer = [System.IO.MemoryStream]::new()
		try { $stream.CopyTo($buffer) } finally { $stream.Dispose() }
		$cms = [System.Security.Cryptography.Pkcs.SignedCms]::new()
		$cms.Decode($buffer.ToArray())
		$buffer.Dispose()
		if ($cms.SignerInfos.Count -ne 1) { throw 'Unexpected number of signers in AAB.' }
		$digest = [System.Security.Cryptography.SHA256]::Create()
		try { $actual = [BitConverter]::ToString($digest.ComputeHash($cms.SignerInfos[0].Certificate.RawData)).Replace('-', '') }
		finally { $digest.Dispose() }
		if ($actual -ne $ExpectedSignerSha256) { throw 'AAB upload signing certificate does not match the pinned release identity.' }
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
	[xml]$manifest = $manifestText
	if ($manifest.DocumentElement.GetAttribute('package') -ne $ExpectedPackage) {
		throw "AAB package does not match $ExpectedPackage"
	}
	foreach ($required in @("com.google.android.gms.permission.AD_ID", "com.google.android.gms.ads.APPLICATION_ID",
		"org.godotengine.plugin.v2.DalaConsent", "com.kadioko.dalaconsent.DalaConsent")) {
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
Write-Output "AAB package, pinned upload certificate, signature, bundle structure, and manifest: verified"
