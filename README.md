# Docker DevSecOps - Caso práctico

Trabajo práctico de Ingeniería de Software de UTN FRLP. Comparamos una aplicación Flask mínima en dos versiones para mostrar cómo sumar controles de seguridad al desarrollo y la ejecución de una imagen Docker.

- `insecure/`: incluye malas prácticas intencionales para la demostración.
- `secure/`: aplica correcciones y medidas de hardening.

El foco está en el proceso DevSecOps; la aplicación es simple y solo expone un par de endpoints.

## ¿Qué se analiza?

- **Gitleaks:** busca secretos en el código.
- **Bandit:** revisa problemas de seguridad en Python (SAST).
- **pip-audit:** detecta vulnerabilidades conocidas en dependencias (SCA).
- **Hadolint:** revisa buenas prácticas en los Dockerfiles.
- **Trivy:** busca vulnerabilidades en las imágenes Docker.
- **OWASP ZAP:** analiza la aplicación mientras está en ejecución (DAST).
- **GitHub Actions:** automatiza controles sobre la versión segura en cada cambio a `main`.

En `secure/` también se endurece el contenedor: corre como `appuser`, usa filesystem raíz de solo lectura, descarta capabilities con `--cap-drop=ALL`, activa `no-new-privileges` y deja `/tmp` escribible mediante tmpfs.

## Estructura del proyecto

```text
insecure/                 Versión insegura de la aplicación
secure/                   Versión endurecida
scripts/                  Scripts para ejecutar la demo y los análisis
reports/                  Reportes generados localmente
demo/DEMO.md              Guía para realizar la demostración
.github/workflows/        Pipeline de GitHub Actions
RESULTADOS.md             Resultados obtenidos en las pruebas
```

## Aplicación

La aplicación es intencionalmente simple, ya que el objetivo del caso práctico es analizar el proceso DevSecOps y no desarrollar un sistema completo.

| Endpoint | insecure | secure |
|---|---|---|
| `GET /` | http://localhost:5000 | http://localhost:5001 |
| `GET /health` | http://localhost:5000/health | http://localhost:5001/health |

## Requisitos

- Windows 10/11
- PowerShell
- Docker Desktop
- Git

Las herramientas de análisis se ejecutan con Docker, así que no hace falta instalarlas individualmente en Windows.

## Cómo ejecutar la demo

Desde la carpeta del proyecto, construir las imágenes:

```powershell
.\scripts\build.ps1
```

Iniciar y probar la versión insecure:

```powershell
.\scripts\run-insecure.ps1
Invoke-RestMethod http://localhost:5000/
Invoke-RestMethod http://localhost:5000/health
docker exec devsecops-insecure whoami
```

El último comando devuelve `root` en insecure. Detenerla antes de iniciar la otra versión:

```powershell
.\scripts\stop.ps1
```

Iniciar y probar secure:

```powershell
.\scripts\run-secure.ps1
Invoke-RestMethod http://localhost:5001/
Invoke-RestMethod http://localhost:5001/health
docker exec devsecops-secure whoami
```

En secure, el proceso corre como `appuser`.

## Análisis de seguridad

Análisis del código y búsqueda de secretos con Gitleaks y Bandit:

```powershell
.\scripts\scan-code.ps1
```

Análisis de dependencias, Dockerfiles e imágenes con pip-audit, Hadolint y Trivy:

```powershell
.\scripts\scan-images.ps1
```

## Hardening del contenedor

Con secure en ejecución, intentar escribir en la raíz del contenedor:

```powershell
docker exec devsecops-secure sh -c 'touch /app/prueba.txt'
```

El comando debe fallar porque el filesystem raíz es de solo lectura. En cambio, `/tmp` usa tmpfs y permite escritura:

```powershell
docker exec devsecops-secure sh -c 'touch /tmp/prueba.txt'
```

Estas pruebas muestran el uso de `appuser`, `--read-only`, `--cap-drop=ALL` y `no-new-privileges` en la variante secure.

## OWASP ZAP

Con secure ejecutándose, lanzar el análisis dinámico:

```powershell
.\scripts\zap-scan.ps1
```

ZAP revisa la aplicación en ejecución y guarda los reportes en `reports/`.

## GitHub Actions

El workflow [devsecops.yml](.github/workflows/devsecops.yml) se ejecuta ante `push` y `pull_request` hacia `main`. Analiza y prueba la variante segura:

```text
Gitleaks
   ↓
Bandit
   ↓
pip-audit
   ↓
Hadolint
   ↓
Docker Build
   ↓
Trivy
   ↓
Pruebas funcionales
   ↓
Pruebas de hardening
```

Automatizar estos controles en cada cambio ayuda a encontrar problemas temprano (Shift-Left). Trivy informa las vulnerabilidades encontradas y, en este caso práctico, el pipeline se configuró para bloquear la ejecución si aparecen vulnerabilidades críticas.

## Resultados y demostración

- [Resultados de las pruebas](RESULTADOS.md)
- [Guion para la demostración](demo/DEMO.md)
