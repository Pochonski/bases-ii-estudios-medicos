-- Joyce. Procedimientos que generan el resumen consultado por PostgreSQL (tds_fdw).
-- Política de agregación: las facturas ANULADA no cuentan; sin facturas válidas -> SIN_FACTURAS;
-- alguna PENDIENTE -> PENDIENTE; todas pagadas -> PAGADA.
:on error exit
USE integracion_externa;
GO
CREATE OR ALTER PROCEDURE dbo.sp_recalcular_resumen_facturacion
    @id_paciente BIGINT = NULL,
    @codigo_region CHAR(2) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF (@id_paciente IS NULL AND @codigo_region IS NOT NULL)
       OR (@id_paciente IS NOT NULL AND @codigo_region IS NULL)
        THROW 51010, 'Indique id_paciente y codigo_region juntos, o ninguno para recalcular todo.', 1;

    DECLARE @ahora DATETIMEOFFSET(0) = SYSDATETIMEOFFSET();

    BEGIN TRANSACTION;
    SELECT pin.id_paciente, pin.codigo_region,
           COUNT(f.id_factura) AS cantidad_facturas,
           CAST(COALESCE(SUM(f.monto), 0) AS DECIMAL(12,2)) AS total_facturado_crc,
           CASE WHEN COUNT(f.id_factura) = 0 THEN 'SIN_FACTURAS'
                WHEN SUM(CASE WHEN f.estado = 'PENDIENTE' THEN 1 ELSE 0 END) > 0 THEN 'PENDIENTE'
                ELSE 'PAGADA' END AS estado_facturacion
    INTO #agregado
    FROM dbo.paciente_integracion AS pin WITH (UPDLOCK, HOLDLOCK)
    LEFT JOIN dbo.facturas_externas AS f
           ON f.id_paciente = pin.id_paciente
          AND f.codigo_region = pin.codigo_region
          AND f.estado <> 'ANULADA'
    WHERE @id_paciente IS NULL
       OR (pin.id_paciente = @id_paciente AND pin.codigo_region = @codigo_region)
    GROUP BY pin.id_paciente, pin.codigo_region;

    IF @id_paciente IS NOT NULL AND NOT EXISTS (SELECT 1 FROM #agregado)
        THROW 51011, 'El paciente-región no está registrado en paciente_integracion.', 1;

    MERGE dbo.resumen_facturacion WITH (HOLDLOCK) AS destino
    USING #agregado AS origen
       ON destino.id_paciente = origen.id_paciente
      AND destino.codigo_region = origen.codigo_region
    WHEN MATCHED THEN UPDATE SET
        cantidad_facturas = origen.cantidad_facturas,
        total_facturado_crc = origen.total_facturado_crc,
        fecha_actualizacion = @ahora
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (id_paciente, codigo_region, cantidad_facturas, total_facturado_crc, fecha_actualizacion)
        VALUES (origen.id_paciente, origen.codigo_region, origen.cantidad_facturas,
                origen.total_facturado_crc, @ahora);

    UPDATE pc SET estado_facturacion = a.estado_facturacion
    FROM dbo.paciente_cobertura AS pc
    JOIN #agregado AS a ON a.id_paciente = pc.id_paciente AND a.codigo_region = pc.codigo_region;
    COMMIT;

    SELECT a.id_paciente, a.codigo_region, a.cantidad_facturas, a.total_facturado_crc,
           a.estado_facturacion, @ahora AS fecha_actualizacion
    FROM #agregado AS a
    ORDER BY a.codigo_region, a.id_paciente;
END;
GO

-- Simula la llegada de una factura desde un sistema externo y deja el resumen coherente
-- en la misma transacción SQL Server.
CREATE OR ALTER PROCEDURE dbo.sp_registrar_factura_externa
    @id_factura BIGINT,
    @id_estudio BIGINT,
    @id_paciente BIGINT,
    @codigo_region CHAR(2),
    @monto DECIMAL(12,2),
    @estado VARCHAR(20),
    @id_convenio INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRANSACTION;
    INSERT INTO dbo.facturas_externas
        (id_factura, id_estudio, id_paciente, codigo_region, id_convenio, monto, fecha, estado)
    VALUES (@id_factura, @id_estudio, @id_paciente, @codigo_region, @id_convenio, @monto,
            SYSDATETIMEOFFSET(), @estado);
    EXEC dbo.sp_recalcular_resumen_facturacion @id_paciente = @id_paciente,
                                               @codigo_region = @codigo_region;
    COMMIT;
END;
GO
SELECT 'PASS 03: procedimientos de resumen y registro de factura' AS resultado;
GO
