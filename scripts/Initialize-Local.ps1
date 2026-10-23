#requires -Version 7.0
[CmdletBinding()]
param([string]$ProjectDirectory = (Split-Path -Parent $PSScriptRoot))
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $ProjectDirectory).ProviderPath
$secretDir = Join-Path $root 'secrets'
if (Test-Path -LiteralPath $secretDir) {
    $item = Get-Item -LiteralPath $secretDir -Force
    if (-not $item.PSIsContainer -or $item.Attributes.HasFlag([IO.FileAttributes]::ReparsePoint)) {
        throw 'secrets debe ser una carpeta normal, sin enlaces.'
    }
}
$null = New-Item -ItemType Directory -Force -Path $secretDir

function Set-PrivateWindowsAcl {
    param([string]$Path, [switch]$Directory)
    $userSid = [Security.Principal.WindowsIdentity]::GetCurrent().User
    $systemSid = [Security.Principal.SecurityIdentifier]::new('S-1-5-18')
    # Reconstruir la DACL completa, sin modificar la SACL (no exige SeSecurityPrivilege).
    $acl = Get-Acl -LiteralPath $Path
    $acl.SetOwner($userSid)
    $acl.SetAccessRuleProtection($true, $false)
    foreach ($rule in @($acl.GetAccessRules($true, $false, [Security.Principal.SecurityIdentifier]))) {
        $acl.RemoveAccessRuleSpecific($rule)
    }
    $inheritance = if ($Directory) { [Security.AccessControl.InheritanceFlags]'ContainerInherit,ObjectInherit' }
                   else { [Security.AccessControl.InheritanceFlags]::None }
    $allowedSids = @($userSid.Value, $systemSid.Value | Select-Object -Unique)
    foreach ($sid in $allowedSids) {
        $rule = [Security.AccessControl.FileSystemAccessRule]::new(
            [Security.Principal.SecurityIdentifier]::new($sid),
            [Security.AccessControl.FileSystemRights]::FullControl,
            $inheritance, [Security.AccessControl.PropagationFlags]::None,
            [Security.AccessControl.AccessControlType]::Allow)
        $acl.AddAccessRule($rule)
    }
    # Persistir solo secciones modificadas; Set-Acl puede intentar escribir también la SACL.
    if ($Directory) { [IO.FileSystemAclExtensions]::SetAccessControl([IO.DirectoryInfo]::new($Path), $acl) }
    else { [IO.FileSystemAclExtensions]::SetAccessControl([IO.FileInfo]::new($Path), $acl) }
    $actual = Get-Acl -LiteralPath $Path
    $rules = @($actual.GetAccessRules($true, $true, [Security.Principal.SecurityIdentifier]))
    if (-not $actual.AreAccessRulesProtected -or
        $actual.GetOwner([Security.Principal.SecurityIdentifier]).Value -ne $userSid.Value -or
        $rules.Count -ne $allowedSids.Count) { throw "DACL no cerrada: $Path" }
    foreach ($rule in $rules) {
        if ($rule.IdentityReference.Value -notin $allowedSids -or $rule.IsInherited -or
            $rule.AccessControlType -ne 'Allow' -or $rule.FileSystemRights -ne 'FullControl' -or
            $rule.InheritanceFlags -ne $inheritance -or $rule.PropagationFlags -ne 'None') {
            throw "Permiso inesperado en $Path"
        }
    }
}

if ($IsWindows) {
    Set-PrivateWindowsAcl -Path $secretDir -Directory
} else {
    & chmod 700 $secretDir
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo restringir la carpeta secrets.' }
}
# Reparar también archivos preexistentes, antes de leer o generar valores.
$existing = @(Get-ChildItem -LiteralPath $secretDir -Force)
foreach ($item in $existing) {
    if ($item.PSIsContainer -or $item.Attributes.HasFlag([IO.FileAttributes]::ReparsePoint)) {
        throw 'secrets solo admite archivos normales en esta fase; no se siguen enlaces ni subcarpetas.'
    }
    if ($IsWindows) { Set-PrivateWindowsAcl -Path $item.FullName }
    else {
        & chmod 644 $item.FullName
        if ($LASTEXITCODE -ne 0) { throw 'No se pudo restringir un archivo existente.' }
    }
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
    if ($IsWindows) { Set-PrivateWindowsAcl -Path $path }
    else {
        & chmod 644 $path
        if ($LASTEXITCODE -ne 0) { throw "No se pudo restringir $name." }
    }
}
$envPath = Join-Path $root '.env'
if (-not (Test-Path -LiteralPath $envPath)) {
    Copy-Item -LiteralPath (Join-Path $root '.env.example') -Destination $envPath
}
Write-Output 'PASS inicialización: permisos aplicados; valores existentes conservados; secretos no mostrados.'
