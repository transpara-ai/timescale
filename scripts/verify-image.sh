#!/usr/bin/env bash
set -euo pipefail

image="${1:?usage: scripts/verify-image.sh IMAGE [PLATFORM]}"
platform="${2:-linux/amd64}"

expected_title="Transpara CNPG Timescale Toolkit"
actual_title="$(docker image inspect "${image}" --format '{{ index .Config.Labels "org.opencontainers.image.title" }}')"
if [ "${actual_title}" != "${expected_title}" ]; then
  echo "unexpected image title label: ${actual_title}" >&2
  exit 1
fi

docker run --rm \
  --platform "${platform}" \
  -e EXPECTED_TIMESCALEDB_DEB_VERSION="${EXPECTED_TIMESCALEDB_DEB_VERSION:-2.28.0~debian13-1804}" \
  -e EXPECTED_TIMESCALEDB_LOADER_DEB_VERSION="${EXPECTED_TIMESCALEDB_LOADER_DEB_VERSION:-2.28.0~debian13-1804}" \
  -e EXPECTED_TOOLKIT_DEB_VERSION="${EXPECTED_TOOLKIT_DEB_VERSION:-1:1.23.0~debian13}" \
  "${image}" \
  bash -euo pipefail -c '
    check() {
      if ! "$@"; then
        echo "verification failed: $*" >&2
        exit 1
      fi
    }

    check test "$(id -u)" = "26"
    check test "$(id -g)" = "102"

    for bin in initdb postgres pg_ctl pg_controldata pg_basebackup; do
      path="$(command -v "${bin}")"
      check test "${path}" = "/usr/lib/postgresql/18/bin/${bin}"
    done

    check test -f /usr/share/postgresql/18/extension/timescaledb.control
    check test -f /usr/share/postgresql/18/extension/timescaledb_toolkit.control
    timescaledb_shared="$(find /usr/lib/postgresql/18/lib -maxdepth 1 -name "timescaledb-*.so" -print -quit)"
    check test -n "${timescaledb_shared}"
    check test -f /usr/lib/postgresql/18/lib/timescaledb_toolkit-1.23.0.so

    loader_version="$(dpkg-query -W -f="\${Version}" timescaledb-2-loader-postgresql-18)"
    check test "${loader_version}" = "${EXPECTED_TIMESCALEDB_LOADER_DEB_VERSION}"

    if dpkg-query -s timescaledb-2-postgresql-18 >/dev/null 2>&1; then
      timescaledb_version="$(dpkg-query -W -f="\${Version}" timescaledb-2-postgresql-18)"
    else
      if ! dpkg-query -s timescaledb-2-oss-postgresql-18 >/dev/null 2>&1; then
        echo "verification failed: neither full nor OSS TimescaleDB package is installed" >&2
        exit 1
      fi
      timescaledb_version="$(dpkg-query -W -f="\${Version}" timescaledb-2-oss-postgresql-18)"
    fi
    check test "${timescaledb_version}" = "${EXPECTED_TIMESCALEDB_DEB_VERSION}"

    toolkit_version="$(dpkg-query -W -f="\${Version}" timescaledb-toolkit-postgresql-18)"
    check test "${toolkit_version}" = "${EXPECTED_TOOLKIT_DEB_VERSION}"

    check test -f /usr/local/share/transpara/timescale-image.env
  '
