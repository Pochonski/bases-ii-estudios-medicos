// Joyce. Cuenta de servicio que usa mongo_fdw desde PostgreSQL (perfil usr_fdw_pg_mongo).
// Mínimo privilegio: leer, insertar y actualizar SOLO resumenes_estudios; sin borrar ni
// administrar. La contraseña llega por la variable de entorno FDW_MONGO_PASSWORD.
// (03_datos_prueba.js del plan no se usa: los datos llegan solo por la exportación real.)
const password = process.env.FDW_MONGO_PASSWORD;
if (!password) { print('Falta FDW_MONGO_PASSWORD'); quit(3); }

const dbr = db.getSiblingDB('reportes_medicos');
const privilegios = [
  { resource: { db: 'reportes_medicos', collection: 'resumenes_estudios' },
    actions: ['find', 'insert', 'update'] }
];
if (dbr.getRole('rol_exportacion_resumenes') === null) {
  dbr.createRole({ role: 'rol_exportacion_resumenes', privileges: privilegios, roles: [] });
} else {
  dbr.updateRole('rol_exportacion_resumenes', { privileges: privilegios, roles: [] });
}
const roles = [{ role: 'rol_exportacion_resumenes', db: 'reportes_medicos' }];
if (dbr.getUser('svc_pg_mongo_rw') === null) {
  dbr.createUser({ user: 'svc_pg_mongo_rw', pwd: password, roles });
} else {
  dbr.updateUser('svc_pg_mongo_rw', { pwd: password, roles });
}
print('PASS 03: svc_pg_mongo_rw con find/insert/update sobre resumenes_estudios');
