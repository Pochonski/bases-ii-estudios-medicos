\set ON_ERROR_STOP on
-- Inserción válida en SJ, con atención en CA; todo se revierte al finalizar el bloque.
BEGIN;
INSERT INTO clinico.pacientes
    (id_paciente, codigo_region, nombre, apellidos, fecha_nacimiento)
VALUES (99001, 'SJ', 'PacienteTemporalFicticio', 'Caso Prueba', DATE '1990-01-01');
INSERT INTO clinico.citas
    (id_cita, id_paciente, codigo_region, id_medico, id_sucursal, fecha_hora, estado)
VALUES (99001, 99001, 'SJ', 501, 3, TIMESTAMPTZ '2026-10-25 10:00:00+00', 'PROGRAMADA');
DO $test$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM clinico.citas c
        JOIN clinico.sucursales s USING (id_sucursal)
        WHERE c.id_cita = 99001 AND c.codigo_region = 'SJ'
          AND s.codigo_region = 'CA'
    ) THEN RAISE EXCEPTION 'Inserción válida entre regiones falló'; END IF;
    RAISE NOTICE 'PASS inserción válida: paciente SJ atendido en CA';
END;
$test$;
ROLLBACK;

DO $test$
DECLARE
    rechazado boolean;
BEGIN
    IF EXISTS (SELECT 1 FROM clinico.pacientes WHERE id_paciente = 99001)
       OR EXISTS (SELECT 1 FROM clinico.citas WHERE id_cita = 99001) THEN
        RAISE EXCEPTION 'ROLLBACK dejó filas temporales';
    END IF;

    rechazado := false;
    BEGIN
        INSERT INTO clinico.citas
            (id_cita, id_paciente, codigo_region, id_medico, id_sucursal, fecha_hora, estado)
        VALUES (99002, 1001, 'CA', 501, 1, now(), 'PROGRAMADA');
    EXCEPTION WHEN foreign_key_violation THEN rechazado := true;
    END;
    IF NOT rechazado THEN RAISE EXCEPTION 'FK compuesta permitió 1001/CA'; END IF;

    rechazado := false;
    BEGIN
        INSERT INTO clinico.pacientes
            (id_paciente, codigo_region, nombre, apellidos, fecha_nacimiento)
        VALUES (99003, 'XX', 'Ficticio', 'Caso Prueba', DATE '1990-01-01');
    EXCEPTION WHEN check_violation THEN rechazado := true;
    END;
    IF NOT rechazado THEN RAISE EXCEPTION 'Se permitió región sin partición'; END IF;

    rechazado := false;
    BEGIN
        INSERT INTO clinico.resultados_estudio
            (id_resultado, id_estudio, id_medico_firmante, resumen, fecha_resultado, revision)
        VALUES (99004, 30001, 501, 'Resultado ficticio duplicado', now(), 1);
    EXCEPTION WHEN unique_violation THEN rechazado := true;
    END;
    IF NOT rechazado THEN RAISE EXCEPTION 'UNIQUE(id_estudio) permitió segundo resultado'; END IF;

    rechazado := false;
    BEGIN
        INSERT INTO integracion.eventos_integracion
            (id_evento, id_estudio, revision, tipo_evento, estado)
        VALUES ('00000000-0000-4000-8000-000000099005', 30001, 0,
                'RESULTADO_CONFIRMADO', 'PENDIENTE');
    EXCEPTION WHEN check_violation THEN rechazado := true;
    END;
    IF NOT rechazado THEN RAISE EXCEPTION 'Se permitió revisión cero'; END IF;

    rechazado := false;
    BEGIN
        INSERT INTO clinico.citas
            (id_cita, id_paciente, codigo_region, id_medico, id_sucursal, fecha_hora, estado)
        VALUES (99006, 1001, 'AL', 501, 1, now(), 'DESCONOCIDA');
    EXCEPTION WHEN check_violation THEN rechazado := true;
    END;
    IF NOT rechazado THEN RAISE EXCEPTION 'Se permitió estado de cita inválido'; END IF;

    rechazado := false;
    BEGIN
        INSERT INTO clinico.diagnosticos
            (id_diagnostico, id_resultado, descripcion)
        VALUES (99007, 999999, 'Diagnóstico ficticio');
    EXCEPTION WHEN foreign_key_violation THEN rechazado := true;
    END;
    IF NOT rechazado THEN RAISE EXCEPTION 'Se permitió diagnóstico sin resultado'; END IF;

    RAISE NOTICE 'PASS integridad: FK compuesta, partición, UNIQUE, CHECK, FK diagnóstico y ROLLBACK';
END;
$test$;
