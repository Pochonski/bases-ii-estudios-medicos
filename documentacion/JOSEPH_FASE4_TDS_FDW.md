# Joseph fase 4: spike aislado PostgreSQL → SQL Server

**Fecha:** 24/10/2026. **Responsable:** Joseph. **Alcance:** comprobar `tds_fdw`
2.0.5 contra SQL Server 2022 con objetos **temporales**, sin implementar facturación
de Joyce ni vistas API de Armando. PR #4 se apila sobre PR #3 mientras éste siga
sin fusionar. La base y el login de esta guía **no son objetos definitivos**.

## Requisitos y ejecución

En Windows 11: Docker Desktop con motor Linux/WSL2 disponible, `docker compose`,
PowerShell 7 y recursos para PostgreSQL/SQL Server (aprox. 4 GiB de límite combinado).
En CI se ejecuta en Ubuntu 22.04 y Windows Server 2022 solo valida configuración.

Desde la raíz del repositorio:

```powershell
pwsh -NoProfile -File ./scripts/Test-TdsFdwSpike.ps1 -StaticOnly
pwsh -NoProfile -File ./scripts/Test-TdsFdwSpike.ps1
```

El runner genera `.tmp/tds-spike-root/.env` y cinco contraseñas temporales
aleatorias, corrige sus ACL con `Initialize-Local.ps1` y no muestra valores. Usa
`compose.yaml` más `pruebas/integracion/tds-spike.compose.yaml`, un nombre aleatorio
`joseph-tds-*`, red `internal: true`, volúmenes propios y **cero puertos host**.
Antes de arrancar comprueba que no existen contenedores ni volúmenes de ese nombre.
Los servicios compartidos y sus volúmenes no se detienen ni se borran. En `finally`
elimina las dos bases y el login temporales y retira **solo** los volúmenes recién
creados por ese proyecto único. Si falla la limpieza, se emite advertencia para
inspección manual; no ejecutar comandos de borrado sobre el proyecto compartido.

El script de SQL Server está exclusivamente en `pruebas/integracion/` y crea
`joseph_fdw_spike`, `dbo.facturacion_spike`, `dbo.vw_estado_facturacion` y
`svc_pg_mssql_ro`. La cuenta recibe `SELECT` sobre la vista y no sobre la tabla.
Cuatro filas ficticias prueban la clave compuesta, Unicode, `BIGINT` mayor que
Int32, `DECIMAL(12,2)` y `DATETIMEOFFSET` con offsets distintos. PostgreSQL crea
`joseph_tds_spike_pg` desde `template0`, instala el núcleo 01/02/03/06 y agrega
un paciente sintético del spike con ID `5000000000` a la partición AL.
`integracion/01_fdw_sqlserver.sql` configura la tabla foránea real; el runner
habilita un login PostgreSQL propio **solo en la base de prueba**. Este login
ejecuta las consultas, sin `SET ROLE` administrativo.

El resultado esperado incluye cuatro filas remotas, `1001/AL` con aseguradora
`Clínica Ñandú`, monto `12345.67` y UTC `2026-10-22 21:30:00`, y
`5000000000/AL` con monto `18.25`. El paciente `1002/AL` permanece en el
`LEFT JOIN` con columnas remotas nulas. Se rechazan lectura directa de la tabla
SQL Server e `INSERT` con la cuenta limitada. Se detiene solo el SQL Server del
proyecto efímero: PostgreSQL local debe continuar respondiendo y la consulta
FDW fallar; tras `start` y healthcheck, la consulta debe recuperarse.

Una falla SQL no esperada hace fallar el runner y el job. `CREATE EXTENSION`
por sí solo no acredita consulta remota. Los artifacts de GitHub Actions registran
SHA de head, checkout, versiones, consultas y marcadores depurados durante 14 días.

## Límite contractual y entrega requerida de Joyce

Para P01/P17 definitivos se requiere: nombre real de base SQL Server, vista
`dbo.vw_estado_facturacion` con **una fila por `(id_paciente BIGINT,
codigo_region CHAR(2))`**, y estas columnas/tipos: `nombre_aseguradora`
NVARCHAR o VARCHAR Unicode compatible; `estado_cobertura` y
`estado_facturacion` texto con estados acordados; `total_facturado_crc`
DECIMAL(12,2); `fecha_actualizacion` DATETIMEOFFSET con política UTC/offset
documentada. Se necesita `svc_pg_mssql_ro` u otra cuenta acordada con `SELECT`
solo sobre la vista, sin lectura DML de tablas base; secreto entregado por canal
seguro, nunca en Git. Joyce debe entregar fixture ficticio con claves del núcleo,
la política de facturas agregadas/ausencia de registro y el procedimiento de
recalcular resumen, para comprobar que la lectura FDW refleja su resultado.

P17 debe repetir login propio, permisos positivos y negativos contra **esa** vista
y cuenta. La ruta definitiva de `api.vw_paciente_facturacion` pertenece a Armando.
La falla remota aquí es un error explícito, no una cobertura inventada. El
`LEFT JOIN` directo de prueba no cambia el contrato API.

## Límites conocidos

FreeTDS está configurado con `encryption=require`; falta validar identidad del
certificado/CA en el despliegue definitivo. La conversión ISO-8601 de
`DATETIMEOFFSET` a `timestamptz` se prueba con offsets del fixture, pero formatos,
escala temporal y collation de la vista definitiva requieren repetición con Joyce.
El parche de `tds_fdw` fuerza filtro/orden local para la opción `query`: esto
puede transferir todas las filas de la vista a PostgreSQL antes de filtrar.
Medir cardinalidad/rendimiento con Joyce y revisar una solución upstream.
No se prueba escritura por TDS, no se prueba MongoDB ni sincronización global.
Windows local solo puede acreditar el runtime cuando Docker Desktop vuelva a
exponer el daemon Linux; una CI Ubuntu verde no demuestra eso.

## Regresión adicional de auditoría — 26/10/2026

El mismo proyecto aislado ahora crea una vista **solo de prueba** para el modo
convencional `schema_name`/`table_name` y comprueba filtros, Unicode y DECIMAL sin
alterar la vista de Joyce. Tras las pruebas originales agrega 2000 filas ficticias
en la base temporal; consulta ambas rutas con `EXPLAIN (ANALYZE, VERBOSE, BUFFERS)`
y registra tiempo y cardinalidad. SQL Server calcula una suma de `DATALENGTH` de
las columnas como **estimación inferior** de bytes, sin atribuirla al tráfico TDS
real. El modo `query` conserva filtro local para corrección, con posible coste de
leer la vista entera. Ejecutar:

```powershell
pwsh -NoProfile -File ./scripts/Test-TdsFdwSpike.ps1
```

Este cambio se probará en la CI del PR de endurecimiento; no se declara aprobado
por los runs anteriores. El volumen de 2004 filas es una muestra académica, no
una predicción de rendimiento en producción.
