# State of POC6

**Last updated:** 2026-03-14 (session 18)

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

### v0.3 Agent Integration — FIRST RUN DONE, FIXING PATH ISSUES

Replaced node stubs with Claude CLI agent invocations. First full pipeline run
on job 373 (`dans_transaction_special`) got through all build + FBR gates but
failed at the validate stage:
- `ExecuteJobRuns` ran ETL framework locally instead of queuing to `control.task_queue`
- `ExecuteProofmark` queued correctly but used wrong paths — all 62 tasks failed
- Publisher overwrote OG job registration in `control.jobs` (fixed)

**Session 18 fixes:**
- Hobson designed path architecture v2 — `RE/` directories, symlinked to host
- All blueprints updated for `_re` naming, `{ETL_ROOT}` literal tokens, RE/ paths
- DB cleaned, OG job registration restored, artifacts wiped for fresh run
- Awaiting: container rebuild (re-curated mount), Hobson's symlinks, re-seed

## Path Architecture (v2)

- **One literal token: `{ETL_ROOT}`** — never resolved by orchestrator, host
  expands at runtime from its own env var
- **RE artifacts** deploy to `{ETL_ROOT}/RE/Jobs/` and `{ETL_ROOT}/RE/externals/`
  (symlinked from host codeprojects to container workspace)
- **`_re` suffix** on all RE identifiers: jobName, typeName, module filenames,
  control.jobs registration
- **OG output** at `{ETL_ROOT}/Output/curated/` (ro mount)
- **RE output** at `{ETL_ROOT}/Output/re-curated/` (ro mount, host writes here)
- See: `AtcStrategy/POC6/HobsonsNotes/path-changes-for-bd-v2.md`

## Architecture

- Dumb Python orchestrator, no LLM in the control loop
- Deterministic state machine drives workflow
- Atomic agents: claim task, do one thing, queue next step, die
- Fresh Claude CLI context per invocation (no rot)
- Postgres task queue with `SELECT ... FOR UPDATE SKIP LOCKED`
- Per-agent blueprints as system prompts
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
| `src/workflow_engine/nodes.py` | Node ABC, stub implementations, agent registry |
| `src/workflow_engine/agent_node.py` | AgentNode — Claude CLI invocation per blueprint |
| `src/workflow_engine/models.py` | JobState, EngineConfig, Outcome, NodeType |
| `blueprints/_conventions.md` | Agent conventions, path tokens, RE naming rules |

## Design Principles (standing)

- No errata accumulation. Retry counter is the only memory between attempts.
- Two counter types only: main retry (N) and conditional (M).
- Keep agents dumb. Let the state machine's structure handle complexity.
- Parallelism is at the job level, not within a single job's pipeline.
- Fresh context every agent invocation. No state carried between invocations.
- Deterministic orchestrator. No LLM in the control loop.
- No vestigial test harnesses — tests exercise the real execution path.

## Division of Labor

- **Hobson** (host): MockEtlFrameworkPython, host-side infrastructure (symlinks, mounts, external.py), Proofmark
- **BD** (container): Workflow engine, agent blueprints, queue plumbing, agent invocation wiring, tests
