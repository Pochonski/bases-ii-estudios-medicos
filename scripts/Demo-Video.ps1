#requires -Version 7.0
# Demostración en vivo para el video (5-8 min). Cada segmento muestra la consulta y su resultado.
#   pwsh -NoProfile -File ./scripts/Demo-Video.ps1            # todos, con pausa entre segmentos
#   pwsh -NoProfile -File ./scripts/Demo-Video.ps1 -Segmento 5 # uno solo
# Requiere Install-JoyceModulos.ps1. El segmento 6 usa el estudio sintético 30033 y lo reinicia.
[CmdletBinding()]
param([int[]]$Segmento = @(1..9), [switch]$SinPausa)
. (Join-Path $PSScriptRoot 'Joyce-Common.ps1')
if (@($Segmento | Where-Object { $_ -in 3,5,6,8 }).Count -gt 0) {
    $null = Assert-JoyceEphemeralContext
}

$sec = @{}
foreach ($n in $script:JoyceSecretNames) { $sec[$n] = Get-JoyceSecret $n }
function Titulo([string]$t) { Write-Host "`n$('=' * 78)`n  $t`n$('=' * 78)" -ForegroundColor Cyan }
function Mostrar([string]$motor, [string]$texto) { Write-Host "[$motor]>" -ForegroundColor Yellow; Write-Host $texto.Trim() -ForegroundColor DarkGray }
function Pg([string]$t, [string]$como = 'postgres') {
    Mostrar "PostgreSQL como $como" $t
    $map = @{ usr_fdw_pg_mssql = 'pg_fdw_mssql_login_password'; usr_fdw_pg_mongo = 'pg_fdw_mongo_login_password'
              usr_api_web = 'pg_api_web_password'; usr_api_mobile = 'pg_api_mobile_password' }
    if ($como -eq 'postgres') { Invoke-JoyceScript -Service postgres -Text $t }
    else { Invoke-JoyceScript -Service postgres -Text $t -PgUser $como -PgLoginSecretVar PG_PW -Env ([ordered]@{ PG_PW = $sec[$map[$como]] }) }
}
function Sql([string]$t) { Mostrar 'SQL Server' $t; Invoke-JoyceScript -Service sqlserver -Text ":on error exit`nSET NOCOUNT ON;`nUSE integracion_externa;`n$t" }
function Mongo([string]$t) { Mostrar 'MongoDB' $t; Invoke-JoyceScript -Service mongodb -Text "const r = db.getSiblingDB('reportes_medicos');`n$t" }
function Pausa { if (-not $SinPausa) { Read-Host "`n[Enter] para continuar" | Out-Null } }

# Hashtable (no [ordered]): con [ordered], $demos[1] indexaría por posición, no por clave.
$demos = @{
  1 = { Titulo '1. Arquitectura: tres motores en contenedores, red interna'
        & docker compose @(Get-JoyceComposeArgs) ps --format 'table {{.Service}}\t{{.Image}}\t{{.Status}}'
        $net = if ($env:JOYCETEST_PROJECT_NAME) { "$($env:JOYCETEST_PROJECT_NAME)-medical-network" } else { 'medical-network' }
        & docker network inspect $net --format 'Red {{.Name}}: internal={{.Internal}}' }
  2 = { Titulo '2. PostgreSQL: segmentación HORIZONTAL de pacientes por región'
        Pg @'
SELECT tableoid::regclass AS particion, count(*) AS pacientes FROM clinico.pacientes GROUP BY 1 ORDER BY 1;
EXPLAIN (COSTS OFF) SELECT * FROM clinico.pacientes WHERE codigo_region = 'CA';
'@ }
  3 = { Titulo '3. SQL Server: segmentación VERTICAL y procedimiento almacenado'
        Sql @'
SELECT TOP 3 * FROM dbo.paciente_integracion ORDER BY id_paciente;   -- fragmento 1
SELECT TOP 3 * FROM dbo.paciente_cobertura ORDER BY id_paciente;     -- fragmento 2
SELECT TOP 3 * FROM dbo.vw_paciente_asegurado ORDER BY id_paciente;  -- reconstrucción 1:1
EXEC dbo.sp_recalcular_resumen_facturacion @id_paciente = 1001, @codigo_region = 'AL';
GO
'@ }
  4 = { Titulo '4. Canales FDW configurados (CREATE SERVER / USER MAPPING, sin contraseñas)'
        Pg @'
SELECT s.srvname AS servidor, w.fdwname AS wrapper, s.srvoptions AS opciones
FROM pg_foreign_server s JOIN pg_foreign_data_wrapper w ON w.oid = s.srvfdw;
SELECT srvname AS servidor, usename AS perfil_interno,
       ARRAY(SELECT o FROM unnest(umoptions) o WHERE o NOT LIKE 'password=%') AS opciones
FROM pg_user_mappings ORDER BY 1;
'@ }
  5 = { Titulo '5. INT-01: paciente (PostgreSQL) + estado de facturación (SQL Server vía tds_fdw)'
        Pg @'
SELECT current_user;
SELECT p.id_paciente, p.codigo_region, p.nombre,
       COALESCE(f.estado_cobertura, 'SIN_REGISTRO') AS cobertura,
       COALESCE(f.estado_facturacion, 'SIN_REGISTRO') AS facturacion,
       f.nombre_aseguradora, f.total_facturado_crc
FROM clinico.pacientes p
LEFT JOIN externo.ft_estado_facturacion f
       ON f.id_paciente = p.id_paciente AND f.codigo_region = p.codigo_region
WHERE p.id_paciente IN (1001, 1009, 2002);
'@ 'usr_fdw_pg_mssql'
        Write-Host "`n-- Cambio en SQL Server: llega una factura nueva para 2003/SJ" -ForegroundColor Green
        Sql @'
EXEC dbo.sp_registrar_factura_externa @id_factura = 99950, @id_estudio = 30023, @id_paciente = 2003,
     @codigo_region = 'SJ', @monto = 12000.00, @estado = 'PENDIENTE';
GO
'@
        Pg "SELECT * FROM externo.ft_estado_facturacion WHERE id_paciente = 2003 AND codigo_region = 'SJ';" 'usr_fdw_pg_mssql'
        $null = Invoke-JoyceScript -Service sqlserver -Text ":on error exit`nUSE integracion_externa;`nDELETE FROM dbo.facturas_externas WHERE id_factura = 99950;`nEXEC dbo.sp_recalcular_resumen_facturacion @id_paciente = 2003, @codigo_region = 'SJ';`nGO" }
  6 = { Titulo '6. INT-02: inserción en PostgreSQL que, tras COMMIT, actualiza MongoDB (mongo_fdw)'
        $null = Invoke-JoyceScript -Service postgres -Text "BEGIN; DELETE FROM integracion.eventos_integracion WHERE id_estudio = 30033; DELETE FROM clinico.resultados_estudio WHERE id_estudio = 30033; UPDATE clinico.estudios SET estado = 'SOLICITADO', fecha_realizacion = NULL WHERE id_estudio = 30033; COMMIT;"
        $null = Invoke-JoyceScript -Service mongodb -Text "db.getSiblingDB('reportes_medicos').resumenes_estudios.deleteMany({ id_estudio: 30033 });"
        Pg @'
BEGIN;
SELECT * FROM integracion.registrar_resultado(30033, 505, 'Ultrasonido ficticio: sin hallazgos');
SELECT id_estudio, revision, estado FROM integracion.eventos_integracion WHERE id_estudio = 30033;
COMMIT;
'@
        Mongo "print('Antes de exportar: ' + r.resumenes_estudios.countDocuments({ id_estudio: 30033 }) + ' documentos');"
        Pg 'CALL integracion.exportar_pendientes();' 'usr_fdw_pg_mongo'
        Mongo "printjson(r.resumenes_estudios.findOne({ id_estudio: 30033 }));"
        Write-Host "`n-- Corrección del resultado: revisión 2" -ForegroundColor Green
        Pg "SELECT * FROM integracion.registrar_resultado(30033, 505, 'Ultrasonido ficticio: corrección del informe');"
        Pg 'CALL integracion.exportar_pendientes();' 'usr_fdw_pg_mongo'
        Mongo "printjson(r.resumenes_estudios.find({ id_estudio: 30033 }, { _id: 1, revision: 1, resultado_resumen: 1 }).toArray());" }
  7 = { Titulo '7. INT-03: vista web (local + remoto) y perfiles externos diferenciados'
        Pg "SELECT * FROM api.vw_paciente_facturacion WHERE id_paciente IN (1001, 1009) ORDER BY 1;" 'usr_api_web'
        Pg "SELECT * FROM api.vw_citas_mobile WHERE id_paciente = 1001;" 'usr_api_mobile'
        Write-Host "`n-- Intentos prohibidos (deben fallar):" -ForegroundColor Green
        Mostrar 'PostgreSQL como usr_api_mobile' 'SELECT * FROM api.vw_paciente_facturacion;'
        Invoke-JoyceScript -Service postgres -Text 'SELECT * FROM api.vw_paciente_facturacion LIMIT 1;' -PgUser usr_api_mobile -PgLoginSecretVar PG_PW -Env ([ordered]@{ PG_PW = $sec.pg_api_mobile_password }) -AllowFailure
        Mostrar 'PostgreSQL como usr_api_web' 'DELETE FROM clinico.citas WHERE id_cita = 10001;'
        Invoke-JoyceScript -Service postgres -Text 'DELETE FROM clinico.citas WHERE id_cita = 10001;' -PgUser usr_api_web -PgLoginSecretVar PG_PW -Env ([ordered]@{ PG_PW = $sec.pg_api_web_password }) -AllowFailure }
  8 = { Titulo '8. INT-04: exportación hacia MongoDB para reportes'
        Pg @'
SELECT integracion.encolar_exportacion_masiva() AS eventos_nuevos;
SELECT estado, count(*) FROM integracion.eventos_integracion GROUP BY estado;
SELECT (SELECT count(*) FROM clinico.resultados_estudio) AS resultados_postgresql;
'@
        Pg 'CALL integracion.exportar_pendientes(); SELECT count(*) AS documentos_mongodb FROM externo.ft_resumenes_estudios;' 'usr_fdw_pg_mongo' }
  9 = { Titulo '9. INT-05: consulta analítica en MongoDB por médico y tipo de estudio'
        Mongo @'
console.table(r.resumenes_estudios.aggregate([
  { $group: { _id: { medico: '$id_medico', tipo: '$tipo_estudio' }, estudios: { $sum: 1 } } },
  { $sort: { '_id.medico': 1, '_id.tipo': 1 } }
]).toArray().map(d => ({ medico: Number(d._id.medico), tipo: d._id.tipo, estudios: d.estudios })));
'@ }
}

foreach ($n in $Segmento) {
    & $demos[$n] | ForEach-Object { Write-Host $_ }
    if ($n -ne $Segmento[-1]) { Pausa }
}
