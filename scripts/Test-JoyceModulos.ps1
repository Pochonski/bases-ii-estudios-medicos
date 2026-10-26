#requires -Version 7.0
# Joyce. Pruebas reales P15, P16, permisos SQL Server, P01 (tds_fdw), P13, P04-P08 e INT-04
# (mongo_fdw + outbox). Requiere Install-JoyceModulos.ps1. Usa los estudios sintéticos
# 30031/30032 (SOLICITADO en el fixture) y los reinicia al comenzar para ser repetible.
# P08 DETIENE y vuelve a iniciar el servicio mongodb de este proyecto Compose.
#   pwsh -NoProfile -File ./scripts/Test-JoyceModulos.ps1 [-EvidencePath evidencias/registros/x.txt]
[CmdletBinding()]
param([string]$EvidencePath, [switch]$SkipMongoOutage)
. (Join-Path $PSScriptRoot 'Joyce-Common.ps1')
$null = Assert-JoyceEphemeralContext

$log = [System.Collections.Generic.List[string]]::new()
function Out-Log([string]$m) { $log.Add($m); Write-Output $m }
function Step([string]$m) { Out-Log "`n===== $m" }

$s = @{}
foreach ($n in $script:JoyceSecretNames) { $s[$n] = Get-JoyceSecret $n }
$svcEnv = [ordered]@{ FDW_MSSQL_PASSWORD = $s.fdw_mssql_password }
$pgMssqlEnv = [ordered]@{ PG_PW = $s.pg_fdw_mssql_login_password }
$pgMongoEnv = [ordered]@{ PG_PW = $s.pg_fdw_mongo_login_password }

function Pg([string]$Text) { Out-Log (Invoke-JoyceScript -Service postgres -Text $Text) }
function PgMssql([string]$Text) {
    Out-Log (Invoke-JoyceScript -Service postgres -Text $Text -PgUser usr_fdw_pg_mssql -PgLoginSecretVar PG_PW -Env $pgMssqlEnv)
}
function Export-Pendientes {
    Out-Log (Invoke-JoyceScript -Service postgres -PgUser usr_fdw_pg_mongo -PgLoginSecretVar PG_PW -Env $pgMongoEnv `
        -Text "SELECT current_user AS ejecuta;`nCALL integracion.exportar_pendientes();")
}
function Mongo([string]$Text) { Out-Log (Invoke-JoyceScript -Service mongodb -Text $Text) }
function Sql([string]$Text) { Out-Log (Invoke-JoyceScript -Service sqlserver -Text $Text) }

$ok = $false
try {
    Out-Log "Pruebas Joyce - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz') - commit $((git -C $script:JoyceRoot rev-parse --short HEAD).Trim())"
    Out-Log ("Docker: " + (& docker version --format '{{.Server.Version}} kernel {{.Server.KernelVersion}}'))
    Wait-JoyceHealthy

    Step 'Reinicio de filas sintéticas de prueba (estudios 30031/30032)'
    Pg @'
BEGIN;
DELETE FROM integracion.eventos_integracion WHERE id_estudio IN (30031, 30032);
DELETE FROM clinico.resultados_estudio WHERE id_estudio IN (30031, 30032);
UPDATE clinico.estudios SET estado = 'SOLICITADO', fecha_realizacion = NULL WHERE id_estudio IN (30031, 30032);
COMMIT;
'@
    Mongo "printjson(db.getSiblingDB('reportes_medicos').resumenes_estudios.deleteMany({ id_estudio: { `$in: [30031, 30032] } }));"

    Step 'P15 fragmentación vertical (sa)'
    Out-Log (Invoke-JoyceScript -Service sqlserver -Path 'pruebas/sqlserver/01_fragmentacion_vertical.sql')
    Step 'P16 procedimiento almacenado (sa)'
    Out-Log (Invoke-JoyceScript -Service sqlserver -Path 'pruebas/sqlserver/02_procedimiento.sql')
    Step 'Permisos svc_pg_mssql_ro (login propio)'
    Out-Log (Invoke-JoyceScript -Service sqlserver -Path 'pruebas/sqlserver/03_permisos_svc.sql' -SqlLogin svc_pg_mssql_ro -Env $svcEnv)

    Step 'P01 PostgreSQL -> SQL Server por tds_fdw (login usr_fdw_pg_mssql)'
    Out-Log (Invoke-JoyceScript -Service postgres -Path 'pruebas/integracion/05_p01_facturacion_real.sql' `
        -PgUser usr_fdw_pg_mssql -PgLoginSecretVar PG_PW -Env $pgMssqlEnv)

    Step 'P16b procedimiento SQL Server confirmado -> visible en PostgreSQL'
    Sql @'
:on error exit
USE integracion_externa;
EXEC dbo.sp_registrar_factura_externa @id_factura = 99902, @id_estudio = 30023,
     @id_paciente = 2003, @codigo_region = 'SJ', @monto = 4100.00, @estado = 'PENDIENTE';
GO
'@
    PgMssql @'
SELECT * FROM externo.ft_estado_facturacion WHERE id_paciente = 2003 AND codigo_region = 'SJ';
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM externo.ft_estado_facturacion WHERE id_paciente = 2003
                 AND codigo_region = 'SJ' AND estado_facturacion = 'PENDIENTE' AND total_facturado_crc = 4100.00) THEN
    RAISE EXCEPTION 'FALLA P16b: PostgreSQL no ve el resumen recalculado';
  END IF; END $$;
\echo 'PASS P16b: PostgreSQL lee el resumen recalculado por el procedimiento'
'@
    Sql @'
:on error exit
USE integracion_externa;
DELETE FROM dbo.facturas_externas WHERE id_factura = 99902;
EXEC dbo.sp_recalcular_resumen_facturacion @id_paciente = 2003, @codigo_region = 'SJ';
GO
'@
    PgMssql @'
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM externo.ft_estado_facturacion WHERE id_paciente = 2003
                 AND codigo_region = 'SJ' AND estado_facturacion = 'SIN_FACTURAS') THEN
    RAISE EXCEPTION 'FALLA P16b: la reversión no se refleja';
  END IF; END $$;
\echo 'PASS P16b: factura de prueba retirada y resumen restaurado (SIN_FACTURAS)'
'@

    Step 'P13 ROLLBACK local: no se exporta un resultado revertido'
    Pg @'
BEGIN;
SELECT * FROM integracion.registrar_resultado(30031, 503, 'Resultado ficticio que será revertido');
ROLLBACK;
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM integracion.eventos_integracion WHERE id_estudio = 30031)
     OR EXISTS (SELECT 1 FROM clinico.resultados_estudio WHERE id_estudio = 30031) THEN
    RAISE EXCEPTION 'FALLA P13: quedó resultado o evento tras ROLLBACK';
  END IF; END $$;
\echo 'PASS P13 (PostgreSQL): sin resultado ni evento tras ROLLBACK'
'@
    Export-Pendientes
    Mongo @'
const n = db.getSiblingDB('reportes_medicos').resumenes_estudios.countDocuments({ id_estudio: 30031 });
print('documentos 30031 = ' + n);
if (n !== 0) { print('FALLA P13: MongoDB recibió un resultado revertido'); quit(1); }
print('PASS P13 (MongoDB): nada exportado del ROLLBACK');
'@

    Step 'P04 resultado + evento en una transacción local (COMMIT)'
    Pg @'
SELECT * FROM integracion.registrar_resultado(30031, 503, 'Ecografía ficticia: hallazgos normales de prueba');
SELECT id_estudio, revision, tipo_evento, estado, intentos FROM integracion.eventos_integracion WHERE id_estudio = 30031;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM integracion.eventos_integracion
                 WHERE id_estudio = 30031 AND revision = 1 AND estado = 'PENDIENTE') THEN
    RAISE EXCEPTION 'FALLA P04: no hay evento PENDIENTE revisión 1';
  END IF; END $$;
\echo 'PASS P04: resultado y evento PENDIENTE confirmados juntos'
'@

    Step 'P05 exportación tras COMMIT por mongo_fdw (login usr_fdw_pg_mongo)'
    Export-Pendientes
    $tipos = @'
const c = db.getSiblingDB('reportes_medicos').resumenes_estudios;
const docs = c.aggregate([{ $match: { id_estudio: 30031 } }, { $project: { _id: 0, id_estudio: 1, revision: 1,
  resultado_resumen: 1, codigo_region: 1, codigo_region_atencion: 1,
  t_id_estudio: { $type: '$id_estudio' }, t_id_paciente: { $type: '$id_paciente' }, t_id_medico: { $type: '$id_medico' },
  t_id_tipo: { $type: '$id_tipo' }, t_id_sucursal: { $type: '$id_sucursal' }, t_revision: { $type: '$revision' },
  t_fecha_resultado: { $type: '$fecha_resultado' }, t_fecha_sinc: { $type: '$fecha_sincronizacion' }, t_oid: { $type: '$$ROOT._id' } } }]).toArray();
printjson(docs);
'@
    Mongo ($tipos + @'
if (docs.length !== 1 || docs[0].revision !== 1) { print('FALLA P05: se esperaba 1 documento revisión 1'); quit(1); }
const d = docs[0];
if (d.t_oid !== 'objectId' || d.t_id_estudio !== 'long' || d.t_id_paciente !== 'long' || d.t_id_medico !== 'long' || d.t_id_tipo !== 'int' ||
    d.t_id_sucursal !== 'int' || d.t_revision !== 'int' || d.t_fecha_resultado !== 'date' || d.t_fecha_sinc !== 'date') {
  print('FALLA P05: tipos BSON fuera de contrato'); quit(1);
}
print('PASS P05: documento creado por mongo_fdw con ObjectId/Int64/Int32/Date según contrato');
'@)
    Mongo @'
const c = db.getSiblingDB('reportes_medicos').resumenes_estudios;
const i = c.getIndexes().find(x => x.key.id_estudio === 1 && x.unique === true);
if (!i) { print('FALLA P05: falta índice UNIQUE id_estudio'); quit(1); }
const copy = c.findOne({ id_estudio: 30031 });
copy._id = ObjectId();
try { c.insertOne(copy); print('FALLA P05: UNIQUE permitió duplicado'); quit(1); }
catch (e) { if (e.code !== 11000) { print('FALLA P05: error inesperado ' + e.code); quit(1); } }
print('PASS P05: índice UNIQUE id_estudio rechaza duplicado');
'@
    Pg @'
SELECT id_estudio, revision, estado, intentos FROM integracion.eventos_integracion WHERE id_estudio = 30031;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM integracion.eventos_integracion WHERE id_estudio = 30031 AND estado = 'PROCESADO') THEN
    RAISE EXCEPTION 'FALLA P05: evento no marcado PROCESADO';
  END IF; END $$;
'@

    Step 'P06 corrección del resultado: revisión 2 actualiza el mismo documento'
    $oidAntes = (Invoke-JoyceScript -Service mongodb -Text "print(db.getSiblingDB('reportes_medicos').resumenes_estudios.findOne({id_estudio:30031})._id.toString());").Trim()
    Pg "SELECT * FROM integracion.registrar_resultado(30031, 503, 'Ecografía ficticia: corrección de prueba, revisión 2');"
    Export-Pendientes
    $oidDespues = (Invoke-JoyceScript -Service mongodb -Text "print(db.getSiblingDB('reportes_medicos').resumenes_estudios.findOne({id_estudio:30031})._id.toString());").Trim()
    if ($oidAntes -ne $oidDespues) { throw 'FALLA P06: cambió _id tras UPDATE por mongo_fdw' }
    Mongo @'
const c = db.getSiblingDB('reportes_medicos').resumenes_estudios;
const docs = c.find({ id_estudio: 30031 }, { _id: 1, revision: 1, resultado_resumen: 1 }).toArray();
printjson(docs);
if (docs.length !== 1 || docs[0].revision !== 2 || !docs[0].resultado_resumen.includes('revisión 2')) {
  print('FALLA P06'); quit(1);
}
print('PASS P06: mismo documento (_id conservado), revisión 2');
'@

    Step 'P07 reprocesar el evento viejo (revisión 1): sin duplicado ni regresión'
    Pg "UPDATE integracion.eventos_integracion SET estado = 'PENDIENTE' WHERE id_estudio = 30031 AND revision = 1;"
    Export-Pendientes
    Mongo @'
const c = db.getSiblingDB('reportes_medicos').resumenes_estudios;
const docs = c.find({ id_estudio: 30031 }, { _id: 0, revision: 1 }).toArray();
printjson(docs);
if (docs.length !== 1 || docs[0].revision !== 2) { print('FALLA P07'); quit(1); }
print('PASS P07: un solo documento y sigue en revisión 2');
'@

    Step 'Permisos negativos de usr_fdw_pg_mongo'
    Out-Log (Invoke-JoyceScript -Service postgres -PgUser usr_fdw_pg_mongo -PgLoginSecretVar PG_PW -Env $pgMongoEnv -Text @'
SELECT current_user AS usuario_conectado;
DO $$ BEGIN
  BEGIN PERFORM 1 FROM clinico.pacientes LIMIT 1;
        RAISE EXCEPTION 'FALLA: usr_fdw_pg_mongo lee pacientes';
  EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'PASS negativo: SELECT clinico.pacientes denegado'; END;
  BEGIN DELETE FROM externo.ft_resumenes_estudios WHERE id_estudio = 30031;
        RAISE EXCEPTION 'FALLA: usr_fdw_pg_mongo borra en MongoDB';
  EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'PASS negativo: DELETE en tabla foránea denegado'; END;
  BEGIN UPDATE clinico.resultados_estudio SET resumen = 'x' WHERE id_estudio = 30031;
        RAISE EXCEPTION 'FALLA: usr_fdw_pg_mongo modifica resultados';
  EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'PASS negativo: UPDATE clinico.resultados_estudio denegado'; END;
END $$;
'@)

    Step 'MongoDB: autenticación propia y permisos mínimos de svc_pg_mongo_rw'
    Out-Log (Invoke-JoyceScript -Service mongodb -Env ([ordered]@{ FDW_MONGO_PASSWORD = $s.fdw_mongo_password }) -Text @'
const a = db.getSiblingDB('admin'); a.logout();
const r = db.getSiblingDB('reportes_medicos');
if (!r.auth('svc_pg_mongo_rw', process.env.FDW_MONGO_PASSWORD)) { print('FALLA: login svc'); quit(1); }
if (!r.resumenes_estudios.findOne({id_estudio:30031})) { print('FALLA: find svc'); quit(1); }
const denied = r.runCommand({ delete: 'resumenes_estudios', deletes: [{q:{id_estudio:30031},limit:1}] });
if (denied.ok !== 0 || denied.code !== 13) { print('FALLA: delete svc no fue denegado'); quit(1); }
const other = r.runCommand({ find: 'indicadores_mensuales', filter: {}, limit: 1 });
if (other.ok !== 0 || other.code !== 13) { print('FALLA: lectura ajena permitida'); quit(1); }
print('PASS svc_pg_mongo_rw: login/find permitidos; delete y colección ajena denegados');
'@)

    if (-not $SkipMongoOutage) {
        Step 'P08 MongoDB detenido: PostgreSQL confirma, evento queda en ERROR y se recupera'
        Invoke-JoyceCompose @('stop', 'mongodb')
        Pg "SELECT * FROM integracion.registrar_resultado(30032, 504, 'Radiografía ficticia registrada con MongoDB apagado');"
        Export-Pendientes
        Pg @'
SELECT id_estudio, revision, estado, intentos FROM integracion.eventos_integracion WHERE id_estudio = 30032;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM integracion.eventos_integracion WHERE id_estudio = 30032 AND estado = 'ERROR' AND intentos = 1)
     OR NOT EXISTS (SELECT 1 FROM clinico.resultados_estudio WHERE id_estudio = 30032) THEN
    RAISE EXCEPTION 'FALLA P08: se esperaba resultado confirmado y evento ERROR';
  END IF; END $$;
\echo 'PASS P08 (caída): resultado confirmado en PostgreSQL, evento en ERROR para reintento'
'@
        Invoke-JoyceCompose @('start', 'mongodb')
        Wait-JoyceHealthy -Services mongodb
        Export-Pendientes
        Pg @'
SELECT id_estudio, revision, estado, intentos FROM integracion.eventos_integracion WHERE id_estudio = 30032;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM integracion.eventos_integracion WHERE id_estudio = 30032 AND estado = 'PROCESADO' AND intentos = 2) THEN
    RAISE EXCEPTION 'FALLA P08: el reintento no procesó el evento';
  END IF; END $$;
'@
        Mongo @'
const n = db.getSiblingDB('reportes_medicos').resumenes_estudios.countDocuments({ id_estudio: 30032 });
if (n !== 1) { print('FALLA P08: documento ausente tras reconexión'); quit(1); }
print('PASS P08: evento recuperado tras reconexión, un documento 30032');
'@
    }

    Step 'INT-04 exportación masiva de resultados hacia MongoDB'
    Pg "SELECT integracion.encolar_exportacion_masiva() AS eventos_encolados;"
    Export-Pendientes
    Out-Log (Invoke-JoyceScript -Service postgres -PgUser usr_fdw_pg_mongo -PgLoginSecretVar PG_PW -Env $pgMongoEnv -Text @'
SELECT count(*) AS documentos_mongo_vistos_por_fdw FROM externo.ft_resumenes_estudios;
SELECT id_estudio, id_medico, id_tipo, tipo_estudio, codigo_region, codigo_region_atencion, revision
FROM externo.ft_resumenes_estudios WHERE id_estudio IN (30001, 30031, 30032) ORDER BY id_estudio;
DO $$
DECLARE v_pg integer; v_mongo integer; v_pend integer;
BEGIN
  SELECT count(*) INTO v_pg FROM clinico.resultados_estudio;
  SELECT count(*) INTO v_mongo FROM externo.ft_resumenes_estudios;
  SELECT count(*) INTO v_pend FROM integracion.eventos_integracion WHERE estado <> 'PROCESADO';
  RAISE NOTICE 'resultados PG=% documentos Mongo=% eventos no procesados=%', v_pg, v_mongo, v_pend;
  IF v_pg <> v_mongo OR v_pend <> 0 THEN RAISE EXCEPTION 'FALLA INT-04: PostgreSQL y MongoDB no coinciden'; END IF;
END $$;
\echo 'PASS INT-04: cada resultado de PostgreSQL tiene exactamente un resumen en MongoDB'
'@)
    Step 'P02/P03/P10/P11 perfil externo usr_api_web (login SCRAM)'
    Out-Log (Invoke-JoyceScript -Service postgres -Path 'pruebas/seguridad/01_usr_api_web.sql' `
        -PgUser usr_api_web -PgLoginSecretVar PG_PW -Env ([ordered]@{ PG_PW = $s.pg_api_web_password }))
    Step 'P10/P11 perfil externo usr_api_mobile (login SCRAM)'
    Out-Log (Invoke-JoyceScript -Service postgres -Path 'pruebas/seguridad/02_usr_api_mobile.sql' `
        -PgUser usr_api_mobile -PgLoginSecretVar PG_PW -Env ([ordered]@{ PG_PW = $s.pg_api_mobile_password }))
    Step 'Autenticación: contraseña incorrecta rechazada'
    $null = Invoke-JoyceScript -Service postgres -PgUser usr_api_mobile -PgLoginSecretVar PG_PW `
        -Env ([ordered]@{ PG_PW = 'contrasena-incorrecta' }) -Text 'SELECT 1;' -AllowFailure
    if ($LASTEXITCODE -eq 0) { throw 'FALLA: login con contraseña incorrecta aceptado' }
    Out-Log 'PASS negativo: usr_api_mobile con contraseña incorrecta no inicia sesión (SCRAM)'

    Step 'P09/INT-05 agregaciones MongoDB por médico y tipo'
    Mongo ([IO.File]::ReadAllText((Join-Path $script:JoyceRoot 'mongodb/04_agregaciones.js')))
    Mongo ([IO.File]::ReadAllText((Join-Path $script:JoyceRoot 'mongodb/05_validaciones.js')))
    # Contraste independiente: el mismo conteo calculado en PostgreSQL (fuente clínica).
    $pgConteo = Invoke-JoyceScript -Service postgres -Path 'pruebas/reportes/01_conteo_pg_medico_tipo.sql'
    $mgConteo = Invoke-JoyceScript -Service mongodb -Path 'pruebas/reportes/02_conteo_mongo_medico_tipo.js'
    $pgLineas = @($pgConteo -split "`n" | Where-Object { $_ -match '^\d+\|' })
    $mgLineas = @($mgConteo -split "`n" | Where-Object { $_ -match '^\d+\|' })
    Out-Log "PostgreSQL médico|tipo|n: $($pgLineas -join ', ')"
    Out-Log "MongoDB    médico|tipo|n: $($mgLineas -join ', ')"
    if ($pgLineas.Count -eq 0 -or ($pgLineas -join ',') -ne ($mgLineas -join ',')) {
        throw 'FALLA P09: la agregación MongoDB no coincide con PostgreSQL'
    }
    Out-Log "PASS P09: $($mgLineas.Count) grupos médico x tipo idénticos en MongoDB y PostgreSQL"
    $ok = $true
    Out-Log "`nRESULTADO: PASA - todas las pruebas de Joyce ejecutadas sin fallas."
}
catch {
    Out-Log "`nRESULTADO: FALLA`n$($_.Exception.Message)"
    throw
}
finally {
    if ($EvidencePath) {
        $full = Join-Path $script:JoyceRoot $EvidencePath
        $null = New-Item -ItemType Directory -Force -Path (Split-Path -Parent $full)
        [IO.File]::WriteAllLines($full, $log, [Text.UTF8Encoding]::new($false))
        Write-Output "Evidencia escrita en $EvidencePath (revisar antes de commit: no debe contener secretos)."
    }
}
