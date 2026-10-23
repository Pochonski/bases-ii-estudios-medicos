# Registro de decisiones (ADR abreviado), supuestos y riesgos

**Fecha del registro inicial:** 21/10/2026. Cada decisión distingue aprobación real del grupo, mandato docente o propuesta técnica. No actualizar su estado sin justificación y comunicación.

| ID | Decisión / hipótesis | Estado | Motivo y consecuencias |
|---|---|---|---|
| D-001 | Usar tres motores PostgreSQL, SQL Server y MongoDB | **[CURSO]** | Rol complementario de cada motor |
| D-002 | No desarrollar web ni móvil; preparar roles/vistas | **[CURSO]** | Alcance académico |
| D-003 | Ejecutar tres motores en **una PC** | **[GRUPO]** | Trabajo centralizado; aceptación por docente pendiente si interpreta distribución física |
| D-004 | Windows 11, Ryzen 5 5600G, 16 GB, GPU RTX 5060 | **[GRUPO]** | Host disponible; falta prueba del entorno |
| D-005 | Docker Desktop + WSL 2, red privada y volúmenes | **[PROPUESTA ACEPTADA COMO PLAN]** | Servidores aislados lógicamente |
| D-006 | Tres regiones SJ/AL/CA y pacientes ficticios | **[PROPUESTA]** | Ejemplos alineados al curso |
| D-007 | PostgreSQL fuente clínica; SQL Server fuente externa; MongoDB analítica | **[CURSO]** | Evita doble autoridad de datos |
| D-008 | Modelo PostgreSQL de 12 tablas incluido outbox | **[PROPUESTA]** | Satisface casos y habilita recuperación |
| D-009 | PK paciente `(id_paciente,codigo_region)` y particiones LIST | **[PROPUESTA]** | Restricción PG por clave de partición |
| D-010 | Fragmentar entidad paciente asegurado por columnas en SQL Server | **[PROPUESTA]** | Reconstruible mediante JOIN de fragmentos |
| D-011 | `tds_fdw` solo lectura a `dbo.vw_estado_facturacion` | **[PROPUESTA; probar]** | Vista devuelve una fila por paciente-región |
| D-012 | `mongo_fdw` prioridad; alternativa intermedia condicional | **[PROPUESTA CON RIESGO DOCENTE]** | Dos apartados del enunciado no coinciden |
| D-013 | Confirmación PG → outbox → exportación MongoDB | **[PROPUESTA]** | Consistencia eventual y reintentos |
| D-014 | Único resumen por `id_estudio`, índice UNIQUE, `revision` | **[PROPUESTA]** | Idempotencia / no regresión de versión |
| D-015 | IDs tipo BIGINT/Int64 y fechas UTC; colones CRC | **[PROPUESTA]** | Contrato intermotor |
| D-016 | PostgreSQL 16 / SQL Server 2022 Developer / MongoDB 8 | **[PRESELECCIÓN; no validada]** | Congelar únicamente después del spike de FDW |
| D-017 | Roles internos y externos con cuatro nombres del enunciado | **[CURSO]** | Permisos mínimos concretados en doc de seguridad |
| D-018 | Joseph y Joyce más trabajo; Armando al final | **[GRUPO]** | Armando no debe bloquear etapas iniciales |
| D-019 | Reparto orientativo 43%/40%/17% | **[PROPUESTA ORGANIZATIVA]** | No medición ni calificación |
| D-020 | Traspaso 25/10, Armando comienza 26/10 | **[PROPUESTA ORGANIZATIVA]** | Congelar interfaces y trabajar con base estable |
| D-021 | Git y repositorio remoto **privado** (propuesta anterior) | **[SUPERADA POR D-024]** | Se sugirió privacidad antes de que el grupo creara el repositorio público |
| D-022 | Documentar antes de dividir/implementar | **[GRUPO]** | Evitar divergencia entre agentes |
| D-023 | No presentar outbox como ACID distribuido | **[CRITERIO TÉCNICO]** | Solo COMMIT local + consistencia eventual |
| D-024 | Repositorio público en `Pochonski/bases-ii-estudios-medicos` | **[GRUPO; 21/10/2026]** | Sustituye D-021. No publicar secretos, datos reales ni enunciado docente original; documentación y guías para agentes sí. |

## Pendientes prioritarios (en orden)

1. **[P0]** Confirmar Moodle: ¿cierre 28/10/2026 23:59? El enunciado lo llama martes y la fecha es miércoles.
2. **[P0]** Aclarar con docente si una PC con tres contenedores satisface «distribuido», si el grupo de 3 es aceptado ante la redacción «grupos de 4 personas» y, especialmente, si una integración intermedia a MongoDB es aceptable cuando `mongo_fdw` falla.
3. **[P0]** Verificar virtualización, espacio SSD, WSL2 y Docker en PC real.
4. **[P0]** Validar compilación y consultas reales `tds_fdw` con versiones elegidas.
5. **[P0]** Validar `mongo_fdw` incluyendo inserción, actualización, `_id`, tipos BSON e índice único; confirmar matriz de versiones con MongoDB.
6. **[P1]** Fijar DDL exacto de tablas SQL Server, estrategia de evento/idempotencia y tipo final de worker sin sobrepasar requisitos.
7. **[P1]** Decidir rol técnico específico para procesador outbox y manejo seguro de credenciales.
8. **[P1]** Confirmar nombres de usuario GitHub de Joyce y Armando, colaboradores y ramas de trabajo.
9. **[P1]** Conseguir evidencia real P01–P18, preparar manual y video.

## Riesgos

| Riesgo | Impacto | Mitigación |
|---|---|---|
| `mongo_fdw` incompatible / dependencias | Alto | Spike temprano; registrar error y pedir alternativa al docente |
| `tds_fdw` falla en imagen PG | Alto | Validar FreeTDS/bibliotecas y servicio remoto antes del esquema |
| Host consume demasiada RAM | Medio/alto | Limitar cargas, revisar WSL2, ajustar recursos, usar dataset pequeño |
| Datos no coinciden entre motores | Alto | Dataset compartido y contratos únicos de IDs |
| Cambios de esquema tras traspaso | Alto | Congelación y revisión de cambios el 25 |
| SQL Server down rompe vista | Medio | Prueba del fallo, explicar indisponibilidad, no inventar datos |
| Worker duplica documentos | Alto | UNIQUE, revisión, idempotencia y P07/P08 |
| Pérdida de equipo o volúmenes | Alto | Commits remotos + respaldos exportables |
| Entrega tarde / video omitido | Alto | Material listo 27/10, validación Moodle |

## Registro de nuevas decisiones

Agregar filas `D-024` y siguientes con **fecha**, **proponente**, **fuente** (curso/grupo/propuesta), **estado**, **consecuencias**, **archivos afectados** y **evidencia** si ya se probó. No borrar decisiones anteriores: marcarlas supersedidas y enlazar reemplazo.

### D-025 — Inicio limitado a Joseph (21–22/10/2026)

- Proponente/fuente: autorización explícita de Joseph en esta sesión.
- Estado: IMPLEMENTACIÓN AUTORIZADA solo para infraestructura/PostgreSQL/lectura SQL Server de Joseph.
- Impacto: rama feature/joseph-infra-postgresql, PR en borrador; sin merge ni módulos de Joyce/Armando.
- Archivos: README, docs de estado/bitácora y entregables de Joseph.

### D-026 — Respetar spike previo al esquema (22/10/2026)

- Proponente: Joseph mediante agente; fuente: gate 2 de docs/06.
- Estado: ejecutado como orden de trabajo; DDL clínico permanece PENDIENTE.
- Motivo: Docker Linux no expone su named pipe incluso tras intentar iniciar Desktop.
- Impacto: entregar archivos y pruebas de infraestructura, investigar conectores, preparar CI Ubuntu;
  no declarar compilación, FDW real ni Windows funcional sin evidencia.

### D-027 — Candidatos inmutables para el spike (22/10/2026)

- Proponente: Joseph mediante agente; fuente: repositorios y manifiestos oficiales.
- Estado: PROPUESTA TÉCNICA verificable por artefactos; compatibilidad funcional SIN APROBAR.
- Elección: PG 16.15/bookworm, SQL Server 2022 Developer y MongoDB 8.0.34-noble por digest amd64;
  tds_fdw 2.0.5, mongo_fdw 5.5.3, driver C 1.30.2, json-c 0.18.
- Motivo: respetar preselección y release mongo_fdw que declara MongoDB 8; evitar master/latest flotantes.
- Archivos: compose.yaml, docker/postgres/Dockerfile, documentacion/COMPATIBILIDAD_FDW.md.
- Evidencia: manifiestos consultados, commits oficiales y cuatro SHA-256 calculados desde descargas;
  apt no está inmovilizado por snapshot. Fijación definitiva pendiente de pruebas con Joyce.

### D-028 — Secretos por archivo y límites de seguridad (22/10/2026)

- Proponente: Joseph mediante agente; fuente: mínimo privilegio de docs/05 y Compose secrets.
- Estado: IMPLEMENTADO; validación estática y generación/idempotencia probadas en Windows.
- Motivo: .env sin contraseñas, secretos fuera del contexto build/Git y solo en su motor.
- Impacto: scripts/Initialize-Local.ps1, .env.example, .gitignore, .dockerignore, configuración PG/FreeTDS;
  pruebas y manual. Sin cambios de columnas o IDs compartidos.
- Límites: red interna; TLS TDS sin CA, sin TLS PG/Mongo, cuentas remotas de Joyce pendientes.
  Perfil FDW PostgreSQL preparado NOLOGIN; no declarar roles plenamente implementados.

### D-029 — Kernel del entorno de prueba MongoDB (22/10/2026)

- Proponente: Joseph mediante agente; fuente: error real de MongoDB y documentación oficial.
- Estado: PROBADO EN CI: runner Ubuntu22, kernel real 6.8.0-1070-azure; run 39747806912 PASA.
- Evidencia: runs 39744770706 y 39747121313 compilaron ambos FDW; PG/SQL Server saludables,
  MongoDB abortó con id 12257600 por kernel 6.19 o posterior.
- Decisión: probar el mismo candidato en runner ubuntu-22.04 (kernel 6.8 según runner-images);
  registrar uname -r. No bajar la versión de MongoDB ni desactivar su protección.
- Impacto: .github/workflows/joseph-infra.yml, manual, compatibilidad y evidencia.
  Sin modificaciones al kernel Windows/WSL ni a contratos compartidos.
- Fuentes: https://jira.mongodb.org/browse/SERVER-121912 y
  https://www.mongodb.com/docs/v8.0/release-notes/8.0/ .

### D-030 — Corregir DACL de secretos (22/10/2026, Joseph; auditoría H1)

- Fuente: reproducción de auditoría y autorización explícita para corregir PR #1.
- Decisión: reconstruir DACL completa, proteger herencia y propietario actual; solo usuario/SYSTEM
  en carpeta y todos los archivos normales existentes. Valores conservados. Corrige la garantía de D-028.
- Archivos: Initialize-Local.ps1, Test-Secrets.ps1, docs/05 y guía.
- Evidencia Windows: regresión con Everyone/Users explícitos y archivos preexistentes PASA;
  DACL/propietario verificados, sin impersonación. API .NET evita el fallo local SeSecurityPrivilege.
- Linux conserva directorio 700/archivos 644; lectura por UID SQL Server y demás motores PASA en CI 39759092391.

### D-031 — Selección Compose compartida y restart sin reconciliar (22/10/2026, Joseph; H2)

- Decisión: ComposeFile/EnvFile/ProjectName/ProjectDirectory comunes a operación y pruebas;
  respetar selección nativa COMPOSE_* si no hay parámetros. Ejemplos usan selección explícita aislada.
- Persistencia espera inspect del contenedor original; no ejecuta up. Verifica ID/bindings/volumen
  y fila sintética PG; limpia al pasar y documenta limpieza del marcador si falla.
- Alcance P12 permanece parcial: restart PG, no tres motores/recreación/restauración.
- Archivos: Compose-Context.ps1, Invoke-Compose.ps1, Test-Infra/Test-Persistence, regresiones y CI.
- Resultado: selección local estática PASA; runtime base/overlay PASA en CI 39759092391. Windows sin daemon.

### D-032 — Validación separada del entorno operativo (22/10/2026, Joseph; H3)

- Decisión: conservar ejemplo base/localhost y añadir config efectiva operativa con fases PASS/FAIL distintas.
- Prueba negativa en proyecto temporal con ejemplo válido y .env operativo POSTGRES_DB vacío.
- Resultado: rechazo operativo reproducido y corregido; .env real no se escribe y se verifica intacto.
- Impacto: Test-Infra y Test-ComposeValidation; sin cambios de contrato o datos.

### D-033 — Evidencia por plataforma y selección (22/10/2026, Joseph)

- CI añade ACL Windows Server2022 y matriz Ubuntu22 base/localhost con lectura de secretos por UID
  y persistencia PG acotada; secretos efímeros enmascarados, artifacts depurados con retención 14 días.
- CI del head auditado 612d07d PASA (39753627026); código corregido a801c88 PASA en 39759092391, tres jobs y artifacts revisados.
- Windows local: daemon ausente, servicio detenido; sin reinstalación ni cambios WSL/kernel/volúmenes.
- FDW remoto, BSON, login propio/privilegios negativos e INT siguen pendientes de Joyce/gates.

### D-034 — Pasarela localhost y validación del puerto activo (22/10/2026, Joseph)

- Fuente/motivación: autorización de continuar el manual local; reproducción Windows con
  `HostConfig.PortBindings` solicitado pero `NetworkSettings.Ports` vacío. Los tres motores
  estaban saludables, pero Windows no escuchaba. H1–H3 ya habían sido aceptados técnicamente
  por Joseph; esta prueba encontró una limitación adicional de la infraestructura.
- Decisión: `compose.local.yaml` incorpora un `port-gateway` TCP sin secretos ni volumen,
  imagen HAProxy 3.2-alpine por digest. Mantiene los **tres motores** solo en la red
  `medical-network` interna. Únicamente el gateway une esa red con `host-access` bridge y
  publica 127.0.0.1. El modo base permanece sin puertos/gateway.
- Motivo: un motor conectado exclusivamente a una red interna no obtuvo puertos reales;
  relajar `internal: true` de los motores habría cambiado su aislamiento.
- Verificación: `Get-PostgresSnapshot` observa `NetworkSettings.Ports` del gateway, su ID,
  salud y proyecto; sondas TCP alcanzan los tres puertos; selección base ante despliegue
  overlay falla. En Windows PASAN healthchecks, consultas nativas PG/SQL Server y P12 parcial.
- Archivos: `compose.local.yaml`, `docker/port-gateway/haproxy.cfg`, `scripts/Compose-Context.ps1`,
  `Test-Infra.ps1`, `Test-Persistence.ps1`, workflow, guía, matriz, estado y evidencia.
- Impacto/limitación: cuarto **contenedor auxiliar**, no motor ni modificación de contrato
  clínico. El gateway tiene salida por bridge; no contiene credenciales y monta config read-only.
  No prueba conectores FDW ni persistencia de los otros motores. CI del cambio pendiente al
  elaborar esta entrada; registrar run y resultado efectivo en evidencia antes de cierre.

**Cierre de verificación D-034:** CI [39807402214](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/39807402214)
SUCCESS en head `0b5e507`, Windows ACL y Ubuntu base/localhost. Artifact localhost confirma
bindings activos en `NetworkSettings.Ports`, TCP desde host y P12 parcial. Registros separados
en `evidencias/registros/2026-10-22-joseph-gateway-ci.txt` y evidencia Windows 11.

### D-035 — Salud real del gateway y regresión de backend (22/10/2026, Joseph)

- Fuente: observaciones menores de la revisión técnica de PR #1; alcance de infraestructura de Joseph.
- Motivo: la sonda TCP del host y el antiguo healthcheck `haproxy -c` podían pasar con un
  backend caído; validaban listener y sintaxis, no disponibilidad de destinos.
- Decisión: HAProxy ofrece `/ready` **solo en 127.0.0.1:8404 dentro del contenedor**;
  responde 503 si alguno de los tres backends carece de servidor activo. El healthcheck
  de Docker consulta ese endpoint. El overlay sigue publicando solo 5432/1433/27017
  hacia 127.0.0.1 del host; 8404 no se publica.
- Prueba controlada: solo en el proyecto efímero `joseph-audit-localhost` de CI, detener
  PostgreSQL, exigir que gateway y validación runtime rechacen el backend caído,
  iniciarlo en `finally` y comprobar salud/IDs/volumen/puertos restaurados. No elimina datos
  ni volúmenes; causa indisponibilidad breve únicamente en ese proyecto de CI.
- Archivos: workflow, `compose.local.yaml`, `docker/port-gateway/haproxy.cfg`,
  `pruebas/infraestructura/Test-GatewayBackendFailure.ps1`, guía, matriz, estado, bitácora
  y evidencia. No cambia contratos clínicos ni módulos de Joyce/Armando.
- Evidencia inicial Windows: sintaxis HAProxy, configuración Compose, salud 200, consulta
  runtime y tres bindings host 127.0.0.1 PASAN tras recrear **solo el gateway**. Los tres
  IDs de motores permanecieron estables. La caída controlada se ejecuta solo en CI.
- Primera ejecución CI 39811585204 **FALLÓ** solo en el test negativo: `docker compose pause`
  congeló PostgreSQL, pero su socket TCP siguió aceptando conexiones; el check TCP de
  HAProxy permaneció UP. El test ejecutó `unpause` en `finally`. Se corrigió el estímulo a
  `stop/start`, que conserva contenedor y volumen pero cierra realmente el listener.
- Cierre CI: [39812197292](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/39812197292)
  SUCCESS en `ee5ce97`, tres jobs. Artifact localhost: el frontend TCP aceptó conexión
  con PG detenido, el gateway se marcó no saludable y la validación runtime lo rechazó;
  tras `start` recuperó salud con mismos contenedores/volumen/bindings. P12 parcial pasó
  después. No demuestra detección cuando un proceso congelado mantiene el socket TCP abierto,
  ni pérdida de funcionalidad que no cierre el puerto del backend.

### D-036 — Núcleo PostgreSQL aislado antes del gate FDW (22/10/2026, Joseph)

- Fuente: autorización explícita de Joseph para fase 2 independiente; motivo: avanzar y
  probar el modelo acordado sin inventar resultados de Joyce ni Armando.
- Decisión: crear 11 tablas en esquema `clinico` y el outbox en `integracion`, con PK
  compuesta de paciente, FK compuesta en citas y particiones LIST SJ/AL/CA sin DEFAULT.
  Los nombres de esquema son elección técnica de este PR; Joyce debe revisar la ruta
  `integracion.eventos_integracion` antes de codificar su worker. No se cambia la
  identidad intermotor ni el contrato `dbo.vw_estado_facturacion`.
- DDL/fixture viven en scripts ejecutados explícitamente sobre base vacía. Los datos son
  ficticios y estables; el outbox del fixture queda vacío. Solo las pruebas locales crean
  eventos sintéticos tras COMMIT y confirman ROLLBACK local; ningún evento se exporta.
- Impacto: PR #2 apilado sobre el PR #1; no cambia Compose, SQL Server, MongoDB, roles o
  vistas API. El gate FDW de `docs/06` **permanece abierto**. Antes de integración revisar
  con Joyce nombres de esquema, campos de outbox, tipos BSON/revisión y fixture compartido.
- Prueba: workflow separado sobre Ubuntu22
  [39878319168](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/39878319168)
  SUCCESS en `502f5fa`; dos bases vacías/restart. Manual Windows y resultado efectivo
  en `docs/07_PRUEBAS.md` y `evidencias/`, sin atribuir CI al host local.

### D-037 — Consolidar el núcleo de Joseph sobre main (23/10/2026, Joseph)

- Fuente/estado: autorización explícita de fase 3; **implementado en rama/PR**, merge
  aún no autorizado. PR #1 `0a42732` está en `main`; PR #2 `84cb072` quedó en la
  rama de infraestructura. El núcleo faltaba en `main` al verificar los árboles.
- Decisión: crear `feature/joseph-core-main-integration` desde `origin/main` y
  cherry-pick de los cuatro commits clínicos `0f3614a`, `295bf32`, `502f5fa`,
  `41c98b4`. El árbol coincidió con la rama de infraestructura fusionada antes
  de los cambios de CI. No duplicar infraestructura, reescribir historia ni tocar
  `main` directamente.
- Motivo/impacto: un PR nuevo y auditable hacia `main`; workflow del núcleo escucha
  ambas bases, `main` y la rama de infraestructura, con filtros de archivos.
  SQL erróneo bajo `ON_ERROR_STOP=1` debe propagarse como fallo CI. El primer run
  `40028582907` quedó rojo tras detectar el SQL inválido por `LASTEXITCODE` residual;
  `ae3f1b9` limpia solo ese código cuando el negativo esperado fue reconocido.
- Archivos: workflow, estado, plan, matriz de pruebas, decisiones, bitácora, guía,
  informe y evidencia. Contratos de IDs/tablas y módulos de otros integrantes
  permanecen intactos.

### D-038 — Riesgos del outbox y opciones para revisión de Joyce (23/10/2026, Joseph)

- Estado: **análisis/propuesta pendiente**, sin DDL, trigger, función ni worker nuevos.
  `id_evento` es único físicamente, pero `(id_estudio, revision, tipo_evento)` no;
  dos UUID pueden representar el mismo evento lógico. La FK al estudio no liga
  `eventos_integracion.revision` con `resultados_estudio.revision` y permite un
  evento sin resultado. La revisión positiva no impide decrementos en UPDATE.
  Cualquier escritor puede modificar el resultado sin emitir evento, salvo que
  permisos o una ruta única de escritura futura lo impidan.
- Casos: reintento tras guardar MongoDB y antes de marcar PROCESADO; dos escritores
  concurrentes; eventos fuera de orden; actualización clínica sin outbox; duplicado
  lógico con distinto UUID; revisión que no existe en el resultado actual.
- Alternativa A: función/procedimiento PostgreSQL único con permisos de DML
  restringidos, bloqueo u optimistic locking y resultado+evento en una transacción.
  Alternativa B: trigger sobre resultado que genere el evento, con política explícita
  para correcciones/cancelaciones. Alternativa C: escritura coordinada desde
  aplicación más UNIQUE lógica y pruebas negativas; deja mayor riesgo si existe
  DML directo. Historial de revisiones inmutable/snapshot sería necesario para
  una FK formal a cada revisión pasada; una FK simple al resultado mutable no basta.
- Revisión requerida de Joyce: semántica de `tipo_evento`, unicidad/reintentos,
  generación y monotonicidad de `revision`, payload histórico o lectura vigente,
  cuenta/privilegios del worker, concurrencia, idempotencia MongoDB e índice único
  `id_estudio`. No elegir mecanismo ni editar interfaz compartida hasta acordarlo.
- Impacto: la consolidación del **núcleo aislado** puede revisarse, pero la
  integración MongoDB y el gate FDW/BSON siguen bloqueados; P04/P13 solo prueban
  atomicidad de la transacción local usada por el test, no todas las escrituras.
