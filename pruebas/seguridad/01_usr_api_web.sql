\set ON_ERROR_STOP on
-- P02, P03, P10, P11 para usr_api_web. Ejecutar CONECTADO como usr_api_web (login SCRAM).
SELECT current_user AS usuario_conectado,
       current_setting('default_transaction_read_only') AS solo_lectura,
       current_setting('statement_timeout') AS statement_timeout;

\echo '--- P02/INT-03: vista web con datos locales PostgreSQL + remotos SQL Server'
SELECT * FROM api.vw_paciente_facturacion
WHERE id_paciente IN (1001, 1009, 2002, 3003) ORDER BY codigo_region, id_paciente;
\echo '--- agenda web (primeras filas)'
SELECT * FROM api.vw_citas_web ORDER BY id_cita LIMIT 3;

DO $$
DECLARE v_total int; v_claves int; v_sin int;
BEGIN
  IF current_user <> 'usr_api_web' THEN RAISE EXCEPTION 'Ejecutar con el login usr_api_web'; END IF;
  SELECT count(*), count(DISTINCT (id_paciente, codigo_region)),
         count(*) FILTER (WHERE estado_cobertura = 'SIN_REGISTRO')
    INTO v_total, v_claves, v_sin FROM api.vw_paciente_facturacion;
  RAISE NOTICE 'pacientes=% claves=% sin_registro=%', v_total, v_claves, v_sin;
  IF v_total <> 30 OR v_claves <> 30 THEN RAISE EXCEPTION 'FALLA P02: pacientes perdidos o duplicados'; END IF;
  IF NOT EXISTS (SELECT 1 FROM api.vw_paciente_facturacion WHERE id_paciente = 1001 AND codigo_region = 'AL'
                 AND estado_facturacion = 'PENDIENTE' AND total_facturado_crc = 23500.00) THEN
    RAISE EXCEPTION 'FALLA P02: 1001/AL no combina su facturación';
  END IF;
  RAISE NOTICE 'PASS P02: 30 pacientes, uno por clave, con facturación remota combinada';
  IF v_sin <> 6 OR NOT EXISTS (SELECT 1 FROM api.vw_paciente_facturacion WHERE id_paciente = 1009
                 AND codigo_region = 'AL' AND estado_facturacion = 'SIN_REGISTRO') THEN
    RAISE EXCEPTION 'FALLA P03: paciente sin registro externo no aparece como SIN_REGISTRO';
  END IF;
  RAISE NOTICE 'PASS P03: 6 pacientes SIN_REGISTRO conservados (1009/AL incluido)';
  IF (SELECT count(*) FROM api.vw_citas_web) <> 30 THEN RAISE EXCEPTION 'FALLA P10: vw_citas_web'; END IF;
  RAISE NOTICE 'PASS P10 positivo: usr_api_web lee vw_paciente_facturacion y vw_citas_web';

  -- La invocación directa permitida solo devuelve exactamente las filas/columnas de la vista.
  IF EXISTS (SELECT * FROM api.fn_paciente_facturacion()
             EXCEPT SELECT * FROM api.vw_paciente_facturacion)
     OR EXISTS (SELECT * FROM api.vw_paciente_facturacion
                EXCEPT SELECT * FROM api.fn_paciente_facturacion()) THEN
    RAISE EXCEPTION 'FALLA P10: función web expone datos fuera de la vista';
  END IF;
  RAISE NOTICE 'PASS P10: función web directa limitada a la proyección de la vista';

  -- P10/P11 negativos.
  BEGIN PERFORM 1 FROM externo.fn_estado_facturacion() LIMIT 1;
        RAISE EXCEPTION 'FALLA: ejecuta función remota sin filtro clínico';
  EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'PASS negativo: función remota interna denegada a web'; END;
  BEGIN PERFORM 1 FROM clinico.pacientes LIMIT 1; RAISE EXCEPTION 'FALLA: lee tabla base';
  EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'PASS negativo: clinico.pacientes denegado'; END;
  BEGIN PERFORM 1 FROM externo.ft_estado_facturacion LIMIT 1; RAISE EXCEPTION 'FALLA: lee tabla foránea';
  EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'PASS negativo: externo.ft_estado_facturacion denegado'; END;
  BEGIN PERFORM 1 FROM api.vw_citas_mobile LIMIT 1; RAISE EXCEPTION 'FALLA: lee vista móvil';
  EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'PASS negativo: api.vw_citas_mobile no es de web'; END;
  BEGIN UPDATE api.vw_citas_web SET estado = 'CANCELADA' WHERE id_cita = 10001; RAISE EXCEPTION 'FALLA: UPDATE';
  EXCEPTION WHEN insufficient_privilege OR read_only_sql_transaction OR object_not_in_prerequisite_state OR feature_not_supported
    THEN RAISE NOTICE 'PASS negativo P11: UPDATE sobre vista rechazado (%)', SQLSTATE; END;
  BEGIN DELETE FROM clinico.citas WHERE id_cita = 10001; RAISE EXCEPTION 'FALLA: DELETE';
  EXCEPTION WHEN insufficient_privilege OR read_only_sql_transaction
    THEN RAISE NOTICE 'PASS negativo P11: DELETE en tabla base rechazado (%)', SQLSTATE; END;
  BEGIN EXECUTE 'CREATE TABLE public.intruso (x int)'; RAISE EXCEPTION 'FALLA: CREATE';
  EXCEPTION WHEN insufficient_privilege OR read_only_sql_transaction
    THEN RAISE NOTICE 'PASS negativo P11: CREATE TABLE rechazado (%)', SQLSTATE; END;
END $$;
\echo 'PASS usr_api_web: P02, P03, P10 y P11'
