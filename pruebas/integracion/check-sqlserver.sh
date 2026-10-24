#!/usr/bin/env bash
set -euo pipefail
export SQLCMDPASSWORD
SQLCMDPASSWORD="$(cat /run/secrets/fdw_password)"
sqlcmd=(/opt/mssql-tools18/bin/sqlcmd -S localhost -U svc_pg_mssql_ro -d joseph_fdw_spike -C -b -f 65001 -h -1 -W)
"${sqlcmd[@]}" -Q "SET NOCOUNT ON; SELECT CAST(SERVERPROPERTY('ProductVersion') AS varchar(40)) AS sqlserver_version, CAST(SERVERPROPERTY('ProductLevel') AS varchar(40)) AS sqlserver_level;"
"${sqlcmd[@]}" -Q 'SET NOCOUNT ON; SELECT ORIGINAL_LOGIN() AS login_name, COUNT(*) AS rows_read FROM dbo.vw_estado_facturacion;'
if "${sqlcmd[@]}" -Q 'SELECT COUNT(*) FROM dbo.facturacion_spike;' >/dev/null 2>&1; then
  echo 'FAIL: cuenta limitada puede leer tabla base' >&2; exit 1
fi
if "${sqlcmd[@]}" -Q "INSERT dbo.facturacion_spike (id_paciente,codigo_region,nombre_aseguradora,estado_cobertura,estado_facturacion,total_facturado_crc,fecha_actualizacion) VALUES (9999,'SJ',N'Prueba',N'VIGENTE',N'PENDIENTE',1.00,SYSDATETIMEOFFSET());" >/dev/null 2>&1; then
  echo 'FAIL: cuenta limitada puede insertar' >&2; exit 1
fi
echo 'PASS SQL Server: SELECT vista como svc_pg_mssql_ro; tabla base e INSERT rechazados'
