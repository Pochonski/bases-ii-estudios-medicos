-- Joyce. Segmentación VERTICAL de la entidad lógica "paciente asegurado".
-- Ambos fragmentos comparten la clave (id_paciente, codigo_region) del núcleo PostgreSQL
-- y se reconstruyen sin pérdida con un JOIN 1:1 (dbo.vw_paciente_asegurado, P15).
--   Fragmento 1 paciente_integracion: identidad e interoperabilidad (aseguradora, código externo).
--   Fragmento 2 paciente_cobertura:   estado de cobertura y de facturación.
-- No hay FK física hacia PostgreSQL: es otro motor y otra autoridad de datos.
:on error exit
USE integracion_externa;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;

IF OBJECT_ID(N'dbo.paciente_integracion', N'U') IS NULL
CREATE TABLE dbo.paciente_integracion (
    id_paciente BIGINT NOT NULL,
    codigo_region CHAR(2) NOT NULL,
    id_aseguradora INT NOT NULL
        CONSTRAINT FK_paciente_integracion_aseguradora REFERENCES dbo.aseguradoras (id_aseguradora),
    codigo_externo VARCHAR(40) NOT NULL CONSTRAINT UQ_paciente_integracion_codigo UNIQUE,
    CONSTRAINT PK_paciente_integracion PRIMARY KEY (id_paciente, codigo_region),
    CONSTRAINT CK_paciente_integracion_id CHECK (id_paciente > 0),
    CONSTRAINT CK_paciente_integracion_region CHECK (codigo_region IN ('SJ', 'AL', 'CA'))
);

IF OBJECT_ID(N'dbo.paciente_cobertura', N'U') IS NULL
CREATE TABLE dbo.paciente_cobertura (
    id_paciente BIGINT NOT NULL,
    codigo_region CHAR(2) NOT NULL,
    estado_cobertura VARCHAR(20) NOT NULL,
    -- Mantenido por dbo.sp_recalcular_resumen_facturacion a partir de las facturas.
    estado_facturacion VARCHAR(20) NOT NULL
        CONSTRAINT DF_paciente_cobertura_facturacion DEFAULT 'SIN_FACTURAS',
    fecha_validacion DATETIMEOFFSET(0) NOT NULL,
    CONSTRAINT PK_paciente_cobertura PRIMARY KEY (id_paciente, codigo_region),
    CONSTRAINT FK_paciente_cobertura_integracion FOREIGN KEY (id_paciente, codigo_region)
        REFERENCES dbo.paciente_integracion (id_paciente, codigo_region) ON DELETE CASCADE,
    CONSTRAINT CK_paciente_cobertura_estado
        CHECK (estado_cobertura IN ('VIGENTE', 'INACTIVA', 'PENDIENTE')),
    CONSTRAINT CK_paciente_cobertura_facturacion
        CHECK (estado_facturacion IN ('PAGADA', 'PENDIENTE', 'SIN_FACTURAS'))
);

IF OBJECT_ID(N'dbo.facturas_externas', N'U') IS NULL
CREATE TABLE dbo.facturas_externas (
    id_factura BIGINT NOT NULL CONSTRAINT PK_facturas_externas PRIMARY KEY,
    id_estudio BIGINT NOT NULL,          -- id_estudio de PostgreSQL, sin FK entre motores
    id_paciente BIGINT NOT NULL,
    codigo_region CHAR(2) NOT NULL,
    id_convenio INT NULL CONSTRAINT FK_facturas_convenio REFERENCES dbo.convenios (id_convenio),
    monto DECIMAL(12,2) NOT NULL,
    fecha DATETIMEOFFSET(0) NOT NULL,
    estado VARCHAR(20) NOT NULL,
    CONSTRAINT FK_facturas_paciente FOREIGN KEY (id_paciente, codigo_region)
        REFERENCES dbo.paciente_integracion (id_paciente, codigo_region),
    CONSTRAINT CK_facturas_id CHECK (id_factura > 0 AND id_estudio > 0),
    CONSTRAINT CK_facturas_monto CHECK (monto >= 0),
    CONSTRAINT CK_facturas_estado CHECK (estado IN ('PAGADA', 'PENDIENTE', 'ANULADA'))
);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_facturas_paciente')
    CREATE INDEX IX_facturas_paciente ON dbo.facturas_externas (id_paciente, codigo_region, estado);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_facturas_estudio')
    CREATE INDEX IX_facturas_estudio ON dbo.facturas_externas (id_estudio);

-- Resumen materializado: lo escribe únicamente el procedimiento de 03.
IF OBJECT_ID(N'dbo.resumen_facturacion', N'U') IS NULL
CREATE TABLE dbo.resumen_facturacion (
    id_paciente BIGINT NOT NULL,
    codigo_region CHAR(2) NOT NULL,
    cantidad_facturas INT NOT NULL,
    total_facturado_crc DECIMAL(12,2) NOT NULL,
    fecha_actualizacion DATETIMEOFFSET(0) NOT NULL,
    CONSTRAINT PK_resumen_facturacion PRIMARY KEY (id_paciente, codigo_region),
    CONSTRAINT FK_resumen_paciente FOREIGN KEY (id_paciente, codigo_region)
        REFERENCES dbo.paciente_integracion (id_paciente, codigo_region) ON DELETE CASCADE,
    CONSTRAINT CK_resumen_valores CHECK (cantidad_facturas >= 0 AND total_facturado_crc >= 0)
);

COMMIT;
GO
SELECT 'PASS 02: fragmentos verticales, facturas y resumen' AS resultado;
GO
