# División de trabajo acordada — Joseph, Joyce y Armando

**Decisión explícita del grupo (21/10/2026):** Joseph y Joyce asumen más trabajo, empezando primero; **Armando implementa al final y no debe encargarse de bloqueantes iniciales**. La distribución es propuesta organizativa, modificable por acuerdo, no porcentajes medidos.

| Integrante | Esfuerzo orientativo | Fase | Objetivo |
|---|---:|---|---|
| Joseph | 43% | 22–25 oct | Docker + PostgreSQL + FDW SQL Server + coordinación |
| Joyce | 40% | 22–25 oct | SQL Server + MongoDB + FDW Mongo + exportación |
| Armando | 17% | 26–27 oct | Roles/vistas externas + agregaciones + pruebas finales |

## Joseph — entrega temprana

**Hace:** entorno compartido Compose, red y volúmenes; PostgreSQL (esquemas, tablas, llaves, FKs, particiones SJ/AL/CA); carga clínica ficticia; `tds_fdw` y tabla extranjera a SQL Server; coordinación del esquema y apoyo para imagen PG con extensiones; configuración de autenticación y FDW internos.

**No se le delega:** reportes analíticos finales ni vistas API asignadas a Armando.

**Gate:** PostgreSQL operativo con particiones reales y datos coherentes; consulta remota a vista SQL Server validada.

**Archivos futuros:** `compose.yaml`, `docker/postgres/*`, `postgresql/01_esquemas.sql`, `02_tablas.sql`, `03_particiones.sql`, `06_datos_prueba.sql`, `integracion/01_fdw_sqlserver.sql`.

## Joyce — entrega temprana

**Hace:** SQL Server: aseguradoras, convenios, paciente fragmentado por columnas, facturas, procedimiento de resumen, vista remota; MongoDB: colección, índices y roles remotos; `mongo_fdw` y proceso outbox PostgreSQL → MongoDB; errores, reintentos y verificación idempotente; imágenes/driver con Joseph.

**Gate:** fragmentación vertical demostrada; consulta federada PG/SQL Server funcionando en colaboración; documento de resultado confirmado aparece/actualiza en MongoDB.

**Archivos futuros:** `sqlserver/01..06`, `mongodb/01_colecciones.js`, `02_indices.js`, `integracion/02_fdw_mongodb.sql`, `integracion/sincronizacion/*`.

## Armando — implementación TARDÍA

**Inicia tentativamente 26 de octubre**, una vez recibido un sistema estable. No se encarga de la instalación inicial, creación de motores, tablas transaccionales, fragmentación, conectores ni sincronización. Sí desarrolla componentes de software concretos (no solo redacta):

1. Consultas analíticas MongoDB: estudios por médico, por tipo, por sucursal y por mes; especialmente **médico × tipo** (INT-05).
2. Roles `usr_api_web`, `usr_api_mobile` y concesiones mínimas, con pruebas positivas/negativas.
3. Vistas `api.vw_paciente_facturacion`, `api.vw_citas_web`, `api.vw_citas_mobile` bajo esquema estable.
4. Pruebas documentadas de reportes, vistas y permisos, además de capturas correspondientes.

**Gate:** las consultas dan resultados comprobables; ambos roles tienen accesos diferenciados; captura y prueba negativa de cada permiso relevante.

**Archivos futuros:** `postgresql/04_roles_externos.sql`, `05_vistas_api.sql`, `mongodb/04_agregaciones.js`, `05_validaciones.js`, `pruebas/seguridad/*`, `pruebas/reportes/*`.

## Reglas de traspaso 25/10

Joseph/Joyce entregan a Armando: contenedores listos, esquema y datos, particiones demostradas, SQL Server preparado, consulta FDW PG↔SQL funcionando, MongoDB con índices, un resumen confirmado sincronizado, nombres/tipos y comandos de acceso no secretos, README actualizado. Ver checklist `agents/HANDOFF_25_OCT.md`.

**Congelación de interfaces:** desde el traspaso, no renombrar columnas, vistas, documentos o tipos sin comunicar y registrar cambio; arreglar fallas críticas sí es válido con trazabilidad.

Si algo previo falla el 25/10, **Joseph/Joyce siguen siendo responsables**; Armando avanza con tareas locales o pruebas sin cargarle ese bloqueo.

## Documentación y video

Cada uno documenta sus propias decisiones y pruebas. Video narrado por **todos**: Joseph ~2:30 (arquitectura/PG), Joyce ~2:30 (SQL Server/MongoDB/sincronización), Armando ~1:45 (vistas/reportes/permisos). Total orientativo 6:45; guion final sujeto a evidencias reales.
