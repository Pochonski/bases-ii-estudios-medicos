# Guía de cierre, validación y empaquetado

Responsable: Joseph, 26/10/2026. Esta guía prepara la revisión de los tres módulos.
**Estado post-merge:** `main` contiene el código probado en `3d50894` y los PR #3/#4/#5/#7 ya integrados. No repetir fusiones ni atribuir revisión de Joyce/Armando no verificada.

**Estado de integración verificado el 26/10/2026:** último commit de código probado en [`3d50894`](https://github.com/Pochonski/bases-ii-estudios-medicos/commit/3d50894c9e566d44a2190d6d115331983127f5bd); PR #3, #4 y #5 fusionados en `main`, PR #7 fusionado en la rama de Joyce e incorporado al merge de #5. No quedan PR de integración abiertos. **Cuatro workflows de `main`: siete trabajos de siete aprobados** en ese mismo SHA: [Infraestructura (3/3)](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40328045185) · [Núcleo PostgreSQL (1/1)](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40328099902) · [TDS FDW (2/2)](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40328122775) · [Integración de tres motores (1/1)](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40328144203).

**Evidencia Ubuntu CI:** P18 desde volúmenes efímeros, P01–P18, INT-01–INT-05, segmentación, FDW reales, permisos API, dos exportadores concurrentes, restauración PG/SQL Server/MongoDB mediante EJSON estricto, P12 tras reinicio y nueve segmentos automáticos de demo.

**Validación local posterior:** Windows 11 pasó P18 integral sobre `origin/main` `2840743917364d137c5298b6456fef15862b3a92`, con Docker Desktop Linux Engine/WSL 2. [Informe, hashes y registro](../evidencias/2026-10-26-validacion-windows.md). Esa prueba no pertenece al nuevo commit documental. Faltan capturas reales, video narrado de 5–8 min y entrega Moodle; confirmar allí el cierre indicado como 28/10/2026 a las 23:59. Límites: TDS `table_name` con igualdad DECIMAL incorrecta (usar `query` probada); TLS/CA no listo para producción; Mongo EJSON no equivale a `mongorestore`; el outbox es eventual y su candado no cubre DML directo fuera del procedimiento.

## 1. Estado y condiciones previas

- El enunciado original facilitado localmente indica **28/10/2026 a las 23:59** como
  entrega. Dice «martes», aunque el 28/10/2026 es miércoles: confirmar el cierre
  efectivo en Moodle. No publicar ese PDF original en GitHub.
- En Windows 11 se necesitan PowerShell 7, Docker Desktop con motor Linux/WSL 2,
  espacio suficiente para tres imágenes y secretos locales. La CI Ubuntu verifica
  funcionalidad en su runner; no acredita estabilidad del equipo Windows.
- Revisar `git status --short` antes de ejecutar. El PDF original y cualquier
  archivo en `secrets/` o `.tmp/` no forman parte de la entrega.

## 2. Diagnóstico no destructivo en Windows

Desde la raíz del repositorio, en PowerShell 7:

```powershell
pwsh --version
docker version
docker compose version
docker info --format '{{.OSType}} {{.OperatingSystem}} {{.KernelVersion}}'
pwsh -NoProfile -File ./scripts/Test-Entrega.ps1 -StaticOnly
```

Si `docker version` no muestra servidor Linux, detener las pruebas de motores;
no borrar volúmenes, reinstalar Docker ni cambiar WSL automáticamente. Guardar
la salida diagnóstica sin secretos. El diagnóstico anterior de daemon ausente
fue **histórico**: el 26/10 el servidor respondió como `linux/amd64`, Docker
Engine 29.8.0, kernel WSL 2 `6.18.33.2-microsoft-standard-WSL2`, y P18 pasó
en la PC de Joseph. Para una nueva sesión, comprobar otra vez el estado actual.

## 3. Instalación y validación

La instalación normal crea o actualiza estructura y conserva datos existentes:

```powershell
pwsh -NoProfile -File ./scripts/Install-JoyceModulos.ps1
```

La carga inicial de datos ficticios es una acción separada y se rechaza si hay
filas en las tablas verificadas:

```powershell
pwsh -NoProfile -File ./scripts/Install-JoyceModulos.ps1 -LoadInitialData
```

La validación integral se ejecuta **solo** en un proyecto Compose efímero creado
por la prueba. Comprueba nombre, red, volúmenes, secretos y ausencia de puertos
publicados antes de iniciar; después retira únicamente los recursos de ese
proyecto. No usar `docker compose down --volumes` sobre `estudios-medicos`.

```powershell
pwsh -NoProfile -File ./scripts/Test-Entrega.ps1 -DesdeCero -RunDemo -DemoSinPausa -EvidencePath .tmp/entrega-local.txt
```

La orden ejecuta P18, núcleo clínico, P01–P17, INT-04/05, permisos,
concurrencia del outbox, restauración en bases nuevas y P12 tras `restart`.
La prueba MongoDB de restauración usa EJSON estricto; no equivale a un plan
operativo de `mongodump/mongorestore`. P12 y restauración son pruebas distintas.
Si alguna falla, conservar su salida y el run; no transformar fallos en PASS.

## 4. Verificación después de integrar

Los cuatro PR están fusionados; **no volver a ejecutar comandos de merge**.
La CI de `main` corresponde al SHA `3d50894c9e566d44a2190d6d115331983127f5bd` y finalizó 7/7:
[Infraestructura (3/3)](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40328045185) · [Núcleo PostgreSQL (1/1)](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40328099902) · [TDS FDW (2/2)](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40328122775) · [Integración de tres motores (1/1)](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40328144203).

Validación del equipo Windows, con repositorio actualizado a `origin/main`
sin descartar cambios locales, y Docker Desktop iniciado:

```powershell
git rev-parse HEAD
docker version
docker compose version
docker info --format '{{.OSType}} {{.OperatingSystem}} {{.KernelVersion}}'
pwsh -NoProfile -File ./scripts/Test-Entrega.ps1 -StaticOnly
```

Solo si `docker info` confirma Linux Engine y la validación estática pasa,
ejecutar en el proyecto efímero (no sobre volúmenes compartidos):

```powershell
pwsh -NoProfile -File ./scripts/Test-Entrega.ps1 -DesdeCero -RunDemo -DemoSinPausa -EvidencePath .tmp/entrega-local.txt
```

La ejecución del 26/10 **ya pasó** en Windows 11 sobre el SHA `2840743`:
[registro completo](../evidencias/registros/2026-10-26-joseph-validacion-integrada-windows.txt)
y [resumen auditable](../evidencias/2026-10-26-validacion-windows.md).
No repetir la suite solo para producir evidencia documental; registrar un nuevo
SHA y resultado si se ejecuta otra vez por una razón concreta.
No ejecutar manualmente `docker compose down --volumes` sobre `estudios-medicos`.

## 5. Video y entrega

`video/GUION.md` cubre las cinco operaciones, segmentación horizontal/vertical,
roles, mapa de conexiones y demostraciones en tres motores. El video debe durar
5–8 minutos y estar narrado por los integrantes conforme al enunciado. La
participación efectiva de Armando y cualquier reemplazo requieren decisión del
grupo; no atribuirle revisión o narración que no realizó.

Después de integrar y validar `main`, preparar un ZIP solo con archivos
versionados del commit final:

```powershell
git fetch origin
git rev-parse origin/main
git archive --format=zip --output .tmp/entrega-main.zip origin/main
```

Antes de subir a Moodle: revisar el contenido del ZIP, confirmar que no incluye
secretos ni el enunciado original, incluir documentación, referencias y enlaces
o archivos de evidencia pertinentes al SHA final, adjuntar el video y verificar
la fecha de cierre en Moodle. Registrar el SHA de `main`, la duración del video
y el acuse de entrega. Esta guía no afirma que el video esté grabado ni que Moodle
haya recibido archivos.
