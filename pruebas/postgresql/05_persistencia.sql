\set ON_ERROR_STOP on
DO $test$
BEGIN
    IF (SELECT count(*) FROM clinico.pacientes) <> 30
       OR NOT EXISTS (SELECT 1 FROM clinico.pacientes
                      WHERE id_paciente = 1001 AND codigo_region = 'AL')
       OR NOT EXISTS (SELECT 1 FROM clinico.resultados_estudio
                      WHERE id_estudio = 30040 AND revision = 1)
       OR NOT EXISTS (SELECT 1 FROM integracion.eventos_integracion
                      WHERE id_estudio = 30040 AND estado = 'PENDIENTE')
       OR EXISTS (SELECT 1 FROM integracion.eventos_integracion
                  WHERE id_estudio = 30039) THEN
        RAISE EXCEPTION 'Estado clínico cambió tras restart';
    END IF;
    RAISE NOTICE 'PASS persistencia parcial: 30 pacientes, resultado/evento COMMIT; ROLLBACK ausente';
END;
$test$;

\echo PASS P12 parcial: registros clínicos PostgreSQL tras restart del mismo contenedor
