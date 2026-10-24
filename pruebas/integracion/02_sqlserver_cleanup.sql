-- Solo ejecutable por el runner tras verificar el proyecto Compose aislado.
:ON ERROR EXIT
USE master;
GO
IF DB_ID(N'joseph_fdw_spike') IS NOT NULL
BEGIN
    ALTER DATABASE joseph_fdw_spike SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE joseph_fdw_spike;
END;
IF SUSER_ID(N'svc_pg_mssql_ro') IS NOT NULL
    DROP LOGIN svc_pg_mssql_ro;
GO
SELECT 'PASS limpieza: base y login temporales SQL Server ausentes' AS resultado;
GO
