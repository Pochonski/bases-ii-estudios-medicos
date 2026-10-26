# Handoff 25 de octubre: Joseph + Joyce → Armando

**Documento de control para traspaso; ninguna casilla se ha marcado como completada.** Momento previsto: final del 25/10/2026, una vez estables contratos y entorno. Inicia Armando el 26/10.

## Checklist técnico

- [ ] `postgres`, `sqlserver`, `mongodb` arrancan, reportan salud y tienen volúmenes.
- [ ] PostgreSQL implementó pacientes y particiones SJ, AL, CA.
- [ ] Datos ficticios clínicos cargados y sin errores de FK.
- [ ] SQL Server tiene aseguradoras, dos fragmentos, facturas y procedimiento.
- [ ] `dbo.vw_estado_facturacion` devuelve una fila por paciente-región.
- [ ] PostgreSQL consulta realmente la vista SQL Server por `tds_fdw`.
- [ ] MongoDB está accesible y tiene colección e índice único.
- [ ] Al menos un resultado confirmado de PG llegó **mediante integración real** a MongoDB.
- [ ] Identificadores/tipos/campos, fechas y regiones congelados/documentados.
- [ ] Comandos para ejecutar pruebas y rutas de archivos revisados; secretos transmitidos por canal seguro, no por Git.
- [ ] Riesgos técnicos abiertos y pruebas fallidas reportados explícitamente.

## Recibí de Joseph

- Commit/PR:
- Estado PG/FDW:
- Credenciales de acceso (canal seguro, no aquí):
- Observaciones:

## Recibí de Joyce

- Commit/PR: rama `feature/joyce-sqlserver-mongodb` (PR pendiente; Joyce aún sin permiso de escritura).
- Estado SQL Server/MongoDB: instalado y probado en Windows 11 local con `scripts/Install-JoyceModulos.ps1`
  y `scripts/Test-JoyceModulos.ps1` (todas PASAN; sin CI). Base `integracion_externa`, vista
  `dbo.vw_estado_facturacion`; MongoDB `reportes_medicos.resumenes_estudios`.
- Documento resumen y su revisión de prueba: estudio 30031 exportado por `mongo_fdw` en revisión 1 y
  actualizado a revisión 2; 32 resúmenes en total (INT-04).
- Observaciones: campos/tipos en `documentacion/JOYCE_SQLSERVER_MONGODB.md`. Joseph debe revisar el
  índice `eventos_logico_ux` y la secuencia `clinico.seq_resultados_estudio` (D-041).

## Armando: aceptación del traspaso

- Fecha y hora:
- Interfaces aceptadas:
- Bloqueos reportados:
- Plan de P02/P03/P09/P10/P11:

**Regla:** la falta de un prerequisito NO reasigna a Armando las tareas bloqueantes; Joseph/Joyce lo resuelven y reportan nuevos plazos al grupo.
