# Session Boundary Implementation — Step 14

**Status:** DRAFT
**Created:** 2026-03-07
**Depends on:** Steps 11 (Phase Structure), 12 (Agent Architecture)
**Feeds into:** Step 15 (Blueprints), Step 16 (Runbook)

---

## Principle

Session boundaries are hard stops, not checkpoints. No agent self-assesses
its own degradation. A fresh session loading clean state beats a degraded
session every time. (Doctrine §3.5)

---

## Phase Boundaries (Between Phases)

Every phase boundary follows the same ritual:

1. Orchestrator stops and reports completion to BD
2. BD validates existence of all required outputs
3. Dan manually approves
4. Dan checks token usage
5. Dan recycles BD (fresh session, clean context)

**Mechanically:** BD launches each Orchestrator as a background agent.
When Orchestrator's work is done, it sends a completion message. BD does
NOT keep the Orchestrator alive for the next phase — a fresh Orchestrator
instance with a fresh blueprint is launched for each phase.

**State transfer between phases:** Artifacts on disk only. No agent carries
context across a phase boundary. The next Orchestrator reads the artifacts
produced by the previous phase as its input.

---

## Within-Phase Boundaries (Batch Boundaries)

Orchestrator processes jobs in batches. At each batch boundary:

1. **Check for CLUTCH file** — `POC4/CLUTCH`. If present, stop and report
   to BD. Dan uses this as an external brake.
2. **Run `dotnet build`** (E.4 only) — catch compile errors early
3. **Update session state** — `POC4/session-state.md` with progress
4. **First-batch gate** — after the first batch completes, Orchestrator
   evaluates quality before proceeding. A broken blueprint caught after
   5 jobs is cheap; caught after 101 is waste.

**Batch sizing:**
- Default: configurable in Orchestrator blueprint, recommended ≤20 jobs
- Concurrency cap: ≤10 simultaneous worker agents
- For dry run (5 jobs): single batch, no batch boundaries needed

---

## Worker Boundaries

Workers are ephemeral subagents. They:
- Spawn with a specific assignment (1 or more jobs)
- Receive only the context needed for their assignment
- Return results to Orchestrator
- Die when their assignment is complete

Workers do NOT persist between assignments. If Orchestrator needs to
reassign work (e.g., reviewer rejects an artifact), it spawns a fresh
worker with the feedback included in context.

---

## CLUTCH Mechanism

**Location:** `POC4/CLUTCH`
**Created by:** Dan (from host) or BD (at Dan's instruction)
**Checked by:** Orchestrator at batch boundaries

If the file exists, Orchestrator must:
1. Finish the current in-progress work (don't abandon mid-job)
2. Write current state to `POC4/session-state.md`
3. Stop launching new work
4. Report to BD: "CLUTCH engaged, paused at batch N"

Dan decides what happens next: resume, adjust, or terminate.

---

## Session State File

**Location:** `POC4/session-state.md`
**Written by:** Orchestrator at batch boundaries and on CLUTCH
**Purpose:** Resurrection artifact. If Orchestrator crashes or BD gets
recycled mid-phase, this file tells the next instance where to pick up.

```markdown
# Session State — {Phase}

**Last updated:** {timestamp}
**Phase:** E.{n}
**Batch:** {current batch number}
**Jobs completed:** {list}
**Jobs in progress:** {list}
**Jobs remaining:** {list}
**Notes:** {anything relevant for resurrection}
```

---

## Dry Run Simplification

- Phase boundaries: still enforced (this is the ritual we're testing)
- Batch boundaries: skipped (5 jobs = 1 batch)
- CLUTCH: available but unlikely to be used
- Session state: still written (good habit, tests the mechanism)
