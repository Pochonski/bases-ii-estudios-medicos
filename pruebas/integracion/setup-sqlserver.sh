#!/usr/bin/env bash
set -euo pipefail
export SQLCMDPASSWORD
SQLCMDPASSWORD="$(cat /run/secrets/sqlserver_sa_password)"
fdw_password="$(cat /run/secrets/fdw_password)"
# El secreto solo viaja por stdin de sqlcmd; nunca se imprime ni se pasa como argumento.
sql="$(cat /opt/proyecto/tds-spike/01_sqlserver_spike.sql.template)"
sql="${sql//__FDW_PASSWORD__/$fdw_password}"
printf '%s\n' "$sql" | /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -C -b -f 65001 -i /dev/stdin
unset sql fdw_password SQLCMDPASSWORD
