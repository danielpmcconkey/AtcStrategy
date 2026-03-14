# BD Wake-Up — POC6 Session 9

## Paste this to start the session:

```
Read /workspace/AtcStrategy/POC6/BDsNotes/bd-wakeup-poc6-session9.md then tell me where we are.
```

---

## What Happened Last Session

1. **Phase 1: COMPLETE** (session 7). 32 tests, all 16 requirements satisfied.

2. **Phase 2: COMPLETE** (session 8). Verification passed 14/14 must-haves.
   - Plan 02-01 (Wave 1): Expanded TRANSITION_TABLE with 18 review branching edges, added REVIEW_ROUTING dict, 7 response node stubs. 50 tests green.
   - Plan 02-02 (Wave 2): Implemented `_resolve_outcome()` with counter logic, auto-promotion, DEAD_LETTER, rewind + downstream counter reset. 59 tests green.
   - Commits: `e1c1073`, `a5f598c`, `7830362` (Wave 1), `fb6a4f9`, `7d9b9db` (Wave 2), `af389f5` (phase completion).

3. **Phase 2 deviation:** Updated Phase 1 `test_no_state_bleed` assertion — APPROVE now resets counters to 0 (creating dict keys) instead of leaving `conditional_counts` empty. Semantically correct, not a regression.

4. **Verifier noted:** Plan 02-02 uses `REVIEW_ROUTING[node_name]` to find rewind targets instead of `TRANSITION_TABLE[(node, Outcome.FAIL)]` as originally planned. Same result, cleaner design.

## What Needs to Happen

Plan and execute Phase 3.

```
/gsd:plan-phase 3
```

After planning completes:

```
/gsd:execute-phase 3
```

### The 3 Phases

| # | Phase | Requirements | Status |
|---|-------|-------------|--------|
| 1 | Foundation and Happy Path Engine | 16 | **COMPLETE** |
| 2 | Review Branching and Counter Mechanics | 11 | **COMPLETE** |
| 3 | FBR Gauntlet, Triage, and Validation Run | 11 | **PLANNED** — plan + execute next |

### Key Files

- `/workspace/EtlReverseEngineering/.planning/PROJECT.md` — project context
- `/workspace/EtlReverseEngineering/.planning/REQUIREMENTS.md` — 38 requirements, full traceability
- `/workspace/EtlReverseEngineering/.planning/ROADMAP.md` — 3-phase roadmap
- `/workspace/EtlReverseEngineering/.planning/STATE.md` — current position
- `/workspace/EtlReverseEngineering/.planning/phases/02-review-branching-and-counter-mechanics/` — Phase 2 plans, summaries, verification
- `/workspace/EtlReverseEngineering/src/workflow_engine/` — the live code
- `/workspace/AtcStrategy/POC6/BDsNotes/state-machine-transitions.md` — transition table (source of truth)

### Design Principles (non-negotiable)

- No errata accumulation between attempts
- Two counter types only: main retry (N) and conditional (M)
- Fresh context every agent invocation
- Parallelism at job level, not within a job
- Deterministic orchestrator, no LLM in the control loop
- Source lives at `src/workflow_engine/`

---

## RAM WARNING — READ THIS

Dan's host has 15GB RAM + 16GB swap. This container shares the host's swap.
**Subagent spawning is dangerous.** During session 8, GSD executor subagents
ate all available memory + swap TWICE, forcing Dan to kill them manually.

**What happened:** The GSD `execute-phase` workflow spawns subagents (separate
Claude processes) to execute each plan. Two Claude instances + host processes
competing for 15GB = OOM. Swap filled to 5GB before Dan caught it.

**What worked:** Executing Plan 02-02 directly (no subagent) — one Claude
process, TDD by hand, zero memory issues.

**Standing order for Phase 3 execution:**
- Do NOT use `/gsd:execute-phase 3`. It will spawn subagents and OOM.
- Instead, read each plan yourself and execute the TDD cycle directly.
- `/gsd:plan-phase 3` is fine — planning doesn't spawn heavy subagents.
- If Dan insists on subagents, warn him about the RAM situation first.
- Before execution, run `free -h` to confirm available memory.
- If swap is dirty from a previous session: tell Dan to run
  `sudo swapoff -a && sudo swapon -a` on the host to flush it.
