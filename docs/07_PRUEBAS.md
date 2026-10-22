# Matriz de pruebas y aceptación

**Estado: TODAS PLANIFICADAS / NO EJECUTADAS.** Para cada prueba preservar: precondiciones, comandos exactos, base/motor, salida relevante, comparación con esperado, fecha, responsable y evidencia en `evidencias/`.

| ID | Procedimiento previsto | Resultado esperado | Requisito |
|---|---|---|---|
| P01 | Desde PG, consultar `externo.ft_estado_facturacion` | Retorna registros SQL Server | INT-01 |
| P02 | Ejecutar `api.vw_paciente_facturacion` | Datos locales y facturación combinados, 1 fila por paciente | INT-01, INT-03 |
| P03 | Consultar paciente sin cobertura en SQL Server | Paciente persiste con `SIN_REGISTRO`; no duplica | INT-03 |
| P04 | Confirmar resultado y outbox PG en transacción | Resultado y evento PENDIENTE confirmados | INT-02 |
| P05 | Ejecutar exportador y verificar colección | Documento creado en MongoDB de resultado confirmado | INT-02, INT-04 |
| P06 | Modificar resultado, aumentar revisión y exportar | Mismo resumen actualizado, revisión mayor | INT-02 |
| P07 | Reprocesar mismo evento | No hay duplicados ni regresión de revisión | Robustez extra |
| P08 | Desconectar/reconectar MongoDB y reintentar | Evento recuperado, resultado intacto | Robustez extra |
| P09 | Ejecutar agregación de MongoDB por médico/tipo | Agrupaciones/cantidades correctas | INT-05 |
| P10 | Conectar con `usr_api_web` y `usr_api_mobile` | Solo vistas permitidas; resultados esperados | Roles externos |
| P11 | Intentar modificación prohibida con cuenta restringida | Error de permiso | Seguridad |
| P12 | Reiniciar contenedores tras guardar registros | Datos persistentes | Infraestructura |
| P13 | Ejecutar ROLLBACK de resultado/evento local | No se exporta evento revertido | INT-02/semántica |
| P14 | `EXPLAIN` y consulta particiones SJ/AL/CA | Prueba real de particionamiento horizontal | Segmentación horizontal |
| P15 | Reconstruir entidad SQL Server desde fragmentos | Recuperar columnas sin pérdida/duplicación | Segmentación vertical |
| P16 | Ejecutar procedimiento almacenado SQL Server | Resumen coherente y consultable | Procedimientos |
| P17 | Crear/mostrar `CREATE SERVER`, mappings, autenticación | Canales FDW documentados | Config FDW |
| P18 | Arranque desde entorno vacío con README | Instalación y pruebas reproducibles | Entrega |

### Escenarios de datos representativos

- Pacientes de las tres regiones, incluido paciente `1001 / AL` ficticio.
- Paciente con seguro vigente y factura pendiente, paciente sin cobertura externa, paciente con cobertura inactiva.
- Estudio de ultrasonido finalizado, revisión actualizada, estudio cancelado y resultado con rollback.
- Médico con varios tipos de estudio y dos sucursales para comprobar agrupación.

### Evidencias previstas (NO creadas)

`01_contenedores.png`, `02_particiones_pg.png`, `03_fragmentos_sql.png`, `04_conexion_mssql.png`, `05_vista_federada.png`, `06_exportacion_mongo.png`, `07_reporte_mongo.png`, `08_roles_permisos.png`, `09_recuperacion.png`; adicionalmente logs de comandos y pruebas. No crear capturas simuladas como si fueran resultados reales.

### Clasificación de fallos

- **Bloqueante**: cualquiera de INT-01 a INT-05 no funciona; no hay segmentación requerida o roles exigidos.
- **Importante**: incoherencia en IDs/datos, pérdida en reinicio, pruebas de privilegios fallidas.
- **Opcional**: dashboards avanzados, métricas adicionales, automatizaciones que no pide el profesor.

### Condición final

El proyecto solo pasa aceptación si los tres motores están conectados, las operaciones exigidas funcionan, y los resultados están probados y documentados. La documentación por sí sola **no sustituye** ejecución real.
