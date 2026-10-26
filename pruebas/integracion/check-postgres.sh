#!/usr/bin/env bash
set -euo pipefail
export PGPASSWORD
PGPASSWORD="$(cat /run/secrets/pg_fdw_login_password)"
dpkg-query -W -f='FreeTDS libsybdb5 ${Version}\n' libsybdb5
psql -X -h 127.0.0.1 -U usr_fdw_pg_mssql -d joseph_tds_spike_pg -v ON_ERROR_STOP=1 \
  -f /opt/proyecto/tds-spike/04_postgresql_assertions.sql
