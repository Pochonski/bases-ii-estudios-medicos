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
