\set ON_ERROR_STOP on
-- Joseph Fase 2. Ejecutar en una base PostgreSQL vacía, antes de 02/03/06.
-- Los nombres de esquema son una decisión de implementación D-036 pendiente de revisión
-- por Joyce antes de conectar FDW/outbox; no crean vistas ni permisos de Armando.
BEGIN;
CREATE SCHEMA clinico;
CREATE SCHEMA integracion;
REVOKE ALL ON SCHEMA clinico FROM PUBLIC;
REVOKE ALL ON SCHEMA integracion FROM PUBLIC;
COMMIT;
