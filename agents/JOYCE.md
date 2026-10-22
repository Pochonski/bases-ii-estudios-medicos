# Agente de Joyce — SQL Server, MongoDB y sincronización

**Prioridad temporal:** fase inicial 22–25/10; ~40% del esfuerzo orientativo. Leer `../AGENTS.md` y contratos completos antes de actuar.

## Misión

Construir los datos externos y analíticos, demostrar fragmentación vertical reconstruible, exponer una vista consultable desde PostgreSQL y generar documentos MongoDB **tras confirmación** de resultados clínicos.

## Alcance posterior a autorización de implementar

### SQL Server
- Aseguradoras, convenios, paciente fragmentado por columnas (`paciente_integracion` y `paciente_cobertura`), facturas externas y resumen facturación.
- Clave común `(id_paciente,codigo_region)` y `JOIN` sin pérdida ni duplicación.
- Procedimiento almacenado que calcula resumen de facturación; `dbo.vw_estado_facturacion` con **una fila por paciente-región**.
- Usuario remoto restringido para `tds_fdw`; entrega a Joseph prueba del contrato SQL Server.

### MongoDB y exportación
- Colección `resumenes_estudios`, índice único en `id_estudio`, cuentas de servicio y pruebas de tipos BSON.
- Compilar/validar `mongo_fdw` con Joseph: lectura, inserción, actualización, `_id`, revisión y fechas; **no asumir** compatibilidad o UPSERT.
- Implementar la estrategia outbox de PostgreSQL: tras `COMMIT`, lectura de pendientes, exportación y confirmación, reintentos y no duplicación. Usar datos ficticios.
- Si FDW no sirve, documentar evidencia y solicitar aprobación explícita de integración intermedia; no sustituir silenciosamente.

## Entregables futuros

`sqlserver/01_base_tablas.sql` hasta `06_datos_prueba.sql`, `mongodb/01_colecciones.js`, `02_indices.js`, `integracion/02_fdw_mongodb.sql`, `integracion/sincronizacion/*`; evidencias P04–P08, P13/P15/P16.

## Dependencias

**De Joseph:** PostgreSQL accesible, claves/tabla outbox y dataset. **Para Joseph:** vista SQL Server estable y usuario lectura; **para Armando:** MongoDB con documentos correctamente sincronizados y nombres/tipos congelados.

## Gates

- P15 fragmentación vertical, P16 procedimiento y P01/P02 colaboración con Joseph.
- P05 documento real de un resultado confirmado, P06 actualización por revisión, P07 no duplicado, P08 recuperación; sin afirmar atomicidad global.
- Handoff del 25/10 apto para las consultas finales de Armando.

## Lo que NO debes hacer

No fabricar evidencias mediante inserciones manuales presentadas como exportación; no asignar conectores iniciales a Armando; no cambiar los contratos de pacientes/estudios sin revisar impactos PG.
