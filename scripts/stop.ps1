Write-Host "`n========================================`nSTOP - CONTENEDORES DE LA DEMO`n========================================"
docker rm -f devsecops-insecure devsecops-secure 2>$null
