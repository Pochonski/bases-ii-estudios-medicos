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

## Manual Windows y puerto efectivo — 22/10/2026, Joseph (D-034)

La CI 39759092391 sigue siendo evidencia de H1–H3 en el código anterior, pero su comprobación
de puertos H2 examinaba `HostConfig.PortBindings` (solicitud) y no
`NetworkSettings.Ports` ni conexiones al host. El primer arranque Windows reveló que la red
`internal: true` sola no activaba esos bindings, aunque los tres motores estaban saludables.
Se conserva ese fallo en el registro Windows.

| Prueba | Resultado Windows local después de agregar `port-gateway` |
|---|---|
| Build imagen PostgreSQL con tds_fdw/mongo_fdw | PASA; ambos artefactos cargan mediante `LOAD` |
| Compose base/overlay + H1/H3 + sintaxis | PASA; `.env` y secretos existentes conservados |
| Tres healthchecks y consultas autenticadas | PASA; PostgreSQL, SQL Server y MongoDB |
| Lectura de secretos por UID | PASA; usuarios postgres, SQL Server 10001:0, mongodb |
| Red y puertos localhost | PASA; motores solo en `medical-network` interna, gateway con tres bindings activos y sondas TCP Windows |
| Cliente Windows PostgreSQL/SQL Server | PASA; consultas autenticadas por 127.0.0.1 y puertos alternativos |
| Selección Compose incorrecta sin overlay | PASA negativo; rechaza el gateway existente antes de escribir marcador |
| P12 PostgreSQL | PASA **parcial**: fila sintética tras `restart`, mismo contenedor/volumen/gateway/puertos, marcador eliminado |
| P12 tres motores / recreación / restauración | NO EJECUTADAS |
| P01/P17 remoto y Mongo BSON/INSERT/UPDATE | BLOQUEADAS por objetos, cuentas, tipos y fixture de Joyce; gate abierto |

MongoDB autenticó dentro de su contenedor; solo se probó TCP desde Windows, no `mongosh`
cliente en Windows. El kernel efectivo Docker fue `6.18.33.2-microsoft-standard-WSL2`.
Pruebas de host y CI deben seguir distinguiéndose. Evidencia Windows y comandos:
`evidencias/registros/2026-10-22-joseph-despliegue-windows.txt`.

### CI del gateway verificada

[39807402214](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/39807402214)
terminó SUCCESS en head `0b5e507`: tres jobs, artifacts revisados. Base: sin puertos
publicados, P12 parcial PG. Overlay: tres puertos 127.0.0.1 activos y conexiones TCP del
runner, P12 parcial PG con gateway estable. Windows Server solo probó ACL. Checkout de merge
`533079c3c16a57f14b82729e0eb9d8f9093d0f31`. Evidencia:
`evidencias/registros/2026-10-22-joseph-gateway-ci.txt`.
Este PASS no cierra P01/P17 remotos, Mongo BSON ni P12 completo.

### Regresión menor del gateway — 22/10/2026, Joseph (D-035)

| Caso | Windows 11 local | CI Ubuntu22 localhost |
|---|---|---|
| Filtro workflow `docker/port-gateway/**` | Revisado en YAML | Filtro presente; el primer run se disparó con varios archivos modificados. NO PROBADO con cambio exclusivo de esa ruta. |
| HAProxy `/ready` y healthcheck Docker | PASA en estado normal tras recrear solo gateway; tres motores conservaron ID | PASA en overlay; el modo base no crea gateway |
| P12 parcial PostgreSQL con gateway actualizado | PASA: fila sintética tras `restart`, mismo ID/volumen/gateway/bindings, tabla eliminada | PASA base/localhost; marcador eliminado |
| Backend PostgreSQL detenido; frontend TCP aún abierto; gateway no saludable; recuperación con mismo volumen/puertos | NO EJECUTADA: la regresión impide afectar el proyecto local | PASS con `stop/start` en proyecto efímero, tras FALLA informativa con `pause` en 39811585204 |
| Exposición host | `NetworkSettings.Ports` del gateway: solo 127.0.0.1:11433/15432/37017; endpoint 8404 no publicado | PASS: solo 127.0.0.1:1433/5432/27017; base sin puertos |

La [CI 39812197292](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/39812197292)
terminó SUCCESS en `ee5ce970e61428b5c68440d2ce3b39f0f39b500d`, checkout de merge
`ed428667f13fce9a717c4cf198cb43805cb7ce25`: tres jobs y artifacts descargados.
La prueba negativa no acredita persistencia nueva ni consultas FDW. El check TCP de HAProxy
no detectó `pause` porque el socket del backend quedó abierto; sí detecta `stop`.
P12 conserva el alcance parcial documentado arriba. Evidencia durable:
`evidencias/registros/2026-10-22-joseph-gateway-backend-ci.txt`.
Al cierre, Docker Desktop dejó de exponer el daemon Windows de nuevo; el PASS local
corresponde a la ejecución anterior a esa pérdida de disponibilidad, no a una comprobación
del estado actual. La CI Ubuntu no sustituye la estabilidad del host Windows.

## Fase 2 PostgreSQL aislada — 22/10/2026, Joseph

**Precondición:** base temporal vacía PostgreSQL 16 en proyecto Compose base; los scripts
se ejecutan en orden 01/02/03/06 con `psql -v ON_ERROR_STOP=1`. La ejecución CI usa
`./scripts/Test-PostgresqlCore.ps1 -Repeat 2 -IncludePersistence`; crea y elimina dos
bases sintéticas, conserva el volumen. Guía: `documentacion/JOSEPH_FASE2_POSTGRESQL.md`.

| Caso | Windows local | CI Ubuntu22 [39878097819](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/39878097819), código `295bf32` |
|---|---|---|
| DDL de 12 tablas, 3 particiones, fixture exacto | NO EJECUTADO: daemon ausente | PASA dos veces, desde base vacía |
| Inserción válida entre regiones; FK/CHECK/UNIQUE inválidos | NO EJECUTADO | PASA; errores esperados capturados y ROLLBACK sin filas |
| P14 `tableoid` y `EXPLAIN` | NO EJECUTADO | PASA: SJ/AL/CA = 10/10/10; plan solo `pacientes_al`; 1001/AL atendido en SJ |
| P04 local: resultado y evento en mismo COMMIT | NO EJECUTADO | PASA; ambos visibles; MongoDB NO EJECUTADO |
| P13 local: resultado/evento revertidos | NO EJECUTADO | PASA; filas ausentes, estudio sin cambio; exportación NO EJECUTADA |
| P12 registros clínicos PG tras restart | NO EJECUTADO | PASA parcialmente, mismo contenedor y volumen; no recreación/restauración/otros motores |
| P18 instalación del módulo desde base vacía | NO EJECUTADO | PASA dos instalaciones del módulo; P18 del sistema completo PENDIENTE |

La [regresión 39878319168](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/39878319168)
también PASÓ en `502f5fa`: PostgreSQL 16.15, dos bases vacías y dos restart;
los marcadores de cada aserción constan en el artifact `joseph-postgresql-core`.
Evidencia versionada: `evidencias/registros/2026-10-22-joseph-postgresql-core-ci.txt`.
P01/P05–P11/P15–P17 y aceptación global permanecen pendientes o dependen de Joyce/Armando.

## Fase 3 — consolidación hacia main (23/10/2026, Joseph)

El PR #3 parte de `main` (`0a42732`) y contiene el mismo modelo/fixture del PR #2
sin cambios de DDL. La CI del núcleo escucha ahora la base `main`. La prueba
controlada `SELECT` a una tabla inexistente usa `ON_ERROR_STOP=1` y comprueba que
`Invoke-ProjectCompose` rechaza el código no cero; cualquier error SQL no capturado
en el runner principal termina el job como fallido.

| Caso | Windows 11 local, proyecto aislado `joseph-core-pr3-local` | CI PR #3 |
|---|---|---|
| Instalación desde dos bases vacías/fixture | PASA, dos bases sintéticas creadas y eliminadas | PASA en [40028827502](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40028827502), head `ae3f1b9` |
| Integridad, identidad compuesta, CHECK/UNIQUE y válidos/inválidos | PASA en ambas bases | PASA en ambas bases |
| P14 `tableoid` y `EXPLAIN` | PASA: 10/10/10, plan solo `pacientes_al`, paciente 1001/AL atendido en SJ | PASA: 10/10/10 y plan solo `pacientes_al` |
| P04/P13 locales | PASAN COMMIT y ROLLBACK de resultado+evento sintéticos | PASAN; sin MongoDB |
| P12 parcial clínico PG | PASA tras dos restart del contenedor aislado, mismo volumen/ID; volumen conservado tras `down` sin `-v` | PASA dos restart; no recreación/restauración |
| Proyecto compartido | PASA: IDs de sus cuatro contenedores idénticos antes/después | No aplica |
| Error SQL controlado | NO EJECUTADO localmente | Primer run [40028582907](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40028582907) FALLÓ tras detectar correctamente el error: `LASTEXITCODE=1` residual; `ae3f1b9` lo corrigió y `sql-error.txt` registra PASS en [40028827502](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40028827502) |
| Infraestructura heredada | Sin cambio; Compose estático aislado PASA | [40028827437](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40028827437) SUCCESS, tres jobs (Ubuntu base/localhost y Windows ACL) en `ae3f1b9` |

En `6e9d1bb` se reforzó el negativo SQL: la consulta inexistente termina con
código 1 en su **propio paso** de Actions, configurado como excepción esperada
`continue-on-error`; el siguiente paso exige `steps.sql_invalido.outcome=failure`.
El [run 40029751371](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40029751371)
PASÓ y `sql-error.txt` registra esa aserción; el runner clínico posterior pasó.
Los SQL de instalación/pruebas carecen de `continue-on-error` y detienen el job
si fallan. La excepción no se aplica a otros pasos ni a despliegues reales.
La [regresión de infraestructura del mismo head](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40029751368)
PASÓ tres jobs; ambos workflows se ejecutarán de nuevo en el cierre documental.

Windows: Docker Engine 29.8.0, kernel efectivo
`6.18.33.2-microsoft-standard-WSL2`, PostgreSQL 16.15. El proyecto de prueba
usó red interna propia y ningún puerto host; se retiraron solo sus contenedores/red.
No se borraron volúmenes ni se reinició el PostgreSQL compartido. FDW remoto,
BSON/escrituras MongoDB, autenticación propia y sincronización siguen NO EJECUTADOS.
Evidencia detallada: `evidencias/registros/2026-10-23-joseph-core-main-ci.txt`.
Ambos workflows deben repetirse o verificarse después del commit documental final.

## Fase 4 — tds_fdw contra SQL Server temporal (24/10/2026, Joseph)

**Configuración:** [guía reproducible](../documentacion/JOSEPH_FASE4_TDS_FDW.md).
El runner usa un proyecto Compose con nombre aleatorio, red interna, cero puertos
host y volúmenes propios; crea y elimina solo `joseph_fdw_spike` y
`joseph_tds_spike_pg`. La vista y el login SQL Server están exclusivamente en
`pruebas/integracion/`; nunca sustituyen los de Joyce.

| Caso | Windows 11 local | CI Ubuntu22 / Windows Server 2022 |
|---|---|---|
| Estructura Compose, secretos temporales, aislamiento | PASA `-StaticOnly` | Windows Server estático PASÓ en [40103007250](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40103007250). |
| SELECT remoto con login propio, 4 filas, tipos/Unicode/fecha | NO EJECUTADO: daemon `dockerDesktopLinuxEngine` ausente | PASA en `e514ee7`: cuatro filas SQL Server, Unicode, DECIMAL, offsets UTC y BIGINT > Int32. |
| SELECT vista permitido; tabla base/INSERT rechazados | NO EJECUTADO | PASA con `svc_pg_mssql_ro`, sin `sa` para consulta FDW. |
| WHERE/ORDER BY y LEFT JOIN sin fila remota | NO EJECUTADO | PASA tras D-040: `1002/AL` remoto 0; JOIN conserva paciente; plan muestra `Filter` local; orden DESC comprobado. |
| SQL Server detenido, error remoto y recuperación | NO EJECUTADO | PASA: PG local `SELECT 1`, FDW código 1 con SQL Server detenido; tras `start`/healthcheck, cuatro filas otra vez. |
| Regresión infraestructura | NO EJECUTADO runtime | [40103007202](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40103007202) PASÓ tres jobs en mismo head `e514ee7`: ACL Windows y Ubuntu base/localhost. |
| Objetos definitivos de Joyce / P01 y P17 finales | BLOQUEADO POR DEPENDENCIA | BLOQUEADO POR DEPENDENCIA: no hay base/vista/cuenta/fixture reales de Joyce. |
| Mongo FDW/BSON/escrituras | NO EJECUTADO | NO EJECUTADO; gate separado. |

La primera ejecución de la CI en `e57de54` [40102260838](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40102260838)
**FALLÓ**, como debe suceder ante SQL no esperado. Su log confirma 4 filas
desde SQL Server y `usr_fdw_pg_mssql` como login PostgreSQL, seguido de
`ERROR: Fila remota inesperada`; `finally` eliminó bases, login, contenedores,
red y los dos volúmenes **de ese proyecto nuevo**. `581b7f5` agrega listado de
claves, conteo filtrado y `EXPLAIN VERBOSE` para diagnosticar sin ocultar el fallo.
La [segunda ejecución 40102446960](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40102446960)
también FALLÓ pero aisló que `WHERE 1002/AL` devolvía `count=4` y no existía
filtro en el plan, coincidiendo con el issue upstream #444. El commit `1c0367e`
aplicó parche local; en la [tercera CI 40102791877](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40102791877)
el `Foreign Scan` mostró `Filter`, pasaron tipos/orden/JOIN y el SQL Server
detenido provocó código no cero mientras PG local respondía. El job FALLÓ porque
el runner exigía palabras inglesas específicas en el error; `e514ee7` quitó esa
clasificación textual, sin permitir código cero. La [cuarta CI 40103007250](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40103007250)
PASÓ dos jobs: caída, código no cero, recuperación y limpieza, además de
tipos/seguridad; artifact descargado en
`evidencias/registros/2026-10-24-joseph-tds-fdw-ci.txt`. La regresión de
infraestructura [40103007202](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40103007202)
PASÓ sus tres jobs en el mismo head `e514ee7`. Los cambios finales de
instrumentación y documentos tendrán CI propia: no atribuir estos runs a un
SHA posterior. **P01/P17 definitivos siguen pendientes de Joyce** y Mongo
FDW/BSON no se ejecutó.

La [CI 40103357010](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40103357010)
del SHA `f3b6327` quedó ROJA aunque las pruebas funcionales, versiones
efectivas, caída/recuperación y limpieza concluyeron. El último
`docker volume inspect` devolvió 1 por ausencia esperada, y PowerShell propagó
ese estado residual al paso. La corrección posterior pone `LASTEXITCODE=0`
solo tras verificar que no queda ningún volumen ni contenedor; cualquier
error real de limpieza lanza excepción. Requiere regresión del nuevo SHA.

**Cierre CI del HEAD de código `8f25634`:** [FDW 40103545333](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40103545333)
SUCCESS en Ubuntu real y Windows Server estático; [infraestructura 40103545352](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40103545352)
SUCCESS en tres jobs (ACL, base, localhost). Artifact descargado: head
`8f256341af2ee0a27bc3ea971802ac072dc48002`, checkout
`ed0b178c7f0d568072e11c2c2c137630b710412c`, PostgreSQL 16.15,
`tds_fdw` 2.0.5 con parche, SQL Server 16.0.4305.5 RTM, FreeTDS
1.3.17+ds-2, Docker 28.0.4, Compose 2.38.2, PowerShell 7.6.6 y kernel
Ubuntu `6.8.0-1064-azure`. El runner imprimió PASS de ausencia de
contenedores/volúmenes del proyecto temporal; artifact sin prefijo de
contraseñas. Extracto versionado en `evidencias/registros/2026-10-24-joseph-tds-fdw-ci.txt`.
La CI del commit documental posterior se verificará por separado.

## Ejecución Joyce — 25/10/2026, Windows 11 local (D-041)

Docker 29.9.2, kernel WSL `6.6.87.2-microsoft-standard-WSL2`, rama `feature/joyce-sqlserver-mongodb`
sobre `5c89c21` + archivos de Joyce. Ejecutado con `scripts/Test-JoyceModulos.ps1`; repetido tres
veces con el mismo resultado. Evidencia: `evidencias/registros/2026-10-25-joyce-pruebas-local.txt`.

| Prueba | Resultado |
|---|---|
| P15 fragmentación vertical | PASA: 24/24 filas, reconstrucción 24, 0 huérfanos |
| P16 procedimiento | PASA: resumen = facturas válidas; vista 1 fila/clave; registro de factura cambia la vista; negativo 51010 |
| Permisos `svc_pg_mssql_ro` | PASA: SELECT vista; tabla base, INSERT y EXECUTE denegados (229) |
| P01 tds_fdw real | PASA con login `usr_fdw_pg_mssql`: 24 filas remotas únicas, LEFT JOIN 30/24/6, 1001/AL PENDIENTE 23500.00, filtro por clave ausente sin filas |
| P16b SQL Server → PG | PASA: factura confirmada visible por FDW; retirada y restaurada |
| P13 ROLLBACK | PASA: sin resultado, evento ni documento |
| P04 | PASA: resultado + evento PENDIENTE en una transacción |
| P05 mongo_fdw | PASA: documento insertado por `usr_fdw_pg_mongo`; tipos long/int/date/objectId |
| P06 | PASA: mismo `_id`, revisión 2 |
| P07 | PASA: reproceso de revisión 1 → SIN_CAMBIOS, un documento |
| Permisos `usr_fdw_pg_mongo` | PASA: pacientes, DELETE foráneo y UPDATE de resultados denegados |
| P08 caída MongoDB | PASA: COMMIT en PG, evento ERROR (intentos 1), recuperado al reiniciar (PROCESADO, intentos 2) |
| INT-04 exportación masiva | PASA: 32 resultados PG = 32 documentos MongoDB, 0 eventos sin procesar |
| P09 agregación médico × tipo | Solo vista previa; la prueba formal es de Armando |
| CI de estos módulos | NO EJECUTADA |

### Módulos de Armando implementados por Joyce (D-042) — misma ejecución

| Prueba | Resultado |
|---|---|
| P02 vista federada | PASA: `usr_api_web` lee `api.vw_paciente_facturacion`; 30 pacientes, 30 claves, 1001/AL PENDIENTE 23500.00 |
| P03 sin cobertura | PASA: 6 pacientes `SIN_REGISTRO` (incluye 1009/AL), sin duplicados |
| P09 médico × tipo | PASA: 12 grupos idénticos entre MongoDB y `GROUP BY` en PostgreSQL; validaciones de unicidad, tipos y región de atención |
| P10 roles externos | PASA: web lee facturación + agenda; móvil solo `vw_citas_mobile`; cada uno denegado en lo ajeno |
| P11 escrituras | PASA: UPDATE en vistas (55000), DELETE en tabla base (42501), CREATE (25006) rechazados |
| Autenticación | PASA: contraseña incorrecta rechazada por SCRAM |

### Verificación de entrega (D-043) — Windows 11 local

| Prueba | Resultado |
|---|---|
| P18 desde entorno vacío | PASA: `down --volumes`, instalación automática y suite completa sin intervención |
| P12 tres motores | PASA: tras `restart`, mismos contenedores y conteos (PG 30 pacientes/32 resultados, SQL Server 24 pacientes/11 facturas, MongoDB 32 resúmenes/12 indicadores); FDW SQL Server responde 24 filas |
| P17 configuración FDW | PASA: servidores, mappings (sin contraseña), tablas foráneas, perfiles, `pg_hba`, permisos SQL Server y MongoDB volcados desde los catálogos |
| P14 particiones (EXPLAIN) | Mostrado en la demo (pruning a `pacientes_ca`); la prueba formal es de Joseph |

## Endurecimiento propuesto del PR #5 — 26/10/2026, Joseph (D-045)

La tabla del 25/10 registra la ejecución histórica de Joyce; aquella P18 **sí** usó
`down --volumes` sobre `estudios-medicos`. No se atribuye a esa evidencia la seguridad
del nuevo procedimiento.

| Caso del nuevo código | Estado Windows local | Evidencia / límite |
|---|---|---|
| P18 aislamiento de nombre, red, 4 volúmenes, 3 secretos, cero puertos | PROBADO estático | `Test-Entrega.ps1 -StaticOnly` pasa `docker compose config`; no crea motores |
| Suite directa fuera de P18 | PROBADO negativo | `Test-JoyceModulos.ps1` termina con código 1 antes de borrar filas |
| Sintaxis de scripts editados y whitespace | PROBADO | parser PowerShell: 0 errores; `git diff --check`: código 0 |
| P18 real en Docker y limpieza de recursos | NO EJECUTADO local | Docker Engine no disponible: falta `dockerDesktopLinuxEngine`; CI pendiente |
| P05 BSON ObjectId/Int64/Int32/Date, UNIQUE, P06 `_id`, cuenta Mongo | IMPLEMENTADO, NO PROBADO en nuevo SHA | Nuevas aserciones agregadas; CI pendiente |
| P12 tres motores, P01–P17, INT-04 en proyecto aislado | NO EJECUTADO en nuevo SHA | Conservar los PASS históricos por separado; esperar CI |

Comandos exactos iniciales: `docker info --format '{{.ServerVersion}} {{.KernelVersion}}'`,
`pwsh -NoProfile -File scripts/Test-Entrega.ps1 -StaticOnly`,
`pwsh -NoProfile -File scripts/Test-JoyceModulos.ps1`, parser de cinco scripts y
`git diff --check`. El runtime de Windows no se infiere de Ubuntu CI.

**Primera CI del PR #7:** [40278085052](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40278085052)
FALLÓ en `779864d` antes de cargar el fixture: el conteo SQL Server incluyó una línea
informativa y el parseo la trató como datos. El proyecto `joyce-p18-a0eb09ce6985`
creó y retiró exclusivamente sus contenedores, red y cuatro volúmenes; la suite
P01–P17 NO SE EJECUTÓ en ese run. El parseo corregido requiere CI nueva.

La regresión TDS nueva usa `table_name` en una vista temporal separada y luego
agrega 2000 filas ficticias al spike para medir EXPLAIN ANALYZE y estimar bytes de
columnas remotas. **Estado: IMPLEMENTADA, NO PROBADA** hasta su CI del SHA nuevo.

**CI `285506a`:** infraestructura (3 jobs) y núcleo PostgreSQL PASAN;
[módulos 40278430083](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40278430083)
FALLA después de P07: el nuevo test de cuenta MongoDB requiere diagnóstico
detallado. P01/P04–P07, BSON ObjectId/Int64/Int32/Date e índice único sí
imprimieron PASS, pero la suite global NO PASÓ y P08–P18 no se acreditan en
este SHA. [TDS 40278430129](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40278430129)
FALLA en aserción compuesta de `table_name`; su plan sí mostró SQL remoto con
`WHERE` enviado. Se separan los predicados para identificar la discrepancia.
Ambos runners retiraron sus recursos efímeros; no se reetiquetan como éxitos.

En `958ca01`, [TDS 40278766277](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40278766277)
confirmó una discrepancia del modo **convencional**: lectura de `12345.67`
correcta, `WHERE total_facturado_crc = 12345.67` sin fila. El modo contractual
`query` no falla. El test ahora registra el plan y la sonda como hallazgo;
`table_name` con filtro de monto **NO QUEDA APROBADO**. La suite [40278766324](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40278766324)
pasó P01/P04–P07 y BSON/índice; el permiso negativo MongoDB sí fue rechazado
con código 13, pero la prueba esperaba respuesta en vez de excepción. La prueba
se corrige para comprobar el código explícitamente. P08–P18 siguen sin PASS en
esa ejecución.

La próxima CI también debe verificar la instalación normal repetida con una factura
centinela (`99971`, ₡6789,12) que se conserva, el rechazo de `-LoadInitialData`
con tablas pobladas, los tres valores centinela de P12 y la retirada de la etiqueta
de imagen efímera. Esos casos son **NO EJECUTADOS en el SHA documental anterior**.

**CI `fad6c94` — [suite integrada 40279657529](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40279657529): PASA.**
El artifact `joyce-modulos-evidencia` identifica HEAD `fad6c94494a9e3b1c9b962d014657fbcf7786591`,
checkout merge `5126643347aeb6ea2013182f38043695db5daac3`, Docker 28.0.4 y
kernel `6.8.0-1064-azure`. P18 usó `joyce-p18-ce6141867e95` y retiró sus
recursos. La suite P01–P11, P13–P16 e INT-04 terminó con `RESULTADO: PASA`;
P12 comparó 11 conteos/valores antes y después de `restart`, incluidos revisión
PostgreSQL 2, monto SQL Server 1.500.000 centavos y revisión MongoDB 2, y el
FDW SQL Server respondió después. La instalación ordinaria conservó factura
centinela y rechazó tanto `-LoadInitialData` como ejecución directa del fixture
SQL sobre tablas pobladas. El patrón de secretos generados no apareció en el
artifact. P17 imprimió configuración y permisos; la autenticación propia y
los negativos se verificaron en la suite, no se probó TLS con CA.

[Infraestructura 40279657494](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40279657494),
[núcleo 40279657479](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40279657479) y
[TDS 40279657460](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40279657460)
también PASAN en ese HEAD. La comprobación Windows de permisos fue en runner;
Docker Desktop de la PC de Joseph sigue sin daemon. La protección adicional
de bloqueo transaccional en el fixture SQL Server se incorpora en un commit
posterior y requiere su propio run de CI.

**CI final de código `0189e58`:** [módulos 40280158117](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40280158117)
PASÓ con el bloqueo SQL incluido. Artifact: HEAD
`0189e58dd741179143abd857408fa8b690cf15eb`, checkout merge
`eff53241f595ee688c8a14784b3bcab699d0d31e`; proyecto
`joyce-p18-0ed71df6a88d`, Docker 28.0.4, kernel `6.8.0-1064-azure`.
P18, P01–P17 e INT-04 imprimieron PASS; tras `restart`, los 11 valores fueron
idénticos y la limpieza retiró recursos efímeros. La instalación normal conservó
la factura centinela y el fixture directo fue rechazado. Artifact sin patrón
de secreto generado. [Infraestructura 40280158123](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40280158123),
[núcleo 40280158116](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40280158116) y
[TDS 40280158198](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40280158198)
corresponden al mismo HEAD y PASARON sus siete trabajos. La próxima modificación
es documental y requiere su propia CI antes de autorizar integración.
