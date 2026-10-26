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
    'pg_fdw_mongo_login_password'  # login de usr_fdw_pg_mongo en PostgreSQL
)

function Invoke-JoyceCompose {
    param([Parameter(Mandatory)][string[]]$Arguments)
    & docker compose --project-directory $script:JoyceRoot -f (Join-Path $script:JoyceRoot 'compose.yaml') @Arguments
    if ($LASTEXITCODE -ne 0) { throw "docker compose $($Arguments -join ' ') terminó con $LASTEXITCODE" }
}

function Get-JoyceContainerId {
    param([Parameter(Mandatory)][string]$Service)
    $id = (& docker compose --project-directory $script:JoyceRoot -f (Join-Path $script:JoyceRoot 'compose.yaml') ps -q $Service)
    if (-not $id) { throw "El servicio $Service no está en ejecución." }
    return $id.Trim()
}

function Initialize-JoyceSecrets {
    $dir = Join-Path $script:JoyceRoot 'secrets'
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
    & pwsh -NoProfile -File (Join-Path $PSScriptRoot 'Initialize-Local.ps1') -ProjectDirectory $script:JoyceRoot
    if ($LASTEXITCODE -ne 0) { throw 'Initialize-Local.ps1 falló.' }
}

function Get-JoyceSecret {
    param([Parameter(Mandatory)][string]$Name)
    return ([IO.File]::ReadAllText((Join-Path $script:JoyceRoot "secrets/$Name.txt"))).Trim()
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
