\set ON_ERROR_STOP on
DO $test$
DECLARE
    esperadas text[] := ARRAY[
        'clinico.regiones', 'clinico.sucursales', 'clinico.pacientes',
        'clinico.medicos', 'clinico.usuarios_administrativos', 'clinico.citas',
        'clinico.ordenes_medicas', 'clinico.tipos_estudio', 'clinico.estudios',
        'clinico.resultados_estudio', 'clinico.diagnosticos',
        'integracion.eventos_integracion'];
    nombre text;
    particiones integer;
BEGIN
    FOREACH nombre IN ARRAY esperadas LOOP
        IF to_regclass(nombre) IS NULL THEN
            RAISE EXCEPTION 'Falta tabla %', nombre;
        END IF;
    END LOOP;
    IF cardinality(esperadas) <> 12 THEN RAISE EXCEPTION 'Conteo de tablas incorrecto'; END IF;
    SELECT count(*) INTO particiones FROM pg_inherits
    WHERE inhparent = 'clinico.pacientes'::regclass;
    IF particiones <> 3 THEN RAISE EXCEPTION 'Particiones: esperado 3, obtenido %', particiones; END IF;
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'pacientes_pk' AND contype = 'p'
          AND conrelid = 'clinico.pacientes'::regclass
    ) OR NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'citas_paciente_fk' AND contype = 'f'
          AND conrelid = 'clinico.citas'::regclass
    ) THEN RAISE EXCEPTION 'Faltan PK/FK compuestas de pacientes'; END IF;
    RAISE NOTICE 'PASS estructura: 12 tablas, 3 particiones, PK/FK paciente compuestas';
END;
$test$;

\echo PASS estructura: 12 tablas, 3 particiones y PK/FK compuestas

DO $test$
DECLARE
    conteos bigint[];
BEGIN
    SELECT ARRAY[
        (SELECT count(*) FROM clinico.regiones),
        (SELECT count(*) FROM clinico.sucursales),
        (SELECT count(*) FROM clinico.pacientes),
        (SELECT count(*) FROM clinico.medicos),
        (SELECT count(*) FROM clinico.usuarios_administrativos),
        (SELECT count(*) FROM clinico.citas),
        (SELECT count(*) FROM clinico.ordenes_medicas),
        (SELECT count(*) FROM clinico.tipos_estudio),
        (SELECT count(*) FROM clinico.estudios),
        (SELECT count(*) FROM clinico.resultados_estudio),
        (SELECT count(*) FROM clinico.diagnosticos),
        (SELECT count(*) FROM integracion.eventos_integracion)
    ] INTO conteos;
    IF conteos <> ARRAY[3,3,30,6,2,30,25,4,40,30,15,0]::bigint[] THEN
        RAISE EXCEPTION 'Conteos fixture inesperados: %', conteos;
    END IF;
    RAISE NOTICE 'PASS fixture: conteos %; outbox vacío', conteos;
END;
$test$;

\echo PASS fixture: conteos exactos y outbox inicialmente vacío
