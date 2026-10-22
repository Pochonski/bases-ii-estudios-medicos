#requires -Version 7.0
[CmdletBinding()]
param(
    [switch]$StaticOnly,
    [string[]]$ComposeFile = @(), [string[]]$EnvFile = @(), [string]$ProjectName,
    [string]$ProjectDirectory = (Split-Path -Parent $PSScriptRoot)
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Compose-Context.ps1')
$stage = 'ejemplo base'
try {
    $example = New-ComposeContext -ProjectDirectory $ProjectDirectory -ComposeFile @('compose.yaml') -EnvFile @('.env.example') -ProjectName joseph-ejemplo
    Assert-InfraConfiguration -Configuration (Get-ComposeConfiguration $example) -NoPublishedPorts
    Write-Output 'PASS ejemplo base: estructura válida y sin puertos publicados.'
    $stage = 'ejemplo localhost'
    $example = New-ComposeContext -ProjectDirectory $ProjectDirectory -ComposeFile @('compose.yaml','compose.local.yaml') -EnvFile @('.env.example') -ProjectName joseph-ejemplo
    Assert-InfraConfiguration -Configuration (Get-ComposeConfiguration $example)
    Write-Output 'PASS ejemplo localhost: puertos limitados a 127.0.0.1.'
    $stage = 'entorno operativo'
    $context = New-ComposeContext -ComposeFile $ComposeFile -EnvFile $EnvFile -ProjectName $ProjectName -ProjectDirectory $ProjectDirectory
    $config = Get-ComposeConfiguration $context
    Assert-InfraConfiguration -Configuration $config
    Write-Output "PASS entorno operativo: proyecto=$($config.name); selección efectiva aceptada por Compose."
    if ($StaticOnly) { return }
    $stage = 'runtime'
    & docker info --format '{{.ServerVersion}}'
    if ($LASTEXITCODE -ne 0) { throw 'Motor Docker Linux no disponible; runtime NO PROBADO.' }
    Invoke-ProjectCompose $context @('ps')
    $snapshot = Get-PostgresSnapshot -Context $context -Configuration $config
    Write-Output "PASS selección runtime PG: puertos=$($snapshot.Ports); volumen=$($snapshot.Volume)."
    Invoke-ProjectCompose $context @('exec','-T','--user','postgres','postgres','sh','-ec','test -r /run/secrets/postgres_password; exec psql -X -U postgres -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f /opt/proyecto/pruebas/01_extensiones.sql')
    Invoke-ProjectCompose $context @('exec','-T','--user','10001:0','sqlserver','bash','-ec','test -r /run/secrets/sqlserver_sa_password; test "$(id -u)" = 10001; export SQLCMDPASSWORD="$(cat /run/secrets/sqlserver_sa_password)"; exec /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -C -b -Q "SELECT @@VERSION"')
    Invoke-ProjectCompose $context @('exec','-T','--user','mongodb','mongodb','sh','-ec','test -r /run/secrets/mongo_root_password')
    Invoke-ProjectCompose $context @('exec','-T','mongodb','mongosh','--quiet','--eval','const fs=require("fs"); const a=db.getSiblingDB("admin"); if(!a.auth(process.env.MONGO_INITDB_ROOT_USERNAME,fs.readFileSync("/run/secrets/mongo_root_password","utf8").trim())) quit(1); print(a.version()); if(a.runCommand({ping:1}).ok!==1) quit(1);')
    Write-Output 'PASS runtime: consultas autenticadas y lectura de secretos por UID de cada motor. FDW remoto/BSON/exportación pendientes.'
} catch { throw "FAIL ${stage}: $($_.Exception.Message)" }
