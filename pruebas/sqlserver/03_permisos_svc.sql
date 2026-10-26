-- Permisos de svc_pg_mssql_ro. Ejecutar CONECTADO como svc_pg_mssql_ro (no como sa).
:on error exit
USE integracion_externa;
GO
SET NOCOUNT ON;
SELECT SUSER_SNAME() AS login_actual;
IF SUSER_SNAME() <> N'svc_pg_mssql_ro' THROW 52020, 'Ejecutar con el login svc_pg_mssql_ro', 1;

SELECT COUNT(*) AS filas_vista FROM dbo.vw_estado_facturacion;
PRINT 'PASS positivo: SELECT sobre dbo.vw_estado_facturacion';

BEGIN TRY
    SELECT TOP 1 id_factura FROM dbo.facturas_externas;
    THROW 52021, 'FALLA: lectura directa de tabla base permitida', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 229 THROW;
    PRINT 'PASS negativo: SELECT dbo.facturas_externas denegado (229)';
END CATCH;

BEGIN TRY
    INSERT INTO dbo.paciente_cobertura (id_paciente, codigo_region, estado_cobertura, fecha_validacion)
    VALUES (1009, 'AL', 'VIGENTE', SYSDATETIMEOFFSET());
    THROW 52022, 'FALLA: INSERT permitido', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 229 THROW;
    PRINT 'PASS negativo: INSERT dbo.paciente_cobertura denegado (229)';
END CATCH;

BEGIN TRY
    EXEC dbo.sp_recalcular_resumen_facturacion;
    THROW 52023, 'FALLA: EXECUTE permitido', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 229 THROW;
    PRINT 'PASS negativo: EXECUTE de procedimiento denegado (229)';
END CATCH;
GO
