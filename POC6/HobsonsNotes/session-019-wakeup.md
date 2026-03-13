# POC6 Session 020 — Wake-Up Prompt

## Copy-paste this into Hobson when you start the next session:

```
Go read /media/dan/fdrive/codeprojects/AtcStrategy/POC6/HobsonsNotes/session-019-wakeup.md — that's your wakeup prompt. Read it, absorb it, then tell me you're ready.
```

---

## Who You Are

You are Hobson. Your CLAUDE.md and MEMORY.md are already loaded.

## What Happened Session 019

### Persistent DB connection fix (queue.py)

Proofmark's queue runner had a memory leak. Each task opened and closed 3 separate psycopg2 connections (one each for `claim_task`, `mark_succeeded`, `mark_failed`). Under 5 concurrent worker threads with GIL contention, the C-level `libpq` objects weren't being deallocated promptly. After ~440 tasks, completion time degraded from 0.13s to 9.5s average and memory climbed from ~40% to 64%.

**Fix applied:** `claim_task`, `mark_succeeded`, and `mark_failed` now accept a `conn` parameter instead of a `dsn` string. No more internal connect/close. The `worker_loop` opens one persistent connection at startup, passes it to all DB functions, and closes it on shutdown. A `_reconnect()` helper handles error recovery — if any DB operation fails, the worker closes the dead connection and opens a fresh one.

Files changed:
- `/media/dan/fdrive/codeprojects/proofmark/src/proofmark/queue.py` — the fix itself
- `/media/dan/fdrive/codeprojects/proofmark/tests/test_queue.py` — tests updated to pass `conn` instead of DSN
- `/media/dan/fdrive/codeprojects/proofmark/Documentation/control/queue-runner.md` — docs updated

All 206 tests pass.

### CLI cleanup

Removed the `proofmark compare` one-at-a-time CLI entry point. All comparisons now go through the queue runner (`proofmark serve`). Deleted `test_cli.py`, removed `run_cli` fixture from `conftest.py`, updated 5 doc files. 206 tests pass.

### Queue state

The `control.proofmark_test_queue` table has:
- 66 Succeeded rows from the Oct 1 CSV validation (session 018)
- 446 Succeeded rows from the Oct 2-21 stress test (before Dan killed the runner due to memory pressure)
- 857 Pending rows — the remainder of the stress test that never ran

The fix has NOT been validated yet. Dan wants to restart the memory leak stress test.

## Your Job Next Session

Dan will guide you on restarting the Proofmark stress test. Follow his lead.

### Still outstanding from session 018 (not urgent):
- Parquet data profiling (38 jobs, Oct 1-21, C# vs Python) — a profiler script exists at `/home/dan/penthouse-pete/parquet-profiler.py` but hasn't been run at scale yet
- Memory file updates (MEMORY.md, atc-poc6.md) — still stale

## Key Files

| What | Path |
|------|------|
| Queue runner (the fix) | `/media/dan/fdrive/codeprojects/proofmark/src/proofmark/queue.py` |
| Queue tests | `/media/dan/fdrive/codeprojects/proofmark/tests/test_queue.py` |
| State of POC6 | `AtcStrategy/POC6/HobsonsNotes/state-of-poc6.md` |
| Job manifest (103 jobs) | `AtcStrategy/POC6/HobsonsNotes/job-scope-manifest.json` |
| Python repo | `/media/dan/fdrive/codeprojects/MockEtlFrameworkPython/` |
| Proofmark | `/media/dan/fdrive/codeprojects/proofmark/` |

## Standing Rules

- Only Hobson writes code to MockEtlFrameworkPython.
- Read the C# source before writing each Python component.
- Job conf files must work as-is (same JSON format, same field names).
- 103 jobs in scope (2 burned: repeat_overdraft_customers, suspicious_wire_flags).
- CSV validation: accepted as "good enough" — all failures are cosmetic.
- Parquet validation: use data profiling, not Proofmark.
