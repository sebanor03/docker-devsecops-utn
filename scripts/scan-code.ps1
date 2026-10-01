$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
$mount = "${root}:/src"
Write-Host "`n========================================`nBANDIT - VERSION INSEGURA`n========================================"
docker run --rm -v "${mount}" -w /src python:3.12-slim sh -c 'pip install --quiet bandit && bandit -f txt insecure/app.py'
Write-Host "`n========================================`nBANDIT - VERSION SEGURA`n========================================"
docker run --rm -v "${mount}" -w /src python:3.12-slim sh -c 'pip install --quiet bandit && bandit -f txt secure/app.py'
Write-Host "`n========================================`nGITLEAKS - VERSION INSEGURA`n========================================"
docker run --rm -v $mount -w /src ghcr.io/gitleaks/gitleaks:latest dir --config .gitleaks.toml insecure
$insecureCode = $LASTEXITCODE
Write-Host "`n========================================`nGITLEAKS - VERSION SEGURA`n========================================"
docker run --rm -v $mount -w /src ghcr.io/gitleaks/gitleaks:latest dir --config .gitleaks.toml secure
$secureCode = $LASTEXITCODE
Write-Host "`nGitleaks exit codes: insecure=$insecureCode secure=$secureCode (1 indica hallazgo)."
