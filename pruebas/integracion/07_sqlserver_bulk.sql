-- Spike aislado de rendimiento. Datos sintéticos; nunca ejecutar en integracion_externa.
:on error exit
USE joseph_fdw_spike;
GO
SET NOCOUNT ON;
;WITH n AS (
  SELECT TOP (2000) ROW_NUMBER() OVER (ORDER BY a.object_id, b.object_id) AS x
  FROM sys.all_objects AS a CROSS JOIN sys.all_objects AS b
)
INSERT INTO dbo.facturacion_spike
  (id_paciente,codigo_region,nombre_aseguradora,estado_cobertura,
   estado_facturacion,total_facturado_crc,fecha_actualizacion)
SELECT CAST(6000000000 AS bigint)+x, 'SJ', N'Aseguradora sintética Ñ',
       N'VIGENTE', N'PAGADA', CAST(x AS decimal(12,2))/100,
       CONVERT(DATETIMEOFFSET(0), '2026-10-25T12:00:00+00:00')
FROM n;
IF (SELECT COUNT(*) FROM dbo.vw_estado_facturacion) <> 2004
    THROW 51020, 'Cardinalidad sintética incorrecta', 1;
SELECT COUNT(*) AS filas_remotas,
       SUM(DATALENGTH(nombre_aseguradora)+DATALENGTH(estado_cobertura)+
           DATALENGTH(estado_facturacion)+DATALENGTH(codigo_region)+
           DATALENGTH(id_paciente)+DATALENGTH(total_facturado_crc)+
           DATALENGTH(fecha_actualizacion)) AS bytes_columnas_estimados
FROM dbo.vw_estado_facturacion;
GO
