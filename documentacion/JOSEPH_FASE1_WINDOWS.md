# Ejecución de la fase 1 de Joseph

Fecha: 22/10/2026, America/Costa_Rica. Rama: `feature/joseph-infra-postgresql`.
Alcance actual: infraestructura, construcción de extensiones y preparación FDW SQL Server.
No se han creado las tablas clínicas: el gate 2 de docs/06 exige evaluar conectores primero.

## Requisitos

Windows 11 x86-64, Docker Desktop en modo Linux con WSL 2, PowerShell 7 (`pwsh`), Git;
30–40 GB libres recomendados y RAM suficiente para Docker. Límites configurados: PostgreSQL 1 GiB,
SQL Server 3 GiB, MongoDB 1.5 GiB; no representan consumo medido.
En esta sesión WSL informa versión predeterminada 2; el motor Docker Linux no responde.
No se modificaron distribuciones WSL ni se habilitaron características de Windows.

## Arranque desde esta carpeta (PowerShell 7)

```powershell
git switch feature/joseph-infra-postgresql
docker desktop start
docker info
# Continuar cuando docker info muestre Server y modo Linux.
./scripts/Initialize-Local.ps1
./scripts/Test-Infra.ps1 -StaticOnly
docker compose config --quiet
docker compose build --progress plain postgres
docker compose up -d --wait --wait-timeout 300
./scripts/Test-Infra.ps1
./scripts/Test-Persistence.ps1
```

Revisar el código de salida de cada comando antes de continuar. `Initialize-Local.ps1` crea
`.env` y tres contraseñas aleatorias de 68 caracteres en `secrets/`, sin mostrarlas ni
sobrescribir archivos existentes. En Windows restringe la carpeta al usuario actual y SYSTEM;
en Linux usa directorio 700 y archivos 644 para que el UID de SQL Server pueda leer su bind mount.
La carpeta privada impide el acceso de otros usuarios del host.
Los archivos se montan únicamente en el servicio que los necesita.
Compose local NO cifra estos archivos en disco; proteger la cuenta y el equipo.
`.dockerignore` impide enviarlos al contexto de construcción.
No cambiar una contraseña en el archivo pensando que rota una base existente: la inicialización
solo aplica a volúmenes nuevos; una rotación requiere ALTER del usuario en cada motor.

El init de PostgreSQL crea únicamente las dos extensiones y restringe CREATE en public.
Los reinicios conservan volúmenes y no vuelven a ejecutar initdb.
Si un init falla con volumen parcialmente creado, inspeccionar el estado y corregirlo;
no eliminar volúmenes ni repetir SQL a ciegas. No hay migraciones clínicas en esta fase.
`Test-Persistence.ps1` reinicia solo PostgreSQL y usa una tabla marcador aleatoria en la base
administrativa `postgres`; elimina el marcador al pasar. Una falla conserva el nombre en la salida
para diagnóstico. No comprueba persistencia de SQL Server/MongoDB.

## Consultas interactivas

```powershell
docker compose exec --user postgres postgres psql -X -U postgres -d estudios_medicos
docker compose exec sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -C
docker compose exec mongodb mongosh --username admin_local --authenticationDatabase admin
```

SQL Server y MongoDB solicitarán contraseña: consultarla localmente en el archivo correspondiente
sin publicarla ni incluirla en capturas. `sa` y root Mongo son administración de bootstrap;
Joyce debe crear sus cuentas de servicio de mínimo privilegio.
Por defecto no se publica ningún puerto. Si se necesitan clientes en Windows:

```powershell
docker compose -f compose.yaml -f compose.local.yaml up -d --wait
```

El overlay publica solo 127.0.0.1:5432/1433/27017, configurables en `.env`.
Conectar el cliente al puerto correspondiente en 127.0.0.1.
Seguir usando ambos `-f` al administrar ese despliegue. Disponibilidad de puertos/overlay sin probar.

## FDW SQL Server: dependencia explícita de Joyce

Esperar la base de integración, `dbo.vw_estado_facturacion` y
`svc_pg_mssql_ro` con SELECT solo a esa vista. El contrato conserva:
`id_paciente bigint`, `codigo_region char(2)`, `nombre_aseguradora`,
`estado_cobertura`, `estado_facturacion`, `total_facturado_crc decimal(12,2)`,
`fecha_actualizacion` temporal con zona. Una fila por paciente-región.
Joyce debe confirmar tipos concretos, cardinalidad, base y fixture; no hay datos de facturación locales.
La proyección FDW convierte la fecha a ISO-8601 en la consulta remota, conservando el instante y las
columnas; validar DATETIMEOFFSET y precisión con Joyce. No cambia la vista remota.
Sin esa dependencia, P01 y la validación funcional de P17 permanecen bloqueadas.

Ejecutar desde PowerShell 7, reemplazando solo el nombre no secreto de base:

```powershell
$joyceDatabase = Read-Host 'Nombre de base entregada por Joyce'
$fdwSecret = Read-Host 'Contraseña de svc_pg_mssql_ro' -AsSecureString
try {
    $env:FDW_MSSQL_PASSWORD = [Net.NetworkCredential]::new('', $fdwSecret).Password
    docker compose exec -T --user postgres --env FDW_MSSQL_PASSWORD postgres psql -X -U postgres -d estudios_medicos -v ON_ERROR_STOP=1 -v "mssql_database=$joyceDatabase" -f /opt/proyecto/integracion/01_fdw_sqlserver.sql
    if ($LASTEXITCODE -ne 0) { throw 'Configuración FDW falló; inspeccionar antes de repetir.' }
} finally {
    Remove-Item Env:FDW_MSSQL_PASSWORD -ErrorAction SilentlyContinue
    $fdwSecret.Dispose()
}
docker compose exec -T --user postgres postgres psql -X -U postgres -d estudios_medicos -v ON_ERROR_STOP=1 -f /opt/proyecto/pruebas/02_fdw_sqlserver.sql
```

Script de instalación transaccional, de una sola ejecución: al encontrar objetos existentes falla
y revierte, sin sobrescribir mappings. El perfil PostgreSQL es NOLOGIN; las pruebas usan SET ROLE
desde el administrador. Habilitación LOGIN/contraseña propia y pruebas de inicio de sesión pendientes.
No hay mappings para PUBLIC ni para postgres; Armando deberá revisar el contexto del propietario
de sus futuras vistas para usar el mapping adecuado. No se crearon vistas API.
No ejecutar con `psql -a/-e`, no imprimir las variables ni consultar opciones secretas de mappings.

## Seguridad efectiva y límites

- SCRAM-SHA-256 para TCP PostgreSQL, peer local solo para el usuario Unix postgres.
- Red interna; sin puertos publicados por defecto.
- FreeTDS exige cifrado TLS a SQL Server; se acepta certificado de laboratorio sin CA validada.
  `sqlcmd -C` también confía en ese certificado. Validación de identidad TLS pendiente.
- PostgreSQL y MongoDB no tienen TLS configurado: autenticación y aislamiento local no equivalen
  a cifrado de todo el tráfico. Esta configuración es para la PC de laboratorio.
- No se incluyeron claves reales, pacientes, datos médicos ni documentos originales del curso.
- SQL Server y MongoDB arrancan vacíos de objetos del proyecto. Sus módulos pertenecen a Joyce.

## Parada y diagnóstico

```powershell
docker compose ps -a
docker compose logs --tail 80 postgres sqlserver mongodb
docker compose down
```

Revisar y redactar logs antes de publicarlos. `down` conserva volúmenes; nunca usar
`down -v` para solucionar un arranque sin respaldo y autorización de Joseph.
Persistencia no sustituye backups. Si no existe el named pipe dockerDesktopLinuxEngine,
abrir/revisar Docker Desktop y su diagnóstico WSL; no declarar que los motores funcionan.

La verificación adicional en GitHub Actions usa un runner Ubuntu, contraseñas efímeras y los mismos
scripts. Un PASS allí no valida el Windows de Joseph ni las consultas de negocio o exportación.