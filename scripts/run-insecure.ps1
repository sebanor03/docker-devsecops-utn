$ErrorActionPreference = 'Stop'
Write-Host "`n========================================`nRUN - VERSION INSEGURA`n========================================"
docker rm -f devsecops-insecure 2>$null | Out-Null
docker run --rm -d --name devsecops-insecure -p 5000:5000 docker-devsecops:insecure
if ($LASTEXITCODE -ne 0) { throw 'No se pudo iniciar el contenedor. ¿Construiste las imágenes?' }
Write-Host 'Aplicación: http://localhost:5000/  | Salud: http://localhost:5000/health'
