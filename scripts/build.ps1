$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
Write-Host "`n========================================`nBUILD - VERSION INSEGURA`n========================================"
docker build -f insecure/Dockerfile -t docker-devsecops:insecure .
if ($LASTEXITCODE -ne 0) { throw 'Falló el build insecure.' }
Write-Host "`n========================================`nBUILD - VERSION SEGURA`n========================================"
docker build -f secure/Dockerfile -t docker-devsecops:secure .
if ($LASTEXITCODE -ne 0) { throw 'Falló el build secure.' }
