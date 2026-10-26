# Joseph fase 2 — núcleo PostgreSQL independiente

**Corte:** 22/10/2026. Rama `feature/joseph-postgresql-core`, PR #2 en borrador,
base `feature/joseph-infra-postgresql` (PR #1). Esta fase es un adelanto aislado:
el gate de consultas FDW/BSON permanece abierto y no hay worker, vista API ni datos
SQL Server/MongoDB implementados aquí.

## Instalación y selección Compose

Ejecutar en PowerShell 7 desde la raíz del checkout. `Initialize-Local.ps1` conserva los
secretos existentes. La base utilizada por las pruebas se crea vacía con nombre aleatorio;
**no instala estas tablas en la base administrativa ni en una base clínica existente**.

```powershell
docker info
./scripts/Initialize-Local.ps1
$deploy = @{
    ComposeFile = @('compose.yaml')
    EnvFile = @('.env')
    ProjectName = 'estudios-medicos'
}
./scripts/Test-Infra.ps1 @deploy -StaticOnly
./scripts/Invoke-Compose.ps1 @deploy -Command @('build','postgres')
./scripts/Invoke-Compose.ps1 @deploy -Command @('up','-d','--wait','--wait-timeout','300','postgres')
./scripts/Test-PostgresqlCore.ps1 @deploy -Repeat 2 -IncludePersistence
```

Si el despliegue existente usa `compose.local.yaml`, seleccionar **ambos** archivos,
los mismos `EnvFile` y `ProjectName` con que se inició. El gateway requiere que los tres
backends estén saludables; en ese modo arrancar los tres motores y el gateway mediante
`up -d --wait --wait-timeout 300` sin limitar a `postgres`. No cambiar la selección entre
operación y prueba. No agregar `down -v` ni borrar volúmenes para repetir la prueba.

Con daemon ausente, `docker info` falla y la ejecución SQL/restart queda **NO EJECUTADA**
en Windows. Se puede verificar sintaxis PowerShell y formato Git:

```powershell
$tokens = $null; $errors = $null
[System.Management.Automation.Language.Parser]::ParseFile(
    (Resolve-Path scripts/Test-PostgresqlCore.ps1), [ref]$tokens, [ref]$errors) | Out-Null
$errors
git diff --check
```

## Orden y resultado de las pruebas

El runner copia `postgresql/` y `pruebas/postgresql/` a `/tmp` del contenedor usando el
mismo contexto Compose; crea una base desde `template0`; ejecuta `01_esquemas.sql`,
`02_tablas.sql`, `03_particiones.sql` y `06_datos_prueba.sql` en ese orden con
`ON_ERROR_STOP=1`. Luego ejecuta:

1. `01_estructura.sql`: existencia de 12 tablas, tres particiones, PK/FK compuestas y
   conteos exactos del fixture.
2. `02_integridad.sql`: inserción válida con atención en otra región, ROLLBACK; rechazos
   de FK, región sin partición, resultado duplicado, revisión cero, estado inválido y
   diagnóstico huérfano.
3. `03_particiones.sql`: `tableoid` para SJ/AL/CA, `EXPLAIN` y poda AL; paciente 1001/AL
   atendido en sucursal SJ.
4. `04_transacciones.sql`: COMMIT local de resultado/evento sintéticos para estudio 30040
   y ROLLBACK local para 30039. No prueba exportación ni transacción distribuida.
5. Con `-IncludePersistence`, `restart postgres`, espera salud del **mismo contenedor**,
   comprueba mismo volumen/gateway/puertos y ejecuta `05_persistencia.sql`. Acredita solo
   registros clínicos PostgreSQL tras restart, no recreación, backup/restauración ni otros motores.

Con `-Repeat 2` se repite en dos bases vacías independientes. Cada base sintética se
elimina explícitamente al pasar; **el volumen nombrado se conserva**. Ante fallo, el
mensaje muestra el nombre de la base retenida para diagnóstico. Después de revisarla,
se puede eliminar solo esa base con el mismo contexto y el nombre exacto del error:

```powershell
$database = 'joseph_core_REEMPLAZAR_POR_GUID_DEL_ERROR'
if ($database -notmatch '^joseph_core_[0-9a-f]{32}$') { throw 'Nombre inválido' }
./scripts/Invoke-Compose.ps1 @deploy -Command @(
    'exec','-T','--user','postgres','postgres','dropdb','-U','postgres',$database)
```

`06_datos_prueba.sql` contiene solo personas y estudios ficticios, dominios
`example.invalid` e IDs estables. La tabla outbox inicia vacía. Las filas creadas por
`04_transacciones.sql` solo viven en la base sintética y demuestran atomicidad local.

## Integración pendiente

Joyce debe revisar `clinico`/`integracion`, campos y estados del outbox antes de implementar
su worker. Hace falta la base, vista real `dbo.vw_estado_facturacion`, cuenta limitada,
tipos y fixture SQL Server para consultas TDS reproducibles. Mongo FDW requiere pruebas
de autenticación, `ObjectId`, Int64/Int32, Date, INSERT/UPDATE, índice único y revisión.
`CREATE EXTENSION`/`LOAD` del PR #1 no cierran estos puntos. No ejecutar módulos de Joyce
o Armando desde este manual.

## Actualización de consolidación — 23/10/2026

PR #1 ya está en `main`; PR #2 fue fusionado solo en la rama de infraestructura.
El PR #3 en borrador propone este núcleo directamente a `main`. Su workflow escucha
ahora ambas bases y prueba que un SQL inválido devuelve un código de error. Los
comandos anteriores siguen siendo válidos. Para verificar en Windows sin reiniciar
el PostgreSQL compartido, se usó una segunda selección Compose **aislada** con un
overlay temporal ignorado por Git que solo cambia el nombre de la red:

```yaml
networks:
  medical-network:
    name: joseph-core-pr3-local-network
```

```powershell
New-Item -ItemType Directory -Force .tmp | Out-Null
@'
networks:
  medical-network:
    name: joseph-core-pr3-local-network
'@ | Set-Content -LiteralPath .tmp/joseph-core-pr3-local.compose.yaml -Encoding utf8
$deploy = @{
    ComposeFile = @('compose.yaml','.tmp/joseph-core-pr3-local.compose.yaml')
    EnvFile = @('.env')
    ProjectName = 'joseph-core-pr3-local'
}
./scripts/Test-Infra.ps1 @deploy -StaticOnly
try {
    ./scripts/Invoke-Compose.ps1 @deploy -Command @('up','-d','--wait','--wait-timeout','180','postgres')
    ./scripts/Test-PostgresqlCore.ps1 @deploy -Repeat 2 -IncludePersistence
} finally {
    ./scripts/Invoke-Compose.ps1 @deploy -Command @('down')
}
```

La ejecución de 23/10 PASÓ dos veces en Windows 11 con Docker Engine 29.8.0 y
PostgreSQL 16.15. El `down` fue **sin `-v`**; el volumen sintético
`joseph-core-pr3-local_postgres_data` quedó conservado. Las dos bases de prueba
se eliminaron al pasar. Los cuatro contenedores del proyecto compartido
`estudios-medicos` conservaron sus IDs; no se reiniciaron. Este resultado no
acredita estabilidad de Docker Desktop tras un reinicio completo de Windows,
ni FDW remoto o sincronización MongoDB.
