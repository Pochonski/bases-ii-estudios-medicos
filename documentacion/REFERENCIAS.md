# Referencias bibliográficas y técnicas

El enunciado exige documentar toda fuente usada. Estas son las fuentes consultadas para
diseñar e implementar el proyecto. Son documentación oficial o repositorios fuente; no se
copió código de terceros salvo el parche local de `tds_fdw` (D-040), que se basa en el
issue citado. Formato: APA 7. Fecha de consulta: octubre de 2026.

## Motores y configuración

- PostgreSQL Global Development Group. (2024). *PostgreSQL 16 documentation: Table partitioning*. https://www.postgresql.org/docs/16/ddl-partitioning.html
- PostgreSQL Global Development Group. (2024). *PostgreSQL 16 documentation: The pg_hba.conf file*. https://www.postgresql.org/docs/16/auth-pg-hba-conf.html
- PostgreSQL Global Development Group. (2024). *PostgreSQL 16 documentation: CREATE SERVER, CREATE USER MAPPING, CREATE FOREIGN TABLE*. https://www.postgresql.org/docs/16/sql-createserver.html
- PostgreSQL Global Development Group. (2024). *PostgreSQL 16 documentation: Transaction management in procedures (PL/pgSQL)*. https://www.postgresql.org/docs/16/plpgsql-transactions.html
- PostgreSQL Global Development Group. (2024). *PostgreSQL 16 documentation: Rules and privileges / views (security_barrier)*. https://www.postgresql.org/docs/16/rules-privileges.html
- PostgreSQL Global Development Group. (2024). *PostgreSQL 16 documentation: Database roles and privileges*. https://www.postgresql.org/docs/16/user-manag.html
- PostgreSQL Global Development Group. (2024). *PostgreSQL 16 documentation: Advisory lock functions*. https://www.postgresql.org/docs/16/functions-admin.html
- PostgreSQL Global Development Group. (2024). *PostgreSQL 16 documentation: pg_dump and pg_restore*. https://www.postgresql.org/docs/16/app-pgdump.html
- Microsoft. (2024). *Quickstart: Run SQL Server Linux container images with Docker*. https://learn.microsoft.com/en-us/sql/linux/quickstart-install-connect-docker
- Microsoft. (2024). *CREATE PROCEDURE, MERGE, CREATE VIEW (Transact-SQL)*. https://learn.microsoft.com/en-us/sql/t-sql/statements/create-procedure-transact-sql
- Microsoft. (2024). *Ownership chains*. https://learn.microsoft.com/en-us/dotnet/framework/data/adonet/sql/ownership-chains
- Microsoft. (2024). *sqlcmd utility: scripting variables*. https://learn.microsoft.com/en-us/sql/tools/sqlcmd/sqlcmd-use-scripting-variables
- Microsoft. (2024). *BACKUP and RESTORE (Transact-SQL)*. https://learn.microsoft.com/en-us/sql/t-sql/statements/backup-transact-sql
- MongoDB, Inc. (2024). *Schema validation ($jsonSchema)*. https://www.mongodb.com/docs/manual/core/schema-validation/
- MongoDB, Inc. (2024). *Aggregation pipeline; $group; $merge*. https://www.mongodb.com/docs/manual/core/aggregation-pipeline/
- MongoDB, Inc. (2024). *User-defined roles*. https://www.mongodb.com/docs/manual/core/security-user-defined-roles/
- MongoDB, Inc. (2025). *MongoDB 8.0 release notes*. https://www.mongodb.com/docs/v8.0/release-notes/8.0/
- MongoDB, Inc. (2025). *mongosh EJSON.stringify and EJSON.parse*. https://www.mongodb.com/docs/mongodb-shell/reference/ejson/stringify/

## Foreign Data Wrappers

- tds-fdw contributors. (2024). *tds_fdw: PostgreSQL foreign data wrapper for Sybase and Microsoft SQL Server* (v2.0.5). GitHub. https://github.com/tds-fdw/tds_fdw
- tds-fdw contributors. (2024). *Issue #444: WHERE conditions ignored when using the query option*. GitHub. https://github.com/tds-fdw/tds_fdw/issues/444
- EnterpriseDB. (2025). *mongo_fdw: PostgreSQL foreign data wrapper for MongoDB* (REL-5_5_3). GitHub. https://github.com/EnterpriseDB/mongo_fdw
- FreeTDS Project. (2024). *FreeTDS user guide: freetds.conf*. https://www.freetds.org/userguide/freetdsconf.html

## Infraestructura

- Docker Inc. (2024). *Compose file reference: networks (internal), secrets, healthcheck*. https://docs.docker.com/reference/compose-file/
- Docker Inc. (2024). *Official image: postgres; mongo*. https://hub.docker.com/_/postgres

## Diseño de integración

- Richardson, C. (2018). *Microservices patterns* (cap. 3: transactional outbox). Manning. Patrón también descrito en https://microservices.io/patterns/data/transactional-outbox.html
- Özsu, M. T., & Valduriez, P. (2020). *Principles of distributed database systems* (4.ª ed.). Springer. (Fragmentación horizontal y vertical, reconstrucción sin pérdida.)

> Para la versión final, el grupo debe agregar las fuentes de la biblioteca TEC que haya
> consultado (https://www.tec.ac.cr/sistema-bibliotecas-tec) y declarar el uso de asistentes de IA
> si el curso lo exige.
