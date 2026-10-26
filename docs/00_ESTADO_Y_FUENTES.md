# Estado real, fuentes y convención de certeza

## Estado vigente confirmado — 26/10/2026 (D-049)

**Estado verificado el 26/10/2026:** rama `main` en [`3d50894`](https://github.com/Pochonski/bases-ii-estudios-medicos/commit/3d50894c9e566d44a2190d6d115331983127f5bd); PR #3, #4 y #5 fusionados en `main`, PR #7 fusionado en la rama de Joyce e incorporado al merge de #5. No quedan PR de integración abiertos. **Cuatro workflows de `main`: siete trabajos de siete aprobados** en ese mismo SHA: [Infraestructura (3/3)](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40328045185) · [Núcleo PostgreSQL (1/1)](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40328099902) · [TDS FDW (2/2)](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40328122775) · [Integración de tres motores (1/1)](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40328144203).

**Evidencia Ubuntu CI:** P18 desde volúmenes efímeros, P01–P18, INT-01–INT-05, segmentación, FDW reales, permisos API, dos exportadores concurrentes, restauración PG/SQL Server/MongoDB mediante EJSON estricto, P12 tras reinicio y nueve segmentos automáticos de demo.

**No confundir con entrega concluida:** Docker Desktop abierto en Windows según Joseph, pero el motor Linux y P18 en esa PC aún no están verificados; faltan capturas reales, video narrado de 5–8 min y entrega Moodle. El documento del curso indica 28/10/2026 a las 23:59, pendiente de confirmar en Moodle. Límites: TDS `table_name` con igualdad DECIMAL incorrecta (usar `query` probada); TLS/CA no listo para producción; Mongo EJSON no equivale a `mongorestore`; candado outbox no cubre DML directo fuera del procedimiento.

> Las entradas de cronología que siguen reflejan fechas pasadas: menciones a PR
> no fusionados o CI pendiente son **históricas**, no el estado actual.

**Corte funcional: 21/10/2026 · Zona horaria: America/Costa_Rica.** El corte inicial siguiente corresponde a planificación. La actualización vigente al final registra los archivos y pruebas realmente creados.

## Jerarquía de autoridad

1. **FUENTE CURSO:** documento original «Segundo Proyecto — Sistema de Gestión de Estudios Médicos Distribuido» (Bases de Datos II, ITCR; 6 páginas en el PDF local facilitado el 26/10/2026), entregado al equipo por el curso. El archivo íntegro no se publica aquí porque el repositorio es público; consúltese mediante Moodle o el grupo. Sus requisitos priman. `docs/01_REQUISITOS.md` resume requisitos con secciones/páginas como referencias.
2. **DECISIÓN GRUPO:** decisiones explícitas de conversación: despliegue en una PC; planificación completa antes de distribuir; Joseph/Joyce más trabajo; Armando implementa al final.
3. **DISEÑO PROPUESTO:** estructura de tablas, campos, nombres, mecanismos de sincronización y porcentajes de reparto diseñados en la conversación. Son baseline para trabajar, pero pueden ajustarse con aprobación.
4. **VERIFICACIÓN PENDIENTE:** compatibilidad, conectores, recursos, evaluación de Moodle y aceptación del despliegue en una PC.

Leyenda en documentos: **[CURSO]** = texto exigido; **[GRUPO]** = acordado; **[PROPUESTA]** = diseño; **[PENDIENTE]** = falta prueba o confirmación.

## Estado por componente al corte inicial (histórico)

| Elemento | Estado al corte | Fuente |
|---|---|---|
| Enunciado y rúbrica textual | Recopilado | [CURSO] |
| Una sola PC Windows 11, Ryzen 5 5600G, 16 GB, RTX 5060 | Decidido | [GRUPO] |
| Tres contenedores Docker con WSL 2 | Arquitectura elegida, no instalada | [GRUPO]/[PROPUESTA] |
| PostgreSQL 16 / SQL Server 2022 Developer / MongoDB 8.0 | Preselección, no fijación final | [PROPUESTA] |
| `tds_fdw`, `mongo_fdw` y versiones concretas | No compilados ni probados | [PENDIENTE] |
| Modelos de tablas y colecciones | Documentados, no implementados | [PROPUESTA] |
| Fragmentación horizontal/vertical | Diseño, no evidencia | [CURSO]/[PROPUESTA] |
| Consultas FDW, sincronización y vistas API | Diseño, no ejecutadas | [CURSO]/[PROPUESTA] |
| Roles internos y externos | Nombres del curso, políticas propuestas | [CURSO]/[PROPUESTA] |
| Reparto 43/40/17 | Estimación orientativa tras decisión grupal | [GRUPO]/[PROPUESTA] |
| Pruebas P01–P13 | Planificadas, todas sin ejecutar | [PROPUESTA] |
| Video y entrega | Planificados, no producidos | [CURSO]/[PROPUESTA] |

## Ambigüedades que deben mantenerse visibles

- En el enunciado hay mención de `mongo_fdw` **o integración intermedia** en la descripción de PostgreSQL, pero otra sección exige `mongo_fdw`: pedir aclaración antes de sustituirlo.
- El título habla de sistema distribuido y tres servidores, pero **no exige literalmente tres PCs físicas**. El grupo eligió una PC con contenedores; confirmar aceptación docente si es necesario. No afirmar distribución física.
- El enunciado dice **«Martes 28 de octubre 2026»**, pero el **28/10/2026 es miércoles**. Confirmar fecha/hora que muestre Moodle. No corregir unilateralmente la fecha del enunciado.
- El enunciado da ejemplos ilustrativos de tablas y documentos que no constituyen por sí mismos modelos cerrados. Lo añadido aquí es diseño del equipo.
- El outbox, el worker, los mecanismos de recuperación y las pruebas de fallos son **mejoras propuestas**; no presentarlos como requisitos literales.
- SQL Server representa fuentes externas simuladas; no se conectará de verdad con aseguradoras ni ministerios.

## Actualización del estado

Cambiar a «implementado» solamente con archivos revisables; cambiar a «probado» únicamente con comandos y resultados guardados en `evidencias/`. El autor debe anotar fecha y hash de commit cuando sea posible. Registrar novedades en `docs/11_BITACORA.md`.

## Actualización vigente — 22/10/2026, Joseph (D-025 a D-028)

Implementación autorizada por Joseph en su sesión; solo su alcance. El corte inicial arriba es histórico.

| Componente | Estado comprobable |
|---|---|
| Clonación/main/rama personal | IMPLEMENTADO Y PROBADO: main limpio 630cca6, rama feature/joseph-infra-postgresql |
| Compose, secretos, scripts PowerShell | IMPLEMENTADO Y PROBADO en validación estática local; ver evidencias/registros/2026-10-22-joseph-local.txt |
| Imagen con tds_fdw/mongo_fdw | IMPLEMENTADO, NO PROBADO localmente: build detenido por ausencia del daemon |
| Tres motores, healthchecks y persistencia | IMPLEMENTADO, NO PROBADO localmente |
| Preparación externo.ft_estado_facturacion | IMPLEMENTADO, NO PROBADO; perfil NOLOGIN, sin datos remotos simulados |
| P01 / contrato SQL Server | BLOQUEADO POR DEPENDENCIA de Joyce (vista, base, cuenta, tipos y fixture) |
| Esquema clínico / particiones / outbox / dataset | PENDIENTE: respetar gate de conectores de docs/06 |
| Mongo FDW funcional / exportación | PENDIENTE de pruebas conjuntas con Joyce; no reemplazado por driver |
| Vistas API, roles externos y agregaciones | PENDIENTE, corresponden a Armando |

Los candidatos están fijados por digest/hash para repetir el spike, con validación funcional pendiente.
No hay aceptación global P01–P18. Ver documentación de ejecución y reporte de esta sesión.

## Cierre verificado — 22/10/2026, Joseph

[CI 39747806912](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/39747806912)
PASA en SHA 89d0754, Ubuntu22/kernel 6.8.0-1070-azure:
build de ambos FDW, tres motores saludables, consultas autenticadas, CREATE EXTENSION/LOAD
y persistencia PostgreSQL tras reinicio (P12 parcial).
Windows sigue sin motor Docker disponible; no se acreditan consultas FDW remotas, BSON/escritura,
P01, P14 ni el outbox.
Evidencia: evidencias/registros/2026-10-22-joseph-ci-exito.txt.
Informe: documentacion/INFORME_CHATGPT_JOSEPH_FASE1.md. PR #1 en borrador, sin merge.

## Correcciones de auditoría en curso — 22/10/2026, Joseph

H1 (ACL) e H3 (.env) corregidos y probados localmente; H2 selección explícita/ambiental probada en estático.
Test-Persistence usa restart+inspect, conserva selección y comprueba contenedor/puertos/volumen/fila.
Su ejecución real nueva está pendiente de CI: daemon Windows ausente. No ampliar el alcance de P12.
CI del head auditado 612d07d confirmada en 39753627026. La nueva CI se identificará al terminar.
Ver D-030..D-033, guía Windows y evidencia 2026-10-22-joseph-auditoria-windows.txt.
Las dependencias de Joyce y el gate de consultas FDW/BSON no cambiaron.

## Cierre de correcciones de auditoría — 22/10/2026, Joseph

CI [39759092391](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/39759092391)
PASA sobre head a801c88004a7943b96e0355fbaea11ff734c683e: ACL Windows Server2022 y dos variantes
Ubuntu22 (base/localhost). Lectura de secretos por UID y P12 parcial PASAN; en overlay se conserva
127.0.0.1:5432 junto con la fila, ID y volumen PG. Marcadores eliminados al pasar.
Artifacts depurados disponibles 14 días; evidencia versionada: evidencias/registros/2026-10-22-joseph-auditoria-ci.txt.
H1/H3 y selección estática probados también en Windows local; daemon sigue ausente.
No se acredita recreación, SQL Server/MongoDB persistentes, restauración, FDW remoto, BSON o login propio.
Informe: documentacion/INFORME_CORRECCIONES_AUDITORIA_PR1.md.
Commits correctivos aa1ae16/a801c88; cierre posterior solo documental. PR #1 en borrador, sin aprobación/merge.

## Validación Windows posterior — 22/10/2026, Joseph (D-034)

El estado anterior «daemon ausente» es histórico. Docker Desktop 4.91.0/Engine 29.8.0
volvió a funcionar tras retirar del uso, conservándolas por renombrado, dos carpetas de
sockets de ejecución dañados. Windows 11/WSL2 kernel efectivo
`6.18.33.2-microsoft-standard-WSL2`. El build de ambos FDW, tres healthchecks, consultas
autenticadas y lectura de secretos por UID PASAN en esta PC. PostgreSQL y SQL Server
respondieron además a clientes nativos de Windows vía puertos localhost.

El overlay anterior no publicaba puertos activos con los tres motores unidos solo a la red
interna. El nuevo `port-gateway` preserva los motores en `medical-network` interna y publica
los tres puertos desde una red bridge adicional solo en `127.0.0.1`. Snapshot y sonda TCP
verifican los puertos efectivos; selección equivocada de Compose se rechaza. P12 PASA
**parcialmente** también en Windows: una fila PostgreSQL tras `restart`, con ID, volumen,
gateway y puertos conservados. La prueba no acredita persistencia de SQL Server/MongoDB,
recreación ni restauración. P01/P17 remotos, Mongo BSON, cuentas y objetos de Joyce siguen
pendientes; gate de conectores y DDL clínico continúan abiertos.

Evidencia: `evidencias/registros/2026-10-22-joseph-despliegue-windows.txt`.
Informe: `documentacion/INFORME_WINDOWS_Y_PUERTOS_JOSEPH.md`.

## Revisión menor de PR #1 — 22/10/2026, Joseph (D-035)

El gateway añade una sonda `/ready` **interna** que rechaza backends no disponibles,
además de la comprobación TCP del host. La salud Docker del gateway depende ahora de
PostgreSQL, SQL Server y MongoDB. El workflow incluye `docker/port-gateway/**` en sus
filtros y ejecuta un stop/start controlado de PostgreSQL solo en su proyecto
efímero localhost. Windows local verificó sintaxis, endpoint sano, consultas runtime y
bindings 127.0.0.1 tras recrear solo el gateway; no se interrumpió la base local.
El primer intento con `pause` falló en CI 39811585204: HAProxy mantuvo el backend UP
porque el socket TCP siguió abierto. Se sustituyó por `stop/start`; la CI
[39812197292](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/39812197292)
PASÓ en `ee5ce97`: tres jobs, caída/recuperación del backend en localhost y P12 parcial.
Evidencia: `evidencias/registros/2026-10-22-joseph-gateway-backend-ci.txt`.
El daemon local volvió a quedar inaccesible después de esas pruebas Windows; no se
acredita estabilidad tras reinicio de Desktop/Windows. No altera el resultado CI.
No cambian los contratos, P12 parcial ni el gate FDW/BSON aún abierto.

## Núcleo PostgreSQL aislado — 22/10/2026, Joseph (D-036)

Joseph autorizó adelantar solo sus 12 tablas clínicas/outbox y pruebas en el PR #2,
basado en la rama del PR #1. Los scripts SQL, particiones LIST SJ/AL/CA, fixture
ficticio y runner sobre bases vacías están implementados. En CI Ubuntu22 del código
`295bf32`, la primera ejecución [39878097819](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/39878097819)
PASÓ dos instalaciones, integridad, `tableoid`/`EXPLAIN`, COMMIT/ROLLBACK locales y
registros PostgreSQL tras `restart`. Se conserva el artifact y un extracto versionado.
El código `502f5fa` añade marcadores explícitos al artifact y versión efectiva PG;
[CI 39878319168](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/39878319168)
también PASÓ dos bases vacías y dos restart de PostgreSQL 16.15. Evidencia duradera:
`evidencias/registros/2026-10-22-joseph-postgresql-core-ci.txt`.

**Windows local:** `docker info` falló por ausencia de `dockerDesktopLinuxEngine` durante
esta fase; SQL/restart NO EJECUTADOS aquí. No se cambiaron WSL, Docker ni volúmenes.
**Integración:** P01, Mongo BSON/lectura/escritura, cuentas y objetos Joyce siguen
pendientes. El outbox no tiene worker ni exportación; P04/P13 solo prueban atomicidad
PostgreSQL. No hay aprobación del gate FDW ni traspaso de interfaz a Armando.

## Consolidación propuesta — 23/10/2026, Joseph (D-037/D-038)

PR #1 fue fusionado en `main` como `0a42732`; PR #2 fue fusionado en la rama de
infraestructura como `84cb072`. Al iniciar la sesión, `main` no contenía el núcleo:
el diff entre ambos árboles era exactamente los 21 archivos clínicos/documentales
de fase 2. Joseph autorizó un PR nuevo; `feature/joseph-core-main-integration`
parte del `main` actualizado y reaplica los cuatro commits originales sin modificar
infraestructura. [PR #3](https://github.com/Pochonski/bases-ii-estudios-medicos/pull/3)
permanece abierto y en borrador. No se ha fusionado ni aprobado.

El workflow del núcleo escucha ahora PRs contra `main`; su prueba negativa de SQL
separa el error esperado de un fallo real. En Windows 11, Docker Desktop respondió
durante esta sesión: un proyecto Compose **aislado**, sin puertos host, pasó dos
instalaciones, integridad, `tableoid`/`EXPLAIN`, COMMIT/ROLLBACK y restart parcial PG.
El proyecto compartido conservó sus IDs; el contenedor de prueba se retiró y su
volumen se conservó. La primera CI de PR #3 falló tras detectar SQL inválido porque
PowerShell retuvo `LASTEXITCODE=1`; `ae3f1b9` corrige solo el cierre de ese negativo.
La [CI del núcleo](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40028827502)
y la [regresión de infraestructura](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40028827437)
pasaron en el head `ae3f1b9`; los artifacts registran el SHA y el checkout.
La CI del commit documental final debe verificarse por separado.
Tras esa verificación se reforzó el negativo en `6e9d1bb`: el paso SQL falla
realmente, con `continue-on-error` **solo en ese paso**; la aserción siguiente
exige su `outcome=failure`. El [run del núcleo](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40029751371)
PASÓ y el artifact registra la aserción. Los scripts clínicos no tienen esa
excepción. La CI del cierre documental posterior también debe verificarse.

El outbox admite duplicados lógicos y eventos con revisión sin correspondencia al
resultado; tampoco obliga a que toda escritura clínica emita evento. D-038 documenta
alternativas pendientes de Joyce. No se cambió DDL ni se afirma exportación, FDW
remoto o transacción global.

## Spike TDS de Joseph — 24/10/2026 (D-039)

Al verificar GitHub, `main` seguía en `0a42732`; [PR #3](https://github.com/Pochonski/bases-ii-estudios-medicos/pull/3)
continuaba OPEN/DRAFT con HEAD `f46dd9b`. No había módulos de Joyce en el árbol ni
PR abiertos de ella. Se abrió [PR #4](https://github.com/Pochonski/bases-ii-estudios-medicos/pull/4),
también en borrador, desde `feature/joseph-tds-fdw-spike` hacia la rama del PR #3.
Solo agrega infraestructura de **prueba aislada** para consultar una vista
temporal SQL Server con `tds_fdw`; no cambia el esquema clínico, contratos de
Joyce, API de Armando ni `main`. La guía y el estado verificable están en
`documentacion/JOSEPH_FASE4_TDS_FDW.md` y `docs/07_PRUEBAS.md`.

La configuración estática pasó en Windows local. El daemon Linux de Docker
Desktop no estaba disponible (pipe ausente, servicio detenido), por lo que las
consultas remotas locales quedaron NO EJECUTADAS; la CI se revisa por separado.
Incluso si el spike pasa, P01/P17 con vista, cuenta y fixture **definitivos** de
Joyce y el gate MongoDB seguirán pendientes.

## Actualización — 25/10/2026, Joyce (D-041)

| Componente | Estado comprobable |
|---|---|
| SQL Server: tablas, fragmentación vertical, procedimientos, vista contractual, login de lectura | IMPLEMENTADO Y PROBADO en Windows 11 local (P15, P16, permisos) |
| PostgreSQL → SQL Server con objetos reales de Joyce | PROBADO localmente (P01, P16b) con login propio `usr_fdw_pg_mssql` |
| MongoDB: colección, validador, índice único, usuario de servicio | IMPLEMENTADO Y PROBADO |
| `mongo_fdw` lectura/INSERT/UPDATE y tipos BSON | PROBADO: el gate BSON queda cerrado para esta versión |
| Outbox y exportación tras COMMIT | IMPLEMENTADO Y PROBADO (P04–P08, P13, INT-04) |
| CI de estos módulos | NO EJECUTADA |
| Vistas API, roles externos, agregaciones finales | PENDIENTE, Armando |

Evidencia: `evidencias/registros/2026-10-25-joyce-pruebas-local.txt`. Guía: `documentacion/JOYCE_SQLSERVER_MONGODB.md`.

| Componente (D-042) | Estado comprobable |
|---|---|
| `usr_api_web` / `usr_api_mobile`, vistas `api`, agregaciones y validaciones MongoDB | IMPLEMENTADO Y PROBADO localmente por Joyce con permiso de Armando; pendiente de su revisión |
| P12 (3 motores), P17, P18 y demo del video (D-043) | PROBADO localmente; evidencia `2026-10-25-joyce-entrega-p12-p17-p18.txt` |

## Actualización vigente — 26/10/2026, Joseph (D-045 a D-047)

Los PR #3, #4 y #5 permanecen abiertos y en borrador, apilados; `main` continúa
en `0a42732`. [PR #7](https://github.com/Pochonski/bases-ii-estudios-medicos/pull/7),
también en borrador, propone cambios a la rama de Joyce sin alterar su HEAD.
La [CI integrada](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40280158117)
del HEAD `0189e58` pasó P18 sobre proyecto/volúmenes/secretos/imagen efímeros,
P01–P17 e INT-04 y P12 con valores de los tres motores tras `restart` en
Ubuntu 22.04, Docker 28.0.4, kernel `6.8.0-1064-azure`. El fixture SQL rechaza
tablas pobladas y la instalación normal conservó una factura centinela.
Las regresiones de infraestructura, núcleo y TDS también pasaron en ese HEAD;
`table_name` con predicado DECIMAL sigue fallando en el spike, por lo que no se
certifica ese camino. En la PC Windows de Joseph, el daemon Linux de Docker
Desktop sigue ausente: P18 runtime local NO EJECUTADO. Restan revisión de Joyce
y Armando, exclusividad/concurrencia del outbox, TLS/CA y restauración real.

## Actualización propuesta — 26/10/2026, Joseph (D-048)

En PR #7 el head de código `cedddb9` agrega bloqueo transaccional por estudio
para exportadores simultáneos, una función web acotada y pruebas de restauración
en bases efímeras. **Implementado, todavía no probado en motores en este SHA** al
registrar la decisión. La validación estática Windows pasa; Docker Desktop Linux
Engine permanece inaccesible. La CI debe probar el nuevo head antes de reemplazar
los estados del corte anterior. El PDF original sigue fuera de Git.

**Resultado posterior del código:** en `ed2e5b2`, la CI Ubuntu
[40286756682](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/40286756682)
pasó P18 y la suite integrada, API huérfana, dos exportadores, restauración
efectiva de los tres motores y demo de nueve segmentos. Las tres regresiones
de Joseph del mismo head también pasaron. Esto no acredita Windows local,
TLS con CA, `mongodump/mongorestore`, video narrado ni revisión de Joyce/Armando.
