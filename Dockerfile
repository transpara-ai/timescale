# syntax=docker/dockerfile:1.7

ARG BASE_IMAGE=ghcr.io/cloudnative-pg/postgresql:18.4-standard-trixie@sha256:7259c775ce18bdf668f17a68accb78e5bcc8074bbea9c8cdac974a8a8525a173
FROM ${BASE_IMAGE}

ARG BASE_IMAGE
ARG PG_MAJOR=18
ARG TIMESCALEDB_PACKAGE_VARIANT=oss
ARG TIMESCALEDB_VERSION=2.28.0~debian13-1804
ARG TIMESCALEDB_LOADER_VERSION=2.28.0~debian13-1804
ARG TOOLKIT_VERSION=1:1.23.0~debian13
ARG IMAGE_VERSION=pg18.4-ts2.28.0-oss-toolkit1.23.0-cnpg-standard
ARG VCS_REF=unknown
ARG BUILD_DATE=unknown

LABEL org.opencontainers.image.title="Transpara CNPG Timescale Toolkit" \
      org.opencontainers.image.description="CloudNativePG PostgreSQL operand image with TimescaleDB and TimescaleDB Toolkit" \
      org.opencontainers.image.source="https://github.com/transpara-ai/timescale" \
      org.opencontainers.image.version="${IMAGE_VERSION}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.base.name="ghcr.io/cloudnative-pg/postgresql:18.4-standard-trixie" \
      org.opencontainers.image.base.digest="sha256:7259c775ce18bdf668f17a68accb78e5bcc8074bbea9c8cdac974a8a8525a173" \
      org.opencontainers.image.licenses="Apache-2.0 AND LicenseRef-Timescale" \
      com.transpara.image.component="timescale" \
      com.transpara.image.pg-major="${PG_MAJOR}" \
      com.transpara.image.timescaledb-version="${TIMESCALEDB_VERSION}" \
      com.transpara.image.timescaledb-loader-version="${TIMESCALEDB_LOADER_VERSION}" \
      com.transpara.image.timescaledb-package-variant="${TIMESCALEDB_PACKAGE_VARIANT}" \
      com.transpara.image.toolkit-version="${TOOLKIT_VERSION}"

ENV PG_MAJOR="${PG_MAJOR}" \
    PATH="/usr/lib/postgresql/${PG_MAJOR}/bin:${PATH}"

USER root
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN set -eux; \
    case "${TIMESCALEDB_PACKAGE_VARIANT}" in \
      oss) timescaledb_package="timescaledb-2-oss-postgresql-${PG_MAJOR}" ;; \
      full) timescaledb_package="timescaledb-2-postgresql-${PG_MAJOR}" ;; \
      *) echo >&2 "TIMESCALEDB_PACKAGE_VARIANT must be 'oss' or 'full'"; exit 64 ;; \
    esac; \
    loader_package="timescaledb-2-loader-postgresql-${PG_MAJOR}"; \
    toolkit_package="timescaledb-toolkit-postgresql-${PG_MAJOR}"; \
    export DEBIAN_FRONTEND=noninteractive; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates curl gnupg; \
    install -d -m 0755 /usr/share/keyrings; \
    curl -fsSL https://packagecloud.io/timescale/timescaledb/gpgkey \
      | gpg --dearmor -o /usr/share/keyrings/timescaledb.gpg; \
    chmod 0644 /usr/share/keyrings/timescaledb.gpg; \
    echo "deb [signed-by=/usr/share/keyrings/timescaledb.gpg] https://packagecloud.io/timescale/timescaledb/debian/ trixie main" \
      > /etc/apt/sources.list.d/timescaledb.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      "${loader_package}=${TIMESCALEDB_LOADER_VERSION}" \
      "${timescaledb_package}=${TIMESCALEDB_VERSION}" \
      "${toolkit_package}=${TOOLKIT_VERSION}"; \
    dpkg-query -W "${loader_package}" "${timescaledb_package}" "${toolkit_package}"; \
    install -d -m 0755 /usr/local/share/transpara; \
    { \
      echo "pg_major=${PG_MAJOR}"; \
      echo "timescaledb_package=${timescaledb_package}"; \
      echo "timescaledb_version=${TIMESCALEDB_VERSION}"; \
      echo "timescaledb_loader_version=${TIMESCALEDB_LOADER_VERSION}"; \
      echo "toolkit_package=${toolkit_package}"; \
      echo "toolkit_version=${TOOLKIT_VERSION}"; \
      echo "base_image=${BASE_IMAGE}"; \
    } > /usr/local/share/transpara/timescale-image.env; \
    apt-get purge -y --auto-remove curl; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

USER 26
