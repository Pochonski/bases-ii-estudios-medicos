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

- Commit/PR:
- Estado SQL Server/MongoDB:
- Documento resumen y su revisión de prueba:
- Observaciones:

## Armando: aceptación del traspaso

- Fecha y hora:
- Interfaces aceptadas:
- Bloqueos reportados:
- Plan de P02/P03/P09/P10/P11:

**Regla:** la falta de un prerequisito NO reasigna a Armando las tareas bloqueantes; Joseph/Joyce lo resuelven y reportan nuevos plazos al grupo.
