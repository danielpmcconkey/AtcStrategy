# Restore to Phase II Baseline

**Created:** 2026-03-06
**Purpose:** Roll back MockEtlFramework, AtcStrategy, proofmark, and the `control` schema to the state they were in at Phase II closure — before any Phase III work began.

---

## What This Baseline Contains

- **MockEtlFramework** @ `37b89a1` — 105 jobs, all active, all configs on disk, Steps 1-7 complete
- **AtcStrategy** @ `69a75f3` — All governance docs, close-outs, amendments, audit fixes applied
- **proofmark** @ `495d1f8` — v0.1.0 with queue runner, 217 tests passing
- **control schema** — 6 tables (jobs, job_runs, job_dependencies, task_queue, comparison_queue, proofmark_test_queue), clean state

## Backup Files

All in this directory (`AtcStrategy/POC4/Backups/`):

| File | Contents |
|------|----------|
| `control-schema-phase-ii-baseline.dump` | pg_dump custom format, data only, all 6 control tables |
| `control-schema-ddl-phase-ii-baseline.sql` | Plain SQL, schema structure only (CREATE TABLE, indexes, sequences) |

## Restore Procedure

### Prerequisites

- PostgreSQL 17 client tools (`pg_dump`, `pg_restore`, `psql`)
- Database access: host `172.18.0.1`, port `5432`, user `claude`, database `atc`
- Git access to all three repos

### Step 1: Restore Git Repos

```bash
# MockEtlFramework
cd /workspace/MockEtlFramework
git checkout phase-ii-baseline

# AtcStrategy
cd /workspace/AtcStrategy
git checkout phase-ii-baseline

# proofmark
cd /workspace/proofmark
git checkout phase-ii-baseline
```

To return to a branch afterward: `git checkout main` (or whatever branch you were on).

### Step 2: Restore Control Schema

**Option A: Data only (tables already exist, just need data reset)**

```bash
# Clear existing data
PGPASSWORD=claude psql -h 172.18.0.1 -U claude -d atc -c "
  TRUNCATE control.comparison_queue, control.proofmark_test_queue, control.task_queue, control.job_runs CASCADE;
  -- jobs and job_dependencies have foreign keys, truncate with CASCADE
  TRUNCATE control.jobs, control.job_dependencies CASCADE;
"

# Restore data
PGPASSWORD=claude /usr/lib/postgresql/17/bin/pg_restore -h 172.18.0.1 -U claude -d atc --data-only /workspace/AtcStrategy/POC4/Backups/control-schema-phase-ii-baseline.dump
```

**Option B: Full rebuild (tables are missing or schema changed)**

```bash
# Drop and recreate schema
PGPASSWORD=claude psql -h 172.18.0.1 -U claude -d atc -c "DROP SCHEMA IF EXISTS control CASCADE;"
PGPASSWORD=claude psql -h 172.18.0.1 -U claude -d atc -f /workspace/AtcStrategy/POC4/Backups/control-schema-ddl-phase-ii-baseline.sql
PGPASSWORD=claude /usr/lib/postgresql/17/bin/pg_restore -h 172.18.0.1 -U claude -d atc --data-only /workspace/AtcStrategy/POC4/Backups/control-schema-phase-ii-baseline.dump
```

### Step 3: Verify

```bash
# Check job count
PGPASSWORD=claude psql -h 172.18.0.1 -U claude -d atc -c "SELECT COUNT(*) FROM control.jobs WHERE is_active = true;"
# Expected: 105

# Check git tags
cd /workspace/MockEtlFramework && git describe --tags --exact-match HEAD
cd /workspace/AtcStrategy && git describe --tags --exact-match HEAD
cd /workspace/proofmark && git describe --tags --exact-match HEAD
# All should report: phase-ii-baseline
```

## Notes

- The `datalake` schema is NOT included in this backup. It contains source data that is large and independently reproducible.
- The `curated` and `double_secret_curated` schemas were empty at baseline and are not backed up.
- Sequence values (auto-increment counters) are not captured due to permission constraints. After a data-only restore, sequences will continue from their current values, which is fine — IDs just won't match exactly.
- The dump was taken with `--no-owner --no-privileges`. Table ownership may differ after restore (tables owned by `dansdev` will restore as `claude`). This is cosmetic and doesn't affect functionality.
