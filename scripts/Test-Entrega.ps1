#requires -Version 7.0
# Verificación de entrega: P18 (instalación desde cero, opcional), suite completa, P12 en los
# TRES motores (restart) y P17 (configuración FDW, roles y autenticación sin secretos).
#   pwsh -NoProfile -File ./scripts/Test-Entrega.ps1 [-DesdeCero] [-EvidencePath ...]
# -DesdeCero ejecuta `docker compose down --volumes` de ESTE proyecto: borra los datos locales
# de los tres motores (se reconstruyen completos con los scripts). No toca otros proyectos.
[CmdletBinding()]
param([switch]$DesdeCero, [string]$EvidencePath)
. (Join-Path $PSScriptRoot 'Joyce-Common.ps1')

$log = [System.Collections.Generic.List[string]]::new()
function Out-Log([string]$m) { $log.Add($m); Write-Output $m }
function Step([string]$m) { Out-Log "`n===== $m" }
$pwsh = (Get-Process -Id $PID).Path

function Get-Conteos {
    $pg = Invoke-JoyceScript -Service postgres -Text @'
\pset tuples_only on
\pset format unaligned
SELECT 'pg.pacientes=' || count(*) FROM clinico.pacientes
UNION ALL SELECT 'pg.pacientes_sj=' || count(*) FROM clinico.pacientes_sj
UNION ALL SELECT 'pg.resultados=' || count(*) FROM clinico.resultados_estudio
UNION ALL SELECT 'pg.eventos_procesados=' || count(*) FROM integracion.eventos_integracion WHERE estado = 'PROCESADO';
'@
    $sq = Invoke-JoyceScript -Service sqlserver -Text @'
SET NOCOUNT ON;
SELECT 'mssql.paciente_integracion=' + CAST(COUNT(*) AS varchar) FROM integracion_externa.dbo.paciente_integracion;
SELECT 'mssql.facturas=' + CAST(COUNT(*) AS varchar) FROM integracion_externa.dbo.facturas_externas;
'@
    $mg = Invoke-JoyceScript -Service mongodb -Text @'
const r = db.getSiblingDB('reportes_medicos');
print('mongo.resumenes=' + r.resumenes_estudios.countDocuments({}));
print('mongo.indicadores=' + r.indicadores_mensuales.countDocuments({}));
'@
    return @(($pg, $sq, $mg) -join "`n" -split "`n" | Where-Object { $_ -match '^[a-z_.]+=\d+$' } | Sort-Object)
}

try {
    Out-Log "Verificación de entrega - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz') - commit $((git -C $script:JoyceRoot rev-parse --short HEAD).Trim())"
    Out-Log ("Docker: " + (& docker version --format '{{.Server.Version}} kernel {{.Server.KernelVersion}}'))

    if ($DesdeCero) {
        Step 'P18 instalación desde cero: down --volumes de este proyecto'
        Invoke-JoyceCompose @('down', '--volumes', '--remove-orphans')
        Out-Log (((& docker volume ls --format '{{.Name}}') | Where-Object { $_ -like 'estudios-medicos_*' }) -join ', ')
        Out-Log 'Volúmenes del proyecto eliminados (lista anterior vacía = PASS).'
        $inst = & $pwsh -NoProfile -File (Join-Path $PSScriptRoot 'Install-JoyceModulos.ps1') 2>&1
        if ($LASTEXITCODE -ne 0) { Out-Log ($inst -join "`n"); throw 'FALLA P18: instalación desde cero' }
        Out-Log (($inst | Where-Object { "$_" -match '^(PASS|==)' }) -join "`n")
    }

    Step 'Suite funcional completa (Test-JoyceModulos.ps1)'
    $suite = & $pwsh -NoProfile -File (Join-Path $PSScriptRoot 'Test-JoyceModulos.ps1') 2>&1
    $suiteText = ($suite | ForEach-Object { "$_" }) -join "`n"
    Out-Log (($suite | Where-Object { "$_" -match 'PASS|FALLA|RESULTADO' }) -join "`n")
    if ($LASTEXITCODE -ne 0 -or $suiteText -notmatch 'RESULTADO: PASA') { throw 'FALLA: suite funcional' }
    if ($DesdeCero) { Out-Log 'PASS P18: desde volúmenes vacíos, instalación y suite completa sin intervención manual' }

    Step 'P12 persistencia de los TRES motores tras reinicio'
    $antes = Get-Conteos
    Out-Log ("antes:   " + ($antes -join ', '))
    $ids = @('postgres', 'sqlserver', 'mongodb' | ForEach-Object { Get-JoyceContainerId $_ })
    Invoke-JoyceCompose @('restart', 'postgres', 'sqlserver', 'mongodb')
    Wait-JoyceHealthy
    $despues = Get-Conteos
    Out-Log ("después: " + ($despues -join ', '))
    $ids2 = @('postgres', 'sqlserver', 'mongodb' | ForEach-Object { Get-JoyceContainerId $_ })
    if (($antes -join ',') -ne ($despues -join ',') -or $antes.Count -lt 8) { throw 'FALLA P12: los datos cambiaron tras el reinicio' }
    if (($ids -join ',') -ne ($ids2 -join ',')) { throw 'FALLA P12: cambiaron los contenedores' }
    $p01 = Invoke-JoyceScript -Service postgres -PgUser usr_fdw_pg_mssql -PgLoginSecretVar PG_PW `
        -Env ([ordered]@{ PG_PW = (Get-JoyceSecret 'pg_fdw_mssql_login_password') }) -Text @'
\pset tuples_only on
SELECT count(*) FROM externo.ft_estado_facturacion;
'@
    if ($p01.Trim() -ne '24') { throw "FALLA P12: FDW SQL Server tras reinicio devolvió '$($p01.Trim())'" }
    Out-Log 'PASS P12: mismos contenedores y mismos conteos en PostgreSQL, SQL Server y MongoDB; FDW operativo tras reinicio'

    Step 'P17 canales FDW, perfiles y autenticación (sin contraseñas)'
    Out-Log (Invoke-JoyceScript -Service postgres -Text @'
\echo '--- Parámetros de conexión y autenticación (postgresql.conf / pg_hba.conf)'
SELECT name, setting FROM pg_settings
WHERE name IN ('listen_addresses', 'port', 'password_encryption', 'hba_file', 'ssl', 'timezone') ORDER BY name;
SELECT line_number, type, database, user_name, address, auth_method FROM pg_hba_file_rules ORDER BY line_number;
\echo '--- Extensiones FDW'
SELECT extname, extversion FROM pg_extension WHERE extname LIKE '%fdw' ORDER BY 1;
\echo '--- CREATE SERVER efectivos'
SELECT s.srvname AS servidor, w.fdwname AS wrapper, s.srvoptions AS opciones
FROM pg_foreign_server AS s JOIN pg_foreign_data_wrapper AS w ON w.oid = s.srvfdw ORDER BY 1;
\echo '--- USER MAPPING (password omitido)'
SELECT srvname AS servidor, usename AS rol_postgresql,
       ARRAY(SELECT o FROM unnest(umoptions) AS o WHERE o NOT LIKE 'password=%') AS opciones
FROM pg_user_mappings ORDER BY 1, 2;
\echo '--- Tablas foráneas'
SELECT foreign_table_schema || '.' || foreign_table_name AS tabla, foreign_server_name AS servidor
FROM information_schema.foreign_tables ORDER BY 1;
\echo '--- Perfiles del curso'
SELECT rolname, rolcanlogin AS login, rolsuper AS superusuario, rolconnlimit AS limite_conexiones, rolconfig AS politicas
FROM pg_roles WHERE rolname IN ('usr_fdw_pg_mssql', 'usr_fdw_pg_mongo', 'usr_api_web', 'usr_api_mobile', 'api_propietario')
ORDER BY rolname;
\echo '--- Privilegios de los perfiles'
SELECT grantee, table_schema || '.' || table_name AS objeto, string_agg(privilege_type, ',' ORDER BY privilege_type) AS privilegios
FROM information_schema.role_table_grants
WHERE grantee IN ('usr_fdw_pg_mssql', 'usr_fdw_pg_mongo', 'usr_api_web', 'usr_api_mobile', 'api_propietario')
GROUP BY grantee, table_schema, table_name ORDER BY grantee, objeto;
SELECT r.rolname AS rol, p.oid::regprocedure AS rutina
FROM pg_proc AS p CROSS JOIN pg_roles AS r
WHERE p.pronamespace::regnamespace::text IN ('integracion', 'externo')
  AND r.rolname IN ('usr_fdw_pg_mssql', 'usr_fdw_pg_mongo', 'usr_api_web', 'usr_api_mobile')
  AND has_function_privilege(r.oid, p.oid, 'EXECUTE') ORDER BY 1, 2;
'@)
    Out-Log (Invoke-JoyceScript -Service sqlserver -Text @'
SET NOCOUNT ON;
USE integracion_externa;
PRINT '--- SQL Server: permisos de svc_pg_mssql_ro';
SELECT pr.name AS principal, pe.state_desc AS estado, pe.permission_name AS permiso,
       COALESCE(OBJECT_NAME(pe.major_id), SCHEMA_NAME(pe.major_id)) AS objeto
FROM sys.database_permissions AS pe JOIN sys.database_principals AS pr ON pr.principal_id = pe.grantee_principal_id
WHERE pr.name = 'svc_pg_mssql_ro' ORDER BY estado DESC, objeto, permiso;
SELECT name, type_desc, is_disabled, is_policy_checked FROM sys.sql_logins WHERE name = 'svc_pg_mssql_ro';
'@)
    Out-Log (Invoke-JoyceScript -Service mongodb -Text @'
print('--- MongoDB: usuario de servicio y privilegios');
const u = db.getSiblingDB('reportes_medicos').getUser('svc_pg_mongo_rw', { showPrivileges: true });
printjson({ user: u.user, db: u.db, mechanisms: u.mechanisms, roles: u.roles, privilegios: u.inheritedPrivileges });
'@)
    Out-Log 'PASS P17: servidores, mappings, tablas foráneas, perfiles y permisos documentados desde los motores'
    Out-Log "`nRESULTADO: PASA - verificación de entrega completa."
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
        Write-Output "Evidencia escrita en $EvidencePath"
    }
}
