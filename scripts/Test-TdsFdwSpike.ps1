#requires -Version 7.0
[CmdletBinding()]
param([switch]$StaticOnly)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'Compose-Context.ps1')
$token = [Convert]::ToHexString([Security.Cryptography.RandomNumberGenerator]::GetBytes(5)).ToLowerInvariant()
$project = "joseph-tds-$token"
$tempRoot = Join-Path $root '.tmp/tds-spike-root'
$envPath = Join-Path $tempRoot '.env'
$started = $false
$ready = $false

function New-SecretFile([string]$Name) {
    $path = Join-Path $tempRoot "secrets/$Name.txt"
    if (-not (Test-Path -LiteralPath $path)) {
        $bytes = [Security.Cryptography.RandomNumberGenerator]::GetBytes(32)
        [IO.File]::WriteAllText($path, ('Aa1!' + [Convert]::ToHexString($bytes)), [Text.UTF8Encoding]::new($false))
    }
}
function Invoke-Spike([string[]]$Command) {
    Invoke-ProjectCompose -Context $context -Command $Command
}
function Assert-CleanProject {
    $existing = @(& docker ps -a --quiet --filter "label=com.docker.compose.project=$project")
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo consultar contenedores Docker.' }
    if ($existing.Count) { throw "Proyecto aislado ya existe: $project" }
    foreach ($volume in 'postgres_data','sqlserver_data','mongodb_data','mongodb_config') {
        $name = "${project}_$volume"
        & docker volume inspect $name *> $null
        if ($LASTEXITCODE -eq 0) { throw "Volumen preexistente inesperado: $name" }
    }
    & docker network inspect "$project-network" *> $null
    if ($LASTEXITCODE -eq 0) { throw "Red preexistente inesperada: $project-network" }
}
function Wait-SqlServerHealthy {
    $id = @(Invoke-Spike @('ps','--all','--quiet','sqlserver'))
    if ($id.Count -ne 1 -or -not $id[0]) { throw 'Falta contenedor SQL Server aislado.' }
    for ($i=0; $i -lt 36; $i++) {
        $health = @(& docker inspect --format '{{.State.Health.Status}}' $id[0])
        if ($LASTEXITCODE -ne 0) { throw 'No se pudo consultar healthcheck SQL Server.' }
        if ($health[0] -eq 'healthy') { return }
        Start-Sleep -Seconds 5
    }
    throw 'SQL Server no recuperó healthcheck tras start.'
}
function Assert-SpikeRemoved {
    $remaining = @(& docker ps -a --quiet --filter "label=com.docker.compose.project=$project")
    if ($LASTEXITCODE -ne 0 -or $remaining.Count) { throw 'Persisten contenedores del spike.' }
    foreach ($volume in 'postgres_data','sqlserver_data','mongodb_data','mongodb_config') {
        & docker volume inspect "${project}_$volume" *> $null
        if ($LASTEXITCODE -eq 0) { throw "Persiste volumen del spike: $volume" }
    }
    Write-Output 'PASS limpieza Docker: sin contenedores ni volúmenes del proyecto temporal'
}

try {
    if (Test-Path -LiteralPath $tempRoot) {
        throw "Existe .tmp/tds-spike-root; revisar antes de ejecutar: $tempRoot"
    }
    New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $root '.env.example') -Destination (Join-Path $tempRoot '.env.example')
    & (Join-Path $PSScriptRoot 'Initialize-Local.ps1') -ProjectDirectory $tempRoot | Out-Null
    New-SecretFile 'fdw_password'
    New-SecretFile 'pg_fdw_login_password'
    & (Join-Path $PSScriptRoot 'Initialize-Local.ps1') -ProjectDirectory $tempRoot | Out-Null
    Add-Content -LiteralPath $envPath -Value "`nTDS_SPIKE_PROJECT=$project" -Encoding utf8
    $context = New-ComposeContext -ProjectDirectory $root -ComposeFile @('compose.yaml','pruebas/integracion/tds-spike.compose.yaml') -EnvFile @($envPath) -ProjectName $project
    $config = Get-ComposeConfiguration -Context $context
    Assert-InfraConfiguration -Configuration $config -NoPublishedPorts
    if ($config.name -ne $project -or $config.networks['medical-network'].name -ne "$project-network") { throw 'Nombre de proyecto o red incorrecto.' }
    foreach ($volume in 'postgres_data','sqlserver_data') {
        if ($config.volumes[$volume].name -ne "${project}_$volume") { throw "Volumen fuera del proyecto: $volume" }
    }
    foreach ($name in 'postgres','sqlserver') {
        if ($config.services[$name].ContainsKey('ports')) { throw "Puerto publicado: $name" }
    }
    foreach ($secret in 'postgres_password','sqlserver_sa_password','fdw_password','pg_fdw_login_password') {
        $expected = [IO.Path]::GetFullPath((Join-Path $tempRoot "secrets/$secret.txt"))
        if ($config.secrets[$secret].file -ne $expected) { throw "Secret fuera del aislamiento: $secret" }
    }
    Write-Output "PASS estático: proyecto $project, red interna, volúmenes propios, sin puertos publicados, secretos temporales"
    if ($StaticOnly) { return }
    & docker info --format '{{.ServerVersion}}' *> $null
    if ($LASTEXITCODE -ne 0) { throw 'Docker Engine no disponible; solo se completó la verificación estática.' }
    Assert-CleanProject
    $started = $true
    Invoke-Spike @('up','-d','--build','--wait','postgres','sqlserver')
    $ready = $true
    Invoke-Spike @('exec','-T','sqlserver','bash','/opt/proyecto/tds-spike/setup-sqlserver.sh')
    Invoke-Spike @('exec','-T','sqlserver','bash','/opt/proyecto/tds-spike/check-sqlserver.sh')
    Invoke-Spike @('exec','-T','postgres','bash','/opt/proyecto/tds-spike/setup-postgres.sh')
    Invoke-Spike @('exec','-T','postgres','bash','/opt/proyecto/tds-spike/check-postgres.sh')
    Invoke-Spike @('stop','sqlserver')
    try {
        Invoke-Spike @('exec','-T','postgres','bash','-c', 'export PGPASSWORD="$(cat /run/secrets/pg_fdw_login_password)"; psql -X -h 127.0.0.1 -U usr_fdw_pg_mssql -d joseph_tds_spike_pg -v ON_ERROR_STOP=1 -Atc "SELECT 1"')
        $composeArgs = $context.Arguments
        $null = @(& docker compose @composeArgs exec -T postgres bash -c 'export PGPASSWORD="$(cat /run/secrets/pg_fdw_login_password)"; psql -X -h 127.0.0.1 -U usr_fdw_pg_mssql -d joseph_tds_spike_pg -v ON_ERROR_STOP=1 -c "SELECT count(*) FROM externo.ft_estado_facturacion"' 2>&1)
        $remoteExit = $LASTEXITCODE
        if ($remoteExit -eq 0) { throw 'Consulta remota funcionó con SQL Server detenido.' }
        Write-Output "PASS negativo: PostgreSQL local responde; FDW falla con SQL Server detenido (código $remoteExit)"
    } finally {
        Invoke-Spike @('start','sqlserver')
        Wait-SqlServerHealthy
    }
    Invoke-Spike @('exec','-T','postgres','bash','/opt/proyecto/tds-spike/check-postgres.sh')
    Write-Output 'PASS recuperación: la consulta remota funciona tras reiniciar SQL Server'
} finally {
    if ($ready) {
        try {
            Invoke-Spike @('exec','-T','postgres','bash','-c', 'export PGPASSWORD="$(cat /run/secrets/postgres_password)"; psql -X -h 127.0.0.1 -U postgres -d postgres -v ON_ERROR_STOP=1 -c "DROP DATABASE IF EXISTS joseph_tds_spike_pg WITH (FORCE)"')
            Invoke-Spike @('exec','-T','sqlserver','bash','-c', 'export SQLCMDPASSWORD="$(cat /run/secrets/sqlserver_sa_password)"; /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -C -b -i /opt/proyecto/tds-spike/02_sqlserver_cleanup.sql')
            Write-Output 'PASS limpieza: bases y login temporales eliminados'
        } catch { Write-Warning "Limpieza de objetos temporales incompleta: $_" }
    }
    if ($started) {
        try {
            Invoke-Spike @('down','--volumes','--remove-orphans')
            Assert-SpikeRemoved
        }
        catch { Write-Warning "Limpieza del proyecto aislado incompleta: $_" }
    }
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
}
