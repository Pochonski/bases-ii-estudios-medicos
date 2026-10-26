# Bases de Datos II · Sistema de Gestión de Estudios Médicos Distribuido

> **Estado (25/10/2026): IMPLEMENTACIÓN COMPLETA Y PROBADA en ramas/PR #3-#5, pendiente de integrar en `main`, grabar el video y entregar.** Ver [matriz de cumplimiento](documentacion/CUMPLIMIENTO_REQUISITOS.md). Proyecto académico del Instituto Tecnológico de Costa Rica, Campus Tecnológico San Carlos. **Entrega indicada en el enunciado: 28/10/2026 a las 23:59; confirmar en Moodle la inconsistencia del día de la semana.**

Este repositorio es la **fuente común de contexto** de Joseph, Joyce, Armando y sus agentes de desarrollo. Se elaboró a partir del enunciado original y de las fases de planificación acordadas en conversación. Su objetivo es prevenir decisiones contradictorias y facilitar trabajo paralelo y revisable.

## ¡Leer esto primero!

1. [`AGENTS.md`](AGENTS.md): normas **obligatorias para cualquier agente**.
2. [`docs/00_ESTADO_Y_FUENTES.md`](docs/00_ESTADO_Y_FUENTES.md): qué está confirmado, propuesto y sin verificar.
3. [`docs/01_REQUISITOS.md`](docs/01_REQUISITOS.md): matriz trazable al enunciado.
4. [`docs/02_ARQUITECTURA.md`](docs/02_ARQUITECTURA.md): despliegue en una PC.
5. [`docs/03_MODELO_DATOS.md`](docs/03_MODELO_DATOS.md): modelos conceptuales y campos.
6. [`docs/04_CONTRATOS_INTEGRACION.md`](docs/04_CONTRATOS_INTEGRACION.md): contratos, FDW, sincronización y errores.
7. [`docs/05_SEGURIDAD.md`](docs/05_SEGURIDAD.md): roles y permisos.
8. [`docs/06_PLAN_IMPLEMENTACION.md`](docs/06_PLAN_IMPLEMENTACION.md): etapas, dependencias, archivos previstos.
9. [`docs/07_PRUEBAS.md`](docs/07_PRUEBAS.md): aceptación funcional y evidencia.
10. [`docs/08_PLAN_EQUIPO.md`](docs/08_PLAN_EQUIPO.md): reparto específico Joseph/Joyce/Armando.
11. [`docs/09_CRONOGRAMA_Y_ENTREGA.md`](docs/09_CRONOGRAMA_Y_ENTREGA.md): fechas y video.
12. [`docs/10_DECISIONES_Y_PENDIENTES.md`](docs/10_DECISIONES_Y_PENDIENTES.md): registro de decisiones, dudas y riesgos.
13. [`agents/`](agents/): instrucciones exclusivas y traspaso para cada integrante.
14. [`referencia/README.md`](referencia/README.md): cómo consultar el enunciado original por los canales del curso (no publicado en este repositorio público).
15. [`docs/12_PUBLICACION_GITHUB.md`](docs/12_PUBLICACION_GITHUB.md): estado del repositorio público y reglas de colaboración.

## Inicio rápido: reconstruir y demostrar todo (P18)

Requisitos: Windows 11, Docker Desktop (motor Linux/WSL 2) y PowerShell 7 (`winget install Microsoft.PowerShell`).

```powershell
pwsh -NoProfile -File ./scripts/Install-JoyceModulos.ps1         # estructura/FDW/roles, conserva datos
pwsh -NoProfile -File ./scripts/Install-JoyceModulos.ps1 -LoadInitialData # solo sobre tablas vacías
pwsh -NoProfile -File ./scripts/Test-Entrega.ps1 -DesdeCero      # P18 efímero + suite + P12/P17
pwsh -NoProfile -File ./scripts/Test-Entrega.ps1 -DesdeCero -RunDemo # demo en proyecto efímero
```

`-DesdeCero` crea un proyecto Compose nuevo con red, volúmenes y secretos propios, sin puertos
host; retira solo esos recursos al terminar. La suite que modifica datos se permite únicamente
en ese contexto. La instalación normal conserva los registros existentes. La ejecución real de
este endurecimiento debe verificarse en CI o Docker Desktop antes de atribuirle P18. Mapa y configuración:
[documentacion/MAPA_CONEXIONES_Y_CONFIGURACION.md](documentacion/MAPA_CONEXIONES_Y_CONFIGURACION.md) ·
guion: [video/GUION.md](video/GUION.md) · referencias: [documentacion/REFERENCIAS.md](documentacion/REFERENCIAS.md).

## Objetivo académico

Simular una plataforma para estudios médicos con **tres motores diferenciados**:

- **PostgreSQL:** datos clínicos transaccionales (pacientes, médicos, citas, órdenes, estudios, resultados y diagnósticos); segmentación horizontal de pacientes por región.
- **Microsoft SQL Server:** integración con facturación, aseguradoras y convenios; segmentación vertical y procedimientos almacenados.
- **MongoDB:** documentos desnormalizados para resúmenes clínicos e indicadores; agregaciones por médico y tipo de estudio.

Se deben demostrar las conexiones PostgreSQL ↔ SQL Server y PostgreSQL ↔ MongoDB, cinco operaciones definidas por el curso, roles internos/externos y un video narrado de 5–8 minutos. **No se exige desarrollar la aplicación web o móvil.**

## Decisiones explícitas del grupo

- **Un solo equipo físico** con Windows 11, AMD Ryzen 5 5600G, 16 GB RAM y tarjeta RTX 5060; Docker Desktop + WSL 2, tres contenedores, red interna y volúmenes persistentes. Aún falta validar virtualización y disco libre.
- **Planificación antes de implementar**, sin scripts ni base de datos creada a la fecha del corte.
- **Joseph y Joyce hacen la mayor parte del trabajo inicial**; Armando implementará módulos técnicos **al final**, iniciando tentativamente el 26/10, cuando la base integrada esté estabilizada.
- División orientativa de esfuerzo: **Joseph 43%**, **Joyce 40%**, **Armando 17%**. No es una medición exacta ni reparto de nota.

## Responsables

| Responsable | Etapa principal | Paquetes previstos |
|---|---|---|
| Joseph | 22–25 oct. | Docker, PostgreSQL, particiones, `tds_fdw`, coordinación técnica |
| Joyce | 22–25 oct. | SQL Server, fragmentación vertical, MongoDB, `mongo_fdw`, exportación de resúmenes |
| Armando | 26–27 oct. | Roles externos, vistas API, agregaciones MongoDB, pruebas y evidencias de sus módulos |

**No asignar a Armando un bloqueante de la fase inicial.** Su desarrollo depende de interfaces acordadas y validadas hasta el 25 de octubre.

## Estado al corte de planificación (histórico)

- [x] Enunciado recopilado, arquitectura planeada y división propuesta por el grupo.
- [x] Modelos conceptuales, contratos, seguridad y pruebas descritos.
- [ ] Docker, WSL 2 y contenedores configurados.
- [ ] Extensiones FDW construidas y comprobadas.
- [ ] Tablas, fragmentos, colecciones y scripts implementados.
- [ ] Integraciones y pruebas ejecutadas.
- [ ] Capturas, respaldos, documentación de ejecución y video entregados.

> **Aviso a los agentes:** Que algo esté documentado NO significa que esté implementado o probado. No registrar resultados, capturas o compatibilidades como exitosos sin evidencia ejecutada.

## Política de cambios

Actualizar `docs/10_DECISIONES_Y_PENDIENTES.md` al tomar decisiones nuevas, `docs/00_ESTADO_Y_FUENTES.md` al cambiar el estado real, y `docs/11_BITACORA.md` al terminar una sesión. Todas las modificaciones técnicas deben acompañarse de una prueba reproducible. Nunca incluir contraseñas, datos de salud reales ni secretos en commits.

**Publicación:** repositorio **público** elegido por el grupo: https://github.com/Pochonski/bases-ii-estudios-medicos. La documentación publicada NO incluye el archivo original del profesor, datos clínicos reales, credenciales ni información privada. Invitaciones de escritura a Joyce y Armando siguen pendientes de sus usuarios de GitHub. La planificación fue trasladada al repositorio remoto el 21/10/2026.

## Implementación autorizada de Joseph — 22/10/2026

Joseph autorizó iniciar exclusivamente su alcance. Infraestructura y preparación FDW en
`feature/joseph-infra-postgresql`; sin merge a main.

- **IMPLEMENTADO Y PROBADO:** validación estática de Compose, sintaxis PowerShell, inicializador
  idempotente, rechazo de configuración incompleta y exclusión Git de secretos.
- **IMPLEMENTADO Y PROBADO EN CI UBUNTU:** build de ambos FDW, tres motores saludables,
  consultas autenticadas, carga de extensiones y persistencia PostgreSQL tras reinicio.
- **IMPLEMENTADO, NO PROBADO EN WINDOWS:** despliegue de los motores; Docker Desktop no expone
  el motor Linux local.
- **BLOQUEADO POR DEPENDENCIA:** lectura de facturación real, requiere vista/usuario/base de Joyce.
- **PENDIENTE:** DDL clínico, particiones, outbox y datos ficticios (después del spike de conectores),
  login de perfiles y validación mongo_fdw con Joyce. Módulos de Armando conservan su responsable.

Guía exacta: [Windows / PowerShell 7](documentacion/JOSEPH_FASE1_WINDOWS.md).
[Compatibilidad y fuentes](documentacion/COMPATIBILIDAD_FDW.md).
[Registro local real](evidencias/registros/2026-10-22-joseph-local.txt).
[CI aprobado en Ubuntu 22.04, SHA 89d0754](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/39747806912).
El resultado no prueba este Windows. [Informe completo para ChatGPT](documentacion/INFORME_CHATGPT_JOSEPH_FASE1.md).

## Correcciones de auditoría PR #1 — 22/10/2026

H1: DACL/propietario reparados también en archivos preexistentes, sin rotar secretos.
H2: selección Compose compartida y restart sin up; bindings/ID/volumen/fila PG comprobados.
H3: ejemplo y .env operativo validados por separado, con negativo temporal y .env real intacto.

[CI corregida a801c88, tres jobs PASAN](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/39759092391):
ACL Windows Server y motores Ubuntu base/localhost; artifacts depurados con retención 14 días.
P12 sigue parcial: solo PostgreSQL tras restart. Windows local no tiene daemon disponible.
FDW remoto, BSON y autenticación propia siguen pendientes; gate abierto, sin módulos ajenos.

[Informe de correcciones y evidencias](documentacion/INFORME_CORRECCIONES_AUDITORIA_PR1.md).
La [guía Windows](documentacion/JOSEPH_FASE1_WINDOWS.md) muestra una selección consistente para operación y tests.
PR #1 sigue en borrador, sin aprobación ni merge.

## Validación local posterior — 22/10/2026

Docker Desktop 4.91.0 volvió a exponer el motor Linux tras conservar y reemplazar sus carpetas
de sockets de ejecución dañados. En Windows 11 se construyó la imagen PostgreSQL y arrancaron
los tres motores con healthchecks y consultas autenticadas. El kernel efectivo fue
`6.18.33.2-microsoft-standard-WSL2`. La primera ejecución del overlay reveló que Docker no
publicaba puertos de contenedores conectados solo a la red `internal: true`; la prueba anterior
comprobaba la solicitud, no el puerto activo. El overlay corregido usa una pasarela HAProxy
sin secretos: solo ella une la red interna a una red bridge y publica puertos en `127.0.0.1`.
PostgreSQL y SQL Server respondieron también desde clientes Windows. P12 sigue limitado a
una fila PostgreSQL tras `restart`; FDW remoto y BSON permanecen pendientes de Joyce.

[Evidencia y comandos Windows](evidencias/registros/2026-10-22-joseph-despliegue-windows.txt) ·
[informe técnico actualizado](documentacion/INFORME_WINDOWS_Y_PUERTOS_JOSEPH.md).
El párrafo anterior de correcciones registra el estado *antes* de esta validación local.

## Núcleo PostgreSQL de Joseph, fase 2 aislada

El [PR #2](https://github.com/Pochonski/bases-ii-estudios-medicos/pull/2) agrega las 12
tablas del modelo, particiones LIST SJ/AL/CA y datos enteramente ficticios. La
[guía de ejecución](documentacion/JOSEPH_FASE2_POSTGRESQL.md) crea bases de prueba
vacías sin modificar la base clínica existente. El PR se basa en la rama de
infraestructura del PR #1 y permanece en borrador. Las consultas FDW remotas, la
validación BSON y el worker de Joyce siguen pendientes; este adelanto no supera ese gate.

La [CI del gateway](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/39807402214)
PASÓ en head `0b5e507` con tres jobs: Windows Server ACL y Ubuntu base/localhost;
[registro revisado](evidencias/registros/2026-10-22-joseph-gateway-ci.txt).

## Consolidación propuesta hacia main — 23/10/2026

Los estados de PR #1/#2 arriba son históricos: [PR #1](https://github.com/Pochonski/bases-ii-estudios-medicos/pull/1)
se fusionó en `main` (`0a42732`) y [PR #2](https://github.com/Pochonski/bases-ii-estudios-medicos/pull/2)
se fusionó únicamente en la rama de infraestructura (`84cb072`). El
[PR #3](https://github.com/Pochonski/bases-ii-estudios-medicos/pull/3), en borrador y
dirigido a `main`, traslada solo el delta clínico por cherry-pick. El gate FDW/MongoDB
sigue abierto. El [informe de fase 3](documentacion/INFORME_CHATGPT_JOSEPH_FASE3.md)
registra el estado actual, la revisión del outbox y las pruebas.

## Módulos de Joyce — 25/10/2026

SQL Server (fragmentación vertical, procedimientos, `dbo.vw_estado_facturacion`), MongoDB
(`resumenes_estudios`) y exportación PostgreSQL → MongoDB por `mongo_fdw` con outbox.
Todas las pruebas de Joyce PASAN en Windows 11 local; sin CI todavía. Ver
[guía](documentacion/JOYCE_SQLSERVER_MONGODB.md), D-041 y
[evidencia](evidencias/registros/2026-10-25-joyce-pruebas-local.txt).
Con permiso de Armando (D-042) también quedaron implementados y probados los roles externos,
las vistas `api` y las agregaciones MongoDB (P02, P03, P09, P10, P11).
