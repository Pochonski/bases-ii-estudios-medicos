# Bases de Datos II · Sistema de Gestión de Estudios Médicos Distribuido

> **Estado: IMPLEMENTACIÓN PARCIAL AUTORIZADA PARA JOSEPH.** Corte de contexto: 21 de octubre de 2026 (America/Costa_Rica). Proyecto académico del Instituto Tecnológico de Costa Rica, Campus Tecnológico San Carlos. **Entrega indicada en el enunciado: 28/10/2026 a las 23:59; confirmar en Moodle la inconsistencia del día de la semana.**

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
- **IMPLEMENTADO, NO PROBADO:** build de la imagen, arranque/salud de motores y persistencia local.
  Docker Desktop no expone el motor Linux; no se ejecutaron motores en Windows.
- **BLOQUEADO POR DEPENDENCIA:** lectura de facturación real, requiere vista/usuario/base de Joyce.
- **PENDIENTE:** DDL clínico, particiones, outbox y datos ficticios (después del spike de conectores),
  login de perfiles y validación mongo_fdw con Joyce. Módulos de Armando conservan su responsable.

Guía exacta: [Windows / PowerShell 7](documentacion/JOSEPH_FASE1_WINDOWS.md).
[Compatibilidad y fuentes](documentacion/COMPATIBILIDAD_FDW.md).
[Registro local real](evidencias/registros/2026-10-22-joseph-local.txt).
El workflow de infraestructura intenta build/runtime en Ubuntu; su resultado no prueba este Windows.
