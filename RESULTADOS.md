# Registro de auditoría técnica — Docker + DevSecOps

## Ejecución y entorno

- Fecha: 2026-10-01 (auditoría local; escaneos de imagen registrados entre 13:01 y 13:02 UTC).
- Entorno: Windows, PowerShell; Docker Engine 29.7.2; imágenes Linux/amd64.
- Imágenes inspeccionadas: `docker-devsecops:insecure` y `docker-devsecops:secure`; no se reconstruyeron.
- La aplicación no se modificó. Los hallazgos se registran para revisión posterior.

## Versiones verificadas

| Componente | Versión comprobada | Evidencia |
|---|---:|---|
| Docker Engine | 29.7.2 | `docker version --format '{{.Server.Version}}'` |
| Python en las imágenes de aplicación | 3.12.14 (ambas) | `docker exec ... python --version` |
| Flask | insecure 2.2.2; secure 3.1.3 | `pip show Flask` dentro de cada contenedor |
| Bandit | 1.9.4 | `bandit --version` en Python 3.12.14 |
| Gitleaks | 8.30.1 | `gitleaks version` |
| pip-audit | 2.10.1 | `pip-audit --version` en Python 3.12.14 |
| Hadolint | 2.15.1 | `hadolint --version` |
| Trivy | 0.74.0 | salida `--version` y campo `Trivy.Version` de ambos JSON |
| OWASP ZAP | 2.17.0 | metadata de `reports/zap-report.json` (reporte existente) |

Bandit y pip-audit se instalaron en contenedores efímeros desde los índices disponibles durante esta ejecución. Gitleaks, Hadolint y Trivy se ejecutaron con las etiquetas `latest`; las versiones de la tabla son las consultadas al momento de la auditoría.

## Imágenes Docker

Tamaños expresados en MB decimales (bytes / 1.000.000).

| Variante | Tag | Image ID | RepoDigest informado por Docker | Tamaño | Creada (UTC) |
|---|---|---|---|---:|---|
| Insecure | `docker-devsecops:insecure` | `sha256:852af57ca6af4a8511479898d11143af9a517098a7e4e595398bd54e8f555515` | `docker-devsecops@sha256:852af57ca6af4a8511479898d11143af9a517098a7e4e595398bd54e8f555515` | 416.937.043 bytes / 416,94 MB | 2026-09-29 22:28:56Z |
| Secure | `docker-devsecops:secure` | `sha256:67b755d5413dfea1948ed2cb14e9302dcd9efd920f3b99dcada208cf3b02e6d7` | `docker-devsecops@sha256:67b755d5413dfea1948ed2cb14e9302dcd9efd920f3b99dcada208cf3b02e6d7` | 44.865.434 bytes / 44,87 MB | 2026-09-29 22:29:00Z |

INSECURE: 416,94 MB
SECURE: 44,87 MB
DIFERENCIA: 372,07 MB menos en secure (89,24 % menor respecto de insecure).

Los valores RepoDigest se copiaron de `docker image inspect`; se consignan como los informa el daemon para estas etiquetas locales.

## Validación funcional y hardening runtime

| Comprobación | Insecure | Secure |
|---|---|---|
| `GET /` | HTTP satisfactorio; JSON `{"aplicacion":"Docker DevSecOps Demo","estado":"funcionando"}` | HTTP satisfactorio; mismo JSON |
| `GET /health` | HTTP satisfactorio; `{"status":"OK"}` | HTTP satisfactorio; `{"status":"OK"}` |
| Usuario del proceso | `root` | `appuser` |
| Escritura en `/app/rootfs-write-test` | Permitida | Rechazada: `Read-only file system` |
| Escritura en `/tmp/demo-write` | No fue requisito de contraste | Permitida en tmpfs |

Valores verificados en `docker inspect devsecops-secure`:

- Config.User: `appuser`
- HostConfig.ReadonlyRootfs: `true`
- HostConfig.CapDrop: `["ALL"]`
- HostConfig.SecurityOpt: `["no-new-privileges:true"]`
- HostConfig.Tmpfs: `{ "/tmp": "" }`

Las dos pruebas funcionales se ejecutaron con los scripts `run-insecure.ps1` y `run-secure.ps1`. Al terminar se eliminaron únicamente los dos contenedores temporales creados para esta auditoría; las imágenes permanecen locales.

## Controles DevSecOps ejecutados

| Control | Insecure: hallazgos observados | Exit code | Secure: hallazgos observados | Exit code |
|---|---|---:|---|---:|
| Gitleaks | 1 marcador ficticio detectado; el valor es de laboratorio, no una credencial funcional | 1 | Sin leaks reportados | 0 |
| Bandit | 3: High 1 (`B201` debug=True), Medium 1 (`B104` bind a todas las interfaces), Low 1 (`B105` cadena con aspecto de contraseña) | 1 | 0 issues identificados; 1 issue suprimido por `# nosec` (`B104`, bind requerido por el contenedor) | 0 |
| pip-audit | 22 vulnerabilidades conocidas en 2 paquetes (Flask 2.2.2 y Werkzeug 2.2.2) | 1 | No known vulnerabilities found para `secure/requirements.txt` en esta ejecución | 0 |
| Hadolint | 1 warning: `DL3042`, instalación pip sin `--no-cache-dir` | 1 | 1 info: `DL3066`, usuario configurado por nombre no numérico | 1 |
| Trivy | 4.074 hallazgos de vulnerabilidades: Critical 19, High 351, Medium 2.248, Low 1.456 | 0 | 207 hallazgos de vulnerabilidades: Critical 0, High 51, Medium 89, Low 67 | 0 |

Los exit codes corresponden a los comandos individuales reproducidos durante la auditoría. Trivy terminó con 0 para ambas imágenes porque el comando no configuró un umbral de fallo; ese código no significa que haya cero hallazgos. El exit code 1 de Hadolint también se observó para el Dockerfile secure, que produjo el hallazgo informativo `DL3066`.

### Detalle Trivy por tipo de paquete

Resultados actuales de `reports/trivy-insecure.json` y `reports/trivy-secure.json` (Trivy 0.74.0, escáner `vuln`, generados 2026-10-01).

| Imagen / tipo | Critical | High | Medium | Low | Total |
|---|---:|---:|---:|---:|---:|
| Insecure — Debian OS (`debian 13.7`) | 19 | 348 | 2.237 | 1.453 | 4.057 |
| Insecure — paquetes Python | 0 | 3 | 11 | 3 | 17 |
| Secure — Debian OS (`debian 13.7`) | 0 | 51 | 84 | 66 | 201 |
| Secure — paquetes Python | 0 | 0 | 5 | 1 | 6 |

## Revisión de OWASP ZAP Baseline

Se revisaron los informes existentes `reports/zap-report.json` y `reports/zap-report.html`. El JSON indica ZAP 2.17.0, objetivo `http://host.docker.internal:5001` y `created: 2026-09-29T22:59:29.788854135Z`. No se volvió a ejecutar ZAP el 2026-10-01. Riesgo y cantidad son los valores exactos del JSON; la clasificación y la posible causa son una evaluación del reporte y del comportamiento predeterminado de Flask/Werkzeug.

| Nombre exacto | Riesgo (confianza ZAP) | Instancias | URL o endpoint afectado | Descripción resumida | Posible causa | Clasificación |
|---|---|---:|---|---|---|---|
| Content Security Policy (CSP) Header Not Set | Medium (High) | 2 | `http://host.docker.internal:5001/robots.txt`; `http://host.docker.internal:5001/sitemap.xml` | Falta CSP, que restringe orígenes de contenido y mitiga ciertas clases de XSS/inyección en páginas web. | La app/servidor no añade la cabecera; ZAP también revisó rutas auxiliares no definidas por la app. | b) Recomendación de hardening HTTP |
| Cross-Origin-Resource-Policy Header Missing or Invalid | Low (Medium) | 1 | `http://host.docker.internal:5001/` | Falta una política CORP para limitar el uso cross-origin del recurso. | Cabecera no configurada por la app/servidor. | b) Recomendación de hardening HTTP |
| Permissions Policy Header Not Set | Low (Medium) | 2 | `http://host.docker.internal:5001/robots.txt`; `http://host.docker.internal:5001/sitemap.xml` | Falta una política que restrinja funciones del navegador como cámara, micrófono o geolocalización. | Cabecera no configurada en respuestas del servidor; las instancias están en rutas auxiliares. | b) Recomendación de hardening HTTP |
| Server Leaks Version Information via "Server" HTTP Response Header Field | Low (High) | 3 | `http://host.docker.internal:5001/`; `/robots.txt`; `/sitemap.xml` | La cabecera `Server` revela `Werkzeug/3.1.9 Python/3.12.14`. | Cabecera informativa predeterminada de Werkzeug, según la evidencia incluida por ZAP. | b) Recomendación de hardening HTTP (divulgación de versión de baja severidad) |
| X-Content-Type-Options Header Missing | Low (Medium) | 1 | `http://host.docker.internal:5001/` | Falta `X-Content-Type-Options: nosniff`, relacionado con el sniffing MIME de navegadores. | Cabecera no configurada por la app/servidor. | b) Recomendación de hardening HTTP |
| Storable and Cacheable Content | Informational (Medium) | 1 | `http://host.docker.internal:5001/` | La respuesta podría almacenarse en caché; ZAP asume heurísticamente una vida de caché de un año al no ver directiva explícita. | La respuesta no envía una directiva de caché explícita; el endpoint devuelve JSON genérico y no se observó información personal o de sesión. | c) Hallazgo informativo |

En estos informes no se observó una vulnerabilidad explotable de la lógica de la aplicación (categoría a). Cinco alertas son recomendaciones de cabeceras HTTP; la sexta es informativa y debe leerse considerando que `/` expone datos genéricos de la demo. No se modificó la aplicación para suprimirlas.

## Validación CI/CD en GitHub Actions

- Repositorio: <https://github.com/sebanor03/docker-devsecops-utn>
- Rama: `main`
- Workflow: `DevSecOps - hardened version`
- Trigger probado: `push` a `main`
- Ejecución: Run #1, asociada al commit `Initial Docker DevSecOps practical case`
- Resultado: **SUCCESS**

Todas las etapas finalizaron correctamente: Checkout; Gitleaks (secret scanning); Bandit (SAST); pip-audit (SCA); Hadolint (Dockerfile); Docker Build de la imagen secure; Trivy (reporte de CRITICAL y HIGH); Trivy (gate de CRITICAL); comprobaciones funcionales de endpoints; y comprobaciones de hardening runtime.

El pipeline evalúa la versión secure/endurecida. La variante insecure se conserva únicamente como comparación educativa. Un pipeline exitoso confirma el cumplimiento de la política definida, no la ausencia total de vulnerabilidades: la política actual de Trivy bloquea vulnerabilidades CRITICAL, mientras que los hallazgos HIGH permanecen visibles en el reporte y no bloquean este pipeline académico. La ejecución real confirmó 0 vulnerabilidades CRITICAL en el gate de Trivy.

Las comprobaciones funcionales verificaron los endpoints de la aplicación. Las pruebas runtime verificaron el usuario `appuser`, el sistema de archivos raíz de solo lectura (`ReadonlyRootfs=true`) y la escritura permitida en `/tmp` mediante tmpfs. Esta ejecución demuestra la automatización del enfoque Shift-Left dentro del proceso CI/CD.

## Limitaciones y notas

- Los resultados describen el estado de estas imágenes y bases de avisos durante la ejecución; las bases y las etiquetas de escáner `latest` cambian con el tiempo.
- Los recuentos Trivy cubren vulnerabilidades del sistema Debian y paquetes Python detectados; no equivalen a una prueba de explotabilidad.
- ZAP corresponde al informe del 2026-09-29, no a un nuevo DAST del 2026-10-01. El análisis Baseline pasivo tampoco prueba ausencia de fallas.
- La regla Bandit `B104` se suprime en secure porque el servidor Flask debe enlazarse a la interfaz del contenedor; la supresión continúa apareciendo en el resumen de Bandit.
- Existen hallazgos HIGH, MEDIUM y LOW en la imagen secure; el pipeline verde solo significa que se cumplió la política configurada, que actualmente bloquea CRITICAL.
- La validación de GitHub Actions acredita la ejecución del workflow en el repositorio remoto; no implica publicación de las imágenes en un registro remoto. Las imágenes de esta auditoría fueron inspeccionadas localmente y sus RepoDigest se registran exactamente como los mostró Docker.
- Los informes Trivy actuales están en `reports/`; ZAP conserva los informes ya existentes en esa carpeta.
