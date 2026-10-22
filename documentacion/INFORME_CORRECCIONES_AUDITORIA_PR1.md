# Informe de correcciones — auditoría PR #1, Joseph

Fecha: 22/10/2026, America/Costa_Rica.
Objetivo: corregir H1/H2/H3 dentro del alcance de infraestructura de Joseph, con pruebas y evidencia separadas por plataforma.
PR: https://github.com/Pochonski/bases-ii-estudios-medicos/pull/1 — se mantiene OPEN/DRAFT, sin aprobación ni merge.

## Estado comprobado antes de modificar

Se leyó íntegramente AUDITORIA_PR_1.md de la ruta local indicada, README, AGENTS, guías Joseph/protocolo
y documentos de arquitectura, requisitos, datos, integración, seguridad, equipo, decisiones y pruebas.
HEAD local/remoto eran 612d07d4b5ab653d23ea1c045d9064d416ac8413; árbol limpio, sin trabajo posterior.
Base main: 630cca6b14f23d73579ccab2a0106ab1fa68f7fc.
Se confirmó el CI previo [39753627026](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/39753627026):
success sobre 612d07d. Esa evidencia histórica se conserva; no valida por sí sola el código nuevo.

## Hallazgos corregidos y archivos

| Hallazgo | Corrección y evidencia |
|---|---|
| H1, P2, autorizaciones explícitas conservadas | Initialize-Local reconstruye la DACL completa y el propietario en carpeta y todos los archivos normales existentes; herencia protegida, solo usuario/SYSTEM. Lee de nuevo y verifica las reglas. Conserva valores; no sigue enlaces/subcarpetas. Test-Secrets reproduce Everyone/Users explícitos en carpeta y archivos preexistentes, comprueba idempotencia y limpia el fixture. PASA en Windows local y Windows Server CI. |
| H2, P2, pérdida potencial de overlay al probar | Compose-Context/Invoke-Compose comparten selección de archivos/entorno/proyecto/directorio con ambos tests. Test-Persistence elimina up: espera health con inspect del mismo contenedor tras restart. Verifica bindings, ID, volumen y fila; limpia el marcador al pasar y documenta limpieza ante fallo. PASA en CI base y localhost. |
| H3, .env operativo sin validar | Test-Infra conserva comprobaciones del ejemplo y añade una fase operativa separada usando la selección real. Distingue PASS/FAIL por fase. Test-ComposeValidation reproduce .env temporal con POSTGRES_DB vacío y ejemplo válido; rechaza el operativo y verifica .env del usuario intacto. PASA local y CI. |

Archivos de código/pruebas:
- scripts/Initialize-Local.ps1.
- scripts/Compose-Context.ps1 e Invoke-Compose.ps1 (nuevos).
- scripts/Test-Infra.ps1 y Test-Persistence.ps1.
- pruebas/infraestructura/Test-Secrets.ps1 y Test-ComposeValidation.ps1 (nuevos).
- .github/workflows/joseph-infra.yml: ACL Windows, matriz base/localhost, enmascarado y artifacts.

Documentación/evidencia: README, docs/00, 05, 07, 10, 11, guía JOSEPH_FASE1_WINDOWS.md,
referencia al informe histórico, este informe y registros auditoria-windows/auditoria-ci.
Decisiones D-030..D-033. No se cambiaron Compose del proyecto, contratos clínicos, imágenes/versiones ni módulos de Joyce/Armando.

H1 verifica la DACL cerrada y el propietario; no se impersonó ni inició sesión con otro principal.
No se promete impedir que un administrador tome posesión.
Linux conserva directorio 700/archivos 644. La CI comprueba lectura dentro de contenedores como
postgres, SQL Server UID 10001:0 y usuario mongodb, sin mostrar secretos.

## Windows local de Joseph

**IMPLEMENTADO Y PROBADO:** siete scripts sin errores sintácticos; H1 temporal con Everyone y Users;
preservación de secretos y .env; reparación de ACL reales manteniendo los valores existentes;
H2 selección explícita base/overlay y ambiental COMPOSE_*; H3 negativo y .env operativo real válido.
No se publicaron valores ni hashes de contraseñas.

Versiones locales: PowerShell 7.6.5, Git 2.54.0.windows.1, Docker CLI 29.8.0, Compose 5.5.1.
WSL --version informó 2.7.10.0 y kernel instalado 6.18.33.2-2. Esto **no determina** el kernel efectivo de Docker.

**NO EJECUTADO:** build/arranque/motores/salud/consultas/lectura por UID/restart y puertos con datos en Windows.
docker info devuelve código 1: named pipe dockerDesktopLinuxEngine ausente; contexto desktop-linux;
com.docker.service observado Stopped. Son observaciones, no una causa demostrada del problema.
No se reinstaló Docker, cambió WSL/kernel, desactivó protección, inició/reinició servicio ni borró volumen.

Evidencia: [registro Windows](../evidencias/registros/2026-10-22-joseph-auditoria-windows.txt).
Durante la corrección, Set-Acl devolvió SeSecurityPrivilege. Se conservó la SACL y se usó
FileSystemAclExtensions para persistir solo secciones modificadas; la regresión posterior pasó.
La suite aislada también se ajustó para eliminar/restaurar variables mediante Env: y consumir únicamente
el código negativo esperado; los errores operativos reales siguen haciendo fallar Test-Infra.

## CI nueva: resultados y artifacts

[Run 39759092391](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/39759092391) **SUCCESS**.
Head PR probado: a801c88004a7943b96e0355fbaea11ff734c683e.
Checkout de merge para pruebas PR: 24cbf39de9562be792443abc987fb075048bc489.
Ambos se registran en artifacts; no confundir el SHA de checkout con el head de la rama.

| Job | Resultado | Entorno |
|---|---|---|
| secretos-windows | PASA | Windows Server 2022, PowerShell 7.6.6; solo regresión ACL, no motores Linux |
| infraestructura base | PASA | Ubuntu22, kernel 6.8.0-1070-azure, PowerShell 7.6.7 |
| infraestructura localhost | PASA | Mismo entorno Ubuntu; compose.yaml + compose.local.yaml |

Docker cliente/servidor CI 28.0.4, Compose 2.38.2.
Motores: PostgreSQL 16.15 (Debian 16.15-1.pgdg12+2), SQL Server 2022 CU27-GDR 16.0.4305.5,
MongoDB 8.0.34. tds_fdw extversion 2.0.5; mongo_fdw código 5.5.3/extversion SQL 1.1.
Sigue siendo matriz candidata; no se declaró compatibilidad FDW funcional definitiva.

En ambas variantes PASAN build, healthchecks, consultas autenticadas, lectura de secretos por UID,
regresiones y P12 parcial. Base conservó ausencia de bindings; overlay conservó
5432/tcp|127.0.0.1|5432. En ambas pasó la comparación de ID y nombre del volumen y se eliminó el marcador.
Esto no prueba conexión de un cliente SQL desde Windows al puerto publicado.

**Alcance exacto P12:** una fila en la base administrativa postgres después de restart del mismo
contenedor PostgreSQL. Se comprueba montaje del volumen nombrado, sin probar recreación, down/up,
reinicio Docker/WSL, persistencia de SQL Server/MongoDB, backup ni restauración.
No se amplió P12 a los tres motores. Las consultas de cada motor se ejecutaron dentro de su contenedor,
sin acreditar FDW ni autenticación entre motores.

Artifacts depurados revisados (retención 14 días):
- joseph-acl-windows: id 12417057261.
- joseph-infra-base: id 12417237579.
- joseph-infra-localhost: id 12416454634.

Se enmascaran los tres secretos efímeros antes de diagnósticos; el upload incluye únicamente .tmp/ci/*.txt,
no .env, archivos secretos, configs completas ni dumps. Revisión acotada sin coincidencias de valores locales
ni patrones indicados de tokens/claves en los artifacts.
Resumen durable: [registro CI](../evidencias/registros/2026-10-22-joseph-auditoria-ci.txt).
Los fallos CI históricos de kernel MongoDB se conservaron.

## Comandos ejecutados

Lecturas Get-Content -Raw de auditoría y contexto obligatorio; git status/log/remote/fetch/rev-parse/diff;
gh pr view y consultas API de Actions/artefactos. Comandos centrales:

```powershell
git status --short --branch
git fetch origin
git rev-parse HEAD origin/feature/joseph-infra-postgresql main origin/main
docker info --format '{{.ServerVersion}}'
docker context show
docker context ls
Get-Service com.docker.service
wsl --status
wsl --version
./pruebas/infraestructura/Test-Secrets.ps1
./pruebas/infraestructura/Test-ComposeValidation.ps1
./scripts/Initialize-Local.ps1
./scripts/Test-Infra.ps1 -StaticOnly
git diff --check
git push origin feature/joseph-infra-postgresql
gh run view 39753627026 --repo Pochonski/bases-ii-estudios-medicos --json headSha,conclusion,url
gh run view 39759092391 --repo Pochonski/bases-ii-estudios-medicos --json status,conclusion,headSha,url,jobs
gh run download 39759092391 --repo Pochonski/bases-ii-estudios-medicos --dir .tmp/auditoria-ci-39759092391
```

Además, Parser.ParseFile sobre siete .ps1; Get-FileHash solo en memoria para comprobar que valores
y .env existentes no cambiaron; escaneo acotado de archivos publicables contra secretos sin mostrarlos;
git add/commit, diff --cached --check y comparación de ascendencia antes de push, sin force.

La CI ejecutó los tests anteriores y, con COMPOSE_FILE/COMPOSE_ENV_FILES/COMPOSE_PROJECT_NAME consistentes:

```powershell
docker compose --progress plain build postgres
docker compose up -d --wait --wait-timeout 300
./scripts/Test-Infra.ps1
./scripts/Test-Persistence.ps1
docker compose ps -a
docker compose down
```

Dentro de la persistencia: psql CREATE/INSERT de marcador aleatorio, restart postgres,
docker inspect del estado, comparación de snapshot, SELECT count(*) y DROP del marcador.
No ejecuta up durante recuperación. La guía incluye parámetros explícitos comunes y limpieza si falla.

## Commits y estado del PR

- aa1ae16: fix(seguridad), reconstruir ACL y conservar archivos.
- a801c88004a7943b96e0355fbaea11ff734c683e: fix(pruebas), selección Compose, entorno operativo y CI.
- El cierre posterior solo documenta resultados/evidencias; consultar git log a801c88..HEAD y el hash final
  de la respuesta de entrega. El CI citado arriba corresponde exactamente al código de a801c88.
- Rama feature/joseph-infra-postgresql; PR #1 debe permanecer OPEN/DRAFT.
- No se aprobaron revisiones ni se ejecutó merge. main no se modificó.

## No ejecutado, dependencias y tareas siguientes

**BLOQUEADO POR DEPENDENCIA / PENDIENTE, sin cambios de gate:**
- TDS: base, vista real dbo.vw_estado_facturacion, cuenta svc_pg_mssql_ro restringida, credencial privada,
  tipos/Unicode/decimal/offset y fixture coordinados con Joyce. No se inventaron datos o estados.
- Mongo FDW: autenticación limitada, ObjectId, Int64/Int32, Date, inserción/actualización, índice único y revisión.
- NOLOGIN y SET ROLE desde administrador no acreditan login propio ni permisos negativos.
- Ninguna consulta FDW remota, BSON/exportación, P01/P17 funcional o INT-01..05 está acreditada.
- El gate de conectores sigue abierto; no se inició DDL clínico/outbox/fixture ni módulos ajenos.
- No se contactó a Joyce/Armando en nombre de Joseph.

Siguientes tareas de Joseph: revisar disponibilidad de Docker Desktop con el usuario sin reinstalación ni
cambio de kernel automático; repetir manual con la selección elegida y guardar evidencia Windows cuando exista
daemon; coordinar por los canales del equipo el spike real con Joyce (sin enviar mensajes desde esta sesión);
mantener el PR en borrador para nueva auditoría. Persistencia ampliada y restauración requieren pruebas
separadas y no deben inferirse del restart actual.

Riesgos conservados: TLS PG/Mongo ausente, CA TDS sin validar, acceso del administrador a secretos,
kernel/digest Mongo por validar en Docker local y paquetes apt móviles. No se amplió exposición.
Toda aprobación o merge requiere una autorización posterior de Joseph.
