# Protocolo para múltiples agentes de desarrollo

1. Lee `../AGENTS.md` y **tu** archivo personal. No uses la conversación original como única fuente; este repo lleva el estado compartido.
2. Si hay diferencias entre documentos, sigue orden de autoridad de `docs/00_ESTADO_Y_FUENTES.md` y registra incidencia. Nunca inventes una aprobación.
3. Antes de implementar comprueba que el grupo pasó de **PLANIFICACIÓN** a **IMPLEMENTACIÓN AUTORIZADA**. La existencia de estas guías NO autoriza código.
4. Cada módulo tiene dueño principal. No renombrar campos compartidos sin consulta y entrada en registro de decisiones.
5. Trabaja en rama personal (`feat/joseph-*`, `feat/joyce-*`, `feat/armando-*`) cuando el repo esté en GitHub; PRs contra `main`. Mantén entregables pequeños.
6. Nunca insertar credenciales, datos clínicos reales o resultados de pruebas inventados.
7. Informa siempre: **contexto leído; objetivo; archivos cambiados; comandos; pruebas y resultado; compatibilidad; bloqueos; riesgos; tareas siguientes; preguntas**.
8. No crear commits o pushes remotos a nombre de otra persona sin aprobación explícita. No dar por revisado tu propio PR.
9. Tras completar módulo, actualizar bitácora, matriz de pruebas y estado del componente en `docs/00_ESTADO_Y_FUENTES.md`.
10. Armando trabaja al final sobre el sistema integrado. No pedirle configurar conexiones/estructuras que debieron preparar Joseph y Joyce.

## Formato recomendado de informe para otro agente

```markdown
# INFORME PARA REVISIÓN CRUZADA
- Responsable y módulo:
- Commit / rama:
- Contratos usados:
- Archivos añadidos/modificados:
- Decisiones nuevas y justificación:
- Comandos ejecutados:
- Pruebas Pxx: PASA/FALLA/NO EJECUTADA + evidencia:
- Errores encontrados y limitaciones:
- Dependencias para el siguiente compañero:
- Próxima acción:
```
