# Contratos de integración y comportamiento distribuido V1

**Estado:** diseño de comunicación aún SIN ejecutar. Consultar `docs/03_MODELO_DATOS.md` para el esquema y `docs/10_DECISIONES_Y_PENDIENTES.md` para pendientes de compatibilidad.

## Identificadores y convenciones comunes

| Concepto | PostgreSQL | SQL Server | MongoDB |
|---|---|---|---|
| `id_paciente` | BIGINT | BIGINT | Int64 |
| `codigo_region` | CHAR(2) | CHAR(2) | String (`SJ`, `AL`, `CA`) |
| `id_estudio` | BIGINT | BIGINT en facturas | Int64 |
| `id_medico` | BIGINT | No requerido en integración inicial | Int64 |
| `id_tipo` | INTEGER | No requerido | Int32 |
| `revision` | INTEGER | No requerido | Int32 |
| Fechas temporales | TIMESTAMPTZ | DATETIMEOFFSET si aplica | BSON Date UTC |
| Montos CRC | No requeridos en núcleo inicial | DECIMAL(12,2) | No requeridos |

**Identidad formal de paciente:** par `(id_paciente,codigo_region)`. **Identidad de estudio:** `id_estudio`. Para atención usar la región de sucursal, separada de región del paciente. Normalizar fechas en UTC y mostrar en la zona deseada en cliente.

## A. SQL Server → PostgreSQL (INT-01 e INT-03)

1. SQL Server posee `paciente_integracion`, `paciente_cobertura`, facturas y aseguradoras.
2. Construir `dbo.vw_estado_facturacion` combinando los dos fragmentos y facturas agregadas, **una fila por paciente y región**.
3. PostgreSQL instala `tds_fdw` y configura `CREATE SERVER`, `USER MAPPING` y `externo.ft_estado_facturacion` contra la vista SQL Server.
4. La vista `api.vw_paciente_facturacion` hace `LEFT JOIN` con `pacientes` usando ambas columnas.
5. Si no existe fila remota, devolver paciente y cobertura `SIN_REGISTRO` (no inventar rechazo). Valores reales de estado: `VIGENTE`, `INACTIVA`, `PENDIENTE`; facturas `PAGADA`, `PENDIENTE`, `SIN_FACTURAS`, con política de agregación definida.
6. `tds_fdw` se usa **solo en lectura**. Los registros SQL Server se cargan/actualizan desde su propio motor, no fingir `INSERT` remoto.
7. El profesor exige procedimientos SQL Server: uno recalcula `resumen_facturacion`, y se comprueba que la vista/consulta remota refleja el resultado.

**Caso ilustrativo NO ejecutado:** paciente 1001 (AL), María Rodríguez (ficticia), estado VIGENTE y factura ₡15.000 PENDIENTE.

**Riesgo:** el acceso remoto puede fallar si SQL Server se apaga; definir comportamiento de vista (error, no disponibilidad) como limitación aceptada, no simular datos locales.

## B. PostgreSQL → MongoDB (INT-02, INT-04)

**Precondición:** resultados clínicos y evento outbox se registran en una **misma transacción PostgreSQL**. El resultado debe estar confirmado antes de publicarse. No exportar desde una transacción pendiente o revertida.

1. Crear/actualizar `resultados_estudio` e insertar en `eventos_integracion` (`id_evento`, `id_estudio`, `revision`, tipo, PENDIENTE) dentro de la transacción local.
2. `COMMIT` en PostgreSQL; recién entonces el procesador ve el evento.
3. Un **procesador único** (componente auxiliar, no frontend) lee el outbox y el detalle vigente de estudios/resultado/médico/tipo/sucursal.
4. A través de `mongo_fdw` si resulta compatible, crear o modificar el resumen en `resumenes_estudios`. Se valida comportamiento real de `_id`, campos BSON e índice único en `id_estudio`; no presuponer UPSERT automático del FDW.
5. Idempotencia: si MongoDB ya tiene igual revisión, no duplicar; si tiene revisión menor, reemplazar/actualizar; **no retroceder** a una revisión anterior. Resolver concurrencia para una sola instancia de worker al inicio.
6. Tras comprobar el documento, marcar el evento procesado en PostgreSQL; si falla, registrarlo y reintentarlo sin pérdida o duplicación.
7. Apagado MongoDB: PostgreSQL puede confirmar; quedan eventos pendientes/ERROR; tras reconexión se procesan.

**No es una transacción ACID global** entre motores. Es un flujo de **consistencia eventual** con confirmación local y reintentos. La garantía de recuperación depende de que el proceso y sus pruebas efectivamente se implementen.

### Importante sobre FDW vs integración intermedia

El enunciado p. 2 menciona `mongo_fdw` **o integración intermedia**, pero p. 3 ordena usar `mongo_fdw`. **Prioridad:** intentar `mongo_fdw` y demostrar acceso real. Si incompatible, detener cambio de enfoque y preguntar docente por la alternativa; documentar evidencia de incompatibilidad. Un driver oficial MongoDB con `updateOne(..., upsert=true)` sería alternativa técnica **solo tras autorización**, no una decisión aprobada.

### Semántica de fallo

| Momento del fallo | Esperado |
|---|---|
| Antes de `COMMIT` PG / `ROLLBACK` | No documento exportado |
| Tras `COMMIT`, MongoDB inaccesible | Evento queda para reintento |
| Documento guardado, antes de marcar PROCESADO | Reintento idempotente sin duplicados |
| Revisión antigua llega después de una nueva | No sobrescribe revisión nueva |
| SQL Server inaccesible | Vista remota informa error / indisponibilidad; no inventar cobertura |

## C. Agregaciones MongoDB (INT-05)

- Conteo por `id_medico` y `id_tipo` (requisito).
- Conteo por tipo de estudio, por región/sucursal de **atención** y por mes (adicional propuesto).
- Primero ejecutar pipeline directo sobre `resumenes_estudios`; solo después, opcionalmente, persistir `indicadores_mensuales`.

## D. Contratos de corte entre integrantes

- **Joseph:** PostgreSQL + `externo.ft_estado_facturacion` + red/FDW SQL Server.
- **Joyce:** `dbo.vw_estado_facturacion` devuelve cardinalidad uno por paciente-región, MongoDB índices y documento, pipeline de exportación.
- **Armando:** consume estructuras congeladas después del traspaso del 25/10, crea `api.vw_paciente_facturacion` y agregaciones.

Los cambios de campos requieren registrar: columna, tipo anterior/nuevo, compatibilidad de datos, propietarios afectados y prueba de regresión.

## Preparación del consumidor SQL Server — 22/10/2026, Joseph

`integracion/01_fdw_sqlserver.sql` conserva nombres e identidad de este contrato; no crea la
vista de Joyce ni la vista API de Armando. Recibe el nombre de base como parámetro explícito.
Cadenas se leen como text, monto numeric(12,2), y fecha timestamptz mediante proyección ISO-8601
en la consulta SQL Server para evitar depender de DATETIMEOFFSET en DB-Library.
No se cambia el objeto remoto. Tipos concretos, offset/precisión, estados, cardinalidad y fixture
requieren revisión con Joyce y prueba real antes de integrar.
La preparación NO certifica compatibilidad: P01 está bloqueada; P17 solo tiene archivos.
El perfil usr_fdw_pg_mssql es NOLOGIN y el mapping no se otorga a PUBLIC.
