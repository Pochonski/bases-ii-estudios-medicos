# Informe técnico para ChatGPT, auditor del proyecto de Joseph

> Informe histórico de la primera sesión. Para H1–H3 y evidencia posterior de auditoría,
> consultar [informe de correcciones](INFORME_CORRECCIONES_AUDITORIA_PR1.md).

**Sesión:** 21–22/10/2026, America/Costa_Rica.
**Responsable:** Joseph Fonseca, con implementación asistida.
**Objetivo:** iniciar infraestructura reproducible y preparación PostgreSQL dentro del alcance de Joseph.
**Repositorio:** https://github.com/Pochonski/bases-ii-estudios-medicos .
**Resultado:** primera etapa de infraestructura implementada y probada en CI Ubuntu; despliegue Windows sin probar.

## 1. Resumen ejecutivo

Se clonó el repositorio directamente en la carpeta solicitada y se revisó main, inicialmente limpia en
630cca6b14f23d73579ccab2a0106ab1fa68f7fc. Se leyeron íntegros README, AGENTS, JOSEPH, PROTOCOLO,
docs/00–12, guías de Joyce/Armando, handoff, CONTRIBUTING y el estado de evidencias antes de modificar.

Se implementó Compose con PostgreSQL personalizado, SQL Server Developer y MongoDB, red interna,
persistencia, healthchecks autenticados y secretos por archivo. Se investigaron las dependencias
de ambos FDW con fuentes primarias y se inmovilizaron candidatos por digest/commit/SHA-256.

El build, los tres motores, SCRAM/configuración PG, la creación y carga de las extensiones y el reinicio
con persistencia PostgreSQL PASARON en GitHub Actions Ubuntu 22.04, kernel 6.8.0-1070-azure.
Docker Desktop local no expone dockerDesktopLinuxEngine incluso tras intentar iniciarlo:
ningún motor quedó acreditado en este Windows. La comprobación local se repitió al cierre y siguió fallando.

La etapa B (12 tablas clínicas, restricciones, particiones, outbox y fixture) permanece PENDIENTE.
Se respetó el gate 2 de docs/06: faltan consultas FDW remotas y pruebas BSON/escritura con Joyce antes del DDL
completo. Se preparó la parte de Joseph de la etapa C, sin resultados de facturación simulados.
No se desarrollaron módulos SQL Server/MongoDB de Joyce ni APIs, roles externos o reportes de Armando.
No hay aceptación global INT-01..05 ni P01..P18.

## 2. Rama, commits y Pull Request

- Rama: `feature/joseph-infra-postgresql`.
- Base main: `630cca6`; verificada remota sin cambios al cerrar la implementación.
- PR **OPEN / DRAFT**, base main: https://github.com/Pochonski/bases-ii-estudios-medicos/pull/1 .
- Sin merge ni aprobación de revisión atribuida al agente.

| Commit | Cambio |
|---|---|
| 4591a7862f5d69083458ec19d8ccd4e03103e7c4 | Infraestructura de tres motores, imagen FDW, scripts y guía |
| bd4ce093e8fe4c8dc59d3ce9c34fae6cbe3b3e02 | Preparación TDS, estado compartido y evidencia local |
| 4785086 | Diagnóstico de arranque en CI |
| 89d07543085020fbb28d83c834a3655851857d79 | Runner compatible y registro del bloqueo de kernel |

El primer commit del informe es efc4ad7. Los commits de cierre posteriores a 89d0754 modifican
solo documentación/evidencias y se consultan con `git log --oneline 89d0754..HEAD`.
El código ejecutable probado corresponde a 89d0754; no se atribuye a otro SHA.
Autor de commits: Joseph Fonseca, cuenta Pochonski con correo noreply de GitHub.

## 3. Archivos creados o modificados

| Grupo | Rutas |
|---|---|
| Compose/configuración | compose.yaml; compose.local.yaml; .env.example; .dockerignore; .gitattributes; .gitignore |
| Imagen PostgreSQL | docker/postgres/Dockerfile; postgresql.conf; pg_hba.conf; freetds.conf; initdb/00_fdw.sql |
| Operación/pruebas PowerShell | scripts/Initialize-Local.ps1; scripts/Test-Infra.ps1; scripts/Test-Persistence.ps1 |
| Preparación FDW | integracion/01_fdw_sqlserver.sql |
| Pruebas SQL de Joseph | pruebas/infraestructura/01_extensiones.sql; 02_fdw_sqlserver.sql |
| CI | .github/workflows/joseph-infra.yml |
| Manual y análisis | documentacion/JOSEPH_FASE1_WINDOWS.md; COMPATIBILIDAD_FDW.md; este informe |
| Estado compartido | README.md; docs/00_ESTADO_Y_FUENTES.md; 02_ARQUITECTURA.md; 04_CONTRATOS_INTEGRACION.md; 05_SEGURIDAD.md; 06_PLAN_IMPLEMENTACION.md; 07_PRUEBAS.md; 10_DECISIONES_Y_PENDIENTES.md; 11_BITACORA.md; 12_PUBLICACION_GITHUB.md |
| Evidencia | evidencias/README.md; registros/2026-10-22-joseph-local.txt; 2026-10-22-joseph-ci-fallo.txt; 2026-10-22-joseph-ci-exito.txt |

Se generaron localmente .env y secrets/*.txt: están ignorados y NO incluidos en los commits.
No se crearon postgresql/01..03 ni 06, sqlserver/*, mongodb/* o integracion/sincronizacion/*.

## 4. Decisiones técnicas y justificaciones

D-025 registra la autorización expresa, limitada a Joseph. D-026 conserva el orden de gates del plan:
la compilación y carga no prueban el acceso remoto ni habilitan por sí solas todo el esquema clínico.

D-027 fija **candidatos de spike**, conservando PG16/SQL2022/Mongo8 del diseño. Fuentes descargadas
con SHA-256 en Dockerfile, build en dos etapas y bibliotecas comprobadas con ldd. Los paquetes apt no usan
snapshot: no se promete una imagen idéntica bit a bit ni la disponibilidad permanente de sus repositorios.

D-028 mantiene .env sin contraseñas. Compose entrega un archivo secreto a su respectivo motor.
Initialize-Local genera 32 bytes aleatorios por contraseña, no muestra valores y conserva archivos existentes.
Windows usa ACL para el usuario/SYSTEM; Linux, directorio 700 y archivos 644 para lectura por UID de SQL Server.
La carpeta privada restringe acceso desde el host; Compose local no cifra el archivo en disco.
El wrapper SQL Server lee el secreto porque no se asumió soporte de MSSQL_SA_PASSWORD_FILE.

La red es interna y no publica puertos. El overlay publica únicamente 127.0.0.1.
Hay un volumen de datos por motor y otro /data/configdb para Mongo.
Límites de memoria: PG 1 GiB, SQL Server 3 GiB (interno 2048 MB), Mongo 1.5 GiB/caché 0.5 GB.
Son límites iniciales; no mediciones del Ryzen/16 GB.

PG usa SCRAM por TCP, peer local Unix para postgres, UTC y sin sentencias registradas en logs.
FreeTDS exige TLS a SQL Server; la CA no está validada. PG/Mongo no tienen TLS:
la seguridad implementada corresponde al laboratorio aislado, no a un despliegue público.

La tabla extranjera conserva el contrato y lee únicamente dbo.vw_estado_facturacion.
El nombre de base y contraseña llegan en ejecución; el monto es numeric(12,2) y la fecha se proyecta como
ISO-8601 desde SQL Server para evitar depender del tipo DB-Library DATETIMEOFFSET.
Esa conversión aún requiere prueba de precisión/offset con Joyce. No se creó o alteró la vista remota.
El rol PostgreSQL usr_fdw_pg_mssql es NOLOGIN y no hay mapping PUBLIC ni de postgres.

D-029 registra el hallazgo real: el candidato MongoDB abortó en el runner Ubuntu24 por la comprobación
de kernel SERVER-121912. Se cambió **solo CI** a Ubuntu22 y se confirmó kernel 6.8.
No se modificó Windows/WSL ni se desactivó la protección de MongoDB.

## 5. Versiones y dependencias utilizadas

| Componente | Versión/artefacto observado |
|---|---|
| Windows local, herramientas | Git 2.54.0.windows.1; gh 2.95.0; Docker CLI 29.8.0; Compose 5.5.1; PowerShell 7 requerido |
| WSL local | Versión predeterminada 2; virtualización/arranque Docker y kernel efectivo no acreditados |
| CI | Ubuntu 22.04; kernel 6.8.0-1070-azure; Docker Engine 28.0.4; linux/amd64 |
| PostgreSQL en CI | 16.15, Debian 16.15-1.pgdg12+2 |
| SQL Server en CI | 2022 RTM-CU27-GDR, KB5126934, 16.0.4305.5, Developer, Ubuntu22.04.5 |
| MongoDB en CI | 8.0.34 |
| tds_fdw | Código v2.0.5 / extversion 2.0.5; commit 5830577908683cb35c760079ec0f105ef7e3ff98 |
| FreeTDS | freetds-dev, freetds-common y libsybdb5: 1.3.17+ds-2, según log apt de CI |
| mongo_fdw | Código REL-5_5_3; extversion SQL 1.1; commit 27aa7b04af197129bf10069c4b512a326c94f3f8 |
| Dependencias Mongo FDW | mongo-c-driver 1.30.2; json-c 0.18-20240915; OpenSSL/Cyrus SASL |
| Construcción | PGXS/postgresql-server-dev-16 de la versión PG_VERSION de imagen; gcc/make/cmake/pkg-config |
| Checkout CI | actions/checkout v4 resuelto a 11d5960a326750d5838078e36cf38b85af677262 |

Digests amd64:
- PG: sha256:e92e17ca202da4bb205f6f4a6c8cb30539edfbaa04987b506630f5d5851ff3c8
- SQL Server: sha256:cf8f0ab2ebe61feec2eed2629061a07d247f791c2a8ddda74a4ac9f06a291718
- Mongo: sha256:4c7d0fb8fde0681e2ae443b0b09371ec9c31a81caab05af9579458bfcb30d656

Las versiones definitivas de integración siguen pendientes; los candidatos ya tienen prueba de build/arranque.
Hashes de las cuatro fuentes y enlaces primarios completos: COMPATIBILIDAD_FDW.md.

## 6. Comandos ejecutados

Lectura: rg --files, Get-Content -Raw de los documentos enumerados en el resumen, git remote show origin,
git show HEAD:.gitattributes y revisión del template de PR. No se obtuvo ni publicó el original del profesor.

Comandos principales (los duplicados de diagnóstico se omiten):
```powershell
git ls-remote --symref https://github.com/Pochonski/bases-ii-estudios-medicos.git HEAD
git clone https://github.com/Pochonski/bases-ii-estudios-medicos.git .
git switch -c feature/joseph-infra-postgresql
git status --short --branch
git log -1 --format='%h %s'
git diff --check
git diff origin/main...HEAD --check
git check-ignore .env secrets/postgres_password.txt secrets/sqlserver_sa_password.txt secrets/mongo_root_password.txt
git push --set-upstream origin feature/joseph-infra-postgresql
git push
git ls-remote origin refs/heads/main
docker --version
docker compose version
docker info --format '{{.ServerVersion}}'
docker desktop start
wsl --status
docker buildx imagetools inspect postgres:16-bookworm
docker buildx imagetools inspect mongo:8.0
docker buildx imagetools inspect mcr.microsoft.com/mssql/server:2022-latest
./scripts/Initialize-Local.ps1
./scripts/Initialize-Local.ps1
./scripts/Test-Infra.ps1 -StaticOnly
docker compose --env-file .env.example config --format json
docker compose --env-file .env.example -f compose.yaml -f compose.local.yaml config --format json
docker compose --progress plain build postgres
gh run view 39747806912 --repo Pochonski/bases-ii-estudios-medicos --json conclusion,headSha,url,jobs
```

También: gh auth status (solo diagnóstico, sin registrar credenciales), gh api de refs oficiales y perfil
para verificar la autoría; descargas HTTPS en memoria con HttpClient y SHA256.HashData;
Parser.ParseFile para tres scripts; prueba negativa con POSTGRES_DB vacío;
comparación interna de hashes para comprobar idempotencia sin publicarlos;
revisión del contenido publicable contra los tres valores secretos sin imprimirlos;
git add y cuatro commits mediante -c user.name/-c user.email noreply;
gh pr create --draft con --body-file, gh pr view, gh run list/view/--log y vinculación del PR al chat.

En CI, además del build:
```powershell
./scripts/Initialize-Local.ps1
./scripts/Test-Infra.ps1 -StaticOnly
docker compose up -d --wait --wait-timeout 300
./scripts/Test-Infra.ps1
./scripts/Test-Persistence.ps1
docker compose ps -a
docker compose logs --no-color --tail 80 postgres sqlserver mongodb
docker compose down
```

Test-Infra ejecutó psql con 01_extensiones.sql, SELECT @@VERSION por sqlcmd y auth/ping MongoDB.
Test-Persistence creó una tabla marcador aleatoria en la base administrativa postgres, confirmó la fila,
reinició PG, comprobó su existencia y eliminó la tabla. No tocó datos clínicos.
El workflow también registró uname -r. Los comandos con secretos leyeron archivos/entorno, sin literales.
No se ejecutó el script 01_fdw_sqlserver.sql ni el test 02_fdw_sqlserver.sql.

## 7. Pruebas, resultados y evidencia

| Elemento | Clasificación y alcance |
|---|---|
| Compose base/overlay y controles de exposición | IMPLEMENTADO Y PROBADO: validación estática Windows y CI |
| Inicializador, sintaxis, .gitignore y configuración incompleta | IMPLEMENTADO Y PROBADO en Windows; secretos existentes conservados y no publicados |
| Build PG + ambos FDW / ldd | IMPLEMENTADO Y PROBADO en CI Ubuntu; NO probado en Windows |
| Tres healthchecks y consultas autenticadas | IMPLEMENTADO Y PROBADO en CI; no equivale a consultas FDW entre motores |
| CREATE EXTENSION / LOAD / HBA sin errores y sin trust TCP | IMPLEMENTADO Y PROBADO en CI PostgreSQL16 |
| Persistencia PG tras restart | IMPLEMENTADO Y PROBADO en CI; P12 parcial, solo PostgreSQL |
| Despliegue y consumo de RAM en Windows | IMPLEMENTADO, NO PROBADO: daemon local ausente |
| Preparación SQL de servidor/mapping/foreign table | IMPLEMENTADO, NO PROBADO: P17 no acreditada |
| P01 / vista de facturación real | BLOQUEADO POR DEPENDENCIA: objetos y cuenta de Joyce |
| BSON, escritura/actualización Mongo FDW y exportación | PENDIENTE de validación con Joyce |
| DDL clínico, FKs, particiones P14 y fixture | PENDIENTE para siguiente etapa de Joseph |
| APIs, perfiles externos, agregaciones y restantes INT | PENDIENTE según responsables |

Evidencias:
- Local: ../evidencias/registros/2026-10-22-joseph-local.txt.
- Fallo de kernel: ../evidencias/registros/2026-10-22-joseph-ci-fallo.txt.
- Éxito CI: ../evidencias/registros/2026-10-22-joseph-ci-exito.txt.
- [CI aprobado, SHA 89d0754](https://github.com/Pochonski/bases-ii-estudios-medicos/actions/runs/39747806912).
- Runs iniciales fallidos: 39744770706 (bd4ce09), 39747121313 (4785086).

La red se creó y los motores respondieron dentro de sus respectivos contenedores.
No se demostró todavía autenticación/consulta PG→SQL Server ni PG→MongoDB.
No se presentan fixtures manuales como integración ni creación de extensión como prueba FDW funcional.

## 8. Problemas encontrados

1. El aislamiento inicial impidió DNS/Git y acceso a la sesión local. Con los permisos del entorno
   se clonó y se comprobó correctamente la sesión GitHub de Pochonski. No fue necesario rotar tokens.
2. Docker CLI existe, pero el named pipe dockerDesktopLinuxEngine no está disponible;
   iniciar Desktop no produjo un motor utilizable en esta sesión. No se forzó reinstalación ni cambio de WSL.
3. La compilación de ambos FDW sí fue viable en CI. Los dos primeros arranques conjuntos fallaron por
   protección de MongoDB ante kernel incompatible. El tercero pasó en kernel 6.8; fallo y solución conservados.
4. Se corrigió whitespace capturado del progreso Docker y se conservó la política original de .gitattributes.
5. Siguen faltando base/vista/cuenta de facturación y los objetos/worker de Joyce.
6. Ningún fallo inicial se ocultó; las versiones siguen sujetas a validación funcional intermotor.

## 9. Dependencias pendientes de Joyce

- Nombre de base SQL Server y dbo.vw_estado_facturacion real, una fila por (id_paciente,codigo_region).
- Confirmación de tipos, estados, agregación de facturas, monto y fecha con offset/precisión.
- Cuenta svc_pg_mssql_ro con solo SELECT a la vista y contraseña por canal seguro.
- Fixture SQL Server coherente con los futuros IDs clínicos; no se inventaron estados locales.
- Validación conjunta mongo_fdw: BSON Int64/Int32/Date/ObjectId, inserción/actualización, índice único,
  revisión monotónica, autenticación y fallos.
- Colecciones/roles MongoDB y pipeline outbox tras COMMIT: responsabilidad de Joyce.
- Revisión del contrato consumidor antes de integrar el PR.

No se enviaron mensajes a Joyce/Armando en nombre del usuario ni se implementaron sus módulos.
Para Armando siguen pendientes las precondiciones del handoff 25/10; no se reasigna ese bloqueo.

## 10. Riesgos y recomendaciones

- Validar Docker Desktop/WSL local antes de afirmar éxito en la computadora de Joseph.
  Repetir exactamente el manual JOSEPH_FASE1_WINDOWS.md y guardar las salidas.
- Comprobar el kernel efectivo de Docker; el candidato Mongo8 tiene un riesgo demostrado con ciertos kernels.
  No cambiar kernel o desactivar protecciones como solución automática.
- Completar pruebas reales de FDW antes de fijar la matriz final, especialmente tipos temporales y BSON.
- Mantener secretos fuera de Git/build/logs; la cuenta administradora de Docker puede leerlos.
- Autenticación y red privada no cifran todo el tráfico: TLS PG/Mongo y CA TDS pendientes si cambia la exposición.
- El rol interno aún es NOLOGIN; no declararlo plenamente configurado bajo docs/05.
- El tamaño de RAM/SSD debe medirse localmente; no hay prueba de carga.
- Conservar volúmenes y preparar backups; no usar down -v para resolver fallos.
- Apt y la etiqueta del runner cambian con el tiempo; guardar evidencia y revisar reconstrucciones.
- Siguen abiertas las aclaraciones docentes/Moodle del plan; no se modificaron requisitos.
- Mantener el PR en borrador hasta revisión de Joyce, pruebas pendientes y autorización de Joseph para merge.

## 11. Próximas tareas específicas de Joseph

1. Resolver disponibilidad del motor Linux Docker Desktop y repetir build/arranque/smoke/persistencia en Windows.
2. Con Joyce, ejecutar una consulta TDS real y la prueba de tipos/escritura mongo_fdw; registrar el resultado
   y confirmar candidatos. P01 debe consultar su vista, sin tabla local que la reemplace.
3. Implementar postgresql/01_esquemas.sql, 02_tablas.sql y 03_particiones.sql según docs/03:
   12 tablas, PK/FKs/CHECK/UNIQUE, identidad compuesta paciente-región y LIST SJ/AL/CA.
4. Coordinar la estructura de eventos con Joyce sin desarrollar su worker; no confundir outbox con ACID global.
5. Crear postgresql/06_datos_prueba.sql con IDs estables y datos totalmente ficticios; distinguir región
   de registro de la región de atención.
6. Añadir y ejecutar P14 con tableoid/EXPLAIN, pruebas negativas de FKs/estados/revisión y rollback;
   registrar exactamente entorno, SHA y salidas.
7. Aplicar integracion/01 contra los objetos reales, completar P01/P17 y habilitar/probar login interno
   con mínimo privilegio. No implementar vistas API ni roles externos de Armando.
8. Actualizar handoff, matriz de pruebas, bitácora y reporte de revisión antes de solicitar merge.

**Preguntas para el auditor:** ninguna autorización adicional asumida; revisar las dependencias indicadas.
No hay autorización de merge y no se realizó merge.
