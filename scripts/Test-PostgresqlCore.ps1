#requires -Version 7.0
[CmdletBinding()]
param(
    [string[]]$ComposeFile = @(), [string[]]$EnvFile = @(), [string]$ProjectName,
    [string]$ProjectDirectory = (Split-Path -Parent $PSScriptRoot),
    [ValidateRange(1,3)][int]$Repeat = 1,
    [switch]$IncludePersistence,
    [ValidateRange(1,600)][int]$TimeoutSeconds = 120
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Compose-Context.ps1')

$context = New-ComposeContext -ComposeFile $ComposeFile -EnvFile $EnvFile `
    -ProjectName $ProjectName -ProjectDirectory $ProjectDirectory
$config = Get-ComposeConfiguration $context
Assert-InfraConfiguration -Configuration $config
$initial = Get-PostgresSnapshot -Context $context -Configuration $config
Write-Output "Inicio núcleo PG: proyecto=$($config.name); volumen=$($initial.Volume); repeticiones=$Repeat."

# docker compose cp usa exactamente el contexto de proyecto/archivos/entorno operativo.
# Los archivos copiados viven solo en el filesystem del contenedor, no en el volumen PG.
Invoke-ProjectCompose $context @('exec','-T','--user','postgres','postgres','mkdir','-p',
    '/tmp/joseph-core-sql','/tmp/joseph-core-tests')
Invoke-ProjectCompose $context @('cp','postgresql/.','postgres:/tmp/joseph-core-sql')
Invoke-ProjectCompose $context @('cp','pruebas/postgresql/.','postgres:/tmp/joseph-core-tests')

for ($iteration = 1; $iteration -le $Repeat; $iteration++) {
    $database = 'joseph_core_' + [guid]::NewGuid().ToString('N')
    $created = $false
    try {
        Invoke-ProjectCompose $context @('exec','-T','--user','postgres','postgres',
            'createdb','-U','postgres','-T','template0',$database)
        $created = $true
        foreach ($file in @('01_esquemas.sql','02_tablas.sql','03_particiones.sql','06_datos_prueba.sql')) {
            Invoke-ProjectCompose $context @('exec','-T','--user','postgres','postgres',
                'psql','-X','-U','postgres','-d',$database,'-v','ON_ERROR_STOP=1',
                '-f',"/tmp/joseph-core-sql/$file")
        }
        foreach ($file in @('01_estructura.sql','02_integridad.sql',
                            '03_particiones.sql','04_transacciones.sql')) {
            Invoke-ProjectCompose $context @('exec','-T','--user','postgres','postgres',
                'psql','-X','-U','postgres','-d',$database,'-v','ON_ERROR_STOP=1',
                '-f',"/tmp/joseph-core-tests/$file")
        }
        Write-Output "PASS creación y pruebas clínicas: base vacía #$iteration; $database."

        if ($IncludePersistence) {
            $before = Get-PostgresSnapshot -Context $context -Configuration $config
            Invoke-ProjectCompose $context @('restart','postgres')
            $timer = [Diagnostics.Stopwatch]::StartNew()
            do {
                $raw = & docker inspect --format '{{json .State}}' $before.Id
                if ($LASTEXITCODE -ne 0) { throw 'No se pudo inspeccionar PostgreSQL tras restart.' }
                $state = ($raw -join "`n") | ConvertFrom-Json -AsHashtable
                if ($state.Running -and $state.Health.Status -eq 'healthy') { break }
                if ($timer.Elapsed.TotalSeconds -ge $TimeoutSeconds) { throw 'Timeout recuperación PG.' }
                Start-Sleep -Seconds 1
            } while ($true)
            $after = Get-PostgresSnapshot -Context $context -Configuration $config
            if ($before.Id -ne $after.Id -or $before.Volume -ne $after.Volume -or
                $before.GatewayId -ne $after.GatewayId -or $before.Ports -ne $after.Ports) {
                throw 'Restart cambió contenedor, volumen, gateway o puertos.'
            }
            Invoke-ProjectCompose $context @('exec','-T','--user','postgres','postgres',
                'psql','-X','-U','postgres','-d',$database,'-v','ON_ERROR_STOP=1',
                '-f','/tmp/joseph-core-tests/05_persistencia.sql')
            Write-Output "PASS persistencia clínica parcial: base #$iteration tras restart; mismo contenedor/volumen."
        }
        Invoke-ProjectCompose $context @('exec','-T','--user','postgres','postgres',
            'dropdb','-U','postgres',$database)
        $created = $false
        Write-Output "PASS limpieza explícita: base sintética #$iteration eliminada; volumen intacto."
    } catch {
        $detail = if ($created) { "Base de prueba conservada para diagnóstico: $database." }
                  else { "La creación de $database no se confirmó." }
        throw "FAIL núcleo PostgreSQL #${iteration}: $($_.Exception.Message) $detail No borrar volúmenes."
    }
}
Write-Output 'PASS reproducibilidad del núcleo en bases vacías; FDW remoto/MongoDB NO PROBADOS.'
