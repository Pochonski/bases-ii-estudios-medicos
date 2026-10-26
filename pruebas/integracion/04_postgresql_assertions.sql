\set ON_ERROR_STOP on
\pset pager off
SELECT current_setting('server_version') AS postgresql_version,
       (SELECT extversion FROM pg_extension WHERE extname='tds_fdw') AS tds_fdw_version;
SELECT current_user AS fdw_login, count(*) AS remote_rows
FROM externo.ft_estado_facturacion;
SELECT id_paciente, codigo_region FROM externo.ft_estado_facturacion ORDER BY id_paciente;
EXPLAIN (VERBOSE, COSTS OFF) SELECT id_paciente FROM externo.ft_estado_tabla_spike WHERE id_paciente = 1001;
SELECT id_paciente, codigo_region, nombre_aseguradora,
       total_facturado_crc, fecha_actualizacion AT TIME ZONE 'UTC' AS fecha_utc
FROM externo.ft_estado_tabla_spike WHERE id_paciente = 1001;
EXPLAIN (VERBOSE, COSTS OFF) SELECT id_paciente FROM externo.ft_estado_tabla_spike
WHERE id_paciente = 1001 AND total_facturado_crc = 12345.67;
SELECT count(*) AS numeric_pushdown_probe FROM externo.ft_estado_tabla_spike
WHERE id_paciente = 1001 AND total_facturado_crc = 12345.67;
SELECT count(*) AS missing_remote_probe FROM externo.ft_estado_facturacion
WHERE id_paciente = 1002 AND codigo_region = 'AL';
EXPLAIN (VERBOSE, COSTS OFF) SELECT id_paciente FROM externo.ft_estado_facturacion
WHERE id_paciente = 1002 AND codigo_region = 'AL';
DO $$
DECLARE n integer; ordered_ids bigint[]; conventional_amount numeric(12,2);
BEGIN
  SELECT count(*) INTO n FROM externo.ft_estado_facturacion;
  IF n <> 4 THEN RAISE EXCEPTION 'Se esperaban 4 filas remotas, llegaron %', n; END IF;
  SELECT count(*) INTO n FROM (
    SELECT id_paciente, codigo_region FROM externo.ft_estado_facturacion
    GROUP BY 1,2 HAVING count(*) > 1
  ) d;
  IF n <> 0 THEN RAISE EXCEPTION 'Duplicados en clave remota'; END IF;
  IF NOT EXISTS (
    SELECT 1 FROM externo.ft_estado_facturacion
    WHERE id_paciente = 1001 AND codigo_region = 'AL'
      AND nombre_aseguradora = 'Clínica Ñandú'
      AND total_facturado_crc = 12345.67::numeric(12,2)
      AND fecha_actualizacion = '2026-10-22 21:30:00+00'::timestamptz
  ) THEN RAISE EXCEPTION 'Error de tipos, Unicode, decimal o zona horaria'; END IF;
  IF NOT EXISTS (
    SELECT 1 FROM externo.ft_estado_facturacion
    WHERE id_paciente = 3001 AND codigo_region = 'CA'
      AND total_facturado_crc = 9999999999.99::numeric(12,2)
      AND fecha_actualizacion = '2026-10-23 10:00:00+00'::timestamptz
  ) THEN RAISE EXCEPTION 'Error de decimal máximo o zona +02'; END IF;
  IF NOT EXISTS (
    SELECT 1 FROM externo.ft_estado_facturacion
    WHERE id_paciente = 5000000000 AND codigo_region = 'AL'
      AND total_facturado_crc = 18.25::numeric(12,2)
  ) THEN RAISE EXCEPTION 'Error de BIGINT fuera de rango Int32'; END IF;
  SELECT count(*) INTO n FROM externo.ft_estado_facturacion
  WHERE id_paciente = 1002 AND codigo_region = 'AL';
  IF n <> 0 THEN RAISE EXCEPTION 'Fila remota inesperada; count=%', n; END IF;
  SELECT count(*) INTO n FROM externo.ft_estado_facturacion
  WHERE id_paciente = 1001 AND codigo_region = 'AL';
  IF n <> 1 THEN RAISE EXCEPTION 'Filtro exacto 1001/AL devolvió % filas', n; END IF;
  SELECT count(*) INTO n FROM externo.ft_estado_tabla_spike;
  IF n <> 4 THEN RAISE EXCEPTION 'Modo table_name: cardinalidad inesperada %', n; END IF;
  SELECT count(*) INTO n FROM externo.ft_estado_tabla_spike WHERE id_paciente = 1001;
  IF n <> 1 THEN RAISE EXCEPTION 'Modo table_name: filtro id incorrecto %', n; END IF;
  SELECT count(*) INTO n FROM externo.ft_estado_tabla_spike WHERE id_paciente = 1001 AND codigo_region = 'AL';
  IF n <> 1 THEN RAISE EXCEPTION 'Modo table_name: filtro región incorrecto %', n; END IF;
  SELECT count(*) INTO n FROM externo.ft_estado_tabla_spike
  WHERE id_paciente = 1001 AND nombre_aseguradora = 'Clínica Ñandú';
  IF n <> 1 THEN RAISE EXCEPTION 'Modo table_name: Unicode incorrecto %', n; END IF;
  SELECT total_facturado_crc INTO STRICT conventional_amount FROM externo.ft_estado_tabla_spike
  WHERE id_paciente = 1001;
  IF conventional_amount <> 12345.67 THEN
    RAISE EXCEPTION 'Modo table_name: conversión DECIMAL incorrecta %', conventional_amount;
  END IF;
  SELECT count(*) INTO n FROM externo.ft_estado_tabla_spike WHERE id_paciente = 1002;
  IF n <> 0 THEN RAISE EXCEPTION 'Modo table_name: fila inexistente devuelta'; END IF;
  SELECT array_agg(id_paciente) INTO ordered_ids FROM (
    SELECT id_paciente FROM externo.ft_estado_facturacion ORDER BY id_paciente DESC
  ) sorted;
  IF ordered_ids <> ARRAY[5000000000,3001,2001,1001]::bigint[]
  THEN RAISE EXCEPTION 'ORDER BY de tabla foránea incorrecto: %', ordered_ids; END IF;
  SELECT count(*) INTO n FROM clinico.pacientes p
  LEFT JOIN externo.ft_estado_facturacion f
    ON f.id_paciente = p.id_paciente AND f.codigo_region = p.codigo_region
  WHERE p.id_paciente = 1002 AND p.codigo_region = 'AL' AND f.id_paciente IS NULL;
  IF n <> 1 THEN RAISE EXCEPTION 'LEFT JOIN perdió paciente sin facturación'; END IF;
END $$;
SELECT p.id_paciente, p.codigo_region, f.nombre_aseguradora,
       f.total_facturado_crc, f.fecha_actualizacion AT TIME ZONE 'UTC' AS fecha_utc
FROM clinico.pacientes p
LEFT JOIN externo.ft_estado_facturacion f
  ON f.id_paciente = p.id_paciente AND f.codigo_region = p.codigo_region
WHERE (p.id_paciente, p.codigo_region) IN ((1001,'AL'),(1002,'AL'),(2001,'SJ'),(3001,'CA'),(5000000000,'AL'))
ORDER BY p.id_paciente;
EXPLAIN (COSTS OFF)
SELECT id_paciente, codigo_region FROM externo.ft_estado_facturacion WHERE id_paciente = 1001;
\echo 'PASS PostgreSQL: FDW real, tipos, JOIN, ausencia remota y Foreign Scan'
\echo 'PASS table_name: vista de prueba, filtro presente/ausente, Unicode y DECIMAL'
