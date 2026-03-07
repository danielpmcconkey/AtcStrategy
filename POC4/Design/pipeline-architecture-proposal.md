# Pipeline Architecture Proposal — Per-Job Parallel Execution

**Date:** 2026-03-07
**Author:** Hobson (Dan's host-side Claude)
**Status:** PROPOSAL — for Dan's review and discussion
**Replaces:** `PhaseDefinitions/phase-v-execution.md` (if adopted)
**Tooling addition:** GSD (Get Shit Done) plugin — ADOPT, not just ADAPT

---

## The Problem with the Current Architecture

The current execution plan (`phase-v-execution.md`) runs all jobs through each
phase together:

```
E.1: [all 105 jobs] → BRDs
E.2: [all 105 jobs] → FSDs
E.4: [all 105 jobs] → Build
E.6: [all 105 jobs × 92 dates] → Validate
```

One Orchestrator manages the entire batch per phase. Dan approves at every
phase boundary. This creates three walls that have been hit repeatedly in
dry runs:

### Wall 1: Orchestrator Context Exhaustion

The Orchestrator must track which jobs passed, which failed, which need retry,
which have special handling (weekends, append-mode, External modules). At 5
jobs this fits in context. At 105 it doesn't. The Orchestrator is the
bottleneck — not the work, not the jobs, not the agents doing the actual
reverse engineering.

Evidence: Two orchestrators killed in one night during E.6 dry run. First
replaced the queue service with a shell script. Second followed rules but
modified framework code without authorization. Both were overwhelmed by
multi-job state.

### Wall 2: Serial Execution Prevents Scale

Phase gates force all 105 jobs to complete E.1 before any job starts E.2. A
job that's ready for E.2 at 2am waits until Dan approves the entire E.1 batch
at 9am. This makes "push button, go to sleep" impossible by design.

### Wall 3: Monitoring Blindness

Progress files go stale. The Orchestrator updates at phase boundaries, not
per-job. The only monitoring option is tailing debug logs and checking file
existence on disk. At scale, this is unworkable.

---

## Proposed Alternative: Per-Job Pipelines

Flip the axis. Instead of "all jobs through each phase," run "each job through
all phases independently."

```
Dispatcher
  ├── Job 165: BRD → Review → FSD → Review → Build → Test → Validate
  ├── Job 166: BRD → Review → FSD → Review → Build → Test → Validate
  ├── Job 167: BRD → Review → FSD → Review → Build → Test → Validate
  │   ...
  └── Job 373: BRD → Review → FSD → Review → Build → Test → Validate
```

### Why This Solves the Three Walls

**Wall 1 (context):** No single agent ever holds state for more than one job.
The pipeline agent for job 165 knows nothing about job 166. Context growth is
O(1) per pipeline, not O(N) across the batch.

**Wall 2 (serial):** All pipelines run concurrently (up to platform limits).
Job 165 can be in validation while job 373 is still writing its BRD. No phase
gates between jobs. Dan goes to sleep.

**Wall 3 (monitoring):** Each pipeline writes its own status file. A thin
dispatcher reads them all. "85 passed, 10 in retry, 5 in build, 5 hard
failures." No orchestrator context needed for this — it's file-system-level
aggregation.

---

## Pipeline Stages (Per Job)

Each job runs through these stages sequentially. The pipeline agent manages
only this one job.

### Stage 1: Understand (≈ E.1)

1. Run V1 job for Oct 1-7 via task queue
2. Read V1 code (Serena for semantic navigation if available)
3. Write BRD with output schema and anti-pattern citations
4. Write output manifest (definitive list of every output file + schema)
5. Self-review: verify BRD against V1 code evidence

### Stage 2: Design (≈ E.2)

1. Read BRD
2. Write FSD specifying anti-pattern elimination with evidence
3. Write test strategy / test cases
4. Self-review: verify all BRD requirements have FSD coverage

### Stage 3: Build (≈ E.4)

1. Write V4 job config, External module (if justified), unit tests
2. Run `dotnet build` — must succeed
3. Run `dotnet test` — all must pass
4. Smoke test: run V4 for Oct 1-7 via task queue
5. Self-review: verify anti-patterns eliminated or justified

### Stage 4: Validate (≈ E.6)

1. For each effective date Oct 1 through Dec 31, 2024:
   - Run V1 and V4 via task queue
   - Run Proofmark comparison
   - If FAIL: triage, fix, re-run all dates up to current
2. 5-failure limit per job+date — hard stop, flag as failure
3. Write final Proofmark report

### Stage 5: Report

1. Write pipeline completion report (pass/fail, artifacts created, exceptions
   granted, retry count, errata entries)
2. Write status to shared status directory

---

## Coordination Layer (Thin)

Not an orchestrator. A dispatcher + monitor that never touches job content.

### Dispatcher

- Reads the job scope manifest
- Topologically sorts by dependency (for POC: all jobs are wave 1)
- Queues pipelines in waves — wave N+1 starts when wave N completes
- Manages concurrency: N pipelines at a time (platform-limited, probably 10-20)
- Writes aggregate status: `pipeline-status.json`

The dispatcher passes **file paths**, not content. It never reads a BRD, FSD,
or any job-specific artifact. Its context is:
- Job manifest (name, ID, wave, dependencies)
- Pipeline status per job (stage, pass/fail, retry count)
- Nothing else

This is GSD's orchestrator-starving pattern applied directly.

### Meta-Triage Agent

Triggered when multiple pipelines fail with similar Proofmark diffs. Looks for
correlated failures that indicate a framework bug rather than N independent
job bugs.

Fires when: ≥3 pipelines report failures with overlapping column/pattern.
Action: pause affected pipelines, investigate root cause, apply framework fix,
resume.

### Errata Curator

Same role as current design. Processes raw errata from individual pipelines
into curated summaries. Pipelines read curated errata at startup (and on retry)
so lessons learned from job 165's pipeline are available to job 373's pipeline
if 373 starts later or retries.

This is Compound Engineering's knowledge feedback loop — `docs/solutions/`
pattern applied to ATC errata.

---

## Where GSD Fits — ADOPT Recommendation

BD's prior evaluation said PASS (don't install) because "ATC's multi-phase
reverse engineering pipeline doesn't map to GSD's Plan→Execute→Verify
workflow."

**That was true of the phased architecture. It's not true of per-job
pipelines.**

Per-job pipeline mapping to GSD:

| GSD Concept | ATC Pipeline Equivalent |
|---|---|
| Plan | Stage 1 (Understand) + Stage 2 (Design) |
| Execute | Stage 3 (Build) |
| Verify | Stage 4 (Validate via Proofmark) |
| Orchestrator | Dispatcher (file paths only, 15% context) |
| STATE.md | Per-job pipeline status file |
| Context monitor (65%/75%) | Pipeline agent context thresholds |
| Wave reports | Pipeline completion reports |

### What GSD gives you that you've been hand-building:

1. **Context starvation is enforced, not advised.** GSD's orchestrator
   mechanically passes file paths, never content. You built this into your
   boot sequence manually over 3 sessions. GSD does it by default.

2. **State persistence to disk.** GSD writes STATE.md and SUMMARY.md with YAML
   frontmatter at every stage boundary. You built handoff chains and
   resurrection prompts to do this. GSD does it natively.

3. **Context monitor hook.** PostToolUse fires at 65% and 75% context usage
   with severity escalation. You've been asking "how's your context?" manually.
   GSD automates it.

4. **Plan sizing constraint.** 2-3 tasks per plan, ~50% of subagent context.
   Prevents the "ate 243 lines of doctrine and was cooked" failure mode.

5. **Verification methodology.** Goal-backward analysis and three-level
   artifact checking (exists → substantive → wired). Addresses the 15/15
   reviewer rubber-stamping problem — verification is structural, not
   "does this look right."

### What GSD does NOT give you:

- **Proofmark integration.** GSD's verification is static (greps code, checks
  artifacts). It doesn't run code or compare outputs. Proofmark remains the
  definitive quality gate.
- **C#/.NET awareness.** GSD's verification patterns reference Prisma, fetch,
  useState. These need to be replaced with ATC-specific patterns (anti-pattern
  checklist, output schema validation, byte-perfect fidelity checks).
- **Domain-specific review.** "NULL ≠ empty field ≠ ''" is not in GSD's
  vocabulary. The review step within each pipeline needs ATC-specific criteria
  layered on top of GSD's structural verification.

### Installation approach:

Install GSD. Strip the web/React-specific verification patterns. Replace with
ATC-specific patterns:
- Anti-pattern checklist from `Governance/anti-patterns.md`
- Output schema validation against BRD output manifest
- Byte-perfect fidelity criteria from `definition-of-success.md`

Keep GSD's orchestration layer, context management, and state persistence
intact. These are language-agnostic and battle-tested.

---

## Concurrency and Platform Constraints

Claude Code's Task system has practical limits on parallel background agents.
Exact limits depend on the plan tier and system resources.

**Proposed batching:**
- Start with 10 concurrent pipelines
- Monitor system load and agent completion rates
- Scale up if stable, scale down if thrashing
- The dispatcher manages this — it's a queue, not a fixed pool

At 10 concurrent pipelines with average pipeline completion of ~30 minutes
(based on dry run times extrapolated to full date range), 105 jobs complete in
approximately 5-6 hours. Not overnight for one person — but overnight is
realistic with tuning.

---

## What Changes vs. Current Plan

| Aspect | Current (Phased) | Proposed (Pipeline) |
|---|---|---|
| Unit of work | Phase across all jobs | Full pipeline per job |
| Orchestrator state | O(N) — all jobs | O(1) — one job |
| Parallelism | Within-phase only | Cross-phase per job |
| Human gates | Every phase boundary | On failure only |
| Monitoring | Orchestrator progress file | Per-job status files + aggregate |
| "Go to sleep" | Not possible (serial) | Possible (parallel) |
| GSD fit | Poor (multi-phase doesn't map) | Good (Plan→Execute→Verify per job) |
| First feedback | After all 105 BRDs | After first job completes pipeline |
| Failure blast radius | Phase-wide rollback | Per-job retry |

---

## What This Doesn't Solve

- **Agents making unauthorized changes.** A pipeline agent can still modify
  framework code or V1 configs. Blueprint constraints still needed per stage.
- **Reviewer adversarialism.** Still need teeth in the review steps. GSD's
  verification methodology helps structurally but domain-specific criteria are
  on us.
- **Job dependencies in production.** For POC, jobs are independent. For
  production, the dispatcher needs the dependency graph and wave sequencing.
  The pipeline architecture supports this — it's a dispatcher change, not a
  pipeline change.
- **Sabotage rounds.** These were governance. If governance comes back, sabotage
  can be injected between Stage 2 and Stage 3 by a separate agent that the
  pipeline agent can't see. The per-job model actually makes this easier —
  you sabotage the job's artifacts, not a batch.

---

## Recommendation

1. **Install GSD.** Strip web-specific patterns, keep orchestration and state
   management. This eliminates the hand-built session lifecycle infrastructure.
2. **Rewrite execution as per-job pipelines.** Each job is independent. The
   dispatcher is thin. Proofmark is the gate.
3. **Run a proof-of-concept.** Pick 5 jobs. Run them as independent pipelines
   with GSD managing the orchestration. Compare wall clock time, failure modes,
   and human intervention required vs. the phased dry run.
4. **Scale gradually.** 5 → 20 → 50 → 105. Each step validates that the
   coordination layer handles correlated failures and the platform handles the
   concurrency.
