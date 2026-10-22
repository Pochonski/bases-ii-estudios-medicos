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

## Ejecución en Windows 11 posterior

- `registros/2026-10-22-joseph-despliegue-windows.txt`: diagnóstico y recuperación de
  Docker Desktop, fallo real de puertos del overlay anterior, pasarela local, salud,
  consultas, P12 parcial y selección Compose negativa. No contiene secretos.
- `documentacion/INFORME_WINDOWS_Y_PUERTOS_JOSEPH.md`: interpretación, comandos,
  límites, decisiones y dependencias. El CI anterior 39759092391 probó los cambios H1–H3;
  su binding en `HostConfig` no probaba publicación activa. La CI del gateway se registra
  por separado a continuación.
- `registros/2026-10-22-joseph-gateway-ci.txt`: CI 39807402214 SUCCESS sobre
  0b5e507, Windows Server ACL y Ubuntu base/localhost con puertos activos y P12 parcial.
  Artifacts descargados y revisados; no sustituyen la prueba en Windows 11.
