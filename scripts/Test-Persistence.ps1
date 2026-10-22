#requires -Version 7.0
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Push-Location (Split-Path -Parent $PSScriptRoot)
try {
    # Identificador generado, sin datos clínicos; solo en la base administrativa postgres.
    $table = 'joseph_probe_' + [guid]::NewGuid().ToString('N')
    & docker compose exec -T --user postgres postgres psql -X -U postgres -d postgres -v ON_ERROR_STOP=1 -c "CREATE TABLE public.$table (id integer PRIMARY KEY); INSERT INTO public.$table VALUES (1);"
    if ($LASTEXITCODE -ne 0) { throw 'No se creó el marcador de persistencia.' }
    & docker compose restart postgres
    if ($LASTEXITCODE -ne 0) { throw 'Falló restart PostgreSQL.' }
    & docker compose up -d --wait --wait-timeout 120 postgres
    if ($LASTEXITCODE -ne 0) { throw 'PostgreSQL no volvió a estar saludable.' }
    $result = & docker compose exec -T --user postgres postgres psql -X -U postgres -d postgres -v ON_ERROR_STOP=1 -tAc "SELECT count(*) FROM public.$table WHERE id=1"
    if ($LASTEXITCODE -ne 0 -or ($result -join '').Trim() -ne '1') { throw "Marcador no persistió: $table" }
    & docker compose exec -T --user postgres postgres psql -X -U postgres -d postgres -v ON_ERROR_STOP=1 -c "DROP TABLE public.$table"
    if ($LASTEXITCODE -ne 0) { throw "No se limpió marcador: $table" }
    Write-Output 'PASS P12 parcial: PostgreSQL conservó una fila tras reinicio; marcador eliminado.'
} finally { Pop-Location }