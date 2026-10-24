# Plan de implementación reproducible

## Principio

La estructura siguiente es la **especificación inicial**; consultar la actualización al final para la implementación parcial autorizada. Añadir scripts, imágenes y configuraciones solo cuando el grupo autorice programar. Las siguientes rutas son **previstas**.

## Árbol de implementación esperado

```text
compose.yaml
.env.example
.dockerignore
docker/
  postgres/Dockerfile
  postgres/postgresql.conf
  postgres/pg_hba.conf
postgresql/
  01_esquemas.sql
  02_tablas.sql
  03_particiones.sql
  04_roles_externos.sql       # Armando, al final
  05_vistas_api.sql          # Armando, al final
  06_datos_prueba.sql
sqlserver/
  01_base_tablas.sql
  02_fragmentacion.sql
  03_procedimientos.sql
  04_vistas.sql
  05_roles.sql
  06_datos_prueba.sql
mongodb/
  01_colecciones.js
  02_indices.js
  03_datos_prueba.js       # solo si es necesario; no simular sincronización
  04_agregaciones.js       # Armando, al final
  05_validaciones.js       # Armando, al final
integracion/
  01_fdw_sqlserver.sql
  02_fdw_mongodb.sql
  sincronizacion/          # utilidad de outbox, formato por decidir
pruebas/
  integracion/
  seguridad/
  reportes/
evidencias/
  capturas/
  registros/
documentacion/
video/
```

## Orden con puertas de calidad (gates)

1. **Entorno:** confirmar WSL2, virtualización, disco, Docker Compose; motores responden consultas locales mínimas.
2. **Spikes de conectores tempranos:** compilar/instalar `tds_fdw` y `mongo_fdw` en la imagen PostgreSQL y verificar consulta de ejemplo (y escritura permitida a MongoDB). **No construir todo el esquema antes de evaluar esta incertidumbre**.
3. **Esquemas:** tablas, FKs, CHECK/UNIQUE, particiones, fragmentación vertical, colecciones e índices.
4. **Datos iniciales:** regiones, sucursales, médicos, tipos, pacientes, citas, órdenes, estudios; aseguradoras, fragmentos y facturas; coherencia de IDs.
5. **Integraciones:** `CREATE SERVER` y mappings PostgreSQL, vista remota SQL Server, vista federada, outbox y sincronización MongoDB.
6. **Seguridad:** roles internos; luego roles/vistas de Armando al comenzar fase final.
7. **Pruebas completas:** INT-01..05, seguridad negativa, reintentos, rollback, persistencia.
8. **Documentación y video:** reproducibilidad, evidencias y explicación narrada.

Orden exacto de ejecución entre módulos se actualizará cuando existan scripts. **No** ejecutar scripts de datos antes de crear sus estructuras, no asumir inicializadores automáticos con volúmenes que ya contienen datos.

## Política de idempotencia y datos

- Distinguir instalación inicial vacía de reinicio normal con volúmenes persistentes.
- Scripts de prueba repetibles sin duplicar registros, bajo datos sintéticos.
- Preparar restauración sin borrar volúmenes sin confirmación explícita.
- Respaldar scripts más exportaciones de datos; volumen persistente no equivale a backup.
- Al publicar en GitHub, usar ramas de trabajo y PR para revisar cambios compartidos.

## Responsable por carpetas

| Ruta futura | Responsable principal | Colaboración |
|---|---|---|
| `compose.yaml`, `docker/postgres/`, `postgresql/01..03`, `postgresql/06`, `integracion/01` | Joseph | Joyce revisa conectores |
| `sqlserver/*`, `mongodb/01..02`, `integracion/02`, `integracion/sincronizacion/` | Joyce | Joseph da soporte PG/Compose |
| `postgresql/04..05`, `mongodb/04..05`, `pruebas/seguridad`, `pruebas/reportes` | Armando, **etapa final** | Joseph/Joyce entregan contratos estables |
| `evidencias/`, `documentacion/`, `video/` | Todos por su módulo | Revisión grupal |

No crear tres Docker Compose incompatibles: **un único `compose.yaml` compartido**.

## Inicio autorizado parcial — 22/10/2026, Joseph

Se implementó la preparación de la etapa 1 y el build/pruebas del spike de etapa 2.
El motor Docker local no respondió; las pruebas de conectores aún no habilitan la etapa 3.
No se crearon las 12 tablas clínicas ni se delegaron tareas ajenas. La infraestructura incluye
un workflow Ubuntu para ejecutar el mismo build y smoke de extensiones/motores.
Manual: documentacion/JOSEPH_FASE1_WINDOWS.md. No usar creación de extensión como prueba
de lectura/escritura remota ni de sincronización.

## Adelanto aislado autorizado — 22/10/2026, Joseph

Joseph autorizó explícitamente implementar y probar solo su núcleo PostgreSQL antes de
resolver las consultas FDW reales. DDL, particiones y fixture se mantienen en el PR #2,
basado en la rama del PR #1, sin integrar SQL Server, MongoDB, worker ni vistas API.
Este adelanto **no supera** el gate 2: el orden de integración 3–7 y las dependencias de
Joyce permanecen. El runner crea bases de prueba vacías, ejecuta scripts en orden
`01_esquemas`, `02_tablas`, `03_particiones`, `06_datos_prueba` y luego pruebas,
conserva el volumen y elimina únicamente las bases sintéticas al pasar. Guía exacta:
`documentacion/JOSEPH_FASE2_POSTGRESQL.md`.

## Ruta de consolidación a main — 23/10/2026

PR #1 llevó infraestructura a `main`, mientras PR #2 se fusionó en la rama de
infraestructura. El PR #3 parte de `main` y reaplica, en orden, los cuatro commits
del núcleo de Joseph. Antes de ajustar el workflow, el árbol resultante coincidía
exactamente con el de la rama de infraestructura tras PR #2. La única corrección
funcional posterior es que el workflow se ejecute también al proponer cambios a
`main` y verifique la propagación de un error SQL controlado. No se reescribieron
ramas compartidas ni se duplicó Docker/Compose. La revisión del outbox queda como
propuesta pendiente de Joyce, sin modificar el contrato ni el gate 2.

## Spike TDS aislado — 24/10/2026, Joseph

Fase 4 autorizada: PR #4 apilado sobre PR #3 mientras éste siga sin merge.
`scripts/Test-TdsFdwSpike.ps1` levanta un proyecto efímero con solo PostgreSQL y
SQL Server; instala únicamente objetos SQL Server de **prueba de compatibilidad**
en `pruebas/integracion/`, sin sustituir los módulos de Joyce. Reutiliza el
consumidor `integracion/01_fdw_sqlserver.sql` y consulta con login PostgreSQL
propio. El runner comprueba tipos, varias filas, ausencia remota, mínimos
privilegios, caída y recuperación; la CI da la evidencia del runtime mientras
Docker Desktop Windows no está disponible. Guía:
`documentacion/JOSEPH_FASE4_TDS_FDW.md`.

El gate 2 se descompone para seguimiento: **TDS contra fixture temporal** se
evalúa en este PR; **TDS contra vista real de Joyce** y **Mongo FDW/BSON** siguen
pendientes. No avanzar la vista API de Armando ni afirmar integración completa
por el resultado del spike.
