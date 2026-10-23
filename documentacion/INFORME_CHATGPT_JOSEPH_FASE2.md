# Informe técnico para ChatGPT — Joseph, fase 2 PostgreSQL

**Fecha:** 22/10/2026 (America/Costa_Rica). **Objetivo:** implementar y probar de
manera independiente el núcleo clínico PostgreSQL de Joseph, sin depender del SQL
Server/MongoDB de Joyce ni de las vistas/roles de Armando. Este informe distingue
implementación, ejecución CI Ubuntu y ejecución en la PC Windows de Joseph.

## 1. Rama, commits y PR

- Punto de partida verificado: `feature/joseph-infra-postgresql` en
  `20e9fe680b8d71a19640b61b8ea991f6a4665183`, PR #1 abierto y en borrador.
- Rama nueva: `feature/joseph-postgresql-core`, creada desde ese commit.
- [PR #2 en borrador](https://github.com/Pochonski/bases-ii-estudios-medicos/pull/2),
  base `feature/joseph-infra-postgresql`. `main` no fue editada, fusionada ni aprobada.
- Commits funcionales: `0f3614a` (DDL/fixture), `295bf32` (pruebas/CI),
  `502f5fa` (marcadores de prueba y versión PG en artifact). El commit documental
  final se identifica en el PR después del cierre de este informe.

## 2. Archivos creados o modificados

| Área | Archivos | Cambio real |
|---|---|---|
| Modelo | `postgresql/01_esquemas.sql`, `02_tablas.sql`, `03_particiones.sql` | Dos esquemas, 12 tablas, PK/FK/CHECK/UNIQUE, índices y LIST SJ/AL/CA |
| Fixture | `postgresql/06_datos_prueba.sql` | Datos sintéticos deterministas; outbox vacío |
| Pruebas | `pruebas/postgresql/01_estructura.sql` a `05_persistencia.sql`; `scripts/Test-PostgresqlCore.ps1` | Validaciones SQL y ejecución en dos bases vacías; restart PG opcional |
| CI | `.github/workflows/joseph-postgresql-core.yml` | Runner Ubuntu22 aislado, artifact 14 días; detiene contenedor sin borrar volúmenes |
| Documentación | `README.md`, `docs/00_ESTADO_Y_FUENTES.md`, `03_MODELO_DATOS.md`, `06_PLAN_IMPLEMENTACION.md`, `07_PRUEBAS.md`, `10_DECISIONES_Y_PENDIENTES.md`, `11_BITACORA.md`, esta página y `JOSEPH_FASE2_POSTGRESQL.md` | D-036, orden de ejecución, estado real, límites y traspaso pendiente |
| Evidencia | `evidencias/registros/2026-10-22-joseph-postgresql-core-ci.txt` | Extracto sin secretos de comandos, resultados y enlaces CI |

No se editó `compose.yaml`, Dockerfile, SQL Server, MongoDB, `integracion/` ni
archivos de Armando. El PR #2 contiene únicamente el delta sobre infraestructura.

**Versiones y dependencias:** se reutiliza la imagen del PR #1 basada en
`postgres:16-bookworm` fijada por digest; la CI de esta fase informó servidor
PostgreSQL `16.15 (Debian 16.15-1.pgdg12+2)`. Dockerfile también compila
`tds_fdw` 2.0.5 y `mongo_fdw` 5.5.3 con `mongo-c-driver` 1.30.2, pero estas
extensiones **no se ejercitan como conectores remotos** en el PR #2.

## 3. Estructura exacta de las doce tablas

**Esquema `clinico`:**

| Tabla | Columnas y tipos | Claves y restricciones principales |
|---|---|---|
| `regiones` | `codigo_region char(2)`, `nombre varchar(60)` | PK código, nombre UNIQUE/NOT NULL, código en SJ/AL/CA, nombre no vacío |
| `sucursales` | `id_sucursal integer`, `codigo_region char(2)`, `nombre varchar(100)`, `direccion varchar(200)`, `activa boolean` | PK positiva; FK región; nombre obligatorio/no vacío; activa NOT NULL default true |
| `pacientes` | `id_paciente bigint`, `codigo_region char(2)`, `nombre varchar(80)`, `apellidos varchar(120)`, `fecha_nacimiento date`, `telefono varchar(20)`, `correo varchar(120)`, `fecha_registro timestamptz` | PK compuesta `(id_paciente,codigo_region)`, FK región, id positivo; nombre/apellidos/fecha obligatorios; fecha registro default `now()` |
| `medicos` | `id_medico bigint`, `nombre varchar(80)`, `apellidos varchar(120)`, `especialidad varchar(100)`, `activo boolean` | PK positiva; nombre/apellidos/especialidad obligatorios/no vacíos; activo default true |
| `usuarios_administrativos` | `id_usuario bigint`, `nombre varchar(120)`, `correo varchar(120)`, `activo boolean` | PK positiva; correo UNIQUE/NOT NULL/no vacío; nombre obligatorio/no vacío; activo default true |
| `citas` | `id_cita bigint`, `id_paciente bigint`, `codigo_region char(2)`, `id_medico bigint`, `id_sucursal integer`, `fecha_hora timestamptz`, `estado varchar(20)` | PK positiva; FK compuesta a paciente, FK médico/sucursal; todos los campos obligatorios; estado PROGRAMADA/COMPLETADA/CANCELADA |
| `ordenes_medicas` | `id_orden bigint`, `id_cita bigint`, `fecha_emision timestamptz`, `indicaciones text`, `estado varchar(20)` | PK positiva, FK cita, fecha/estado obligatorios y estado no vacío |
| `tipos_estudio` | `id_tipo integer`, `nombre varchar(100)`, `categoria varchar(60)`, `descripcion text` | PK positiva; nombre UNIQUE/NOT NULL/no vacío |
| `estudios` | `id_estudio bigint`, `id_orden bigint`, `id_tipo integer`, `estado varchar(20)`, `fecha_realizacion timestamptz` | PK positiva; FK orden/tipo; estado SOLICITADO/EN_PROCESO/FINALIZADO/CANCELADO |
| `resultados_estudio` | `id_resultado bigint`, `id_estudio bigint`, `id_medico_firmante bigint`, `resumen text`, `fecha_resultado timestamptz`, `revision integer` | PK positiva; FK estudio UNIQUE; FK médico; resumen/fecha obligatorios; revisión positiva default 1 |
| `diagnosticos` | `id_diagnostico bigint`, `id_resultado bigint`, `descripcion text`, `codigo_diagnostico varchar(30)` | PK positiva; FK resultado; descripción obligatoria/no vacía |

**Esquema `integracion`:** `eventos_integracion` contiene `id_evento uuid` PK,
`id_estudio bigint` FK, `revision integer > 0`, `tipo_evento varchar(40)` no vacío,
`estado varchar(20)` en PENDIENTE/PROCESADO/ERROR (default PENDIENTE),
`intentos integer >= 0` (default 0), `fecha_creacion timestamptz` (default `now()`)
y `fecha_procesamiento timestamptz` opcional. Es almacenamiento local de outbox,
sin worker ni garantía de entrega aún. Los índices de FKs y pendientes figuran en
`02_tablas.sql`; PostgreSQL crea índices propios para PK/UNIQUE.

Los esquemas revocan acceso de `PUBLIC`; los roles externos quedan para la fase
asignada a Armando. No se añadió una secuencia global de IDs: el contrato formal
de paciente es el par compuesto, y la identidad compartida de estudio es `id_estudio`.

## 4. Particiones y fixture

`clinico.pacientes` usa `PARTITION BY LIST(codigo_region)` con
`pacientes_sj ('SJ')`, `pacientes_al ('AL')` y `pacientes_ca ('CA')`, sin DEFAULT.
La FK de `citas` utiliza **ambas** columnas de identidad. La región donde ocurre la
atención se obtiene de `citas.id_sucursal` → `sucursales.codigo_region`. El caso
ficticio `1001/AL` se atiende en sucursal `1/SJ`; una prueba verifica esa diferencia.

El fixture, determinista para base vacía, incluye 3 regiones, 3 sucursales,
30 pacientes (10 por región: AL 1001–1010, SJ 2001–2010, CA 3001–3010), 6 médicos,
2 administrativos, 30 citas, 25 órdenes, 4 tipos, 40 estudios, 30 resultados y
15 diagnósticos con código `SIM-*`. Usa `example.invalid`, nombres explícitamente
ficticios y fechas fijas. **Cero** eventos de integración en el fixture; ninguna
factura ni documento MongoDB simulado.

## 5. Comandos y pruebas efectivamente ejecutados

En Windows local: `git status/log/branch/add/commit/push/diff --check`,
`gh pr create/view`, `gh run list/view/download`, parser de PowerShell 7 y
`docker info`, además de `./scripts/Test-Infra.ps1 -ComposeFile compose.yaml
-EnvFile .env -ProjectName estudios-medicos -StaticOnly`. La selección local base
PASÓ ejemplo y entorno operativo; el parser devolvió **0 errores** y
`git diff --check` fue limpio.
`docker info` falló por ausencia de `npipe:////./pipe/dockerDesktopLinuxEngine`.
**No** se ejecutaron DDL, consultas ni restart clínico en esta PC durante la fase 2;
no se cambió WSL/kernel/Docker ni se eliminaron volúmenes locales.

En CI Ubuntu22 se ejecutan `Initialize-Local.ps1`, `Test-Infra.ps1 -StaticOnly`,
`docker compose build postgres`, `docker compose up -d --wait --wait-timeout 300 postgres`,
`./scripts/Test-PostgresqlCore.ps1 -Repeat 2 -IncludePersistence` y
`docker compose down` **sin `-v`**. El runner usa `createdb -T template0`, ejecuta
01/02/03/06 y las cinco pruebas SQL con `ON_ERROR_STOP=1`, reinicia únicamente PG,
compara contenedor/volumen/puertos y elimina las bases sintéticas tras éxito.

La primera ejecución [39878097819](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/39878097819)
terminó **SUCCESS** en código `295bf32`, checkout de merge `f00e266`,
Ubuntu22 kernel `6.8.0-1064-azure`, Docker 28.0.4, Compose 2.38.2, PowerShell 7.6.6.
Los `NOTICE` del log muestran estructura/fixture exactos, seis rechazos, P14,
COMMIT/ROLLBACK y persistencia en ambas bases. El artifact registra `tableoid`
10/10/10 y un plan que escanea solo `pacientes_al`. Ambas bases se eliminaron.
La [regresión 39878319168](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/39878319168)
terminó **SUCCESS** en `502f5fa`, checkout de merge `16aec74`, con los mismos
resultados en dos bases vacías y dos restart. Su artifact `joseph-postgresql-core`
incluye marcadores `PASS` por caso, PostgreSQL servidor **16.15**
(`Debian 16.15-1.pgdg12+2`), kernel `6.8.0-1064-azure`, Docker 28.0.4,
Compose 2.38.2 y PowerShell 7.6.6. Se verificó que la configuración efectiva
no publica puertos. Los IDs de las bases sintéticas no son contratos compartidos.

La regresión heredada de infraestructura [39878097833](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/39878097833)
terminó **SUCCESS** en ese mismo código inicial: ACL Windows Server 2022,
Ubuntu base y Ubuntu localhost. Ese job Windows prueba permisos, no el núcleo
clínico ni los motores de la PC de Joseph.
La [regresión 39878319636](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/39878319636)
también terminó **SUCCESS** en el head funcional final `502f5fa`: tres jobs y
artifacts base/localhost/ACL descargados y revisados. No se cambió Compose y
el modo base sigue sin puertos; localhost publica solo en 127.0.0.1.

**Alcance Pxx:** P14 queda probado en Ubuntu. P04 prueba solo COMMIT local con
evento PENDIENTE; P13 solo ROLLBACK local; P12 solo registros clínicos PostgreSQL
tras `restart` del mismo contenedor/volumen. P18 demuestra dos instalaciones de
este módulo en bases vacías, no la instalación completa de tres motores/integraciones.

## 6. Riesgos, dependencias y recomendación

1. La elección de esquemas `clinico`/`integracion`, ruta y campos del outbox requieren
   revisión de Joyce **antes** de conectar su worker. No se cambió el contrato
   intermotor de IDs ni se envió mensaje a compañeros.
2. TDS requiere de Joyce la base, `dbo.vw_estado_facturacion` real, cuenta restringida,
   tipos y fixture acordados; no hay consulta FDW remota acreditada.
3. Mongo FDW requiere validación conjunta de autenticación, `ObjectId`, Int64/Int32,
   BSON Date, lectura, INSERT, UPDATE, índice único y revisión monotónica. `LOAD` o
   `CREATE EXTENSION` de fase 1 no prueban esos comportamientos.
4. No hay worker, exportación, consulta federada, vista API ni roles externos.
   COMMIT PG + outbox no es una transacción ACID global. La política de reintentos
   y los permisos de cuentas propias siguen pendientes.
5. El restart probado conserva el contenedor y volumen; no acredita recreación,
   restauración ni persistencia de SQL Server/MongoDB. La estabilidad del daemon
   Docker Desktop Windows sigue sin confirmar en esta sesión.

**Recomendación:** revisar técnicamente y conservar el PR #2 apilado y en borrador.
Tras restaurar el daemon local, repetir la guía Windows con la misma selección
Compose. Antes de integrar con Joyce, acordar esquema/outbox y completar el spike
FDW/BSON con consultas y escrituras reales. Solo entonces planificar el traspaso
de interfaz a Armando. No fusionar ni aprobar PR #1/#2 sin nueva autorización.

**Tareas siguientes de Joseph:** repetir prueba clínica en Windows; documentar
kernel efectivo, versión PG, `tableoid`, EXPLAIN y restart; revisar con Joyce los
campos de intercambio; validar P01 con su vista/cuenta/fixture reales; conservar
evidencia del gate FDW y resolver fallos antes de integración.
