#requires -Version 7.0
[CmdletBinding()]
param(
    [string[]]$ComposeFile = @(), [string[]]$EnvFile = @(), [string]$ProjectName,
    [string]$ProjectDirectory = (Split-Path -Parent $PSScriptRoot),
    [ValidateRange(1,600)][int]$TimeoutSeconds = 120
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Compose-Context.ps1')
$table = 'joseph_probe_' + [guid]::NewGuid().ToString('N')
$context = New-ComposeContext -ComposeFile $ComposeFile -EnvFile $EnvFile -ProjectName $ProjectName -ProjectDirectory $ProjectDirectory
try {
    $config = Get-ComposeConfiguration $context
    $before = Get-PostgresSnapshot -Context $context -Configuration $config
    Invoke-ProjectCompose $context @('exec','-T','--user','postgres','postgres','psql','-X','-U','postgres','-d','postgres','-v','ON_ERROR_STOP=1','-c',"CREATE TABLE public.$table (id integer PRIMARY KEY); INSERT INTO public.$table VALUES (1);")
    Write-Output "Marcador sintético PostgreSQL: public.$table; proyecto=$($config.name)."
    Invoke-ProjectCompose $context @('restart','postgres')
    # Solo esperar el mismo contenedor. No up/recreate/reconciliación de configuración.
    $timer = [Diagnostics.Stopwatch]::StartNew()
    do {
        $raw = & docker inspect --format '{{json .State}}' $before.Id
        if ($LASTEXITCODE -ne 0) { throw 'No se pudo consultar la recuperación del contenedor original.' }
        $state = ($raw -join "`n") | ConvertFrom-Json -AsHashtable
        if ($state.Running -and $state.Health.Status -eq 'healthy') { break }
        if ($timer.Elapsed.TotalSeconds -ge $TimeoutSeconds) { throw 'Tiempo de recuperación agotado.' }
        Start-Sleep -Seconds 1
    } while ($true)
    $after = Get-PostgresSnapshot -Context $context -Configuration $config
    if ($before.Id -ne $after.Id -or $before.Ports -ne $after.Ports -or $before.Volume -ne $after.Volume) {
        throw 'El contenedor, sus puertos o su volumen cambiaron durante restart.'
    }
    $result = Invoke-ProjectCompose $context @('exec','-T','--user','postgres','postgres','psql','-X','-U','postgres','-d','postgres','-v','ON_ERROR_STOP=1','-tAc',"SELECT count(*) FROM public.$table WHERE id=1")
    if (($result -join '').Trim() -ne '1') { throw 'La fila marcador no persistió.' }
    Invoke-ProjectCompose $context @('exec','-T','--user','postgres','postgres','psql','-X','-U','postgres','-d','postgres','-v','ON_ERROR_STOP=1','-c',"DROP TABLE public.$table")
    Write-Output "PASS P12 parcial PG: fila tras restart; mismo contenedor/volumen/puertos [$($after.Ports)]; marcador eliminado."
    Write-Output 'Alcance: solo PostgreSQL tras restart; no acredita recreación, otros motores ni restauración.'
} catch {
    throw "FAIL persistencia PG: $($_.Exception.Message) Marcador=public.$table en base postgres (puede no haberse creado). Limpieza con la misma selección Compose: exec -T --user postgres postgres psql -X -U postgres -d postgres -v ON_ERROR_STOP=1 -c 'DROP TABLE IF EXISTS public.$table'. No borrar volúmenes."
}
