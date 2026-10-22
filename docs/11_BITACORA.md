# Bitácora de progreso y trazabilidad

## 2026-10-21 — Inicialización documental

- **Responsable:** Joseph, con planificación asistida y revisión pendiente del equipo.
- **Alcance:** se documentaron requisitos del enunciado, decisiones de arquitectura y asignación, modelos, contratos, seguridad, plan, pruebas, fechas y guías de agentes.
- **Archivos:** README, AGENTS, docs/, agents/, referencia del curso (disponible localmente en el paquete original) y políticas Git.
- **Implementación:** NO realizada.
- **Pruebas de bases de datos/FDW:** NO ejecutadas.
- **Certeza:** solo documentación. Revisar pendientes en `docs/10_DECISIONES_Y_PENDIENTES.md`.

## Plantilla de entradas posteriores

```text
### AAAA-MM-DD HH:MM — [responsable] [actividad]
Objetivo:
Archivos creados/modificados:
Decisiones (IDs):
Comandos ejecutados:
Pruebas / resultado (o NO EJECUTADAS):
Evidencias:
Bloqueos y pendientes:
Dependencias para otros integrantes:
Commit o PR:
```

## 2026-10-21 — Preparación para repositorio público de GitHub

- **Destino:** `https://github.com/Pochonski/bases-ii-estudios-medicos` (creado vacío por el usuario, público).
- **Decisión D-024:** el repositorio público sustituye la propuesta de repo privado D-021.
- **Ajustes:** guías de agentes y planes publicados; referencia del enunciado original excluida del remoto público, referencias actualizadas.
- **Implementación de bases de datos:** NO realizada; **pruebas de bases de datos:** NO ejecutadas.
- **Verificación de contenido documental:** revisión de nombres de archivo, referencias y política de publicación, pendiente de verificación remota después del push.

## 2026-10-21 — Publicación del plan en GitHub

- Se preparó la publicación de los archivos de planificación y las guías individuales para los tres agentes en la rama `main` del repositorio público.
- No se incluyó el archivo del enunciado original ni contraseñas o datos médicos reales.
- Estado técnico inalterado: sin bases de datos implementadas ni pruebas ejecutadas.

## 2026-10-22 — Joseph, infraestructura y preparación PostgreSQL

- Objetivo: iniciar alcance autorizado de Joseph desde main 630cca6 en rama feature/joseph-infra-postgresql.
- Contexto leído completo: README, AGENTS, agents/JOSEPH, PROTOCOLO, docs/00..12, guías Joyce/Armando,
  handoff, CONTRIBUTING y evidencia. Dependencias identificadas antes de cambios.
- Cambios reales: Compose de tres motores, imagen personalizada con fuentes/checksums de dos FDW,
  configuración PG/HBA/FreeTDS, inicializador seguro, pruebas estáticas/runtime/persistencia, CI Ubuntu,
  preparación SQL de lectura, manual y documentación. No hay tablas clínicas ni objetos de Joyce/Armando.
- Decisiones: D-025..D-028; gate de conectores conserva pendiente la etapa clínica.
- Comandos: git clone/switch/status/show/diff, gh api (refs/perfil), docker --version/compose version/info/
  desktop start/buildx imagetools inspect/compose config/build; wsl --status; descargas oficiales en
  memoria con SHA-256; scripts Initialize-Local (dos veces) y Test-Infra -StaticOnly; parser PowerShell;
  git check-ignore y diff --check. Comandos de prueba exactos en manual/evidencia.
- Pruebas: estáticas PASAN; build local falla antes de compilar por named pipe ausente.
  P01 bloqueada por vista/base/cuenta de Joyce; P12/P14/P17/P18 no acreditadas localmente.
- Evidencia: evidencias/registros/2026-10-22-joseph-local.txt.
- Dependencias: Joyce confirma contrato SQL Server y valida BSON/escrituras Mongo FDW; Armando consume
  posteriormente, sin reasignaciones. No se enviaron mensajes en nombre de Joseph.
- Git/PR y resultados posteriores: se registrarán al terminar la verificación de esta misma sesión.

### Continuación — diagnóstico de CI (misma sesión)

PR en borrador #1: https://github.com/Pochonski/bases-ii-estudios-medicos/pull/1 .
Commits iniciales 4591a78 y bd4ce09; 4785086 agregó logs para diagnóstico.
Build de ambas extensiones PASÓ en Ubuntu; el init creó ambas extensiones y PG/SQL Server
estuvieron saludables. Las dos primeras ejecuciones FALLARON por aborto de MongoDB,
id 12257600 / SERVER-121912 (kernel no compatible).
Se registra D-029 y se cambia solo el runner a ubuntu-22.04, agregando uname -r.
Evidencia y cierre definitivo se registran en el informe final, sin atribuir éxito al Windows local.
