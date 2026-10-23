\set ON_ERROR_STOP on
SET enable_partition_pruning = on;
SELECT tableoid::regclass AS particion, count(*) AS pacientes
FROM clinico.pacientes GROUP BY tableoid ORDER BY particion;
EXPLAIN (COSTS OFF)
SELECT id_paciente FROM clinico.pacientes WHERE codigo_region = 'AL';

DO $test$
DECLARE
    sj integer;
    al integer;
    ca integer;
    plan json;
    region_registro char(2);
    region_atencion char(2);
BEGIN
    SELECT count(*) FILTER (WHERE tableoid = 'clinico.pacientes_sj'::regclass),
           count(*) FILTER (WHERE tableoid = 'clinico.pacientes_al'::regclass),
           count(*) FILTER (WHERE tableoid = 'clinico.pacientes_ca'::regclass)
    INTO sj, al, ca FROM clinico.pacientes;
    IF ARRAY[sj, al, ca] <> ARRAY[10,10,10] THEN
        RAISE EXCEPTION 'Distribución SJ/AL/CA incorrecta: %', ARRAY[sj,al,ca];
    END IF;

    EXECUTE 'EXPLAIN (FORMAT JSON, COSTS OFF)
             SELECT id_paciente FROM clinico.pacientes WHERE codigo_region = ''AL'''
    INTO plan;
    IF position('pacientes_al' IN plan::text) = 0
       OR position('pacientes_sj' IN plan::text) > 0
       OR position('pacientes_ca' IN plan::text) > 0 THEN
        RAISE EXCEPTION 'EXPLAIN no podó a AL: %', plan;
    END IF;

    SELECT c.codigo_region, s.codigo_region
    INTO region_registro, region_atencion
    FROM clinico.citas c JOIN clinico.sucursales s USING (id_sucursal)
    WHERE c.id_paciente = 1001 AND c.codigo_region = 'AL';
    IF region_registro <> 'AL' OR region_atencion <> 'SJ' THEN
        RAISE EXCEPTION 'Se confundió región de registro con atención';
    END IF;
    RAISE NOTICE 'PASS P14: tableoid SJ/AL/CA=10/10/10, pruning AL y atención AL->SJ';
END;
$test$;

\echo PASS P14: tableoid 10/10/10, EXPLAIN podó a AL, atención AL hacia SJ
