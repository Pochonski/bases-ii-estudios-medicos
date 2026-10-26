# Bitácora de progreso y trazabilidad

## 2026-10-21 — Inicialización documental

- **Responsable:** Joseph, con planificación asistida y revisión pendiente del equipo.
- **Alcance:** se documentaron requisitos del enunciado, decisiones de arquitectura y asignación, modelos, contratos, seguridad, plan, pruebas, fechas y guías de agentes.
- **Archivos:** README, AGENTS, docs/, agents/, referencia del curso (disponible localmente en el paquete original) y políticas Git.
- **Implementación:** NO realizada.
- **Pruebas de bases de datos/FDW:** NO ejecutadas.
- **Certeza:** solo documentación. Revisar pendientes en `docs/10_DECISIONES_Y_PENDIENTES.md`.

## Plantilla de entradas posteriores

```text
### AAAA-MM-DD HH:MM — [responsable] [actividad]
Objetivo:
Archivos creados/modificados:
Decisiones (IDs):
Comandos ejecutados:
Pruebas / resultado (o NO EJECUTADAS):
Evidencias:
Bloqueos y pendientes:
Dependencias para otros integrantes:
Commit o PR:
```

## 2026-10-21 — Preparación para repositorio público de GitHub

- **Destino:** `https://github.com/Pochonski/bases-ii-estudios-medicos` (creado vacío por el usuario, público).
- **Decisión D-024:** el repositorio público sustituye la propuesta de repo privado D-021.
- **Ajustes:** guías de agentes y planes publicados; referencia del enunciado original excluida del remoto público, referencias actualizadas.
- **Implementación de bases de datos:** NO realizada; **pruebas de bases de datos:** NO ejecutadas.
- **Verificación de contenido documental:** revisión de nombres de archivo, referencias y política de publicación, pendiente de verificación remota después del push.

## 2026-10-21 — Publicación del plan en GitHub

- Se preparó la publicación de los archivos de planificación y las guías individuales para los tres agentes en la rama `main` del repositorio público.
- No se incluyó el archivo del enunciado original ni contraseñas o datos médicos reales.
- Estado técnico inalterado: sin bases de datos implementadas ni pruebas ejecutadas.

## 2026-10-22 — Joseph, infraestructura y preparación PostgreSQL

- Objetivo: iniciar alcance autorizado de Joseph desde main 630cca6 en rama feature/joseph-infra-postgresql.
- Contexto leído completo: README, AGENTS, agents/JOSEPH, PROTOCOLO, docs/00..12, guías Joyce/Armando,
  handoff, CONTRIBUTING y evidencia. Dependencias identificadas antes de cambios.
- Cambios reales: Compose de tres motores, imagen personalizada con fuentes/checksums de dos FDW,
  configuración PG/HBA/FreeTDS, inicializador seguro, pruebas estáticas/runtime/persistencia, CI Ubuntu,
  preparación SQL de lectura, manual y documentación. No hay tablas clínicas ni objetos de Joyce/Armando.
- Decisiones: D-025..D-028; gate de conectores conserva pendiente la etapa clínica.
- Comandos: git clone/switch/status/show/diff, gh api (refs/perfil), docker --version/compose version/info/
  desktop start/buildx imagetools inspect/compose config/build; wsl --status; descargas oficiales en
  memoria con SHA-256; scripts Initialize-Local (dos veces) y Test-Infra -StaticOnly; parser PowerShell;
  git check-ignore y diff --check. Comandos de prueba exactos en manual/evidencia.
- Pruebas: estáticas PASAN; build local falla antes de compilar por named pipe ausente.
  P01 bloqueada por vista/base/cuenta de Joyce; P12/P14/P17/P18 no acreditadas localmente.
- Evidencia: evidencias/registros/2026-10-22-joseph-local.txt.
- Dependencias: Joyce confirma contrato SQL Server y valida BSON/escrituras Mongo FDW; Armando consume
  posteriormente, sin reasignaciones. No se enviaron mensajes en nombre de Joseph.
- Git/PR y resultados posteriores: se registrarán al terminar la verificación de esta misma sesión.

### Continuación — diagnóstico de CI (misma sesión)

PR en borrador #1: https://github.com/Pochonski/bases-ii-estudios-medicos/pull/1 .
Commits iniciales 4591a78 y bd4ce09; 4785086 agregó logs para diagnóstico.
Build de ambas extensiones PASÓ en Ubuntu; el init creó ambas extensiones y PG/SQL Server
estuvieron saludables. Las dos primeras ejecuciones FALLARON por aborto de MongoDB,
id 12257600 / SERVER-121912 (kernel no compatible).
Se registra D-029 y se cambia solo el runner a ubuntu-22.04, agregando uname -r.
Evidencia y cierre definitivo se registran en el informe final, sin atribuir éxito al Windows local.

## Cierre verificado — 22/10/2026, Joseph

[CI 39747806912](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/39747806912)
PASA en SHA 89d0754, Ubuntu22/kernel 6.8.0-1070-azure:
build de tds_fdw/mongo_fdw, tres motores saludables, consultas autenticadas, CREATE EXTENSION/LOAD
y persistencia PostgreSQL tras reinicio (P12 parcial). No prueba Windows, consultas FDW remotas,
BSON/escritura, P01, P14 ni el outbox.
Evidencia: evidencias/registros/2026-10-22-joseph-ci-exito.txt.
Informe de auditoría: documentacion/INFORME_CHATGPT_JOSEPH_FASE1.md.
PR #1 permanece en borrador; main conserva 630cca6.

## 2026-10-22 — Joseph, correcciones de auditoría PR #1

- Objetivo: H1 ACL, H2 selección Compose/restart y H3 .env operativo. Auditoría local leída íntegra.
- Inicio: árbol limpio; HEAD y remoto feature/joseph-infra-postgresql = 612d07d; main = 630cca6.
  No existía trabajo posterior. PR OPEN/DRAFT, sin aprobación ni merge.
- Cambios reales: reconstrucción DACL/owner y reparación de archivos existentes sin rotar secretos;
  helper/launcher Compose, validación ejemplo frente a operación, restart por inspect sin up y
  comparación de bindings/ID/volumen; regresiones temporales y CI base/localhost/ACL Windows.
- Decisiones: D-030..D-033, sin cambios al modelo/contratos clínicos.
- Comandos: git status/log/fetch/rev-parse/diff, gh pr view y gh run view 39753627026;
  docker info/context, Get-Service, wsl --status/--version; Parser.ParseFile; Test-Secrets,
  Test-ComposeValidation, Initialize-Local y Test-Infra -StaticOnly.
- Resultados Windows: H1 temporal e idempotencia PASAN; valores reales conservados al reparar;
  H2 selección estática explícita/ambiental y H3 negativo PASAN; siete scripts sin errores sintácticos.
- Fallo durante corrección: Set-Acl devolvió SeSecurityPrivilege; API FileSystemAclExtensions permitió
  persistir DACL/owner sin tocar SACL. Se conservan fallos históricos y límites.
- Windows motores: NO EJECUTADOS, named pipe ausente y servicio detenido. WSL instalado 2.7.10.0 /
  kernel informado 6.18.33.2-2; kernel efectivo Docker desconocido. Sin cambios de sistema o volúmenes.
- Evidencia: evidencias/registros/2026-10-22-joseph-auditoria-windows.txt. CI corregida aún pendiente.
- P01/P17/BSON y gate FDW siguen abiertos; NOLOGIN/SET ROLE no acreditan login o permiso negativo.
  No se contactó a compañeros ni se implementaron sus módulos. Cierre CI/commits se registrará después.

## Cierre de correcciones de auditoría — 22/10/2026, Joseph

CI [39759092391](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/39759092391)
PASA sobre head a801c88004a7943b96e0355fbaea11ff734c683e: ACL Windows Server2022 y dos variantes
Ubuntu22 (base/localhost). Lectura de secretos por UID y P12 parcial PASAN; en overlay se conserva
127.0.0.1:5432 junto con la fila, ID y volumen PG. Marcadores eliminados al pasar.
Artifacts depurados disponibles 14 días; evidencia versionada: evidencias/registros/2026-10-22-joseph-auditoria-ci.txt.
H1/H3 y selección estática probados también en Windows local; daemon sigue ausente.
No se acredita recreación, SQL Server/MongoDB persistentes, restauración, FDW remoto, BSON o login propio.
Informe: documentacion/INFORME_CORRECCIONES_AUDITORIA_PR1.md.
Commits correctivos aa1ae16/a801c88; cierre posterior solo documental. PR #1 en borrador, sin aprobación/merge.

## 2026-10-22 — Joseph, recuperación Docker Desktop y manual Windows

- Objetivo: resolver disponibilidad del motor Linux y ejecutar el manual local sin alterar
  WSL/kernel, protecciones, imágenes previas ni volúmenes. Contexto obligatorio y PR #1
  comprobados; inicio limpio en `fc7b305`, `main` en `630cca6`, PR OPEN/DRAFT.
- Diagnóstico: Docker Desktop 4.91.0 abortaba al renombrar el socket de Ingest (`error 1920`).
  Reinicio por CLI no progresó. Se cerró Desktop y se conservaron por renombrado sus carpetas
  transitorias de sockets `Docker/run` y `docker-secrets-engine`; inicio normal posterior
  expuso Engine 29.8.0 y kernel `6.18.33.2-microsoft-standard-WSL2`. No se concluyó causa
  raíz de los sockets ni estabilidad tras otro reinicio de Desktop/Windows.
- Implementación D-034: el primer `compose.local.yaml` no activaba puertos con los motores
  solo en red interna. Se agregó pasarela TCP sin secretos y sondas de puerto activo, conservando
  red interna para los tres motores. La selección base equivocada ahora falla en runtime.
- Archivos: overlay, configuración HAProxy, helper/test Compose, workflow, guía, decisiones,
  matriz, estado, este registro e informe/evidencia Windows. No se tocaron módulos Joyce/Armando.
- Comandos: `docker info/context/ps/network inspect/stats`, `docker desktop restart/stop`,
  `Start-Process Docker Desktop`, `docker buildx imagetools inspect`, inicializador,
  regresiones H1–H3, `Test-Infra -StaticOnly`, `Invoke-Compose build/up/ps`,
  `Test-Infra`, `Test-Persistence`, clientes Windows `psql`/`sqlcmd`, parser PowerShell y Git.
- Pruebas: build/health/consultas autenticadas/lectura secretos/puertos activos/clientes
  Windows PASAN. P12 PASA solo para una fila PG tras `restart`, marcador eliminado. Docker
  publicó puertos por gateway. El primer overlay sin gateway FALLÓ publicación efectiva,
  aunque la configuración estática pasó. Detalles: evidencia Windows de esta fecha.
- Riesgos y pendientes: sockets antiguos retenidos fuera del repo; puerto 5432 ocupado por
  otro proceso, se usaron puertos alternativos desde archivo temporal ignorado; no se probó
  reinicio completo de Desktop ni restauración; FDW/BSON/cuentas Joyce y gate siguen abiertos.
  CI del nuevo código por ejecutar y documentar; PR permanece en borrador.

### Verificación CI y cierre documental

Run 39806854571 PASÓ para diseño gateway en 9b22c98. Se precisaron dos mensajes de salida
(host genérico y modo base sin gateway) en 0b5e507; Windows repitió P12 parcial.
Run [39807402214](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/39807402214)
PASÓ en head 0b5e507: tres jobs y artifacts revisados. Ubuntu base sin puertos;
Ubuntu localhost con gateway, TCP host y P12 parcial; Windows Server ACL.
Evidencia durable: `evidencias/registros/2026-10-22-joseph-gateway-ci.txt`.
El cierre documental posterior no modifica código probado. PR #1 sigue OPEN/DRAFT.

## 2026-10-22 — Joseph, observaciones menores de infraestructura PR #1

- **Objetivo:** filtrar cambios de `docker/port-gateway/**` y rechazar un backend
  HAProxy indisponible, manteniendo solo puertos host en 127.0.0.1.
- **Contexto y rama:** README, AGENTS, `agents/JOSEPH.md`, protocolo, docs obligatorios,
  seguridad, pruebas y guía; `feature/joseph-infra-postgresql` limpio en `a521ee2` al inicio,
  PR #1 OPEN/DRAFT, `main` en `630cca6`.
- **Cambio real:** filtro de workflow; `/ready` interno HAProxy dependiente de tres backends;
  healthcheck del gateway; test de stop/start protegido para CI efímera. Decisión D-035.
- **Archivos:** workflow, overlay, HAProxy, nuevo test, guía, arquitectura, seguridad,
  matriz, estado, decisiones, esta bitácora e informe/evidencia por cerrar.
- **Comandos ejecutados:** `git status/log/diff/commit/push`, `gh pr view`, `docker info/ps/
  inspect/exec`, `docker compose config` vía Test-Infra, `haproxy -c`, `wget /ready`,
  `Invoke-Compose restart/up --no-deps --force-recreate --wait port-gateway`,
  `Test-Infra -StaticOnly` y runtime, parser PowerShell y `git diff --check`.
- **Resultados Windows 11:** Docker Engine 29.8.0/WSL2 kernel 6.18.33.2 disponible;
  sintaxis y configuración PASS; `/ready` 200 y healthcheck Docker saludable;
  tres consultas autenticadas y lectura de secretos por UID PASS. Solo se recreó el
  gateway; IDs de los tres motores permanecieron estables. Bindings efectivos:
  127.0.0.1:11433/15432/37017, sin 8404. No se pausó el proyecto local.
- **P12 local:** `Test-Persistence.ps1` PASS parcial con una fila sintética tras `restart`
  de PostgreSQL; mismo contenedor/gateway/volumen/bindings; marcador eliminado.
- **Disponibilidad posterior del host:** al cerrar la evidencia, `docker info` volvió a
  fallar por named pipe `dockerDesktopLinuxEngine` ausente; `docker desktop status`
  no pudo leer estado y `com.docker.service` estaba Stopped. Se conserva como riesgo
  de estabilidad local; no se cambió Docker/WSL/volúmenes para ocultarlo.
- **CI y evidencia:** commit de código `5d73d9e`; ejecución negativa, artifacts y run
  39811585204 FALLÓ: con `pause`, el socket TCP de PG siguió abierto y HAProxy continuó
  saludable. El `finally` ejecutó `unpause`; base y ACL PASARON; P12 localhost no se ejecutó.
  `ee5ce97` cambió solo el estímulo a `stop/start` para cerrar el listener. La CI
  [39812197292](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/39812197292)
  PASÓ: tres jobs y artifacts descargados. El negativo y la recuperación PASARON;
  P12 parcial siguió PASS en base/localhost. Extractos durables en
  `evidencias/registros/2026-10-22-joseph-gateway-backend-ci.txt`.
- **Riesgos/dependencias:** la caída del backend causa indisponibilidad breve en el
  proyecto de prueba; no hay datos ni volúmenes borrados. P12 sigue parcial. FDW remoto,
  BSON y cuentas/objetos de Joyce siguen bloqueados; no se contactó a compañeros.
- **Siguiente:** repetir CI con stop/start, registrar evidencia y mantener PR en borrador sin aprobación/merge.

## 2026-10-22 — Joseph, fase 2 PostgreSQL independiente

- **Objetivo y autorización:** adelantar exclusivamente 12 tablas PostgreSQL, LIST SJ/AL/CA,
  fixture ficticio y pruebas, aislados del gate FDW y de los módulos Joyce/Armando.
- **Punto de partida:** `feature/joseph-infra-postgresql` limpio en `20e9fe6`;
  `feature/joseph-postgresql-core` creada desde ese commit. PR #2 en borrador,
  base en rama de infraestructura; `main` no modificado.
- **Archivos:** `postgresql/01_esquemas.sql`, `02_tablas.sql`, `03_particiones.sql`,
  `06_datos_prueba.sql`; cinco pruebas SQL; `scripts/Test-PostgresqlCore.ps1`;
  workflow separado; README, docs 00/03/06/07/10/11, guía, informe y evidencia.
- **Comandos:** `git status/log/branch/add/commit/push/diff --check`, `gh pr create/view`,
  `gh run list/view/download`, parser PowerShell, `docker info`. CI ejecuta
  `Initialize-Local`, validación Compose, `docker compose build/up` solo PG,
  `Test-PostgresqlCore -Repeat 2 -IncludePersistence`, `docker compose down` sin `-v`.
- **Resultado inicial CI:** [39878097819](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/39878097819)
  SUCCESS en código `295bf32`: dos bases vacías, 12 tablas, fixture exacto,
  inserciones y rechazos, P14 tableoid/EXPLAIN, COMMIT/ROLLBACK locales y
  persistencia clínica tras restart del mismo PG. Ambas bases sintéticas eliminadas.
  [Regresión 39878319168](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/39878319168)
  sobre `502f5fa` PASÓ: marcadores explícitos en artifact, PG servidor 16.15,
  mismo resultado funcional en dos bases vacías y dos restart. Ver extracto en
  `evidencias/registros/2026-10-22-joseph-postgresql-core-ci.txt`.
  La regresión heredada de infraestructura
  [39878319636](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/39878319636)
  PASÓ en el mismo head: ACL Windows Server y Ubuntu base/localhost, artifacts revisados.
- **Windows local:** `docker info` falló por named pipe `dockerDesktopLinuxEngine` ausente.
  `Test-Infra -StaticOnly` PASÓ con `.env` operativo/Compose base; sintaxis PowerShell
  0 errores y `git diff --check` limpio. SQL/restart NO EJECUTADOS
  localmente. Sin cambiar WSL/Docker ni eliminar volúmenes.
- **Riesgos/dependencias:** esquema `clinico`/`integracion` requiere revisión Joyce
  antes de worker; falta vista/base/cuenta/fixture SQL Server, validación Mongo FDW
  de autenticación/BSON/escritura/índice/revisión y gate de conectores. Outbox solo
  local, sin exportación. P12 parcial; P18 completo pendiente.
- **Siguiente:** repetir en Windows cuando el daemon responda, solicitar revisión
  técnica de interfaz en PR #2 y mantener ambos PR en borrador sin merge/aprobación.

## 2026-10-23 — Joseph, consolidación del núcleo hacia main

- **Objetivo:** preparar un PR nuevo y aislado del núcleo clínico sobre `main`,
  corregir su filtro CI y revisar el outbox sin alterar contratos compartidos.
- **Estado inicial comprobado:** árbol local limpio en `feature/joseph-postgresql-core`;
  `main=0a42732` con PR #1 fusionado, rama de infraestructura `84cb072` con PR #2
  fusionado. Diff exacto de 21 archivos clínicos/documentales; núcleo ausente de
  `main`. PR #1/#2 consultados en GitHub, ambos MERGED.
- **Estrategia y archivos:** rama `feature/joseph-core-main-integration` desde
  `origin/main`; cherry-pick limpio de `0f3614a`→`344bb5b`, `295bf32`→`f93c0fb`,
  `502f5fa`→`8322310`, `41c98b4`→`29bb20c`. El árbol resultante coincidió con
  `origin/feature/joseph-infra-postgresql`; después solo se cambió workflow y
  documentación de estado, pruebas, decisiones, guía, informe/evidencia. No se
  tocaron Compose, DDL, fixture, SQL Server, MongoDB ni módulos de Armando.
- **Comandos:** `git status/fetch/ls-remote/diff/log/switch/cherry-pick/add/commit/push`,
  `gh pr view/create`, `gh run list/view`, `docker info/version/ps/image inspect`,
  `Test-Infra -StaticOnly`, `Invoke-Compose up/down` y
  `Test-PostgresqlCore -Repeat 2 -IncludePersistence` en proyecto aislado.
- **Windows local:** Engine 29.8.0/WSL2 kernel 6.18.33.2, PG 16.15; dos instalaciones
  y restart de PG PASAN. Proyecto de prueba sin puertos, red/volumen propios; dos
  bases sintéticas eliminadas, contenedores de prueba retirados, volumen conservado.
  IDs de los cuatro contenedores compartidos no cambiaron.
- **CI:** PR #3 abierto en borrador. Primer run núcleo
  [40028582907](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40028582907)
  FALLÓ en el negativo SQL esperado: Compose/psql devolvieron error y el shell
  conservó `LASTEXITCODE=1` pese a la captura. Commit `ae3f1b9` limpia solo ese
  código tras verificar el error. La primera regresión de infraestructura
  [40028582691](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40028582691)
  PASÓ tres jobs. En `ae3f1b9`, la [CI corregida del núcleo](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40028827502)
  PASÓ instalación doble, tests SQL, dos restart y negativo controlado; la
  [regresión de infraestructura](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40028827437)
  PASÓ los tres jobs, incluidos Windows ACL y gateway localhost. Artifacts
  descargados y contrastados: head `ae3f1b9`, checkout `a5f4175`, PostgreSQL
  16.15, Docker 28.0.4, Compose 2.38.2, kernel Ubuntu `6.8.0-1064-azure`.
- **Outbox (D-038):** UUID único no impide duplicado lógico; revisión de evento no
  ligada a resultado; escritura directa puede omitir evento. Alternativas concretas
  documentadas para Joyce, sin implementar worker, trigger ni cambios de DDL.
- **Riesgos/dependencias:** FDW remoto, BSON, cuenta propia y exportación pendientes;
  P12 solo restart PG. Ningún PR aprobado/fusionado en esta sesión; `main` intacto.
- **Siguiente:** verificar la CI del commit documental final y entregar informe
  para auditoría. Solicitar revisión de Joyce antes de integrar el outbox.
- **Refuerzo CI posterior (23/10):** `bd3124b` registró guía/informe/evidencia; su
  [CI de núcleo](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40029279031)
  y [CI de infraestructura](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40029278993)
  PASARON cuatro checks, head `bd3124b`, checkout `8381f9c`. Para acreditar mejor
  la propagación SQL, `6e9d1bb` sustituyó la captura interna por un paso que
  falla de verdad y otro que exige `outcome=failure`; solo el negativo lleva
  `continue-on-error`. [Núcleo 40029751371](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40029751371)
  PASÓ con artifact `sql-error.txt` y pruebas clínicas posteriores. Las pruebas
  locales Windows no se repitieron porque DDL, fixture y runner no cambiaron.
  Infraestructura [40029751368](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40029751368)
  PASÓ los tres jobs del mismo head.

## 2026-10-24 — Joseph, fase 4 tds_fdw autónoma

- **Objetivo:** ejecutar lectura real PostgreSQL → SQL Server antes de recibir la
  vista y cuenta finales de Joyce; conservar PR #3 intacto y abrir PR #4 apilado.
- **Estado inicial:** `main=0a42732`, PR #1/#2 MERGED, PR #3 OPEN/DRAFT en
  `f46dd9b`; árbol local limpio. No hay módulos `sqlserver/` ni `mongodb/` de
  Joyce ni PR abiertos de ella. Rama nueva `feature/joseph-tds-fdw-spike` desde
  `origin/feature/joseph-core-main-integration`, sin cambiar `main`.
- **Archivos y razón:** runner `scripts/Test-TdsFdwSpike.ps1`, workflow
  `.github/workflows/joseph-tds-fdw-spike.yml`, fixtures/scripts solo en
  `pruebas/integracion/` y guía `documentacion/JOSEPH_FASE4_TDS_FDW.md`.
  Cambio documental registrado aquí y en D-039: explica el límite del spike,
  pruebas y dependencias sin alterar contratos compartidos.
- **Comandos y evidencia inicial:** `git fetch/status/diff`, `gh pr view/list`,
  `docker info`, `docker context show`, `wsl --status`, `Get-Service`,
  `pwsh -File scripts/Test-TdsFdwSpike.ps1 -StaticOnly`, `git diff --check`,
  `git commit/push`, `gh pr create`. Estático Windows PASÓ; runtime Windows
  NO EJECUTADO: `com.docker.service` detenido y pipe
  `dockerDesktopLinuxEngine` ausente. No se tocó WSL, Desktop ni volúmenes.
- **Commit inicial:** `e57de54` con runner, scripts de prueba y workflow.
  [PR #4](https://github.com/Pochonski/bases-ii-estudios-medicos/pull/4)
  OPEN/DRAFT dirigido a la rama del PR #3. CI inicial en curso al redactar esta
  entrada; resultado y SHA finales se añaden tras revisión de artifacts.
- **Dependencias/siguiente:** Joyce debe proveer base, vista, cuenta limitada,
  tipos/fixture y agregación acordada; Mongo FDW/BSON sigue separado. Ejecutar
  y depurar CI, repetir manual Windows cuando haya daemon, mantener ambos PR en
  borrador y solicitar revisión de contratos antes de integración definitiva.
- **Fallo real de la primera CI:** [40102260838](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40102260838)
  FALLÓ en `e57de54`: cuatro filas reales vía login FDW y permisos negativos
  SQL Server pasaron, pero `1002/AL` pareció existir. El runner limpió las dos
  bases, login, contenedores, red y volúmenes temporales. Diagnóstico en
  `581b7f5`, [40102446960](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40102446960):
  listado remoto = `1001/AL, 2001/SJ, 3001/CA, 5000000000/AL`; la consulta
  `WHERE 1002/AL` devolvió **count=4** y `EXPLAIN` no incluyó filtro ni WHERE
  remoto. Ambas CI rojas detectaron un bug real, no se contabilizan como PASS.
- **Corrección D-040:** commit `1c0367e` añade parche local al build de
  `tds_fdw` fijado, y aserciones de filtro/orden/LEFT JOIN. Se validó que el
  parche aplica al archivo fuente del commit upstream; la compilación y la
  regresión CI del nuevo SHA siguen en verificación al registrar esta línea.
- **CI con parche:** [40102791877](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40102791877)
  en `1c0367e` FALLÓ al clasificar textualmente el error de desconexión, pero
  compiló el parche y pasó cuatro filas, Unicode, BIGINT, DECIMAL, UTC, filtro,
  orden y JOIN. `EXPLAIN` mostró `Filter` local; el SQL Server detenido produjo
  código no cero mientras PG local respondió. `e514ee7` exige ese código y
  elimina solo el filtro de palabras del mensaje. La [CI 40103007250](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40103007250)
  PASÓ dos jobs en ese head: consulta real, negativos, caída/recuperación y
  limpieza, más estático Windows Server. Artifacts descargados/revisados:
  `evidencias/registros/2026-10-24-joseph-tds-fdw-ci.txt`.
- **Infraestructura:** [40103007202](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40103007202)
  PASÓ tres jobs en `e514ee7`: ACL Windows y Ubuntu base/localhost. Los cambios
  posteriores de instrumentación/documentación requieren verificar nueva CI.
- **Cierre propuesto:** se agregan versiones efectivas PostgreSQL, SQL Server y
  FreeTDS a la salida depurada, verificación de ausencia de contenedores/
  volúmenes tras limpieza y filtros CI para documentos de esta fase. La guía,
  matriz, seguridad, decisiones, informe y evidencia se actualizan por el
  hallazgo D-040; no se cambia `integracion/01_fdw_sqlserver.sql` ni contrato
  del outbox. El commit final y su CI se contrastarán antes del informe externo.
- **CI de instrumentación:** [40103357010](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40103357010)
  en `f3b6327` quedó ROJA pese a completar consulta, seguridad, caída,
  recuperación y limpieza; `docker volume inspect` devolvió 1 al confirmar
  ausencia de volúmenes, y PowerShell conservó ese código al salir. La nueva
  corrección limpia solo el código esperado después de comprobar ausencia y
  hace **fallar** el job si la limpieza realmente queda incompleta. Se repite
  CI en el siguiente commit; no se declara verde este run.
- **Cierre funcional:** commit `8f25634` y [CI FDW 40103545333](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40103545333)
  SUCCESS: cuatro filas remotas, tipos/Unicode/offsets, WHERE/ORDER/JOIN,
  permisos negativos, caída y recuperación, ausencia de contenedores y
  volúmenes efímeros. Artifact descargado, head y checkout verificados,
  versiones en `evidencias/registros/2026-10-24-joseph-tds-fdw-ci.txt`.
  [Infraestructura 40103545352](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40103545352)
  SUCCESS tres jobs del mismo head. Windows local siguió sin daemon; no hubo
  consulta FDW local. Esta actualización documental registra fecha, responsable,
  motivo y efecto; no cambia contratos. Verificar CI del commit documental
  posterior por separado.

## 2026-10-25 — Joyce, SQL Server, MongoDB, mongo_fdw y outbox

- **Responsable:** Joyce (con agente). **Rama:** `feature/joyce-sqlserver-mongodb`. Decisión D-041.
- **Motivación:** cumplir el alcance de `agents/JOYCE.md` y desbloquear P01/P17 de Joseph y el
  handoff a Armando.
- **Entorno:** Windows 11, Docker Desktop actualizado a Engine 29.9.2 (la actualización automática
  quedó colgada y hubo que abrir Docker Desktop a mano), kernel WSL 6.6.87.2, PowerShell 7.6 instalado.
- **Comandos:** `pwsh -NoProfile -File ./scripts/Install-JoyceModulos.ps1` y
  `pwsh -NoProfile -File ./scripts/Test-JoyceModulos.ps1 -EvidencePath evidencias/registros/2026-10-25-joyce-pruebas-local.txt`.
- **Resultado:** primera ejecución FALLÓ en P05 (`invalid transaction termination` por `SET` en el
  procedimiento); corregido. Luego tres ejecuciones seguidas PASAN completas: P15, P16, permisos
  `svc_pg_mssql_ro`, P01, P16b, P13, P04, P05, P06, P07, permisos `usr_fdw_pg_mongo`, P08 e INT-04.
- **Impacto:** contrato `dbo.vw_estado_facturacion` cumplido sin cambios; dos objetos añadidos al
  núcleo de Joseph pendientes de su revisión (D-041). No se tocaron módulos de Armando.
- **No ejecutado:** CI, P17 formal de Joseph sobre estos objetos, TLS.

## 2026-10-25 — Joyce, módulos de Armando (con su permiso)

- **Responsable:** Joyce (con agente). Decisión D-042. Misma rama `feature/joyce-sqlserver-mongodb`.
- **Archivos:** `postgresql/04_roles_externos.sql`, `postgresql/05_vistas_api.sql`,
  `mongodb/04_agregaciones.js`, `mongodb/05_validaciones.js`, `pruebas/seguridad/*`;
  instalador y pruebas ampliados; dos secretos nuevos en `secrets/` (ignorada).
- **Resultado:** suite completa PASA (49 marcas PASS, incluye P02, P03, P09, P10, P11).
- **Impacto:** la base ya no admite CONNECT de roles ajenos a los cuatro perfiles (el superusuario
  no se ve afectado). Armando debe confirmar y revisar.

## 2026-10-25 — Joyce, verificación de entrega y material del video (D-043)

- `Test-Entrega.ps1 -DesdeCero`: borró los volúmenes del proyecto local, reinstaló y PASÓ P18, la suite
  completa, P12 en tres motores y P17. Demo de 9 segmentos ejecutada completa.
- Nuevos: mapa de conexiones y configuración, referencias, guion del video, inicio rápido en README.
- No ejecutado: CI, grabación del video, entrega en Moodle.

## 2026-10-25 — Joyce asume el alcance de Armando y agrega CI (D-044)

- PR #5 abierto en borrador (base `feature/joseph-tds-fdw-spike`). CI de infraestructura de Joseph
  PASÓ en sus tres jobs con los cambios de Joyce (run 40273876990).
- `pruebas/reportes/` creada; P09 la usa. Suite local repetida: PASA.
- Workflow `joyce-modulos.yml` agregado; su resultado se registra al terminar.

## 2026-10-25 — Joyce, verificación de completitud

- CI `joyce-modulos.yml` [40274339076](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40274339076)
  PASÓ en `2ab0832` (Ubuntu 22.04, kernel 6.8.0-1064-azure, Docker 28.0.4): P18, suite completa, P12, P17;
  artifact descargado y revisado. CI de infraestructura de Joseph también PASÓ (3 jobs).
- Pruebas de Joseph (estructura, integridad, P14) agregadas a `Test-Entrega.ps1` justo tras la instalación
  desde cero: PASAN. Ejecutadas después de la suite fallaba solo el conteo del fixture porque la suite agrega
  resultados sintéticos (precondición de esa prueba, no defecto).
- `documentacion/CUMPLIMIENTO_REQUISITOS.md`: todos los requisitos técnicos ✅; pendientes del grupo:
  merges #3→#4→#5, video, confirmar fecha y subir a Moodle.
