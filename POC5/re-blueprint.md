# RE Blueprint — Lessons Learned & Reusable Patterns

Living document. Updated as we RE more jobs.

---

## Job Conf Patterns

### Output Directory
RE job confs MUST use `{ETL_RE_OUTPUT}` token for `outputDirectory`, not a relative path. Relative paths resolve against `{ETL_ROOT}` on the host, which writes to Hobson's copy instead of the sandbox.

```json
"outputDirectory": "{ETL_RE_OUTPUT}"
```

The writer appends `jobDirName/outputTableDirName/date/fileName` automatically.

### Job Naming
Suffix with `_RE`: `SecuritiesDirectory_RE`. The `jobName` in the conf must match the `job_name` in `control.jobs`.

### Job Registration
```sql
INSERT INTO control.jobs (job_name, description, job_conf_path, is_active)
VALUES (
  'JobName_RE',
  'RE of JobName - [what changed]',
  '{ETL_RE_ROOT}/EtlReverseEngineering/job-confs/job_name_re.json',
  true
);
```

**Gotcha:** The ETL framework caches the job registry at startup. New jobs aren't visible until restart. (Fix pending — Hobson adding lazy reload.)

---

## Task Queue Patterns

### Queue All 92 Dates
```sql
INSERT INTO control.task_queue (job_name, effective_date, status)
SELECT 'JobName_RE', d.dt::date, 'Pending'
FROM generate_series('2024-10-01'::date, '2024-12-31'::date, '1 day') d(dt);
```

### Reset Failed Tasks
```sql
UPDATE control.task_queue SET status = 'Pending', error_message = NULL
WHERE job_name = 'JobName_RE' AND status = 'Failed';
```

---

## Proofmark Patterns

### Date Formatting
Use `to_char(d.dt, 'YYYY-MM-DD')` for date strings in paths. Do NOT use `d.dt::text` — Postgres renders it with timezone suffix (`2024-10-18 00:00:00-04`).

### CSV Jobs — File Paths
CSV reader expects a **file path**, not a directory. Include the filename.

```sql
INSERT INTO control.proofmark_test_queue (config_path, lhs_path, rhs_path, job_key, date_key)
SELECT
  '{ETL_RE_ROOT}/EtlReverseEngineering/proofmark-configs/JobName.yaml',
  '{ETL_ROOT}/Output/curated/{jobDirName}/{tableDirName}/' || to_char(d.dt, 'YYYY-MM-DD') || '/{fileName}',
  '{ETL_RE_OUTPUT}/{jobDirName}/{tableDirName}/' || to_char(d.dt, 'YYYY-MM-DD') || '/{fileName}',
  'JobName',
  d.dt::date
FROM generate_series('2024-10-01'::date, '2024-12-31'::date, '1 day') d(dt);
```

### Parquet Jobs — Directory Paths
Parquet reader expects a **directory** containing `part-*.parquet` files. Use the directory path (with trailing slash or not — TBD, haven't tested yet).

### Proofmark Config Location
`{ETL_RE_ROOT}/EtlReverseEngineering/proofmark-configs/{JobName}.yaml`

### Minimal CSV Config (no fuzzy, no excluded, no trailer)
```yaml
comparison_target: JobName
reader: csv
csv:
  header_rows: 1
  trailer_rows: 0
```

### CSV Config with Trailer
```yaml
comparison_target: JobName
reader: csv
csv:
  header_rows: 1
  trailer_rows: 1
```

Jobs with non-deterministic trailers (timestamp-based) will need `trailer_rows: 1` to skip comparison of the trailer line. Jobs: CreditScoreAverage, DailyTransactionVolume, TopBranches, ExecutiveDashboard.

---

## Directory Conventions

| What | Where |
|------|-------|
| RE job confs | `/workspace/EtlReverseEngineering/job-confs/{job_name}_re.json` |
| BRD/FSD/test docs | `/workspace/EtlReverseEngineering/jobs/{JobName}/` |
| Proofmark configs | `/workspace/EtlReverseEngineering/proofmark-configs/{JobName}.yaml` |
| RE output | `{ETL_RE_OUTPUT}/{jobDirName}/{tableDirName}/{date}/{fileName}` |

---

## RE Workflow (per job)

1. Read original job conf
2. Check original output (format, row count, stability across dates)
3. Write BRD (numbered requirements with evidence, flag anti-patterns)
4. Write FSD (numbered specs traceable to BRDs, document changes from V1)
5. Write test strategy (traceable to FSDs)
6. Write `_re` job conf (remediate anti-patterns, use `{ETL_RE_OUTPUT}`)
7. Write Proofmark config YAML

> **CRITICAL ORDERING CONSTRAINT:** Steps 6-7 (write job conf and Proofmark config files) MUST complete and be verified on disk (`test -f path`) BEFORE steps 8-11 (register job, queue tasks, queue Proofmark). The framework and Proofmark workers pick up queued items immediately. If config files don't exist yet, the first task fails and fail-fast cascades SKIPs across the entire batch. For Append mode jobs this is catastrophic -- a cascaded failure means ALL 92 dates fail.

8. Register job in `control.jobs`
9. Queue 92 dates in `control.task_queue`
10. Verify all Succeeded
11. Queue 92 Proofmark comparisons in `control.proofmark_test_queue`
12. Verify 92/92 PASS

---

## Token Reference

| Token | Resolves to (container) | Resolves to (host) | Used by |
|-------|------------------------|--------------------|---------|
| `{ETL_ROOT}` | `/workspace/MockEtlFramework` | `/media/dan/fdrive/codeprojects/MockEtlFramework/` | ETL FW, Proofmark |
| `{ETL_RE_ROOT}` | `/workspace` | `/media/dan/fdrive/ai-sandbox/workspace/` | ETL FW (job conf paths), Proofmark (config paths) |
| `{ETL_RE_OUTPUT}` | `/workspace/MockEtlFramework/Output/curated_re` | host equivalent | ETL FW (output dir), Proofmark (rhs paths) |
