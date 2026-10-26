#!/usr/bin/env bash
set -euo pipefail
export PGPASSWORD FDW_MSSQL_PASSWORD PG_FDW_LOGIN_PASSWORD
PGPASSWORD="$(cat /run/secrets/postgres_password)"
FDW_MSSQL_PASSWORD="$(cat /run/secrets/fdw_password)"
PG_FDW_LOGIN_PASSWORD="$(cat /run/secrets/pg_fdw_login_password)"
psql_admin=(psql -X -h 127.0.0.1 -U postgres -v ON_ERROR_STOP=1)
"${psql_admin[@]}" -d postgres -c 'CREATE DATABASE joseph_tds_spike_pg TEMPLATE template0;'
"${psql_admin[@]}" -d joseph_tds_spike_pg -c 'CREATE EXTENSION tds_fdw;' >/dev/null
for file in 01_esquemas.sql 02_tablas.sql 03_particiones.sql 06_datos_prueba.sql; do
  "${psql_admin[@]}" -d joseph_tds_spike_pg -f "/opt/proyecto/postgresql/$file" >/dev/null
done
"${psql_admin[@]}" -d joseph_tds_spike_pg -c "INSERT INTO clinico.pacientes (id_paciente,codigo_region,nombre,apellidos,fecha_nacimiento,telefono,correo,fecha_registro) SELECT 5000000000,codigo_region,'PacienteSpike5000000000',apellidos,fecha_nacimiento,telefono,'spike5000000000@example.invalid',fecha_registro FROM clinico.pacientes WHERE id_paciente=1001 AND codigo_region='AL';" >/dev/null
"${psql_admin[@]}" -d joseph_tds_spike_pg -v mssql_database=joseph_fdw_spike -f /opt/proyecto/integracion/01_fdw_sqlserver.sql >/dev/null
"${psql_admin[@]}" -d joseph_tds_spike_pg -f /opt/proyecto/tds-spike/03_postgresql_role.sql >/dev/null
"${psql_admin[@]}" -d joseph_tds_spike_pg -f /opt/proyecto/tds-spike/06_table_mode.sql >/dev/null
echo 'PASS PostgreSQL: núcleo ficticio y FDW configurados en base aislada'
