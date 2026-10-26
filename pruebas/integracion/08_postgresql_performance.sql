\set ON_ERROR_STOP on
\timing on
-- Las dos rutas leen datos reales SQL Server. El modo query filtra localmente.
SELECT count(*) AS filas_remotas FROM externo.ft_estado_facturacion;
DO $$
DECLARE n integer;
BEGIN
  SELECT count(*) INTO n FROM externo.ft_estado_facturacion;
  IF n <> 2004 THEN RAISE EXCEPTION 'Cardinalidad remota: %, esperado 2004', n; END IF;
  SELECT count(*) INTO n FROM externo.ft_estado_facturacion
    WHERE id_paciente = 6000000001 AND codigo_region = 'SJ';
  IF n <> 1 THEN RAISE EXCEPTION 'Modo query filtró mal: %', n; END IF;
  SELECT count(*) INTO n FROM externo.ft_estado_tabla_spike
    WHERE id_paciente = 6000000001 AND codigo_region = 'SJ';
  IF n <> 1 THEN RAISE EXCEPTION 'Modo table_name filtró mal: %', n; END IF;
END $$;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, COSTS OFF)
SELECT id_paciente FROM externo.ft_estado_facturacion
WHERE id_paciente = 6000000001 AND codigo_region = 'SJ';
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, COSTS OFF)
SELECT id_paciente FROM externo.ft_estado_tabla_spike
WHERE id_paciente = 6000000001 AND codigo_region = 'SJ';
\echo 'PASS rendimiento: 2004 filas remotas, filtros exactos en query y table_name; planes/tiempos arriba'
