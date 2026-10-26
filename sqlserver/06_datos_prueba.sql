-- Joyce. Datos externos FICTICIOS alineados con postgresql/06_datos_prueba.sql.
-- La carga normal exige tablas vacías. Una reinicialización con datos requiere
-- SESSION_CONTEXT('joseph_fixture_reset')='EXPLICIT_LAB_RESET' en esta conexión,
-- fijado por el instalador solo después de validar un proyecto efímero.
--
-- Claves del núcleo PostgreSQL: pacientes AL 1001-1010, SJ 2001-2010, CA 3001-3010.
-- Estudio 30000+n -> orden ((n-1)%25)+1 -> cita/paciente en orden AL, CA, SJ:
--   órdenes 1-10 = AL 1001-1010, 11-20 = CA 3001-3010, 21-25 = SJ 2001-2005.
-- Casos de prueba:
--   1001/AL VIGENTE con factura PENDIENTE de 15000 (más una PAGADA)  -> PENDIENTE
--   2002/SJ INACTIVA con factura PENDIENTE
--   3003/CA PENDIENTE con su única factura ANULADA                    -> SIN_FACTURAS
--   1009, 1010, 2009, 2010, 3009, 3010 SIN registro externo           -> SIN_REGISTRO en PG
:on error exit
USE integracion_externa;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
-- Mantener el examen de tablas vacías y los DELETE en la misma transacción.
-- TABLOCKX/HOLDLOCK impide una inserción concurrente entre ambos pasos.
DECLARE @filas_existentes bigint =
  (SELECT COUNT(*) FROM dbo.aseguradoras WITH (TABLOCKX, HOLDLOCK)) +
  (SELECT COUNT(*) FROM dbo.convenios WITH (TABLOCKX, HOLDLOCK)) +
  (SELECT COUNT(*) FROM dbo.paciente_integracion WITH (TABLOCKX, HOLDLOCK)) +
  (SELECT COUNT(*) FROM dbo.paciente_cobertura WITH (TABLOCKX, HOLDLOCK)) +
  (SELECT COUNT(*) FROM dbo.facturas_externas WITH (TABLOCKX, HOLDLOCK)) +
  (SELECT COUNT(*) FROM dbo.resumen_facturacion WITH (TABLOCKX, HOLDLOCK));
IF @filas_existentes > 0 AND
   COALESCE(CONVERT(nvarchar(128), SESSION_CONTEXT(N'joseph_fixture_reset')), N'') <> N'EXPLICIT_LAB_RESET'
BEGIN
    ROLLBACK TRANSACTION;
    THROW 51021, 'Fixture SQL Server: existen datos; reinicializacion requiere contexto deliberado.', 1;
END;

DELETE FROM dbo.facturas_externas;
DELETE FROM dbo.resumen_facturacion;
DELETE FROM dbo.paciente_cobertura;
DELETE FROM dbo.paciente_integracion;
DELETE FROM dbo.convenios;
DELETE FROM dbo.aseguradoras;

INSERT INTO dbo.aseguradoras (id_aseguradora, nombre, codigo_externo, activa) VALUES
    (1, N'Aseguradora Ficticia Ñandú', 'ASG-FIC-001', 1),
    (2, N'Seguro Social Simulado', 'ASG-FIC-002', 1),
    (3, N'Cooperativa de Salud de Prueba', 'ASG-FIC-003', 0);

INSERT INTO dbo.convenios
    (id_convenio, id_aseguradora, codigo_institucion, fecha_inicio, fecha_fin, estado) VALUES
    (11, 1, 'INST-SIM-SJ', '2026-01-01', NULL, 'ACTIVO'),
    (12, 2, 'INST-SIM-AL', '2026-01-01', NULL, 'ACTIVO'),
    (13, 3, 'INST-SIM-CA', '2025-01-01', '2025-12-31', 'VENCIDO');

-- 8 pacientes registrados por región (n = 1..8). Aseguradora rota 1,2,3.
WITH regiones AS (
    SELECT codigo_region, base_id
    FROM (VALUES ('AL', CAST(1000 AS BIGINT)), ('SJ', 2000), ('CA', 3000)) AS r(codigo_region, base_id)
), numeros AS (
    SELECT n FROM (VALUES (1),(2),(3),(4),(5),(6),(7),(8)) AS g(n)
)
INSERT INTO dbo.paciente_integracion (id_paciente, codigo_region, id_aseguradora, codigo_externo)
SELECT r.base_id + g.n, r.codigo_region, 1 + ((g.n - 1) % 3),
       CONCAT('EXT-', r.codigo_region, '-', r.base_id + g.n)
FROM regiones AS r CROSS JOIN numeros AS g;

INSERT INTO dbo.paciente_cobertura
    (id_paciente, codigo_region, estado_cobertura, estado_facturacion, fecha_validacion)
SELECT id_paciente, codigo_region,
       CASE WHEN id_paciente IN (2002, 1005, 3006) THEN 'INACTIVA'
            WHEN id_paciente IN (3003, 2007) THEN 'PENDIENTE'
            ELSE 'VIGENTE' END,
       'SIN_FACTURAS',   -- lo recalcula el procedimiento al final
       CONVERT(DATETIMEOFFSET(0), '2026-10-01T08:00:00-06:00')
FROM dbo.paciente_integracion;

INSERT INTO dbo.facturas_externas
    (id_factura, id_estudio, id_paciente, codigo_region, id_convenio, monto, fecha, estado) VALUES
    (90001, 30001, 1001, 'AL', 12, 15000.00, CONVERT(DATETIMEOFFSET(0), '2026-10-21T09:00:00-06:00'), 'PENDIENTE'),
    (90002, 30026, 1001, 'AL', 12,  8500.00, CONVERT(DATETIMEOFFSET(0), '2026-10-21T10:00:00-06:00'), 'PAGADA'),
    (90003, 30002, 1002, 'AL', 12, 22000.00, CONVERT(DATETIMEOFFSET(0), '2026-10-21T11:00:00-06:00'), 'PAGADA'),
    (90004, 30003, 1003, 'AL', 12, 18000.00, CONVERT(DATETIMEOFFSET(0), '2026-10-21T12:00:00-06:00'), 'PAGADA'),
    (90005, 30004, 1004, 'AL', NULL, 11000.00, CONVERT(DATETIMEOFFSET(0), '2026-10-21T13:00:00-06:00'), 'PENDIENTE'),
    (90006, 30011, 3001, 'CA', 11, 30000.00, CONVERT(DATETIMEOFFSET(0), '2026-10-22T09:00:00-06:00'), 'PENDIENTE'),
    (90007, 30036, 3001, 'CA', 11,  5000.00, CONVERT(DATETIMEOFFSET(0), '2026-10-22T10:00:00-06:00'), 'PAGADA'),
    (90008, 30012, 3002, 'CA', 11, 12500.00, CONVERT(DATETIMEOFFSET(0), '2026-10-22T11:00:00-06:00'), 'PAGADA'),
    (90009, 30013, 3003, 'CA', NULL, 9000.00, CONVERT(DATETIMEOFFSET(0), '2026-10-22T12:00:00-06:00'), 'ANULADA'),
    (90010, 30021, 2001, 'SJ', 11, 45000.00, CONVERT(DATETIMEOFFSET(0), '2026-10-23T09:00:00-06:00'), 'PAGADA'),
    (90011, 30022, 2002, 'SJ', 11, 27500.00, CONVERT(DATETIMEOFFSET(0), '2026-10-23T10:00:00-06:00'), 'PENDIENTE');

COMMIT;
GO
EXEC dbo.sp_recalcular_resumen_facturacion;
GO
SELECT 'PASS 06: fixture ficticio cargado y resumen recalculado' AS resultado;
GO
