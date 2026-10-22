# Agente de Joseph — infraestructura y PostgreSQL

**Prioridad temporal:** fase inicial 22–25/10; ~43% del esfuerzo orientativo. **Primero leer `../AGENTS.md`, `../docs/00_ESTADO_Y_FUENTES.md` y los contratos.**

## Misión

Levantar entorno reproducible (después de autorización), PostgreSQL principal, particiones reales y acceso de lectura a SQL Server; coordinar interfaces y entregar entorno estable a Armando antes de 26/10.

## Alcance autorizado SOLO cuando comience implementación

- `compose.yaml` con servicios `postgres`, `sqlserver`, `mongodb`, healthchecks, puertos seguros, volúmenes, red y variables externas.
- Imagen PostgreSQL con `tds_fdw` y soporte `mongo_fdw` en colaboración con Joyce; realizar pruebas mínimas tempranas.
- PostgreSQL: `regiones`, `sucursales`, `pacientes` LIST partition, médicos, administrativos, citas, órdenes, tipos, estudios, resultados, diagnósticos y estructura outbox acordada.
- Integridad referencial compuesta de pacientes: no confundir región registrada con región de atención.
- Datos falsos reproducibles y contratos de IDs estables.
- Config de FDW SQL Server: FOREIGN SERVER/mapping/foreign table `externo.ft_estado_facturacion`, compatible con vista entregada por Joyce.
- Preparación de perfiles internos y políticas de conexión, sin sustituir tareas de roles externos de Armando.

## Entregables futuros

`compose.yaml`, `docker/postgres/*`, `postgresql/01_esquemas.sql`, `02_tablas.sql`, `03_particiones.sql`, `06_datos_prueba.sql`, `integracion/01_fdw_sqlserver.sql`, pruebas P01/P14 y aportes P02/P17/P18.

## Interfaces recibidas / entregadas

**Recibes de Joyce:** `dbo.vw_estado_facturacion`, nombres de SQL Server, credenciales de servicio por canal seguro y documentación de tipos; resultado de compilación Mongo FDW.

**Entregas a Joyce:** tablas clínicas, IDs, entidades relacionadas y outbox; base preparada para sincronización. **Entregas a Armando (25/10):** tablas y vistas extranjeras estables, datos y guía sin secretos.

## Criterios de aceptación

- Motores responden dentro de la red; PG persiste tras reinicio.
- `pacientes` repartidos efectivamente en tres particiones y demostrado con EXPLAIN.
- Consulta PG→SQL Server real con evidencia; fallback no debe fingir consulta remota.
- Tablas/FKs coherentes; campos acordados; `pg_hba.conf` y `postgresql.conf` documentados.

## Lo que NO debes hacer

No construir las vistas API/reportes de Armando por defecto; no editar datos externos SQL Server sin coordinación; no afirmar que Docker ya funciona ni que existe una transacción ACID global.

### Informe de fin de sesión

Usar formato en `PROTOCOLO_AGENTES.md`, con salidas de P01, P14, P17 según lo ejecutado.
