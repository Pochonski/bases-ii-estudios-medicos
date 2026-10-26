#requires -Version 7.0
# Respaldo lógico y restauración comprobada en bases NUEVAS del proyecto P18 efímero.
# Nunca restaura sobre reportes_medicos, integracion_externa ni POSTGRES_DB.
[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Joyce-Common.ps1')
$null = Assert-JoyceEphemeralContext
Wait-JoyceHealthy
$pgId = Get-JoyceContainerId postgres
$pgRestored = $false
try {
    # PostgreSQL: archivo custom dentro del contenedor efímero, nueva base en el mismo
    # cluster, comparación de filas y revisión clínica. El archivo no sale a artifacts.
    & docker exec -u postgres $pgId bash -e -c 'pg_dump -Fc -U postgres -d "$POSTGRES_DB" -f /tmp/joseph-p18-postgres.dump'
    if ($LASTEXITCODE -ne 0) { throw 'pg_dump falló.' }
    & docker exec -u postgres $pgId createdb -U postgres joseph_p18_restore
    if ($LASTEXITCODE -ne 0) { throw 'createdb de restauración falló.' }
    $pgRestored = $true
    & docker exec -u postgres $pgId pg_restore -U postgres -d joseph_p18_restore --no-owner --no-privileges /tmp/joseph-p18-postgres.dump
    if ($LASTEXITCODE -ne 0) { throw 'pg_restore falló.' }
    $pgCounts = (& docker exec -u postgres $pgId psql -X -q -t -A -U postgres -d joseph_p18_restore -c "SELECT (SELECT count(*) FROM clinico.pacientes), (SELECT revision FROM clinico.resultados_estudio WHERE id_estudio=30031), (SELECT count(*) FROM integracion.eventos_integracion WHERE id_estudio=30031 AND estado='PROCESADO');").Trim()
    if ($LASTEXITCODE -ne 0 -or $pgCounts -ne '30|4|4') { throw "Restauración PostgreSQL no conserva pacientes/revisión/eventos ($pgCounts)." }
    Write-Output "PASS restauración PostgreSQL: pg_dump/pg_restore, pacientes|revisión|eventos=$pgCounts"

    # SQL Server: BACKUP nativo y RESTORE hacia otra base, con archivos físicos propios.
    $sqlOutput = Invoke-JoyceScript -Service sqlserver -Text @'
:on error exit
SET NOCOUNT ON;
BACKUP DATABASE [integracion_externa]
 TO DISK = N'/var/opt/mssql/joseph-p18-sqlserver.bak' WITH COPY_ONLY, INIT;
DECLARE @datos sysname = (SELECT name FROM sys.master_files
 WHERE database_id=DB_ID(N'integracion_externa') AND type_desc='ROWS');
DECLARE @log sysname = (SELECT name FROM sys.master_files
 WHERE database_id=DB_ID(N'integracion_externa') AND type_desc='LOG');
IF @datos IS NULL OR @log IS NULL THROW 51070, 'Archivos lógicos desconocidos', 1;
DECLARE @sql nvarchar(max) = N'RESTORE DATABASE [joseph_p18_restore] FROM DISK = N''/var/opt/mssql/joseph-p18-sqlserver.bak'' WITH '
 + N'MOVE N''' + REPLACE(@datos,'''','''''') + N''' TO N''/var/opt/mssql/data/joseph_p18_restore.mdf'', '
 + N'MOVE N''' + REPLACE(@log,'''','''''') + N''' TO N''/var/opt/mssql/data/joseph_p18_restore_log.ldf'', RECOVERY;';
EXEC (@sql);
IF (SELECT COUNT(*) FROM joseph_p18_restore.dbo.facturas_externas)
   <> (SELECT COUNT(*) FROM integracion_externa.dbo.facturas_externas)
 OR (SELECT COUNT(*) FROM joseph_p18_restore.dbo.paciente_integracion)
   <> (SELECT COUNT(*) FROM integracion_externa.dbo.paciente_integracion)
 OR NOT EXISTS (SELECT 1 FROM joseph_p18_restore.dbo.facturas_externas
                WHERE id_factura=90001 AND monto=15000.00)
 THROW 51071, 'La base restaurada difiere del origen', 1;
PRINT 'PASS restauración SQL Server: BACKUP/RESTORE nativos, facturas, pacientes y monto verificadas';
GO
'@
    if ($sqlOutput -notmatch 'PASS restauración SQL Server') { throw 'SQL Server no confirmó datos restaurados.' }
    Write-Output 'PASS restauración SQL Server: BACKUP/RESTORE nativos, facturas, pacientes y monto verificados'

    # La imagen mongo:8.0 no garantiza mongodump. EJSON estricto conserva tipos BSON;
    # archivo local efímero, base destino nueva, validador/índices y comparación completa.
    $mongoOutput = Invoke-JoyceScript -Service mongodb -Text @'
const filesystem = require('fs');
const ruta = '/tmp/joseph-p18-mongodb.ejson';
const origen = db.getSiblingDB('reportes_medicos');
const destino = db.getSiblingDB('joseph_p18_restore');
const nombres = ['resumenes_estudios', 'indicadores_mensuales'];
try {
  const paquete = nombres.map(nombre => ({
    nombre,
    opciones: origen.getCollectionInfos({name:nombre})[0].options,
    indices: origen.getCollection(nombre).getIndexes().filter(i => i.name !== '_id_'),
    documentos: origen.getCollection(nombre).find().toArray()
  }));
  filesystem.writeFileSync(ruta, EJSON.stringify(paquete, {relaxed:false}), {mode:0o600});
  destino.dropDatabase();
  // El modo relaxed predeterminado convierte Int32/Int64 a Number y el validador
  // rechaza la copia. Deserializar en modo estricto conserva los tipos BSON.
  const copia = EJSON.parse(filesystem.readFileSync(ruta, 'utf8'), {relaxed:false});
  for (const item of copia) {
    destino.createCollection(item.nombre, item.opciones);
    for (const indice of item.indices) {
      destino.getCollection(item.nombre).createIndex(indice.key,
        {name:indice.name, unique:indice.unique === true});
    }
    if (item.documentos.length) destino.getCollection(item.nombre).insertMany(item.documentos);
    const ordenar = d => EJSON.stringify(d, {relaxed:false});
    const a = origen.getCollection(item.nombre).find().sort({_id:1}).toArray().map(ordenar);
    const b = destino.getCollection(item.nombre).find().sort({_id:1}).toArray().map(ordenar);
    if (JSON.stringify(a) !== JSON.stringify(b)) throw new Error('Documentos restaurados difieren: ' + item.nombre);
    if (origen.getCollection(item.nombre).getIndexes().length !== destino.getCollection(item.nombre).getIndexes().length)
      throw new Error('Índices restaurados difieren: ' + item.nombre);
  }
  const d = destino.resumenes_estudios.findOne({id_estudio:30031});
  if (!d || d.revision !== 4 || d._id._bsontype !== 'ObjectId' ||
      d.id_paciente._bsontype !== 'Long' || !(d.fecha_resultado instanceof Date))
    throw new Error('Tipos BSON o revisión no conservados');
  print('PASS restauración MongoDB: archivo EJSON estricto, colecciones/índices/documentos y BSON verificados');
} finally {
  destino.dropDatabase();
  if (filesystem.existsSync(ruta)) filesystem.unlinkSync(ruta);
}
'@
    if ($mongoOutput -notmatch 'PASS restauración MongoDB') { throw 'MongoDB no confirmó datos restaurados.' }
    Write-Output 'PASS restauración MongoDB: EJSON estricto, colecciones, índices, documentos y BSON verificados'
} finally {
    if ($pgRestored) {
        & docker exec -u postgres $pgId dropdb -U postgres --if-exists joseph_p18_restore
        if ($LASTEXITCODE -ne 0) { Write-Warning 'Base PostgreSQL de restauración efímera no retirada; P18 retirará el volumen.' }
    }
    # La base solo puede existir dentro del proyecto efímero validado arriba.
    try {
        $null = Invoke-JoyceScript -Service sqlserver -Text @'
:on error exit
IF DB_ID(N'joseph_p18_restore') IS NOT NULL
BEGIN
 ALTER DATABASE [joseph_p18_restore] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
 DROP DATABASE [joseph_p18_restore];
END;
GO
'@
    } catch { Write-Warning 'Base SQL Server de restauración efímera no retirada; P18 retirará el volumen.' }
}
