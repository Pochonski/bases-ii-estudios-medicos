\set ON_ERROR_STOP on
-- Spike aislado: modo convencional de tds_fdw sobre una vista de prueba de solo lectura.
CREATE FOREIGN TABLE externo.ft_estado_tabla_spike (
  id_paciente bigint, codigo_region char(2), nombre_aseguradora text,
  estado_cobertura text, estado_facturacion text,
  total_facturado_crc numeric(12,2), fecha_actualizacion timestamptz
) SERVER sqlserver_medico OPTIONS (
  schema_name 'dbo', table_name 'vw_estado_tabla_spike',
  match_column_names 'true', use_remote_estimate 'false'
);
REVOKE ALL ON externo.ft_estado_tabla_spike FROM PUBLIC;
GRANT SELECT ON externo.ft_estado_tabla_spike TO usr_fdw_pg_mssql;
