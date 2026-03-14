# BD Wake-Up — POC6 Session 10

## Paste this to start the session:

```
Read /workspace/AtcStrategy/POC6/BDsNotes/bd-wakeup-poc6-session10.md then tell me where we are.
```

---

## What Happened Last Session

1. **Phase 1: COMPLETE** (session 7). 32 tests, all 16 requirements satisfied.

2. **Phase 2: COMPLETE** (session 8). 59 tests, 14/14 must-haves verified.

3. **Phase 3: PLANNED** (session 9). Research, validation strategy, and 2 plans created. Verification passed all 8 dimensions, 11/11 requirements covered.
   - Commits: `f3e6862` (research), `5d94b34` (validation strategy), `79a4f03` (plans).

## What Needs to Happen

Execute Phase 3 manually — read each plan and do the TDD cycle yourself. **Do NOT use `/gsd:execute-phase 3`** (RAM constraint, see below).

### Execution Order

**Plan 03-01 first (Wave 1):** FBR Gauntlet
- Read the plan: `cat .planning/phases/03-fbr-gauntlet-triage-and-validation-run/03-01-PLAN.md`
- FBR_ROUTING dict, CONDITIONAL/FAIL edges for 6 gates, fbr_return_pending flag, response node FAILURE edges
- Requirements: FBR-01, FBR-02, FBR-03, FBR-04
- 2 TDD tasks

**Plan 03-02 second (Wave 2):** Triage + Validation Run
- Read the plan: `cat .planning/phases/03-fbr-gauntlet-triage-and-validation-run/03-02-PLAN.md`
- Triage T1-T7 pipeline, DiagnosticStubNode, TriageRouterNode, TRIAGE_ROUTE outcome, 200-job validation run
- Requirements: TR-01, TR-02, TR-03, TR-04, TR-05, TR-06, TR-07
- 3 tasks (2 TDD + 1 validation)

### The 3 Phases

| # | Phase | Requirements | Status |
|---|-------|-------------|--------|
| 1 | Foundation and Happy Path Engine | 16 | **COMPLETE** |
| 2 | Review Branching and Counter Mechanics | 11 | **COMPLETE** |
| 3 | FBR Gauntlet, Triage, and Validation Run | 11 | **PLANNED** — execute next |

### Key Files

- `/workspace/EtlReverseEngineering/.planning/PROJECT.md` — project context
- `/workspace/EtlReverseEngineering/.planning/REQUIREMENTS.md` — 38 requirements, full traceability
- `/workspace/EtlReverseEngineering/.planning/ROADMAP.md` — 3-phase roadmap
- `/workspace/EtlReverseEngineering/.planning/STATE.md` — current position
- `/workspace/EtlReverseEngineering/.planning/phases/03-fbr-gauntlet-triage-and-validation-run/` — plans, research, validation
- `/workspace/EtlReverseEngineering/src/workflow_engine/` — the live code
- `/workspace/AtcStrategy/POC6/BDsNotes/state-machine-transitions.md` — transition table (source of truth)

### Design Principles (non-negotiable)

- No errata accumulation between attempts
- Two counter types only: main retry (N) and conditional (M)
- Fresh context every agent invocation
- Parallelism at job level, not within a job
- Deterministic orchestrator, no LLM in the control loop
- Source lives at `src/workflow_engine/`

### Key Design Decisions from Research (baked into plans)

- **FBR_ROUTING** reuses same response nodes as REVIEW_ROUTING. `fbr_return_pending` flag differentiates routing.
- **fbr_return_pending** set on FBR CONDITIONAL only, never on FAIL. Cleared on FBR_BrdCheck entry.
- **DiagnosticStubNode** always returns SUCCESS. Stores fault/clean in `job.triage_results`. T7 reads results and returns `Outcome.TRIAGE_ROUTE`.
- **TriageProofmarkFailures** placeholder from Phase 2 gets retired — T7 rewind handles it.
- **Response node FAILURE edges** (deferred from Phase 2) get wired in 03-01.

---

## RAM WARNING — READ THIS

Dan's host has 15GB RAM + 16GB swap. This container shares the host's swap.
**Subagent spawning is dangerous.** During session 8, GSD executor subagents
ate all available memory + swap TWICE, forcing Dan to kill them manually.

**Standing order for Phase 3 execution:**
- Do NOT use `/gsd:execute-phase 3`. It will spawn subagents and OOM.
- Instead, read each plan yourself and execute the TDD cycle directly.
- Before execution, run `free -h` to confirm available memory.
- If swap is dirty from a previous session: tell Dan to run
  `sudo swapoff -a && sudo swapon -a` on the host to flush it.
