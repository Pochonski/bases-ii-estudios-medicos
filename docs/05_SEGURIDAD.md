# Seguridad y roles — mínimo privilegio

**Fuente [CURSO]:** nombres de cuatro usuarios y diferenciación entre internos (clúster) y externos (web/móvil) son obligatorios. La implementación de políticas detalladas es [PROPUESTA].

## Perfiles PostgreSQL

| Perfil | Naturaleza | Acceso previsto | Dueño de preparación |
|---|---|---|---|
| `usr_fdw_pg_mssql` | Interno | Lectura remota permitida en SQL Server | Joseph con Joyce |
| `usr_fdw_pg_mongo` | Interno | Acceso controlado a los resúmenes mediante FDW | Joseph/Joyce |
| `usr_api_web` | Externo | `SELECT` sobre vistas autorizadas `api` | Armando |
| `usr_api_mobile` | Externo | `SELECT` solo vistas reducidas `api` | Armando |

La identidad de ejecución del procesador outbox (cuenta de aplicación/servicio) necesita diseñarse separadamente; no permitirle usar credenciales de superusuario. Los objetos `FOREIGN SERVER` y `USER MAPPING` deben pertenecer a roles apropiados y no exponerse indiscriminadamente.

## Cuentas de servicio remotas [PROPUESTA]

- SQL Server: `svc_pg_mssql_ro`, solo `SELECT` sobre `dbo.vw_estado_facturacion` (y objetos necesarios, si corresponde), nunca administrador.
- MongoDB: `svc_pg_mongo_rw`, permiso de lectura/escritura limitado a base/colecciones destinadas al FDW; consultar soporte real de roles en driver/conector.

## Vistas para futuras aplicaciones [PROPUESTA]

- `api.vw_paciente_facturacion`: datos mínimos de paciente + facturación federada, evitar diagnósticos y notas innecesarias.
- `api.vw_citas_web`: citas, datos de médico/sucursal, campos autorizados.
- `api.vw_citas_mobile`: proyección mínima sin campos clínicos sensibles no indispensables.

**No desarrollar** frontend ni móvil. Son consumidores conceptuales. Definir apropiadamente el propietario de vistas y los permisos subyacentes; probar efectivamente con cada cuenta. Una vista no garantiza por sí sola la privacidad por paciente/usuario: si se requiere control por filas, tendría que diseñarse; no sobreprometerlo en alcance.

## Autenticación y red

- Contraseñas fuertes en `.env` local sin commit; `.env.example` solo variables sin valores secretos.
- Red Docker interna; exponer puertos administrativos solo a localhost si hace falta.
- Documentar y revisar `postgresql.conf`, `pg_hba.conf`, usuarios de los tres motores y mapeos FDW.
- Evitar credenciales en capturas y video; usar pacientes ficticios.
- Mantener pruebas **positivas y negativas**: `SELECT` permitido y `INSERT/UPDATE/DELETE` denegado a usuarios solo lectura; `usr_api_mobile` no debe acceder a vistas exclusivas de web ni tablas base.

## Criterio de aprobación

Ningún rol se considera implementado sin scripts, verificación de inicio de sesión y evidencia de una operación permitida más una operación denegada.

## Implementación parcial — 22/10/2026, Joseph (D-028)

La configuración no secreta está en .env; contraseñas aleatorias en secrets/ ignorado.
Compose monta solo el secreto de cada motor; no hay contraseñas en environment del modelo Compose.
El wrapper de SQL Server exporta su contraseña al proceso en tiempo de arranque: un administrador
del contenedor aún puede acceder a ella. No se promete aislamiento frente al dueño de Docker.
SCRAM PostgreSQL, peer Unix local, red interna y puertos localhost opcionales preparados.
TLS de FreeTDS es obligatorio pero sin CA validada; PostgreSQL y MongoDB no configuran TLS.
No hay prueba funcional de roles ni habilitación de perfiles externos. Consultar el manual local.

## Corrección de auditoría H1 — 22/10/2026, Joseph (D-030)

La versión auditada conservaba autorizaciones explícitas de terceros. Se reconstruye la DACL y se
verifican propietario/herencia/reglas tanto en carpeta como archivos existentes, conservando valores.
Regresión Windows con Everyone/Users PASA; no se impersonó otro usuario ni se certifica protección
frente a administradores que puedan tomar posesión. Linux mantiene 700/644 para Compose por archivo.
Las pruebas de login y permisos negativos de los roles FDW continúan NO EJECUTADAS.

## Puertos opcionales — 22/10/2026, Joseph (D-034)

Los motores quedan exclusivamente en `medical-network` interna. En modo local, la pasarela
TCP no recibe secretos, usa sistema de archivos de solo lectura y conecta esa red a
`host-access` no interna; solo ella publica 127.0.0.1. La pasarela puede tener salida de red
por su bridge, por lo que se limita a forwarding TCP y no ejecuta lógica de aplicación.
Los clientes Windows autenticaron PostgreSQL/SQL Server; MongoDB solo fue autenticado dentro
del contenedor, aunque su puerto localhost aceptó TCP. Estas pruebas usan cuentas de
administración inicial, no acreditan login de roles propios ni permisos negativos.
