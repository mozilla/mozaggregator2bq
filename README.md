# mozaggregator2bq

A set of scripts for loading Firefox Telemetry aggregates into BigQuery. These
aggregates power the Telemetry Dashboard and Evolution Viewer.

## Quickstart

### Interacting with the database

To start a psql instance with the read-only replica of the production Postgres
instance, run the following commands. Ensure that you have the appropriate AWS
credentials.

```bash
source scripts/export_credentials_s3

PGPASSWORD=$POSTGRES_PASS psql \
    --host="$POSTGRES_HOST" \
    --username="$POSTGRES_USER" \
    --dbname="$POSTGRES_DB"
```

An example query:

```sql
-- list all aggregates by build_id
select tablename
from pg_catalog.pg_tables
where schemaname='public' and tablename like 'build_id%';

--  build_id_aurora_0_20130414
--  build_id_aurora_0_20150128
--  build_id_aurora_0_20150329
--  build_id_aurora_1_20130203
--  build_id_aurora_1_20150604
-- ...

-- list all aggregates by submission_date
select tablename
from pg_catalog.pg_tables
where schemaname='public' and tablename like 'submission_date%';

--  submission_date_beta_1_20151027
--  submission_date_nightly_40_20151029
--  submission_date_beta_39_20151027
--  submission_date_nightly_1_20151025
--  submission_date_nightly_39_20151031
-- ...
```

### Database dumps by aggregate type and date

To start dumping data, run the following commands.

```bash
source scripts/export_credentials_s3

time DATA_DIR=data AGGREGATE_TYPE=submission DS_NODASH=20191201 scripts/pg_dump_by_day
# 23.92s user 1.97s system 39% cpu 1:05.48 total

time DATA_DIR=data AGGREGATE_TYPE=build_id DS_NODASH=20191201 scripts/pg_dump_by_day
# 3.47s user 0.49s system 24% cpu 16.188 total
```

This should result in gzipped files in the following hierarchy.

```bash
data
├── [  96]  build_id
│   └── [ 128]  20191201
│       ├── [8.4M]  474306.dat.gz
│       └── [1.6K]  toc.dat
└── [  96]  submission
    └── [3.2K]  20191201
        ├── [ 74K]  474405.dat.gz
        ├── [ 48K]  474406.dat.gz
        ....
        ├── [1.8M]  474504.dat.gz
        └── [ 93K]  toc.dat

4 directories, 103 files
```

See the [`pg_dump` documentation](https://www.postgresql.org/docs/9.1/app-pgdump.html) for details on the file format. 

```bash
$ gzip -cd data/submission/20191201/474405.dat.gz | head -n3
{"os": "Windows_NT", "child": "false", "label": "", "metric": "A11Y_INSTANTIATED_FLAG", "osVersion": "6.3", "application": "Firefox", "architecture": "x86"}    {0,2,0,2,2}
{"os": "Windows_NT", "child": "false", "label": "", "metric": "A11Y_CONSUMERS", "osVersion": "6.3", "application": "Firefox", "architecture": "x86"}    {0,0,0,0,0,0,0,0,0,0,2,0,20,2}
{"os": "Windows_NT", "child": "false", "label": "", "metric": "A11Y_ISIMPLEDOM_USAGE_FLAG", "osVersion": "6.3", "application": "Firefox", "architecture": "x86"}        {2,0,0,0,2}
```
