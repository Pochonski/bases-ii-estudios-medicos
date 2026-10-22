# Evidencias de Joseph — 22/10/2026

- registros/2026-10-22-joseph-local.txt: validación estática y build local bloqueado por daemon.
- registros/2026-10-22-joseph-ci-fallo.txt: fallo real de kernel MongoDB en los dos primeros runs.
- registros/2026-10-22-joseph-ci-exito.txt: build, tres motores, extensiones y persistencia PG en Ubuntu22.

El CI aprobó SHA 89d0754; no acredita funcionamiento en Windows ni consultas FDW/exportación.
Ver documentacion/INFORME_CHATGPT_JOSEPH_FASE1.md para resultados, límites y dependencias.
No agregar secretos, datos médicos reales ni capturas simuladas.

## Correcciones de auditoría H1–H3

- registros/2026-10-22-joseph-auditoria-windows.txt: DACL, .env/selección estáticos y daemon ausente.
- registros/2026-10-22-joseph-auditoria-ci.txt: CI 39759092391 / a801c88; ACL Windows Server y
  motores Ubuntu base/localhost, con bindings y una fila PG conservados tras restart.
- Artifacts revisados y retenidos 14 días; los extractos versionados conservan lo relevante.

P12 no acredita recreación/restauración ni persistencia de los tres motores. FDW/BSON/login propio pendientes.
El informe de correcciones contiene el head, comandos, resultados, archivos y límites.
