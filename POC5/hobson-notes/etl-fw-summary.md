# MockEtlFramework — Operational Summary for POC5

## What It Is

C# / .NET 8 reproduction of a production PySpark ETL framework. Reads JSON job confs, runs an ordered chain of modules (DataSourcing, Transformation, DataFrameWriter, CsvFileWriter, ParquetFileWriter, External), threads shared state through the pipeline.

## Queue/Claim Pattern

- Table: `control.task_queue`
- Claim: `FOR UPDATE SKIP LOCKED` (Postgres row-level locking)
- Threading: 5 threads (4 parallel + 1 serial), each with own DB connection
- Lifecycle: polls queue, exits when all threads find empty queue (unlike Proofmark which keeps polling)

## Key Tables

- `control.jobs` — job registrations (ID, name, conf path, active flag)
- `control.job_dependencies` — dependency graph (SameDay / Latest)
- `control.job_runs` — run history (run_date, min/max effective_date, status)
- `control.task_queue` — queue items (job_name, effective_date, execution_mode, status)

## How to Launch

```
JobExecutor --service                      # long-running queue mode
JobExecutor <yyyy-MM-dd>                  # run all active jobs for date
JobExecutor <yyyy-MM-dd> <job_name>       # run one job for date
```

Queue mode (`--service`) delegates to `TaskQueueService`. Populate queue via SQL INSERT, executor picks up work automatically.

## What It Outputs

File writers produce output under `Output/poc4/{jobDirName}/{tableDirName}/{effective_date}/`. Formats: CSV (with optional trailers) and Parquet. Also writes to Postgres via DataFrameWriter.

## Config

- Postgres password: hex-encoded UTF-16 LE in `PGPASS` env var
- Job confs: JSON files under `JobExecutor/Jobs/`
- Output paths are relative to solution root

## POC5 Relevance

Run as a host-side service. Agents in Docker add tasks to `control.task_queue` via Postgres. ETL FW picks them up, runs jobs, writes output to host-side directory. Agents get read-only access to that output directory.
