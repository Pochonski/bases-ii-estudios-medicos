\set ON_ERROR_STOP on
-- P10 y P11 para usr_api_mobile. Ejecutar CONECTADO como usr_api_mobile (login SCRAM).
SELECT current_user AS usuario_conectado,
       current_setting('default_transaction_read_only') AS solo_lectura,
       current_setting('statement_timeout') AS statement_timeout;
\echo '--- vista móvil reducida'
SELECT * FROM api.vw_citas_mobile WHERE id_paciente = 1001 AND codigo_region = 'AL';

DO $$
BEGIN
  IF current_user <> 'usr_api_mobile' THEN RAISE EXCEPTION 'Ejecutar con el login usr_api_mobile'; END IF;
  IF (SELECT count(*) FROM api.vw_citas_mobile) <> 30 THEN RAISE EXCEPTION 'FALLA P10: vw_citas_mobile'; END IF;
  RAISE NOTICE 'PASS P10 positivo: usr_api_mobile lee vw_citas_mobile';

  BEGIN PERFORM 1 FROM api.vw_paciente_facturacion LIMIT 1; RAISE EXCEPTION 'FALLA: lee facturación';
  EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'PASS negativo: api.vw_paciente_facturacion es exclusiva de web'; END;
  BEGIN PERFORM 1 FROM api.vw_citas_web LIMIT 1; RAISE EXCEPTION 'FALLA: lee agenda web';
  EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'PASS negativo: api.vw_citas_web es exclusiva de web'; END;
  BEGIN PERFORM 1 FROM clinico.citas LIMIT 1; RAISE EXCEPTION 'FALLA: lee tabla base';
  EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'PASS negativo: clinico.citas denegado'; END;
  BEGIN PERFORM 1 FROM externo.fn_estado_facturacion() LIMIT 1; RAISE EXCEPTION 'FALLA: ejecuta función remota';
  EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'PASS negativo: externo.fn_estado_facturacion denegada'; END;
  BEGIN UPDATE api.vw_citas_mobile SET estado = 'CANCELADA' WHERE id_cita = 10001; RAISE EXCEPTION 'FALLA: UPDATE';
  EXCEPTION WHEN insufficient_privilege OR read_only_sql_transaction OR object_not_in_prerequisite_state OR feature_not_supported
    THEN RAISE NOTICE 'PASS negativo P11: UPDATE sobre vista móvil rechazado (%)', SQLSTATE; END;
END $$;
\echo 'PASS usr_api_mobile: P10 y P11'
