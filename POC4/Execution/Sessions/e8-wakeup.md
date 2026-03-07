# E.8 Wake-Up — Orchestrator Redesign & Attempt #3

**Date:** 2026-03-07
**Status:** Triage complete. All pre-dry-run fixes committed. Ready to redesign and build the E.6 orchestrator.

---

## What Was Done This Session

### Triage (all complete)
1. **DataSourcing/Transformation empty-result fix** — ACCEPTED, committed, pushed (`1fca961`).
   When a query returns zero rows, both modules now preserve column schema instead of
   nuking it. Jobs produce header-only CSV on no-data dates instead of crashing.
   Docs updated in Architecture.md.

2. **V1 outputDirectory fix** — All 97 V1 job configs changed from `Output/poc4` to
   `Output/curated`. Committed and pushed (`4d03377`).

3. **External module date-partitioned paths** — 8 V1 external modules hardcoded flat
   output paths. All 8 fixed to use `Output/curated/{job}/{table}/{date}/{file}.csv`.
   Committed and pushed (`4d03377`).

4. **TaskQueueService idle timeout** — Dan's change, not the orchestrator's. Idle counter
   at 30 cycles × 30s = 15 min before shutdown. Committed and pushed (`4d03377`).

5. **Cleaned DB state** — task_queue and job_runs truncated. Clean slate.

6. **Cleaned output dirs** — `Output/curated/` and `Output/double_secret_curated/` emptied.
   `Output/poc4/` deleted.

7. **TaskQueueService commit `c98c7d3`** — Dan explained this was a botched IDE apply, not
   orchestrator damage. The commit nuked the file to 33 lines; Dan restored and reimplemented
   in working tree. Now committed correctly at `4d03377`.

### Decisions Made
- **Empty-result semantics:** Dan decided to accept the orchestrator's graceful-empty behavior
  for the POC, even though his original rule was T-N = hard fail. Proofmark catches mismatches
  instead of the framework crashing. Simpler for the POC.
- **Proofmark comparison map:** Dan decided the orchestrator should NOT get a pre-baked
  comparison map. The agent processing each date should derive Proofmark configs at runtime
  from job configs and actual output. No static trailer_rows map.
- **External module anti-patterns:** The 8 dirty modules' bugs (inflated trailers, hardcoded
  dates, integer division, Banker's rounding) are anti-patterns for V4 rewrites to fix. We
  only fixed the output paths for Proofmark compatibility.

### What's NOT Done
- **PeakTransactionTimes V1 config** has no writer section (pure external module). The
  external module path is fixed, but there's no `outputDirectory` in the config to change.
  This is fine — the module handles its own output.
- **AtcStrategy repo** has uncommitted changes from prior orchestrator sessions (orchestrator-e6.md
  rewrite, progress files, errata, session prompts). NOT committed — these are dry run artifacts
  that may be disposable.

---

## The Plan: Three-Tier E.6 Architecture

Dan approved this direction. You are implementing it.

### Tier 1: Bash Loop (the sequencer)
- Iterates dates (Oct 1 – Dec 31, 2024 = 92 dates)
- Spawns a date worker agent per date
- Reads structured result file (pass/fail per job)
- On all-pass: advances cursor, moves to next date
- On failure: spawns triage agent with failure details
- Reads triage result (fixes applied, re-run list)
- Injects re-runs into its queue
- Pure sequencing, zero judgment, no LLM

### Tier 2: Date Worker Agent (context-isolated)
- Receives ONE date as input
- Queues all V1 + V4 jobs for that date via task_queue
- Polls for completion
- Derives Proofmark config from job configs and actual output (trailer detection, column mapping)
- Runs Proofmark comparisons for each V1/V4 pair
- Writes structured result file: `e6-results/{date}/date-result.json`
- Dies after one date. Clean context every time.

### Tier 3: Triage Agent (judgment layer)
- Only spawned when date worker reports failures
- Gets failure details (job name, Proofmark output, file paths)
- Diagnoses root cause
- Applies fixes (V4 config changes, V4 code changes)
- Determines blast radius: which (job, date) pairs need re-running
- Writes structured result: `e6-results/{date}/triage-result.json`
- Writes errata to `POC4/Errata/raw-errata-log.md`

### Structured Output Contracts

```json
// date-result.json
{
  "date": "2024-10-05",
  "status": "passed|failed",
  "passed": ["JobA", "JobB"],
  "failed": [
    {"job": "DailyBalanceMovement", "reason": "V4 produced 2506 rows, V1 produced 0"}
  ]
}

// triage-result.json
{
  "fixes_applied": ["daily_balance_movement_v4.json: removed mostRecent"],
  "rerun": [
    {"job": "DailyBalanceMovementV4", "dates": ["2024-10-01", "2024-10-02"]}
  ]
}
```

### Key Design Constraints
- Date worker must derive Proofmark configs at runtime, NOT from a static map
- Triage agent can modify V4 configs and V4 code only — never V1 configs, V1 external
  modules, framework Lib/ code, or Proofmark source
- The bash loop must handle re-runs without LLM judgment — just reads JSON, re-queues
- Errata is the only artifact that persists across dates (appended by triage agent)
- The 8 dirty external modules have trailers; the 64 clean ones may or may not depending
  on job config writer settings. Date worker must check actual output, not assume.

---

## Files to Read on Wake-Up

1. This file
2. `/workspace/MockEtlFramework/CLAUDE.md` — framework guardrails
3. `/workspace/AtcStrategy/POC4/ProgramDoctrine/condensed-mission.md` — mission context
4. `git -C /workspace/MockEtlFramework log --oneline -5` — verify commits landed
5. `/workspace/AtcStrategy/POC4/Design/Blueprints/orchestrator-e6.md` — current (stale)
   blueprint, will be replaced by the three-tier design

---

## Git State

### MockEtlFramework
- **Latest commit:** `4d03377` — pre-dry-run fixes
- **Uncommitted (working tree):** V4 job configs, V4 test file, PeakTransactionTimesWriterV4.cs
  (all dry run artifacts from prior orchestrator sessions)
- **Tag `poc4-pre-dry-run`** still exists as the clean revert target

### AtcStrategy
- **Uncommitted:** orchestrator-e6.md (v2 rewrite), progress files, errata, session prompts,
  e7-wakeup.md, this file. All from prior sessions + this session.

### Control DB
- task_queue: EMPTY
- job_runs: EMPTY
