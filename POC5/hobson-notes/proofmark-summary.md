# Proofmark — Operational Summary for POC5

## What It Is

Python 3.11 CLI tool. Compares two file-based dataset outputs (LHS vs RHS) via a hash-sort-diff pipeline. Produces JSON equivalence reports. Supports CSV and Parquet. Configurable column classification: STRICT / FUZZY (with tolerance) / EXCLUDED.

## Queue/Claim Pattern

- Default table: `comparison_queue` (configurable via `--table`, e.g. `control.proofmark_test_queue`)
- Claim: `FOR UPDATE SKIP LOCKED` — same Postgres pattern as ETL FW
- Threading: N daemon worker threads (default 5, configurable via `--workers`)
- Lifecycle: **does NOT self-terminate** when queue is empty — keeps polling at `--poll-interval` (default 5s). Operator kills via SIGINT/SIGTERM. Graceful shutdown waits up to 30s for in-flight tasks.

## Key Table Schema

```sql
CREATE TABLE IF NOT EXISTS comparison_queue (
    task_id       SERIAL PRIMARY KEY,
    config_path   TEXT NOT NULL,        -- path to YAML config
    lhs_path      TEXT NOT NULL,        -- path to LHS output
    rhs_path      TEXT NOT NULL,        -- path to RHS output
    job_key       TEXT,                 -- optional grouping key
    date_key      DATE,                 -- optional date key
    status        VARCHAR(20) DEFAULT 'Pending',  -- Pending → Running → Succeeded/Failed
    result        VARCHAR(10),          -- PASS or FAIL
    started_at    TIMESTAMP,
    completed_at  TIMESTAMP,
    result_json   JSONB,               -- full comparison report
    error_message TEXT,
    created_at    TIMESTAMP DEFAULT NOW()
);
```

## How to Launch

```
proofmark serve --db <dsn> [--table <name>] [--workers <n>] [--poll-interval <s>] [--init-db]
proofmark compare --config <yaml> --left <path> --right <path> [--output <file>]
```

Optional dependency: `pip install proofmark[queue]` for `psycopg2-binary`.

## What It Outputs

- JSON report (file or stdout) with equivalence result
- In queue mode: stores full report as JSONB in `result_json` column, extracts PASS/FAIL to `result` convenience column

## POC5 Relevance

Run as host-side service. Agents in Docker insert comparison tasks into the queue table via Postgres (config path, LHS path, RHS path). Proofmark picks them up, reads the output files (host-side), writes results back to Postgres. Agents read results from the queue table.
