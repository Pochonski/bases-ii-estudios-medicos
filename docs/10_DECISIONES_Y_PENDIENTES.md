# Registro de decisiones (ADR abreviado), supuestos y riesgos

**Fecha del registro inicial:** 21/10/2026. Cada decisión distingue aprobación real del grupo, mandato docente o propuesta técnica. No actualizar su estado sin justificación y comunicación.

| ID | Decisión / hipótesis | Estado | Motivo y consecuencias |
|---|---|---|---|
| D-001 | Usar tres motores PostgreSQL, SQL Server y MongoDB | **[CURSO]** | Rol complementario de cada motor |
| D-002 | No desarrollar web ni móvil; preparar roles/vistas | **[CURSO]** | Alcance académico |
| D-003 | Ejecutar tres motores en **una PC** | **[GRUPO]** | Trabajo centralizado; aceptación por docente pendiente si interpreta distribución física |
| D-004 | Windows 11, Ryzen 5 5600G, 16 GB, GPU RTX 5060 | **[GRUPO]** | Host disponible; falta prueba del entorno |
| D-005 | Docker Desktop + WSL 2, red privada y volúmenes | **[PROPUESTA ACEPTADA COMO PLAN]** | Servidores aislados lógicamente |
| D-006 | Tres regiones SJ/AL/CA y pacientes ficticios | **[PROPUESTA]** | Ejemplos alineados al curso |
| D-007 | PostgreSQL fuente clínica; SQL Server fuente externa; MongoDB analítica | **[CURSO]** | Evita doble autoridad de datos |
| D-008 | Modelo PostgreSQL de 12 tablas incluido outbox | **[PROPUESTA]** | Satisface casos y habilita recuperación |
| D-009 | PK paciente `(id_paciente,codigo_region)` y particiones LIST | **[PROPUESTA]** | Restricción PG por clave de partición |
| D-010 | Fragmentar entidad paciente asegurado por columnas en SQL Server | **[PROPUESTA]** | Reconstruible mediante JOIN de fragmentos |
| D-011 | `tds_fdw` solo lectura a `dbo.vw_estado_facturacion` | **[PROPUESTA; probar]** | Vista devuelve una fila por paciente-región |
| D-012 | `mongo_fdw` prioridad; alternativa intermedia condicional | **[PROPUESTA CON RIESGO DOCENTE]** | Dos apartados del enunciado no coinciden |
| D-013 | Confirmación PG → outbox → exportación MongoDB | **[PROPUESTA]** | Consistencia eventual y reintentos |
| D-014 | Único resumen por `id_estudio`, índice UNIQUE, `revision` | **[PROPUESTA]** | Idempotencia / no regresión de versión |
| D-015 | IDs tipo BIGINT/Int64 y fechas UTC; colones CRC | **[PROPUESTA]** | Contrato intermotor |
| D-016 | PostgreSQL 16 / SQL Server 2022 Developer / MongoDB 8 | **[PRESELECCIÓN; no validada]** | Congelar únicamente después del spike de FDW |
| D-017 | Roles internos y externos con cuatro nombres del enunciado | **[CURSO]** | Permisos mínimos concretados en doc de seguridad |
| D-018 | Joseph y Joyce más trabajo; Armando al final | **[GRUPO]** | Armando no debe bloquear etapas iniciales |
| D-019 | Reparto orientativo 43%/40%/17% | **[PROPUESTA ORGANIZATIVA]** | No medición ni calificación |
| D-020 | Traspaso 25/10, Armando comienza 26/10 | **[PROPUESTA ORGANIZATIVA]** | Congelar interfaces y trabajar con base estable |
| D-021 | Git y repositorio remoto **privado** (propuesta anterior) | **[SUPERADA POR D-024]** | Se sugirió privacidad antes de que el grupo creara el repositorio público |
| D-022 | Documentar antes de dividir/implementar | **[GRUPO]** | Evitar divergencia entre agentes |
| D-023 | No presentar outbox como ACID distribuido | **[CRITERIO TÉCNICO]** | Solo COMMIT local + consistencia eventual |
| D-024 | Repositorio público en `Pochonski/bases-ii-estudios-medicos` | **[GRUPO; 21/10/2026]** | Sustituye D-021. No publicar secretos, datos reales ni enunciado docente original; documentación y guías para agentes sí. |

## Pendientes prioritarios (en orden)

1. **[P0]** Confirmar Moodle: ¿cierre 28/10/2026 23:59? El enunciado lo llama martes y la fecha es miércoles.
2. **[P0]** Aclarar con docente si una PC con tres contenedores satisface «distribuido», si el grupo de 3 es aceptado ante la redacción «grupos de 4 personas» y, especialmente, si una integración intermedia a MongoDB es aceptable cuando `mongo_fdw` falla.
3. **[P0]** Verificar virtualización, espacio SSD, WSL2 y Docker en PC real.
4. **[P0]** Validar compilación y consultas reales `tds_fdw` con versiones elegidas.
5. **[P0]** Validar `mongo_fdw` incluyendo inserción, actualización, `_id`, tipos BSON e índice único; confirmar matriz de versiones con MongoDB.
6. **[P1]** Fijar DDL exacto de tablas SQL Server, estrategia de evento/idempotencia y tipo final de worker sin sobrepasar requisitos.
7. **[P1]** Decidir rol técnico específico para procesador outbox y manejo seguro de credenciales.
8. **[P1]** Confirmar nombres de usuario GitHub de Joyce y Armando, colaboradores y ramas de trabajo.
9. **[P1]** Conseguir evidencia real P01–P18, preparar manual y video.

## Riesgos

| Riesgo | Impacto | Mitigación |
|---|---|---|
| `mongo_fdw` incompatible / dependencias | Alto | Spike temprano; registrar error y pedir alternativa al docente |
| `tds_fdw` falla en imagen PG | Alto | Validar FreeTDS/bibliotecas y servicio remoto antes del esquema |
| Host consume demasiada RAM | Medio/alto | Limitar cargas, revisar WSL2, ajustar recursos, usar dataset pequeño |
| Datos no coinciden entre motores | Alto | Dataset compartido y contratos únicos de IDs |
| Cambios de esquema tras traspaso | Alto | Congelación y revisión de cambios el 25 |
| SQL Server down rompe vista | Medio | Prueba del fallo, explicar indisponibilidad, no inventar datos |
| Worker duplica documentos | Alto | UNIQUE, revisión, idempotencia y P07/P08 |
| Pérdida de equipo o volúmenes | Alto | Commits remotos + respaldos exportables |
| Entrega tarde / video omitido | Alto | Material listo 27/10, validación Moodle |

## Registro de nuevas decisiones

Agregar filas `D-024` y siguientes con **fecha**, **proponente**, **fuente** (curso/grupo/propuesta), **estado**, **consecuencias**, **archivos afectados** y **evidencia** si ya se probó. No borrar decisiones anteriores: marcarlas supersedidas y enlazar reemplazo.
