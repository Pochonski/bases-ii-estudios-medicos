# Informe para ChatGPT — revisión técnica menor del PR #1

**Responsable:** Joseph, infraestructura. **Fecha:** 22/10/2026. **Rama:**
`feature/joseph-infra-postgresql`. **PR:**
https://github.com/Pochonski/bases-ii-estudios-medicos/pull/1 — OPEN/DRAFT;
base `main` `630cca6b14f23d73579ccab2a0106ab1fa68f7fc`. No se aprobó ni fusionó.

## Resumen ejecutivo

Se cerraron las dos observaciones menores de infraestructura en el código: el workflow
incluye `docker/port-gateway/**`, y el gateway informa disponibilidad de sus tres
backends mediante un endpoint de salud interno. Se agregó una prueba negativa controlada
en CI que detiene PostgreSQL, verifica que el frontend TCP aún acepta conexiones pero
que el gateway y la validación runtime rechazan el backend caído, y luego inicia el
mismo contenedor sin borrar datos ni volúmenes. La CI final pasó sus tres jobs. Los
bindings host siguen restringidos a `127.0.0.1`; el endpoint de salud no se publica.

El primer intento de la prueba falló: `pause` no cerró el socket TCP, por lo que
HAProxy mantuvo el backend UP. El fallo y su corrección a `stop/start` se conservan.
En Windows local las pruebas positivas y P12 parcial pasaron, pero el daemon de Docker
Desktop volvió a quedar inaccesible después; no se afirma estabilidad del host.

## Commits y archivos

- `5d73d9e55d19a2f11201787e4c99ea80f73f9024` — filtro de workflow,
  endpoint `/ready`, healthcheck y primer test negativo (estimulación con `pause`).
- `ee5ce970e61428b5c68440d2ce3b39f0f39b500d` — cambiar estímulo del test
  a `stop/start` para cerrar realmente el socket del backend. La CI exitosa probó
  este commit de código.
- El cierre documental posterior registra D-035, bitácora, matriz, guía e informe;
  su SHA se obtiene del historial de esta rama.

| Archivo | Cambio real |
|---|---|
| `.github/workflows/joseph-infra.yml` | Filtro `docker/port-gateway/**` y paso de caída controlada solo en matriz localhost. |
| `docker/port-gateway/haproxy.cfg` | `/ready` en loopback interno 127.0.0.1:8404; 503 si `nbsrv` de PG, SQL Server o MongoDB es cero. |
| `compose.local.yaml` | Healthcheck del gateway consulta `/ready` en vez de validar solo sintaxis. |
| `pruebas/infraestructura/Test-GatewayBackendFailure.ps1` | `stop/start` protegido por `GITHUB_ACTIONS` y nombre de proyecto efímero; comprueba rechazo, recuperación, IDs, volumen y bindings. |
| `docs/00`, `02`, `05`, `07`, `10`, `11`; `documentacion/JOSEPH_FASE1_WINDOWS.md` | Estado, arquitectura, seguridad, pruebas, D-035, bitácora e instrucciones con límites reales. |
| `evidencias/registros/2026-10-22-joseph-gateway-backend-ci.txt` y este informe | Extractos depurados de Windows/CI, fallo histórico y auditoría. |

No se modificaron contratos clínicos, modelo de datos ni módulos de Joyce/Armando.

## Decisiones técnicas y versiones

La sonda anterior abría TCP al frontend y ejecutaba `haproxy -c`; podía pasar sin un
backend disponible. HAProxy 3.2.26 permite que `monitor-uri` devuelva 503 con
`monitor fail` y `nbsrv` si no hay servidores activos (manual oficial:
https://docs.haproxy.org/3.2/configuration.html). Docker inspecciona ese resultado
cada 3 s, con 2 reintentos y 10 s de inicio. El endpoint escucha solo en el loopback
del contenedor; el overlay conserva únicamente los tres puertos host 127.0.0.1.
El test usa `docker compose stop/start` en un proyecto CI efímero; conserva contenedor
y volúmenes y siempre intenta iniciar PostgreSQL en `finally`. No se introducen
credenciales nuevas ni cambios de versión de motores/FDW.

Windows 11 local: Docker Desktop 4.91.0, Engine 29.8.0, kernel efectivo WSL2
`6.18.33.2-microsoft-standard-WSL2`, Compose 5.5.1 y PowerShell 7.6.5.
CI Ubuntu 22.04: kernel `6.8.0-1070-azure`, Docker 28.0.4, Compose 2.38.2,
PowerShell 7.6.7. CI ACL: Windows Server 2022, PowerShell 7.6.6.
Imagen gateway: `haproxy:3.2-alpine` por digest ya fijado en el overlay. Los demás
digests y extensiones se conservan como en D-027/D-034, sin validación FDW remota nueva.

## Comandos ejecutados y resultados

- `git status/log/diff`, `gh pr view`, `git commit`, `git push`, `gh run list/view/watch/download`,
  `gh api .../artifacts`: rama correcta; PR OPEN/DRAFT; artifacts descargados.
- `docker info/ps/inspect/exec`, `docker desktop status`, `wsl --status/--version`,
  `Get-Service com.docker.service`: motor disponible durante pruebas; inaccesible al
  cierre por named pipe ausente, servicio detenido.
- `docker exec ... haproxy -c -f ...`: PASS. `docker exec ... wget ... /ready`:
  HTTP 200 en estado sano. Parser PowerShell y `git diff --check`: PASS.
- `./scripts/Test-Infra.ps1 -StaticOnly -ComposeFile compose.yaml,compose.local.yaml
  -EnvFile .env,.tmp/windows-local/ports.env -ProjectName estudios-medicos`: PASS
  ejemplo base, overlay y selección operativa.
- `./scripts/Invoke-Compose.ps1` con esa selección y `restart port-gateway`, luego
  `up -d --no-deps --force-recreate --wait port-gateway`: PASS; solo gateway recreado,
  IDs de motores conservados. Se aplicó el nuevo healthcheck sin borrar volúmenes.
- `./scripts/Test-Infra.ps1` con esa selección: PASS tres consultas autenticadas,
  lectura de secretos por UID, puerto activo y host TCP. `docker inspect` confirmó
  únicamente `127.0.0.1:11433/15432/37017`; 8404 no está publicado.
- `./scripts/Test-Persistence.ps1` con esa selección: PASS **parcial** PostgreSQL;
  fila sintética después de `restart`, mismo contenedor/gateway/volumen/puertos y
  marcador eliminado. No equivale a P12 completo.

## Evidencia CI y fallo conservado

- [Run 39811585204](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/39811585204),
  head `5d73d9e`: **FAIL** en negativo localhost después de 60 s. `pause` dejó
  el socket de PG abierto; HAProxy no marcó backend DOWN. `finally` hizo `unpause`.
  Jobs ACL Windows y base pasaron; P12 localhost no se ejecutó.
- [Run 39812197292](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/39812197292),
  head `ee5ce97`, checkout merge `ed428667`: **SUCCESS** en ACL Windows,
  infraestructura base e infraestructura localhost. Artifact
  `joseph-infra-localhost/backend-failure.txt` confirma rechazo y recuperación;
  `runtime.txt` muestra bindings 127.0.0.1 y consultas autenticadas;
  `persistencia.txt` confirma P12 parcial. Base no publica puertos; ACL Windows
  conserva valores y restringe DACL. Los tres artifacts tienen retención de 14 días;
  extractos durables en el registro de evidencia.

El filtro nuevo está presente y un commit que modificó esa ruta inició el workflow,
pero ese commit también cambió el workflow y otros archivos. No se ejecutó un cambio
que tocara **exclusivamente** `docker/port-gateway/**` para aislar el filtro.

## Riesgos, pendientes y dependencias

- **Docker Desktop Windows intermitente:** al terminar, `docker info` falló por falta
  de `dockerDesktopLinuxEngine`; `docker desktop status` no pudo obtener estado y
  `com.docker.service` estaba Stopped. Las pruebas locales anteriores son reales,
  pero no demuestran continuidad tras reinicio Desktop/Windows. No se reinició ni
  reinstaló Docker, cambió WSL/kernel o borraron volúmenes.
- El healthcheck verifica disponibilidad TCP de HAProxy, no una transacción o login
  por el gateway. El caso `pause` mostró que un proceso congelado puede conservar
  socket abierto y aparecer UP. La CI valida `stop`, no todas las clases de fallo.
- P12 sigue limitado a una fila PostgreSQL tras `restart`; SQL Server/MongoDB,
  recreación, backup y restauración NO EJECUTADOS.
- FDW TDS real, autenticación/consulta remota y tipos dependen de base, vista
  `dbo.vw_estado_facturacion`, cuenta restringida y fixture de Joyce. Mongo FDW
  todavía requiere ObjectId, Int64/Int32, Date, INSERT/UPDATE, índice único y
  revisión. NOLOGIN/SET ROLE no prueban login propio ni permisos negativos.
  El gate de conectores sigue abierto; no se contactó a compañeros.

## Valoración y siguientes tareas de Joseph

Las observaciones menores de infraestructura están **listas para revisión técnica
final de este alcance**: código y regresión CI son reproducibles, con el fallo inicial
y los límites visibles. **Mantener el PR en borrador; no aprobar ni fusionar.** El PR
de fase 1 no puede considerarse aceptación funcional del sistema distribuido ni
superación del gate FDW.

Joseph debe investigar la estabilidad de Docker Desktop con diagnóstico no destructivo
y repetir el manual tras reiniciar Desktop/Windows; junto con Joyce, validar las
consultas TDS y BSON/escrituras Mongo FDW sobre objetos/cuentas reales acordados.
Después podrá continuar su núcleo PostgreSQL bajo los gates de `docs/06_PLAN_IMPLEMENTACION.md`,
sin asumir tareas de Joyce o Armando.
