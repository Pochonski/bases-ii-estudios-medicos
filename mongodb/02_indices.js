// Joyce. Índices de MongoDB. createIndex es idempotente con la misma especificación.
const dbr = db.getSiblingDB('reportes_medicos');
const res = dbr.getCollection('resumenes_estudios');

// Un único resumen por estudio: impide duplicados aunque se reintente la exportación.
res.createIndex({ id_estudio: 1 }, { unique: true, name: 'ux_id_estudio' });
// Apoyan la agregación obligatoria médico x tipo y las de sucursal/mes (Armando).
res.createIndex({ id_medico: 1, id_tipo: 1 }, { name: 'ix_medico_tipo' });
res.createIndex({ codigo_region_atencion: 1, fecha_resultado: 1 }, { name: 'ix_region_atencion_fecha' });

printjson(res.getIndexes().map(i => ({ name: i.name, key: i.key, unique: !!i.unique })));
print('PASS 02: índices de resumenes_estudios');
