# State of POC6

**Last updated:** 2026-03-15 (session 20)

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

### v0.3 Agent Integration — 10/11 JOBS COMPLETE, 12 IN PROGRESS

First end-to-end pipeline runs with real Claude CLI agents replacing stubs.

**Session 18:** First complete run — job 373 (`DansTransactionSpecial`), 62/62
proofmark comparisons passed STRICT. Several bug fixes (signoff outcome type,
proofmark-executor paths, no-delete evidence rule).

**Session 19:** 10-job batch run. Results:
- **Run 1 (all 10):** 4 completed, 6 failed at `ExecuteJobRuns`. Root cause:
  `_load_all()` in `external.py` had hardcoded import list including a phantom
  module (`repeat_overdraft_customer_processor`) from a job cut between POC5/POC6.
  Also discovered agents were copy-pasting OG external module code with `_re`
  suffix instead of actually remediating anti-patterns.
- **Blueprint overhaul:** Rewrote 10 blueprints to enforce remediation-first
  anti-pattern policy. Key change: externals are last resort, not default.
  FSD writer now instructs agents to inline logic into standard framework
  modules (DataSourcing, Transformation, CsvFileWriter).
- **Hobson fix:** Replaced hardcoded `_load_all()` import list with directory
  scan (`pkgutil.iter_modules`). 156 tests passing.
- **Run 2 (6 failed jobs, fresh start):** 5 completed with genuine remediation.
  Jobs 160 and 166 fully eliminated external modules. Jobs 161, 164, 165
  reduced externals to thin I/O shims. All proofmark STRICT. Job 163
  (TransactionAnomalyFlags) still running — got kicked back by FBR.
- **Timeout fix:** `run_until_drained` timeout bumped from 1h to 4h.

**Session 20:** Infrastructure + batch-12 launch.
- **Job 163 dead-lettered** at FBR_ProofmarkCheck (5/5 retries exhausted).
  Root cause: zombie job from missing FAIL transition + timeout cascade.
  Rebuilt successfully on retry but couldn't survive FBR gauntlet.
- **Bug fix: work-node FAIL transitions.** WORK nodes had no FAIL edge in
  the transition table, causing zombie jobs (status=RUNNING, no queue entry).
  Added self-retry FAIL edges for all 27 work nodes. Also added save-before-raise
  safety net in step_handler.
- **Per-node model mapping.** `MODEL_MAP` in `nodes.py` assigns models by node:
  Opus for spec/design/adversarial review (16 nodes), Haiku for mechanical
  execution (2 nodes), Sonnet for everything else (23 nodes via fallback).
  ~35% fewer Opus calls vs uniform Opus.
- **Blueprint cleanup.** Burned all C# references (OG is now Python). Killed
  stale tokens (`{OG_CS_ROOT}`, `{FW_DOCS}`, `{ORCH_ROOT}`, `{JOB_DIR}`).
  All paths hardcoded. `{ETL_ROOT}` remains as only token (literal for DB).
  Updated external module interface docs (register/execute pattern).
- **Timeout bumped** from 600s to 1800s (30 min) per step.
- **Token-budget clutch** tested and working. `control.re_engine_config`
  `clutch_engaged = true` parks all workers until disengaged.
- **Batch-12 launched** (13 jobs: 12 new + job 163 resume). All 12 new jobs
  progressed to Build/Validate stage before clutch engaged. Model mapping
  confirmed working in logs (Sonnet for Plan/Build, Opus for Review/FBR).

**Due diligence on completed jobs (session 19):**
- No proofmark cheating (all compare curated vs re-curated)
- Genuine code remediation (not copy-paste) confirmed for all 5
- 31-date proofmark coverage confirmed for 4/5 (job 164 only 1 date had output — legit)
- All deployments correct (RE/Jobs, RE/externals, Output/re-curated)

**Completed jobs:** 159, 160, 161, 162, 164, 165, 166, 369, 371, 373 (10 total)
**Dead-lettered:** 163 (TransactionAnomalyFlags — FBR_ProofmarkCheck, 5 retries)
**In progress (clutch engaged):** 1-12 (batch-12, all in Build/Validate stage)

## Batch Status at Clutch Engagement (session 20)

| Job | Node | Retries |
|-----|------|---------|
| 1   | ReviewProofmarkConfig | 0 |
| 2   | BuildProofmarkConfig | 0 |
| 3   | ReviewFsd | 0 |
| 4   | ReviewJobArtifacts | 0 |
| 5   | ReviewJobArtifacts | 0 |
| 6   | ExecuteUnitTests | 0 |
| 7   | BuildJobArtifacts | 0 |
| 8   | FBR_BddCheck | 0 |
| 9   | ExecuteUnitTests | 0 |
| 10  | BuildProofmarkConfig | 0 |
| 11  | ReviewProofmarkConfig | 0 |
| 12  | ReviewUnitTests | 0 |

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
- 103 independent job pipelines (from manifest), zero cross-contamination
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
| `blueprints/_conventions.md` | Agent conventions, paths, RE naming rules |

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
