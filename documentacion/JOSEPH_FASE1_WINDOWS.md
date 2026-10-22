# Ejecución de la fase 1 de Joseph

Actualización: 22/10/2026, ejecución local y D-034 posteriores a correcciones H1–H3. Rama feature/joseph-infra-postgresql; PR #1 en borrador.
Solo infraestructura de Joseph. El gate FDW sigue abierto: CREATE EXTENSION/LOAD no prueban consultas remotas ni BSON.

## Diagnóstico Windows y requisitos

PowerShell 7, Git y Docker Desktop en modo Linux/WSL 2. Revisar 30–40 GB libres y recursos:
PG 1 GiB, SQL Server 3 GiB, MongoDB 1.5 GiB son límites, no consumo medido.

```powershell
docker info
docker context show
Get-Service com.docker.service
wsl --status
wsl --version
```

En la primera revisión local del 22/10 faltaba el named pipe. El log de Docker Desktop 4.91.0
mostró error 1920 al renombrar `sailor-ingest.sock`; `fsutil reparsepoint query` reprodujo el
error. Tras cerrar Desktop se **renombraron y conservaron**, sin borrar, las carpetas
transitorias `%LOCALAPPDATA%\Docker\run` y `%LOCALAPPDATA%\docker-secrets-engine`. Al volver
a iniciar Desktop, `docker info` respondió con Engine 29.8.0 y kernel efectivo
`6.18.33.2-microsoft-standard-WSL2`. Esta recuperación se probó una sola vez; no se ha probado
su permanencia tras reiniciar Desktop o Windows. Los directorios anteriores permanecen fuera
del repositorio. No se modificó WSL/kernel, protecciones ni volúmenes.
Si el daemon falta en otro arranque, revisar el error actual antes de repetir una reparación.

## Inicialización y pruebas sin daemon

```powershell
./scripts/Initialize-Local.ps1
./pruebas/infraestructura/Test-Secrets.ps1
./pruebas/infraestructura/Test-ComposeValidation.ps1
```

El inicializador crea .env y tres secretos aleatorios de 68 caracteres solo si faltan. Conserva los bytes
existentes, sin mostrarlos. En Windows reconstruye la DACL de secrets/ y de **todos los archivos normales
existentes**, cambia propietario al usuario actual, protege la herencia y permite solo usuario/SYSTEM.
Verifica el resultado; si no puede aplicar permisos, falla. Rechaza enlaces/subcarpetas dentro de secrets/.
La persistencia de ACL usa FileSystemAclExtensions: en este Windows Set-Acl devolvió SeSecurityPrivilege.
No se alteran las auditorías SACL ni se solicitan privilegios adicionales.

La regresión crea carpeta y archivos temporales con Allow explícitos Everyone/Users, comprueba su retiro
y preservación de valores tras dos ejecuciones, y limpia la carpeta temporal. Verifica DACL/propietario,
sin impersonación ni inicio de sesión de otra cuenta. Un administrador puede tomar posesión de archivos.
En Linux usa directorio 700/archivos 644 para permitir lectura por los UID dentro de sus respectivos
bind mounts; el directorio privado restringe acceso desde el host. La CI comprueba lectura por usuarios
postgres, SQL Server 10001:0 y mongodb. Compose local no cifra los secretos en disco.

.env es configuración no secreta; secrets/ está ignorado y fuera del build.
No rotar un valor en el archivo creyendo que cambia una contraseña de un volumen existente:
la rotación requiere modificar la cuenta dentro del motor.

## Una selección para todas las operaciones y pruebas

Ejecutar desde el repositorio. Elegir la selección **antes** de arrancar y conservar $deploy:

```powershell
$deploy = @{
    ComposeFile = @('compose.yaml')
    EnvFile = @('.env')
    ProjectName = 'estudios-medicos'
}
# Si se necesitan clientes en localhost, usar esto desde el arranque:
# $deploy.ComposeFile = @('compose.yaml','compose.local.yaml')

./scripts/Test-Infra.ps1 @deploy -StaticOnly
./scripts/Invoke-Compose.ps1 @deploy -Command @('build','postgres')
./scripts/Invoke-Compose.ps1 @deploy -Command @('up','-d','--wait','--wait-timeout','300')
./scripts/Test-Infra.ps1 @deploy
./scripts/Test-Persistence.ps1 @deploy
```

En esta PC el puerto 5432 ya estaba ocupado por otro PostgreSQL. Para repetir la validación
sin editar `.env`, seleccionar el overlay y dos archivos de entorno **antes** del arranque:

```powershell
New-Item -ItemType Directory -Path .tmp/windows-local -Force | Out-Null
Set-Content -LiteralPath .tmp/windows-local/ports.env -Encoding utf8 -Value @(
    'POSTGRES_PORT=15432','SQLSERVER_PORT=11433','MONGODB_PORT=37017'
)
$deploy.ComposeFile = @('compose.yaml','compose.local.yaml')
$deploy.EnvFile = @('.env','.tmp/windows-local/ports.env')
```

En el overlay actual la publicación la hace **`port-gateway`**, un proxy TCP sin secretos
conectado a `medical-network` y a `host-access`. Los motores siguen solo en la red interna;
el proxy expone únicamente 127.0.0.1. Compose levanta cuatro contenedores: tres motores
y esa pasarela auxiliar. El modo base mantiene exactamente tres motores y ningún puerto host.

Revisar cada código de salida. Invoke-Compose y ambos tests comparten Compose-Context.ps1 y admiten
ComposeFile (array), EnvFile (array), ProjectName y ProjectDirectory. Rutas relativas se resuelven
desde ProjectDirectory, por defecto la raíz del checkout.
Sin parámetros explícitos se respeta la selección nativa de Docker: COMPOSE_FILE, COMPOSE_ENV_FILES,
COMPOSE_PROJECT_NAME y .env. COMPOSE_FILE separa rutas con ; en Windows y : en Linux;
COMPOSE_ENV_FILES usa comas. Los parámetros explícitos tienen precedencia.

Test-Infra valida por separado:
1. Ejemplo base sin puertos, fijando archivos/.env.example/proyecto de ejemplo.
2. Ejemplo con overlay, solo 127.0.0.1.
3. Configuración **operativa**, con los mismos parámetros/variables que usarán las operaciones.
Un PASS del ejemplo no sustituye un PASS operativo. Un .env operativo inválido hace fallar el script.
La prueba negativa H3 se hace en una copia temporal; no edita .env del usuario ni imprime su contenido.

Por defecto no hay puertos host; el overlay publica 127.0.0.1:5432/1433/27017
(configurables en .env o en archivo temporal adicional). El primer overlay guardaba
bindings solicitados en `HostConfig`, pero Docker no activó puertos de motores unidos
solo a una red `internal: true`. Ahora las verificaciones runtime contrastan el
`NetworkSettings.Ports` del gateway, su ID/salud, proyecto y volumen PG, y abren TCP
a los tres puertos desde el host. Si se arrancó con overlay pero se prueba como base,
falla antes de insertar el marcador.

El gateway ahora usa `/ready` de HAProxy, enlazado a 127.0.0.1:8404 **dentro del
contenedor**, para exigir al menos un servidor activo en cada uno de los tres backends.
Docker marca no saludable al gateway cuando cualquiera cae; `Test-Infra.ps1` y
`Test-Persistence.ps1` rechazan esa condición. El puerto 8404 no está publicado al host.
Una sonda TCP del frontend sola puede pasar aunque el backend esté caído. La regresión
que detiene e inicia PostgreSQL está protegida para ejecutarse únicamente en el proyecto efímero
`joseph-audit-localhost` de GitHub Actions; **no ejecutarla contra el despliegue local**.

## Qué acredita la persistencia y cómo limpiar

Test-Persistence crea una tabla public.joseph_probe_<GUID> con una fila en la base administrativa postgres;
ejecuta restart postgres, espera health de **ese mismo contenedor** mediante inspect y compara ID,
gateway, puertos activos y nombre del volumen. Comprueba la fila y elimina la tabla al pasar.
No ejecuta up ni reconcilia/recrea configuración durante la recuperación.

**P12 parcial:** una fila PostgreSQL tras restart, con puertos activos, gateway y volumen conservados.
No acredita datos en SQL Server/MongoDB, recreación, down/up, reinicio Docker/WSL, backup ni restauración.
Aunque verifica el montaje del volumen nombrado, restart por sí solo no reemplaza una prueba de recreación.

Si falla, conserva en el error el nombre del marcador y muestra cómo limpiarlo con la misma selección.
Cuando PostgreSQL esté disponible, copiar el nombre del error:

```powershell
$table = 'joseph_probe_REEMPLAZAR_POR_GUID_DEL_ERROR'
if ($table -notmatch '^joseph_probe_[0-9a-f]{32}$') { throw 'Marcador inválido' }
./scripts/Invoke-Compose.ps1 @deploy -Command @(
    'exec','-T','--user','postgres','postgres','psql','-X','-U','postgres',
    '-d','postgres','-v','ON_ERROR_STOP=1','-c',"DROP TABLE IF EXISTS public.$table"
)
```

No borrar volúmenes para obtener PASS. El init solo corre en volumen nuevo; corregir instalaciones parciales
mediante diagnóstico, sin repetir DDL a ciegas. Persistencia no equivale a backup.

## Consultas y diagnóstico con la misma selección

```powershell
./scripts/Invoke-Compose.ps1 @deploy -Command @('ps','-a')
./scripts/Invoke-Compose.ps1 @deploy -Command @('exec','--user','postgres','postgres','psql','-X','-U','postgres','-d','estudios_medicos')
./scripts/Invoke-Compose.ps1 @deploy -Command @('exec','sqlserver','/opt/mssql-tools18/bin/sqlcmd','-S','localhost','-U','sa','-C')
./scripts/Invoke-Compose.ps1 @deploy -Command @('exec','mongodb','mongosh','--username','admin_local','--authenticationDatabase','admin')
./scripts/Invoke-Compose.ps1 @deploy -Command @('stats','--no-stream')
./scripts/Invoke-Compose.ps1 @deploy -Command @('run','--rm','--no-deps','--entrypoint','uname','mongodb','-r')
./scripts/Invoke-Compose.ps1 @deploy -Command @('logs','--tail','80','postgres','sqlserver','mongodb')
./scripts/Invoke-Compose.ps1 @deploy -Command @('down')
```

Ajustar nombres de DB/usuario si .env difiere del ejemplo. SQL Server/Mongo solicitarán contraseña.
No publicar valores ni logs sin revisar. sa/root son administración inicial; Joyce prepara cuentas limitadas.
down conserva volúmenes; no usar down -v. El kernel de uname dentro del contenedor es el efectivo Docker.
Si aparece SERVER-121912, conservar el error y revisar con Joyce el digest/kernel; no eludir la protección.

## FDW: dependencias sin cambios

Esperar la base real, dbo.vw_estado_facturacion y svc_pg_mssql_ro de Joyce, con SELECT solo a la vista.
Contrato: una fila por (id_paciente bigint, codigo_region char(2)), nombre_aseguradora, estado_cobertura,
estado_facturacion, total_facturado_crc decimal(12,2), fecha_actualizacion con tipos/offset acordados.
La proyección ISO-8601 TDS aún requiere prueba de Unicode, precisión y zona; no hay datos sustitutos locales.

```powershell
$joyceDatabase = Read-Host 'Base entregada por Joyce'
$fdwSecret = Read-Host 'Contraseña de svc_pg_mssql_ro' -AsSecureString
try {
    $env:FDW_MSSQL_PASSWORD = [Net.NetworkCredential]::new('', $fdwSecret).Password
    ./scripts/Invoke-Compose.ps1 @deploy -Command @(
        'exec','-T','--user','postgres','--env','FDW_MSSQL_PASSWORD','postgres',
        'psql','-X','-U','postgres','-d','estudios_medicos','-v','ON_ERROR_STOP=1',
        '-v',"mssql_database=$joyceDatabase",'-f','/opt/proyecto/integracion/01_fdw_sqlserver.sql'
    )
} finally {
    Remove-Item Env:FDW_MSSQL_PASSWORD -ErrorAction SilentlyContinue
    $fdwSecret.Dispose()
}
./scripts/Invoke-Compose.ps1 @deploy -Command @(
    'exec','-T','--user','postgres','postgres','psql','-X','-U','postgres','-d','estudios_medicos',
    '-v','ON_ERROR_STOP=1','-f','/opt/proyecto/pruebas/02_fdw_sqlserver.sql'
)
```

Instalación transaccional de una ejecución; no usar psql -a/-e ni imprimir mappings/variables.
NOLOGIN y SET ROLE desde administrador no demuestran autenticación propia ni permisos negativos.
Mongo FDW requiere validación conjunta de cuenta limitada, ObjectId, Int64/Int32, Date, INSERT/UPDATE,
índice único y revisión. No hay exportador ni outbox funcionando. El gate de conectores sigue abierto.

## Seguridad y evidencia CI

SCRAM PG, peer Unix local, red interna y puertos localhost opcionales. FreeTDS exige cifrado pero no valida
CA; sqlcmd -C confía en certificado de laboratorio. PG/Mongo sin TLS. No ampliar exposición sin revisar esto.
Las tablas clínicas, SQL Server/MongoDB de Joyce y vistas/roles/reportes de Armando siguen pendientes.

El workflow ejecuta ACL en Windows Server 2022 y motores en Ubuntu22 con matriz base/localhost.
Windows Server CI no es la PC Windows11 de Joseph. Se enmascaran secretos efímeros antes del diagnóstico
y se guardan solo resúmenes y salidas depuradas en artifacts con retención de 14 días.
Ni el PASS Ubuntu ni el PASS ACL acreditan motores en esta PC. El informe de correcciones identifica
head, run, resultados y limitaciones. Logs históricos de fallos permanecen en evidencias/.
