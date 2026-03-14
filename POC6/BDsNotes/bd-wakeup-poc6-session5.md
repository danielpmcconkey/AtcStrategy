# BD Wake-Up — POC6 Session 5

## Paste this to start the session:

```
Read /workspace/AtcStrategy/POC6/BDsNotes/bd-wakeup-poc6-session5.md then tell me where we are.
```

---

## What Happened Last Session

1. Checked the old GSD project in EtlReverseEngineering — it was 100% stale (C#/.NET 8
   roadmap, zero phases executed). Nuked `.planning/` and started fresh.

2. Ran `/gsd:new-project` end-to-end:
   - Deep questioning (short — design was already locked from Session 3)
   - 4 parallel researchers (stack, features, architecture, pitfalls)
   - Key research finding: roll your own FSM, don't use a library. structlog as the
     one runtime dep. Counter scope confusion is the #1 risk.
   - Defined 38 v1 requirements across 8 categories
   - Created 3-phase coarse roadmap (approved)

3. **Critical design correction during questioning:** Dan clarified the counter model
   is simpler than researchers assumed. NOT four counter families. TWO:
   - **Main retry counter (N, per job):** Any full Fail increments it. Hits N → DEAD_LETTER.
     No separate FBR depth cap or triage retry counter — the main counter naturally bounds everything.
   - **Conditional counter (M, per node instance):** Hits M → auto-promotes to Fail.
     Resets to 0 on success at that node OR on rewind past that node.
   - N and M are configurable with sensible defaults.

4. Config: YOLO mode, coarse granularity, parallel execution, git-tracked, all agents on,
   balanced (sonnet) models.

## What Needs to Happen

Start planning and executing Phase 1.

```
/gsd:discuss-phase 1
```

or skip straight to:

```
/gsd:plan-phase 1
```

### The 3 Phases

| # | Phase | Requirements | Core Complexity |
|---|-------|-------------|-----------------|
| 1 | Foundation and Happy Path Engine | 16 | Get the loop running — state model, transition table, stubs, logging |
| 2 | Review Branching and Counter Mechanics | 11 | The hard phase — three-outcome reviews, rewind+replay, counter semantics |
| 3 | FBR Gauntlet, Triage, and Validation Run | 11 | FBR 6-gate gauntlet, triage T1-T7, 100+ job validation batch |

### Key Files

- `/workspace/EtlReverseEngineering/.planning/PROJECT.md` — project context (corrected counter model)
- `/workspace/EtlReverseEngineering/.planning/REQUIREMENTS.md` — 38 requirements, full traceability
- `/workspace/EtlReverseEngineering/.planning/ROADMAP.md` — 3-phase roadmap
- `/workspace/EtlReverseEngineering/.planning/research/SUMMARY.md` — research synthesis
- `/workspace/AtcStrategy/POC6/BDsNotes/state-machine-transitions.md` — the transition table (source of truth)

### Design Principles (non-negotiable)

- No errata accumulation between attempts
- Two counter types only: main retry (N) and conditional (M)
- Fresh context every agent invocation
- Parallelism at job level, not within a job
- Deterministic orchestrator, no LLM in the control loop
- Source lives at `src/workflow_engine/`
