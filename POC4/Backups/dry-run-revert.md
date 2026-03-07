# Dry Run Revert Instructions

**Tag:** `poc4-pre-dry-run`
**Created:** 2026-03-07

## What was changed for the dry run

1. `POC4/Governance/ScopeManifest/job-scope-manifest.json` — trimmed from 105 jobs to 5
2. `control.jobs` — 100 jobs set to `is_active = false`

## Revert steps

### 1. Restore the scope manifest

```bash
cd /workspace/AtcStrategy
git checkout poc4-pre-dry-run -- POC4/Governance/ScopeManifest/job-scope-manifest.json
```

### 2. Restore the control schema

pg_restore fails due to ownership (tables owned by dansdev, we connect as claude).
Use direct SQL instead:

```bash
PGPASSWORD=claude psql -h 172.18.0.1 -U claude -d atc -c "
  UPDATE control.jobs SET is_active = true;
  DELETE FROM control.task_queue;
  DELETE FROM control.job_runs WHERE triggered_by = 'queue';
"
```

### 3. Verify

```bash
PGPASSWORD=claude psql -h 172.18.0.1 -U claude -d atc \
  -c "SELECT count(*) FROM control.jobs WHERE is_active = true;"
# Should return 105
```

### 4. Clean up dry run artifacts

- Delete `POC4/Artifacts/` contents
- Delete `POC4/Errata/` contents
- Revert any V4 job configs/external modules added to MockEtlFramework:
  ```bash
  cd /workspace/MockEtlFramework
  git checkout poc4-pre-dry-run
  ```
