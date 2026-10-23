#requires -Version 7.0
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$tempParent = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
$tempRoot = Join-Path $tempParent ('joseph-secrets-test-' + [guid]::NewGuid().ToString('N'))
$null = New-Item -ItemType Directory -Path $tempRoot
try {
    Copy-Item -LiteralPath (Join-Path $root '.env.example') -Destination (Join-Path $tempRoot '.env.example')
    [IO.File]::WriteAllText((Join-Path $tempRoot '.env'), '# configuración preexistente de prueba')
    $secretDir = Join-Path $tempRoot 'secrets'
    $null = New-Item -ItemType Directory -Path $secretDir
    $existing = @{}
    foreach ($name in 'postgres_password.txt','sqlserver_sa_password.txt','extra-preexistente.txt') {
        $path = Join-Path $secretDir $name
        $value = [guid]::NewGuid().ToString('N') + [guid]::NewGuid().ToString('N')
        [IO.File]::WriteAllText($path, $value)
        $existing[$name] = $value
    }
    if ($IsWindows) {
        # Repro H1: Allow explícitos de Everyone y Users en carpeta y archivos.
        foreach ($item in @(Get-Item -LiteralPath $secretDir) + @(Get-ChildItem -LiteralPath $secretDir)) {
            $acl = Get-Acl -LiteralPath $item.FullName
            $inheritance = if ($item.PSIsContainer) { [Security.AccessControl.InheritanceFlags]'ContainerInherit,ObjectInherit' }
                           else { [Security.AccessControl.InheritanceFlags]::None }
            foreach ($sid in 'S-1-1-0','S-1-5-32-545') {
                $acl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new(
                    [Security.Principal.SecurityIdentifier]::new($sid),
                    [Security.AccessControl.FileSystemRights]::Read, $inheritance,
                    [Security.AccessControl.PropagationFlags]::None,
                    [Security.AccessControl.AccessControlType]::Allow))
            }
            Set-Acl -LiteralPath $item.FullName -AclObject $acl
            $rules = (Get-Acl -LiteralPath $item.FullName).GetAccessRules($true,$true,[Security.Principal.SecurityIdentifier])
            if (@($rules | Where-Object { $_.IdentityReference.Value -eq 'S-1-1-0' -and -not $_.IsInherited }).Count -eq 0) {
                throw 'El fixture no reprodujo el permiso explícito de Everyone.'
            }
        }
        Write-Output 'PRECONDICIÓN H1: Everyone y Users con lectura explícita en carpeta y archivos existentes.'
    } else {
        & chmod 777 $secretDir
        foreach ($path in Get-ChildItem -LiteralPath $secretDir) { & chmod 666 $path.FullName }
        if ($LASTEXITCODE -ne 0) { throw 'No se prepararon permisos del fixture Linux.' }
    }
    1..2 | ForEach-Object { & (Join-Path $root 'scripts/Initialize-Local.ps1') -ProjectDirectory $tempRoot }
    foreach ($name in $existing.Keys) {
        if ([IO.File]::ReadAllText((Join-Path $secretDir $name)) -cne $existing[$name]) { throw 'Se modificó un valor preexistente.' }
    }
    if ([IO.File]::ReadAllText((Join-Path $tempRoot '.env')) -cne '# configuración preexistente de prueba') { throw 'Se modificó .env existente.' }
    if (-not (Test-Path -LiteralPath (Join-Path $secretDir 'mongo_root_password.txt'))) { throw 'No se generó el secreto faltante.' }
    if ($IsWindows) {
        $userSid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
        $allowed = @($userSid,'S-1-5-18' | Select-Object -Unique)
        foreach ($item in @(Get-Item -LiteralPath $secretDir) + @(Get-ChildItem -LiteralPath $secretDir)) {
            $acl = Get-Acl -LiteralPath $item.FullName
            $rules = @($acl.GetAccessRules($true,$true,[Security.Principal.SecurityIdentifier]))
            if (-not $acl.AreAccessRulesProtected -or $rules.Count -ne $allowed.Count -or
                $acl.GetOwner([Security.Principal.SecurityIdentifier]).Value -ne $userSid) { throw 'DACL/propietario inesperados.' }
            foreach ($rule in $rules) {
                if ($rule.IdentityReference.Value -notin $allowed -or $rule.IsInherited -or
                    $rule.AccessControlType -ne 'Allow' -or $rule.FileSystemRights -ne 'FullControl') { throw 'Permiso de tercero conservado.' }
            }
        }
        Write-Output 'PASS H1 Windows: DACL cerrada y protegida en carpeta y cuatro archivos; propietario actual; solo usuario/SYSTEM.'
        Write-Output 'Límite: inspección de DACL; no se inició sesión ni se impersonó a otra cuenta.'
    } else {
        if ((& stat -c '%a' $secretDir) -ne '700') { throw 'Directorio Linux no tiene modo 700.' }
        foreach ($path in Get-ChildItem -LiteralPath $secretDir) {
            if ((& stat -c '%a' $path.FullName) -ne '644') { throw 'Archivo Linux no tiene modo 644.' }
        }
        Write-Output 'PASS Linux: directorio 700 y archivos 644, compatibles con el UID de SQL Server en el bind mount.'
    }
    Write-Output 'PASS idempotencia: valores existentes y .env conservados; valores no impresos.'
} finally {
    $resolved = (Resolve-Path -LiteralPath $tempRoot).ProviderPath
    if ([IO.Path]::GetFullPath($resolved) -ne [IO.Path]::GetFullPath($tempRoot) -or
        [IO.Path]::GetDirectoryName($resolved) -ne $tempParent.TrimEnd([IO.Path]::DirectorySeparatorChar) -or
        [IO.Path]::GetFileName($resolved) -notmatch '^joseph-secrets-test-[0-9a-f]{32}$') { throw 'Ruta temporal no segura para limpiar.' }
    Remove-Item -LiteralPath $resolved -Recurse -Force
}
