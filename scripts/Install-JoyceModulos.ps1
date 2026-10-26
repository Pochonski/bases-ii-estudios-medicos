#requires -Version 7.0
# Joyce. Instala SQL Server, MongoDB y la integración PostgreSQL (FDW + outbox) sobre el
# entorno Compose de Joseph. Repetible: los scripts de Joyce son idempotentes; el núcleo
# PostgreSQL de Joseph y su FDW SQL Server se aplican solo si todavía no existen.
#   pwsh -NoProfile -File ./scripts/Install-JoyceModulos.ps1
[CmdletBinding()]
param([switch]$SkipUp)
. (Join-Path $PSScriptRoot 'Joyce-Common.ps1')

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

Step 'SQL Server: sqlserver/01..06'
foreach ($f in '01_base_tablas', '02_fragmentacion', '03_procedimientos', '04_vistas') {
    Invoke-JoyceScript -Service sqlserver -Path "sqlserver/$f.sql"
}
Invoke-JoyceScript -Service sqlserver -Path 'sqlserver/05_roles.sql' `
    -Env ([ordered]@{ FDW_MSSQL_PASSWORD = $s.fdw_mssql_password })
Invoke-JoyceScript -Service sqlserver -Path 'sqlserver/06_datos_prueba.sql'

Step 'MongoDB: mongodb/01..03'
Invoke-JoyceScript -Service mongodb -Path 'mongodb/01_colecciones.js'
Invoke-JoyceScript -Service mongodb -Path 'mongodb/02_indices.js'
Invoke-JoyceScript -Service mongodb -Path 'mongodb/03_usuarios.js' `
    -Env ([ordered]@{ FDW_MONGO_PASSWORD = $s.fdw_mongo_password })

Step 'PostgreSQL: núcleo clínico de Joseph (solo si falta)'
$hayNucleo = Invoke-JoyceScript -Service postgres -Text "\pset tuples_only on`nSELECT to_regclass('clinico.pacientes') IS NOT NULL;"
if ($hayNucleo.Trim() -ne 't') {
    foreach ($f in '01_esquemas', '02_tablas', '03_particiones', '06_datos_prueba') {
        Invoke-JoyceScript -Service postgres -Path "postgresql/$f.sql"
    }
} else { Write-Output 'clinico.pacientes ya existe; no se reaplica el núcleo.' }

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
