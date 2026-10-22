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
    $expectedNames = if ($NoPublishedPorts -or -not $Configuration.services.ContainsKey('port-gateway')) {
        'mongodb,postgres,sqlserver'
    } else { 'mongodb,port-gateway,postgres,sqlserver' }
    if (($names -join ',') -ne $expectedNames) { throw 'Se esperan tres motores y, solo en localhost, un gateway.' }
    if (-not $Configuration.networks['medical-network'].internal) { throw 'Red no interna.' }
    if ($NoPublishedPorts -and $Configuration.services.ContainsKey('port-gateway')) { throw 'Gateway inesperado en base.' }
    $volumes = @{ postgres = 'postgres_data'; sqlserver = 'sqlserver_data'; mongodb = 'mongodb_data' }
    foreach ($name in $volumes.Keys) {
        $service = $Configuration.services[$name]
        if ($service.ContainsKey('ports') -and @($service.ports).Count) { throw "Motor con puerto publicado directamente: $name" }
        if (-not $service.healthcheck.test -or -not $service.secrets) { throw "Falta healthcheck/secret: $name" }
        if (@($service.volumes | Where-Object { $_.type -eq 'volume' -and $_.source -eq $volumes[$name] }).Count -ne 1) {
            throw "Falta volumen persistente: $name"
        }
        if (-not $service.networks.ContainsKey('medical-network')) { throw "Falta red: $name" }
        foreach ($key in $service.environment.Keys) {
            if ($key -match '(PASSWORD|TOKEN|SECRET)$') { throw "Secret en environment: $name/$key" }
        }
    }
    if ($Configuration.services.ContainsKey('port-gateway')) {
        $gateway = $Configuration.services['port-gateway']
        if (-not $Configuration.networks.ContainsKey('host-access') -or
            ($Configuration.networks['host-access'].ContainsKey('internal') -and $Configuration.networks['host-access'].internal)) { throw 'Falta red de acceso al host.' }
        if (-not $gateway.networks.ContainsKey('medical-network') -or -not $gateway.networks.ContainsKey('host-access')) { throw 'Gateway fuera de sus dos redes.' }
        if (-not $gateway.read_only -or -not $gateway.healthcheck.test -or
            $gateway.ContainsKey('secrets') -or $gateway.ContainsKey('environment')) { throw 'Gateway sin aislamiento mínimo.' }
        $expectedPorts = @('1433/tcp','27017/tcp','5432/tcp')
        $actualPorts = @($gateway.ports | ForEach-Object { "$($_.target)/$($_.protocol)" } | Sort-Object)
        if (($actualPorts -join ',') -ne ($expectedPorts -join ',')) { throw 'Puertos gateway inesperados.' }
        foreach ($port in $gateway.ports) {
            if ($port.host_ip -ne '127.0.0.1' -or -not $port.published) { throw 'Gateway fuera de localhost.' }
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
    $projectGateways = @(& docker ps --all --quiet --filter "label=com.docker.compose.project=$($Configuration.name)" --filter 'label=com.docker.compose.service=port-gateway')
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo verificar el gateway del proyecto.' }
    if (-not $Configuration.services.ContainsKey('port-gateway') -and $projectGateways.Count) {
        throw 'El despliegue conserva un gateway de localhost, pero la selección Compose omitió el overlay.'
    }
    if ($container.HostConfig.PortBindings -and @($container.HostConfig.PortBindings.Keys).Count) {
        throw 'PostgreSQL publicó un puerto fuera del gateway.'
    }
    $ports = @()
    $gatewayId = ''
    if ($Configuration.services.ContainsKey('port-gateway')) {
        $gatewayIds = @(Invoke-ProjectCompose -Context $Context -Command @('ps', '--all', '--quiet', 'port-gateway'))
        if ($gatewayIds.Count -ne 1 -or -not $gatewayIds[0]) { throw 'Se requiere un gateway de puertos.' }
        $gatewayRaw = & docker inspect --format '{{json .}}' $gatewayIds[0]
        if ($LASTEXITCODE -ne 0) { throw 'No se pudo inspeccionar el gateway.' }
        $gateway = ($gatewayRaw -join "`n") | ConvertFrom-Json -AsHashtable
        if ($gateway.Config.Labels['com.docker.compose.project'] -ne $Configuration.name -or
            -not $gateway.State.Running -or $gateway.State.Health.Status -ne 'healthy') { throw 'Gateway incorrecto o no saludable.' }
        $expected = @($Configuration.services['port-gateway'].ports | ForEach-Object { "$($_.target)/$($_.protocol)|$($_.host_ip)|$($_.published)" } | Sort-Object)
        foreach ($entry in $gateway.NetworkSettings.Ports.GetEnumerator()) {
            foreach ($binding in $entry.Value) { $ports += "$($entry.Key)|$($binding.HostIp)|$($binding.HostPort)" }
        }
        if (($expected -join ';') -ne (($ports | Sort-Object) -join ';')) {
            throw 'Puertos del gateway no publicados realmente. Revise NetworkSettings.Ports, no solo HostConfig.'
        }
        $gatewayId = $gateway.Id
    }
    $mount = @($container.Mounts | Where-Object { $_.Destination -eq '/var/lib/postgresql/data' })
    if ($mount.Count -ne 1 -or $mount[0].Type -ne 'volume' -or
        $mount[0].Name -ne $Configuration.volumes.postgres_data.name) { throw 'Volumen PostgreSQL distinto al seleccionado.' }
    [pscustomobject]@{
        Id = $container.Id
        GatewayId = $gatewayId
        Ports = ($ports | Sort-Object) -join ';'
        Volume = $mount[0].Name
    }
}

function Assert-LocalhostPortConnections {
    param([hashtable]$Configuration)
    if (-not $Configuration.services.ContainsKey('port-gateway')) { return }
    foreach ($port in $Configuration.services['port-gateway'].ports) {
        $client = [Net.Sockets.TcpClient]::new()
        try {
            $task = $client.ConnectAsync('127.0.0.1', [int]$port.published)
            if (-not $task.Wait(5000)) { throw "Timeout localhost:$($port.published)" }
            $null = $task.GetAwaiter().GetResult()
        } finally { $client.Dispose() }
    }
}
