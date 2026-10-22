# Contribución y control de cambios

## Flujo Git sugerido

- `main`: versión integrada y documentada.
- `feat/joseph-*`, `feat/joyce-*`, `feat/armando-*`: ramas por módulos; no compartir ramas de trabajo salvo coordinación.
- Cada PR documenta requisito afectado, archivos, contrato, pruebas ejecutadas, evidencia, riesgos y dependencias.
- Si cambia un contrato compartido, debe ser revisado por el responsable consumidor antes de fusionar.
- Antes de `merge` de material técnico, comprobar que no hay contraseñas ni datos médicos reales.
- Repositorio remoto **público** por decisión del grupo; agregar compañeros como colaboradores de escritura cuando se conozcan sus nombres de GitHub. No publicar secretos, datos médicos reales ni archivos del curso de circulación restringida.

## Modificaciones de decisiones

No borrar una decisión vieja de `docs/10_DECISIONES_Y_PENDIENTES.md`. Añadir nueva línea que explique qué cambió y por qué. Marcar preselecciones técnicas como verificadas solo con pruebas reales. Actualizar `docs/11_BITACORA.md` en cada sesión.

## Plantilla de PR

Ver `.github/PULL_REQUEST_TEMPLATE.md`.
