\set ON_ERROR_STOP on
\set ECHO none
-- Ejecutar una sola vez con psql como administrador, cuando Joyce entregue la vista/usuario.
-- mssql_database es parámetro explícito; no se inventa el nombre de base de Joyce.
\if :{?mssql_database}
\else
  \echo 'Falta -v mssql_database=<base entregada por Joyce>'
  SELECT 1 / 0; -- ON_ERROR_STOP termina con código 3 antes de modificar objetos.
\endif
\getenv fdw_password FDW_MSSQL_PASSWORD
\if :{?fdw_password}
\else
  \echo 'Falta FDW_MSSQL_PASSWORD en el entorno del proceso psql'
  SELECT 1 / 0; -- ON_ERROR_STOP termina con código 3 antes de modificar objetos.
\endif
BEGIN;
SET LOCAL log_statement = 'none';
SET LOCAL log_min_error_statement = 'panic';
SET LOCAL log_min_duration_statement = -1;
CREATE SCHEMA IF NOT EXISTS externo;
REVOKE ALL ON SCHEMA externo FROM PUBLIC;
-- Perfil preparado; habilitar LOGIN con contraseña propia después de revisar privilegios.
CREATE ROLE usr_fdw_pg_mssql NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION;
CREATE SERVER sqlserver_medico FOREIGN DATA WRAPPER tds_fdw
  OPTIONS (servername 'sqlserver', database :'mssql_database',
           tds_version '7.4', sqlserver_ansi_mode 'true');
CREATE USER MAPPING FOR usr_fdw_pg_mssql SERVER sqlserver_medico
  OPTIONS (username 'svc_pg_mssql_ro', password :'fdw_password');
-- Proyección de fecha como ISO-8601 para evitar depender de DATETIMEOFFSET en DB-Library.
-- Los datos siguen viniendo exclusivamente de dbo.vw_estado_facturacion.
CREATE FOREIGN TABLE externo.ft_estado_facturacion (
  id_paciente bigint,
  codigo_region char(2),
  nombre_aseguradora text,
  estado_cobertura text,
  estado_facturacion text,
  total_facturado_crc numeric(12,2),
  fecha_actualizacion timestamptz
) SERVER sqlserver_medico OPTIONS (
  query 'SELECT id_paciente, codigo_region, nombre_aseguradora, estado_cobertura, estado_facturacion, total_facturado_crc, CONVERT(varchar(40), fecha_actualizacion, 127) AS fecha_actualizacion FROM dbo.vw_estado_facturacion',
  match_column_names 'true',
  use_remote_estimate 'false'
);
REVOKE ALL ON FOREIGN SERVER sqlserver_medico FROM PUBLIC;
REVOKE ALL ON externo.ft_estado_facturacion FROM PUBLIC;
GRANT USAGE ON SCHEMA externo TO usr_fdw_pg_mssql;
GRANT USAGE ON FOREIGN SERVER sqlserver_medico TO usr_fdw_pg_mssql;
GRANT SELECT ON externo.ft_estado_facturacion TO usr_fdw_pg_mssql;
COMMIT;
\unset fdw_password
-- No CREATE de objetos SQL Server; no vistas API; no datos locales que sustituyan facturación.