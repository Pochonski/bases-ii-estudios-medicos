// Módulo de Armando, implementado por Joyce con su permiso (D-042).
// Validaciones de la capa analítica. Termina con código 1 ante cualquier falla.
const dbr = db.getSiblingDB('reportes_medicos');
const res = dbr.getCollection('resumenes_estudios');
let fallas = 0;
function check(ok, msg) { print((ok ? 'PASS ' : 'FALLA ') + msg); if (!ok) fallas++; }

const total = res.countDocuments({});
check(total > 0, `hay documentos exportados (${total})`);

const dup = res.aggregate([{ $group: { _id: '$id_estudio', n: { $sum: 1 } } }, { $match: { n: { $gt: 1 } } }]).toArray();
check(dup.length === 0, 'un único resumen por id_estudio');

const malTipo = res.countDocuments({ $or: [
  { id_estudio: { $not: { $type: 'long' } } }, { id_medico: { $not: { $type: 'long' } } },
  { id_tipo: { $not: { $type: 'int' } } }, { revision: { $not: { $type: 'int' } } },
  { fecha_resultado: { $not: { $type: 'date' } } }] });
check(malTipo === 0, 'tipos BSON según contrato (long/int/date)');

const sumaMedicoTipo = res.aggregate([
  { $group: { _id: { m: '$id_medico', t: '$id_tipo' }, n: { $sum: 1 } } },
  { $group: { _id: null, total: { $sum: '$n' } } }]).toArray()[0].total;
check(sumaMedicoTipo === total, `la agregación médico x tipo suma el total (${sumaMedicoTipo})`);

const sinDatosPersonales = res.countDocuments({ $or: [{ paciente: { $exists: true } },
  { nombre: { $exists: true } }, { correo: { $exists: true } }, { telefono: { $exists: true } }] });
check(sinDatosPersonales === 0, 'los resúmenes no contienen nombre ni contacto del paciente');

// Fixture: el paciente 1001/AL se atiende en la sucursal 1 (SJ); estudio 30001.
const e1 = res.findOne({ id_estudio: 30001 });
check(e1 !== null && e1.codigo_region === 'AL' && e1.codigo_region_atencion === 'SJ',
      'región de registro (AL) y de atención (SJ) se conservan separadas en 30001');

let rechazado = false;
try { res.insertOne({ id_estudio: 'texto', revision: 1 }); } catch (e) { rechazado = e.code === 121; }
check(rechazado, 'el validador rechaza un documento fuera de contrato (código 121)');

if (fallas > 0) { print(`RESULTADO: ${fallas} falla(s)`); quit(1); }
print('PASS 05: validaciones de la capa analítica');
