#requires -Version 7.0
[CmdletBinding()]
param(
    [string[]]$ComposeFile = @(), [string[]]$EnvFile = @(), [string]$ProjectName,
    [string]$ProjectDirectory = (Split-Path -Parent $PSScriptRoot),
    [Parameter(Mandatory)][string[]]$Command
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Compose-Context.ps1')
$context = New-ComposeContext -ComposeFile $ComposeFile -EnvFile $EnvFile -ProjectName $ProjectName -ProjectDirectory $ProjectDirectory
Invoke-ProjectCompose -Context $context -Command $Command
