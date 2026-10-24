# Informe técnico a ChatGPT — Joseph fase 4, tds_fdw

**Fecha:** 24/10/2026. **PR:** [#4](https://github.com/Pochonski/bases-ii-estudios-medicos/pull/4),
OPEN/DRAFT, base `feature/joseph-core-main-integration` (PR #3). Ningún PR se
aprobó ni fusionó en esta sesión; `main` no se modificó. Este informe distingue
la compatibilidad de un spike de la integración académica definitiva.

## Resumen y estado Git

Al comenzar, `main` estaba en `0a42732a3cfc87a8b3a955b4c71cd894a5221ce8`.
PR #1/#2 estaban MERGED, mientras PR #3 seguía OPEN/DRAFT con HEAD
`f46dd9bfab90d2bd6c010fe294c7921647f27869`; no había archivos ni PR
abiertos de Joyce. La rama `feature/joseph-tds-fdw-spike` se creó desde ese
HEAD sin cherry-pick de infraestructura ni cambios de `main`.

Commits de implementación: `e57de54` (spike/CI), `581b7f5` (diagnóstico),
`1c0367e` (parche local de tds_fdw), `e514ee7` (negativo por código de salida).
El commit documental y las pruebas finales se registran en la bitácora y
`docs/07_PRUEBAS.md` cuando concluyan.

## Archivos y arquitectura

| Ruta | Función |
|---|---|
| `pruebas/integracion/tds-spike.compose.yaml` | Proyecto aleatorio, red interna, secretos y volúmenes propios, sin puertos host. |
| `pruebas/integracion/01_sqlserver_spike.sql.template`, `02_sqlserver_cleanup.sql` | Base, vista, cuatro filas ficticias y login temporales; limpieza. |
| `pruebas/integracion/03_postgresql_role.sql`, `04_postgresql_assertions.sql` | Login PG propio y aserciones SQL remotas, tipos, filtro, orden y JOIN. |
| `pruebas/integracion/*.sh`, `scripts/Test-TdsFdwSpike.ps1` | Preparación, pruebas positivas/negativas, caída/recuperación y limpieza. |
| `docker/postgres/Dockerfile`, `docker/postgres/patches/tds-fdw-query-local-quals.patch` | Construcción reproducible de tds_fdw 2.0.5 fijado con corrección local para la opción `query`. |
| `.github/workflows/joseph-tds-fdw-spike.yml`, `.gitattributes` | CI Ubuntu real/Windows estático, LF del parche y fixtures. |
| `docs/00`, `04`, `05`, `06`, `07`, `10`, `11`; guía y este informe; evidencia | Estado, decisión D-039/D-040, seguridad, pruebas y traspaso. |

El SQL Server temporal contiene `dbo.facturacion_spike` y
`dbo.vw_estado_facturacion` con `id_paciente BIGINT`, `codigo_region CHAR(2)`,
`nombre_aseguradora NVARCHAR(100)`, `estado_cobertura NVARCHAR(20)`,
`estado_facturacion NVARCHAR(20)`, `total_facturado_crc DECIMAL(12,2)` y
`fecha_actualizacion DATETIMEOFFSET(0)`. PK del par en la tabla, vista con una
fila por par. `svc_pg_mssql_ro` recibe solo `SELECT` de la vista; la tabla base
y `INSERT` se deniegan. PostgreSQL crea `joseph_tds_spike_pg`, instala el
núcleo y ejecuta el script existente `integracion/01_fdw_sqlserver.sql`:
servidor `sqlserver_medico`, mapping propio hacia el login SQL Server y
`externo.ft_estado_facturacion` con fecha ISO-8601 convertida a `timestamptz`.
El login de consulta PG es `usr_fdw_pg_mssql`, sin mapping `PUBLIC` ni `SET ROLE`
administrativo como prueba. TDS se usa solo para lectura.

## Hallazgo real y corrección

La primera CI devolvió cuatro filas para una consulta `WHERE` que debía devolver
cero. La segunda imprimió las cuatro claves y `EXPLAIN`: el `Foreign Scan` no
tenía filtro, y el SQL remoto fijo tampoco WHERE. Esto coincide con el
[issue upstream #444](https://github.com/tds-fdw/tds_fdw/issues/444).
Con `query`, `tds_fdw` clasificaba las condiciones como remotas pero no las
agregaba al SQL fijo; también podía reclamar orden sin enviarlo. Un resultado
de paciente equivocado era posible. El parche local clasifica todas las
restricciones como locales y no ofrece rutas de orden/joins parametrizados para
tablas con `query`. No altera la opción `table`, la versión fijada, el objeto
remoto de Joyce ni el contrato de columnas. La CI corrigió `WHERE`, `ORDER BY`,
ausencia remota y JOIN; el plan ahora muestra `Filter` local. Este parche
requiere revisión técnica antes de reutilizar la imagen fuera del spike.

## Pruebas, comandos y evidencia

Comandos locales de lectura y validación: `git fetch/status/diff`, `gh pr
view/list`, `docker info`, `docker context show`, `wsl --status`, `Get-Service`,
`pwsh -NoProfile -File scripts/Test-TdsFdwSpike.ps1 -StaticOnly`,
`pwsh -NoProfile -File scripts/Test-TdsFdwSpike.ps1`, parser PowerShell y
`git diff --check`. En Windows 11 el estático PASÓ, pero el runtime no se
ejecutó: `com.docker.service` detenido y pipe `dockerDesktopLinuxEngine`
ausente. No se cambió WSL, Docker ni un volumen compartido.

La [CI verde de código e514ee7](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40103007250)
corrió en Ubuntu 22.04 (kernel `6.8.0-1064-azure`, Docker 28.0.4, Compose
2.38.2, PowerShell 7.6.6) y Windows Server 2022 estático. Head
`e514ee7f1c30240a67cf6af7b822e9ec2f52f7f4`, checkout
`dae6488981ca82f796a8f77cbd15b0091a69ec47`. Artifact
`joseph-tds-spike-real` descargado y revisado; extracto duradero en
`evidencias/registros/2026-10-24-joseph-tds-fdw-ci.txt`.

Consultas desde el login PG propio devolvieron cuatro filas SQL Server:
`1001/AL` con `Clínica Ñandú`, `12345.67`, UTC `2026-10-22 21:30:00`;
`2001/SJ` con `Seguro Público`, `0.01`; `3001/CA` con `9999999999.99`
y offset +02 convertido a UTC `10:00`; `5000000000/AL` prueba BIGINT fuera
de Int32. `1002/AL` devolvió cero filas remotas y persistió en el `LEFT JOIN`
con valores remotos nulos. El negativo SQL Server rechazó lectura de tabla e
INSERT. Al detener solo el SQL Server efímero, PG respondió `SELECT 1` y FDW
falló con código 1; tras `start`/healthcheck, la consulta remota volvió a
devolver cuatro filas. Limpieza de bases/login temporales confirmada. La
regresión de infraestructura debe revisarse por SHA en `docs/07_PRUEBAS.md`.

Las tres CI previas del spike quedaron rojas y se conservan como evidencia:
[40102260838](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40102260838)
detectó ausencia errónea; [40102446960](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40102446960)
aisló el bug `count=4`; [40102791877](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40102791877)
compiló el parche y pasó filtros/tipos/JOIN, pero el runner rechazó el texto
del error en la caída controlada. `e514ee7` conserva el criterio de fallo
FDW no cero y elimina solo esa clasificación textual.

## Dependencias y evaluación

**P01:** PARCIAL. Se probó una consulta FDW real contra SQL Server temporal,
incluidos tipos y JOIN, pero **no** la facturación definitiva. **P17:** PARCIAL.
`CREATE SERVER`, mapping, autenticación PG/SQL Server y permisos negativos
pasaron en el spike; la cuenta definitiva, TLS y otras rutas FDW siguen
pendientes. El gate general de conectores no está aprobado: Mongo FDW/BSON,
inserción, actualización, índice único, revisión y worker de Joyce no se
ejecutaron. Tampoco existe transacción global ni API de Armando en este PR.

Joyce debe entregar, sin que Joseph altere unilateralmente sus módulos:

1. Nombre de base y `dbo.vw_estado_facturacion`, con una fila única por
   `(id_paciente BIGINT, codigo_region CHAR(2))`.
2. `nombre_aseguradora` Unicode, `estado_cobertura` y
   `estado_facturacion` con longitudes/valores acordados,
   `total_facturado_crc DECIMAL(12,2)` y `fecha_actualizacion DATETIMEOFFSET`
   con precisión/offset explícitos.
3. `svc_pg_mssql_ro` o cuenta acordada con solo SELECT de la vista,
   sin SELECT/DML de tablas subyacentes; secreto por canal seguro.
4. Fixture ficticio con IDs compartidos, caso sin registro, cardinalidad y
   política de agregación de facturas; procedimiento que recalcula
   `resumen_facturacion` y prueba de reflejo remoto de su resultado.
5. Política TLS/CA y convenciones de collation/Unicode para producción.

**Riesgos:** alto: el bug upstream de filtros/orden requiere mantener y auditar
el parche hasta una corrección upstream; alto: P01/P17 finales dependen de
Joyce; medio: TLS exige validación de identidad y la caída remota produce
indisponibilidad explícita; medio: Windows local no tiene daemon estable; medio:
tipos/offset/precisión de la vista definitiva pueden diferir. Repetir el
manual Windows cuando el daemon responda y repetir todos los negativos con
objetos de Joyce antes de considerar integración. El PR #4 puede recibir
revisión técnica del spike, pero no habilita merge automático del PR #3/#4 ni
cierra toda la parte de Joseph.
