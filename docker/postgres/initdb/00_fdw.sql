\set ON_ERROR_STOP on
-- Solo inicializa un volumen vacío. No crea tablas clínicas ni objetos de Joyce/Armando.
BEGIN;
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
CREATE EXTENSION tds_fdw;
CREATE EXTENSION mongo_fdw;
COMMIT;