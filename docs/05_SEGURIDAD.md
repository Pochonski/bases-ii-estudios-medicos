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
