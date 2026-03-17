# State of POC6

**Last updated:** 2026-03-17 (session 26)

## Milestones

### v0.1 State Machine Mechanics — SHIPPED (2026-03-13)

Phases 1-3. 92 tests, 38 requirements. Deterministic state machine with stubbed nodes:
- 27 happy-path nodes (Plan → Define → Design → Build → Validate)
- Three-outcome review model (Approve / Conditional / Fail)
- FBR 6-gate gauntlet with restart semantics
- Triage 7-step diagnostic sub-pipeline with earliest-fault routing
- Counter mechanics: main retry (N), conditional (M), auto-promotion, DEAD_LETTER
- Structured JSON logging for every transition

### v0.2 Parallel Execution Infrastructure — SHIPPED (2026-03-14)

Phases 4-7. 40 new tests (132 total), 16 requirements. Replaced synchronous engine with queue-based execution:
- **Phase 4:** Postgres `re_task_queue` + `re_job_state` in `control` schema, psycopg3 pool, CRUD, `SKIP LOCKED` concurrency proof, one-active-per-job constraint
- **Phase 5:** `enqueue_next` (transition lookup → enqueue) and `ingest_manifest` (bulk-load jobs from manifest JSON)
- **Phase 6:** `WorkerPool` — N configurable threads (default 6, `RE_WORKER_COUNT` env var), claim-execute loop, pluggable `TaskHandler`
- **Phase 7:** `StepHandler` — per-step SM logic through queue, Engine rewritten as manifest-ingest → pool wrapper, all engine tests rewritten for queue execution, `run_job()` deleted

### v0.3 Agent Integration — 37/102 JOBS COMPLETE, 3 IN PROGRESS

First end-to-end pipeline runs with real Claude CLI agents replacing stubs.

**Sessions 18-20:** Initial agent integration. First complete job (373,
DansTransactionSpecial). Blueprint overhauls for anti-pattern remediation.
External module loading fixed (directory scan replacing hardcoded imports).
Per-node model mapping (Opus/Sonnet/Haiku). Token-budget clutch. 10 jobs
complete by end of session 20.

**Session 25:** Major engine changes (commit `770ee81`):
- **FinalSignOff removed** — rubber-stamping, zero value. 21 nodes, was 22.
- **Pat CONDITIONAL flow** — `FBR_EvidenceAudit` returns CONDITIONAL for
  fixable doc/test drift → PatFix auto-resolves → COMPLETE. REJECTED →
  DEAD_LETTER for real output problems.
- **Triage-fix blueprint updated** — "update everything your changes
  invalidate" constraint added.
- **Graceful shutdown** — SIGINT/SIGTERM handler, non-daemon workers,
  `start_new_session=True` for Claude subprocesses.
- **Logging to stderr + engine.log** — structlog via stdlib, thread-safe
  FileHandler. Diagnostic traceback blocks in step_handler for transition
  failures.
- 28 jobs complete by end of session. PatFix tested manually on job 15
  (first CONDITIONAL→PatFix→COMPLETE, via manual task injection).

**Session 26:** PatFix validated end-to-end. Proofmark blueprint fixed.
- **PatFix fully automated** — jobs 20, 23, 19, 21, 16 all completed via
  CONDITIONAL→PatFix→COMPLETE with zero manual intervention. PatFix handles
  FSD updates, test rewrites, re-running jobs through framework, re-running
  Proofmark, and fixing typeName mismatches. Pat's audit reviewed — all
  CONDITIONALs are legitimate doc/test drift after triage pivots, not
  papering over real problems.
- **Proofmark executor blueprint fixed** (commit `20cd311`) — added parquet
  path handling. Old blueprint hardcoded CSV paths; parquet jobs need
  directory paths. Agent now reads jobconf for `jobDirName`,
  `outputTableDirName`, `fileName` instead of guessing. Won't help jobs
  already past this step, but prevents the recurring double-nested parquet
  path error for new jobs.
- **Job feeder automation** — bash script checks every 2 minutes, maintains
  6 running jobs by hot-loading from eligible pool (checks
  `control.job_dependencies`). Recipe for hot-loading:
  ```sql
  INSERT INTO control.re_job_state (job_id, current_node, status)
  VALUES ('{job_id}', 'LocateOgSourceFiles', 'RUNNING');
  INSERT INTO control.re_task_queue (job_id, node_name)
  VALUES ('{job_id}', 'LocateOgSourceFiles');
  ```
  `job_id` = `control.jobs.job_id` (same number).
- **37 jobs complete**, 1 dead-lettered (job 5, trailer comparison — accepted),
  3 still running at session end.

## Current Job Status

**37 COMPLETE, 1 DEAD_LETTER, 3 RUNNING** out of 102 OG jobs.

### Running Jobs at Session End

| Job | Name | Current Node | Notes |
|-----|------|-------------|-------|
| 18 | CreditScoreAverage | ExecuteProofmark | Had typeName issue (triage fixed), now Proofmark data mismatches — heading to triage again |
| 26 | TopBranches | Publish | Clean run |
| 28 | CustomerTransactionActivity | ReviewFsd | Mid-pipeline |

### Dead Letter
| Job | Name | Node | Reason |
|-----|------|------|--------|
| 5 | DailyTransactionVolume | ExecuteProofmark | Trailer comparison — Proofmark feature killed. Output is correct. Job 6 can consume its output. |

## Token Budget Observations (Session 26)

- ~0.4-0.5%/min with 6 workers sustained
- Session 25 averaged ~0.6%/min (higher due to BD context overhead)
- Clutch at 90% leaves ~10% buffer for wind-down
- 5-hour session refresh, ~160 min active budget per cycle
- 13 concurrent agents is the RAM ceiling; tokens are the real constraint

## Path Architecture (v2)

- **One literal token: `{ETL_ROOT}`** — never resolved by orchestrator, host
  expands at runtime from its own env var. Used ONLY in DB entries.
- **All other paths hardcoded** to container mount points. No tokens.
- **RE artifacts** deploy to `/workspace/MockEtlFrameworkPython/RE/Jobs/` and
  `/workspace/MockEtlFrameworkPython/RE/externals/` (symlinked to host)
- **`_re` suffix** on all RE identifiers: jobName, typeName, module filenames,
  control.jobs registration
- **OG output** at `/workspace/MockEtlFrameworkPython/Output/curated/` (ro mount)
- **RE output** at `/workspace/MockEtlFrameworkPython/Output/re-curated/` (ro mount, host writes here)
- **OG job confs** at `/workspace/MockEtlFrameworkPython/JobExecutor/Jobs/`
- **OG externals** at `/workspace/MockEtlFrameworkPython/src/etl/modules/externals/`
- **Framework docs** at `/workspace/MockEtlFrameworkPython/Documentation/`

## Architecture

- Dumb Python orchestrator, no LLM in the control loop
- Deterministic state machine drives workflow
- Atomic agents: claim task, do one thing, queue next step, die
- Fresh Claude CLI context per invocation (no rot)
- Postgres task queue with `SELECT ... FOR UPDATE SKIP LOCKED`
- Per-agent blueprints as system prompts
- Per-node model assignment via MODEL_MAP (Opus/Sonnet/Haiku)
- Token-budget clutch in `control.re_engine_config` for pausing workers
- 102 independent job pipelines, zero cross-contamination
- PatFix auto-remediation for documentation/test drift after triage
- See: `poc6-architecture.md`

## Key Files (EtlReverseEngineering repo)

| File | What |
|------|------|
| `src/workflow_engine/step_handler.py` | Per-step SM logic — the TaskHandler for workers |
| `src/workflow_engine/worker.py` | WorkerPool — N threads, claim-execute-enqueue loop |
| `src/workflow_engine/queue_ops.py` | enqueue_next, ingest_manifest |
| `src/workflow_engine/db.py` | Postgres pool, task queue + job state CRUD |
| `src/workflow_engine/schema.sql` | DDL for re_task_queue, re_job_state |
| `src/workflow_engine/engine.py` | Engine — manifest ingest + pool wrapper |
| `src/workflow_engine/transitions.py` | Transition table, routing dicts, validation |
| `src/workflow_engine/nodes.py` | Node ABC, stub implementations, agent registry, MODEL_MAP |
| `src/workflow_engine/agent_node.py` | AgentNode — Claude CLI invocation per blueprint |
| `src/workflow_engine/models.py` | JobState, EngineConfig, Outcome, NodeType |
| `src/workflow_engine/log_config.py` | structlog config — stderr + engine.log |
| `blueprints/_conventions.md` | Agent conventions, paths, RE naming rules |
| `blueprints/proofmark-executor.md` | Proofmark queue entry construction (CSV + Parquet) |
| `blueprints/pat-fix.md` | PatFix auto-remediation blueprint |

## Design Principles (standing)

- No errata accumulation. Retry counter is the only memory between attempts.
- Two counter types only: main retry (N) and conditional (M).
- Keep agents dumb. Let the state machine's structure handle complexity.
- Parallelism is at the job level, not within a single job's pipeline.
- Fresh context every agent invocation. No state carried between invocations.
- Deterministic orchestrator. No LLM in the control loop.
- No vestigial test harnesses — tests exercise the real execution path.
- Model assignment by node complexity, not uniform across pipeline.

## Division of Labor

- **Hobson** (host): MockEtlFrameworkPython, host-side infrastructure (symlinks, mounts, external.py), Proofmark
- **BD** (container): Workflow engine, agent blueprints, queue plumbing, agent invocation wiring, tests
