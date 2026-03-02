# D.1 Post-Mortem and Recommendations

**Written:** 2026-03-02 by Basement Dweller
**Context:** D.1 crashed. BBC launched 20 parallel proofmark runs, pegged Dan's PC, forced a hard power cycle. Before the crash, results were showing systemic 0% match rates across all completed comparisons. This doc covers what went wrong and how to move forward.

---

## What Happened

### The Crash (Not the Interesting Part)
BBC ran a background shell script that kicked off 20 parallel proofmark comparisons. On a GTX 1080 / consumer-grade workstation, this was too much. Dan lost UI control for 30 minutes, then had to hard power cycle his Linux box. 32 of 101 proofmark reports landed before the crash.

**Verdict:** Dumb of us. Cap parallelism. Moving on.

### The Systemic Failures (The Interesting Part)

All 32 completed proofmark reports: **FAIL. Zero passes. 0.0% match rate on almost everything.**

This is not the saboteur (12 surgical mutations). This is everything failing. Two distinct root causes:

#### Root Cause 1: Date Mismatch — V2 Only Ran for 2024-10-01

Database evidence:
- 99 V2 jobs succeeded for exactly ONE date: **2024-10-01**
- 2 V2 jobs (`RepeatOverdraftCustomersV2`, `SuspiciousWireFlagsV2`) failed on every date
- V1 baseline output reflects **2024-12-31** (the last date in the 92-day range)
- V2 output reflects **2024-10-01** (the first and only successful date)
- Every proofmark comparison is comparing October 1st data to December 31st data

**Why this happened:** The `JobExecutorService` was designed for production-style auto-advance: "gap-fill from last succeeded date to today." "Today" during D.1 was 2026-03-02, so after succeeding for 2024-10-01, the next auto-advance attempt would try to gap-fill ~520 days — not the intended 91. With `Overwrite` mode writers, each date's output replaces the previous, so only the final date's output survives in the file.

The V1 baseline run (C.6) worked around this by resetting `job_runs` between date iterations — a hack that forced the framework to re-execute for each target date. D.1 either didn't use this hack or the background script didn't implement the date loop correctly.

**Evidence from proofmark reports:**
- CSV trailers: `TRAILER|3|2024-12-31` (V1) vs `TRAILER|3|2024-10-01` (V2)
- Data rows show October 2024 dates on RHS (V2), December 2024 on LHS (V1)
- Row count mismatches on Append-mode jobs (V1 accumulated 92 days, V2 has 1 day)

#### Root Cause 2: Parquet Type Mismatches

Every Parquet-output V2 job fails on schema before data comparison even starts:
- `int32` (V1) vs `int64` (V2)
- `decimal128(38,18)` (V1) vs `double` (V2)
- Some jobs: `int32` (V1) vs `string` (V2)

This is a real code-level issue in the V2 implementations. The V2 SQL (running through SQLite → DataFrame → Parquet.Net) infers different column types than V1. This won't go away by fixing the date loop — it's a separate problem that Phase D resolution agents were designed to handle.

---

## The MockEtlFramework Design Problem

The framework's auto-advance model (gap-fill to today) doesn't support the use case we actually need: **replay a specific date range for comparison purposes.** The C.6 hack (reset `job_runs` between iterations) worked but it's fragile and unintuitive. We shouldn't be hacking around the framework's execution model for a core POC operation.

**The CLAUDE.md directive "NEVER modify files in Lib/" was written for the blind lead — to prevent the reverse-engineering agents from changing the framework they're supposed to be building against.** For infrastructure changes to support the POC execution mechanics, modifying the framework is appropriate and necessary. The blind lead still never touches `Lib/`. We (orchestrator + Dan) make infrastructure changes.

---

## Recommendation: Don't Scrap POC3

Phases A through C are solid:
- 101 BRDs written and reviewed (Phase A)
- 101 FSDs, test plans, V2 configs, V2 processors (Phase B, Run 2)
- 12 code-level saboteur mutations planted (B→C break)
- 101 proofmark configs generated (Phase C)
- Build passes, tests pass (Phase C)
- V1 baseline populated (Phase C — C.6)

All of that is good work. The problem is purely in D.1 execution mechanics.

### What Needs to Happen

1. **Fix the MockEtlFramework execution model** (see proposals below)
2. **Clean V2 run history** — delete all V2 entries from `control.job_runs`
3. **Clean V2 output** — wipe `Output/double_secret_curated/`
4. **Re-run D.1** with proper date-range execution, sequentially, NOT 20 in parallel
5. **Re-run D.2** (proofmark comparisons)
6. **Then** assess the real failure landscape — saboteur hits + Parquet type mismatches + any legitimate logic errors
7. Phase D resolution agents handle the real failures with full token budget

---

## Proposal: MockEtlFramework as a Task Queue Service

### Concept
Instead of the current "run once and gap-fill to today" model, redesign the executor as a long-running service that pulls work from a queue.

**Queue entry = one (job_name, effective_date) pair.** The service:
1. Checks the queue for the next task
2. Executes that single job for that single effective date
3. Records success/failure
4. Checks queue again
5. No tasks? Sleep 30 seconds, check again

### Why This Is Better
- **Matches real-world ETL:** Production Spark jobs execute one job + one date. A scheduler (Airflow, Control-M, etc.) decides what to run and when. The executor doesn't decide — it just executes what it's told.
- **Eliminates auto-advance confusion:** No more gap-fill logic, no more "today" as a moving target, no more job_runs reset hacks. The queue says "run X for 2024-10-15" and that's exactly what happens.
- **Trivial to populate for POC use:** Generate the full work queue with a simple script: 101 jobs × 92 dates = 9,292 tasks. Load them all, start the service, let it grind.
- **Clean observability:** Queue depth = remaining work. Completed tasks = progress. Failed tasks = investigation targets. Simple.
- **Reusable across phases:** C.6 (V1 baseline), D.1 (V2 run), and any future re-runs all use the same mechanism. No more phase-specific execution hacks.

### Implementation Sketch

**New table: `control.task_queue`**
```sql
CREATE TABLE control.task_queue (
    task_id SERIAL PRIMARY KEY,
    job_name VARCHAR(255) NOT NULL,
    effective_date DATE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'Pending',  -- Pending, Running, Succeeded, Failed
    queued_at TIMESTAMP NOT NULL DEFAULT NOW(),
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    error_message TEXT
);
CREATE INDEX idx_task_queue_status ON control.task_queue(status);
```

**Modified JobExecutor entry point:**
- New mode: `dotnet run --project JobExecutor -- --service`
- Starts a loop: poll `task_queue` for next `Pending` task (ORDER BY task_id), mark `Running`, execute, mark `Succeeded`/`Failed`, repeat
- On empty queue: sleep 30 seconds, poll again
- Graceful shutdown: SIGINT/SIGTERM finishes current task, then exits
- Optional: `dotnet run --project JobExecutor -- --service --workers 3` for N worker threads (controlled parallelism)

**Queue population script:**
```bash
# Generate full work queue for V2 jobs across date range
PGPASSWORD=claude psql -h 172.18.0.1 -U claude -d atc -c "
INSERT INTO control.task_queue (job_name, effective_date)
SELECT j.job_name, d.dt::date
FROM control.jobs j
CROSS JOIN generate_series('2024-10-01'::date, '2024-12-31'::date, '1 day') d(dt)
WHERE j.job_name LIKE '%V2' AND j.is_active = true
ORDER BY d.dt, j.job_name;"
```

### What Changes in `Lib/`
- **New file:** `Lib/Control/TaskQueueService.cs` — the polling loop, task claim, status updates
- **Modified:** `JobExecutor/Program.cs` — add `--service` mode that delegates to `TaskQueueService` instead of `JobExecutorService`
- **Unchanged:** `JobRunner`, all modules, `JobExecutorService` (the old auto-advance mode still exists for backwards compatibility)
- **Key detail:** Each task runs with `effectiveDateOverride` set to the task's effective_date. This already exists in `JobExecutorService` — it's the single-date backfill mode. The task queue just feeds it one date at a time.

### Risks and Mitigations
- **Performance:** One dotnet process polling a DB is cheap. The expensive part is job execution, which is the same cost regardless of execution model.
- **Failure handling:** A failed task stays in the queue as `Failed`. It doesn't block other tasks (no dependency enforcement in the queue — that's the orchestrator's job if needed).
- **Graceful shutdown:** The service should handle SIGINT cleanly. Mark current task as `Failed` with "interrupted" message if killed mid-execution.

---

## Proposal: Proofmark Batch Mode / Service

### The Question: Is It Worth It?

Proofmark is Python. Launching `python3 -m proofmark compare ...` 101 times is way lighter than 101 `dotnet run` invocations. Python startup is ~100ms; dotnet startup + JIT is 1-2 seconds. The comparison itself is I/O-bound (reading files, hashing rows), not CPU-bound.

**My take: batch mode yes, daemon no.**

A full daemon with queue polling is overkill for Proofmark. The comparisons are fast (seconds to low minutes each), stateless (no DB writes, no side effects beyond the output JSON), and naturally sequential. A batch mode that reads a manifest and churns through it is the sweet spot.

### Batch Mode Design

**Manifest file (CSV or YAML):**
```csv
config,lhs,rhs,output
POC3/proofmark_configs/account_balance_snapshot.yaml,Output/curated/account_balance_snapshot,Output/double_secret_curated/account_balance_snapshot,POC3/logs/proofmark_reports/account_balance_snapshot.json
POC3/proofmark_configs/account_customer_join.yaml,Output/curated/account_customer_join,Output/double_secret_curated/account_customer_join,POC3/logs/proofmark_reports/account_customer_join.json
...
```

**New CLI command:**
```bash
python3 -m proofmark batch --manifest POC3/proofmark_batch.csv [--continue-on-error] [--parallel 4]
```

- Reads the manifest
- Runs each comparison sequentially (or with controlled parallelism via `--parallel`)
- `--continue-on-error`: don't stop on the first FAIL (default behavior for batch)
- Outputs a summary at the end: X PASS, Y FAIL, Z ERROR
- Each individual comparison still produces its own JSON report at the specified output path

### What Changes in Proofmark
- **New file:** `proofmark/batch.py` (or add to existing CLI) — manifest parser + loop
- **New CLI entry:** `proofmark batch` command
- **Unchanged:** Core comparison logic, config parsing, report generation — batch mode just calls the existing `compare` function in a loop

### Why Not a Daemon
- Comparisons are stateless — no queue state to manage, no "running" status to track
- Comparisons are fast — no 30-second polling loops needed; just run them all and you're done in minutes
- No side effects — if one fails, it doesn't affect others. No need for task isolation.
- The manifest IS the queue — you don't need a database table. A file is simpler, versionable, and inspectable.

### Manifest Generation
Could be a simple script that reads the proofmark configs directory and generates the CSV:
```bash
for config in POC3/proofmark_configs/*.yaml; do
    job=$(basename "$config" .yaml)
    # Determine if output is CSV or Parquet directory based on config
    echo "$config,Output/curated/$job_output,Output/double_secret_curated/$job_output,POC3/logs/proofmark_reports/$job.json"
done > POC3/proofmark_batch.csv
```
(Actual script would need to read each YAML to determine the correct LHS/RHS paths based on reader type.)

---

## Summary of Changes

| Component | Change | Scope |
|-----------|--------|-------|
| MockEtlFramework | Task queue service mode | New `TaskQueueService.cs` + `Program.cs` modification |
| MockEtlFramework | `control.task_queue` table | New DB table |
| Proofmark | Batch mode CLI | New `batch` command, manifest parser |
| POC3 execution | Queue population script | One-time script per phase |
| POC3 execution | Batch manifest generation | One-time script |
| POC3 D.1 | Clean and re-run | Delete V2 run history + output, repopulate queue, run service |
| POC3 D.2 | Clean and re-run | Generate manifest, run batch mode |

---

## Open Questions for Dan

1. **Mock ETL service: single-threaded or configurable workers?** Single-threaded is safest (no resource contention). Configurable (`--workers N`) gives us the option to speed up execution on days when the machine has headroom. Recommend configurable with default of 1.

2. **Is the "never modify Lib/" rule relaxed for this?** It should be. The rule exists to prevent the blind lead from tampering with the framework during reverse-engineering. Infrastructure changes to support POC execution are a different concern. The blind lead still never touches `Lib/`.

3. **Parquet type mismatches — fix now or let resolution agents handle?** These are real V2 code bugs. We could fix the obvious ones (int32→int64, decimal→double) proactively, or let Phase D resolution agents discover and fix them via the normal triage loop. The latter is more honest for the POC narrative. Recommend letting the process work as designed.

4. **Should the task queue support priorities?** Probably not for POC3. Simple FIFO is fine. But worth noting for POC4 if we want to prioritize certain jobs (e.g., sabotaged jobs first for faster signal).
