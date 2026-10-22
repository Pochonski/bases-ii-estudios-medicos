# Informe a ChatGPT — despliegue Windows y publicación local, Joseph

**Fecha:** 22/10/2026, America/Costa_Rica. **Objetivo:** continuar PR #1 en el alcance de
Joseph, resolver la disponibilidad de Docker Desktop sin reinstalar ni alterar WSL/kernel,
ejecutar el manual en Windows y corregir cualquier fallo real de la infraestructura.

## Resumen ejecutivo

Docker Desktop 4.91.0 volvió a exponer Engine 29.8.0 tras conservar por renombrado dos
carpetas transitorias de sockets que impedían su arranque. El build local de PostgreSQL con
`tds_fdw` y `mongo_fdw` pasó; PostgreSQL, SQL Server y MongoDB arrancaron y respondieron
consultas autenticadas en la PC Windows 11. El kernel efectivo del motor fue
`6.18.33.2-microsoft-standard-WSL2`.

El primer despliegue descubrió un defecto no detectado por la CI anterior: el overlay
solicitaba puertos en `HostConfig`, pero los motores conectados exclusivamente a una red
`internal: true` no los publicaron. Se agregó un contenedor auxiliar HAProxy sin secretos
que enlaza la red interna con una red bridge y publica solo en `127.0.0.1`. Las pruebas
ahora verifican `NetworkSettings.Ports` y conexiones TCP reales desde el host. Clientes
Windows autenticaron PostgreSQL y SQL Server por esos puertos. La prueba P12 conservó una
fila sintética de PostgreSQL tras `restart`, sin cambiar su contenedor, volumen, gateway ni
puertos. El marcador fue eliminado. P12 sigue parcial; el gate FDW/BSON sigue abierto.
La CI del último commit de código pasó en los tres jobs; se conserva evidencia separada
para Windows 11, Windows Server CI y Ubuntu CI.

## Rama, PR y alcance Git

- Inicio: `fc7b305b3db36044664fe93051223fcbf0f4a8e8`, árbol limpio, remoto igual.
- Rama: `feature/joseph-infra-postgresql`; `main`/`origin/main` permanecían en
  `630cca6b14f23d73579ccab2a0106ab1fa68f7fc` al iniciar.
- [PR #1](https://github.com/Pochonski/bases-ii-estudios-medicos/pull/1): OPEN/DRAFT al
  inicio; debe mantenerse así. No se emitió aprobación ni merge.
- Commits de esta continuación: `841969c` (gateway y prueba efectiva), `9b22c98`
  (evidencia/manual), `0b5e507` (mensajes exactos por modo). El cierre posterior
  documenta la CI sin cambiar código; su SHA final se consigna en la entrega.
- [CI anterior del código H1–H3, 39759092391](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/39759092391):
  tres jobs PASAN en `a801c88`; solo comprobó `HostConfig`, no puertos activos. La
  [CI de `fc7b305`, 39791879419](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/39791879419)
  terminó SUCCESS, sin el gateway actual.
- [CI del gateway, 39807402214](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/39807402214):
  SUCCESS sobre head `0b5e507`; Windows Server ACL y Ubuntu base/localhost. Checkout de
  merge `533079c3c16a57f14b82729e0eb9d8f9093d0f31`. Tres artifacts revisados.

## Archivos creados o modificados

| Ruta | Cambio real |
|---|---|
| `compose.local.yaml` | `port-gateway` opcional con puertos localhost, bridge `host-access`, red interna compartida y healthcheck. |
| `docker/port-gateway/haproxy.cfg` | Reenvío TCP de PostgreSQL, SQL Server y MongoDB; sin credenciales. |
| `scripts/Compose-Context.ps1` | Valida tres motores internos y gateway opcional; compara puerto activo del gateway y proyecto/ID/salud; prueba TCP de host; rechaza overlay omitido. |
| `scripts/Test-Infra.ps1`, `Test-Persistence.ps1` | Verifican puertos activos y gateway antes/después de reinicio. P12 conserva solo alcance PostgreSQL. |
| `.github/workflows/joseph-infra.yml` | Diagnóstico del gateway si falla CI; la matriz existente base/localhost ejecuta el nuevo test. |
| README, `docs/00`, `02`, `05`, `07`, `10`, `11`, manual Windows | Estado actualizado y D-034, sin cambiar contratos de datos. |
| `evidencias/registros/2026-10-22-joseph-despliegue-windows.txt`, `evidencias/README.md`, este informe | Resultados reales, fallo previo, límites y comandos. |
| `evidencias/registros/2026-10-22-joseph-gateway-ci.txt` | Head/checkout, tres jobs y extractos de artifacts del nuevo código. |

No se modificaron los módulos asignados a Joyce/Armando, modelo clínico, claves, vista
`dbo.vw_estado_facturacion` ni contrato MongoDB. H1–H3 habían sido cerrados técnicamente
por Joseph; D-034 responde a una limitación adicional observada al ejecutar Windows.

## Decisiones y versiones

**D-034:** mantener `medical-network` con `internal: true` para los tres motores y añadir
una pasarela sin secretos solo cuando se usa `compose.local.yaml`. Cambiar la red de los
motores a no interna habría debilitado el aislamiento. La pasarela es un cuarto contenedor
auxiliar, no un cuarto motor. Tiene filesystem de solo lectura, 128 MiB de límite y
configuración TCP sin lógica de aplicación. La red `host-access` no es interna; solo la
pasarela puede salir por ella. Los puertos host siguen ligados a 127.0.0.1.

Versiones observadas en esta PC: PowerShell 7.6.5; Docker Desktop 4.91.0.239619;
Engine 29.8.0; Compose v5.5.1; WSL 2.7.10.0; kernel Docker
`6.18.33.2-microsoft-standard-WSL2`; PostgreSQL 16.15; SQL Server 2022 CU27-GDR
16.0.4305.5; MongoDB 8.0.34; `tds_fdw` 2.0.5; `mongo_fdw` extensión 1.1/código
5.5.3; HAProxy 3.2.26 `3.2-alpine` por digest
`sha256:dfba86f031bd4c9039f10f8cc5de75991d1b6766d5460f0335b980408503baad`.
Estos son candidatos para el spike, no aprobación de compatibilidad FDW funcional.

La explicación de redes internas se contrasta con la
[documentación de Compose](https://docs.docker.com/compose/how-tos/networking/);
el patrón de socket inaccesible también aparece en
[docker/desktop-feedback#531](https://github.com/docker/desktop-feedback/issues/531).
La observación local, no esos enlaces, sustenta el resultado de esta PC.

## Comandos ejecutados y resultados

Antes de cambiar archivos se revisaron README, AGENTS, `agents/JOSEPH.md`, protocolo y
documentos aplicables `docs/00,01,02,03,04,05,06,07,08,10,11`, guía y reporte previo.
`git status/log/fetch/rev-parse` y `gh pr view` confirmaron rama/PR/base sin cambios posteriores.

Diagnóstico: `docker info`, `docker desktop status/restart --timeout 40`, `docker context ls`,
`Get-Service`, `Get-Process`, `wsl --list --verbose`, lectura acotada del log backend y
`fsutil reparsepoint query` del socket. El log reportó error 1920 al renombrar
`sailor-ingest.sock`; `fsutil` reprodujo error 1920. El reinicio CLI quedó esperando,
por lo que se interrumpió. `docker desktop stop --force --timeout 30` terminó; tras
verificar ausencia de procesos GUI/backend, `Move-Item -LiteralPath` conservó las dos
carpetas de sockets con sufijo temporal fuera del repo. `Start-Process` del ejecutable
instalado abrió Desktop; `docker info` confirmó Engine Linux. No se borraron datos,
volúmenes ni se ajustó WSL/kernel o protecciones del sistema.

La selección para todos los comandos posteriores fue:

```powershell
$deploy = @{
    ComposeFile = @('compose.yaml','compose.local.yaml')
    EnvFile = @('.env','.tmp/windows-local/ports.env')
    ProjectName = 'estudios-medicos'
}
```

El puerto 5432 estaba ocupado por un proceso ajeno; `.tmp/windows-local/ports.env`
(ignorado por Git) definió `POSTGRES_PORT=15432`, `SQLSERVER_PORT=11433` y
`MONGODB_PORT=37017`. No se editó `.env`; el inicializador conservó sus valores y los
tres secretos, comprobados con hashes **solo en memoria**. Se ejecutaron:

```powershell
./scripts/Initialize-Local.ps1
./pruebas/infraestructura/Test-Secrets.ps1
./pruebas/infraestructura/Test-ComposeValidation.ps1
./scripts/Test-Infra.ps1 @deploy -StaticOnly
./scripts/Invoke-Compose.ps1 @deploy -Command @('pull','sqlserver','mongodb')
./scripts/Invoke-Compose.ps1 @deploy -Command @('build','postgres')
./scripts/Invoke-Compose.ps1 @deploy -Command @('up','-d','--wait','--wait-timeout','300')
./scripts/Test-Infra.ps1 @deploy
./scripts/Test-Persistence.ps1 @deploy
```

El primer `up` correspondió al overlay antiguo y demostró el fallo de publicación; el
segundo, con gateway, recreó contenedores para aplicar la nueva configuración, conservando
volúmenes. No había marcador P12 antes de esa recreación. Los scripts de prueba corrieron
con el gateway saludable. Se ejecutaron además `docker inspect` (HostConfig,
NetworkSettings, montajes), `docker port`, `docker network inspect`,
`Get-NetTCPConnection`, `docker stats --no-stream`, parser PowerShell, `git diff --check`
y prueba negativa de selección base ante despliegue overlay. Clientes Windows `psql.exe`
y `sqlcmd.exe` usaron secretos solo en variables de proceso temporales, eliminadas después.
La [evidencia detallada](../evidencias/registros/2026-10-22-joseph-despliegue-windows.txt)
preserva salidas resumidas; los logs de build/pull/up siguen en `.tmp/windows-local` ignorado.

CI: `gh run watch 39807402214 --exit-status` salió 0; `gh run view ... --json`
confirmó `completed/success` en head 0b5e507 y los tres jobs. `gh run download`
guardó artifacts ignorados en `.tmp/ci-gateway-final-39807402214`; se revisaron
`runtime.txt`, `persistencia.txt`, `resumen.txt`, regresión de configuración y ACL.
El [extracto durable](../evidencias/registros/2026-10-22-joseph-gateway-ci.txt)
registra IDs, versiones, salidas pertinentes y límites sin secretos. La matriz
Ubuntu22 usó kernel 6.8.0-1070-azure, Docker 28.0.4 y Compose 2.38.2. En base
`puertos=[]`; en overlay `NetworkSettings.Ports` reflejó 127.0.0.1:5432/1433/27017
y los tres TCP del runner respondieron. P12 parcial pasó en ambos modos.

## Pruebas: resultado y alcance

| Clase | Resultado Windows 11 |
|---|---|
| **IMPLEMENTADO Y PROBADO** | H1 DACL en carpeta/archivos y valores conservados; H3 negativo con `.env` temporal; H2 selección explícita/ambiental; siete scripts sin error de sintaxis; config Compose y `git diff --check`. |
| **IMPLEMENTADO Y PROBADO** | Build local FDW; tres motores saludables y consultas autenticadas; carga de extensiones y reglas PG; lectura de secretos por UID de cada motor. |
| **IMPLEMENTADO Y PROBADO** | Gateway con `NetworkSettings.Ports` activo, tres listeners 127.0.0.1 y tres sondas TCP desde Windows; clientes nativos PostgreSQL/SQL Server autenticados vía gateway. |
| **IMPLEMENTADO Y PROBADO parcialmente** | P12: una fila sintética PostgreSQL sobrevivió `restart`; se mantuvieron ID de contenedor, volumen, ID de gateway, bindings activos y TCP; tabla eliminada. |
| **PROBADO NEGATIVO** | Selección solo base con gateway existente: falla antes de crear fila. Primer overlay: motores saludables pero sin puertos activos; prueba anterior era insuficiente. |
| **IMPLEMENTADO, NO PROBADO** | Recuperación persistente de Docker Desktop tras un nuevo reinicio del programa o Windows. |
| **NO EJECUTADO** | Persistencia SQL Server/MongoDB, recreación con marcador, backup/restauración, consultas FDW remotas, BSON/INSERT/UPDATE Mongo desde FDW, cuentas restringidas propias y pruebas negativas de permisos. |
| **BLOQUEADO POR DEPENDENCIA** | Vista/base/cuenta/fixture SQL Server de Joyce; autenticación, tipos BSON, escritura, índice único y revisión Mongo FDW con Joyce. |
| **PENDIENTE** | DDL clínico, particiones SJ/AL/CA, datos ficticios, outbox y gates siguientes tras spike; trabajo Armando en su fase. |

MongoDB desde Windows solo aceptó la conexión TCP de prueba; la autenticación MongoDB
que se acredita fue dentro del contenedor. Las consultas FDW no se sustituyen por
`CREATE EXTENSION`/`LOAD`. `NOLOGIN`/`SET ROLE` no acreditan login propio ni permisos negativos.

## Problemas, riesgos y próximas tareas

- Se conservan dos carpetas de sockets antiguas fuera del repo. La recuperación fue exitosa
  en un inicio, sin probar duración tras reboot. No afirmar causa raíz ni que un workaround
  sirva para otros fallos de Desktop.
- El gateway es otro componente operativo. Sus puertos están limitados a localhost y no
  recibe secretos; el bridge auxiliar le permite salida, por lo que esa excepción queda
  explícita. La base sin overlay sigue aislada y sin puertos publicados.
- La CI previa H1–H3 sigue válida para sus hallazgos, pero su prueba de puertos solo verificó
  bindings solicitados. La nueva matriz 39807402214 sí demostró publicación activa y TCP
  del host Ubuntu. No representa Windows 11; esa evidencia local consta aparte.
- P12 no acredita recreación ni restauración; un volumen montado no es backup. No se borraron
  volúmenes ni se alteraron recursos Docker ajenos.
- Joseph: revisar la CI del nuevo commit, conservar artifacts depurados, ejecutar junto con
  Joyce el spike `tds_fdw` sobre vista real/cuenta limitada y `mongo_fdw` con BSON y escrituras,
  registrar fallos y decidir el gate. La coordinación corresponde al equipo; no se enviaron
  mensajes a compañeros en esta sesión.
- Después del gate, Joseph crea esquema/particiones/datos ficticios de su alcance y prueba
  P14; Armando mantiene su trabajo posterior. Toda ampliación de persistencia/restauración
  necesita prueba separada y evidencia sintética.

La rama y PR se mantendrán en borrador. Aprobación y merge requieren nueva autorización de Joseph.
