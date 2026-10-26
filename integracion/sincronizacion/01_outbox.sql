\set ON_ERROR_STOP on
-- Joyce. Outbox PostgreSQL -> MongoDB (D-013/D-014, opción A de D-038, propuesta D-041).
-- Ejecutar con psql como administrador después de postgresql/01..03 e integracion/02.
--
-- Flujo: integracion.registrar_resultado() guarda resultado + evento en UNA transacción local.
-- Tras el COMMIT, usr_fdw_pg_mongo ejecuta CALL integracion.exportar_pendientes(), que escribe
-- por mongo_fdw y marca el evento. NO es una transacción ACID global: consistencia eventual
-- con reintentos; MongoDB nunca recibe una revisión menor a la que ya tiene.
BEGIN;

-- Un evento lógico por (estudio, revisión, tipo); evita duplicados con UUID distinto (D-038).
CREATE UNIQUE INDEX IF NOT EXISTS eventos_logico_ux
    ON integracion.eventos_integracion (id_estudio, revision, tipo_evento);

-- El fixture usa id_resultado 40001-40030; los nuevos resultados parten de 41000.
CREATE SEQUENCE IF NOT EXISTS clinico.seq_resultados_estudio START WITH 41000;

CREATE OR REPLACE FUNCTION integracion.registrar_resultado(
    p_id_estudio bigint,
    p_id_medico_firmante bigint,
    p_resumen text,
    p_fecha_resultado timestamptz DEFAULT now())
RETURNS TABLE (id_resultado bigint, revision integer, id_evento uuid)
LANGUAGE plpgsql
SET search_path = pg_catalog, pg_temp
AS $$
#variable_conflict use_column
DECLARE
    v_estado text;
    v_resultado clinico.resultados_estudio%ROWTYPE;
    v_evento uuid := gen_random_uuid();
BEGIN
    SELECT e.estado INTO v_estado
    FROM clinico.estudios AS e WHERE e.id_estudio = p_id_estudio FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'El estudio % no existe', p_id_estudio;
    END IF;
    IF v_estado = 'CANCELADO' THEN
        RAISE EXCEPTION 'El estudio % está cancelado', p_id_estudio;
    END IF;

    -- El bloqueo serializa escritores concurrentes del mismo resultado: revisión monotónica.
    UPDATE clinico.resultados_estudio AS r
       SET id_medico_firmante = p_id_medico_firmante,
           resumen = p_resumen,
           fecha_resultado = p_fecha_resultado,
           revision = r.revision + 1
     WHERE r.id_estudio = p_id_estudio
    RETURNING r.* INTO v_resultado;
    IF NOT FOUND THEN
        INSERT INTO clinico.resultados_estudio
            (id_resultado, id_estudio, id_medico_firmante, resumen, fecha_resultado, revision)
        VALUES (nextval('clinico.seq_resultados_estudio'), p_id_estudio, p_id_medico_firmante,
                p_resumen, p_fecha_resultado, 1)
        RETURNING * INTO v_resultado;
    END IF;

    UPDATE clinico.estudios AS e
       SET estado = 'FINALIZADO',
           fecha_realizacion = COALESCE(e.fecha_realizacion, p_fecha_resultado)
     WHERE e.id_estudio = p_id_estudio AND e.estado <> 'FINALIZADO';

    INSERT INTO integracion.eventos_integracion (id_evento, id_estudio, revision, tipo_evento, estado)
    VALUES (v_evento, p_id_estudio, v_resultado.revision, 'RESULTADO_CONFIRMADO', 'PENDIENTE');

    RETURN QUERY SELECT v_resultado.id_resultado, v_resultado.revision, v_evento;
END;
$$;

-- INT-04: encola la exportación de todos los resultados cuya revisión vigente aún no tiene evento.
CREATE OR REPLACE FUNCTION integracion.encolar_exportacion_masiva()
RETURNS integer
LANGUAGE plpgsql
SET search_path = pg_catalog, pg_temp
AS $$
DECLARE
    v_cantidad integer;
BEGIN
    INSERT INTO integracion.eventos_integracion (id_evento, id_estudio, revision, tipo_evento, estado)
    SELECT gen_random_uuid(), r.id_estudio, r.revision, 'EXPORTACION_MASIVA', 'PENDIENTE'
    FROM clinico.resultados_estudio AS r
    WHERE NOT EXISTS (SELECT 1 FROM integracion.eventos_integracion AS e
                      WHERE e.id_estudio = r.id_estudio AND e.revision = r.revision)
    ON CONFLICT DO NOTHING;
    GET DIAGNOSTICS v_cantidad = ROW_COUNT;
    RETURN v_cantidad;
END;
$$;

-- Procesador único. Cada evento se confirma por separado: un fallo no bloquea a los demás.
-- Lee el estado VIGENTE del resultado (no un payload histórico), por eso un evento viejo
-- reprocesado no hace retroceder el documento.
CREATE OR REPLACE PROCEDURE integracion.exportar_pendientes(
    p_limite integer DEFAULT 100,
    p_max_intentos integer DEFAULT 5)
LANGUAGE plpgsql
-- Sin cláusula SET: PostgreSQL prohíbe COMMIT en procedimientos que la tienen.
-- Todos los objetos van calificados con su esquema.
AS $$
DECLARE
    v_evento record;
    v_doc record;
    v_mongo record;
    v_accion text;
    v_vistos uuid[] := '{}';
    v_ok integer := 0;
    v_error integer := 0;
BEGIN
    FOR i IN 1 .. p_limite LOOP
        SELECT e.id_evento, e.id_estudio, e.revision INTO v_evento
        FROM integracion.eventos_integracion AS e
        WHERE e.estado IN ('PENDIENTE', 'ERROR')
          AND e.intentos < p_max_intentos
          AND e.id_evento <> ALL (v_vistos)
        ORDER BY e.fecha_creacion, e.id_evento
        LIMIT 1
        FOR UPDATE SKIP LOCKED;
        EXIT WHEN NOT FOUND;
        v_vistos := v_vistos || v_evento.id_evento;

        BEGIN
            SELECT r.id_estudio, c.id_paciente, c.codigo_region,
                   r.id_medico_firmante AS id_medico, es.id_tipo, t.nombre AS tipo_estudio,
                   c.id_sucursal, s.codigo_region AS codigo_region_atencion,
                   r.fecha_resultado, r.resumen, r.revision
              INTO STRICT v_doc
              FROM clinico.resultados_estudio AS r
              JOIN clinico.estudios AS es ON es.id_estudio = r.id_estudio
              JOIN clinico.ordenes_medicas AS o ON o.id_orden = es.id_orden
              JOIN clinico.citas AS c ON c.id_cita = o.id_cita
              JOIN clinico.sucursales AS s ON s.id_sucursal = c.id_sucursal
              JOIN clinico.tipos_estudio AS t ON t.id_tipo = es.id_tipo
             WHERE r.id_estudio = v_evento.id_estudio;

            SELECT m.revision INTO v_mongo
              FROM externo.ft_resumenes_estudios AS m
             WHERE m.id_estudio = v_evento.id_estudio;

            IF NOT FOUND THEN
                INSERT INTO externo.ft_resumenes_estudios
                    (_id, id_estudio, id_paciente, codigo_region, id_medico, id_tipo, tipo_estudio,
                     id_sucursal, codigo_region_atencion, fecha_resultado, resultado_resumen,
                     revision, fecha_sincronizacion)
                VALUES (NULL, v_doc.id_estudio, v_doc.id_paciente, v_doc.codigo_region,
                        v_doc.id_medico, v_doc.id_tipo, v_doc.tipo_estudio, v_doc.id_sucursal,
                        v_doc.codigo_region_atencion, v_doc.fecha_resultado, v_doc.resumen,
                        v_doc.revision, clock_timestamp());
                v_accion := 'INSERTADO';
            ELSIF v_mongo.revision < v_doc.revision THEN
                UPDATE externo.ft_resumenes_estudios AS m
                   SET id_paciente = v_doc.id_paciente,
                       codigo_region = v_doc.codigo_region,
                       id_medico = v_doc.id_medico,
                       id_tipo = v_doc.id_tipo,
                       tipo_estudio = v_doc.tipo_estudio,
                       id_sucursal = v_doc.id_sucursal,
                       codigo_region_atencion = v_doc.codigo_region_atencion,
                       fecha_resultado = v_doc.fecha_resultado,
                       resultado_resumen = v_doc.resumen,
                       revision = v_doc.revision,
                       fecha_sincronizacion = clock_timestamp()
                 WHERE m.id_estudio = v_evento.id_estudio;
                v_accion := 'ACTUALIZADO';
            ELSE
                v_accion := 'SIN_CAMBIOS (MongoDB ya tiene revisión ' || v_mongo.revision || ')';
            END IF;

            -- Comprobar el documento antes de marcar el evento.
            PERFORM 1 FROM externo.ft_resumenes_estudios AS m
             WHERE m.id_estudio = v_evento.id_estudio AND m.revision >= v_doc.revision;
            IF NOT FOUND THEN
                RAISE EXCEPTION 'MongoDB no refleja la revisión % del estudio %',
                    v_doc.revision, v_evento.id_estudio;
            END IF;

            UPDATE integracion.eventos_integracion AS e
               SET estado = 'PROCESADO', intentos = e.intentos + 1,
                   fecha_procesamiento = clock_timestamp()
             WHERE e.id_evento = v_evento.id_evento;
            v_ok := v_ok + 1;
            RAISE NOTICE 'evento % estudio % rev % -> %',
                v_evento.id_evento, v_evento.id_estudio, v_evento.revision, v_accion;
        EXCEPTION WHEN OTHERS THEN
            -- La escritura remota que ya ocurrió no se revierte; el reintento es idempotente.
            UPDATE integracion.eventos_integracion AS e
               SET estado = 'ERROR', intentos = e.intentos + 1,
                   fecha_procesamiento = clock_timestamp()
             WHERE e.id_evento = v_evento.id_evento;
            v_error := v_error + 1;
            RAISE WARNING 'evento % estudio % rev % -> ERROR: %',
                v_evento.id_evento, v_evento.id_estudio, v_evento.revision, SQLERRM;
        END;
        COMMIT;
    END LOOP;
    RAISE NOTICE 'exportar_pendientes: % procesados, % con error', v_ok, v_error;
END;
$$;

-- Escritura clínica y encolado: solo el administrador (no hay rol de aplicación clínica aún).
REVOKE ALL ON FUNCTION integracion.registrar_resultado(bigint, bigint, text, timestamptz) FROM PUBLIC;
REVOKE ALL ON FUNCTION integracion.encolar_exportacion_masiva() FROM PUBLIC;
REVOKE ALL ON PROCEDURE integracion.exportar_pendientes(integer, integer) FROM PUBLIC;

-- Exportación: solo el perfil interno usr_fdw_pg_mongo, con lo mínimo para armar el resumen.
-- No recibe clinico.pacientes: el documento no lleva nombres ni contacto del paciente.
GRANT USAGE ON SCHEMA clinico, integracion TO usr_fdw_pg_mongo;
GRANT SELECT ON clinico.resultados_estudio, clinico.estudios, clinico.ordenes_medicas,
                clinico.citas, clinico.sucursales, clinico.tipos_estudio TO usr_fdw_pg_mongo;
GRANT SELECT ON integracion.eventos_integracion TO usr_fdw_pg_mongo;
GRANT UPDATE (estado, intentos, fecha_procesamiento)
    ON integracion.eventos_integracion TO usr_fdw_pg_mongo;
GRANT EXECUTE ON PROCEDURE integracion.exportar_pendientes(integer, integer) TO usr_fdw_pg_mongo;
COMMIT;
\echo 'PASS sincronizacion/01: outbox, registrar_resultado, exportación y permisos'
