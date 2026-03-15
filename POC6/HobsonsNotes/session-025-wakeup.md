# POC6 Session 026 — Wake-Up Prompt

## Copy-paste this into Hobson when you start the next session:

```
Go read /media/dan/fdrive/codeprojects/AtcStrategy/POC6/HobsonsNotes/session-025-wakeup.md — that's your wakeup prompt. Read it, absorb it, then tell me you're ready.
```

---

## Who You Are

You are Hobson. Your CLAUDE.md and MEMORY.md are already loaded.

## What Happened Last Session (025)

**Network isolation v2. Major path architecture rework. Framework code change.**

### The Problem

The RE team was using wrong paths — trying to run the ETL framework locally
(doesn't work, DB is localhost), and referencing tokens that don't exist on
the host side. We also had no mechanism for the host framework to load RE
code (job confs and external modules) without a rebuild.

### What Was Built

1. **Path architecture v2 — "everything under ETL_ROOT":**
   - One token: `{ETL_ROOT}`. Never changes. Never flips.
   - Host: `/media/dan/fdrive/codeprojects/MockEtlFrameworkPython`
   - Container: `/workspace/MockEtlFrameworkPython`
   - OG output: `{ETL_ROOT}/Output/curated/`
   - RE output: `{ETL_ROOT}/Output/re-curated/` (real dir on host, ro mount into container)
   - RE code: `{ETL_ROOT}/RE/Jobs/` and `{ETL_ROOT}/RE/externals/` (symlinks → workspace)

2. **Symlinks created on host:**
   - `{ETL_ROOT}/RE/Jobs/` → workspace `RE/Jobs/`
   - `{ETL_ROOT}/RE/externals/` → workspace `RE/externals/`
   - Publisher writes to workspace, host framework reads through symlinks.

3. **Docker mounts (3 total in compose.yml):**
   - `./workspace:/workspace` (rw)
   - `Output/curated → Output/curated:ro` (OG output)
   - `Output/re-curated → Output/re-curated:ro` (RE output)
   - Container needs `docker compose down && docker compose up -d` for new mounts.

4. **`external.py` changed — dynamic RE module loading:**
   - OG modules: standard imports (hardcoded list, unchanged)
   - RE modules: `importlib` file-based loading from `RE/externals/`
   - Drop a `.py` file, framework finds it next run. No rebuild.
   - 156 tests passing.

5. **`.gitignore` updated:** Added `RE/` to MockEtlFrameworkPython's `.gitignore`.

6. **10 blueprints updated in EtlReverseEngineering:**
   - `_conventions.md`: killed `{OG_CURATED}`, added `{ETL_ROOT}` as first-class token,
     queue entry path guidance, "cannot run FW locally" section.
   - `job-executor.md`: full rewrite — INSERT into `control.task_queue`.
   - `proofmark-executor.md`: full rewrite — INSERT into `control.proofmark_test_queue`.
   - `publisher.md`: rewritten — copies confs + externals to RE/ dirs, registers
     `{ETL_ROOT}/RE/Jobs/...` in control.jobs.
   - 6 others: `{OG_CURATED}` → `{ETL_ROOT}/Output/curated/`.

7. **Wrote BD a v2 briefing:** `path-changes-for-bd-v2.md` with full step-by-step
   RE pipeline (12 steps). BD to update blueprints to match.

8. **State-of-poc6.md fully rewritten** — section 4 (network isolation) replaced
   with v2 architecture.

### Three task queues (confirmed with Dan):

| Queue | Purpose | Inserts | Processes |
|-------|---------|---------|-----------|
| `control.task_queue` | ETL job execution | Basement | Host (`python cli.py --service`) |
| `control.proofmark_test_queue` | Output comparison | Basement | Host (`proofmark serve`) |
| `control.re_task_queue` | Workflow state machine | BD orchestrator | BD orchestrator |

### RE Pipeline (the 12 steps):

1. Builder writes job conf to EtlRE
2. Builder writes external module to EtlRE
3. Builder sets `outputDirectory` to `Output/re-curated`
4. Publisher copies job conf to `{ETL_ROOT}/RE/Jobs/{job}/jobconf.json`
5. Publisher copies external module to `{ETL_ROOT}/RE/externals/{module}.py`
6. Publisher registers `{ETL_ROOT}/RE/Jobs/{job}/jobconf.json` in control.jobs
7. ExecuteJobRuns inserts into control.task_queue
8. ExecuteJobRuns polls task_queue for results
9. ExecuteJobRuns monitors `{ETL_ROOT}/Output/re-curated` for output
10. BuildProofmarkConfig writes config to EtlRE
11. ProofmarkExecutor copies config to `{ETL_ROOT}/RE/Jobs/{job}/`
12. ProofmarkExecutor inserts into proofmark_test_queue with LHS=curated, RHS=re-curated

## Current State

Read these to get oriented:

1. `/media/dan/fdrive/codeprojects/AtcStrategy/POC6/HobsonsNotes/state-of-poc6.md` — master reference (fully updated for session 025)
2. `/media/dan/fdrive/codeprojects/AtcStrategy/POC6/HobsonsNotes/path-changes-for-bd-v2.md` — the v2 briefing Dan gave BD

## What BD Is Working On

v0.3: Agent Integration. Updating blueprints to match the 12-step pipeline.
Then replacing stub nodes with real Claude CLI invocations.

## What's Likely Next for Hobson

- Proofmark may need `{ETL_ROOT}` token cleanup similar to what was done for ETL FW
  (check if dead `ETL_RE_ROOT`/`ETL_RE_OUTPUT` tokens were fully removed from Proofmark source)
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
