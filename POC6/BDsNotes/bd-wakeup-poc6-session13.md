# BD Wake-Up — POC6 Session 13

## Paste this to start the session:

```
Read /workspace/AtcStrategy/POC6/BDsNotes/bd-wakeup-poc6-session13.md then tell me where we are.
```

---

## What Happened Last Session

1. **v0.1: COMPLETE** (sessions 1-11). 92 tests, 38 requirements. All validated.

2. **v0.2 milestone initialized** (session 12): 16 requirements, 4-phase roadmap (phases 4-7).

3. **Phase 4 planned** (session 12):
   - 2 plans across 2 waves, verified by plan-checker (passed with 1 non-blocking warning)
   - Plan 04-01 (wave 1): Schema DDL (`re_task_queue`, `re_job_state`), psycopg3 pool, CRUD + tests
   - Plan 04-02 (wave 2): `SKIP LOCKED` concurrency proof, one-active-per-job constraint tests
   - Committed: `a01fc30` (plans), `cfb26a4` (.gitignore)
   - **Checker warning:** `fail_task` signature inconsistency in 04-01 Task 2 — behavior section says
     `fail_task(task_id, error_msg)` but action section revises to `fail_task(task_id)`. Action is authoritative.

4. **40+ commits unpushed on main** in EtlReverseEngineering.

## What Needs to Happen

**Next step: Execute Plan 04-01** — read the plan, do TDD directly. Do NOT use `/gsd:execute-phase`.

### Phase 4 Plans

| Plan | Wave | What it builds | Requirements | Status |
|------|------|---------------|-------------|--------|
| 04-01 | 1 | Schema DDL, psycopg3 pool, CRUD operations + tests | TQ-01, JS-01, JS-02 | **NOT STARTED** |
| 04-02 | 2 | SKIP LOCKED concurrency proof, one-active-per-job | TQ-02, JS-03 | NOT STARTED |

### How to Execute

1. Read `.planning/phases/04-postgres-foundations/04-01-PLAN.md`
2. Follow the tasks in order — write code, write tests, run tests
3. Use `fail_task(task_id: int)` (no error param) — the action section is authoritative
4. When 04-01 is green, move to 04-02

### The 4 Phases (v0.2)

| # | Phase | Requirements | Status |
|---|-------|-------------|--------|
| 4 | Postgres Foundations | TQ-01, TQ-02, JS-01, JS-02, JS-03 | **PLANNED** |
| 5 | Queue Write Paths | TQ-03, TQ-04 | NOT STARTED |
| 6 | Worker Pool | WK-01, WK-02, WK-03, WK-04 | NOT STARTED |
| 7 | State Machine Wiring and Tests | SM-10, SM-11, TS-01, TS-02, TS-03 | NOT STARTED |

### What v0.2 Is

Replace the synchronous `Engine.run_job()` loop with a work-stealing execution model:
- Postgres `re_task_queue` in `control` schema (172.18.0.1:5432, user=claude)
- N worker threads (default 6, configurable) monitoring the queue
- `SELECT ... FOR UPDATE SKIP LOCKED` for FIFO claiming
- Node completion enqueues the next task — no direct invocation
- Job manifest JSON as input (existing format: `/workspace/AtcStrategy/POC6/HobsonsNotes/job-scope-manifest.json`)
- Parallelism across jobs, NOT within a single job
- Stubs stay stubbed — this is infrastructure only, de-stubbing is a future milestone

### Key Decisions From Dan

- **No vestigial test harness.** The synchronous `run_job()` gets deleted entirely.
  Engine integration tests get rewritten to work against the queue-based model.
  Dan's exact words: "I don't want a test harness that operates fundamentally different
  from the real-world workflow"
- **Transition table data tests stay as-is.** They test the dict, not the execution model.
- **Worker default is 6** with external config override.
- **Job manifest format already exists** — 103 jobs with job_id, job_name, job_conf_path.

### Key Files

- `/workspace/EtlReverseEngineering/.planning/phases/04-postgres-foundations/04-01-PLAN.md` — **execute this next**
- `/workspace/EtlReverseEngineering/.planning/phases/04-postgres-foundations/04-02-PLAN.md` — after 04-01
- `/workspace/EtlReverseEngineering/.planning/PROJECT.md` — project context
- `/workspace/EtlReverseEngineering/.planning/REQUIREMENTS.md` — 16 requirements
- `/workspace/EtlReverseEngineering/.planning/ROADMAP.md` — 7-phase roadmap
- `/workspace/EtlReverseEngineering/src/workflow_engine/` — the live code
- `/workspace/AtcStrategy/POC6/BDsNotes/state-machine-transitions.md` — transition table
- `/workspace/AtcStrategy/POC6/BDsNotes/poc6-architecture.md` — architecture doc

### Design Principles (non-negotiable)

- No errata accumulation between attempts
- Two counter types only: main retry (N) and conditional (M)
- Fresh context every agent invocation
- Parallelism at job level, not within a job
- Deterministic orchestrator, no LLM in the control loop
- No vestigial test harnesses — tests must exercise the real execution path

---

## RAM WARNING — READ THIS

Dan's host has 15GB RAM + 16GB swap. This container shares the host's swap.
**Subagent spawning is dangerous.** GSD executor subagents have OOM'd the host twice.

**Standing order:**
- Do NOT use `/gsd:execute-phase`. It will spawn subagents and OOM.
- Execute TDD cycles directly — read the plan, write the code.
- Before heavy work, run `free -h` to confirm available memory.
