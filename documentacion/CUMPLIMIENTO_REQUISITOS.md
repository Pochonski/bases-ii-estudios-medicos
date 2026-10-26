# Matriz de cumplimiento del enunciado — actualización 26/10/2026

**Leyenda:** ✅ implementado y probado · ⚠️ pendiente de acción/validación · ❌ falta.

**Estado de integración verificado el 26/10/2026:** último commit de código probado en [`3d50894`](https://github.com/Pochonski/bases-ii-estudios-medicos/commit/3d50894c9e566d44a2190d6d115331983127f5bd); PR #3, #4 y #5 fusionados en `main`, PR #7 fusionado en la rama de Joyce e incorporado al merge de #5. No quedan PR de integración abiertos. **Cuatro workflows de `main`: siete trabajos de siete aprobados** en ese mismo SHA: [Infraestructura (3/3)](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40328045185) · [Núcleo PostgreSQL (1/1)](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40328099902) · [TDS FDW (2/2)](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40328122775) · [Integración de tres motores (1/1)](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40328144203).

**Evidencia Ubuntu CI:** P18 desde volúmenes efímeros, P01–P18, INT-01–INT-05, segmentación, FDW reales, permisos API, dos exportadores concurrentes, restauración PG/SQL Server/MongoDB mediante EJSON estricto, P12 tras reinicio y nueve segmentos automáticos de demo.

**Validación Windows 11 posterior:** P18 integral pasó sobre `origin/main` `2840743917364d137c5298b6456fef15862b3a92`, además de la CI Ubuntu anterior. Ver [registro e informe con hashes](../evidencias/2026-10-26-validacion-windows.md). No atribuir la ejecución al nuevo commit documental. Faltan capturas reales, video narrado de 5–8 min y entrega Moodle; confirmar el cierre efectivo indicado como 28/10/2026 a las 23:59. Límites: TDS `table_name` con igualdad DECIMAL incorrecta (usar `query` probada); TLS/CA no listo para producción; Mongo EJSON no equivale a `mongorestore`; el outbox es eventual y su candado no cubre DML directo fuera del procedimiento.

Los estados por módulo de la tabla siguiente conservan su matriz de aceptación; los
comentarios fechados de octubre anteriores se sustituyen arriba por el cierre verificado.

**Evidencias:**
- **Local:** Windows 11, archivos `evidencias/registros/2026-10-25-joyce-pruebas-local.txt` y
  `2026-10-25-joyce-entrega-p12-p17-p18.txt`.
- **Local final de Joseph:** [P18 integral 26/10](../evidencias/2026-10-26-validacion-windows.md)
  y [registro original copiado íntegro](../evidencias/registros/2026-10-26-joseph-validacion-integrada-windows.txt),
  código `2840743`, Docker Desktop Linux Engine en Windows 11.
- **CI:** Ubuntu 22.04, run [40274339076](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40274339076),
  artifact `joyce-modulos-evidencia`.
- **Infraestructura de Joseph:** runs de `joseph-infra.yml`, por ejemplo
  [40274338962](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40274338962).

## Motores y propósito

| Requisito del enunciado | Implementación | Prueba | Estado |
|---|---|---|---|
| PostgreSQL núcleo transaccional: pacientes, médicos, administrativos, citas, órdenes, estudios, resultados, diagnósticos, integridad referencial | `postgresql/01..03,06` (Joseph): 12 tablas, PK/FK compuestas, CHECK | estructura + integridad (Joseph) sobre la instalación integrada | ✅ |
| Segmentación horizontal por región | `clinico.pacientes` LIST → `pacientes_sj/al/ca` | P14 (10/10/10, pruning) | ✅ |
| SQL Server: integración externa (aseguradoras, convenios, facturación) | `sqlserver/01..06` | P15, P16 | ✅ |
| Segmentación vertical (`paciente_integracion` solo con columnas de interoperabilidad) | `paciente_integracion` + `paciente_cobertura`, reconstrucción 1:1 | P15 | ✅ |
| Procedimientos almacenados que generan resúmenes consultados por PostgreSQL | `sp_recalcular_resumen_facturacion`, `sp_registrar_factura_externa` | P16, P16b | ✅ |
| MongoDB: datos desnormalizados de PostgreSQL, reportes, agrupación por tipo/médico/fechas | `resumenes_estudios`, `indicadores_mensuales` (`$merge` mensual) | P05, P09, validaciones | ✅ |

## Comunicación distribuida

| Requisito | Implementación | Prueba | Estado |
|---|---|---|---|
| PostgreSQL ↔ SQL Server con FDW (`tds_fdw`) | `sqlserver_medico`, `externo.ft_estado_facturacion` | P01, P17 | ✅ |
| PostgreSQL ↔ MongoDB con `mongo_fdw` | `mongo_reportes`, `externo.ft_resumenes_estudios` (lectura, INSERT, UPDATE) | P05–P08, P17 | ✅ |
| Documentar canales FDW | `documentacion/MAPA_CONEXIONES_Y_CONFIGURACION.md` | P17 (volcado de catálogos) | ✅ |
| Consultas de prueba entre sistemas | `pruebas/integracion`, `pruebas/sqlserver`, `pruebas/seguridad`, `pruebas/reportes` | suite completa | ✅ |

## Usuarios y seguridad

| Requisito | Implementación | Prueba | Estado |
|---|---|---|---|
| `usr_fdw_pg_mssql`, permisos mínimos | Login SCRAM; mapping a `svc_pg_mssql_ro` (solo `SELECT` en la vista) | P01, permisos SQL Server | ✅ |
| `usr_fdw_pg_mongo`, inserción controlada | Login SCRAM, 3 conexiones; mapping a `svc_pg_mongo_rw` (find/insert/update) | P05, permisos negativos | ✅ |
| `usr_api_web`, vistas web | SELECT en `api.vw_paciente_facturacion` y `api.vw_citas_web` | P02, P10, P11 | ✅ |
| `usr_api_mobile`, vistas simplificadas | SELECT solo en `api.vw_citas_mobile` | P10, P11 | ✅ |
| Políticas diferenciadas y configuración de autenticación | SCRAM, solo lectura, límites de conexión y timeouts distintos, `pg_hba` restringido, CONNECT solo a perfiles | P10, P11, contraseña incorrecta rechazada, P17 | ✅ |

## Las cinco operaciones obligatorias

| Operación | Cómo se demuestra | Prueba | Estado |
|---|---|---|---|
| 1. Paciente PostgreSQL + estado de facturación SQL Server | LEFT JOIN con la tabla foránea, login `usr_fdw_pg_mssql` | P01 · demo segmento 5 | ✅ |
| 2. Inserción PostgreSQL que, tras confirmarse, actualiza MongoDB | `registrar_resultado` → COMMIT → `exportar_pendientes` | P04–P08, P13 · demo 6 | ✅ |
| 3. Vista PostgreSQL local + remota para la web | `api.vw_paciente_facturacion` | P02, P03 · demo 7 | ✅ |
| 4. Exportación hacia MongoDB para reportes agregados | `encolar_exportacion_masiva` + exportador | INT-04 · demo 8 | ✅ |
| 5. Analítica MongoDB por médico y tipo | `mongodb/04_agregaciones.js` | P09 (igual a PostgreSQL) · demo 9 | ✅ |

## Entregables

| Entregable | Dónde | Estado |
|---|---|---|
| Modelo de BD con segmentación horizontal y vertical | `docs/03_MODELO_DATOS.md`; implementado en los scripts; resumen en la sección 6 del mapa | ✅ |
| Scripts de creación y configuración de los tres motores | `postgresql/`, `sqlserver/`, `mongodb/`, `integracion/`, `docker/`, `compose.yaml`; instalador de un comando | ✅ (P18 desde cero) |
| Configuración FDW documentada (`postgresql.conf`, `pg_hba.conf`, `CREATE SERVER`) | `docker/postgres/*`, `integracion/01-02`, mapa de conexiones | ✅ |
| Perfiles y privilegios configurados | `integracion/01-02`, `postgresql/04-05`, `sqlserver/05`, `mongodb/03` | ✅ |
| Consultas de integración y transacciones distribuidas | `pruebas/`, `scripts/Demo-Video.ps1` | ✅ |
| Referencias bibliográficas | `documentacion/REFERENCIAS.md` | ⚠️ agregar fuentes de la biblioteca TEC si se usaron |
| Video de 5 a 8 minutos narrado | `video/GUION.md` + `scripts/Demo-Video.ps1` | ⚠️ **falta grabarlo** |
| Fuentes y documentación en Moodle | `git archive` de `main` cuando todo esté integrado | ⚠️ **falta subirlo** |

## Lo que todavía no está terminado (acciones del grupo)

1. **Capturas y video:** obtener evidencia visual auténtica de las
   conexiones, tres motores, cinco operaciones y permisos; grabar video
   narrado de 5–8 minutos con participación realmente acreditada.
2. **Coordinación docente:** confirmar plazo/hora efectiva en Moodle;
   aclarar aceptación del grupo de 3 y del despliegue lógico en una PC,
   y el alcance de cada integrante.
3. **Entrega:** preparar ZIP desde el `main` definitivo, revisar contenido,
   adjuntar evidencias y video, y subir a Moodle; **no entregado aún**.
4. **Bibliografía:** revisar referencias usadas y normas de cita/IA del curso.

## Limitaciones declaradas (no son incumplimientos)

- Distribución **lógica** en una PC, no física. El enunciado no exige varias máquinas; queda
  pendiente confirmarlo con el docente, como dice D-003.
- PostgreSQL → MongoDB es **consistencia eventual** con outbox, no ACID global.
- TLS sin CA verificada en FreeTDS; PostgreSQL y MongoDB sin TLS dentro de la red interna.
- `tds_fdw` lleva un parche local (D-040) porque, con la opción `query`, ignoraba el `WHERE`.
