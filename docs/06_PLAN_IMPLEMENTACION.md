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
