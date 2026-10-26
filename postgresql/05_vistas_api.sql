\set ON_ERROR_STOP on
-- Módulo de Armando, implementado por Joyce con su permiso (D-042).
-- Vistas para futuras aplicaciones web y móvil. Repetible. Requiere 04_roles_externos.sql.
--
-- tds_fdw busca el USER MAPPING del usuario que ejecuta la consulta, no del dueño de la vista
-- (comprobado: "user mapping not found" para el lector). Para que ningún perfil externo tenga
-- credenciales de SQL Server, la lectura remota pasa por una función SECURITY DEFINER cuyo
-- dueño es el perfil interno usr_fdw_pg_mssql: todo acceso remoto usa siempre su mapping.
BEGIN;
CREATE SCHEMA IF NOT EXISTS api;
REVOKE ALL ON SCHEMA api FROM PUBLIC;

CREATE OR REPLACE FUNCTION externo.fn_estado_facturacion()
RETURNS SETOF externo.ft_estado_facturacion
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = pg_catalog, pg_temp
AS $$ SELECT * FROM externo.ft_estado_facturacion $$;
ALTER FUNCTION externo.fn_estado_facturacion() OWNER TO usr_fdw_pg_mssql;
REVOKE ALL ON FUNCTION externo.fn_estado_facturacion() FROM PUBLIC;

-- Privilegios del dueño de las vistas: solo lo que las vistas leen.
GRANT USAGE ON SCHEMA clinico, externo TO api_propietario;
GRANT SELECT ON clinico.pacientes, clinico.regiones, clinico.citas, clinico.medicos,
                clinico.sucursales, clinico.ordenes_medicas, clinico.estudios TO api_propietario;
GRANT EXECUTE ON FUNCTION externo.fn_estado_facturacion() TO api_propietario;

-- INT-03 (web): datos mínimos del paciente + estado de facturación de SQL Server.
-- LEFT JOIN por la identidad completa: un paciente sin registro externo aparece con
-- SIN_REGISTRO y nunca se duplica (la vista remota garantiza 1 fila por paciente-región).
-- Sin fecha de nacimiento, teléfono, correo ni datos clínicos.
CREATE OR REPLACE VIEW api.vw_paciente_facturacion WITH (security_barrier) AS
SELECT p.id_paciente,
       p.codigo_region,
       r.nombre AS region_registro,
       p.nombre,
       p.apellidos,
       f.nombre_aseguradora,
       COALESCE(f.estado_cobertura, 'SIN_REGISTRO') AS estado_cobertura,
       COALESCE(f.estado_facturacion, 'SIN_REGISTRO') AS estado_facturacion,
       f.total_facturado_crc,
       f.fecha_actualizacion AS facturacion_actualizada
FROM clinico.pacientes AS p
JOIN clinico.regiones AS r ON r.codigo_region = p.codigo_region
LEFT JOIN externo.fn_estado_facturacion() AS f
       ON f.id_paciente = p.id_paciente AND f.codigo_region = p.codigo_region;

-- Web: agenda completa para personal administrativo.
CREATE OR REPLACE VIEW api.vw_citas_web WITH (security_barrier) AS
SELECT c.id_cita,
       c.id_paciente,
       c.codigo_region AS region_registro_paciente,
       p.nombre || ' ' || p.apellidos AS paciente,
       c.id_medico,
       m.nombre || ' ' || m.apellidos AS medico,
       m.especialidad,
       c.id_sucursal,
       s.nombre AS sucursal,
       s.codigo_region AS region_atencion,
       c.fecha_hora,
       c.estado,
       (SELECT count(*) FROM clinico.ordenes_medicas AS o
          JOIN clinico.estudios AS e ON e.id_orden = o.id_orden
         WHERE o.id_cita = c.id_cita) AS cantidad_estudios
FROM clinico.citas AS c
JOIN clinico.pacientes AS p ON p.id_paciente = c.id_paciente AND p.codigo_region = c.codigo_region
JOIN clinico.medicos AS m ON m.id_medico = c.id_medico
JOIN clinico.sucursales AS s ON s.id_sucursal = c.id_sucursal;

-- Móvil: proyección mínima (sin nombre del paciente, especialidad ni conteos).
CREATE OR REPLACE VIEW api.vw_citas_mobile WITH (security_barrier) AS
SELECT c.id_cita,
       c.id_paciente,
       c.codigo_region,
       c.fecha_hora,
       c.estado,
       s.nombre AS sucursal,
       m.nombre || ' ' || m.apellidos AS medico
FROM clinico.citas AS c
JOIN clinico.medicos AS m ON m.id_medico = c.id_medico
JOIN clinico.sucursales AS s ON s.id_sucursal = c.id_sucursal;

ALTER VIEW api.vw_paciente_facturacion OWNER TO api_propietario;
ALTER VIEW api.vw_citas_web OWNER TO api_propietario;
ALTER VIEW api.vw_citas_mobile OWNER TO api_propietario;
REVOKE ALL ON api.vw_paciente_facturacion, api.vw_citas_web, api.vw_citas_mobile FROM PUBLIC;

GRANT USAGE ON SCHEMA api TO usr_api_web, usr_api_mobile;
-- Web: facturación + agenda completa. Las funciones invocadas en una vista se autorizan
-- con el usuario que consulta, por eso usr_api_web necesita EXECUTE (devuelve solo
-- columnas de facturación, sin nombres; no otorga credenciales remotas).
GRANT SELECT ON api.vw_paciente_facturacion, api.vw_citas_web TO usr_api_web;
GRANT EXECUTE ON FUNCTION externo.fn_estado_facturacion() TO usr_api_web;
-- Móvil: solo su vista reducida.
GRANT SELECT ON api.vw_citas_mobile TO usr_api_mobile;
COMMIT;
\echo 'PASS 05: vistas api (paciente_facturacion, citas_web, citas_mobile) y permisos'
