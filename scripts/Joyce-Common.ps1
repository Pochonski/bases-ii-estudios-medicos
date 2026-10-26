#requires -Version 7.0
# Funciones compartidas por Install-JoyceModulos.ps1 y Test-JoyceModulos.ps1.
# Los scripts viajan al contenedor por stdin; los secretos van en las primeras líneas de
# stdin y se exportan como variables de entorno del proceso, nunca en argumentos.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
# Los contenedores emiten UTF-8; sin esto la consola de Windows decodifica con la página OEM.
[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
$OutputEncoding = [Text.UTF8Encoding]::new($false)

$script:JoyceRoot = Split-Path -Parent $PSScriptRoot
$script:JoyceSecretNames = @(
    'fdw_mssql_password',          # svc_pg_mssql_ro en SQL Server
    'fdw_mongo_password',          # svc_pg_mongo_rw en MongoDB
    'pg_fdw_mssql_login_password', # login de usr_fdw_pg_mssql en PostgreSQL
    'pg_fdw_mongo_login_password', # login de usr_fdw_pg_mongo en PostgreSQL
    'pg_api_web_password',         # login de usr_api_web (D-042)
    'pg_api_mobile_password'       # login de usr_api_mobile (D-042)
)

function Get-JoyceComposeArgs {
    $args = @('--project-directory', $script:JoyceRoot, '-f', (Join-Path $script:JoyceRoot 'compose.yaml'))
    $flags = @($env:JOYCETEST_PROJECT_NAME, $env:JOYCETEST_OVERLAY_PATH, $env:JOYCETEST_ENV_PATH)
    if (@($flags | Where-Object { $_ }).Count -gt 0) {
        if (@($flags | Where-Object { -not $_ }).Count -gt 0 -or
            $env:JOYCETEST_PROJECT_NAME -notmatch '^joyce-p18-[a-f0-9]{12}$') {
            throw 'Contexto Compose efímero incompleto o inválido.'
        }
        $args += @('--project-name', $env:JOYCETEST_PROJECT_NAME,
                   '-f', $env:JOYCETEST_OVERLAY_PATH, '--env-file', $env:JOYCETEST_ENV_PATH)
    }
    return $args
}

function Assert-JoyceEphemeralContext {
    if ($env:JOYCETEST_PROJECT_NAME -notmatch '^joyce-p18-[a-f0-9]{12}$' -or
        -not $env:JOYCETEST_OVERLAY_PATH -or -not $env:JOYCETEST_ENV_PATH -or
        -not $env:JOYCETEST_SECRET_DIR -or -not $env:JOYCETEST_MARKER_PATH -or
        -not (Test-Path -LiteralPath $env:JOYCETEST_MARKER_PATH -PathType Leaf)) {
        throw 'Operación con datos de prueba denegada: requiere contexto efímero verificado de P18.'
    }
    $marker = Get-Content -LiteralPath $env:JOYCETEST_MARKER_PATH -Raw
    if ($marker.Trim() -ne $env:JOYCETEST_PROJECT_NAME) { throw 'Marcador efímero inválido.' }
    $config = (& docker compose @(Get-JoyceComposeArgs) config --format json) | Out-String
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo validar Compose efímero.' }
    $c = $config | ConvertFrom-Json
    if ($c.name -ne $env:JOYCETEST_PROJECT_NAME -or
        $c.networks.'medical-network'.name -ne "$($env:JOYCETEST_PROJECT_NAME)-medical-network") {
        throw 'Compose no usa el proyecto o la red efímera esperados.'
    }
    foreach ($v in 'postgres_data','sqlserver_data','mongodb_data','mongodb_config') {
        if ($c.volumes.$v.name -ne "$($env:JOYCETEST_PROJECT_NAME)-$v") {
            throw "Volumen $v fuera del proyecto efímero."
        }
    }
    foreach ($s in 'postgres_password','sqlserver_sa_password','mongo_root_password') {
        $expected = Join-Path $env:JOYCETEST_SECRET_DIR "$s.txt"
        if ([IO.Path]::GetFullPath($c.secrets.$s.file) -ne [IO.Path]::GetFullPath($expected)) {
            throw "Ruta del secreto $s fuera del contexto efímero."
        }
    }
    foreach ($svc in $c.services.PSObject.Properties) {
        $portProperty = $svc.Value.PSObject.Properties['ports']
        if ($portProperty -and @($portProperty.Value).Count -gt 0) {
            throw "El servicio $($svc.Name) publica puertos host."
        }
        $networkNames = @($svc.Value.networks.PSObject.Properties.Name)
        if ($networkNames.Count -ne 1 -or $networkNames[0] -ne 'medical-network') {
            throw "El servicio $($svc.Name) usa una red no autorizada."
        }
    }
    if ((@($c.services.PSObject.Properties.Name) | Sort-Object) -join ',' -ne 'mongodb,postgres,sqlserver') {
        throw 'P18 contiene servicios inesperados.'
    }
    if ($c.services.postgres.image -ne "$($env:JOYCETEST_PROJECT_NAME)/postgres-fdw:ci") {
        throw 'La imagen PostgreSQL no tiene una etiqueta efímera propia.'
    }
    $expectedMounts = @{ postgres = @{'/var/lib/postgresql/data'='postgres_data'};
                         sqlserver = @{'/var/opt/mssql'='sqlserver_data'};
                         mongodb = @{'/data/db'='mongodb_data';'/data/configdb'='mongodb_config'} }
    foreach ($service in $expectedMounts.Keys) {
        foreach ($target in $expectedMounts[$service].Keys) {
            $mount = @($c.services.$service.volumes | Where-Object { $_.target -eq $target })
            if ($mount.Count -ne 1 -or $mount[0].type -ne 'volume' -or
                $mount[0].source -ne $expectedMounts[$service][$target]) {
                throw "Montaje de datos $service $target fuera de volumen efímero."
            }
        }
    }
    return $c
}

function Invoke-JoyceCompose {
    param([Parameter(Mandatory)][string[]]$Arguments)
    & docker compose @(Get-JoyceComposeArgs) @Arguments
    if ($LASTEXITCODE -ne 0) { throw "docker compose $($Arguments -join ' ') terminó con $LASTEXITCODE" }
}

function Get-JoyceContainerId {
    param([Parameter(Mandatory)][string]$Service)
    $id = (& docker compose @(Get-JoyceComposeArgs) ps -q $Service)
    if (-not $id) { throw "El servicio $Service no está en ejecución." }
    return $id.Trim()
}

function Initialize-JoyceSecrets {
    $secretRoot = if ($env:JOYCETEST_SECRET_DIR) {
        Assert-JoyceEphemeralMarker
        Split-Path -Parent $env:JOYCETEST_SECRET_DIR
    } else { $script:JoyceRoot }
    $dir = Join-Path $secretRoot 'secrets'
    $null = New-Item -ItemType Directory -Force -Path $dir
    foreach ($name in $script:JoyceSecretNames) {
        $path = Join-Path $dir "$name.txt"
        if (-not (Test-Path -LiteralPath $path)) {
            $bytes = [byte[]]::new(32)
            [Security.Cryptography.RandomNumberGenerator]::Fill($bytes)
            # Mismo formato que Initialize-Local.ps1: cumple la política de SQL Server.
            [IO.File]::WriteAllText($path, 'Aa1!' + [Convert]::ToHexString($bytes), [Text.UTF8Encoding]::new($false))
        }
    }
    # Reaplica la DACL privada de Joseph a todos los archivos de secrets/ (también los nuevos).
    & pwsh -NoProfile -File (Join-Path $PSScriptRoot 'Initialize-Local.ps1') -ProjectDirectory $secretRoot
    if ($LASTEXITCODE -ne 0) { throw 'Initialize-Local.ps1 falló.' }
}

function Get-JoyceSecret {
    param([Parameter(Mandatory)][string]$Name)
    $dir = if ($env:JOYCETEST_SECRET_DIR) { $env:JOYCETEST_SECRET_DIR } else { Join-Path $script:JoyceRoot 'secrets' }
    return ([IO.File]::ReadAllText((Join-Path $dir "$Name.txt"))).Trim()
}

function Assert-JoyceEphemeralMarker {
    if ($env:JOYCETEST_PROJECT_NAME -notmatch '^joyce-p18-[a-f0-9]{12}$' -or
        -not $env:JOYCETEST_MARKER_PATH -or
        -not (Test-Path -LiteralPath $env:JOYCETEST_MARKER_PATH -PathType Leaf) -or
        (Get-Content -LiteralPath $env:JOYCETEST_MARKER_PATH -Raw).Trim() -ne $env:JOYCETEST_PROJECT_NAME) {
        throw 'Marcador de contexto efímero ausente o inválido.'
    }
}

# Ejecuta un script (archivo o texto) dentro del contenedor. $Env es un hashtable ordenado
# VARIABLE -> valor que se exporta antes de ejecutar. Devuelve la salida; lanza si falla,
# salvo con -AllowFailure, en cuyo caso deja $LASTEXITCODE para que lo examine el llamador.
function Invoke-JoyceScript {
    param(
        [Parameter(Mandatory)][ValidateSet('postgres', 'sqlserver', 'mongodb')][string]$Service,
        [string]$Path,
        [string]$Text,
        [System.Collections.Specialized.OrderedDictionary]$Env = [ordered]@{},
        [string]$PgUser = 'postgres',
        [string]$PgLoginSecretVar,
        [string]$SqlLogin = 'sa',
        [switch]$AllowFailure
    )
    if ($Path) { $Text = [IO.File]::ReadAllText((Join-Path $script:JoyceRoot $Path)) }
    if (-not $Text) { throw 'Indique -Path o -Text.' }
    foreach ($k in $Env.Keys) {
        if ($k -notmatch '^[A-Z_][A-Z0-9_]*$') { throw "Nombre de variable inválido: $k" }
        if ("$($Env[$k])" -match '[\r\n]') { throw "El valor de $k contiene saltos de línea." }
    }
    $reads = ($Env.Keys | ForEach-Object { "IFS= read -r $_; export $_;" }) -join ' '
    $tmp = "/tmp/joyce-$([guid]::NewGuid().ToString('N'))"
    switch ($Service) {
        'postgres' {
            if ($PgUser -eq 'postgres') {
                $run = "psql -X -q -v ON_ERROR_STOP=1 -U postgres -d `"`$POSTGRES_DB`" -f $tmp"
            } else {
                # Login real del perfil por TCP con SCRAM; la contraseña viene de $PgLoginSecretVar.
                $run = "PGPASSWORD=`"`$$PgLoginSecretVar`" psql -X -q -v ON_ERROR_STOP=1 -h 127.0.0.1 -U $PgUser -d `"`$POSTGRES_DB`" -f $tmp"
            }
            $user = 'postgres'
        }
        'sqlserver' {
            $sqlPassword = if ($SqlLogin -eq 'sa') { 'SQLCMDPASSWORD="$(cat /run/secrets/sqlserver_sa_password)"' }
                           else { 'SQLCMDPASSWORD="$FDW_MSSQL_PASSWORD"' }
            $run = "$sqlPassword /opt/mssql-tools18/bin/sqlcmd -S localhost -U $SqlLogin -C -b -I -W -i $tmp"
            $user = ''
        }
        'mongodb' {
            $auth = "const fs = require('fs'); if (!db.getSiblingDB('admin').auth(process.env.MONGO_INITDB_ROOT_USERNAME, fs.readFileSync('/run/secrets/mongo_root_password', 'utf8').trim())) quit(1);"
            $Text = $auth + "`n" + $Text
            $run = "mongosh --quiet --host 127.0.0.1 --file $tmp"
            $user = ''
        }
    }
    $bash = "set -o pipefail; umask 077; $reads cat > $tmp; $run; rc=`$?; rm -f $tmp; exit `$rc"
    $stdin = (@($Env.Values | ForEach-Object { "$_" }) + $Text) -join "`n"
    $id = Get-JoyceContainerId $Service
    $dockerArgs = @('exec', '-i')
    if ($user) { $dockerArgs += @('-u', $user) }
    $output = $stdin | & docker @dockerArgs $id bash -c $bash 2>&1
    $code = $LASTEXITCODE
    $text = ($output | ForEach-Object { "$_" }) -join "`n"
    if ($code -ne 0 -and -not $AllowFailure) {
        throw "Falló $Service ($($Path ?? 'texto')), código $code`n$text"
    }
    $global:LASTEXITCODE = $code
    return $text
}

function Wait-JoyceHealthy {
    param([string[]]$Services = @('postgres', 'sqlserver', 'mongodb'), [int]$TimeoutSeconds = 240)
    $limit = (Get-Date).AddSeconds($TimeoutSeconds)
    foreach ($s in $Services) {
        do {
            $state = (& docker inspect -f '{{.State.Health.Status}}' (Get-JoyceContainerId $s)).Trim()
            if ($state -eq 'healthy') { break }
            if ((Get-Date) -gt $limit) { throw "$s no quedó healthy (estado: $state)." }
            Start-Sleep -Seconds 3
        } while ($true)
    }
}
