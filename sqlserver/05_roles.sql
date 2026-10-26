-- Joyce. Cuenta de servicio que usa tds_fdw desde PostgreSQL (perfil usr_fdw_pg_mssql).
-- La contraseña llega como variable de entorno FDW_MSSQL_PASSWORD (sqlcmd la expone como
-- variable de scripting); nunca se escribe en este archivo ni en Git.
:on error exit
USE master;
GO
IF SUSER_ID(N'svc_pg_mssql_ro') IS NULL
    CREATE LOGIN svc_pg_mssql_ro WITH PASSWORD = N'$(FDW_MSSQL_PASSWORD)',
        CHECK_POLICY = ON, DEFAULT_DATABASE = integracion_externa;
ELSE
    ALTER LOGIN svc_pg_mssql_ro WITH PASSWORD = N'$(FDW_MSSQL_PASSWORD)';
GO
USE integracion_externa;
GO
IF USER_ID(N'svc_pg_mssql_ro') IS NULL
    CREATE USER svc_pg_mssql_ro FOR LOGIN svc_pg_mssql_ro;
-- Solo lectura de la vista contractual. La cadena de propiedad dbo permite leerla
-- sin conceder SELECT sobre las tablas base.
GRANT SELECT ON OBJECT::dbo.vw_estado_facturacion TO svc_pg_mssql_ro;
-- Denegaciones explícitas para que la prueba negativa documente la intención.
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.paciente_integracion TO svc_pg_mssql_ro;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.paciente_cobertura TO svc_pg_mssql_ro;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.facturas_externas TO svc_pg_mssql_ro;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.resumen_facturacion TO svc_pg_mssql_ro;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.aseguradoras TO svc_pg_mssql_ro;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.convenios TO svc_pg_mssql_ro;
DENY EXECUTE ON SCHEMA::dbo TO svc_pg_mssql_ro;
GO
SELECT 'PASS 05: login svc_pg_mssql_ro con SELECT solo sobre dbo.vw_estado_facturacion' AS resultado;
GO
