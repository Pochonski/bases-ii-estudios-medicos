-- Joyce. SQL Server: base de integración externa (simulada) y catálogos.
-- Ejecutar con sqlcmd como administrador. Idempotente: crea solo lo que falta.
:on error exit
SET NOCOUNT ON;
IF DB_ID(N'integracion_externa') IS NULL
    CREATE DATABASE integracion_externa;
GO
USE integracion_externa;
GO
SET XACT_ABORT ON;
BEGIN TRANSACTION;

IF OBJECT_ID(N'dbo.aseguradoras', N'U') IS NULL
CREATE TABLE dbo.aseguradoras (
    id_aseguradora INT NOT NULL CONSTRAINT PK_aseguradoras PRIMARY KEY,
    nombre NVARCHAR(100) NOT NULL CONSTRAINT UQ_aseguradoras_nombre UNIQUE,
    codigo_externo VARCHAR(30) NOT NULL CONSTRAINT UQ_aseguradoras_codigo UNIQUE,
    activa BIT NOT NULL CONSTRAINT DF_aseguradoras_activa DEFAULT 1,
    CONSTRAINT CK_aseguradoras_id CHECK (id_aseguradora > 0),
    CONSTRAINT CK_aseguradoras_nombre CHECK (LEN(LTRIM(nombre)) > 0)
);

IF OBJECT_ID(N'dbo.convenios', N'U') IS NULL
CREATE TABLE dbo.convenios (
    id_convenio INT NOT NULL CONSTRAINT PK_convenios PRIMARY KEY,
    id_aseguradora INT NOT NULL
        CONSTRAINT FK_convenios_aseguradora REFERENCES dbo.aseguradoras (id_aseguradora),
    codigo_institucion VARCHAR(30) NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NULL,
    estado VARCHAR(20) NOT NULL,
    CONSTRAINT CK_convenios_id CHECK (id_convenio > 0),
    CONSTRAINT CK_convenios_estado CHECK (estado IN ('ACTIVO', 'VENCIDO', 'SUSPENDIDO')),
    CONSTRAINT CK_convenios_fechas CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio)
);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_convenios_aseguradora')
    CREATE INDEX IX_convenios_aseguradora ON dbo.convenios (id_aseguradora);

COMMIT;
GO
SELECT 'PASS 01: base integracion_externa, aseguradoras y convenios' AS resultado;
GO
