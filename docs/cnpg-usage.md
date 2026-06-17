# CloudNativePG Usage

Use an `ImageCatalog` for this image. The release tag starts with `pg18.4`,
which is useful for humans but is not a CloudNativePG auto-detectable major
version tag. The catalog declares `major: 18` explicitly.

## ImageCatalog

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: ImageCatalog
metadata:
  name: transpara-timescale
  namespace: transpara
spec:
  images:
    - major: 18
      image: registry.transpara.com/transpara/timescale:pg18.4-ts2.28.0-oss-toolkit1.23.0-cnpg-standard
```

After release, prefer the immutable digest form:

```yaml
image: registry.transpara.com/transpara/timescale:pg18.4-ts2.28.0-oss-toolkit1.23.0-cnpg-standard@sha256:<manifest-digest>
```

## Cluster

TimescaleDB must be preloaded at server start.

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: tstore-db
  namespace: transpara
spec:
  instances: 3
  imageCatalogRef:
    apiGroup: postgresql.cnpg.io
    kind: ImageCatalog
    name: transpara-timescale
    major: 18
  postgresql:
    shared_preload_libraries:
      - timescaledb
  storage:
    size: 100Gi
```

## Extension Activation

For manual validation, run SQL in the target database:

```sql
CREATE EXTENSION IF NOT EXISTS timescaledb;
CREATE EXTENSION IF NOT EXISTS timescaledb_toolkit;
```

For declarative CNPG management on CNPG versions that support `Database`
extension management:

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Database
metadata:
  name: tstore-db-app
  namespace: transpara
spec:
  name: app
  owner: app
  cluster:
    name: tstore-db
  extensions:
    - name: timescaledb
    - name: timescaledb_toolkit
```

The application path is already compatible with this image: `tstore-interface`
creates both extensions during schema setup. This image only makes the extension
files and shared libraries available inside the CNPG operand container.
