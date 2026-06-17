#!/usr/bin/env bash
set -euo pipefail

image="${1:?usage: scripts/smoke-test.sh IMAGE [PLATFORM]}"
platform="${2:-linux/amd64}"

docker run --rm \
  --platform "${platform}" \
  -e EXPECTED_TIMESCALEDB_SQL_VERSION="${EXPECTED_TIMESCALEDB_SQL_VERSION:-2.28.0}" \
  -e EXPECTED_TOOLKIT_SQL_VERSION="${EXPECTED_TOOLKIT_SQL_VERSION:-1.23.0}" \
  "${image}" \
  bash -euo pipefail -c '
    export PGDATA=/tmp/pgdata
    export PGSOCKET=/tmp/pgsocket

    mkdir -p "${PGSOCKET}"
    initdb -D "${PGDATA}" >/tmp/initdb.log
    echo "shared_preload_libraries = '\''timescaledb'\''" >> "${PGDATA}/postgresql.conf"

    pg_ctl -D "${PGDATA}" -o "-k ${PGSOCKET}" -w start >/tmp/pgstart.log
    trap "pg_ctl -D ${PGDATA} -m fast -w stop >/tmp/pgstop.log" EXIT

    cat >/tmp/smoke.sql <<SQL
CREATE EXTENSION IF NOT EXISTS timescaledb;
CREATE EXTENSION IF NOT EXISTS timescaledb_toolkit;
SELECT extname, extversion
FROM pg_extension
WHERE extname IN ('\''timescaledb'\'', '\''timescaledb_toolkit'\'')
ORDER BY extname;
SQL

    psql -h "${PGSOCKET}" -d postgres -v ON_ERROR_STOP=1 -f /tmp/smoke.sql

    ts_version="$(psql -h "${PGSOCKET}" -d postgres -At -c "SELECT extversion FROM pg_extension WHERE extname = '\''timescaledb'\'';")"
    toolkit_version="$(psql -h "${PGSOCKET}" -d postgres -At -c "SELECT extversion FROM pg_extension WHERE extname = '\''timescaledb_toolkit'\'';")"

    test "${ts_version}" = "${EXPECTED_TIMESCALEDB_SQL_VERSION}"
    test "${toolkit_version}" = "${EXPECTED_TOOLKIT_SQL_VERSION}"
  '
