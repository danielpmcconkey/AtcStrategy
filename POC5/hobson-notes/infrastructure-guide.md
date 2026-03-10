# Infrastructure Guide — How to Do Things from Docker

You're in a Docker container. Two services run on the host outside your container.
You talk to them through Postgres. This doc tells you how.

---

## Postgres Connection

| Setting  | Value            |
|----------|------------------|
| Host     | `172.18.0.1`     |
| Port     | `5432`           |
| Database | `atc`            |
| User     | `claude`         |
| Password | `claude`         |

The `claude` role has write access to the `atc` database — you can CREATE TABLE,
INSERT, UPDATE, etc. The data lake tables (what ETL jobs query from) are in
various schemas in this same database.

---

## MockEtlFramework (the ETL engine)

A C# / .NET 8 application running on the host. It polls a task queue in Postgres
for work, reads a JSON job configuration, runs the job's pipeline (source data,
transform, write output), and writes output files to a host-side directory.

**You have a reference copy of its code** at `/workspace/MockEtlFramework/`.
Study it freely. You cannot modify the running version.

### Submitting an ETL job

Insert a row into `control.task_queue`:

```sql
INSERT INTO control.task_queue (job_name, effective_date, status)
VALUES ('CustomerAccountSummary', '2024-10-01', 'Pending');
```

The framework picks up `Pending` rows, claims them via `FOR UPDATE SKIP LOCKED`,
runs the job, and sets status to `Succeeded` or `Failed`.

To run a job across the full date range:

```sql
INSERT INTO control.task_queue (job_name, effective_date, status)
SELECT 'CustomerAccountSummary', d.dt::date, 'Pending'
FROM generate_series('2024-10-01'::date, '2024-12-31'::date, '1 day') d(dt);
```

### Checking ETL results

```sql
SELECT status, COUNT(*) FROM control.task_queue
WHERE job_name = 'CustomerAccountSummary'
GROUP BY status;
```

Failed tasks have an `error_message` column with details.

### Where output goes

ETL output lands on the host filesystem. You have **read-only** access to it
via a Docker mount. The path inside your container depends on the job — check
the job's JSON conf for its output directory structure.

---

## Proofmark (the comparison engine)

A Python application running on the host. It compares two sets of output files
(your RE output vs. the original output) and tells you PASS or FAIL.

**You have a reference copy of its code** at `/workspace/proofmark/`.
Study it freely. You cannot modify the running version.

### Submitting a comparison

Insert a row into `control.proofmark_test_queue`:

```sql
INSERT INTO control.proofmark_test_queue (config_path, lhs_path, rhs_path, job_key, date_key)
VALUES (
  '{ETL_ROOT}/path/to/proofmark-config.yaml',
  '{ETL_ROOT}/Output/curated/JobDir/TableDir/2024-10-01/',
  '{ETL_RE_OUTPUT}/JobDir/TableDir/2024-10-01/',
  'CustomerAccountSummary',
  '2024-10-01'
);
```

**Path tokens:** `{ETL_ROOT}` and `{ETL_RE_OUTPUT}` are placeholders that
Proofmark resolves on the host side via environment variables. Always use these
tokens — never hardcode absolute paths. The host resolves them to directories
you can't see from Docker.

- `{ETL_ROOT}` → the original ETL output (the "known good" files)
- `{ETL_RE_OUTPUT}` → your RE output (what you're testing)
- `lhs_path` = original output (LHS = left-hand side)
- `rhs_path` = your RE output (RHS = right-hand side)

### Checking comparison results

```sql
SELECT task_id, status, result, error_message
FROM control.proofmark_test_queue
WHERE job_key = 'CustomerAccountSummary' AND date_key = '2024-10-01';
```

- `status`: Pending → Running → Succeeded / Failed
- `result`: `PASS` or `FAIL` (only set when status = Succeeded)
- `result_json`: Full JSONB comparison report with details on mismatches
- `error_message`: Set when status = Failed (Proofmark itself errored)

### Proofmark configs

Each comparison needs a YAML config file that tells Proofmark how to read the
output (CSV vs Parquet, column classifications, etc.). These configs are
job-specific. Check the Proofmark reference code and documentation at
`/workspace/proofmark/Documentation/` for the config format.

---

## Key Database Tables

| Table | Purpose |
|-------|---------|
| `control.jobs` | Job registry — ID, name, conf path, active flag |
| `control.job_dependencies` | Dependency graph between jobs (SameDay / Latest) |
| `control.task_queue` | ETL FW work queue — you INSERT, framework executes |
| `control.proofmark_test_queue` | Proofmark work queue — you INSERT, Proofmark compares |

---

## Reference Material in Your Workspace

| What | Where |
|------|-------|
| ETL framework code | `/workspace/MockEtlFramework/` |
| Proofmark code | `/workspace/proofmark/` |
| Original job configurations | `/workspace/MockEtlFramework/JobExecutor/Jobs/` |
| Original output (reference copy) | `/workspace/MockEtlFramework/Output/curated/` |
| Job list (105 jobs) | `AtcStrategy/POC5/hobson-notes/job-scope-manifest.json` |

The original output in your workspace is a **snapshot** for study purposes.
Proofmark compares against the real output on the host, not your copy.
