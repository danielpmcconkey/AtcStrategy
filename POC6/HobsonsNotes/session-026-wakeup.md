# POC6 Session 028 — Wake-Up Prompt

## Copy-paste this into Hobson when you start the next session:

```
Go read /media/dan/fdrive/codeprojects/AtcStrategy/POC6/HobsonsNotes/session-026-wakeup.md — that's your wakeup prompt. Read it, absorb it, then tell me you're ready.
```

---

## Who You Are

You are Hobson. Your CLAUDE.md and MEMORY.md are already loaded.

## What Happened Last Session (027)

**Append-mode re-run bug found and fixed. Queue status mismatch diagnosed.**

### The Bug

Dan spotted that when an RE team re-runs a job (e.g. re-running Oct 1 after
fixing a defect, with Oct 1–31 output already on disk), append-mode file
writers were pulling in data from future partitions. Re-running Oct 1 would
produce a file containing Oct 31 + Oct 1 data.

**Root cause:** `date_partition_helper.find_latest_partition()` returned the
lexicographically largest date directory with no awareness of the current
effective date. On a re-run of Oct 1, it grabbed the Oct 31 partition.

### The Fix

- `find_latest_partition()` now accepts `before: date | None`. When set,
  partitions >= that date are excluded from the search.
- Both `CsvFileWriter` and `ParquetFileWriter` pass `before=effective_date`.
- Regression tests added to both test files — the exact Oct 1 / Oct 31
  re-run scenario.
- **158 tests passing** (was 156).
- Committed and pushed to `MockEtlFrameworkPython` main.

### Files Changed

- `src/etl/date_partition_helper.py` — `before` parameter added
- `src/etl/modules/csv_file_writer.py` — passes `before=effective_date`
- `src/etl/modules/parquet_file_writer.py` — same
- `tests/test_csv_file_writer.py` — re-run regression test
- `tests/test_parquet_file_writer.py` — re-run regression test

### Queue Status Mismatch (not yet fixed)

BD's blueprints insert into `control.task_queue` with `status = 'Queued'`,
but the framework's `task_queue_service.py` polls for `status = 'Pending'`
(line 64). Dan manually updated the rows to unblock, but the blueprint
contract needs fixing. BD should insert with `status = 'Pending'`.

This is tracked as active issue #3 in state-of-poc6.md.

## Current State

Read these to get oriented:

1. `/media/dan/fdrive/codeprojects/AtcStrategy/POC6/HobsonsNotes/state-of-poc6.md` — master reference (updated for session 027)

## What BD Is Working On

v0.3: Agent Integration. Updating blueprints to match the 12-step pipeline.
Replacing stub nodes with real Claude CLI invocations. Also needs to fix
the `Queued` → `Pending` status value in the job-executor blueprint.

## What's Likely Next for Hobson

- BD may need help with the `Queued` vs `Pending` mismatch — check if there's
  a blueprint or convention doc that specifies the status enum
- Proofmark may need `{ETL_ROOT}` token cleanup (carried from session 025)
- CIO presentation prep (still pending)
- Dan may have entirely different plans

Ask Dan what he needs.

## Key Repos and Paths

| Repo | Hobson's copy | BD's copy |
|------|--------------|-----------|
| AtcStrategy | `/media/dan/fdrive/codeprojects/AtcStrategy/` | `/media/dan/fdrive/ai-sandbox/workspace/AtcStrategy/` |
| EtlReverseEngineering | `/media/dan/fdrive/codeprojects/EtlReverseEngineering/` | `/media/dan/fdrive/ai-sandbox/workspace/EtlReverseEngineering/` |
| MockEtlFrameworkPython | `/media/dan/fdrive/codeprojects/MockEtlFrameworkPython/` | `/media/dan/fdrive/ai-sandbox/workspace/MockEtlFrameworkPython/` |
| Proofmark | `/media/dan/fdrive/codeprojects/proofmark/` | `/media/dan/fdrive/ai-sandbox/workspace/proofmark/` |

## Standing Rules

- Only Hobson writes code to MockEtlFrameworkPython (on the host side).
- Read code before editing it.
- 103 jobs in scope (2 burned: repeat_overdraft_customers, suspicious_wire_flags).
- **Do NOT run `pytest tests/` in Proofmark without understanding the test table situation.** Tests use `control._test_proofmark_queue`, production uses `control.proofmark_test_queue`.
- **RAM warning:** 15GB RAM + 16GB swap. Subagent spawning is dangerous — has OOM'd the host twice.
