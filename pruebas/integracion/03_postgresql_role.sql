\set ON_ERROR_STOP on
\set ECHO none
-- Se aplica exclusivamente en joseph_tds_spike_pg, después de integracion/01.
\getenv login_password PG_FDW_LOGIN_PASSWORD
\if :{?login_password}
\else
  SELECT 1 / 0;
\endif
BEGIN;
SET LOCAL log_statement = 'none';
SET LOCAL log_min_error_statement = 'panic';
ALTER ROLE usr_fdw_pg_mssql LOGIN PASSWORD :'login_password';
GRANT USAGE ON SCHEMA clinico TO usr_fdw_pg_mssql;
GRANT SELECT ON clinico.pacientes TO usr_fdw_pg_mssql;
COMMIT;
\unset login_password
