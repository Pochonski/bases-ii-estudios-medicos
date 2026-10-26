# Guía de cierre, validación y empaquetado

Responsable: Joseph, 26/10/2026. Esta guía prepara la revisión de los tres módulos.
No autoriza fusiones ni sustituye la revisión de Joyce o Armando.

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
la salida diagnóstica sin secretos. En esta sesión `desktop-linux` estaba
seleccionado, `com.docker.service` detenido y la app Docker Desktop no tenía
proceso visible. Abrir Docker Desktop de forma ordinaria, esperar que indique
motor Linux activo y repetir `docker version` antes de ejecutar P18. El arranque
y su estabilidad en la PC de Joseph siguen pendientes de prueba.

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
pwsh -NoProfile -File ./scripts/Test-Entrega.ps1 -DesdeCero -EvidencePath .tmp/entrega-local.txt
pwsh -NoProfile -File ./scripts/Test-Entrega.ps1 -DesdeCero -RunDemo -DemoSinPausa
```

La primera orden ejecuta P18, núcleo clínico, P01–P17, INT-04/05, permisos,
concurrencia del outbox, restauración en bases nuevas y P12 tras `restart`.
La prueba MongoDB de restauración usa EJSON estricto; no equivale a un plan
operativo de `mongodump/mongorestore`. P12 y restauración son pruebas distintas.
Si alguna falla, conservar su salida y el run; no transformar fallos en PASS.

## 4. Evidencia y revisión antes de integrar

Para cada PR verificar HEAD, BASE, diff, checks del SHA definitivo y artifacts:

```powershell
gh pr view 3 --json state,isDraft,headRefOid,baseRefName,mergeable,statusCheckRollup
gh pr view 4 --json state,isDraft,headRefOid,baseRefName,mergeable,statusCheckRollup
gh pr view 7 --json state,isDraft,headRefOid,baseRefName,mergeable,statusCheckRollup
gh pr view 5 --json state,isDraft,headRefOid,baseRefName,mergeable,statusCheckRollup
```

Secuencia propuesta, **solo después de autorización humana de fusión**:

1. PR #3 → `main`; verificar núcleo y CI.
2. Cambiar base de #4 a `main`, comprobar diff sin duplicación, ejecutar CI y
   fusionar #4 → `main`.
3. Revisar con Joyce y Armando el PR #7, fusionarlo en la rama de Joyce y comprobar
   que #5 incorpora sus commits. Sin esa revisión, #7 permanece en borrador.
4. Cambiar base de #5 a `main`, comprobar diff, secretos, contratos, permisos y
   todos los checks del HEAD; fusionar #5 → `main`.
5. Repetir P18 y las cuatro regresiones sobre el `main` final, y validar Windows.

El cambio de base debe hacerse solo en el momento indicado; no reescribir
historial compartido ni usar `push --force`.

Comandos de referencia **para después de recibir autorización explícita**, nunca
como parte de esta revisión:

```powershell
gh pr merge 3 --merge
gh pr edit 4 --base main
# Revisar diff y checks nuevos de #4 antes del siguiente comando.
gh pr merge 4 --merge
# Revisar/aceptar #7 con Joyce y Armando; entonces incorporarlo a la rama de Joyce.
gh pr merge 7 --merge
gh pr edit 5 --base main
# Revisar diff y checks nuevos de #5 antes del siguiente comando.
gh pr merge 5 --merge
```

La estrategia de merge commit conserva la ancestralidad de los PR apilados.
Después de cada base nueva, comprobar que el diff solo muestre su módulo y que
GitHub ejecute los checks para la combinación actual; detenerse ante conflictos.

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
