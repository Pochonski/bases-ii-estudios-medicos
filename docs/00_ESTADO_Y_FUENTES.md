# Estado real, fuentes y convención de certeza

**Corte funcional: 21/10/2026 · Zona horaria: America/Costa_Rica.** El corte inicial siguiente corresponde a planificación. La actualización vigente al final registra los archivos y pruebas realmente creados.

## Jerarquía de autoridad

1. **FUENTE CURSO:** documento original «Segundo Proyecto — Sistema de Gestión de Estudios Médicos Distribuido» (Bases de Datos II, ITCR; 5 páginas), entregado al equipo por el curso. El archivo íntegro no se publica aquí porque el repositorio es público; consúltese mediante Moodle o el grupo. Sus requisitos priman. `docs/01_REQUISITOS.md` resume requisitos con secciones/páginas como referencias.
2. **DECISIÓN GRUPO:** decisiones explícitas de conversación: despliegue en una PC; planificación completa antes de distribuir; Joseph/Joyce más trabajo; Armando implementa al final.
3. **DISEÑO PROPUESTO:** estructura de tablas, campos, nombres, mecanismos de sincronización y porcentajes de reparto diseñados en la conversación. Son baseline para trabajar, pero pueden ajustarse con aprobación.
4. **VERIFICACIÓN PENDIENTE:** compatibilidad, conectores, recursos, evaluación de Moodle y aceptación del despliegue en una PC.

Leyenda en documentos: **[CURSO]** = texto exigido; **[GRUPO]** = acordado; **[PROPUESTA]** = diseño; **[PENDIENTE]** = falta prueba o confirmación.

## Estado por componente al corte inicial (histórico)

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

## Actualización vigente — 22/10/2026, Joseph (D-025 a D-028)

Implementación autorizada por Joseph en su sesión; solo su alcance. El corte inicial arriba es histórico.

| Componente | Estado comprobable |
|---|---|
| Clonación/main/rama personal | IMPLEMENTADO Y PROBADO: main limpio 630cca6, rama feature/joseph-infra-postgresql |
| Compose, secretos, scripts PowerShell | IMPLEMENTADO Y PROBADO en validación estática local; ver evidencias/registros/2026-10-22-joseph-local.txt |
| Imagen con tds_fdw/mongo_fdw | IMPLEMENTADO, NO PROBADO localmente: build detenido por ausencia del daemon |
| Tres motores, healthchecks y persistencia | IMPLEMENTADO, NO PROBADO localmente |
| Preparación externo.ft_estado_facturacion | IMPLEMENTADO, NO PROBADO; perfil NOLOGIN, sin datos remotos simulados |
| P01 / contrato SQL Server | BLOQUEADO POR DEPENDENCIA de Joyce (vista, base, cuenta, tipos y fixture) |
| Esquema clínico / particiones / outbox / dataset | PENDIENTE: respetar gate de conectores de docs/06 |
| Mongo FDW funcional / exportación | PENDIENTE de pruebas conjuntas con Joyce; no reemplazado por driver |
| Vistas API, roles externos y agregaciones | PENDIENTE, corresponden a Armando |

Los candidatos están fijados por digest/hash para repetir el spike, con validación funcional pendiente.
No hay aceptación global P01–P18. Ver documentación de ejecución y reporte de esta sesión.

## Cierre verificado — 22/10/2026, Joseph

[CI 39747806912](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/39747806912)
PASA en SHA 89d0754, Ubuntu22/kernel 6.8.0-1070-azure:
build de ambos FDW, tres motores saludables, consultas autenticadas, CREATE EXTENSION/LOAD
y persistencia PostgreSQL tras reinicio (P12 parcial).
Windows sigue sin motor Docker disponible; no se acreditan consultas FDW remotas, BSON/escritura,
P01, P14 ni el outbox.
Evidencia: evidencias/registros/2026-10-22-joseph-ci-exito.txt.
Informe: documentacion/INFORME_CHATGPT_JOSEPH_FASE1.md. PR #1 en borrador, sin merge.
