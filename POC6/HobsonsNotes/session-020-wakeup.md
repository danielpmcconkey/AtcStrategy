# POC6 Session 021 — Wake-Up Prompt

## Copy-paste this into Hobson when you start the next session:

```
Go read /media/dan/fdrive/codeprojects/AtcStrategy/POC6/HobsonsNotes/session-020-wakeup.md — that's your wakeup prompt. Read it, absorb it, then tell me you're ready.
```

---

## Who You Are

You are Hobson. Your CLAUDE.md and MEMORY.md are already loaded.

## What Happened Session 020

Power cut killed the previous session mid-investigation. This session recovered context and made three code changes to address the memory leak / performance degradation in the Proofmark queue runner.

### Change 1: Free intermediate structures in pipeline.run() (F1)

**File:** `/media/dan/fdrive/codeprojects/proofmark/src/proofmark/pipeline.py`

After hashing, `lhs_result` and `rhs_result` are `del`'d (schema captured into a local variable first). After diffing, `lhs_hashed` and `rhs_hashed` are `del`'d. This reduces peak memory per task — previously all intermediate structures were live simultaneously until `run()` returned.

### Change 2: Cap correlator at 100 unmatched rows (F6)

**File:** `/media/dan/fdrive/codeprojects/proofmark/src/proofmark/correlator.py`

Added `MAX_UNMATCHED_FOR_CORRELATION = 100`. If either side exceeds 100 unmatched rows, correlation is skipped entirely — all unmatched rows go straight to uncorrelated. Prevents O(n*m) blowup on badly mismatched comparisons.

### Change 3: Telemetry — RSS + GC tracking per task (T1)

**Files:**
- `/media/dan/fdrive/codeprojects/proofmark/src/proofmark/queue.py` — added `_rss_mb()` helper (reads `/proc/self/statm`), added telemetry logging after each task's `gc.collect()`
- `/media/dan/fdrive/codeprojects/proofmark/src/proofmark/app_config.py` — added `telemetry: bool = False` to `QueueSettings`
- `/media/dan/fdrive/codeprojects/proofmark/settings.yaml` — **created**, contains `queue: { telemetry: true }`

**How to monitor telemetry:**

The runner logs to stdout via Python's `logging` module. When `telemetry: true`, after every completed task you'll see:

```
[worker-0] task 42 | rss=1234.5 MB | uncollectable=0
```

- **rss** — current process RSS in MB (from `/proc/self/statm`). Watch for monotonic growth.
- **uncollectable** — objects the GC can't collect (reference cycles with `__del__`). Should be 0. If it grows, you have a smoking gun.

**To enable:** `proofmark serve --settings settings.yaml`
**To disable:** remove `--settings` flag or set `telemetry: false`

### Bug found: tests were nuking the production queue table

**File:** `/media/dan/fdrive/codeprojects/proofmark/tests/test_queue.py`

`test_queue.py` was using `TEST_TABLE = "control.proofmark_test_queue"` — the same table the runner uses. Every test class's `setup_method` DROPs and recreates it. Running `pytest` wiped all 1,363 queued tasks from the previous session and left behind 6 test fixture rows.

**Fix applied:** Changed `TEST_TABLE` to `"control._test_proofmark_queue"`. Tests now use their own table. 12 queue tests pass.

**Hobson ran pytest this session to validate the F1/F6 changes. That's what killed the data.** Dan is aware.

### Queue rebuild

A background agent was rebuilding the queue at session end:
- 65 CSV jobs × 21 dates (Oct 1–21, 2024)
- **Reverse manifest order** — jobs that were last in the previous run now have the lowest task_ids (run first). This tests whether the performance degradation correlates with execution position or specific jobs.
- Only rows where both LHS (C# original) and RHS (Python rewrite) files exist on disk
- `job_key` and `date_key` populated for easy querying

**Verify the queue loaded correctly before starting the runner:**
```sql
PGPASSWORD='claude' psql -U claude -h localhost -d atc -c "
  SELECT COUNT(*) AS total,
         COUNT(DISTINCT job_key) AS jobs,
         MIN(date_key) AS min_date,
         MAX(date_key) AS max_date
  FROM control.proofmark_test_queue
  WHERE status = 'Pending';
"
```

Expected: ~1,300+ rows, 65 jobs, dates 2024-10-01 to 2024-10-21.

## Your Job Next Session

1. **Verify the queue loaded correctly** (query above).
2. **Start the runner** with telemetry enabled:
   ```bash
   cd /media/dan/fdrive/codeprojects/proofmark
   source .venv/bin/activate
   proofmark serve --settings settings.yaml
   ```
3. **Monitor for the memory leak.** Watch the `rss=` values in the log output. Previously, RSS climbed from ~38% to ~66% and completion times degraded from 0.04s to 78s over ~440 tasks. With F1 applied, peak memory per task should be lower. The question is whether RSS still ratchets upward.
4. **If RSS stabilises:** the `del` statements in pipeline.run() were sufficient. The leak was peak-memory fragmentation, not a true reference leak.
5. **If RSS still climbs:** escalate to `tracemalloc` (T2 from the telemetry report). The report is at `/media/dan/fdrive/codeprojects/AtcStrategy/POC6/HobsonsNotes/telemetry-options-memory-leak.md`.

## Agreed fixes not yet implemented

| ID | Fix | Status | Effort |
|----|-----|--------|--------|
| F4 | Refactor HashedRow to stop triple-storing row data | Agreed, not started | Medium |
| F5 | `json.dumps` → `orjson` or streaming | Agreed but low priority | Low |

## Fixes discussed and deferred/rejected

| ID | Fix | Decision |
|----|-----|----------|
| F2 | PyArrow memory pool release | All jobs are CSV. Not our problem, but good hygiene if parquet is added later. |
| F3 | Switch to ProcessPoolExecutor | Dan concerned it re-introduces startup cost. Hobson clarified workers are pooled, but agreed it's a fallback, not first move. |
| F7 | Stream CSV reader | Dan correctly noted you need all rows in memory for hash matching anyway. Marginal benefit. Skipped. |
| F8 | Move sort_key closure out of loop | Trivial/negligible. Skipped. |

## RCA and telemetry reports

| Report | Path |
|--------|------|
| Root cause analysis | `/media/dan/fdrive/codeprojects/AtcStrategy/POC6/HobsonsNotes/rca-memory-leak-pipeline.md` |
| Telemetry options | `/media/dan/fdrive/codeprojects/AtcStrategy/POC6/HobsonsNotes/telemetry-options-memory-leak.md` |

## Key Files

| What | Path |
|------|------|
| Pipeline (F1 change) | `/media/dan/fdrive/codeprojects/proofmark/src/proofmark/pipeline.py` |
| Correlator (F6 change) | `/media/dan/fdrive/codeprojects/proofmark/src/proofmark/correlator.py` |
| Queue runner (T1 change) | `/media/dan/fdrive/codeprojects/proofmark/src/proofmark/queue.py` |
| App config (T1 change) | `/media/dan/fdrive/codeprojects/proofmark/src/proofmark/app_config.py` |
| Runner settings | `/media/dan/fdrive/codeprojects/proofmark/settings.yaml` |
| Queue tests (table name fix) | `/media/dan/fdrive/codeprojects/proofmark/tests/test_queue.py` |
| Job manifest (103 jobs) | `AtcStrategy/POC6/HobsonsNotes/job-scope-manifest.json` |
| State of POC6 | `AtcStrategy/POC6/HobsonsNotes/state-of-poc6.md` |
| Python repo | `/media/dan/fdrive/codeprojects/MockEtlFrameworkPython/` |
| Proofmark repo | `/media/dan/fdrive/codeprojects/proofmark/` |

## Standing Rules

- Only Hobson writes code to MockEtlFrameworkPython.
- Read the C# source before writing each Python component.
- Job conf files must work as-is (same JSON format, same field names).
- 103 jobs in scope (2 burned: repeat_overdraft_customers, suspicious_wire_flags).
- CSV validation: accepted as "good enough" — all failures are cosmetic.
- Parquet validation: use data profiling, not Proofmark.
- **Do NOT run `pytest tests/` without understanding that test_queue.py will DROP and recreate `control._test_proofmark_queue`.** The production table is `control.proofmark_test_queue` — they are now separate, but be aware.
