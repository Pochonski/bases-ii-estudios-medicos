\set ON_ERROR_STOP on
-- P01 / INT-01 con los objetos REALES de Joyce (base integracion_externa).
-- Ejecutar conectado como usr_fdw_pg_mssql (login propio, sin SET ROLE).
SELECT current_user AS usuario_conectado;
DO $$
BEGIN
  IF current_user <> 'usr_fdw_pg_mssql' THEN
    RAISE EXCEPTION 'Ejecutar con el login usr_fdw_pg_mssql';
  END IF;
END $$;

\echo '--- Filas remotas (SQL Server dbo.vw_estado_facturacion vía tds_fdw)'
SELECT * FROM externo.ft_estado_facturacion ORDER BY codigo_region, id_paciente;

\echo '--- Paciente PostgreSQL + estado de facturación SQL Server (LEFT JOIN)'
SELECT p.id_paciente, p.codigo_region, p.nombre,
       COALESCE(f.estado_cobertura, 'SIN_REGISTRO') AS estado_cobertura,
       COALESCE(f.estado_facturacion, 'SIN_REGISTRO') AS estado_facturacion,
       f.nombre_aseguradora, f.total_facturado_crc, f.fecha_actualizacion
FROM clinico.pacientes AS p
LEFT JOIN externo.ft_estado_facturacion AS f
  ON f.id_paciente = p.id_paciente AND f.codigo_region = p.codigo_region
WHERE p.id_paciente IN (1001, 1009, 2002, 3003)
ORDER BY p.codigo_region, p.id_paciente;

DO $$
DECLARE
  v_remotas integer; v_dupl integer; v_total integer; v_con integer; v_sin integer;
  v_estado text; v_monto numeric; v_aseg text;
BEGIN
  SELECT count(*) INTO v_remotas FROM externo.ft_estado_facturacion;
  SELECT count(*) INTO v_dupl FROM (SELECT 1 FROM externo.ft_estado_facturacion
                                    GROUP BY id_paciente, codigo_region HAVING count(*) > 1) AS d;
  SELECT count(*), count(f.id_paciente), count(*) - count(f.id_paciente)
    INTO v_total, v_con, v_sin
    FROM clinico.pacientes AS p
    LEFT JOIN externo.ft_estado_facturacion AS f
      ON f.id_paciente = p.id_paciente AND f.codigo_region = p.codigo_region;
  SELECT estado_facturacion, total_facturado_crc, nombre_aseguradora
    INTO v_estado, v_monto, v_aseg
    FROM externo.ft_estado_facturacion WHERE id_paciente = 1001 AND codigo_region = 'AL';

  RAISE NOTICE 'remotas=% duplicadas=% pacientes=% con_registro=% sin_registro=% 1001/AL=% % %',
    v_remotas, v_dupl, v_total, v_con, v_sin, v_estado, v_monto, v_aseg;
  IF v_remotas <> 24 OR v_dupl <> 0 THEN
    RAISE EXCEPTION 'FALLA P01: se esperaban 24 filas remotas únicas';
  END IF;
  IF v_total <> 30 OR v_con <> 24 OR v_sin <> 6 THEN
    RAISE EXCEPTION 'FALLA P01: el LEFT JOIN pierde o duplica pacientes';
  END IF;
  IF v_estado <> 'PENDIENTE' OR v_monto <> 23500.00 OR v_aseg <> 'Aseguradora Ficticia Ñandú' THEN
    RAISE EXCEPTION 'FALLA P01: valores remotos de 1001/AL inesperados';
  END IF;
  -- Regresión D-040: el filtro por un paciente sin registro no debe devolver filas.
  IF EXISTS (SELECT 1 FROM externo.ft_estado_facturacion WHERE id_paciente = 1009 AND codigo_region = 'AL') THEN
    RAISE EXCEPTION 'FALLA P01: WHERE ignorado por tds_fdw';
  END IF;
END $$;
\echo 'PASS P01: lectura real PostgreSQL -> SQL Server, 1 fila por paciente-región, LEFT JOIN 30/24/6'
