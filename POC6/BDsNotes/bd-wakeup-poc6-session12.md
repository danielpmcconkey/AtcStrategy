# BD Wake-Up — POC6 Session 12

## Paste this to start the session:

```
Read /workspace/AtcStrategy/POC6/BDsNotes/bd-wakeup-poc6-session12.md then tell me where we are.
```

---

## What Happened Last Session

1. **v0.1: COMPLETE** (sessions 1-11). All 3 phases done. 92 tests, 38 requirements satisfied.
   State machine fully validated — transitions, counters, rewinds, FBR gauntlet, triage, DEAD_LETTER.

2. **v0.2 milestone initialized**: "Parallel Execution Infrastructure"
   - Dan chose multi-threaded executor + Postgres queue over de-stubbing
   - Skipped research (we know Postgres and Python threading)
   - 16 requirements defined and approved (TQ-01–04, JS-01–03, WK-01–04, SM-10–11, TS-01–03)
   - 4-phase roadmap created and approved (phases 4–7)
   - MILESTONES.md created to archive v0.1
   - All committed: `64e9bcb` (milestone start), `688b6b1` (roadmap)

3. **37+ commits unpushed on main** in EtlReverseEngineering.

## What Needs to Happen

**Next step: `/gsd:plan-phase 4`** — then execute it.

### The 4 Phases (v0.2)

| # | Phase | Requirements | Status |
|---|-------|-------------|--------|
| 4 | Postgres Foundations | TQ-01, TQ-02, JS-01, JS-02, JS-03 | **NOT STARTED** |
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

- `/workspace/EtlReverseEngineering/.planning/PROJECT.md` — project context (updated for v0.2)
- `/workspace/EtlReverseEngineering/.planning/REQUIREMENTS.md` — 16 requirements, full traceability
- `/workspace/EtlReverseEngineering/.planning/ROADMAP.md` — 7-phase roadmap (phases 1-3 done, 4-7 new)
- `/workspace/EtlReverseEngineering/.planning/MILESTONES.md` — v0.1 archived
- `/workspace/EtlReverseEngineering/src/workflow_engine/` — the live code
- `/workspace/AtcStrategy/POC6/BDsNotes/state-machine-transitions.md` — transition table (source of truth)
- `/workspace/AtcStrategy/POC6/BDsNotes/poc6-architecture.md` — architecture doc (queue design, agent model)
- `/workspace/AtcStrategy/POC6/HobsonsNotes/job-scope-manifest.json` — job manifest (103 jobs)

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
