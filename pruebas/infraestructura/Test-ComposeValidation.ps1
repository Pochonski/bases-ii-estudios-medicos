#requires -Version 7.0
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$testScript = Join-Path $root 'scripts/Test-Infra.ps1'
$tempParent = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
$tempRoot = Join-Path $tempParent ('joseph-compose-test-' + [guid]::NewGuid().ToString('N'))
$null = New-Item -ItemType Directory -Path $tempRoot
# Aislar selección/interpolación del shell y restaurarla al finalizar.
$keys = @('COMPOSE_FILE','COMPOSE_ENV_FILES','COMPOSE_PROJECT_NAME','COMPOSE_PATH_SEPARATOR','COMPOSE_DISABLE_ENV_FILE',
          'POSTGRES_DB','MONGO_ROOT_USERNAME','ACCEPT_EULA','POSTGRES_PORT','SQLSERVER_PORT','MONGODB_PORT')
$saved = @{}
foreach ($key in $keys) {
    $saved[$key] = [Environment]::GetEnvironmentVariable($key)
    Remove-Item -LiteralPath "Env:$key" -ErrorAction SilentlyContinue
}
$userEnv = Join-Path $root '.env'
$before = if (Test-Path -LiteralPath $userEnv) { (Get-FileHash -LiteralPath $userEnv).Hash } else { $null }
try {
    foreach ($file in 'compose.yaml','compose.local.yaml','.env.example') {
        Copy-Item -LiteralPath (Join-Path $root $file) -Destination (Join-Path $tempRoot $file)
    }
    $valid = [IO.File]::ReadAllText((Join-Path $tempRoot '.env.example')).Replace('POSTGRES_DB=estudios_medicos','POSTGRES_DB=auditoria_operativa').Replace('POSTGRES_PORT=5432','POSTGRES_PORT=15432')
    [IO.File]::WriteAllText((Join-Path $tempRoot '.env'), $valid)
    & $testScript -StaticOnly -ProjectDirectory $tempRoot -ComposeFile @('compose.yaml') -EnvFile @('.env') -ProjectName auditoria-base
    & $testScript -StaticOnly -ProjectDirectory $tempRoot -ComposeFile @('compose.yaml','compose.local.yaml') -EnvFile @('.env') -ProjectName auditoria-local
    Write-Output 'PASS H2 estático: base y overlay aceptados con selección explícita de archivos/entorno/proyecto.'
    $env:COMPOSE_FILE = @('compose.yaml','compose.local.yaml') -join [IO.Path]::PathSeparator
    $env:COMPOSE_ENV_FILES = '.env'
    $env:COMPOSE_PROJECT_NAME = 'auditoria-ambiental'
    & $testScript -StaticOnly -ProjectDirectory $tempRoot
    Write-Output 'PASS H2 ambiental: COMPOSE_FILE, COMPOSE_ENV_FILES y COMPOSE_PROJECT_NAME respetados.'
    foreach ($key in 'COMPOSE_FILE','COMPOSE_ENV_FILES','COMPOSE_PROJECT_NAME') { Remove-Item -LiteralPath "Env:$key" -ErrorAction SilentlyContinue }
    # Repro H3: .env realmente usado inválido, ejemplo todavía válido; solo en carpeta temporal.
    [IO.File]::WriteAllText((Join-Path $tempRoot '.env'), $valid.Replace('POSTGRES_DB=auditoria_operativa','POSTGRES_DB='))
    $rejected = $false
    try { & $testScript -StaticOnly -ProjectDirectory $tempRoot -ProjectName auditoria-invalida }
    catch {
        if ($_.Exception.Message -notlike 'FAIL entorno operativo:*') { throw }
        $rejected = $true
        # La salida 1 era el resultado esperado del caso negativo; GitHub pwsh la hereda.
        $global:LASTEXITCODE = 0
        Write-Output 'PASS H3 negativo: ejemplo válido, FAIL entorno operativo por POSTGRES_DB vacío; .env temporal.'
    }
    if (-not $rejected) { throw 'H3: se aceptó un .env operativo inválido.' }
    $after = if (Test-Path -LiteralPath $userEnv) { (Get-FileHash -LiteralPath $userEnv).Hash } else { $null }
    if ($before -cne $after) { throw 'Se alteró .env del usuario.' }
    Write-Output 'PASS aislamiento: .env real del usuario intacto; sin necesidad de daemon.'
    Write-Output 'NO EJECUTADO por esta suite: restart, conservación real de puertos y datos; corresponden a Test-Persistence.'
} finally {
    foreach ($key in $keys) {
        if ($null -eq $saved[$key]) { Remove-Item -LiteralPath "Env:$key" -ErrorAction SilentlyContinue }
        else { Set-Item -LiteralPath "Env:$key" -Value $saved[$key] }
    }
    $resolved = (Resolve-Path -LiteralPath $tempRoot).ProviderPath
    if ([IO.Path]::GetFullPath($resolved) -ne [IO.Path]::GetFullPath($tempRoot) -or
        [IO.Path]::GetDirectoryName($resolved) -ne $tempParent.TrimEnd([IO.Path]::DirectorySeparatorChar) -or
        [IO.Path]::GetFileName($resolved) -notmatch '^joseph-compose-test-[0-9a-f]{32}$') { throw 'Ruta temporal no segura para limpiar.' }
    Remove-Item -LiteralPath $resolved -Recurse -Force
}
