#requires -Version 7.0
# Verificación de entrega: P18 (instalación desde cero, opcional), suite completa, P12 en los
# TRES motores (restart) y P17 (configuración FDW, roles y autenticación sin secretos).
#   pwsh -NoProfile -File ./scripts/Test-Entrega.ps1 [-DesdeCero] [-EvidencePath ...]
# -DesdeCero crea y retira un proyecto Compose efímero, sin puertos host.
[CmdletBinding()]
param([switch]$DesdeCero, [switch]$StaticOnly, [switch]$RunDemo,
      [switch]$DemoSinPausa, [string]$EvidencePath)
. (Join-Path $PSScriptRoot 'Joyce-Common.ps1')

$log = [System.Collections.Generic.List[string]]::new()
function Out-Log([string]$m) { $log.Add($m); Write-Output $m }
function Step([string]$m) { Out-Log "`n===== $m" }
$pwsh = (Get-Process -Id $PID).Path
$started = $false
$tempRoot = $null
$project = $null

function Assert-NoExistingResources {
    $containers = @(& docker ps -aq --filter "label=com.docker.compose.project=$project")
    if ($LASTEXITCODE -ne 0 -or $containers.Count) {
        throw "No se pudo verificar ausencia de contenedores para $project."
    }
    & docker network inspect "$project-medical-network" *> $null
    if ($LASTEXITCODE -eq 0) { throw "Red preexistente para $project; se cancela P18." }
    foreach ($name in @("$project-postgres_data", "$project-sqlserver_data", "$project-mongodb_data", "$project-mongodb_config")) {
        & docker volume inspect $name *> $null
        if ($LASTEXITCODE -eq 0) { throw "Volumen preexistente $name; se cancela P18." }
    }
    & docker image inspect "$project/postgres-fdw:ci" *> $null
    if ($LASTEXITCODE -eq 0) { throw "Imagen preexistente para $project; se cancela P18." }
    $global:LASTEXITCODE = 0
}

function Assert-OwnedResources {
    $ids = @(& docker ps -aq --filter "label=com.docker.compose.project=$project")
    foreach ($id in $ids) {
        $owner = (& docker inspect -f '{{index .Config.Labels "com.docker.compose.project"}}' $id).Trim()
        if ($owner -ne $project) { throw "Contenedor ajeno detectado: $id" }
    }
    foreach ($name in @("$project-postgres_data", "$project-sqlserver_data", "$project-mongodb_data", "$project-mongodb_config")) {
        $v = & docker volume inspect $name --format '{{index .Labels "com.docker.compose.project"}}' 2>$null
        if ($LASTEXITCODE -eq 0 -and "$v".Trim() -ne $project) { throw "Volumen ajeno detectado: $name" }
    }
    $n = & docker network inspect "$project-medical-network" --format '{{index .Labels "com.docker.compose.project"}}' 2>$null
    if ($LASTEXITCODE -eq 0 -and "$n".Trim() -ne $project) { throw 'Red ajena detectada.' }
    $global:LASTEXITCODE = 0
}

function New-IsolatedContext {
    param([switch]$NoDocker)
    $suffix = [guid]::NewGuid().ToString('N').Substring(0, 12)
    $script:project = "joyce-p18-$suffix"
    $script:tempRoot = Join-Path $script:JoyceRoot ".tmp/p18/$project"
    $null = New-Item -ItemType Directory -Force -Path $tempRoot
    $env:JOYCETEST_PROJECT_NAME = $project
    $env:JOYCETEST_MARKER_PATH = Join-Path $tempRoot 'owner.txt'
    $env:JOYCETEST_SECRET_DIR = Join-Path $tempRoot 'secrets'
    $env:JOYCETEST_OVERLAY_PATH = Join-Path $tempRoot 'isolation.json'
    $env:JOYCETEST_ENV_PATH = Join-Path $tempRoot '.env'
    [IO.File]::WriteAllText($env:JOYCETEST_MARKER_PATH, $project)
    Copy-Item -LiteralPath (Join-Path $script:JoyceRoot '.env.example') -Destination $env:JOYCETEST_ENV_PATH
    $v = @{}
    foreach ($name in 'postgres_data','sqlserver_data','mongodb_data','mongodb_config') {
        $v[$name] = @{ name = "$project-$name" }
    }
    $secrets = @{}
    foreach ($name in 'postgres_password','sqlserver_sa_password','mongo_root_password') {
        $secrets[$name] = @{ file = ((Join-Path $env:JOYCETEST_SECRET_DIR "$name.txt") -replace '\\','/') }
    }
    $overlay = @{ name = $project; services = @{ postgres = @{ image = "$project/postgres-fdw:ci" } };
                  networks = @{ 'medical-network' = @{ name = "$project-medical-network"; internal = $true } };
                  volumes = $v; secrets = $secrets }
    [IO.File]::WriteAllText($env:JOYCETEST_OVERLAY_PATH, ($overlay | ConvertTo-Json -Depth 8))
    Initialize-JoyceSecrets
    $null = Assert-JoyceEphemeralContext
    if (-not $NoDocker) { Assert-NoExistingResources }
    $suffixMessage = if ($NoDocker) { 'recursos Docker NO COMPROBADOS' } else { 'recursos preexistentes ausentes' }
    Out-Log "PASS aislamiento P18: $project; red/volúmenes/secretos propios, cero puertos publicados; $suffixMessage"
}

function Get-Conteos {
    $pg = Invoke-JoyceScript -Service postgres -Text @'
\pset tuples_only on
\pset format unaligned
SELECT 'pg.pacientes=' || count(*) FROM clinico.pacientes
UNION ALL SELECT 'pg.pacientes_sj=' || count(*) FROM clinico.pacientes_sj
UNION ALL SELECT 'pg.resultados=' || count(*) FROM clinico.resultados_estudio
UNION ALL SELECT 'pg.revision_prueba=' || revision FROM clinico.resultados_estudio WHERE id_estudio=30031
UNION ALL SELECT 'pg.eventos_procesados=' || count(*) FROM integracion.eventos_integracion WHERE estado = 'PROCESADO';
'@
    $sq = Invoke-JoyceScript -Service sqlserver -Text @'
SET NOCOUNT ON;
SELECT 'mssql.paciente_integracion=' + CAST(COUNT(*) AS varchar) FROM integracion_externa.dbo.paciente_integracion;
SELECT 'mssql.facturas=' + CAST(COUNT(*) AS varchar) FROM integracion_externa.dbo.facturas_externas;
SELECT 'mssql.factura_monto_centimos=' + CAST(CAST(monto * 100 AS bigint) AS varchar)
  FROM integracion_externa.dbo.facturas_externas WHERE id_factura=90001;
'@
    $mg = Invoke-JoyceScript -Service mongodb -Text @'
const r = db.getSiblingDB('reportes_medicos');
print('mongo.resumenes=' + r.resumenes_estudios.countDocuments({}));
print('mongo.indicadores=' + r.indicadores_mensuales.countDocuments({}));
const doc = r.resumenes_estudios.findOne({id_estudio:30031});
if (doc) print('mongo.revision_prueba=' + doc.revision);
'@
    return @(($pg, $sq, $mg) -join "`n" -split "`n" | Where-Object { $_ -match '^[a-z_.]+=\d+$' } | Sort-Object)
}

try {
    Out-Log "Verificación de entrega - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz') - commit $((git -C $script:JoyceRoot rev-parse --short HEAD).Trim())"
    if ($StaticOnly) {
        New-IsolatedContext -NoDocker
        $originalOverlay = [IO.File]::ReadAllText($env:JOYCETEST_OVERLAY_PATH)
        try {
            $tampered = $originalOverlay | ConvertFrom-Json -AsHashtable
            $tampered.networks.'medical-network'.name = 'medical-network'
            [IO.File]::WriteAllText($env:JOYCETEST_OVERLAY_PATH, ($tampered | ConvertTo-Json -Depth 8))
            $rejected = $false
            try { $null = Assert-JoyceEphemeralContext } catch { $rejected = $true }
            if (-not $rejected) { throw 'La red compartida fue aceptada por la protección P18.' }
            Out-Log 'PASS negativo estático: red global medical-network rechazada'
        } finally {
            [IO.File]::WriteAllText($env:JOYCETEST_OVERLAY_PATH, $originalOverlay)
        }
        $null = Assert-JoyceEphemeralContext
        Out-Log 'PASS estático: Compose efectivo validado; motores, pruebas y limpieza Docker NO EJECUTADOS.'
        return
    }
    Out-Log ("Docker: " + (& docker version --format '{{.Server.Version}} kernel {{.Server.KernelVersion}}'))
    if ($LASTEXITCODE -ne 0) { throw 'Docker Engine no está disponible.' }
    if (-not $DesdeCero) { throw 'Test-Entrega exige -DesdeCero: la suite modifica datos sintéticos y reinicia motores.' }
    New-IsolatedContext
    if ($DesdeCero) {
        Step 'P18 instalación desde proyecto y volúmenes efímeros vacíos'
        $started = $true
        $inst = & $pwsh -NoProfile -File (Join-Path $PSScriptRoot 'Install-JoyceModulos.ps1') -LoadInitialData 2>&1
        if ($LASTEXITCODE -ne 0) { Out-Log (($inst | Select-Object -Last 80) -join "`n"); throw 'FALLA P18: instalación desde cero' }
        Assert-OwnedResources
        Out-Log (($inst | Where-Object { "$_" -match '^(PASS|==)' }) -join "`n")

        # Pruebas del núcleo de Joseph: requieren el fixture intacto, antes de la suite.
        Step 'Núcleo PostgreSQL de Joseph sobre la instalación integrada (estructura, integridad, P14)'
        foreach ($f in '01_estructura', '02_integridad', '03_particiones') {
            Out-Log (Invoke-JoyceScript -Service postgres -Path "pruebas/postgresql/$f.sql")
        }
    }

    Step 'Suite funcional completa (Test-JoyceModulos.ps1)'
    $suite = & $pwsh -NoProfile -File (Join-Path $PSScriptRoot 'Test-JoyceModulos.ps1') 2>&1
    $suiteText = ($suite | ForEach-Object { "$_" }) -join "`n"
    Out-Log (($suite | Where-Object { "$_" -match 'PASS|FALLA|RESULTADO' }) -join "`n")
    if ($LASTEXITCODE -ne 0 -or $suiteText -notmatch 'RESULTADO: PASA') {
        Out-Log (($suite | Select-Object -Last 80) -join "`n")
        throw 'FALLA: suite funcional'
    }
    if ($DesdeCero) { Out-Log 'PASS P18: desde volúmenes vacíos, instalación y suite completa sin intervención manual' }

    Step 'Seguridad API: facturación remota huérfana no aparece en la vista web'
    $alcanceApi = & $pwsh -NoProfile -File (Join-Path $PSScriptRoot 'Test-ApiScope.ps1') 2>&1
    if ($LASTEXITCODE -ne 0) {
        Out-Log (($alcanceApi | Select-Object -Last 40) -join "`n")
        throw 'FALLA: alcance de facturación web'
    }
    Out-Log (($alcanceApi | Where-Object { "$_" -match 'PASS alcance API|PASS limpieza API' }) -join "`n")

    Step 'Concurrencia real del outbox: dos exportadores y dos revisiones del mismo estudio'
    $concurrente = & $pwsh -NoProfile -File (Join-Path $PSScriptRoot 'Test-OutboxConcurrency.ps1') 2>&1
    if ($LASTEXITCODE -ne 0) {
        Out-Log (($concurrente | Select-Object -Last 40) -join "`n")
        throw 'FALLA: concurrencia del outbox'
    }
    Out-Log (($concurrente | Where-Object { "$_" -match 'PASS concurrencia|evento .* rev' }) -join "`n")

    Step 'Restauración comprobada en bases nuevas de los tres motores efímeros'
    $restauracion = & $pwsh -NoProfile -File (Join-Path $PSScriptRoot 'Test-Restore.ps1') 2>&1
    if ($LASTEXITCODE -ne 0) {
        Out-Log (($restauracion | Select-Object -Last 40) -join "`n")
        throw 'FALLA: restauración de los tres motores'
    }
    Out-Log (($restauracion | Where-Object { "$_" -match 'INFO MongoDB|PASS restauración' }) -join "`n")

    Step 'Instalación ordinaria repetida: conservar factura sintética y rechazar recarga inicial'
    $null = Invoke-JoyceScript -Service sqlserver -Text @'
:on error exit
USE integracion_externa;
EXEC dbo.sp_registrar_factura_externa @id_factura=99971, @id_estudio=30023,
  @id_paciente=2003, @codigo_region='SJ', @monto=6789.12, @estado='PENDIENTE';
GO
'@
    try {
        $normal = & $pwsh -NoProfile -File (Join-Path $PSScriptRoot 'Install-JoyceModulos.ps1') -SkipUp 2>&1
        if ($LASTEXITCODE -ne 0) { Out-Log (($normal | Select-Object -Last 40) -join "`n"); throw 'Instalación normal repetida falló.' }
        $negative = & $pwsh -NoProfile -File (Join-Path $PSScriptRoot 'Install-JoyceModulos.ps1') -SkipUp -LoadInitialData 2>&1
        if ($LASTEXITCODE -eq 0 -or (($negative | ForEach-Object { "$_" }) -join "`n") -notmatch 'Carga inicial SQL Server denegada') {
            throw 'La carga inicial no rechazó tablas pobladas como se esperaba.'
        }
        $global:LASTEXITCODE = 0
        $direct = Invoke-JoyceScript -Service sqlserver -Path 'sqlserver/06_datos_prueba.sql' -AllowFailure
        if ($LASTEXITCODE -eq 0 -or $direct -notmatch '51021') {
            throw 'El fixture SQL Server aceptó ejecución directa sobre datos existentes.'
        }
        $global:LASTEXITCODE = 0
        $invoice = Invoke-JoyceScript -Service sqlserver -Text @'
SET NOCOUNT ON;
USE integracion_externa;
SELECT CAST(COUNT(*) AS varchar(20)) FROM dbo.facturas_externas
WHERE id_factura=99971 AND monto=6789.12 AND estado='PENDIENTE';
'@
        if (@($invoice -split '\r?\n' | Where-Object { $_.Trim() -eq '1' }).Count -ne 1) {
            throw 'La instalación normal cambió o borró la factura sintética.'
        }
        Out-Log 'PASS instalación normal conserva factura/importe; carga inicial y SQL directo sobre datos existentes rechazados'
    } finally {
        $null = Invoke-JoyceScript -Service sqlserver -Text @'
:on error exit
USE integracion_externa;
DELETE FROM dbo.facturas_externas WHERE id_factura=99971;
EXEC dbo.sp_recalcular_resumen_facturacion @id_paciente=2003, @codigo_region='SJ';
GO
'@
    }

    Step 'P12 persistencia de los TRES motores tras reinicio'
    $antes = Get-Conteos
    Out-Log ("antes:   " + ($antes -join ', '))
    $ids = @('postgres', 'sqlserver', 'mongodb' | ForEach-Object { Get-JoyceContainerId $_ })
    Invoke-JoyceCompose @('restart', 'postgres', 'sqlserver', 'mongodb')
    Wait-JoyceHealthy
    $despues = Get-Conteos
    Out-Log ("después: " + ($despues -join ', '))
    $ids2 = @('postgres', 'sqlserver', 'mongodb' | ForEach-Object { Get-JoyceContainerId $_ })
    if (($antes -join ',') -ne ($despues -join ',') -or $antes.Count -lt 11) { throw 'FALLA P12: los datos cambiaron tras el reinicio' }
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
    if ($RunDemo) {
        Step 'Demostración en el mismo proyecto efímero (sin afectar datos compartidos)'
        & $pwsh -NoProfile -File (Join-Path $PSScriptRoot 'Demo-Video.ps1') -SinPausa:$DemoSinPausa
        if ($LASTEXITCODE -ne 0) { throw 'FALLA: demostración efímera.' }
        Out-Log 'PASS demostración: nueve segmentos ejecutados dentro de P18 efímero'
    }
    Out-Log "`nRESULTADO: PASA - verificación de entrega completa."
}
catch {
    Out-Log "`nRESULTADO: FALLA`n$($_.Exception.Message)"
    throw
}
finally {
    if ($started) {
        try {
            $null = Assert-JoyceEphemeralContext
            Assert-OwnedResources
            Invoke-JoyceCompose @('down', '--volumes')
            & docker image inspect "$project/postgres-fdw:ci" *> $null
            if ($LASTEXITCODE -eq 0) {
                & docker image rm "$project/postgres-fdw:ci" *> $null
                if ($LASTEXITCODE -ne 0) { throw "No se pudo retirar la etiqueta de imagen efímera $project." }
            }
            Assert-NoExistingResources
            Out-Log "PASS limpieza: solo recursos del proyecto efímero $project; volúmenes compartidos intactos"
        } catch {
            Out-Log "FALLA limpieza segura de $project`: $($_.Exception.Message). Recursos conservados para diagnóstico; no ejecutar down sobre estudios-medicos."
            throw
        }
    }
    if ($EvidencePath) {
        if ($env:JOYCETEST_SECRET_DIR -and (Test-Path -LiteralPath $env:JOYCETEST_SECRET_DIR)) {
            $textLog = $log -join "`n"
            foreach ($file in Get-ChildItem -LiteralPath $env:JOYCETEST_SECRET_DIR -File) {
                $secret = [IO.File]::ReadAllText($file.FullName).Trim()
                if ($secret -and $textLog.Contains($secret)) { throw "Secreto detectado en evidencia: $($file.Name)" }
            }
        }
        $full = Join-Path $script:JoyceRoot $EvidencePath
        $null = New-Item -ItemType Directory -Force -Path (Split-Path -Parent $full)
        [IO.File]::WriteAllLines($full, $log, [Text.UTF8Encoding]::new($false))
        Write-Output "Evidencia escrita en $EvidencePath"
    }
    if ($tempRoot -and (Test-Path -LiteralPath $tempRoot)) {
        $allowed = [IO.Path]::GetFullPath((Join-Path $script:JoyceRoot '.tmp/p18')) + [IO.Path]::DirectorySeparatorChar
        $resolved = [IO.Path]::GetFullPath($tempRoot)
        if (-not $resolved.StartsWith($allowed, [StringComparison]::OrdinalIgnoreCase)) { throw 'Ruta temporal fuera del workspace.' }
        if (-not $started -or -not (& docker ps -aq --filter "label=com.docker.compose.project=$project")) {
            Remove-Item -LiteralPath $resolved -Recurse -Force
        }
    }
    foreach ($name in 'JOYCETEST_PROJECT_NAME','JOYCETEST_MARKER_PATH','JOYCETEST_SECRET_DIR','JOYCETEST_OVERLAY_PATH','JOYCETEST_ENV_PATH') {
        [Environment]::SetEnvironmentVariable($name, $null, 'Process')
    }
}
