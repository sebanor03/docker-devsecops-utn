$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
New-Item -ItemType Directory -Force reports | Out-Null
Write-Host "`n========================================`nOWASP ZAP BASELINE - APLICACION LOCAL`n========================================"
$ready = $false
for ($attempt = 0; $attempt -lt 20; $attempt++) {
    try { Invoke-RestMethod http://localhost:5001/health | Out-Host; $ready = $true; break }
    catch { Start-Sleep -Seconds 1 }
}
if (-not $ready) { throw 'La app segura no responde en localhost:5001 tras 20 segundos. Ejecute scripts/run-secure.ps1.' }
$mount = "${root}:/zap/wrk/:rw"
docker run --rm -t -v $mount ghcr.io/zaproxy/zaproxy:stable zap-baseline.py -t http://host.docker.internal:5001 -r reports/zap-report.html -J reports/zap-report.json
$code = $LASTEXITCODE
Write-Host "Informes: reports/zap-report.html y reports/zap-report.json (si ZAP los generó). Código de salida: $code"
if ($code -gt 1) { throw "ZAP terminó con error de ejecución ($code). Los hallazgos baseline pueden devolver 0 o 1." }
