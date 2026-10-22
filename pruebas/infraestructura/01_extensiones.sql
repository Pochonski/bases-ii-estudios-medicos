\set ON_ERROR_STOP on
SELECT version();
SHOW timezone;
SHOW password_encryption;
SELECT extname, extversion FROM pg_extension
WHERE extname IN ('tds_fdw', 'mongo_fdw') ORDER BY extname;
LOAD '$libdir/tds_fdw';
LOAD '$libdir/mongo_fdw';
DO $$
BEGIN
  IF (SELECT count(*) FROM pg_extension WHERE extname IN ('tds_fdw','mongo_fdw')) <> 2 THEN
    RAISE EXCEPTION 'Faltan extensiones';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_hba_file_rules WHERE error IS NOT NULL) THEN
    RAISE EXCEPTION 'pg_hba.conf contiene errores';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_hba_file_rules WHERE type LIKE 'host%' AND auth_method = 'trust') THEN
    RAISE EXCEPTION 'Autenticacion trust por TCP no permitida';
  END IF;
  IF current_setting('password_encryption') <> 'scram-sha-256' THEN
    RAISE EXCEPTION 'SCRAM no configurado';
  END IF;
  IF current_setting('server_version_num')::integer / 10000 <> 16 THEN
    RAISE EXCEPTION 'Esta prueba requiere PostgreSQL 16';
  END IF;
END $$;
SELECT line_number, type, auth_method, error FROM pg_hba_file_rules;
-- Cargar la biblioteca y crear la extensión NO demuestra una consulta remota FDW.