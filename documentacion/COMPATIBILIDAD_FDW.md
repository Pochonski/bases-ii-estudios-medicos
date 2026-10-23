# Spike de compatibilidad de FDW — Joseph / colaboración Joyce

Consulta de fuentes y artefactos: 21–22/10/2026. No congelar versiones funcionales hasta pruebas reales.
Los digests inmovilizan candidatos para poder repetir el spike; no equivalen a aprobación final.

| Componente | Candidato verificable | Evidencia / límite |
|---|---|---|
| PostgreSQL | 16.15, Debian bookworm, linux/amd64 | Metadato del manifiesto oficial de postgres:16-bookworm |
| SQL Server | 2022 Developer, CU27-GDR 16.0.4305.5 | SELECT @@VERSION en CI; digest en compose.yaml |
| MongoDB | 8.0.34-noble, linux/amd64 | Metadato oficial de mongo:8.0 |
| tds_fdw | 2.0.5, commit 5830577908683cb35c760079ec0f105ef7e3ff98 | Fuente declara PG 16 y FreeTDS, solo lectura |
| FreeTDS | libsybdb5 / freetds-dev 1.3.17+ds-2 | Versión registrada en apt del build CI |
| mongo_fdw | REL-5_5_3, commit 27aa7b04af197129bf10069c4b512a326c94f3f8 | Makefile acepta PG 16; release declara MongoDB 8 |
| mongo-c-driver | 1.30.2 con OpenSSL/Cyrus SASL | Versión indicada por el INSTALL de ese release |
| json-c | json-c-0.18-20240915 | Versión indicada por ese release |
| Otros paquetes apt | Repositorios del candidato Debian | No snapshot de apt; reproducción funcional prevista, no bit a bit |

## Comprobaciones ejecutadas

`git/gh` confirmaron los dos commits oficiales. Se descargaron en memoria cuatro archivos
y se calcularon SHA-256; los mismos hashes se comprueban en el Dockerfile.
`docker buildx imagetools inspect` confirmó los tres manifiestos sin necesitar daemon.
Ninguna de estas comprobaciones demuestra compilación o una consulta remota.

SHA-256:
- tds_fdw: `03c644bae1e40131e8974884d7aa41c8e6023aceb299ed33ba83bf1474f6d4d6`
- mongo_fdw: `375ebf5fd85a201a968c8895944f038720b49a17009607b6cbf50143f2648873`
- mongo-c-driver: `56224101eccd24bd71e42f806df8332b1280c2294b21b32c2da2d0f77cfa5cbe`
- json-c: `3112c1f25d39eca661fe3fc663431e130cc6e2f900c081738317fba49d29e298`

## Puertas de verificación

1. PASÓ en CI Ubuntu22: build real, ldd sin faltantes, CREATE EXTENSION y LOAD en PG16 (run 39747806912).
2. Consulta tds_fdw real a SQL Server, incluyendo UTF-8, fechas con offset y decimal.
3. Joyce: consulta e inserción/actualización reales mongo_fdw con BSON Int64, Int32, Date, ObjectId,
   índice único y revisión. Crear la extensión no prueba estas operaciones ni un UPSERT.
4. Confirmar privilegios mínimos, persistencia y fallos; solo entonces fijar versiones definitivas.
5. Pasar al DDL clínico y coordinar el contrato de outbox con Joyce; no adelantar worker ni APIs.

El extversion SQL de mongo_fdw puede ser 1.1 aunque el release del código sea 5.5.3;
registrar ambos por separado.

## Fuentes primarias

- [tds_fdw 2.0.5](https://github.com/tds-fdw/tds_fdw/tree/v2.0.5)
- [Opciones de servidor TDS](https://github.com/tds-fdw/tds_fdw/blob/v2.0.5/ForeignServerCreation.md)
- [mongo_fdw 5.5.3](https://github.com/EnterpriseDB/mongo_fdw/releases/tag/REL-5_5_3)
- [Instalación y dependencias](https://github.com/EnterpriseDB/mongo_fdw/blob/REL-5_5_3/INSTALL.md)
- [FreeTDS: cifrado y CA](https://www.freetds.org/userguide/freetdsconf.html)
- [Imagen PostgreSQL e inicialización](https://hub.docker.com/_/postgres)
- [Contenedor SQL Server y sqlcmd](https://learn.microsoft.com/en-us/sql/linux/quickstart-install-connect-docker?view=sql-server-ver16)
- [Secretos Compose](https://docs.docker.com/compose/how-tos/use-secrets/)

## Hallazgo experimental de kernel — 22/10/2026 (D-029)

Runs [39744770706](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/39744770706)
y [39747121313](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/39747121313):
build completo con tds_fdw y mongo_fdw PASÓ; PG inicializó ambas extensiones.
El arranque conjunto FALLÓ porque MongoDB emitió id 12257600 (kernel desde 6.19 incompatible).
La comprobación se cambia a ubuntu-22.04 y registra el kernel real; no altera Windows/WSL.
[Incidencia oficial SERVER-121912](https://jira.mongodb.org/browse/SERVER-121912),
[notas oficiales MongoDB 8.0](https://www.mongodb.com/docs/v8.0/release-notes/8.0/),
[imagen oficial del runner 22.04](https://github.com/actions/runner-images/blob/main/images/ubuntu/Ubuntu2204-Readme.md).
El kernel que usa Docker Desktop también deberá verificarse antes de fijar versiones definitivas.
