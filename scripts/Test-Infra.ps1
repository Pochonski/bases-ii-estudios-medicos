#requires -Version 7.0
[CmdletBinding()]
param([switch]$StaticOnly)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Push-Location (Split-Path -Parent $PSScriptRoot)
try {
    $raw = & docker compose --env-file .env.example config --format json
    if ($LASTEXITCODE -ne 0) { throw 'Compose base inválido.' }
    $config = ($raw -join "`n") | ConvertFrom-Json -AsHashtable
    $names = @($config.services.Keys | Sort-Object)
    if (($names -join ',') -ne 'mongodb,postgres,sqlserver') { throw 'Se esperan tres motores.' }
    if (-not $config.networks['medical-network'].internal) { throw 'Red no interna.' }
    $expectedVolumes = @{ postgres = 'postgres_data'; sqlserver = 'sqlserver_data'; mongodb = 'mongodb_data' }
    foreach ($name in $names) {
        $service = $config.services[$name]
        if ($service.ContainsKey('ports') -and @($service.ports).Count -gt 0) { throw "Puerto publicado por defecto: $name" }
        if (-not $service.healthcheck.test) { throw "Falta healthcheck: $name" }
        if (-not $service.secrets) { throw "Falta secret: $name" }
        if (@($service.volumes | Where-Object { $_.type -eq 'volume' -and $_.source -eq $expectedVolumes[$name] }).Count -ne 1) {
            throw "Falta volumen persistente: $name"
        }
        if (-not $service.networks.ContainsKey('medical-network')) { throw "Falta red: $name" }
        foreach ($key in $service.environment.Keys) {
            if ($key -match '(PASSWORD|TOKEN|SECRET)$') { throw "Secret en environment: $name/$key" }
        }
    }
    $raw = & docker compose --env-file .env.example -f compose.yaml -f compose.local.yaml config --format json
    if ($LASTEXITCODE -ne 0) { throw 'Overlay localhost inválido.' }
    $local = ($raw -join "`n") | ConvertFrom-Json -AsHashtable
    foreach ($name in $names) {
        foreach ($port in $local.services[$name].ports) {
            if ($port.host_ip -ne '127.0.0.1') { throw "Puerto fuera de localhost: $name" }
        }
    }
    Write-Output 'PASS estático: tres motores, red interna, secretos por archivo, volúmenes, healthchecks, puertos localhost opcionales.'
    if ($StaticOnly) { return }
    & docker info --format '{{.ServerVersion}}'
    if ($LASTEXITCODE -ne 0) { throw 'Motor Docker Linux no disponible; runtime NO PROBADO.' }
    & docker compose ps
    & docker compose exec -T --user postgres postgres sh -ec 'exec psql -X -U postgres -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f /opt/proyecto/pruebas/01_extensiones.sql'
    if ($LASTEXITCODE -ne 0) { throw 'Falló smoke PostgreSQL/extensiones.' }
    & docker compose exec -T sqlserver bash -ec 'export SQLCMDPASSWORD="$(cat /run/secrets/sqlserver_sa_password)"; exec /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -C -b -Q "SELECT @@VERSION"'
    if ($LASTEXITCODE -ne 0) { throw 'Falló consulta SQL Server.' }
    & docker compose exec -T mongodb mongosh --quiet --eval 'const fs=require("fs"); const a=db.getSiblingDB("admin"); if(!a.auth(process.env.MONGO_INITDB_ROOT_USERNAME,fs.readFileSync("/run/secrets/mongo_root_password","utf8").trim())) quit(1); print(a.version()); if(a.runCommand({ping:1}).ok!==1) quit(1);'
    if ($LASTEXITCODE -ne 0) { throw 'Falló autenticación/consulta MongoDB.' }
    Write-Output 'PASS runtime: consultas autenticadas y bibliotecas FDW cargadas. P01/exportación MongoDB pendientes de Joyce.'
} finally { Pop-Location }