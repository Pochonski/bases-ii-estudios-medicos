// Joyce. MongoDB: base analítica y colecciones. Ejecutar con mongosh autenticado como
// administrador. Idempotente: crea lo que falta y reaplica el validador.
// Los documentos de resumenes_estudios los escribe SOLO la exportación desde PostgreSQL
// (mongo_fdw); este script no inserta datos.
const dbr = db.getSiblingDB('reportes_medicos');

// Validador del contrato docs/03: tipos BSON exactos, sin nombres ni contacto del paciente.
const esquemaResumen = {
  $jsonSchema: {
    bsonType: 'object',
    required: ['id_estudio', 'id_paciente', 'codigo_region', 'id_medico', 'id_tipo',
               'tipo_estudio', 'id_sucursal', 'codigo_region_atencion', 'fecha_resultado',
               'resultado_resumen', 'revision', 'fecha_sincronizacion'],
    properties: {
      id_estudio: { bsonType: 'long', minimum: 1 },
      id_paciente: { bsonType: 'long', minimum: 1 },
      codigo_region: { enum: ['SJ', 'AL', 'CA'], description: 'región de REGISTRO del paciente' },
      id_medico: { bsonType: 'long', minimum: 1, description: 'médico firmante' },
      id_tipo: { bsonType: 'int', minimum: 1 },
      tipo_estudio: { bsonType: 'string' },
      id_sucursal: { bsonType: 'int', minimum: 1 },
      codigo_region_atencion: { enum: ['SJ', 'AL', 'CA'], description: 'región de la sucursal' },
      fecha_resultado: { bsonType: 'date' },
      resultado_resumen: { bsonType: 'string' },
      revision: { bsonType: 'int', minimum: 1 },
      fecha_sincronizacion: { bsonType: 'date' }
    }
  }
};

const existentes = dbr.getCollectionNames();
if (!existentes.includes('resumenes_estudios')) {
  dbr.createCollection('resumenes_estudios', {
    validator: esquemaResumen, validationLevel: 'strict', validationAction: 'error'
  });
} else {
  dbr.runCommand({ collMod: 'resumenes_estudios', validator: esquemaResumen,
                   validationLevel: 'strict', validationAction: 'error' });
}
// Opcional según docs/03: agregaciones persistidas, después de demostrarlas en vivo.
if (!existentes.includes('indicadores_mensuales')) {
  dbr.createCollection('indicadores_mensuales');
}
print('PASS 01: reportes_medicos.resumenes_estudios (validador) e indicadores_mensuales');
