# Publicación, colaboración y protección del repositorio

**Repositorio:** https://github.com/Pochonski/bases-ii-estudios-medicos
**Visibilidad:** público, definido por el usuario el 21/10/2026. **Estado:** implementación parcial de Joseph; consultar la actualización al final.

## Acceso para agentes

Clonar el repositorio y leer `README.md` y `AGENTS.md`, luego `docs/00_ESTADO_Y_FUENTES.md`, `docs/01_REQUISITOS.md`, las decisiones en `docs/10_DECISIONES_Y_PENDIENTES.md` y el archivo de rol en `agents/`. No asumir que la conversación original estará disponible.

## Trabajo compartido

- Solicitar los usuarios de GitHub de Joyce y Armando; invitarlos como colaboradores si deben hacer push.
- Usar ramas `feat/joseph-*`, `feat/joyce-*`, `feat/armando-*` y PR revisables a `main`.
- Congelar interfaces para el traspaso del 25/10, según el plan; cambios posteriores requieren coordinación.
- Mantener bitácora y estado de pruebas con evidencia, no marcar implementado solo por documentación.

## Seguridad y visibilidad

- El repositorio es **público**. No publicar datos personales de pacientes, resultados clínicos reales, claves, tokens, secretos ni respaldos.
- El enunciado original del profesor se mantiene fuera del repositorio público; cada integrante debe consultarlo internamente.
- Publicar solo archivos de planificación y scripts no sensibles, revisados antes de hacer push.
- Las rutas `.env` y otras credenciales están excluidas en `.gitignore`. El README explica variables de configuración sin revelar secretos.

## Estado de la publicación

La creación del repositorio en GitHub y la publicación de documentos son actos distintos. La existencia de un enlace no demuestra que la planificación esté subida hasta comprobar los archivos y el commit remoto.

## Actualización — 22/10/2026, Joseph

Implementación parcial autorizada en feature/joseph-infra-postgresql. main se conserva;
PR en borrador al finalizar comprobaciones. La revisión de Joyce debe cubrir contrato SQL Server
y conectores; Armando mantiene las vistas/roles/reportes finales.
No se publican .env ni secretos generados; documentacion/ contiene instrucciones y fuentes.
