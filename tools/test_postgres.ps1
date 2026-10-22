param([switch]$VerifyProject)
$ErrorActionPreference = 'Stop'
$containerName = 'ddrtz-test-' + [guid]::NewGuid().ToString('N').Substring(0, 10)
$previousUrl = $env:TEST_DATABASE_URL
try {
	& docker run --detach --rm --name $containerName --publish '127.0.0.1::5432' --env POSTGRES_HOST_AUTH_METHOD=trust --env POSTGRES_DB=ddrtz_test postgres:17-alpine
	if ($LASTEXITCODE -ne 0) { throw 'Could not start isolated PostgreSQL test container.' }
	$mapping = & docker port $containerName 5432
	if ($mapping -notmatch '127\.0\.0\.1:(\d+)') { throw 'Could not resolve the PostgreSQL test port.' }
	$env:TEST_DATABASE_URL = 'postgresql://postgres@127.0.0.1:' + $Matches[1] + '/ddrtz_test'
	$ready = $false
	for ($attempt = 0; $attempt -lt 30; $attempt++) {
		& docker exec $containerName pg_isready -U postgres *> $null
		if ($LASTEXITCODE -eq 0) { $ready = $true; break }
		Start-Sleep -Milliseconds 300
	}
	if (-not $ready) { throw 'PostgreSQL test container did not become ready.' }
	if ($VerifyProject) {
		& (Join-Path $PSScriptRoot 'verify_project.ps1') -RequirePostgres
		if (-not $?) { throw 'Full project verification failed.' }
		return
	}
	Push-Location (Join-Path $PSScriptRoot '..\backend')
	try {
		& npm test
		if ($LASTEXITCODE -ne 0) { throw 'PostgreSQL regression tests failed.' }
	} finally { Pop-Location }
} finally {
	$env:TEST_DATABASE_URL = $previousUrl
	& docker stop $containerName *> $null
}
