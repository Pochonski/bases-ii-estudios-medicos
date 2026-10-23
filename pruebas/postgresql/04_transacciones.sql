\set ON_ERROR_STOP on
-- Solo prueba atomicidad local PostgreSQL. No existe exportador ni COMMIT global.
BEGIN;
UPDATE clinico.estudios
SET estado = 'FINALIZADO', fecha_realizacion = TIMESTAMPTZ '2026-10-22 08:00:00+00'
WHERE id_estudio = 30040;
INSERT INTO clinico.resultados_estudio
    (id_resultado, id_estudio, id_medico_firmante, resumen, fecha_resultado, revision)
VALUES (40040, 30040, 501, 'Resultado transaccional ficticio COMMIT',
        TIMESTAMPTZ '2026-10-22 09:00:00+00', 1);
INSERT INTO integracion.eventos_integracion
    (id_evento, id_estudio, revision, tipo_evento, estado, intentos, fecha_creacion)
VALUES ('00000000-0000-4000-8000-000000030040', 30040, 1,
        'RESULTADO_CONFIRMADO', 'PENDIENTE', 0, TIMESTAMPTZ '2026-10-22 09:00:00+00');
COMMIT;

DO $test$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM clinico.estudios e
        JOIN clinico.resultados_estudio r USING (id_estudio)
        JOIN integracion.eventos_integracion x
          ON x.id_estudio = r.id_estudio AND x.revision = r.revision
        WHERE e.id_estudio = 30040 AND e.estado = 'FINALIZADO'
          AND x.estado = 'PENDIENTE'
    ) THEN RAISE EXCEPTION 'COMMIT local no confirmó resultado y evento'; END IF;
    RAISE NOTICE 'PASS COMMIT local: resultado y evento PENDIENTE visibles juntos';
END;
$test$;

BEGIN;
UPDATE clinico.estudios
SET estado = 'FINALIZADO', fecha_realizacion = TIMESTAMPTZ '2026-10-22 10:00:00+00'
WHERE id_estudio = 30039;
INSERT INTO clinico.resultados_estudio
    (id_resultado, id_estudio, id_medico_firmante, resumen, fecha_resultado, revision)
VALUES (40039, 30039, 501, 'Resultado transaccional ficticio ROLLBACK',
        TIMESTAMPTZ '2026-10-22 11:00:00+00', 1);
INSERT INTO integracion.eventos_integracion
    (id_evento, id_estudio, revision, tipo_evento)
VALUES ('00000000-0000-4000-8000-000000030039', 30039, 1, 'RESULTADO_CONFIRMADO');
ROLLBACK;

DO $test$
BEGIN
    IF EXISTS (SELECT 1 FROM clinico.resultados_estudio WHERE id_estudio = 30039)
       OR EXISTS (SELECT 1 FROM integracion.eventos_integracion WHERE id_estudio = 30039)
       OR NOT EXISTS (SELECT 1 FROM clinico.estudios
                      WHERE id_estudio = 30039 AND estado = 'SOLICITADO') THEN
        RAISE EXCEPTION 'ROLLBACK local conservó cambios';
    END IF;
    RAISE NOTICE 'PASS ROLLBACK local: resultado/evento ausentes, estudio sin cambio';
END;
$test$;
