#requires -Version 7.0
# Fila remota huérfana sintética: visible al perfil FDW interno, invisible en API web.
[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Joyce-Common.ps1')
$null = Assert-JoyceEphemeralContext
Wait-JoyceHealthy
$created = $false
try {
    $null = Invoke-JoyceScript -Service sqlserver -Text @'
:on error exit
SET NOCOUNT ON;
USE integracion_externa;
BEGIN TRANSACTION;
INSERT INTO dbo.paciente_integracion
 (id_paciente,codigo_region,id_aseguradora,codigo_externo)
SELECT 999991,'SJ',MIN(id_aseguradora),'ORPHAN-P18-999991'
FROM dbo.aseguradoras;
INSERT INTO dbo.paciente_cobertura
 (id_paciente,codigo_region,estado_cobertura,fecha_validacion)
VALUES (999991,'SJ','VIGENTE',SYSDATETIMEOFFSET());
COMMIT;
EXEC dbo.sp_recalcular_resumen_facturacion
 @id_paciente=999991,@codigo_region='SJ';
GO
'@
    $created = $true
    $interno = (Invoke-JoyceScript -Service postgres -PgUser usr_fdw_pg_mssql `
        -PgLoginSecretVar PG_PW `
        -Env ([ordered]@{ PG_PW = Get-JoyceSecret 'pg_fdw_mssql_login_password' }) -Text @'
\pset tuples_only on
\pset format unaligned
SELECT count(*) FROM externo.fn_estado_facturacion()
WHERE id_paciente=999991 AND codigo_region='SJ';
'@).Trim()
    if ($interno -ne '1') { throw "La vista remota no expuso la fila sintética al perfil interno ($interno)." }
    $web = Invoke-JoyceScript -Service postgres -PgUser usr_api_web `
        -PgLoginSecretVar PG_PW `
        -Env ([ordered]@{ PG_PW = Get-JoyceSecret 'pg_api_web_password' }) -Text @'
DO $$ BEGIN
 IF EXISTS (SELECT 1 FROM api.fn_paciente_facturacion()
            WHERE id_paciente=999991 AND codigo_region='SJ')
    OR EXISTS (SELECT 1 FROM api.vw_paciente_facturacion
               WHERE id_paciente=999991 AND codigo_region='SJ') THEN
   RAISE EXCEPTION 'La API publicó facturación sin paciente clínico';
 END IF;
 IF NOT EXISTS (SELECT 1 FROM api.vw_paciente_facturacion
                WHERE id_paciente=1001 AND codigo_region='AL') THEN
   RAISE EXCEPTION 'La API perdió facturación legítima';
 END IF;
END $$;
\echo 'PASS alcance API: fila huérfana excluida, paciente legítimo visible'
'@
    if ($web -notmatch 'PASS alcance API') { throw 'La prueba de alcance web no confirmó el filtro.' }
    Write-Output 'PASS alcance API: FDW interno ve 1 fila huérfana; web ve 0 y conserva paciente legítimo'
} finally {
    if ($created) {
        $null = Invoke-JoyceScript -Service sqlserver -Text @'
:on error exit
SET NOCOUNT ON;
USE integracion_externa;
DELETE FROM dbo.paciente_integracion WHERE id_paciente=999991 AND codigo_region='SJ';
IF EXISTS (SELECT 1 FROM dbo.vw_estado_facturacion WHERE id_paciente=999991 AND codigo_region='SJ')
 THROW 51072, 'La fila sintética quedó en la vista', 1;
GO
'@
        Write-Output 'PASS limpieza API: fila huérfana sintética retirada del proyecto efímero'
    }
}
