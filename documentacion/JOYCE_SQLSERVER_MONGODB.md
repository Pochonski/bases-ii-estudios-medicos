# Joyce: SQL Server, MongoDB y sincronización

**Responsable:** Joyce. **Rama:** `feature/joyce-sqlserver-mongodb` (parte de
`feature/joseph-tds-fdw-spike`, que incluye el núcleo clínico de Joseph y el parche D-040).
**Decisión:** D-041. Datos 100 % ficticios; ningún secreto en Git.

## Qué se construyó

### SQL Server — base `integracion_externa`

| Archivo | Contenido |
|---|---|
| `sqlserver/01_base_tablas.sql` | Base, `aseguradoras`, `convenios` |
| `sqlserver/02_fragmentacion.sql` | Fragmentos verticales `paciente_integracion` (aseguradora, código externo) y `paciente_cobertura` (cobertura, facturación), ambos con PK `(id_paciente, codigo_region)` y FK 1:1; `facturas_externas`; `resumen_facturacion` |
| `sqlserver/03_procedimientos.sql` | `dbo.sp_recalcular_resumen_facturacion` (genera el resumen) y `dbo.sp_registrar_factura_externa` (simula llegada de factura y recalcula) |
| `sqlserver/04_vistas.sql` | `dbo.vw_paciente_asegurado` (reconstrucción vertical) y `dbo.vw_estado_facturacion` (contrato con PostgreSQL, una fila por paciente-región) |
| `sqlserver/05_roles.sql` | Login `svc_pg_mssql_ro`: `SELECT` solo de la vista; `DENY` explícito en tablas y `EXECUTE` |
| `sqlserver/06_datos_prueba.sql` | 3 aseguradoras, 3 convenios, 24 pacientes registrados (8 por región), 11 facturas; recalcula el resumen |

**Segmentación vertical:** la entidad lógica *paciente asegurado* se divide por columnas.
El fragmento 1 guarda solo lo necesario para interoperar (`id_aseguradora`, `codigo_externo`);
el fragmento 2, el estado de cobertura y facturación. La vista `vw_paciente_asegurado`
reconstruye la entidad con un `JOIN` 1:1 por la clave compuesta (prueba P15).

**Política de facturación:** facturas `ANULADA` no cuentan; sin facturas válidas →
`SIN_FACTURAS`; alguna `PENDIENTE` → `PENDIENTE`; todas pagadas → `PAGADA`. Coberturas:
`VIGENTE`, `INACTIVA`, `PENDIENTE`. Un paciente sin fila en SQL Server se muestra en
PostgreSQL como `SIN_REGISTRO` mediante `LEFT JOIN` (lo formaliza Armando en la vista API).

**Casos del fixture:** 1001/AL VIGENTE, facturas 15 000 PENDIENTE + 8 500 PAGADA → total
23 500, `PENDIENTE`. 2002/SJ INACTIVA. 3003/CA con su única factura ANULADA → `SIN_FACTURAS`.
Sin registro externo: 1009, 1010, 2009, 2010, 3009, 3010.

### MongoDB — base `reportes_medicos`

| Archivo | Contenido |
|---|---|
| `mongodb/01_colecciones.js` | `resumenes_estudios` con validador `$jsonSchema` (tipos del contrato: Int64, Int32, Date) e `indicadores_mensuales` (opcional) |
| `mongodb/02_indices.js` | Único `ux_id_estudio`; `ix_medico_tipo`; `ix_region_atencion_fecha` |
| `mongodb/03_usuarios.js` | Rol `rol_exportacion_resumenes` (find/insert/update solo en `resumenes_estudios`) y usuario `svc_pg_mongo_rw` |

No hay script de datos de prueba MongoDB: **todos** los documentos llegan por la exportación real.

### PostgreSQL — canal mongo_fdw y outbox

| Archivo | Contenido |
|---|---|
| `integracion/02_fdw_mongodb.sql` | Rol `usr_fdw_pg_mongo` (LOGIN, sin privilegios administrativos), servidor `mongo_reportes`, user mapping solo para ese rol, `externo.ft_resumenes_estudios` |
| `integracion/sincronizacion/01_outbox.sql` | `integracion.registrar_resultado()`, `integracion.encolar_exportacion_masiva()`, `CALL integracion.exportar_pendientes()` y permisos mínimos |

Flujo (INT-02/INT-04):

1. `SELECT * FROM integracion.registrar_resultado(id_estudio, id_medico, resumen);`
   inserta o corrige el resultado (revisión +1) y crea el evento `PENDIENTE` **en la misma
   transacción**. Un `ROLLBACK` no deja nada que exportar.
2. Tras `COMMIT`, `usr_fdw_pg_mongo` ejecuta `CALL integracion.exportar_pendientes();`.
   Por cada evento lee el estado **vigente** del resultado, consulta MongoDB por
   `mongo_fdw` y hace `INSERT` (no existe), `UPDATE` (MongoDB tiene revisión menor) o nada
   (ya tiene igual o mayor). Verifica el documento y marca `PROCESADO`; si falla, `ERROR`
   con `intentos+1` y se reintenta en la siguiente llamada (máx. 5).
3. Cada evento se confirma por separado (`COMMIT` dentro del procedimiento).

**No es una transacción ACID global**: es consistencia eventual. Si MongoDB recibió el
documento pero PostgreSQL no alcanzó a marcar el evento, el reintento no duplica (índice
único + comparación de revisión).

El documento no contiene nombre ni contacto del paciente; `usr_fdw_pg_mongo` ni siquiera
tiene acceso a `clinico.pacientes`.

## Cómo ejecutar (Windows 11, PowerShell 7, Docker Desktop)

```powershell
pwsh -NoProfile -File ./scripts/Install-JoyceModulos.ps1
pwsh -NoProfile -File ./scripts/Install-JoyceModulos.ps1 -LoadInitialData # únicamente tablas vacías
pwsh -NoProfile -File ./scripts/Test-Entrega.ps1 -StaticOnly      # valida aislamiento sin daemon
pwsh -NoProfile -File ./scripts/Test-Entrega.ps1 -DesdeCero      # suite en proyecto efímero
```

El instalador:
- crea cuatro secretos nuevos en `secrets/` (ignorada por Git) y reaplica las ACL de Joseph;
- levanta `compose.yaml`;
- aplica SQL Server 01–05 y MongoDB 01–03; el script 06 de SQL Server solo se ejecuta
  con `-LoadInitialData` si las tablas están vacías, o con `-ResetLabData` en P18 efímero;
- aplica el núcleo de Joseph y su `integracion/01_fdw_sqlserver.sql` **solo si faltan**
  (con `mssql_database=integracion_externa`);
- habilita el login de `usr_fdw_pg_mssql` con `pruebas/integracion/03_postgresql_role.sql`;
- aplica `integracion/02` y el outbox.

Los secretos viajan por stdin al contenedor y se exportan como variables de entorno del
proceso; nunca aparecen como argumentos ni en archivos versionados.

`Test-JoyceModulos.ps1` exige el proyecto efímero que prepara `Test-Entrega.ps1`; allí
**detiene y reinicia `mongodb`** para P08 (se puede omitir con `-SkipMongoOutage`).
Reinicia los estudios sintéticos 30031/30032 solo dentro de ese proyecto. No ejecutar
`docker compose down --volumes` contra `estudios-medicos`. Las pruebas anteriores del
25/10 documentan el comportamiento histórico; no acreditan el aislamiento nuevo.

## Pruebas

| Prueba | Qué comprueba |
|---|---|
| P15 | Fragmentos 1:1, reconstrucción sin pérdida ni duplicados |
| P16 | Resumen coherente con facturas; el procedimiento cambia la vista; negativo de parámetros |
| Permisos SQL Server | `svc_pg_mssql_ro` lee la vista; se le niega tabla base, `INSERT` y `EXECUTE` (error 229) |
| P01 | Login `usr_fdw_pg_mssql`: 24 filas remotas únicas; `LEFT JOIN` 30/24/6; valores de 1001/AL; regresión de `WHERE` (D-040) |
| P16b | Factura confirmada en SQL Server → visible desde PostgreSQL; se retira y se restaura |
| P13 | `ROLLBACK` no deja resultado, evento ni documento |
| P04 | Resultado y evento `PENDIENTE` confirmados juntos |
| P05 | Documento creado por `mongo_fdw`; tipos BSON `long`/`int`/`date`; evento `PROCESADO` |
| P06 | Corrección → revisión 2 en el mismo documento |
| P07 | Reprocesar el evento de revisión 1: un solo documento, sigue en revisión 2 |
| Permisos PG | `usr_fdw_pg_mongo` no lee `pacientes`, no borra en MongoDB, no modifica resultados |
| P08 | MongoDB detenido: PostgreSQL confirma y el evento queda `ERROR`; al volver MongoDB, se procesa |
| INT-04 | Exportación masiva: cada resultado de PG tiene exactamente un resumen en MongoDB |

Los resultados reales se registran en `docs/07_PRUEBAS.md` y en `evidencias/registros/`.

## Para Joseph (revisar)

- D-041 agrega a su núcleo: índice único `eventos_logico_ux (id_estudio, revision, tipo_evento)`
  y secuencia `clinico.seq_resultados_estudio` (inicia en 41000). No renombra ni cambia columnas.
- Su `integracion/01_fdw_sqlserver.sql` se usa **sin cambios** con `mssql_database=integracion_externa`.

## Para Armando

- Vista remota en PostgreSQL: `externo.ft_estado_facturacion` (concedida a `usr_fdw_pg_mssql`).
  Para `api.vw_paciente_facturacion`, `LEFT JOIN` por `(id_paciente, codigo_region)`, con
  `COALESCE(..., 'SIN_REGISTRO')`.
- MongoDB: `reportes_medicos.resumenes_estudios`. Campos: `id_estudio` long, `id_paciente`
  long, `codigo_region` (registro), `id_medico` long (firmante), `id_tipo` int,
  `tipo_estudio`, `id_sucursal` int, `codigo_region_atencion` (sucursal), `fecha_resultado`
  date, `resultado_resumen`, `revision` int, `fecha_sincronizacion` date.
- Índice `ix_medico_tipo` disponible para la agregación médico × tipo.

## Módulos de Armando hechos por Joyce (D-042)

| Archivo | Contenido |
|---|---|
| `postgresql/04_roles_externos.sql` | `usr_api_web` (20 conexiones, timeout 15 s) y `usr_api_mobile` (50 conexiones, 5 s), ambos SCRAM y solo lectura; `api_propietario`; CONNECT solo para los cuatro perfiles |
| `postgresql/05_vistas_api.sql` | `externo.fn_estado_facturacion()` (SECURITY DEFINER, dueño `usr_fdw_pg_mssql`) y las vistas `api.vw_paciente_facturacion`, `api.vw_citas_web`, `api.vw_citas_mobile` |
| `mongodb/04_agregaciones.js` | Médico × tipo (INT-05), productividad, sucursal/región de atención, fuera de región, indicadores mensuales (`$merge` a `indicadores_mensuales`) |
| `mongodb/05_validaciones.js` | Unicidad, tipos BSON, suma de la agregación, sin datos personales, región registro ≠ atención, validador activo |
| `pruebas/seguridad/01..02` | P02, P03, P10, P11 por perfil, con login real |

| Perfil | Puede leer | Se le niega |
|---|---|---|
| `usr_api_web` | `api.vw_paciente_facturacion`, `api.vw_citas_web` | tablas `clinico`, tabla foránea, `vw_citas_mobile`, cualquier escritura |
| `usr_api_mobile` | `api.vw_citas_mobile` | facturación, agenda web, tablas, función remota, escrituras |

Por qué la función: `tds_fdw` usa el mapping del **usuario que consulta**. Si la vista leyera la
tabla foránea directamente, `usr_api_web` necesitaría credenciales de SQL Server.
