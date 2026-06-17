# Transpara CNPG Timescale Toolkit Image

This repository builds a Transpara-owned CloudNativePG PostgreSQL operand image
with TimescaleDB and TimescaleDB Toolkit installed.

The image intentionally does not use `timescale/timescaledb-ha`. CloudNativePG
manages PostgreSQL high availability; this image only supplies the PostgreSQL
operand plus the Timescale extensions required by tStore.

## Image Contract

- Image: `registry.transpara.com/transpara/timescale`
- Base: `ghcr.io/cloudnative-pg/postgresql:18.4-standard-trixie@sha256:7259c775ce18bdf668f17a68accb78e5bcc8074bbea9c8cdac974a8a8525a173`
- Platforms: `linux/amd64`, `linux/arm64`
- Default package variant: OSS TimescaleDB plus Toolkit
- Default tag: `pg18.4-ts2.28.0-oss-toolkit1.23.0-cnpg-standard`
- Full package tag, pending license approval: `pg18.4-ts2.28.0-toolkit1.23.0-cnpg-standard`

Published digest: not published yet. Before production use, publish the
multi-arch manifest and replace this line with the exact digest.

## Package Pins

Default OSS build:

- `timescaledb-2-loader-postgresql-18=2.28.0~debian13-1804`
- `timescaledb-2-oss-postgresql-18=2.28.0~debian13-1804`
- `timescaledb-toolkit-postgresql-18=1:1.23.0~debian13`

Full TimescaleDB build:

- `timescaledb-2-loader-postgresql-18=2.28.0~debian13-1804`
- `timescaledb-2-postgresql-18=2.28.0~debian13-1804`
- `timescaledb-toolkit-postgresql-18=1:1.23.0~debian13`

Do not publish either image variant until `docs/license-review.md` is resolved.

## Local Build

Build the default OSS variant:

```bash
docker build \
  --build-arg TIMESCALEDB_PACKAGE_VARIANT=oss \
  -t registry.transpara.com/transpara/timescale:pg18.4-ts2.28.0-oss-toolkit1.23.0-cnpg-standard \
  .
```

Build the full TimescaleDB variant after approval:

```bash
docker build \
  --build-arg TIMESCALEDB_PACKAGE_VARIANT=full \
  -t registry.transpara.com/transpara/timescale:pg18.4-ts2.28.0-toolkit1.23.0-cnpg-standard \
  .
```

Verify the image contract:

```bash
./scripts/verify-image.sh \
  registry.transpara.com/transpara/timescale:pg18.4-ts2.28.0-oss-toolkit1.23.0-cnpg-standard \
  linux/amd64
```

Run the SQL smoke test:

```bash
./scripts/smoke-test.sh \
  registry.transpara.com/transpara/timescale:pg18.4-ts2.28.0-oss-toolkit1.23.0-cnpg-standard \
  linux/amd64
```

Local `linux/arm64` builds require Docker binfmt/QEMU support. The GitHub
Actions workflow installs QEMU before Buildx.

## CI And Release

The image workflow builds and verifies `linux/amd64` and `linux/arm64`, runs the
amd64 SQL smoke test, runs a Trivy high/critical scan, and uploads CycloneDX
SBOM artifacts.

Registry publishing is manual. Use `workflow_dispatch` with `publish=true` only
after `docs/license-review.md` is approved; the workflow also requires
`license_review_complete=true` for publish attempts.

## Platform Wiring

This repo does not update Transpara Platform deployment paths yet. Keep
`tinstaller` and `tsystem-api` on their current image references until this image
has a published digest, license approval, and a separate platform integration PR.

Use `docs/cnpg-usage.md` for manual CNPG validation.
