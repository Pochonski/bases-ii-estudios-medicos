#requires -Version 7.0
# Prueba disruptiva de disponibilidad: suspende procesos PG en un proyecto efímero de CI.
# No escribe datos ni elimina contenedores, redes o volúmenes; siempre intenta reanudar PG.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'scripts/Compose-Context.ps1')

$context = New-ComposeContext
$config = Get-ComposeConfiguration $context
if ($env:GITHUB_ACTIONS -ne 'true' -or $config.name -ne 'joseph-audit-localhost') {
    throw 'Esta prueba de pausa solo se permite en el proyecto efímero joseph-audit-localhost de CI.'
}
if (-not $config.services.ContainsKey('port-gateway')) { throw 'Se requiere overlay localhost.' }

$before = Get-PostgresSnapshot -Context $context -Configuration $config
$pauseAttempted = $false
try {
    $pauseAttempted = $true
    Invoke-ProjectCompose $context @('pause','postgres')
    $timer = [Diagnostics.Stopwatch]::StartNew()
    do {
        $health = & docker inspect --format '{{.State.Health.Status}}' $before.GatewayId
        if ($LASTEXITCODE -ne 0) { throw 'No se pudo inspeccionar el gateway.' }
        if (($health -join '').Trim() -eq 'unhealthy') { break }
        if ($timer.Elapsed.TotalSeconds -ge 60) { throw 'El gateway no detectó el backend PostgreSQL suspendido.' }
        Start-Sleep -Seconds 1
    } while ($true)

    # La mera conexión TCP a los frontends sigue siendo posible; la salud debe fallar.
    Assert-LocalhostPortConnections -Configuration $config
    $detected = $false
    try { $null = Get-PostgresSnapshot -Context $context -Configuration $config }
    catch {
        if ($_.Exception.Message -ne 'Gateway incorrecto o no saludable.') { throw }
        $detected = $true
    }
    if (-not $detected) { throw 'La validación runtime aceptó un gateway con backend caído.' }
    Write-Output 'PASS negativo: TCP localhost acepta conexiones, pero la salud del gateway y la validación runtime rechazan PostgreSQL suspendido.'
} finally {
    if ($pauseAttempted) {
        $state = & docker inspect --format '{{.State.Status}}' $before.Id
        if ($LASTEXITCODE -ne 0) { throw 'No se pudo inspeccionar PostgreSQL para reanudarlo.' }
        if (($state -join '').Trim() -eq 'paused') { Invoke-ProjectCompose $context @('unpause','postgres') }
    }
}

$timer = [Diagnostics.Stopwatch]::StartNew()
do {
    $pgHealth = & docker inspect --format '{{.State.Health.Status}}' $before.Id
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo inspeccionar PostgreSQL tras reanudar.' }
    $gatewayHealth = & docker inspect --format '{{.State.Health.Status}}' $before.GatewayId
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo inspeccionar el gateway tras reanudar.' }
    if (($pgHealth -join '').Trim() -eq 'healthy' -and ($gatewayHealth -join '').Trim() -eq 'healthy') { break }
    if ($timer.Elapsed.TotalSeconds -ge 90) { throw 'PostgreSQL/gateway no recuperó salud tras unpause.' }
    Start-Sleep -Seconds 1
} while ($true)

$after = Get-PostgresSnapshot -Context $context -Configuration $config
Assert-LocalhostPortConnections -Configuration $config
if ($before.Id -ne $after.Id -or $before.GatewayId -ne $after.GatewayId -or
    $before.Ports -ne $after.Ports -or $before.Volume -ne $after.Volume) {
    throw 'La pausa/reanudación cambió contenedor, gateway, puertos o volumen PostgreSQL.'
}
Write-Output 'PASS recuperación: mismos contenedores, volumen y bindings localhost; tres motores/gateway disponibles antes de P12.'
