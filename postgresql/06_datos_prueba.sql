\set ON_ERROR_STOP on
-- Fixture completamente ficticio y determinista para una base VACÍA.
-- Ejecutar una vez después de 01, 02 y 03. No simula SQL Server, MongoDB ni exportación.
BEGIN;

INSERT INTO clinico.regiones (codigo_region, nombre) VALUES
    ('SJ', 'San José'), ('AL', 'Alajuela'), ('CA', 'Cartago');

INSERT INTO clinico.sucursales
    (id_sucursal, codigo_region, nombre, direccion, activa) VALUES
    (1, 'SJ', 'Sucursal Ficticia SJ', 'Dirección de prueba SJ', true),
    (2, 'AL', 'Sucursal Ficticia AL', 'Dirección de prueba AL', true),
    (3, 'CA', 'Sucursal Ficticia CA', 'Dirección de prueba CA', true);

-- AL: 1001–1010; SJ: 2001–2010; CA: 3001–3010. La identidad es el par id/región.
WITH series AS (
    SELECT codigo_region, base_id, n
    FROM (VALUES ('AL'::char(2), 1000::bigint),
                 ('SJ'::char(2), 2000::bigint),
                 ('CA'::char(2), 3000::bigint)) AS r(codigo_region, base_id)
    CROSS JOIN generate_series(1, 10) AS g(n)
)
INSERT INTO clinico.pacientes
    (id_paciente, codigo_region, nombre, apellidos, fecha_nacimiento,
     telefono, correo, fecha_registro)
SELECT base_id + n, codigo_region, 'PacienteFicticio' || (base_id + n), 'Caso Prueba',
       DATE '1980-01-01' + (n * 365), NULL,
       'paciente' || (base_id + n) || '@example.invalid',
       TIMESTAMPTZ '2026-10-01 12:00:00+00' + (n || ' days')::interval
FROM series;

INSERT INTO clinico.medicos
    (id_medico, nombre, apellidos, especialidad, activo)
SELECT 500 + n, 'MedicoFicticio' || n, 'Caso Prueba',
       CASE WHEN n % 2 = 0 THEN 'Imagenología ficticia' ELSE 'Medicina de prueba' END,
       true
FROM generate_series(1, 6) AS g(n);

INSERT INTO clinico.usuarios_administrativos
    (id_usuario, nombre, correo, activo) VALUES
    (601, 'Administrativo Ficticio 1', 'admin1@example.invalid', true),
    (602, 'Administrativo Ficticio 2', 'admin2@example.invalid', true);

INSERT INTO clinico.tipos_estudio
    (id_tipo, nombre, categoria, descripcion) VALUES
    (1, 'Ecografía de prueba', 'Imagen', 'Tipo ficticio para validar relaciones.'),
    (2, 'Radiografía de prueba', 'Imagen', 'Tipo ficticio para validar relaciones.'),
    (3, 'Laboratorio de prueba', 'Laboratorio', 'Tipo ficticio para validar relaciones.'),
    (4, 'Tomografía de prueba', 'Imagen', 'Tipo ficticio para validar relaciones.');

-- 1001/AL se atiende en la sucursal 1/SJ: ambas regiones se conservan separadas.
WITH enumerados AS (
    SELECT id_paciente, codigo_region,
           row_number() OVER (ORDER BY codigo_region, id_paciente) AS n
    FROM clinico.pacientes
)
INSERT INTO clinico.citas
    (id_cita, id_paciente, codigo_region, id_medico, id_sucursal, fecha_hora, estado)
SELECT 10000 + n, id_paciente, codigo_region, 501 + ((n - 1) % 6),
       CASE WHEN id_paciente = 1001 AND codigo_region = 'AL' THEN 1
            WHEN codigo_region = 'SJ' THEN 1
            WHEN codigo_region = 'AL' THEN 2 ELSE 3 END,
       TIMESTAMPTZ '2026-10-15 08:00:00+00' + (n || ' hours')::interval,
       CASE WHEN n <= 25 THEN 'COMPLETADA' ELSE 'PROGRAMADA' END
FROM enumerados;

INSERT INTO clinico.ordenes_medicas
    (id_orden, id_cita, fecha_emision, indicaciones, estado)
SELECT 20000 + n, 10000 + n,
       TIMESTAMPTZ '2026-10-17 08:00:00+00' + (n || ' hours')::interval,
       'Indicación sintética para pruebas de integridad ' || n, 'EMITIDA'
FROM generate_series(1, 25) AS g(n);

INSERT INTO clinico.estudios
    (id_estudio, id_orden, id_tipo, estado, fecha_realizacion)
SELECT 30000 + n, 20001 + ((n - 1) % 25), 1 + ((n - 1) % 4),
       CASE WHEN n <= 30 THEN 'FINALIZADO' ELSE 'SOLICITADO' END,
       CASE WHEN n <= 30 THEN
           TIMESTAMPTZ '2026-10-20 08:00:00+00' + (n || ' hours')::interval
       ELSE NULL END
FROM generate_series(1, 40) AS g(n);

INSERT INTO clinico.resultados_estudio
    (id_resultado, id_estudio, id_medico_firmante, resumen, fecha_resultado, revision)
SELECT 40000 + n, 30000 + n, 501 + ((n - 1) % 6),
       'Resultado sintético de prueba ' || n || '; sin información médica real.',
       TIMESTAMPTZ '2026-10-21 08:00:00+00' + (n || ' hours')::interval, 1
FROM generate_series(1, 30) AS g(n);

INSERT INTO clinico.diagnosticos
    (id_diagnostico, id_resultado, descripcion, codigo_diagnostico)
SELECT 50000 + n, 40000 + n,
       'Descripción ficticia de prueba ' || n, 'SIM-' || lpad(n::text, 3, '0')
FROM generate_series(1, 15) AS g(n);

-- eventos_integracion queda vacío: no se presenta el fixture como exportado.
COMMIT;
