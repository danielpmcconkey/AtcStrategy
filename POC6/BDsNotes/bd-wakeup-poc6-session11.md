# BD Wake-Up — POC6 Session 11

## Paste this to start the session:

```
Read /workspace/AtcStrategy/POC6/BDsNotes/bd-wakeup-poc6-session11.md then tell me where we are.
```

---

## What Happened Last Session

1. **Phase 3: COMPLETE** (session 10). All 3 phases done. 92 tests, 38 requirements satisfied.
   - Plan 03-01: FBR gauntlet routing + engine logic (commit `ce1e332`)
   - Plan 03-02 Tasks 1-2: Triage pipeline + engine logic (commit `9fa0a71`)
   - Plan 03-02 Task 3: 200-job validation run (commit `3e103fe`)

2. **Node registry fix**: StubWorkNode and StubReviewNode only get RNG for nodes that have
   failure edges. FinalSignOff, ExecuteUnitTests, ExecuteJobRuns, Publish are always deterministic.
   Without this, the validation run hit missing transitions.

3. **Skeptical auditor ran** against the validation run. Verdict:
   - Code faithfully implements the spec. All 71 edges match.
   - Validation test is loose — "at least one" threshold checks. Real regression
     protection comes from the 85+ targeted unit tests.
   - Triage coverage thin in the validation run (2 of 4 destinations hit).
   - Response node FAILURE edges are an undocumented extension of the spec (reasonable but not in the table).
   - The workflow is internally consistent but unproven against real RE tasks.

4. **37 commits unpushed on main** in EtlReverseEngineering.

## What Needs to Happen

Two things, both new work (no existing plans):

### 1. De-stub nodes — replace stubs with real agent invocations

The workflow engine currently uses StubWorkNode/StubReviewNode/DiagnosticStubNode everywhere.
These return random or deterministic outcomes but don't do anything. Time to start replacing
them with real implementations that invoke Claude CLI agents with per-node blueprints.

Key context:
- Architecture says atomic agents: claim task, do one thing, queue next step, die
- Fresh Claude CLI context per invocation (no rot)
- Per-agent blueprints as system prompts (see `agent-taxonomy.md`)
- Agents produce Python artifacts for MockEtlFrameworkPython
- No need to de-stub everything at once — start with a vertical slice

### 2. Multi-threaded task executor and queue

The engine currently runs jobs sequentially (`run_job()` in a for loop). The architecture
calls for parallelism at the job level (105 independent pipelines). Need:
- Postgres task queue with `SELECT ... FOR UPDATE SKIP LOCKED` (Postgres already available at 172.18.0.1)
- Multi-threaded executor that pulls jobs from the queue
- Job-level parallelism, NOT within-pipeline parallelism
- See `poc6-architecture.md` for the queue design

### Order TBD — discuss with Dan

These two are independent. Dan may want to tackle them in either order or interleave.
Don't assume — ask.

### The 3 Phases (all complete)

| # | Phase | Requirements | Status |
|---|-------|-------------|--------|
| 1 | Foundation and Happy Path Engine | 16 | **COMPLETE** |
| 2 | Review Branching and Counter Mechanics | 11 | **COMPLETE** |
| 3 | FBR Gauntlet, Triage, and Validation Run | 11 | **COMPLETE** |

### Key Files

- `/workspace/EtlReverseEngineering/.planning/PROJECT.md` — project context
- `/workspace/EtlReverseEngineering/.planning/REQUIREMENTS.md` — 38 requirements, full traceability
- `/workspace/EtlReverseEngineering/.planning/ROADMAP.md` — 3-phase roadmap (all done)
- `/workspace/EtlReverseEngineering/src/workflow_engine/` — the live code
- `/workspace/AtcStrategy/POC6/BDsNotes/state-machine-transitions.md` — transition table (source of truth)
- `/workspace/AtcStrategy/POC6/BDsNotes/poc6-architecture.md` — architecture doc (queue design, agent model)
- `/workspace/AtcStrategy/POC6/BDsNotes/agent-taxonomy.md` — agent taxonomy (blueprint reference)

### Design Principles (non-negotiable)

- No errata accumulation between attempts
- Two counter types only: main retry (N) and conditional (M)
- Fresh context every agent invocation
- Parallelism at job level, not within a job
- Deterministic orchestrator, no LLM in the control loop

---

## RAM WARNING — READ THIS

Dan's host has 15GB RAM + 16GB swap. This container shares the host's swap.
**Subagent spawning is dangerous.** GSD executor subagents have OOM'd the host twice.

**Standing order:**
- Do NOT use `/gsd:execute-phase`. It will spawn subagents and OOM.
- Execute TDD cycles directly — read the plan, write the code.
- Before heavy work, run `free -h` to confirm available memory.
