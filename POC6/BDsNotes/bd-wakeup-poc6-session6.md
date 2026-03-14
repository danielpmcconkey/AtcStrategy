# BD Wake-Up — POC6 Session 6

## Paste this to start the session:

```
Read /workspace/AtcStrategy/POC6/BDsNotes/bd-wakeup-poc6-session6.md then tell me where we are.
```

---

## What Happened Last Session

1. Did a quick research tour on `/compound-engineering:deepen-plan` — it's a CE skill that
   throws every available agent at a plan in parallel for enrichment. Cool concept but CE-native,
   not plug-and-play with GSD. Filed it under "interesting, might steal the idea later."

2. Ran `/gsd:plan-phase 1` end-to-end:
   - Skipped discuss-phase — all design decisions already baked into PROJECT.md and REQUIREMENTS.md
   - **Research:** High confidence, zero architectural unknowns. "Translate spec to code."
     Key insight: design JobState with counter fields from day one (main_retry_count,
     conditional_counts dict) even though Phase 1 won't use them.
   - **Validation strategy:** Created and committed. All 16 requirements mapped to pytest commands.
     Wave 0 needs: pyproject.toml, package inits, conftest, and test file stubs.
   - **Planning:** 2 plans in 2 waves, all 16 requirements covered.
   - **Verification:** Passed all 8 dimensions clean on first try. No revision loop needed.

3. Plans are committed and ready to execute.

## What Needs to Happen

Execute Phase 1.

```
/gsd:execute-phase 1
```

### Phase 1 Plan Structure

| Wave | Plan | What it builds |
|------|------|----------------|
| 1 | 01-01 | Data layer: models (JobState, EngineConfig, Outcome enum), transition table (dict-based, all 27 nodes), node stubs, structlog config + full test suite |
| 2 | 01-02 | Engine: main loop (pick→resolve→execute→advance→repeat), CLI entry point, end-to-end smoke test |

- Plan 01 is the denser one (12 files, 2 tasks) — but it's mechanical scaffolding
- Plan 02 depends on 01 and wires everything into a running loop (3 files, 2 tasks)

### The 3 Phases (unchanged)

| # | Phase | Requirements | Core Complexity |
|---|-------|-------------|-----------------|
| 1 | Foundation and Happy Path Engine | 16 | Get the loop running — state model, transition table, stubs, logging |
| 2 | Review Branching and Counter Mechanics | 11 | The hard phase — three-outcome reviews, rewind+replay, counter semantics |
| 3 | FBR Gauntlet, Triage, and Validation Run | 11 | FBR 6-gate gauntlet, triage T1-T7, 100+ job validation batch |

### Key Files

- `/workspace/EtlReverseEngineering/.planning/PROJECT.md` — project context (corrected counter model)
- `/workspace/EtlReverseEngineering/.planning/REQUIREMENTS.md` — 38 requirements, full traceability
- `/workspace/EtlReverseEngineering/.planning/ROADMAP.md` — 3-phase roadmap
- `/workspace/EtlReverseEngineering/.planning/phases/01-foundation-and-happy-path-engine/` — Phase 1 artifacts:
  - `01-RESEARCH.md` — research findings
  - `01-VALIDATION.md` — test strategy and requirement→test mapping
  - `01-01-PLAN.md` — Wave 1: data layer
  - `01-02-PLAN.md` — Wave 2: engine + integration
- `/workspace/AtcStrategy/POC6/BDsNotes/state-machine-transitions.md` — the transition table (source of truth)

### Design Principles (non-negotiable)

- No errata accumulation between attempts
- Two counter types only: main retry (N) and conditional (M)
- Fresh context every agent invocation
- Parallelism at job level, not within a job
- Deterministic orchestrator, no LLM in the control loop
- Source lives at `src/workflow_engine/`
