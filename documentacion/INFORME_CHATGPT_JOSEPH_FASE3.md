# Informe para ChatGPT — Joseph, consolidación del núcleo PostgreSQL

**Fecha:** 23/10/2026, America/Costa_Rica. **Responsable:** Joseph. **Alcance:**
preparar el núcleo clínico del PR #2 para `main` mediante un PR nuevo, revisar CI y
el outbox, sin fusionar ni asumir los módulos de Joyce o Armando.

## A. Resumen ejecutivo

`main` contenía PR #1 (infraestructura), pero no las 12 tablas clínicas del PR #2.
Se creó `feature/joseph-core-main-integration` desde `main` y se reaplicaron los
cuatro commits originales de fase 2. Antes de corregir CI, el árbol coincidía
exactamente con la rama de infraestructura tras PR #2. El [PR #3](https://github.com/Pochonski/bases-ii-estudios-medicos/pull/3)
está abierto y en borrador hacia `main`; no hubo merge ni aprobación.

El modelo, particiones y fixture no se alteraron. El workflow escucha ahora PRs
contra `main` y valida un fallo SQL controlado. En Windows 11, un proyecto Compose
aislado pasó dos instalaciones y dos reinicios PostgreSQL. La primera CI del PR
quedó roja por `LASTEXITCODE` residual en el negativo SQL aun después de detectar
el error; se corrigió el cierre de esa prueba. La CI posterior del núcleo y la
infraestructura PASÓ en `ae3f1b9`. El gate FDW/BSON y el contrato operativo del
outbox siguen abiertos.

## B. Estado GitHub y commits

| Referencia | Estado verificado al inicio |
|---|---|
| `origin/main` | `0a42732a3cfc87a8b3a955b4c71cd894a5221ce8` (merge PR #1) |
| `origin/feature/joseph-infra-postgresql` | `84cb072a35b9f2d9c881124327a7ebf04f65403e` (merge PR #2) |
| PR #1 | MERGED a `main` |
| PR #2 | MERGED solo a rama de infraestructura |
| PR #3 | OPEN/DRAFT, base `main`, rama `feature/joseph-core-main-integration` |

Commits reaplicados: `0f3614a`→`344bb5b` (DDL/fixture), `295bf32`→`f93c0fb`
(pruebas/CI), `502f5fa`→`8322310` (marcadores/versiones), `41c98b4`→`29bb20c`
(documentación). Corrección de CI: `af34ed8` (filtro `main` y negativo SQL),
`ae3f1b9` (limpieza de código residual tras el negativo esperado). El commit
documental final y HEAD del PR se indican en el PR/informe de cierre. `main`
permaneció en `0a42732` durante esta sesión; no se hizo push a esa rama.

## C. Archivos del PR y cambio concreto

| Rutas | Cambio |
|---|---|
| `postgresql/01_esquemas.sql`, `02_tablas.sql`, `03_particiones.sql`, `06_datos_prueba.sql` | Traslado sin cambios del núcleo: 12 tablas, restricciones, particiones LIST y fixture ficticio |
| `pruebas/postgresql/01_estructura.sql` a `05_persistencia.sql`; `scripts/Test-PostgresqlCore.ps1` | Traslado sin cambios de pruebas y runner de bases efímeras |
| `.github/workflows/joseph-postgresql-core.yml` | Añade `main` al filtro de base PR y verifica propagación de SQL inválido |
| `README.md`, `docs/00_ESTADO_Y_FUENTES.md`, `06_PLAN_IMPLEMENTACION.md`, `07_PRUEBAS.md`, `10_DECISIONES_Y_PENDIENTES.md`, `11_BITACORA.md` | Estado de merges, estrategia, D-037/D-038, resultados y riesgos; entradas históricas preservadas |
| `docs/03_MODELO_DATOS.md`, `documentacion/INFORME_CHATGPT_JOSEPH_FASE2.md`, `JOSEPH_FASE2_POSTGRESQL.md`, evidencia fase 2 | Traslado histórico de PR #2; guía fase 2 ampliada con prueba local aislada |
| `documentacion/INFORME_CHATGPT_JOSEPH_FASE3.md`, `evidencias/registros/2026-10-23-joseph-core-main-ci.txt` | Informe nuevo y evidencia de fase 3 |

No se tocaron `compose.yaml`, imagen/base de motores, SQL Server, MongoDB, FDW,
worker, vistas API ni reportes de Armando. El delta con la rama de infraestructura
tras cherry-pick fue vacío; solo workflow/documentación son cambios nuevos.

## D. Estrategia de consolidación

`git merge-base origin/main origin/feature/joseph-infra-postgresql` devolvió
`20e9fe6`. `git diff --name-status` mostró exactamente los 21 archivos del
núcleo de fase 2. La rama nueva se creó desde `origin/main`; cuatro cherry-picks
lineales conservaron mensajes y autoría, con nuevos hashes normales, sin rebase
ni force push. `git diff --name-status origin/feature/joseph-infra-postgresql HEAD`
quedó vacío antes de la corrección CI. Así se preserva íntegro el árbol de PR #1
y se evita duplicar los cambios Docker/HAProxy. El PR #3 muestra el delta clínico
directamente frente a `main`.

## E. Modelo PostgreSQL conservado

Las doce tablas son `clinico.regiones`, `sucursales`, `pacientes`, `medicos`,
`usuarios_administrativos`, `citas`, `ordenes_medicas`, `tipos_estudio`,
`estudios`, `resultados_estudio`, `diagnosticos` e
`integracion.eventos_integracion`. `pacientes` conserva PK
`(id_paciente,codigo_region)` y particiones `LIST` SJ, AL, CA sin DEFAULT;
`citas` conserva la FK compuesta y su `id_sucursal` independiente para región de
atención. Se preservan FKs, NOT NULL, CHECK, UNIQUE e índices de fase 2.

El fixture instala 3 regiones/sucursales, 30 pacientes, 6 médicos, 2
administrativos, 30 citas, 25 órdenes, 4 tipos, 40 estudios, 30 resultados,
15 diagnósticos y cero eventos iniciales. Usa `example.invalid`, nombres
ficticios e IDs estables; 1001/AL se atiende en sucursal SJ. No hay datos reales.
**Corrección de modelo en esta fase: ninguna.** Alterar unicidad/revisión/outbox
unilateralmente cambiaría una interfaz que Joyce debe revisar.

## F. CI/CD

El workflow conservó filtros por `postgresql/**`, `pruebas/postgresql/**`, el
runner y el propio YAML, y agregó `main` a las bases de PR. CI genera secretos
efímeros enmascarados, construye el PostgreSQL del proyecto, inicia solo PG,
ejecuta el runner `-Repeat 2 -IncludePersistence`, guarda artifacts 14 días y
termina con `docker compose down` sin `-v`. El PR #3 disparó de verdad ese job y
la regresión heredada de infraestructura (Windows ACL, Ubuntu base/localhost).

Un paso nuevo ejecuta `psql -v ON_ERROR_STOP=1` sobre una tabla inexistente y
exige que `Invoke-ProjectCompose` lance un error por código no cero. El primer
[run 40028582907](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40028582907)
FALLÓ: registró el SQL error y el mensaje PASS del negativo, pero el runner
`pwsh` terminó con `LASTEXITCODE=1` residual; se omitieron las pruebas clínicas.
`ae3f1b9` pone a cero **solo** ese código tras reconocer el error esperado.
Los errores SQL no capturados del runner principal siguen produciendo excepción
y job fallido. La [CI corregida](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40028827502)
PASÓ el negativo y el runner clínico en `ae3f1b9`; el artifact incluye
`sql-error.txt`, `nucleo.txt` y `resumen.txt`.

## G. Pruebas y evidencia

**Windows 11 local:** Docker Desktop `desktop-linux`, Engine 29.8.0, kernel
`6.18.33.2-microsoft-standard-WSL2`; imagen PostgreSQL del proyecto, servidor
16.15. `Test-Infra.ps1 -StaticOnly` PASÓ con proyecto aislado. Se ejecutó:

```powershell
$deploy = @{ ComposeFile=@('compose.yaml','.tmp/joseph-core-pr3-local.compose.yaml');
             EnvFile=@('.env'); ProjectName='joseph-core-pr3-local' }
./scripts/Invoke-Compose.ps1 @deploy -Command @('up','-d','--wait','--wait-timeout','180','postgres')
./scripts/Test-PostgresqlCore.ps1 @deploy -Repeat 2 -IncludePersistence
./scripts/Invoke-Compose.ps1 @deploy -Command @('down')
```

El overlay temporal asignó una red propia; no publicó puertos. **PASARON** dos
instalaciones desde `template0`, 12 tablas/3 particiones, fixture exacto,
inserción válida y seis rechazos de integridad, FK compuesta, `tableoid`
10/10/10, `EXPLAIN` solo `pacientes_al`, COMMIT/ROLLBACK locales y dos restart
del mismo contenedor/volumen PG. Las dos bases sintéticas se eliminaron; el
volumen de prueba se conservó tras retirar contenedor/red. IDs de los cuatro
contenedores compartidos idénticos antes/después. No se reinició el PostgreSQL
compartido. P12 es **parcial**: no recreación, restauración ni otros motores.

**CI:** la primera regresión de infraestructura
[40028582691](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40028582691)
PASÓ sus tres jobs; el primer núcleo `40028582907` FALLÓ como se indica arriba.
La CI corregida del núcleo [40028827502](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40028827502)
PASÓ; la regresión [40028827437](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40028827437)
PASÓ Ubuntu base/localhost y Windows ACL. Artifacts descargados: head PR
`ae3f1b9e0222169b4c10b035e72f5a8e019fe50e`, checkout de PR
`a5f4175bbc2ad10c78d5d6676f4c184b56cd042b`, Docker 28.0.4,
Compose 2.38.2, PostgreSQL 16.15, PowerShell 7.6.6, kernel Ubuntu
`6.8.0-1064-azure`; Windows Server 2022/PowerShell 7.6.7 para ACL. Los
detalles constan en `evidencias/registros/2026-10-23-joseph-core-main-ci.txt`.
Windows local y
Ubuntu CI se reportan por separado. No se ejecutaron consultas FDW remotas,
pruebas BSON ni exportación.

## H. Revisión del outbox: comportamiento y opciones

`eventos_integracion` tiene UUID PK y FK solo a `estudios.id_estudio`. Se pueden
insertar dos UUID distintos para el mismo `(id_estudio,revision,tipo_evento)`;
la revisión del evento puede no corresponder a la revisión actual de
`resultados_estudio` o incluso no existir resultado. `revision > 0` no impide
que un UPDATE de resultado retroceda la revisión. Nada en el DDL obliga a un
escritor futuro a insertar un evento junto con un resultado. El test demuestra
atomicidad solo para **la transacción que él ejecuta**.

Con dos escritores concurrentes, la revisión debe asignarse bajo bloqueo de la
fila u optimistic locking; UUIDs distintos no serializan eventos lógicos. Un
worker puede recibir eventos fuera de orden. Si MongoDB guarda el documento y
PG falla antes de marcar PROCESADO, el reintento debe ser idempotente y no
decrementar versión. El índice único Mongo en `id_estudio` evita duplicar
documentos, pero por sí solo no previene reemplazo con revisión antigua.
Conservar solo un resultado mutable tampoco permite una FK simple a cada
revisión histórica del evento.

Opciones para decisión conjunta con Joyce:

1. **Función de escritura única en PostgreSQL** que actualice resultado y evento
   en una transacción, con DML directo restringido y revisión controlada por
   bloqueo/versión esperada. Hacer explícita la cuenta de servicio y probar
   permisos positivos/negativos.
2. **Trigger** sobre cambios de resultado para emitir evento, con política
   definida para corrección, cancelación, firmas y revisiones. Reduce omisiones
   por DML directo, pero añade efectos implícitos y requiere pruebas de rollback.
3. **Transacción desde aplicación más UNIQUE lógica** en evento. Permite control
   en código, pero el DML directo puede omitir la emisión. La clave candidata
   `(id_estudio,revision,tipo_evento)` debe acordarse: quizá hay eventos distintos
   legítimos en una revisión. Para exportar versiones históricas se necesitaría
   snapshot/payload inmutable o tabla de revisiones, no una FK al resultado mutable.

Joyce debe acordar semántica del evento, revisión monotónica, payload histórico
frente a lectura vigente, worker único o locking, idempotencia Mongo/BSON,
índice único y recuperación. **No** se implementó trigger, función, worker ni
cambio de contrato. No hay sincronización MongoDB ni transacción ACID global.

## I. Hallazgos y riesgos

| Severidad | Hallazgo | Efecto y estado |
|---|---|---|
| Crítico para integración | FDW TDS remoto y `mongo_fdw` lectura/escritura/BSON no acreditados | Gate 2 abierto; depende de objetos/cuentas/fixture de Joyce y pruebas reales |
| Alto | Escritura de resultado puede omitir outbox; revisión no vinculada ni monotónica | Puede perder exportación o enviar versión incorrecta; D-038 pendiente de Joyce |
| Alto | Duplicados lógicos/concurrencia/reintentos Mongo | Requiere política de idempotencia, clave y prueba de fallos antes de usar worker |
| Medio | P12 cubre solo restart PG del mismo contenedor | No acredita recreación, restauración ni persistencia de otros motores |
| Bajo, corregido | Negativo SQL dejó `LASTEXITCODE=1` tras captura esperada | Run inicial rojo; corrección puntual y regresión CI |
| Medio | Estabilidad de Docker Desktop Windows tras reinicio completo | La sesión local pasó, pero no prueba un arranque posterior de Windows |

## J. Recomendación para auditoría

1. **¿Listo para revisión final?** Sí, sujeto a confirmar la CI del commit
   documental final y revisar artifacts/alcance del PR. Sigue en borrador.
2. **¿Bloqueo técnico para fusionar?** No se detecta uno para trasladar el
   núcleo **aislado** si CI pasa; el gate FDW/BSON y el outbox bloquean su uso
   como integración funcional. Joyce debe revisar el contrato antes de tratar
   el esquema como interfaz estable.
3. **¿Qué necesita Joyce?** Confirmar esquemas, `id_estudio`, semántica y clave
   de evento, revisiones, política de escritura y reintentos, BSON/índice Mongo;
   aportar vista/base/cuenta/fixture de facturación para P01.
4. **¿Qué falta a Joseph?** Consulta FDW real con Joyce, validación de cuenta y
   permisos negativos, acuerdo de outbox y traspaso comprobado; además de
   persistencia/backup más amplia si se requiere P12 completo.
5. **¿Qué comprobar antes de autorizar merge?** Head/base exactos, diff limitado,
   cuatro checks verdes en el SHA final, artifact de dos bases/restart,
   propagación SQL, secretos ausentes, PR aún DRAFT, y pendientes D-038 visibles.

No fusionar ni aprobar sin autorización nueva de Joseph.
