-- Joyce. Vistas de SQL Server.
:on error exit
USE integracion_externa;
GO
-- Reconstrucción de la entidad fragmentada verticalmente (P15).
CREATE OR ALTER VIEW dbo.vw_paciente_asegurado AS
SELECT pin.id_paciente, pin.codigo_region, pin.id_aseguradora, pin.codigo_externo,
       pc.estado_cobertura, pc.estado_facturacion, pc.fecha_validacion
FROM dbo.paciente_integracion AS pin
JOIN dbo.paciente_cobertura AS pc
  ON pc.id_paciente = pin.id_paciente AND pc.codigo_region = pin.codigo_region;
GO
-- Contrato con PostgreSQL (externo.ft_estado_facturacion): UNA fila por (id_paciente, codigo_region).
-- Las facturas llegan preagregadas desde resumen_facturacion, así el JOIN no multiplica filas.
-- Un paciente sin fila aquí no tiene registro externo: PostgreSQL lo muestra con LEFT JOIN.
CREATE OR ALTER VIEW dbo.vw_estado_facturacion AS
SELECT pin.id_paciente,
       pin.codigo_region,
       a.nombre AS nombre_aseguradora,
       pc.estado_cobertura,
       pc.estado_facturacion,
       CAST(COALESCE(r.total_facturado_crc, 0) AS DECIMAL(12,2)) AS total_facturado_crc,
       COALESCE(r.fecha_actualizacion, pc.fecha_validacion) AS fecha_actualizacion
FROM dbo.paciente_integracion AS pin
JOIN dbo.paciente_cobertura AS pc
  ON pc.id_paciente = pin.id_paciente AND pc.codigo_region = pin.codigo_region
JOIN dbo.aseguradoras AS a
  ON a.id_aseguradora = pin.id_aseguradora
LEFT JOIN dbo.resumen_facturacion AS r
  ON r.id_paciente = pin.id_paciente AND r.codigo_region = pin.codigo_region;
GO
SELECT 'PASS 04: vistas de reconstrucción y de estado de facturación' AS resultado;
GO
