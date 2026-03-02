# MockEtlFramework Rearchitect Spec

**Written:** 2026-03-02
**Authors:** Dan + BD
**Status:** Design agreed, pre-implementation

---

## Problem Statement

Each invocation of `dotnet run --project JobExecutor` pays the full cost of:
- .NET runtime startup
- JIT compilation of entire Lib/ and all external modules
- Process teardown

For a single effective date (101 jobs), this takes ~20 minutes wall clock. For 92 effective dates via a shell script loop (92 separate `dotnet run` calls), that's ~30 hours. Both C.6 (V1 baseline) and D.1 (V2 run) need full 92-date runs, totaling ~60 hours of compute.

Additionally, the `succeededToday` check in `JobExecutorService` uses the wall-clock `run_date` to skip jobs that already succeeded "today." When running a date-range loop on a single calendar day, this causes all jobs to be skipped after the first effective date succeeds. C.6 and D.1 both hit this problem.

---

## Solution: Long-Running Background Executor with Task Queue

### Core Concept

Replace the "run once and exit" model with a long-running process that polls a task queue. Fire it once at the start of a phase, leave it running. The dotnet startup and JIT cost is paid exactly once.

### Task Queue Table

```sql
CREATE TABLE control.task_queue (
    task_id SERIAL PRIMARY KEY,
    job_name VARCHAR(255) NOT NULL,
    effective_date DATE NOT NULL,
    execution_mode VARCHAR(10) NOT NULL DEFAULT 'parallel',  -- 'parallel' or 'serial'
    status VARCHAR(20) NOT NULL DEFAULT 'Pending',           -- Pending, Running, Succeeded, Failed
    queued_at TIMESTAMP NOT NULL DEFAULT NOW(),
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    error_message TEXT
);
CREATE INDEX idx_task_queue_status ON control.task_queue(status);
```

### Threading Model

**5 threads total:**
- **4 parallel threads** — each independently polls for the next `Pending` task where `execution_mode = 'parallel'`, executes it, loops
- **1 serial thread** — same pattern but filters on `execution_mode = 'serial'`

All 5 threads run concurrently. The serial thread ensures ordering for jobs that have self-dependencies (e.g., append-mode jobs where date N depends on date N-1).

### Task Claim (Race Condition Prevention)

Each thread claims work with a single atomic query:

```sql
UPDATE control.task_queue
SET status = 'Running', started_at = NOW()
WHERE task_id = (
    SELECT task_id FROM control.task_queue
    WHERE status = 'Pending' AND execution_mode = 'parallel'
    ORDER BY task_id
    FOR UPDATE SKIP LOCKED
    LIMIT 1
)
RETURNING *;
```

`FOR UPDATE SKIP LOCKED` prevents two threads from grabbing the same task. Postgres does the heavy lifting.

**Critical:** Each thread must have its own `DbConnection` / `DbContext`. EF Core contexts are not thread-safe.

### Execution Mode Assignment

| Writer Type | Write Mode | Execution Mode | Reason |
|-------------|-----------|----------------|--------|
| CsvFileWriter | Overwrite | parallel | Each date replaces previous. No dependency on prior dates. |
| CsvFileWriter | Append | serial | Rows accumulate. Date order matters. |
| ParquetFileWriter | Overwrite | parallel | Each date replaces part files. No dependency. |
| ParquetFileWriter | Append | serial | Part files accumulate. Date order matters. |
| External | varies | serial (safe default) | Unknown I/O behavior. Default to safe. |

Rough split: ~75 parallel, ~26 serial. The parallel pool does the bulk of the work.

### Empty Queue Behavior

When a thread finds no pending tasks of its type: `Thread.Sleep(5000)`, then poll again. No busy-waiting.

### Error Handling

**Per-task:** Each thread wraps its job execution in `try { ... } finally { cleanup }`.
- On success: mark task `Succeeded`
- On exception: mark task `Failed`, record error message
- On process kill mid-task: task stays `Running` (orphaned)

**Monitoring rule:** `Succeeded` = trust the output. Anything else (`Failed`, `Running` from a dead process) = trash the output, re-queue if desired.

**No SIGINT "finish first" handler.** If the process needs to die, let it die. A stuck job that won't respond to Ctrl+C is worse than a partial output file. The monitoring/orchestration layer handles cleanup and re-queuing.

**Main thread:** One grand `try { ... } catch { ... } finally { ... }` that ensures all threads are signaled to stop on unhandled exceptions.

### `succeededToday` Check

**Remove it.** The task queue model makes it redundant — if a task is in the queue, it should be executed. The queue is the source of truth for what needs to run, not the job_runs history.

### Invocation

```bash
# Start the executor (runs until queue is empty + idle, or killed)
dotnet run --project JobExecutor -- --service

# Populate queue, executor picks up work automatically
# Monitor via SQL queries against control.task_queue
```

### Queue Population

```sql
-- Example: all V2 jobs for full date range
INSERT INTO control.task_queue (job_name, effective_date, execution_mode)
SELECT j.job_name, d.dt::date,
    CASE
        WHEN j.writer_mode = 'Append' OR j.writer_type = 'External' THEN 'serial'
        ELSE 'parallel'
    END
FROM control.jobs j
CROSS JOIN generate_series('2024-10-01'::date, '2024-12-31'::date, '1 day') d(dt)
WHERE j.is_active = true AND j.job_name LIKE '%V2'
ORDER BY d.dt, j.job_name;
```

Note: The `writer_mode` / `writer_type` columns may not exist on `control.jobs` today. Execution mode assignment might need to come from job conf files or a manual mapping. Implementation detail to work out.

### Monitoring Queries

```sql
-- Overall progress
SELECT status, COUNT(*) FROM control.task_queue GROUP BY status;

-- Failed tasks
SELECT job_name, effective_date, error_message
FROM control.task_queue WHERE status = 'Failed'
ORDER BY job_name, effective_date;

-- Per-job summary
SELECT job_name,
  SUM(CASE WHEN status='Succeeded' THEN 1 ELSE 0 END) as ok,
  SUM(CASE WHEN status='Failed' THEN 1 ELSE 0 END) as fail,
  SUM(CASE WHEN status='Pending' THEN 1 ELSE 0 END) as pending
FROM control.task_queue
GROUP BY job_name ORDER BY job_name;
```

---

## Scope of Changes

| Component | Change |
|-----------|--------|
| `JobExecutor/Program.cs` | Add `--service` mode that launches the queue executor |
| `Lib/Control/` (new) | `TaskQueueService.cs` — polling loop, thread management, task claim |
| `Lib/Control/JobExecutorService.cs` | Remove `succeededToday` check |
| Database | New `control.task_queue` table |
| `JobExecutorService.cs` | Unchanged otherwise — still used by individual task execution within threads |

---

## What This Enables

- **C.6 redo:** Populate queue with 101 V1 jobs × 92 dates. Start service. Walk away.
- **D.1:** Same pattern with V2 jobs.
- **D.4 resolution:** Drop 92 tasks for a single fixed job. Executor picks them up immediately if still running.
- **Estimated speedup:** 4x on parallel jobs (75% of portfolio), plus elimination of 91 cold starts. Exact numbers TBD from benchmark.
