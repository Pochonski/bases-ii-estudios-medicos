-- P15. Reconstrucción sin pérdida ni duplicación de la entidad fragmentada verticalmente.
:on error exit
USE integracion_externa;
GO
SET NOCOUNT ON;
DECLARE @f1 INT = (SELECT COUNT(*) FROM dbo.paciente_integracion);
DECLARE @f2 INT = (SELECT COUNT(*) FROM dbo.paciente_cobertura);
DECLARE @rec INT = (SELECT COUNT(*) FROM dbo.vw_paciente_asegurado);
DECLARE @dist INT = (SELECT COUNT(*) FROM (SELECT DISTINCT id_paciente, codigo_region FROM dbo.vw_paciente_asegurado) AS d);
DECLARE @huerf1 INT = (SELECT COUNT(*) FROM dbo.paciente_integracion AS a
                       WHERE NOT EXISTS (SELECT 1 FROM dbo.paciente_cobertura AS b
                                         WHERE b.id_paciente = a.id_paciente AND b.codigo_region = a.codigo_region));
DECLARE @huerf2 INT = (SELECT COUNT(*) FROM dbo.paciente_cobertura AS b
                       WHERE NOT EXISTS (SELECT 1 FROM dbo.paciente_integracion AS a
                                         WHERE b.id_paciente = a.id_paciente AND b.codigo_region = a.codigo_region));
SELECT @f1 AS filas_fragmento_1, @f2 AS filas_fragmento_2, @rec AS filas_reconstruidas,
       @dist AS claves_distintas, @huerf1 AS sin_fragmento_2, @huerf2 AS sin_fragmento_1;
IF @f1 = 0 OR @f1 <> @f2 OR @rec <> @f1 OR @dist <> @rec OR @huerf1 <> 0 OR @huerf2 <> 0
    THROW 52015, 'FALLA P15: la reconstrucción vertical pierde o duplica filas', 1;

-- Columnas de cada fragmento: solo la clave se repite.
SELECT t.name AS fragmento, c.name AS columna
FROM sys.columns AS c JOIN sys.tables AS t ON t.object_id = c.object_id
WHERE t.name IN ('paciente_integracion', 'paciente_cobertura')
ORDER BY t.name, c.column_id;

SELECT TOP 5 * FROM dbo.vw_paciente_asegurado ORDER BY codigo_region, id_paciente;
PRINT 'PASS P15: fragmentos 1:1, reconstrucción sin pérdida ni duplicados';
GO
