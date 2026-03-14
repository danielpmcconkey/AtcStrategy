# POC6 Session 024 — Wake-Up Prompt

## Copy-paste this into Hobson when you start the next session:

```
Go read /media/dan/fdrive/codeprojects/AtcStrategy/POC6/HobsonsNotes/session-023-wakeup.md — that's your wakeup prompt. Read it, absorb it, then tell me you're ready.
```

---

## Who You Are

You are Hobson. Your CLAUDE.md and MEMORY.md are already loaded.

## What Happened Last Session (023)

**Network isolation is fully implemented.** All TODO items from the session 021 design are done.

### What was done:

1. **Env vars simplified (4→2):**
   - `ETL_ROOT` updated in `.bashrc` and `compose.yml` to point at MockEtlFrameworkPython
   - `ETL_RE_OUTPUT` and `ETL_RE_ROOT` removed from `.bashrc`, `compose.yml`, Proofmark source, ETL FW source, and all documentation (6 doc files across both repos)

2. **Docker mounts:**
   - Read-only mount added: OG curated output → `/workspace/og-curated/` (agents can read the answer key, can't write to it)
   - `re-curated/` directory created at `/media/dan/fdrive/ai-sandbox/workspace/re-curated/`
   - Host-side symlink: `og-curated` → OG curated output

3. **Basement DB connection confirmed:** `172.18.0.1`, `claude` role, 103 active jobs visible

4. **All repos committed and pushed:**
   - MockEtlFrameworkPython: 227 files, full codebase (was entirely untracked). Added `Output/` to `.gitignore`.
   - Proofmark: 125 files including 103 per-job comparison config YAMLs
   - AtcStrategy: Both sides synced (Hobson's notes + BD's notes)

5. **BD's workspace cleaned up:**
   - C# MockEtlFramework deleted
   - Fresh clones of MockEtlFrameworkPython and Proofmark
   - Handoff note left at `BDsNotes/hobson-handoff-session-023.md`

6. **Tests:** 206 Proofmark, 156 ETL FW — all passing

### What was NOT done:

- No orchestrator work. BD owns that.
- No end-to-end test from the basement side (queueing a job from inside the container, having the host pick it up). Dan may have done this with BD after session 023.

## Current State

Read these to get oriented:

1. `/media/dan/fdrive/codeprojects/AtcStrategy/POC6/HobsonsNotes/state-of-poc6.md` — master reference, updated at end of session 023
2. `/media/dan/fdrive/codeprojects/AtcStrategy/POC6/HobsonsNotes/env-var-mapping.md` — current env var values, mounts, symlinks

## What's Likely Next

Unknown. Dan wasn't sure when he'd be back. Possible directions:

- BD may have made progress on the orchestrator (C# EtlReverseEngineering repo, Phase 1)
- Dan may want to do an end-to-end integration test of the full pipeline
- There may be new requirements or changes from BD's work that need host-side support
- CIO presentation prep for ATC

Ask Dan what he needs.

## Standing Rules

- Only Hobson writes code to MockEtlFrameworkPython (on the host side).
- Read code before editing it.
- 103 jobs in scope (2 burned: repeat_overdraft_customers, suspicious_wire_flags).
- **Do NOT run `pytest tests/` in Proofmark without understanding the test table situation.** Tests use `control._test_proofmark_queue`, production uses `control.proofmark_test_queue`.
