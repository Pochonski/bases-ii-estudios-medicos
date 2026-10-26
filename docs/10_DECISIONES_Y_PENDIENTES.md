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
  Tras revisar el límite de esa comprobación, `6e9d1bb` la sustituyó por un
  paso SQL que falla realmente bajo `continue-on-error` limitado a ese paso y
  una aserción posterior de `outcome=failure`. Así se ensaya la propagación en
  Actions sin dejar rojo el PR por el error deliberado. La CI del núcleo en
  [40029751371](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40029751371)
  PASÓ; no se suavizaron los errores de instalación o de pruebas clínicas.
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

### D-039 — Spike tds_fdw autónomo y temporal (24/10/2026, Joseph)

- **Fuente y motivo:** autorización explícita de Joseph para fase 4; PR #3 sigue
  abierto en borrador, y no existen archivos ni PR de los módulos SQL Server/MongoDB
  definitivos de Joyce. El requisito académico pide consultas FDW reales; instalar
  la extensión no basta.
- **Decisión de implementación:** PR #4 se apila sobre el HEAD del PR #3. Un
  proyecto Compose con nombre aleatorio, red interna, volúmenes nuevos y sin puertos
  host levanta PostgreSQL y SQL Server. Solo en él se crean una base/vista de prueba
  SQL Server con el contrato de columnas, cuatro filas ficticias y login de lectura
  limitada. El script FDW de Joseph se ejecuta sin modificarlo y las consultas se
  hacen mediante autenticación PostgreSQL propia. Tras la prueba se eliminan objetos
  y recursos **del proyecto temporal**, nunca volúmenes preexistentes compartidos.
- **Impacto:** no se aprueba ni modifica `dbo.vw_estado_facturacion` de Joyce, la
  política de factura agregada, `api.vw_paciente_facturacion` de Armando ni el
  outbox. P01/P17 finales quedan pendientes de vista/base/fixture/cuenta reales.
  La prueba de conectividad/tipos/permisos será solo **compatibilidad de spike**,
  y el gate `mongo_fdw`/BSON continúa abierto.
- **Seguridad y riesgo:** `encryption=require` en FreeTDS no acredita verificación
  de identidad del servidor; la CA/TLS definitiva requiere revisión. Los secretos
  son efímeros e ignorados; no hay mapping `PUBLIC`. La limpieza `down --volumes`
  se limita a un nombre aleatorio previamente verificado ausente y creado en la
  misma ejecución; no se autoriza para proyectos compartidos.
- **Pruebas y estado:** `scripts/Test-TdsFdwSpike.ps1 -StaticOnly` pasó en Windows
  11; Docker Desktop no exponía `dockerDesktopLinuxEngine` y el runtime local no se
  ejecutó. La CI [40103007250](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40103007250)
  de `e514ee7` PASÓ lectura real, negativos y recuperación en Ubuntu y estático
  Windows Server; evidencia en `docs/07_PRUEBAS.md`. No certifica el host Windows
  local ni objetos definitivos.

### D-040 — Corregir pérdida silenciosa de WHERE/ORDER BY en tds_fdw (24/10/2026, Joseph)

- **Hallazgo reproducido:** CI `40102446960` con extensión 2.0.5 y opción
  `query` obtuvo cuatro filas para `WHERE id_paciente=1002 AND codigo_region='AL'`,
  pese a que ninguna de las cuatro claves remotas era `1002/AL`. `EXPLAIN VERBOSE`
  mostró `Foreign Scan` sin `Filter` y `Remote query` sin predicado. La primera
  CI `40102260838` había detectado el problema, y la segunda lo aisló. Es un
  riesgo de respuesta clínica/facturación incorrecta, no una simple falla de test.
- **Causa contrastada:** [issue abierto #444 de tds_fdw](https://github.com/tds-fdw/tds_fdw/issues/444)
  describe exactamente que el planner clasifica condiciones como remotas para
  `query`, pero el SQL remoto fijo no recibe WHERE; también reclama orden remoto
  sin enviar ORDER BY. Nuestro runtime coincidió con ese mecanismo.
- **Corrección propuesta dentro de Joseph:** mantener el commit upstream fijado y
  aplicar un parche local explícito durante el build de PostgreSQL. Cuando una
  tabla FDW usa `query`, todas sus condiciones quedan `local_conds` y no se
  crean rutas de orden ni joins parametrizados que el SQL fijo no puede cumplir.
  Se conserva la proyección ISO de DATETIMEOFFSET y no se cambia la vista de Joyce
  ni el contrato externo. La regresión exige filtro ausente/presente, orden
  descendente y `LEFT JOIN` correcto. Las tablas FDW basadas en `table` mantienen
  el comportamiento upstream.
- **Impacto y revisión:** la imagen sigue partiendo de `tds_fdw` 2.0.5, pero
  **incluye parche local**; indicar esto en cualquier despliegue. Joyce debe
  revisar el contrato/resultado antes de integración definitiva. La CI `40103007250`
  mostró `Filter` local, ausencia 1002/AL, orden y JOIN correctos. Mantener el
  gate definitivo abierto hasta repetir con la vista/cuenta de Joyce y TLS validado.
  El filtrado local evita respuestas incorrectas pero lee la consulta fija
  completa: medir costo y cardinalidad de la vista real; un arreglo upstream o
  diseño que preserve pushdown seguro sería preferible si el volumen crece.

### D-041 — Módulos de Joyce: SQL Server, MongoDB, mongo_fdw y outbox (25/10/2026, Joyce)

- **Fuente/estado:** autorización explícita de Joyce para su alcance (`agents/JOYCE.md`).
  IMPLEMENTADO Y PROBADO en Windows 11 local (Docker 29.9.2, kernel WSL 6.6.87.2), rama
  `feature/joyce-sqlserver-mongodb` creada desde `feature/joseph-tds-fdw-spike` (núcleo de
  Joseph + parche D-040). Sin merge. No hay CI propia todavía.
- **SQL Server:** base `integracion_externa`; fragmentos verticales `paciente_integracion` y
  `paciente_cobertura` con PK `(id_paciente,codigo_region)`; `facturas_externas`,
  `resumen_facturacion`, procedimientos `sp_recalcular_resumen_facturacion` y
  `sp_registrar_factura_externa`; vista contractual `dbo.vw_estado_facturacion` sin cambios
  de nombre/columnas respecto al contrato; login `svc_pg_mssql_ro` solo con `SELECT` de la vista.
  Política: `ANULADA` no cuenta; sin facturas → `SIN_FACTURAS`; alguna pendiente → `PENDIENTE`.
- **MongoDB:** `reportes_medicos.resumenes_estudios` con validador `$jsonSchema` de tipos del
  contrato, índice único `id_estudio`, usuario `svc_pg_mongo_rw` (find/insert/update en esa
  colección únicamente).
- **mongo_fdw (resuelve P0 #5 de este registro):** probado de verdad: lectura, `INSERT`,
  `UPDATE` por `_id`, mapeo bigint→Int64, integer→Int32, timestamptz→Date, `_id` ObjectId.
  **No se necesita integración intermedia**; se mantiene `mongo_fdw` como pide el enunciado.
- **Outbox (opción A de D-038):** `integracion.registrar_resultado()` escribe resultado + evento
  en una transacción; `CALL integracion.exportar_pendientes()` (solo `usr_fdw_pg_mongo`) lee el
  estado vigente, inserta/actualiza por revisión, verifica y marca; `ERROR` + reintento (máx. 5);
  `integracion.encolar_exportacion_masiva()` para INT-04. Consistencia eventual, no ACID global.
- **Cambios al núcleo de Joseph — REQUIEREN SU REVISIÓN:** índice único
  `eventos_logico_ux (id_estudio, revision, tipo_evento)` y secuencia
  `clinico.seq_resultados_estudio` (inicio 41000). No se renombra ni altera ninguna columna.
  `integracion/01_fdw_sqlserver.sql` de Joseph se usa sin modificar (`mssql_database=integracion_externa`).
- **Secretos:** cuatro archivos nuevos en `secrets/` (ignorada) con la ACL de `Initialize-Local.ps1`;
  viajan por stdin y entorno del proceso, no por argumentos.
- **Hallazgo:** un procedimiento PL/pgSQL con cláusula `SET` no puede hacer `COMMIT`
  (`invalid transaction termination`); se quitó `SET search_path` del exportador y se calificaron
  todos los objetos. El documento ya escrito antes del fallo no se duplicó (diseño idempotente).
- **Archivos:** `sqlserver/01..06`, `mongodb/01..03`, `integracion/02_fdw_mongodb.sql`,
  `integracion/sincronizacion/01_outbox.sql`, `pruebas/sqlserver/*`,
  `pruebas/integracion/05_p01_facturacion_real.sql`, `scripts/Joyce-Common.ps1`,
  `Install-JoyceModulos.ps1`, `Test-JoyceModulos.ps1`, `documentacion/JOYCE_SQLSERVER_MONGODB.md`.
- **Evidencia:** `evidencias/registros/2026-10-25-joyce-pruebas-local.txt`.
- **Pendiente:** TLS de FreeTDS sin CA (igual que D-039); MongoDB sin TLS; CI para estos módulos;
  la vista API y las agregaciones finales siguen siendo de Armando.

### D-042 — Joyce implementa los módulos de Armando con su permiso (25/10/2026, Joyce)

- **Fuente:** Joyce informa que Armando le dio permiso para hacer partes de su alcance.
  No modifica la regla 10 de AGENTS.md (a Armando no se le traspasan tareas iniciales); aquí
  ocurre lo contrario. **Armando debe confirmarlo y revisar el PR**, y narra su parte del video.
- **Implementado:** `postgresql/04_roles_externos.sql` (usr_api_web/usr_api_mobile con SCRAM,
  `default_transaction_read_only`, límites de conexión y `statement_timeout` distintos;
  `api_propietario` NOLOGIN dueño de las vistas; `REVOKE CONNECT ... FROM PUBLIC` y CONNECT
  solo a los cuatro perfiles del curso), `postgresql/05_vistas_api.sql` (`api.vw_paciente_facturacion`,
  `api.vw_citas_web`, `api.vw_citas_mobile`, todas `security_barrier`), `mongodb/04_agregaciones.js`
  (médico × tipo, productividad, sucursal/región de atención, fuera de región, indicadores mensuales
  con `$merge`), `mongodb/05_validaciones.js`, `pruebas/seguridad/01..02`.
- **Hallazgo técnico:** `tds_fdw` usa el USER MAPPING del usuario que consulta, no el del dueño
  de la vista (`user mapping not found` reproducido). Decisión: función `SECURITY DEFINER`
  `externo.fn_estado_facturacion()` con dueño `usr_fdw_pg_mssql`; el acceso remoto siempre sale
  por el perfil interno y ningún perfil externo tiene credenciales de SQL Server. `usr_api_web`
  necesita `EXECUTE` sobre ella (las funciones de una vista se autorizan con el invocador).
- **Pruebas:** P02, P03, P09 (contraste exacto MongoDB = PostgreSQL, 12 grupos), P10, P11 y login
  con contraseña incorrecta rechazado PASAN en Windows 11 local. Evidencia en
  `evidencias/registros/2026-10-25-joyce-pruebas-local.txt`. Sin CI.
- **Límite:** las vistas no filtran por paciente/usuario (sin RLS); P11 sobre vistas con JOIN
  falla por vista no actualizable (55000) además de solo lectura.
