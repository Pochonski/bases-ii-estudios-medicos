\set ON_ERROR_STOP on
\set ECHO none
-- Joyce. Canal PostgreSQL -> MongoDB con mongo_fdw y perfil interno usr_fdw_pg_mongo.
-- Ejecutar con psql como administrador, después de mongodb/01..03. Repetible.
-- Secretos por entorno del proceso psql, nunca en Git:
--   FDW_MONGO_PASSWORD           contraseña de svc_pg_mongo_rw en MongoDB
--   PG_FDW_MONGO_LOGIN_PASSWORD  contraseña de login de usr_fdw_pg_mongo en PostgreSQL
\getenv fdw_password FDW_MONGO_PASSWORD
\if :{?fdw_password}
\else
  \echo 'Falta FDW_MONGO_PASSWORD en el entorno del proceso psql'
  SELECT 1 / 0;
\endif
\getenv login_password PG_FDW_MONGO_LOGIN_PASSWORD
\if :{?login_password}
\else
  \echo 'Falta PG_FDW_MONGO_LOGIN_PASSWORD en el entorno del proceso psql'
  SELECT 1 / 0;
\endif
BEGIN;
SET LOCAL log_statement = 'none';
SET LOCAL log_min_error_statement = 'panic';
SET LOCAL log_min_duration_statement = -1;

CREATE SCHEMA IF NOT EXISTS externo;
REVOKE ALL ON SCHEMA externo FROM PUBLIC;

SELECT NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'usr_fdw_pg_mongo') AS crear_rol \gset
\if :crear_rol
  CREATE ROLE usr_fdw_pg_mongo;
\endif
-- Perfil interno: solo login, sin privilegios administrativos; pocas conexiones.
ALTER ROLE usr_fdw_pg_mongo LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION
    NOBYPASSRLS CONNECTION LIMIT 3 PASSWORD :'login_password';

CREATE SERVER IF NOT EXISTS mongo_reportes FOREIGN DATA WRAPPER mongo_fdw
    OPTIONS (address 'mongodb', port '27017', authentication_database 'reportes_medicos');
REVOKE ALL ON FOREIGN SERVER mongo_reportes FROM PUBLIC;

-- Solo el perfil interno tiene mapping: el administrador no escribe en MongoDB por FDW.
DROP USER MAPPING IF EXISTS FOR usr_fdw_pg_mongo SERVER mongo_reportes;
CREATE USER MAPPING FOR usr_fdw_pg_mongo SERVER mongo_reportes
    OPTIONS (username 'svc_pg_mongo_rw', password :'fdw_password');

-- mongo_fdw exige _id como primera columna para INSERT/UPDATE.
-- bigint -> BSON Int64, integer -> Int32, timestamptz -> BSON Date (UTC), text -> String.
DROP FOREIGN TABLE IF EXISTS externo.ft_resumenes_estudios;
CREATE FOREIGN TABLE externo.ft_resumenes_estudios (
    _id name,
    id_estudio bigint,
    id_paciente bigint,
    codigo_region text,
    id_medico bigint,
    id_tipo integer,
    tipo_estudio text,
    id_sucursal integer,
    codigo_region_atencion text,
    fecha_resultado timestamptz,
    resultado_resumen text,
    revision integer,
    fecha_sincronizacion timestamptz
) SERVER mongo_reportes
  OPTIONS (database 'reportes_medicos', collection 'resumenes_estudios');
REVOKE ALL ON externo.ft_resumenes_estudios FROM PUBLIC;

GRANT USAGE ON SCHEMA externo TO usr_fdw_pg_mongo;
GRANT USAGE ON FOREIGN SERVER mongo_reportes TO usr_fdw_pg_mongo;
-- Inserción y actualización controladas; sin DELETE (tampoco lo permite el rol MongoDB).
GRANT SELECT, INSERT, UPDATE ON externo.ft_resumenes_estudios TO usr_fdw_pg_mongo;
COMMIT;
\unset fdw_password
\unset login_password
\echo 'PASS integracion/02: servidor mongo_reportes, mapping y externo.ft_resumenes_estudios'
