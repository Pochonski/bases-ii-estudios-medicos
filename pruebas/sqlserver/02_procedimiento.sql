-- P16. El procedimiento genera un resumen coherente con las facturas y la vista contractual
-- lo refleja con una fila por paciente-región. Todo se revierte al final.
:on error exit
USE integracion_externa;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

-- Coherencia del resumen materializado con las facturas válidas.
IF EXISTS (
    SELECT 1
    FROM dbo.resumen_facturacion AS r
    OUTER APPLY (SELECT COUNT(*) AS n, COALESCE(SUM(monto), 0) AS total
                 FROM dbo.facturas_externas AS f
                 WHERE f.id_paciente = r.id_paciente AND f.codigo_region = r.codigo_region
                   AND f.estado <> 'ANULADA') AS f
    WHERE r.cantidad_facturas <> f.n OR r.total_facturado_crc <> f.total)
    THROW 52016, 'FALLA P16: resumen_facturacion no coincide con las facturas', 1;

IF EXISTS (SELECT 1 FROM dbo.vw_estado_facturacion GROUP BY id_paciente, codigo_region HAVING COUNT(*) > 1)
    THROW 52017, 'FALLA P16: la vista devuelve más de una fila por paciente-región', 1;

SELECT * FROM dbo.vw_estado_facturacion
WHERE (id_paciente = 1001 AND codigo_region = 'AL') OR (id_paciente = 3003 AND codigo_region = 'CA');

BEGIN TRANSACTION;
SELECT 'antes' AS momento, * FROM dbo.vw_estado_facturacion WHERE id_paciente = 2003 AND codigo_region = 'SJ';
EXEC dbo.sp_registrar_factura_externa @id_factura = 99901, @id_estudio = 30023,
     @id_paciente = 2003, @codigo_region = 'SJ', @monto = 7250.50, @estado = 'PENDIENTE';
SELECT 'despues' AS momento, * FROM dbo.vw_estado_facturacion WHERE id_paciente = 2003 AND codigo_region = 'SJ';
IF NOT EXISTS (SELECT 1 FROM dbo.vw_estado_facturacion
               WHERE id_paciente = 2003 AND codigo_region = 'SJ'
                 AND estado_facturacion = 'PENDIENTE' AND total_facturado_crc = 7250.50)
    THROW 52018, 'FALLA P16: el procedimiento no actualizó el resumen', 1;
ROLLBACK;

BEGIN TRY
    EXEC dbo.sp_recalcular_resumen_facturacion @id_paciente = 1001;
    THROW 52019, 'FALLA P16: aceptó parámetros incompletos', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 51010 THROW;
    PRINT 'PASS negativo: parámetros incompletos rechazados (51010)';
END CATCH;
PRINT 'PASS P16: procedimiento coherente, vista 1 fila por paciente-región, cambio revertido';
GO
