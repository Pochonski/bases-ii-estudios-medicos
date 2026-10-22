# Estado real, fuentes y convención de certeza

**Corte funcional: 21/10/2026 · Zona horaria: America/Costa_Rica.** No hay implementación realizada en este repositorio. Todos los SQL, JS, Dockerfiles y pruebas referidos en otros documentos son **nombres previstos**, no archivos existentes.

## Jerarquía de autoridad

1. **FUENTE CURSO:** documento original «Segundo Proyecto — Sistema de Gestión de Estudios Médicos Distribuido» (Bases de Datos II, ITCR; 5 páginas), entregado al equipo por el curso. El archivo íntegro no se publica aquí porque el repositorio es público; consúltese mediante Moodle o el grupo. Sus requisitos priman. `docs/01_REQUISITOS.md` resume requisitos con secciones/páginas como referencias.
2. **DECISIÓN GRUPO:** decisiones explícitas de conversación: despliegue en una PC; planificación completa antes de distribuir; Joseph/Joyce más trabajo; Armando implementa al final.
3. **DISEÑO PROPUESTO:** estructura de tablas, campos, nombres, mecanismos de sincronización y porcentajes de reparto diseñados en la conversación. Son baseline para trabajar, pero pueden ajustarse con aprobación.
4. **VERIFICACIÓN PENDIENTE:** compatibilidad, conectores, recursos, evaluación de Moodle y aceptación del despliegue en una PC.

Leyenda en documentos: **[CURSO]** = texto exigido; **[GRUPO]** = acordado; **[PROPUESTA]** = diseño; **[PENDIENTE]** = falta prueba o confirmación.

## Estado por componente

| Elemento | Estado al corte | Fuente |
|---|---|---|
| Enunciado y rúbrica textual | Recopilado | [CURSO] |
| Una sola PC Windows 11, Ryzen 5 5600G, 16 GB, RTX 5060 | Decidido | [GRUPO] |
| Tres contenedores Docker con WSL 2 | Arquitectura elegida, no instalada | [GRUPO]/[PROPUESTA] |
| PostgreSQL 16 / SQL Server 2022 Developer / MongoDB 8.0 | Preselección, no fijación final | [PROPUESTA] |
| `tds_fdw`, `mongo_fdw` y versiones concretas | No compilados ni probados | [PENDIENTE] |
| Modelos de tablas y colecciones | Documentados, no implementados | [PROPUESTA] |
| Fragmentación horizontal/vertical | Diseño, no evidencia | [CURSO]/[PROPUESTA] |
| Consultas FDW, sincronización y vistas API | Diseño, no ejecutadas | [CURSO]/[PROPUESTA] |
| Roles internos y externos | Nombres del curso, políticas propuestas | [CURSO]/[PROPUESTA] |
| Reparto 43/40/17 | Estimación orientativa tras decisión grupal | [GRUPO]/[PROPUESTA] |
| Pruebas P01–P13 | Planificadas, todas sin ejecutar | [PROPUESTA] |
| Video y entrega | Planificados, no producidos | [CURSO]/[PROPUESTA] |

## Ambigüedades que deben mantenerse visibles

- En el enunciado hay mención de `mongo_fdw` **o integración intermedia** en la descripción de PostgreSQL, pero otra sección exige `mongo_fdw`: pedir aclaración antes de sustituirlo.
- El título habla de sistema distribuido y tres servidores, pero **no exige literalmente tres PCs físicas**. El grupo eligió una PC con contenedores; confirmar aceptación docente si es necesario. No afirmar distribución física.
- El enunciado dice **«Martes 28 de octubre 2026»**, pero el **28/10/2026 es miércoles**. Confirmar fecha/hora que muestre Moodle. No corregir unilateralmente la fecha del enunciado.
- El enunciado da ejemplos ilustrativos de tablas y documentos que no constituyen por sí mismos modelos cerrados. Lo añadido aquí es diseño del equipo.
- El outbox, el worker, los mecanismos de recuperación y las pruebas de fallos son **mejoras propuestas**; no presentarlos como requisitos literales.
- SQL Server representa fuentes externas simuladas; no se conectará de verdad con aseguradoras ni ministerios.

## Actualización del estado

Cambiar a «implementado» solamente con archivos revisables; cambiar a «probado» únicamente con comandos y resultados guardados en `evidencias/`. El autor debe anotar fecha y hash de commit cuando sea posible. Registrar novedades en `docs/11_BITACORA.md`.
