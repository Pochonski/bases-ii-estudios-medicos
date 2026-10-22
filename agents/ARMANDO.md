# Agente de Armando — módulos técnicos de etapa FINAL

**Restricción explícita del grupo:** Armando programa **después** de que Joseph y Joyce creen el núcleo integrado. **Inicio objetivo: 26/10**; esfuerzo orientativo ~17%. Leer `../AGENTS.md`, contratos y `HANDOFF_25_OCT.md`.

## Misión

Crear funcionalidades finales **sobre contratos ya estables**: vistas externas de consulta, usuarios web/móvil, consultas analíticas y sus validaciones. No instalar ni construir primero los motores.

## Precondiciones para empezar

Debe estar disponible lo del checklist `HANDOFF_25_OCT.md`: entorno, PostgreSQL/SQL Server/MongoDB, particiones, vista FDW, índices, al menos un resumen sincronizado, datos ficticios y rutas de prueba. Si falta algún punto, registrar dependencia; Joseph/Joyce mantienen propiedad de corregir el bloqueo.

## Implementación propia

1. **PostgreSQL:** crear `usr_api_web`, `usr_api_mobile`; permisos mínimos y validaciones negativas.
2. **Vistas:** `api.vw_paciente_facturacion` (LEFT JOIN PG + tabla extranjera SQL Server), `api.vw_citas_web`, `api.vw_citas_mobile`; aplicar mínimos campos necesarios.
3. **MongoDB:** pipelines de conteo por médico/tipo (obligatorio), por tipo, sucursal y mes (extras); revisar que `codigo_region_atencion` no sea la región de registro del paciente.
4. **Pruebas y evidencias propias:** consultas, resultados esperados, registro de accesos permitidos/denegados, capturas reales.

## Entregables futuros

`postgresql/04_roles_externos.sql`, `postgresql/05_vistas_api.sql`, `mongodb/04_agregaciones.js`, `mongodb/05_validaciones.js`, `pruebas/seguridad/*`, `pruebas/reportes/*`, imágenes/logs de sus casos P02/P03/P09/P10/P11.

## Criterios de aceptación

- Reporte agrupa realmente estudios por `id_medico` y `id_tipo` y produce conteos comprobados.
- `usr_api_web` y `usr_api_mobile` leen únicamente las vistas autorizadas, no las tablas base; evidencia de denegación.
- La vista federada recupera paciente aun si no tiene cobertura remota (LEFT JOIN, SIN_REGISTRO) y no duplica pacientes.
- Documentar su trabajo y narrar su parte (~1:45) en el video conjunto.

## Qué NO hacer

- No crear ni modificar esquemas base de pacientes/citas/facturas salvo aprobación de cambio transversal.
- No hacerse cargo de Docker, fragmentación, FreeTDS, FDW Mongo o worker outbox.
- No renombrar objetos bajo congelación del 25/10.
- No comenzar antes de la autorización general de implementación y sin revisar el handoff.

## Si el handoff es parcial

Avanzar de forma separable: escribir/probar agregaciones con el dataset previamente acordado (sin simular integración) o preparar validaciones de seguridad; comunicar bloqueos de los demás sin absorberlos.
