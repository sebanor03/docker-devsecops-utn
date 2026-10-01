# Guion de exposición (7–10 minutos)

Usar una terminal PowerShell en la raíz del repositorio. Docker Desktop debe estar iniciado. Los escaneos de imagen requieren red para descargar bases de datos e imágenes de herramientas; ZAP tarda algunos minutos.

## 1. Arquitectura (30 s)

**COMANDO:** ninguno; mostrar el diagrama del README.  
**QUÉ OBSERVAR:** una aplicación Flask local, dos imágenes comparables y analizadores ejecutados como contenedores.  
**QUÉ EXPLICAR:** no hay base de datos, servicios externos ni infraestructura adicional; el objetivo es aislar el aporte de cada control.

## 2. Construir imágenes (45 s)

**COMANDO:** `.\scripts\build.ps1`  
**QUÉ OBSERVAR:** ambos builds desde el mismo contexto con Dockerfiles distintos.  
**QUÉ EXPLICAR:** secure copia solo app y dependencias y usa base slim; el contexto común permite comparar sin duplicar el proyecto.

## 3. Levantar insecure y comprobar aplicación (30 s)

**COMANDO:** `.\scripts\run-insecure.ps1`, luego `Invoke-RestMethod http://localhost:5000/` y `Invoke-RestMethod http://localhost:5000/health`.  
**QUÉ OBSERVAR:** JSON esperado en ambos endpoints.  
**QUÉ EXPLICAR:** la funcionalidad es igual en ambas variantes; se contrastan controles de ciclo de vida.

## 4. Usuario root (20 s)

**COMANDO:** `docker exec devsecops-insecure whoami`  
**QUÉ OBSERVAR:** `root`.  
**QUÉ EXPLICAR:** el Dockerfile no declara USER, así que el proceso hereda el usuario root de la imagen.

**COMANDO:** `docker exec devsecops-insecure sh -c 'touch /tmp/demo-write'`  
**QUÉ OBSERVAR:** la escritura funciona.  
**QUÉ EXPLICAR:** insecure no activa filesystem de solo lectura; el proceso root puede escribir dentro del contenedor.

## 5–9. Controles de código y artefactos (2 min)

**COMANDO:** `.\scripts\scan-code.ps1`  
**QUÉ OBSERVAR:** Gitleaks detecta el único marcador ficticio en insecure; Bandit reporta el uso de Flask debug; secure no contiene el marcador ni el hallazgo esperado.  
**QUÉ EXPLICAR:** el secreto es texto de laboratorio, no una credencial; Gitleaks usa regla personalizada. El debug habilita herramientas del servidor de desarrollo y se desactiva en secure.

**COMANDO:** `.\scripts\scan-images.ps1`  
**QUÉ OBSERVAR:** pip-audit identifica avisos conocidos para Flask 2.2.2; Hadolint diferencia instrucciones; Trivy informa conteos reales por severidad.  
**QUÉ EXPLICAR:** se compara con una dependencia fija y corregida; los números de Trivy varían según la base y el día, por eso se completan en RESULTADOS.md desde la ejecución real.

## 10. Detener insecure (10 s)

**COMANDO:** `.\scripts\stop.ps1`  
**QUÉ OBSERVAR:** contenedores de demostración detenidos/eliminados.  
**QUÉ EXPLICAR:** ambos publican puertos distintos; el script de limpieza es idempotente para el uso normal.

## 11–15. Secure y runtime hardening (1 min)

**COMANDO:** `.\scripts\run-secure.ps1`, `docker exec devsecops-secure whoami`, `Invoke-RestMethod http://localhost:5001/health`.  
**QUÉ OBSERVAR:** usuario `appuser` y salud `OK`.  
**QUÉ EXPLICAR:** `USER appuser` limita el impacto de comprometer el proceso.

**COMANDO:** `docker exec devsecops-secure sh -c 'touch /app/rootfs-write-test'` y `docker exec devsecops-secure sh -c 'touch /tmp/demo-write'`.  
**QUÉ OBSERVAR:** la primera escritura falla; la segunda funciona por el tmpfs de `/tmp`.  
**QUÉ EXPLICAR:** `--read-only` monta la raíz como solo lectura; tmpfs es una zona efímera escribible.

**COMANDO:** `docker inspect devsecops-secure --format '{{.HostConfig.CapDrop}} {{.HostConfig.SecurityOpt}}'`  
**QUÉ OBSERVAR:** `ALL` y `no-new-privileges:true`.  
**QUÉ EXPLICAR:** descartar capabilities retira permisos Linux adicionales; no-new-privileges impide adquirir privilegios nuevos mediante exec/SUID. Se aplican por runtime, no sustituyen actualizar y configurar la app.

## 16–17. Controles secure y DAST (1 min)

**COMANDO:** `.\scripts\scan-code.ps1`, `.\scripts\scan-images.ps1`, `.\scripts\zap-scan.ps1`  
**QUÉ OBSERVAR:** salidas de los controles y los informes ZAP en `reports/`.  
**QUÉ EXPLICAR:** ZAP Baseline realiza spider y análisis pasivo contra `host.docker.internal:5001`, que resuelve al host Docker Desktop; no se envían ataques activos ni se apunta a terceros.

## 18–20. CI, Shift-Left y conclusión (1 min)

**COMANDO:** abrir `.github/workflows/devsecops.yml` y mostrar la ejecución en la pestaña Actions tras publicar el repositorio.  
**QUÉ OBSERVAR:** checkout, Gitleaks, Bandit, pip-audit, Hadolint, build, Trivy y smoke test de secure.  
**QUÉ EXPLICAR:** el pipeline evalúa únicamente el candidato endurecido; el ejemplo insecure queda disponible para aprendizaje y no rompe cada ejecución. Shift-Left significa encontrar y corregir problemas temprano, con feedback automatizado en los cambios. Ningún escáner demuestra ausencia de riesgo.

**CIERRE:** completar `RESULTADOS.md` con lo observado y registrar limitaciones y versiones de herramientas.
