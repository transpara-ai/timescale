# License Review Gate

Status: pending.

Do not publish `registry.transpara.com/transpara/timescale` for customer use and
do not wire it into `tinstaller` or `tsystem-api` until this review is complete.

## Components

| Component | Default package | License posture | Decision |
| --- | --- | --- | --- |
| CNPG PostgreSQL base | `ghcr.io/cloudnative-pg/postgresql:18.4-standard-trixie` | CNPG/PostgreSQL/Debian package licenses | Accepted as existing platform dependency |
| TimescaleDB OSS | `timescaledb-2-oss-postgresql-18` | OSS package variant from Timescale Packagecloud | Default for builds before review |
| TimescaleDB full | `timescaledb-2-postgresql-18` | Requires product/legal approval before redistribution | Pending |
| TimescaleDB Toolkit | `timescaledb-toolkit-postgresql-18` | Timescale License applies to source and binaries | Pending |

## Required Decision

1. Confirm whether Transpara may redistribute TimescaleDB Toolkit in a
   customer-facing image.
2. Confirm whether the full TimescaleDB package is allowed, or whether all
   customer images must use `timescaledb-2-oss-postgresql-18`.
3. Record the approved image tag in this file and in `README.md`.

If Toolkit redistribution is not approved, stop this image line. There is no
pure-OSS Toolkit package path in the plan.

## Build Outcomes

Approved OSS-only TimescaleDB plus Toolkit:

```bash
docker build \
  --build-arg TIMESCALEDB_PACKAGE_VARIANT=oss \
  -t registry.transpara.com/transpara/timescale:pg18.4-ts2.28.0-oss-toolkit1.23.0-cnpg-standard \
  .
```

Approved full TimescaleDB plus Toolkit:

```bash
docker build \
  --build-arg TIMESCALEDB_PACKAGE_VARIANT=full \
  -t registry.transpara.com/transpara/timescale:pg18.4-ts2.28.0-toolkit1.23.0-cnpg-standard \
  .
```

After publishing, capture the multi-arch manifest digest in `README.md` before
the image is treated as released.
