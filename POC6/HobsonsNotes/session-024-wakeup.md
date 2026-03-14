# POC6 Session 025 — Wake-Up Prompt

## Copy-paste this into Hobson when you start the next session:

```
Go read /media/dan/fdrive/codeprojects/AtcStrategy/POC6/HobsonsNotes/session-024-wakeup.md — that's your wakeup prompt. Read it, absorb it, then tell me you're ready.
```

---

## Who You Are

You are Hobson. Your CLAUDE.md and MEMORY.md are already loaded.

## What Happened Last Session (024)

**Housekeeping session.** No code written, no tests run.

### What was done:

1. **AtcStrategy repo synced:**
   - Committed and pushed Hobson's changes (ETL_ROOT path abstraction in job-scope-manifest.json, session-023-wakeup.md, skills-vs-blueprints.md)
   - Pulled BD's changes (11 files: 9 session wakeups, state-machine-transitions.md, state-of-poc6.md)
   - Both copies now on commit `903b916`

2. **EtlReverseEngineering repo cloned:**
   - BD's new orchestrator repo cloned to `/media/dan/fdrive/codeprojects/EtlReverseEngineering/`
   - Python workflow engine with 92 tests. v0.1 complete, v0.2 in progress.

3. **State-of-poc6.md updated** to reflect BD's orchestrator progress (v0.1 done, v0.2 scoped)

4. **Stale .idea directory deleted** from AtcStrategy (Rider IDE config, no code in that repo)

## Current State

Read these to get oriented:

1. `/media/dan/fdrive/codeprojects/AtcStrategy/POC6/HobsonsNotes/state-of-poc6.md` — master reference
2. `/media/dan/fdrive/codeprojects/AtcStrategy/POC6/BDsNotes/state-of-poc6.md` — BD's perspective (shorter, more current on orchestrator status)
3. `/media/dan/fdrive/codeprojects/AtcStrategy/POC6/BDsNotes/bd-wakeup-poc6-session12.md` — BD's latest wakeup (most current on v0.2 details)

## What BD Is Working On

BD is building the v0.2 milestone: **Parallel Execution Infrastructure.** Four phases (4-7):

| # | Phase | What | Status |
|---|-------|------|--------|
| 4 | Postgres Foundations | Task queue table, job seeder, Postgres DAL | NOT STARTED |
| 5 | Queue Write Paths | Queue insert/claim operations | NOT STARTED |
| 6 | Worker Pool | Multi-threaded executor, 6 workers | NOT STARTED |
| 7 | State Machine Wiring | Connect state machine to queue-based execution | NOT STARTED |

The synchronous `run_job()` loop will be deleted. Tests rewritten to exercise the queue-based model.

## What's Likely Next for Hobson

Unknown. Possible directions:

- BD may need host-side support for the Postgres task queue (table creation, permissions)
- End-to-end integration test of the full pipeline (basement agent writes to queue, host picks it up)
- CIO presentation prep for ATC
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
