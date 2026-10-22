#requires -Version 7.0
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$secretDir = Join-Path $root 'secrets'
$null = New-Item -ItemType Directory -Force -Path $secretDir
if ($IsWindows) {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent().Name
    & icacls $secretDir /inheritance:r /grant:r "${identity}:(OI)(CI)F" '*S-1-5-18:(OI)(CI)F' | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo restringir la carpeta secrets.' }
} else {
    & chmod 700 $secretDir
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo restringir la carpeta secrets.' }
}
foreach ($name in 'postgres_password', 'sqlserver_sa_password', 'mongo_root_password') {
    $path = Join-Path $secretDir "$name.txt"
    if (-not (Test-Path -LiteralPath $path)) {
        $bytes = [byte[]]::new(32)
        [Security.Cryptography.RandomNumberGenerator]::Fill($bytes)
        # Cumple categorías de complejidad SQL Server sin caracteres problemáticos para shells.
        $value = 'Aa1!' + [Convert]::ToHexString($bytes)
        [IO.File]::WriteAllText($path, $value, [Text.UTF8Encoding]::new($false))
    }
    if (-not $IsWindows) {
        & chmod 644 $path
        if ($LASTEXITCODE -ne 0) { throw "No se pudo restringir $name." }
    }
}
$envPath = Join-Path $root '.env'
if (-not (Test-Path -LiteralPath $envPath)) {
    Copy-Item -LiteralPath (Join-Path $root '.env.example') -Destination $envPath
}
Write-Output 'Configuración local preparada. No se sobrescribieron archivos existentes ni se mostraron secretos.'