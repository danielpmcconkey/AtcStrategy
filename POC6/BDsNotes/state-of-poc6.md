# State of POC6

**Last updated:** 2026-03-14 (session 13)

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

### v0.3 Agent Integration — NOT STARTED

Replace node stubs with Claude CLI agent invocations. Hobson is writing agent blueprints upstairs.

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
| `src/workflow_engine/nodes.py` | Node ABC, stub implementations |
| `src/workflow_engine/models.py` | JobState, EngineConfig, Outcome, NodeType |

## Design Principles (standing)

- No errata accumulation. Retry counter is the only memory between attempts.
- Two counter types only: main retry (N) and conditional (M).
- Keep agents dumb. Let the state machine's structure handle complexity.
- Parallelism is at the job level, not within a single job's pipeline.
- Fresh context every agent invocation. No state carried between invocations.
- Deterministic orchestrator. No LLM in the control loop.
- No vestigial test harnesses — tests exercise the real execution path.

## Division of Labor

- **Hobson** (host): Agent blueprints, MockEtlFrameworkPython, anything touching the host filesystem
- **BD** (container): Workflow engine, queue plumbing, agent invocation wiring, tests
