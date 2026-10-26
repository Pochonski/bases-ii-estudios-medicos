# Guion del video — 7:00 aprox. (el enunciado pide entre 5 y 8 minutos)

**Antes de grabar:**

```powershell
pwsh -NoProfile -File ./scripts/Install-JoyceModulos.ps1   # si el entorno no está levantado
pwsh -NoProfile -File ./scripts/Demo-Video.ps1             # Enter entre segmentos
```

- Terminal con fuente grande y ventana maximizada.
- No mostrar la carpeta `secrets/` ni el archivo `.env`.
- Tener abierto `documentacion/MAPA_CONEXIONES_Y_CONFIGURACION.md` con el diagrama renderizado
  (vista previa de Markdown en VS Code).
- Todos los datos son ficticios. Cada uno puede grabar su parte por separado y luego se unen.

| Tiempo | Quién | Pantalla | Qué decir (resumen) |
|---|---|---|---|
| 0:00–0:40 | Joseph | Diagrama del mapa de conexiones | Problema: plataforma de estudios médicos con tres motores de propósitos distintos. PostgreSQL transaccional, SQL Server integración externa, MongoDB analítica. No se construye app; se construye la infraestructura de datos y los perfiles. |
| 0:40–1:20 | Joseph | Segmento **1** | Una PC Windows 11 con Docker Desktop/WSL 2. Tres contenedores, uno por servidor lógico, con red `medical-network` `internal=true`: los motores no se exponen hacia afuera. Secretos en archivos, no en el código. Aclarar que es distribución lógica, no física. |
| 1:20–2:10 | Joseph | Segmento **2** | Segmentación horizontal: `pacientes` particionada por LIST en SJ/AL/CA, 10 pacientes en cada una. El `EXPLAIN` muestra que una consulta por `CA` solo lee `pacientes_ca` (partition pruning). PK compuesta `(id_paciente, codigo_region)`. Región de registro ≠ región de atención. |
| 2:10–2:40 | Joseph | Segmento **4** + `postgresql.conf` / `pg_hba.conf` | Canales FDW: `sqlserver_medico` con `tds_fdw`, `mongo_reportes` con `mongo_fdw`. Cada uno tiene mapping solo para su perfil interno (`usr_fdw_pg_mssql`, `usr_fdw_pg_mongo`). SCRAM-SHA-256; `pg_hba` acepta solo la red interna y localhost. |
| 2:40–3:30 | Joyce | Segmento **3** | SQL Server simula aseguradoras y facturación. Segmentación vertical: la entidad *paciente asegurado* se divide en `paciente_integracion` (datos de interoperabilidad) y `paciente_cobertura` (estado), con la misma clave; la vista los reconstruye 1:1 sin pérdida. El procedimiento `sp_recalcular_resumen_facturacion` genera el resumen que consulta PostgreSQL. |
| 3:30–4:20 | Joyce | Segmento **5** | **Operación 1**: desde PostgreSQL, con el login `usr_fdw_pg_mssql`, un `LEFT JOIN` entre pacientes locales y la tabla foránea de SQL Server. 1009 aparece `SIN_REGISTRO`: no se inventa cobertura. Luego llega una factura en SQL Server y PostgreSQL la ve de inmediato. La cuenta remota solo puede leer esa vista. |
| 4:20–5:20 | Joyce | Segmento **6** | **Operación 2**: resultado + evento en una sola transacción. Antes de exportar, MongoDB no tiene el documento. Tras el COMMIT, `usr_fdw_pg_mongo` llama al exportador, que inserta por `mongo_fdw` (Int64, Int32, Date). Se corrige el resultado: revisión 2 actualiza el **mismo** documento. Explicar: no es ACID global; es consistencia eventual con outbox, idempotente. Si MongoDB está caído, el evento queda en ERROR y se reintenta (P08 en evidencias). |
| 5:20–5:40 | Joyce | Segmento **8** | **Operación 4**: exportación masiva. Cada resultado de PostgreSQL tiene exactamente un resumen en MongoDB (mismos conteos). |
| 5:40–6:30 | Armando | Segmento **7** | **Operación 3**: vista `api.vw_paciente_facturacion` para la web, que combina datos locales y remotos. Perfiles externos: web lee facturación y agenda; móvil solo su vista reducida. Las pruebas prohibidas fallan con *permission denied*. Ambos perfiles son de solo lectura, con SCRAM y límites de conexión/tiempo distintos. Detalle técnico: `tds_fdw` usa el mapping de quien consulta, por eso la vista pasa por una función del perfil interno. |
| 6:30–7:00 | Armando | Segmento **9** | **Operación 5**: agregación en MongoDB por médico y tipo de estudio, verificada contra PostgreSQL. Mencionar reportes adicionales (sucursal, mes, indicadores mensuales). Cierre: las cinco operaciones funcionan; las evidencias están en `evidencias/registros/`. |

## Frases clave (para no olvidarlas)

- "Tres servidores lógicos en contenedores aislados, una red interna; no hay alta disponibilidad
  ni distribución física."
- "La exportación ocurre **después del COMMIT**; si se hace ROLLBACK no se exporta nada."
- "PostgreSQL y MongoDB no comparten una transacción: usamos un outbox con reintentos
  idempotentes. Es consistencia eventual."
- "Cada canal FDW tiene su perfil interno con permisos mínimos; los perfiles externos nunca
  tienen credenciales remotas."

## Respaldo si algo falla en vivo

Mostrar los registros de `evidencias/registros/2026-10-25-joyce-pruebas-local.txt` y
`2026-10-25-joyce-entrega-p12-p17-p18.txt`, que incluyen todas las operaciones ejecutadas.
