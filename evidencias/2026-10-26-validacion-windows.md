# Validación integral real en Windows 11 — 26/10/2026

Responsable: Joseph. **Código ejecutado:**
`2840743917364d137c5298b6456fef15862b3a92` de `origin/main`, en un
worktree limpio y separado. Esta evidencia corresponde a ese SHA, **no** al
commit documental que publique este informe. La suite empezó a las
07:54:28 UTC−06:00 y el registro se escribió a las 07:59:35. Su proceso
terminó con código 0, `RESULTADO: PASA` y `PASS limpieza`.

## Entorno y comandos realmente ejecutados

| Elemento | Versión / resultado |
|---|---|
| Host | Windows 11, Docker Desktop 4.91.0 |
| Docker cliente y servidor | 29.8.0; servidor `linux/amd64` |
| Kernel Docker | `6.18.33.2-microsoft-standard-WSL2` |
| Docker Compose | v5.5.1 |
| PowerShell | 7.6.5 |
| Imágenes del proyecto | PostgreSQL 16 `bookworm` personalizada; SQL Server 2022; MongoDB 8.0, fijadas por digest en el código |
| Extensiones efectivas P17 | `tds_fdw` 2.0.5; `mongo_fdw` 1.1 según `pg_extension` |

Se ejecutaron `docker version`, `docker info --format`, `docker compose version`,
`pwsh --version`, `wsl --status`, `git fetch origin main --prune --no-tags` y
`git worktree add --detach $target origin/main`; se comprobó el SHA completo
con `git rev-parse HEAD`. Desde esa copia se ejecutaron exactamente:

```powershell
pwsh -NoProfile -File ./scripts/Test-Entrega.ps1 -StaticOnly
pwsh -NoProfile -File ./scripts/Test-Entrega.ps1 -DesdeCero -RunDemo -DemoSinPausa -EvidencePath .tmp/entrega-local.txt
```

La validación estática terminó en PASS. La suite integrada terminó con código 0.
No se volvió a ejecutar para preparar este documento. Se ejecutó solo en
`joyce-p18-5f7d311360ec`, sin publicar puertos host; el script verificó red,
volúmenes, secretos y ausencia previa de recursos con ese nombre.

## Matriz de resultados del [registro íntegro](registros/2026-10-26-joseph-validacion-integrada-windows.txt)

| Prueba | Resultado | Evidencia en el registro |
|---|---|---|
| P01 | PASS | Lectura FDW real SQL Server; `LEFT JOIN` 30/24/6, línea 64 |
| P02 | PASS | Vista web combinada, 30 pacientes, línea 94 |
| P03 | PASS | 6 pacientes `SIN_REGISTRO`, línea 95 |
| P04 | PASS | Resultado y evento confirmados juntos, línea 74 |
| P05 | PASS | Inserción `mongo_fdw`, tipos BSON e índice único, líneas 77–78 |
| P06 | PASS | Actualización con mismo `_id`, revisión 2, línea 82 |
| P07 | PASS | Reproceso sin duplicado, línea 83 |
| P08 | PASS | Caída y recuperación MongoDB con reintento, líneas 89–90 |
| P09 | PASS | 12 grupos médico × tipo iguales a PostgreSQL, línea 123 |
| P10 | PASS | Lecturas permitidas web y móvil, líneas 96–113 |
| P11 | PASS | Accesos/escrituras prohibidos rechazados, líneas 98–113 |
| P12 | PASS | Tres motores con valores iguales antes/después de `restart`, líneas 147–149 |
| P13 | PASS | ROLLBACK sin resultado, evento ni documento, líneas 69–70 |
| P14 | PASS | `tableoid` 10/10/10 y poda `EXPLAIN`, línea 53 |
| P15 | PASS | Fragmentación vertical 1:1 sin pérdida, línea 57 |
| P16 | PASS | Procedimiento, resumen y consulta posterior FDW, líneas 59 y 65 |
| P17 | PASS | Servidores FDW, mappings sin contraseñas, perfiles y permisos, línea 307 |
| P18 | PASS | Instalación desde volúmenes vacíos, línea 125 |

Las operaciones del curso se acreditan por la matriz de pruebas; el log imprime
`INT-04` literalmente y las demás se derivan de sus P correspondientes:

| Operación | Resultado | Pruebas reales |
|---|---|---|
| INT-01 | PASS | P01/P02: paciente PostgreSQL + facturación SQL Server |
| INT-02 | PASS | P04–P08/P13: COMMIT, exportación, revisión y ROLLBACK |
| INT-03 | PASS | P02/P03: vista web local + remota y ausencia remota |
| INT-04 | PASS | 32 resultados PostgreSQL = 32 documentos MongoDB, línea 92 |
| INT-05 | PASS | P09: 12 grupos médico × tipo contrastados, línea 123 |

Además: permisos SQL Server positivos/negativos (líneas 60–63), MongoDB
(línea 87), perfiles web/móvil y SCRAM (líneas 96–114); fila remota huérfana
visible solo internamente (líneas 128–129); dos exportadores concurrentes,
un documento, mismo ObjectId y revisión final 4 (líneas 132–135).
Los nueve segmentos de demostración terminaron en PASS (línea 310);
**no son un video grabado**.

## Persistencia, restauración y aislamiento

- PostgreSQL: `pg_dump/pg_restore` en base nueva; 30 pacientes, revisión 4 y
  4 eventos comprobados (línea 138).
- SQL Server: `BACKUP/RESTORE DATABASE` en base nueva; facturas, pacientes e
  importe comprobados (línea 139).
- MongoDB: copia lógica EJSON **estricta** en base nueva; documentos, índices y
  tipos BSON comprobados (líneas 140–141). `mongodump/mongorestore` estaban
  disponibles, pero **no se ejecutaron**.
- P12 comparó 11 valores antes y después del reinicio de los mismos tres
  contenedores; la lectura FDW siguió operativa. P12 y restauración son
  pruebas diferentes.
- La instalación ordinaria conservó una factura sintética; la carga inicial
  y el fixture directo sobre tablas pobladas fueron rechazados (línea 144).
- El registro finaliza con `PASS limpieza` (línea 313). El
  [inventario publicable](registros/2026-10-26-joseph-inventario-docker.md)
  confirma 7/17/6 contenedores/volúmenes/redes antes y después, **cero
  diferencias de identificadores**. Una comprobación Docker posterior encontró
  cero recursos del proyecto P18. No se borraron volúmenes compartidos.

## Procedencia, hashes y seguridad

| Archivo | SHA-256 | Publicación |
|---|---|---|
| Original `entrega-local.txt`, 18824 bytes | `2EB27B4825FA4FD6A9D0E88A443F47D8C2E729137054FE609CD23BFDB4B39ACB` | Original intacto en `.tmp`; copia íntegra en Git con el **mismo hash** |
| Original `docker-before.json`, 1361 bytes | `3F5402E28FCC429043743285369B612F3B1C94DC7795AF9B62FA12C3B923CC9B` | Solo resumen, no JSON completo |
| Original `docker-after.json`, 1361 bytes | `3F5402E28FCC429043743285369B612F3B1C94DC7795AF9B62FA12C3B923CC9B` | Solo resumen, no JSON completo |
| Copia [inventario resumido](registros/2026-10-26-joseph-inventario-docker.md) | `4732445A667936C780D84EB390D19368374F9D23B3A69CD566F7AF19DED6F6D8` | Derivado comprobable; no copia byte a byte de los JSON |

Se leyó el log completo (313 líneas), se examinaron nombres y contenido, y se
buscaron patrones de valores secretos, asignaciones de credenciales, URI de
conexión, rutas privadas y correos. **No se hallaron valores sensibles**. Las
cinco líneas con términos relacionados con secretos describen que se omitieron
o muestran `password_encryption`; no contienen contraseñas. Por eso el log se
publica sin cambiar un byte. Los identificadores Docker completos se omiten
del resumen por minimización de información. Los originales no fueron
modificados ni movidos. Los datos clínicos del fixture son ficticios.
`.gitattributes` desactiva la conversión de saltos de línea **solo para este
registro** y conserva los espacios de la salida original: el hash del blob Git
indexado y el hash Git calculado sobre los bytes crudos son idénticos. Se
verificó también el mismo SHA-256 del original y de la copia en disco.

## Límites y pendientes

El outbox ofrece consistencia eventual, **no ACID global**; su candado protege
a exportadores que usan el procedimiento, no DML MongoDB directo. El modo TDS
contractual `query` pasó en la integración; esta ejecución no volvió a probar
la igualdad DECIMAL defectuosa de `table_name`. TLS/CA no está validado para
producción. EJSON estricto no equivale a `mongorestore` ni a un plan operativo
de respaldos. Faltan capturas auténticas, video narrado, confirmación del
cierre en Moodle y la entrega. No se fabricaron imágenes ni capturas.
