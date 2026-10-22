# Cronograma, documentación y video

## Fechas

**Enunciado:** inicio martes **13/10/2026**; entrega «martes 28/10/2026 11:59 p. m.» (inconsistente: el 28 cae miércoles). **Confirmar horario real en Moodle** antes de asumir la fecha. Zona horaria America/Costa_Rica.

| Fecha | Trabajo previsto | Liderazgo |
|---|---|---|
| **21 oct (mié)** | Cerrar planificación y el presente repositorio de contexto | Todos / Joseph |
| **22 oct (jue)** | Docker, SQL/PG/Mongo mínimos y prueba temprana de conectores | Joseph y Joyce |
| **23 oct (vie)** | Esquemas, particiones, fragmentos, colecciones, dataset | Joseph y Joyce |
| **24 oct (sáb)** | Integración SQL Server: FDW, procedimientos, lectura remota | Joseph y Joyce |
| **25 oct (dom)** | Integración MongoDB, eventos, estabilizar contratos y traspaso | Joseph y Joyce |
| **26 oct (lun)** | Armando: roles/vistas externas, agregaciones, pruebas propias; pruebas cruzadas | Armando, apoyo grupo |
| **27 oct (mar)** | Correcciones, evidencia final, manual y video narrado | Todos |
| **28 oct (mié)** | Revisar archivos y entregar Moodle antes de hora real confirmada | Todos |

**Regla:** el video y entregables deben quedar preferentemente listos el 27; el 28 es margen de revisión. Cronograma es objetivo, no confirmación de trabajo realizado.

## Video 5–8 min [CURSO]

Guion estimado **6:45**:

- 0:00–2:30 Joseph: propósito, una PC/3 contenedores, red, PostgreSQL y particiones, FDW.
- 2:30–5:00 Joyce: SQL Server, fragmentos, procedimientos, MongoDB, exportación tras confirmación.
- 5:00–6:45 Armando: vistas web/móvil, roles y permisos, agregación médico/tipo, validación.

Ajustar cronología para mostrar **cinco operaciones**, diagrama de conexiones, consultas ejecutadas en **tres motores**, evidencia de comunicación remota, narración de los tres y explicación de límites (consistencia eventual vs ACID global).

## Entregables mínimos

1. Modelo relacional + segmentación horizontal y vertical, con justificación.
2. Scripts de configuración/creación en PostgreSQL, SQL Server y MongoDB, más instrucciones de ejecución.
3. Configuración real FDW documentada (`postgresql.conf`, `pg_hba.conf`, `CREATE SERVER`, mapeos, pruebas).
4. Cuatro roles del curso, permisos, autenticación y sus pruebas.
5. Consultas/transacciones/transferencias distribuidas exigidas.
6. Capturas y registros de resultados reales.
7. README de reconstrucción, datos ficticios, referencias, video 5–8 min.
8. Subida a Moodle, no solo dejar repo en GitHub.

## Política académica

- No usar datos médicos reales ni evidencias fabricadas.
- Citar manuales, artículos, documentación o repositorios externos usados durante implementación.
- Respetar prohibición de copia/plagio indicada en enunciado.
- El PDF/archivo de la tarea tiene advertencia de descuento del 10% por hora tardía; revisar Moodle para efectos exactos.
