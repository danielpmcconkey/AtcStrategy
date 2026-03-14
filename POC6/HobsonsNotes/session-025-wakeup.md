# POC6 Session 026 — Wake-Up Prompt

## Copy-paste this into Hobson when you start the next session:

```
Go read /media/dan/fdrive/codeprojects/AtcStrategy/POC6/HobsonsNotes/session-025-wakeup.md — that's your wakeup prompt. Read it, absorb it, then tell me you're ready.
```

---

## Who You Are

You are Hobson. Your CLAUDE.md and MEMORY.md are already loaded.

## What Happened Last Session (025)

**Path consolidation and blueprint fixes.** No framework code changed, no tests run.

### What was done:

1. **Pulled BD's updates from EtlReverseEngineering:**
   - v0.2 shipped (phases 4-7 in one session). 132 tests, 16 requirements.
   - v0.3 scaffolding started. 38 files changed. Agent integration docs, blueprint updates.
   - BD's latest wakeup: `bd-wakeup-poc6-session14.md`

2. **Path consolidation — "everything under ETL_ROOT":**
   - Dan's directive: the only env var token the host services expand is `{ETL_ROOT}`.
     All resolvable paths must be expressible as `{ETL_ROOT}/...`.
   - The old `{OG_CURATED}` token (pointing to `/workspace/og-curated/`) is dead.
   - OG curated output is now at `{ETL_ROOT}/Output/curated/` (ro mount in container).
   - RE curated output will land at `{ETL_ROOT}/Output/re-curated/` (host symlink
     bridges to workspace).

3. **compose.yml updated:**
   - ro mount target changed: `/workspace/og-curated` → `/workspace/MockEtlFrameworkPython/Output/curated`
   - Container rebuild required for this to take effect.

4. **Host filesystem changes:**
   - Removed: `workspace/og-curated` symlink
   - Created: `MockEtlFrameworkPython/Output/re-curated` symlink → workspace's `Output/curated/`
   - Created: `workspace/MockEtlFrameworkPython/Output/curated/` directory (RE output target)

5. **10 blueprints updated in EtlReverseEngineering:**
   - `_conventions.md`: killed `{OG_CURATED}`, added `{ETL_ROOT}` as first-class token,
     added queue entry path guidance, added "cannot run FW locally" section.
   - `job-executor.md`: full rewrite — INSERT into `control.task_queue`, not `python -m cli`.
   - `proofmark-executor.md`: full rewrite — INSERT into `control.proofmark_test_queue`
     with `{ETL_ROOT}` token paths.
   - `publisher.md`: rewritten — copies code artifacts from EtlRE into MockEtlFW at
     standard framework locations, registers `{ETL_ROOT}/JobExecutor/Jobs/{job_name}.json`.
   - 6 others: `{OG_CURATED}` → `{ETL_ROOT}/Output/curated/`
   - `builder.md`: hardcoded paths → `{ETL_ROOT}` tokens.

6. **Wrote BD a summary:** `path-changes-for-bd.md` in HobsonsNotes.
   Dan will direct BD to read it. BD has cleanup to do before going live.

### Three task queues (confirmed with Dan):

| Queue | Purpose | Inserts | Processes |
|-------|---------|---------|-----------|
| `control.task_queue` | ETL job execution | Basement | Host (`python cli.py --service`) |
| `control.proofmark_test_queue` | Output comparison | Basement | Host (`proofmark serve`) |
| `control.re_task_queue` | Workflow state machine | BD orchestrator | BD orchestrator |

### Key design point confirmed:

RE agents write code in EtlReverseEngineering (`{job_dir}/artifacts/code/`).
The publisher deploys final artifacts into MockEtlFrameworkPython. "Build here,
deploy there." Dan approved this pattern.

## Current State

Read these to get oriented:

1. `/media/dan/fdrive/codeprojects/AtcStrategy/POC6/HobsonsNotes/state-of-poc6.md` — master reference (needs update for session 025 changes)
2. `/media/dan/fdrive/codeprojects/AtcStrategy/POC6/HobsonsNotes/path-changes-for-bd.md` — summary of this session's changes
3. `/media/dan/fdrive/codeprojects/AtcStrategy/POC6/BDsNotes/bd-wakeup-poc6-session14.md` — BD's latest wakeup

## What BD Is Working On

v0.3: Agent Integration. Replacing stub nodes with real Claude CLI invocations.
Phases 4-7 (v0.2) shipped. BD needs to do cleanup with Dan before building
against the new path conventions.

## What's Likely Next for Hobson

- Update `state-of-poc6.md` to reflect session 025 changes (path consolidation,
  blueprint updates, compose.yml change)
- Update `env-var-mapping.md` to reflect the new mount and symlink layout
- Possible: help Dan with container rebuild / verification that the new mounts work
- Possible: CIO presentation prep
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
