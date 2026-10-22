# AGENTS.md — contrato obligatorio para agentes de Joseph, Joyce y Armando

## Misión y límites

Trabajas en un proyecto universitario de **Bases de Datos II**. Antes de ejecutar cualquier cambio, lee **completamente** `README.md`, `docs/00_ESTADO_Y_FUENTES.md`, `docs/01_REQUISITOS.md`, `docs/02_ARQUITECTURA.md`, `docs/03_MODELO_DATOS.md`, `docs/04_CONTRATOS_INTEGRACION.md`, `docs/08_PLAN_EQUIPO.md` y `docs/10_DECISIONES_Y_PENDIENTES.md`; luego tu archivo de `agents/`. Si tu tarea afecta roles, pruebas o fechas, lee también los documentos correspondientes.

La prioridad de fuentes es: **(1)** enunciado original del curso; **(2)** decisiones explícitas del grupo; **(3)** acuerdos técnicos posteriormente aprobados y registrados; **(4)** propuestas del diseño actual. Una propuesta NO puede sobrescribir el enunciado ni transformarse en un requisito falso. Ante ambigüedad académica, documentar y escalar, no fingir autorización.

## Reglas que no se negocian

1. **Estado inicial solo documentación.** No implementar nada hasta que el grupo autorice expresamente la fase de implementación; crear estos documentos no implica autorizar código.
2. La solución usa **una sola PC Windows 11 + Docker Desktop/WSL 2** y tres motores separados en contenedores. No inventar clusters multinodo ni alta disponibilidad.
3. No construir frontend ni móvil: solo perfiles/vistas para futuras aplicaciones.
4. Respetar modelos, identificadores compartidos, nombres de objetos y los contratos. Si deben cambiar, proponer modificación, registrar decisión e informar a los demás antes de editar interfaces compartidas.
5. Los pacientes y estudios son **ficticios**. Nunca usar información médica real, contraseñas ni tokens en documentación, commits o capturas.
6. Se requiere probar **FDW real**; no presentarlo como logrado sin consultas reproducibles. `tds_fdw` se reserva para lecturas. La ruta `mongo_fdw` está pendiente de validación práctica; la alternativa intermedia requiere aclaración por contradicción del enunciado.
7. **Después de COMMIT** no significa una transacción ACID global. El outbox y MongoDB proveerían consistencia eventual; marcar todo eso como diseño hasta que haya pruebas.
8. No hacer commits de otros módulos sin coordinar. Solicitar revisión para cambios al esquema o contrato que afecten a otro responsable. Mantener `main` estable; usar ramas personales y PR cuando el repositorio remoto exista.
9. Mantener cada módulo reproducible (archivos, orden de ejecución, datos ficticios, validaciones y evidencia). No prometer que un test pasó si no se ejecutó.
10. **Armando entra al final**. No moverle instalación inicial de Docker, creación del núcleo de PostgreSQL, SQL Server ni conectores, ni bloquear el arranque por tareas asignadas a él.
11. Si tu trabajo requiere modificar `docs/`, registrar el cambio con fecha, responsable, motivación e impacto en `docs/10_DECISIONES_Y_PENDIENTES.md` y `docs/11_BITACORA.md`.
12. **Cada respuesta o informe de agente** debe incluir: objetivo, archivos afectados, qué se modificó realmente, comandos ejecutados, pruebas y resultados (o NO EJECUTADAS), riesgos, dependencias y tareas siguientes. Si no se ejecutó nada, decirlo.

## Contratos de coordinación

- La identidad formal del paciente propuesta es `(id_paciente, codigo_region)`; la región del **paciente** no debe confundirse con la **región de atención**.
- `id_estudio` compartido; PostgreSQL es origen de información clínica. SQL Server es origen de facturación y convenios; MongoDB de indicadores basados en datos exportados.
- La vista remota SQL Server → PostgreSQL se llama provisionalmente `dbo.vw_estado_facturacion`/`externo.ft_estado_facturacion`; debe retornar una fila por paciente-región. PostgreSQL ofrecería `api.vw_paciente_facturacion` por `LEFT JOIN`.
- MongoDB: resumen único por `id_estudio`, revisión monotónica, exportación tras COMMIT, reintentos idempotentes. **Comportamiento real de `mongo_fdw`, tipos BSON y atomicidad pendientes de comprobar**.
- Cualquier ruptura de contrato requiere aprobación y comunicación a los demás; después del traspaso del 25/10 deben congelarse las interfaces salvo correcciones justificadas.

## Cómo empezar una sesión

1. Revisa tu rama, `git status`, `README`, `AGENTS.md`, tu archivo de agente y el estado actual.
2. Identifica un requisito y un criterio de aceptación concretos.
3. Si aún no hay autorización para implementar, **solo planifica o documenta**.
4. Tras implementar (cuando se autorice), deja pruebas y evidencias en rutas previstas; registra estado real y traspasos.
5. No alterar tareas de Armando para resolver bloqueos previos de Joseph/Joyce.

**Archivo para cada rol:** `agents/JOSEPH.md`, `agents/JOYCE.md`, `agents/ARMANDO.md`.
