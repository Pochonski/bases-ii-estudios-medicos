// Módulo de Armando, implementado por Joyce con su permiso (D-042).
// INT-05: consultas analíticas sobre resumenes_estudios (documentos exportados desde PostgreSQL).
// La región de ATENCIÓN (sucursal) se usa para reportes de clínicas; codigo_region es la de
// REGISTRO del paciente y no debe confundirse.
const dbr = db.getSiblingDB('reportes_medicos');
const res = dbr.getCollection('resumenes_estudios');

// 1. OBLIGATORIA: estudios por médico firmante y tipo de estudio.
const porMedicoTipo = res.aggregate([
  { $group: { _id: { id_medico: '$id_medico', id_tipo: '$id_tipo', tipo_estudio: '$tipo_estudio' },
              estudios: { $sum: 1 }, ultima_fecha: { $max: '$fecha_resultado' } } },
  { $project: { _id: 0, id_medico: '$_id.id_medico', id_tipo: '$_id.id_tipo',
                tipo_estudio: '$_id.tipo_estudio', estudios: 1, ultima_fecha: 1 } },
  { $sort: { id_medico: 1, id_tipo: 1 } }
]).toArray();
print('== 1. Estudios por médico y tipo (INT-05)');
console.table(porMedicoTipo.map(d => ({ medico: Number(d.id_medico), tipo: d.tipo_estudio, estudios: d.estudios })));

// 2. Productividad médica: total por médico con el desglose de tipos.
const productividad = res.aggregate([
  { $group: { _id: '$id_medico', estudios: { $sum: 1 }, tipos: { $addToSet: '$tipo_estudio' },
              corregidos: { $sum: { $cond: [{ $gt: ['$revision', 1] }, 1, 0] } } } },
  { $project: { _id: 0, id_medico: '$_id', estudios: 1, corregidos: 1,
                tipos_distintos: { $size: '$tipos' } } },
  { $sort: { estudios: -1, id_medico: 1 } }
]).toArray();
print('== 2. Productividad por médico');
console.table(productividad.map(d => ({ medico: Number(d.id_medico), estudios: d.estudios,
  tipos_distintos: d.tipos_distintos, con_correccion: d.corregidos })));

// 3. Rendimiento de clínicas: por sucursal / región de atención y tipo.
const porSucursal = res.aggregate([
  { $group: { _id: { region: '$codigo_region_atencion', sucursal: '$id_sucursal', tipo: '$tipo_estudio' },
              estudios: { $sum: 1 } } },
  { $sort: { '_id.region': 1, '_id.sucursal': 1, '_id.tipo': 1 } }
]).toArray();
print('== 3. Estudios por región de atención, sucursal y tipo');
console.table(porSucursal.map(d => ({ region_atencion: d._id.region, sucursal: d._id.sucursal,
  tipo: d._id.tipo, estudios: d.estudios })));

// 4. Pacientes atendidos fuera de su región de registro.
const fueraDeRegion = res.aggregate([
  { $match: { $expr: { $ne: ['$codigo_region', '$codigo_region_atencion'] } } },
  { $group: { _id: { registro: '$codigo_region', atencion: '$codigo_region_atencion' },
              estudios: { $sum: 1 } } },
  { $sort: { '_id.registro': 1, '_id.atencion': 1 } }
]).toArray();
print('== 4. Estudios atendidos fuera de la región de registro del paciente');
console.table(fueraDeRegion.map(d => ({ registro: d._id.registro, atencion: d._id.atencion, estudios: d.estudios })));

// 5. Indicadores mensuales por región de atención y tipo; se persisten en indicadores_mensuales
//    con $merge (repetible: reemplaza el indicador del mismo mes/región/tipo).
const pipelineMensual = [
  { $group: { _id: { mes: { $dateToString: { format: '%Y-%m', date: '$fecha_resultado', timezone: 'America/Costa_Rica' } },
                     region_atencion: '$codigo_region_atencion', tipo_estudio: '$tipo_estudio' },
              estudios: { $sum: 1 }, medicos: { $addToSet: '$id_medico' } } },
  { $project: { _id: { $concat: ['$_id.mes', '|', '$_id.region_atencion', '|', '$_id.tipo_estudio'] },
                mes: '$_id.mes', region_atencion: '$_id.region_atencion', tipo_estudio: '$_id.tipo_estudio',
                estudios: 1, medicos_distintos: { $size: '$medicos' }, calculado: '$$NOW' } }
];
res.aggregate(pipelineMensual.concat([{ $merge: { into: 'indicadores_mensuales', on: '_id',
                                                  whenMatched: 'replace', whenNotMatched: 'insert' } }]));
print('== 5. indicadores_mensuales (persistidos con $merge)');
console.table(dbr.indicadores_mensuales.find({}, { _id: 0, calculado: 0 })
  .sort({ mes: 1, region_atencion: 1, tipo_estudio: 1 }).toArray());
