\set ON_ERROR_STOP on
\set ECHO none
-- Módulo de Armando, implementado por Joyce con su permiso (D-042).
-- Perfiles EXTERNOS para futuras aplicaciones: usr_api_web y usr_api_mobile.
-- Autenticación SCRAM (pg_hba.conf de Joseph: samenet y localhost con scram-sha-256).
-- Contraseñas por entorno del proceso psql, nunca en Git:
--   PG_API_WEB_PASSWORD, PG_API_MOBILE_PASSWORD
-- Repetible. Ejecutar después del núcleo y de integracion/01-02 (usa los perfiles internos).
\getenv web_password PG_API_WEB_PASSWORD
\if :{?web_password}
\else
  \echo 'Falta PG_API_WEB_PASSWORD'
  SELECT 1 / 0;
\endif
\getenv mobile_password PG_API_MOBILE_PASSWORD
\if :{?mobile_password}
\else
  \echo 'Falta PG_API_MOBILE_PASSWORD'
  SELECT 1 / 0;
\endif
SELECT current_database() AS base_actual \gset
BEGIN;
SET LOCAL log_statement = 'none';
SET LOCAL log_min_error_statement = 'panic';

SELECT NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'usr_api_web') AS crear_web,
       NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'usr_api_mobile') AS crear_mobile,
       NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'api_propietario') AS crear_prop \gset
\if :crear_web
  CREATE ROLE usr_api_web;
\endif
\if :crear_mobile
  CREATE ROLE usr_api_mobile;
\endif
-- Dueño de las vistas api: sin login; concentra los SELECT sobre tablas base.
\if :crear_prop
  CREATE ROLE api_propietario;
\endif
ALTER ROLE api_propietario NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS;

-- Políticas diferenciadas por perfil: solo lectura, límites de conexión y tiempos.
ALTER ROLE usr_api_web LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS
    CONNECTION LIMIT 20 PASSWORD :'web_password';
ALTER ROLE usr_api_web SET default_transaction_read_only = on;
ALTER ROLE usr_api_web SET statement_timeout = '15s';
ALTER ROLE usr_api_web SET idle_in_transaction_session_timeout = '60s';

ALTER ROLE usr_api_mobile LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS
    CONNECTION LIMIT 50 PASSWORD :'mobile_password';
ALTER ROLE usr_api_mobile SET default_transaction_read_only = on;
ALTER ROLE usr_api_mobile SET statement_timeout = '5s';
ALTER ROLE usr_api_mobile SET idle_in_transaction_session_timeout = '30s';

-- Solo los perfiles del proyecto pueden conectarse a la base (antes: cualquier rol).
REVOKE CONNECT, TEMPORARY ON DATABASE :"base_actual" FROM PUBLIC;
GRANT CONNECT ON DATABASE :"base_actual"
    TO usr_api_web, usr_api_mobile, usr_fdw_pg_mssql, usr_fdw_pg_mongo;
COMMIT;
\unset web_password
\unset mobile_password
\echo 'PASS 04: usr_api_web, usr_api_mobile (SCRAM, solo lectura) y api_propietario'
