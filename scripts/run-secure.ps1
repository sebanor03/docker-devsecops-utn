$ErrorActionPreference = 'Stop'
Write-Host "`n========================================`nRUN - VERSION ENDURECIDA`n========================================"
docker rm -f devsecops-secure 2>$null | Out-Null
docker run --rm -d --name devsecops-secure --read-only --cap-drop=ALL --security-opt=no-new-privileges:true --tmpfs /tmp -p 5001:5000 docker-devsecops:secure
if ($LASTEXITCODE -ne 0) { throw 'No se pudo iniciar el contenedor. ¿Construiste las imágenes?' }
Write-Host 'Aplicación: http://localhost:5001/  | Salud: http://localhost:5001/health'
