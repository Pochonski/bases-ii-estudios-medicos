// P09 (contraste). La misma agregación médico x tipo sobre MongoDB, formato médico|tipo|n.
db.getSiblingDB('reportes_medicos').resumenes_estudios.aggregate([
  { $group: { _id: { m: '$id_medico', t: '$id_tipo' }, n: { $sum: 1 } } },
  { $sort: { '_id.m': 1, '_id.t': 1 } }
]).forEach(d => print(`${d._id.m}|${d._id.t}|${d.n}`));
