# Matriz de pruebas y aceptación

**Estado: aceptación funcional pendiente; ejecución estática parcial registrada al final.** Para cada prueba preservar: precondiciones, comandos exactos, base/motor, salida relevante, comparación con esperado, fecha, responsable y evidencia en `evidencias/`.

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

## Ejecución parcial — 22/10/2026, Joseph

| Prueba | Resultado local |
|---|---|
| Compose base y overlay, red, secretos, volúmenes y healthchecks | PASA validación estática |
| Sintaxis de tres scripts PowerShell | PASA |
| Inicializador repetido sin rotar secretos existentes | PASA |
| POSTGRES_DB vacío | PASA negativo: Compose rechaza |
| .env y tres secretos ignorados / git diff --check | PASA |
| Build Docker PG con FDW | NO EJECUTADO: comando falla antes de compilar, daemon ausente |
| P01 facturación real | BLOQUEADO POR DEPENDENCIA de Joyce |
| P12 PostgreSQL | Script preparado, NO EJECUTADO localmente |
| P14 particiones | PENDIENTE, todavía no hay DDL clínico |
| P17 FDW | SQL/config preparados; NO EJECUTADO ni login validado |
| P18 instalación vacía | Solo parte estática probada; arranque local NO EJECUTADO |
| Otras Pxx | PENDIENTES, conservan responsables |

Evidencia: evidencias/registros/2026-10-22-joseph-local.txt.
El workflow Ubuntu es una comprobación adicional; no acredita funcionamiento en Windows.

## Cierre verificado — 22/10/2026, Joseph

[CI 39747806912](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/39747806912)
PASA en SHA 89d0754, Ubuntu22/kernel 6.8.0-1070-azure:
build de tds_fdw/mongo_fdw, tres motores saludables, consultas autenticadas, CREATE EXTENSION/LOAD
y persistencia PostgreSQL tras reinicio (P12 parcial). No prueba Windows, consultas FDW remotas,
BSON/escritura, P01, P14 ni el outbox.
Evidencia: evidencias/registros/2026-10-22-joseph-ci-exito.txt.
Informe de auditoría: documentacion/INFORME_CHATGPT_JOSEPH_FASE1.md.
PR #1 permanece en borrador; main conserva 630cca6.

## Regresiones de auditoría — 22/10/2026, Joseph

| Caso | Windows local | CI corregida |
|---|---|---|
| H1 Everyone/Users explícitos en carpeta/archivos, DACL final y owner | PASA; sin impersonación | PASA Windows Server 2022 |
| Valores existentes / .env conservados, nuevo secreto, idempotencia | PASA | PASA Windows Server/Ubuntu |
| H2 selección base/overlay explícita y COMPOSE_* | PASA estático | PASA Ubuntu base/localhost |
| H3 ejemplo válido y .env operativo vacío | PASA negativo; archivo temporal, .env real intacto | PASA Ubuntu base/localhost |
| Puertos/ID/volumen y fila PG tras restart en base/localhost | NO EJECUTADO: daemon ausente | PASA Ubuntu base/localhost |
| Lectura de secretos por UID de cada motor | NO EJECUTADO | PASA Ubuntu base/localhost |

P12 solo cubre una fila PostgreSQL tras restart y bindings/volumen conservados.
No acredita recreación/restauración ni persistencia SQL Server/MongoDB.
CI previa confirmada: 39753627026 / 612d07d; no valida las correcciones nuevas.
Evidencia local: evidencias/registros/2026-10-22-joseph-auditoria-windows.txt.
P01/P17/BSON, autenticación propia y privilegios negativos siguen NO EJECUTADOS; gates abiertos.

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
