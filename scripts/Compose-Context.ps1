#requires -Version 7.0
# Parámetros explícitos tienen precedencia; sin ellos Docker conserva COMPOSE_FILE,
# COMPOSE_ENV_FILES, COMPOSE_PROJECT_NAME y .env. No imprimir la configuración completa.
function New-ComposeContext {
    param(
        [string[]]$ComposeFile = @(), [string[]]$EnvFile = @(), [string]$ProjectName,
        [string]$ProjectDirectory = (Split-Path -Parent $PSScriptRoot)
    )
    $root = (Resolve-Path -LiteralPath $ProjectDirectory).ProviderPath
    $composeArgs = @('--project-directory', $root)
    foreach ($file in $ComposeFile) {
        $path = [IO.Path]::GetFullPath($file, $root)
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Falta archivo Compose: $path" }
        $composeArgs += @('-f', $path)
    }
    foreach ($file in $EnvFile) {
        $path = [IO.Path]::GetFullPath($file, $root)
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Falta archivo de entorno: $path" }
        $composeArgs += @('--env-file', $path)
    }
    if ($ProjectName) { $composeArgs += @('--project-name', $ProjectName) }
    [pscustomobject]@{ Arguments = [string[]]$composeArgs; ProjectDirectory = $root }
}

function Invoke-ProjectCompose {
    param([Parameter(Mandatory)]$Context, [Parameter(Mandatory)][string[]]$Command)
    $composeArgs = $Context.Arguments
    Push-Location $Context.ProjectDirectory
    try {
        & docker compose @composeArgs @Command
        if ($LASTEXITCODE -ne 0) { throw "Compose $($Command[0]) terminó con código $LASTEXITCODE." }
    } finally { Pop-Location }
}

function Get-ComposeConfiguration {
    param([Parameter(Mandatory)]$Context)
    $raw = Invoke-ProjectCompose -Context $Context -Command @('config', '--format', 'json')
    ($raw -join "`n") | ConvertFrom-Json -AsHashtable
}

function Assert-InfraConfiguration {
    param([hashtable]$Configuration, [switch]$NoPublishedPorts)
    $names = @($Configuration.services.Keys | Sort-Object)
    if (($names -join ',') -ne 'mongodb,postgres,sqlserver') { throw 'Se esperan tres motores.' }
    if (-not $Configuration.networks['medical-network'].internal) { throw 'Red no interna.' }
    $volumes = @{ postgres = 'postgres_data'; sqlserver = 'sqlserver_data'; mongodb = 'mongodb_data' }
    foreach ($name in $names) {
        $service = $Configuration.services[$name]
        if ($service.ContainsKey('ports')) {
            if ($NoPublishedPorts -and @($service.ports).Count) { throw "Puerto publicado en base: $name" }
            foreach ($port in $service.ports) {
                if ($port.host_ip -ne '127.0.0.1') { throw "Puerto fuera de localhost: $name" }
            }
        }
        if (-not $service.healthcheck.test -or -not $service.secrets) { throw "Falta healthcheck/secret: $name" }
        if (@($service.volumes | Where-Object { $_.type -eq 'volume' -and $_.source -eq $volumes[$name] }).Count -ne 1) {
            throw "Falta volumen persistente: $name"
        }
        if (-not $service.networks.ContainsKey('medical-network')) { throw "Falta red: $name" }
        foreach ($key in $service.environment.Keys) {
            if ($key -match '(PASSWORD|TOKEN|SECRET)$') { throw "Secret en environment: $name/$key" }
        }
    }
}

function Get-PostgresSnapshot {
    param([Parameter(Mandatory)]$Context, [hashtable]$Configuration)
    $ids = @(Invoke-ProjectCompose -Context $Context -Command @('ps', '--all', '--quiet', 'postgres'))
    if ($ids.Count -ne 1 -or -not $ids[0]) { throw 'Se requiere exactamente un contenedor PostgreSQL.' }
    $raw = & docker inspect --format '{{json .}}' $ids[0]
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo inspeccionar PostgreSQL.' }
    $container = ($raw -join "`n") | ConvertFrom-Json -AsHashtable
    if ($container.Config.Labels['com.docker.compose.project'] -ne $Configuration.name) { throw 'Proyecto distinto al seleccionado.' }
    $expected = @()
    if ($Configuration.services.postgres.ContainsKey('ports')) {
        $expected = @($Configuration.services.postgres.ports | ForEach-Object { "$($_.target)/$($_.protocol)|$($_.host_ip)|$($_.published)" })
    }
    $actual = @()
    if ($container.HostConfig.PortBindings) {
        foreach ($entry in $container.HostConfig.PortBindings.GetEnumerator()) {
            foreach ($binding in $entry.Value) { $actual += "$($entry.Key)|$($binding.HostIp)|$($binding.HostPort)" }
        }
    }
    if ((($expected | Sort-Object) -join ';') -ne (($actual | Sort-Object) -join ';')) {
        throw 'Puertos reales distintos a la selección Compose. Indique los mismos archivos/entorno/proyecto del arranque.'
    }
    $mount = @($container.Mounts | Where-Object { $_.Destination -eq '/var/lib/postgresql/data' })
    if ($mount.Count -ne 1 -or $mount[0].Type -ne 'volume' -or
        $mount[0].Name -ne $Configuration.volumes.postgres_data.name) { throw 'Volumen PostgreSQL distinto al seleccionado.' }
    [pscustomobject]@{
        Id = $container.Id
        Ports = ($actual | Sort-Object) -join ';'
        Volume = $mount[0].Name
    }
}
