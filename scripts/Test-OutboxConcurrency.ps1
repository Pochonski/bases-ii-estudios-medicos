#requires -Version 7.0
# Dos exportadores reales compiten por revisiones del mismo estudio, solo en P18 efímero.
[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Joyce-Common.ps1')
$null = Assert-JoyceEphemeralContext
Wait-JoyceHealthy

$jobs = [System.Collections.Generic.List[object]]::new()
$common = Join-Path $PSScriptRoot 'Joyce-Common.ps1'
try {
    $oidAntes = (Invoke-JoyceScript -Service mongodb -Text @'
const d = db.getSiblingDB('reportes_medicos').resumenes_estudios.findOne({id_estudio:30031});
if (!d || d.revision !== 2) quit(1);
print(d._id.toString());
'@).Trim()
    $null = Invoke-JoyceScript -Service postgres -Text @'
SELECT * FROM integracion.registrar_resultado(30031, 503, 'Ecografía ficticia concurrente, revisión 3');
SELECT * FROM integracion.registrar_resultado(30031, 503, 'Ecografía ficticia concurrente, revisión 4');
DO $$ BEGIN
 IF (SELECT count(*) FROM integracion.eventos_integracion
     WHERE id_estudio=30031 AND revision IN (3,4) AND estado='PENDIENTE') <> 2 THEN
   RAISE EXCEPTION 'No hay dos eventos pendientes para concurrencia';
 END IF;
END $$;
'@

    # El bloqueador solo retiene el candado sintético. Hace observable que los dos
    # exportadores alcanzan simultáneamente el mismo estudio antes de liberarlos.
    $blocker = Start-Job -ArgumentList $common -ScriptBlock {
        param($commonPath)
        . $commonPath
        $null = Assert-JoyceEphemeralContext
        Invoke-JoyceScript -Service postgres -Text @'
BEGIN;
SELECT pg_advisory_xact_lock(30031);
SELECT pg_sleep(30);
COMMIT;
'@
    }
    $jobs.Add($blocker)
    $bloqueado = $false
    for ($i=0; $i -lt 15; $i++) {
        $probe = (Invoke-JoyceScript -Service postgres -Text @'
\pset tuples_only on
\pset format unaligned
SELECT pg_try_advisory_xact_lock(30031);
'@).Trim()
        if ($probe -eq 'f') { $bloqueado = $true; break }
        Start-Sleep -Seconds 1
    }
    if (-not $bloqueado) { throw 'El bloqueador de prueba no adquirió el candado.' }

    for ($i=1; $i -le 2; $i++) {
        $worker = Start-Job -ArgumentList $common -ScriptBlock {
            param($commonPath)
            . $commonPath
            $null = Assert-JoyceEphemeralContext
            $envVars = [ordered]@{ PG_PW = Get-JoyceSecret 'pg_fdw_mongo_login_password' }
            Invoke-JoyceScript -Service postgres -PgUser usr_fdw_pg_mongo `
                -PgLoginSecretVar PG_PW -Env $envVars `
                -Text 'CALL integracion.exportar_pendientes(1);'
        }
        $jobs.Add($worker)
    }

    $esperando = 0
    for ($i=0; $i -lt 20; $i++) {
        $raw = Invoke-JoyceScript -Service postgres -Text @'
\pset tuples_only on
\pset format unaligned
SELECT count(*) FROM pg_stat_activity
WHERE usename='usr_fdw_pg_mongo' AND wait_event_type='Lock'
  AND query LIKE 'CALL integracion.exportar_pendientes(1)%';
'@
        $esperando = [int]$raw.Trim()
        if ($esperando -eq 2) { break }
        Start-Sleep -Seconds 1
    }
    if ($esperando -ne 2) { throw "No se observaron dos exportadores concurrentes esperando el mismo estudio ($esperando)." }
    Write-Output 'PASS concurrencia: dos sesiones exportadoras observadas bloqueadas sobre el mismo estudio'

    foreach ($job in $jobs) {
        if (-not (Wait-Job -Job $job -Timeout 60)) { throw 'Exportador o bloqueador excedió 60 segundos.' }
        $result = @(Receive-Job -Job $job -ErrorAction Stop)
        if ($job.State -ne 'Completed') { throw "Trabajo concurrente falló: $($job.State)" }
        foreach ($line in $result) { if ("$line" -match 'evento|exportar_pendientes') { Write-Output "$line" } }
    }
    $pg = (Invoke-JoyceScript -Service postgres -Text @'
\pset tuples_only on
\pset format unaligned
SELECT count(*) FROM integracion.eventos_integracion
WHERE id_estudio=30031 AND revision IN (3,4) AND estado='PROCESADO';
'@).Trim()
    if ($pg -ne '2') { throw "Los dos eventos no quedaron procesados ($pg)." }
    $mongo = (Invoke-JoyceScript -Service mongodb -Text @'
const c = db.getSiblingDB('reportes_medicos').resumenes_estudios;
const d = c.find({id_estudio:30031}).toArray();
if (d.length !== 1 || d[0].revision !== 4 ||
    !d[0].resultado_resumen.includes('revisión 4')) quit(1);
print(d[0]._id.toString());
'@).Trim()
    if ($mongo -ne $oidAntes) { throw 'El documento MongoDB cambió de _id.' }
    Write-Output 'PASS concurrencia: dos eventos procesados, un documento, mismo ObjectId y revisión final 4'
} finally {
    foreach ($job in $jobs) {
        if ($job.State -eq 'Running') { Stop-Job -Job $job }
        Remove-Job -Job $job -Force
    }
}
