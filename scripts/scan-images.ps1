$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
Write-Host "`n========================================`nPIP-AUDIT - VERSION INSEGURA`n========================================"
docker run --rm -v "${root}:/src" -w /src python:3.12-slim sh -c 'pip install --quiet pip-audit && pip-audit -r insecure/requirements.txt'
Write-Host "`n========================================`nPIP-AUDIT - VERSION SEGURA`n========================================"
docker run --rm -v "${root}:/src" -w /src python:3.12-slim sh -c 'pip install --quiet pip-audit && pip-audit -r secure/requirements.txt'
Write-Host "`n========================================`nHADOLINT - DOCKERFILES`n========================================"
docker run --rm -i -v "${root}:/work" hadolint/hadolint:latest hadolint /work/insecure/Dockerfile /work/secure/Dockerfile
Write-Host "`n========================================`nTRIVY - IMAGEN INSEGURA`n========================================"
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v devsecops-trivy-cache:/root/.cache/trivy -v "${root}/reports:/reports" aquasec/trivy:latest image --scanners vuln --quiet --format json --output /reports/trivy-insecure.json --severity CRITICAL,HIGH,MEDIUM,LOW docker-devsecops:insecure
$insecureReport = Get-Content -Raw reports/trivy-insecure.json | ConvertFrom-Json
$insecureVulnerabilities = @($insecureReport.Results | ForEach-Object { $_.Vulnerabilities } | Where-Object { $_ })
foreach ($severity in @('CRITICAL','HIGH','MEDIUM','LOW')) { $count = @($insecureVulnerabilities | Where-Object { $_.Severity -eq $severity }).Count; Write-Host ("{0}: {1}" -f $severity,$count) }
Write-Host "`n========================================`nTRIVY - IMAGEN SEGURA`n========================================"
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v devsecops-trivy-cache:/root/.cache/trivy -v "${root}/reports:/reports" aquasec/trivy:latest image --scanners vuln --quiet --format json --output /reports/trivy-secure.json --severity CRITICAL,HIGH,MEDIUM,LOW docker-devsecops:secure
$secureReport = Get-Content -Raw reports/trivy-secure.json | ConvertFrom-Json
$secureVulnerabilities = @($secureReport.Results | ForEach-Object { $_.Vulnerabilities } | Where-Object { $_ })
foreach ($severity in @('CRITICAL','HIGH','MEDIUM','LOW')) { $count = @($secureVulnerabilities | Where-Object { $_.Severity -eq $severity }).Count; Write-Host ("{0}: {1}" -f $severity,$count) }
