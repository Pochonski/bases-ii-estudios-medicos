#requires -Version 7.0
# Joyce. Instala SQL Server, MongoDB y la integración PostgreSQL (FDW + outbox) sobre el
# entorno Compose de Joseph. Repetible: los scripts de Joyce son idempotentes; el núcleo
# PostgreSQL de Joseph y su FDW SQL Server se aplican solo si todavía no existen.
# Sin parámetros instala estructura sin recargar datos. -LoadInitialData carga fixtures
# únicamente en tablas vacías. -ResetLabData reiniticia SQL Server solo en P18 efímero.
[CmdletBinding()]
param([switch]$SkipUp, [switch]$LoadInitialData, [switch]$ResetLabData)
. (Join-Path $PSScriptRoot 'Joyce-Common.ps1')
if ($LoadInitialData -and $ResetLabData) { throw 'Elija carga inicial o reinicialización, no ambas.' }
if ($ResetLabData) { $null = Assert-JoyceEphemeralContext }

function Step([string]$m) { Write-Output "`n== $m" }

Step 'Secretos locales (no se muestran)'
Initialize-JoyceSecrets
$s = @{}
foreach ($n in $script:JoyceSecretNames) { $s[$n] = Get-JoyceSecret $n }

if (-not $SkipUp) {
    Step 'Levantar los tres motores (compose.yaml)'
    Invoke-JoyceCompose @('up', '-d', '--build')
}
Wait-JoyceHealthy

Step 'SQL Server: estructura y objetos 01..05 (sin datos)'
foreach ($f in '01_base_tablas', '02_fragmentacion', '03_procedimientos', '04_vistas') {
    Invoke-JoyceScript -Service sqlserver -Path "sqlserver/$f.sql"
}
Invoke-JoyceScript -Service sqlserver -Path 'sqlserver/05_roles.sql' `
    -Env ([ordered]@{ FDW_MSSQL_PASSWORD = $s.fdw_mssql_password })

$sqlRows = Invoke-JoyceScript -Service sqlserver -Text @'
SET NOCOUNT ON;
USE integracion_externa;
SELECT CAST(
 (SELECT COUNT(*) FROM dbo.aseguradoras) +
 (SELECT COUNT(*) FROM dbo.convenios) +
 (SELECT COUNT(*) FROM dbo.paciente_integracion) +
 (SELECT COUNT(*) FROM dbo.paciente_cobertura) +
 (SELECT COUNT(*) FROM dbo.facturas_externas) +
 (SELECT COUNT(*) FROM dbo.resumen_facturacion) AS varchar(20));
'@
$sqlCounts = @($sqlRows -split '\r?\n' | Where-Object { $_.Trim() -match '^\d+$' } | ForEach-Object { $_.Trim() })
if ($sqlCounts.Count -ne 1) { throw 'No se pudo obtener el conteo de tablas SQL Server; se cancela carga de datos.' }
if ($LoadInitialData -and $sqlCounts[0] -ne '0') {
    throw 'Carga inicial SQL Server denegada: existen filas. Instalación normal no las reemplaza.'
}

Step 'MongoDB: mongodb/01..03'
Invoke-JoyceScript -Service mongodb -Path 'mongodb/01_colecciones.js'
Invoke-JoyceScript -Service mongodb -Path 'mongodb/02_indices.js'
Invoke-JoyceScript -Service mongodb -Path 'mongodb/03_usuarios.js' `
    -Env ([ordered]@{ FDW_MONGO_PASSWORD = $s.fdw_mongo_password })

Step 'PostgreSQL: núcleo clínico de Joseph (solo si falta; datos por opción explícita)'
$hayNucleo = Invoke-JoyceScript -Service postgres -Text "\pset tuples_only on`nSELECT to_regclass('clinico.pacientes') IS NOT NULL;"
if ($hayNucleo.Trim() -ne 't') {
    foreach ($f in '01_esquemas', '02_tablas', '03_particiones') {
        Invoke-JoyceScript -Service postgres -Path "postgresql/$f.sql"
    }
} else { Write-Output 'clinico.pacientes ya existe; no se reaplica el núcleo.' }
if ($LoadInitialData) {
    $pgRows = Invoke-JoyceScript -Service postgres -Text "\pset tuples_only on`nSELECT count(*) FROM clinico.pacientes;"
    $pgCounts = @($pgRows -split '\r?\n' | Where-Object { $_.Trim() -match '^\d+$' } | ForEach-Object { $_.Trim() })
    if ($pgCounts.Count -ne 1 -or $pgCounts[0] -ne '0') { throw 'Carga inicial PostgreSQL denegada: hay pacientes o conteo no verificable.' }
    Invoke-JoyceScript -Service postgres -Path 'postgresql/06_datos_prueba.sql'
    Invoke-JoyceScript -Service sqlserver -Path 'sqlserver/06_datos_prueba.sql'
    Write-Output 'PASS carga inicial: fixtures ficticios instalados solo en tablas vacías.'
} elseif ($ResetLabData) {
    $resetSql = "EXEC sys.sp_set_session_context @key=N'joseph_fixture_reset', @value=N'EXPLICIT_LAB_RESET';`nGO`n" +
        [IO.File]::ReadAllText((Join-Path $script:JoyceRoot 'sqlserver/06_datos_prueba.sql'))
    Invoke-JoyceScript -Service sqlserver -Text $resetSql
    Write-Output 'PASS reinicialización deliberada del fixture SQL Server en proyecto efímero.'
} else {
    Write-Output 'PASS instalación normal: no se ejecutaron scripts de datos.'
}

Step 'PostgreSQL -> SQL Server: integracion/01 de Joseph (solo si falta)'
$hayFdw = Invoke-JoyceScript -Service postgres -Text "\pset tuples_only on`nSELECT to_regclass('externo.ft_estado_facturacion') IS NOT NULL;"
if ($hayFdw.Trim() -ne 't') {
    $text = "\set mssql_database integracion_externa`n" + [IO.File]::ReadAllText((Join-Path $script:JoyceRoot 'integracion/01_fdw_sqlserver.sql'))
    Invoke-JoyceScript -Service postgres -Text $text -Env ([ordered]@{ FDW_MSSQL_PASSWORD = $s.fdw_mssql_password })
} else { Write-Output 'externo.ft_estado_facturacion ya existe; no se recrea.' }
# Login propio del perfil (mismo script del spike de Joseph): habilita LOGIN y SELECT de pacientes.
Invoke-JoyceScript -Service postgres -Path 'pruebas/integracion/03_postgresql_role.sql' `
    -Env ([ordered]@{ PG_FDW_LOGIN_PASSWORD = $s.pg_fdw_mssql_login_password })

Step 'PostgreSQL -> MongoDB: integracion/02 y outbox'
Invoke-JoyceScript -Service postgres -Path 'integracion/02_fdw_mongodb.sql' -Env ([ordered]@{
    FDW_MONGO_PASSWORD = $s.fdw_mongo_password
    PG_FDW_MONGO_LOGIN_PASSWORD = $s.pg_fdw_mongo_login_password
})
Invoke-JoyceScript -Service postgres -Path 'integracion/sincronizacion/01_outbox.sql'

Step 'PostgreSQL: perfiles externos y vistas api (módulo de Armando, D-042)'
Invoke-JoyceScript -Service postgres -Path 'postgresql/04_roles_externos.sql' -Env ([ordered]@{
    PG_API_WEB_PASSWORD = $s.pg_api_web_password
    PG_API_MOBILE_PASSWORD = $s.pg_api_mobile_password
})
Invoke-JoyceScript -Service postgres -Path 'postgresql/05_vistas_api.sql'

Write-Output "`nPASS instalación de módulos de Joyce. Siguiente: pwsh -NoProfile -File ./scripts/Test-JoyceModulos.ps1"
