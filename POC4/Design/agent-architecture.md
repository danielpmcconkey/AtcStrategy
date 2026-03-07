# Agent Architecture — Step 12

**Status:** DRAFT
**Created:** 2026-03-07
**Depends on:** Step 11 (Execution Phase Structure)
**Feeds into:** Steps 13 (Errata), 14 (Session Boundaries), 15 (Blueprints), 16 (Runbook)

---

## Roles

### Layer 0 — Dan

Final authority. Approves phase boundaries. Checks token usage. Recycles BD.
Makes all judgment calls (sabotage plausibility, pull-the-plug, success determination).

### Layer 1 — BD

Infrastructure layer. Zero decision-making authority during execution.

Responsibilities:
- Launches Orchestrator in background at Dan's instruction (one fresh instance per phase)
- Validates existence of all required outputs when Orchestrator reports completion
- Reports phase results to Dan
- Launches Saboteur directly (E.3, E.5) — never through Orchestrator
- Launches Pat directly (post-E.6) — never through Orchestrator

BD does NOT:
- Make architectural or quality decisions
- Override Orchestrator
- Interact with workers directly

### Layer 2 — Orchestrator

One fresh instance per execution phase. Receives only its phase's blueprint.
Cannot see sabotage plans, other phase blueprints, or the full mission doctrine.

Responsibilities:
- Starts and stops workers and reviewers
- Assigns jobs to workers
- Enforces first-batch gates (quality checks after first batch, not phase end)
- Manages batch sizing and concurrency (cap: 10 concurrent agents)
- Reports completion to BD when all phase work is done

Orchestrator does NOT:
- Survive phase boundaries (dies at phase end)
- Self-assess its own degradation
- Communicate with Saboteur, Pat, or other Orchestrator instances

### Layer 3 — Workers

Generic agent role with phase-specific instructions. Each worker receives the
Orchestrator's assignment (specific jobs) and the relevant context for its task.

| Variant | Phase | Input | Output |
|---------|-------|-------|--------|
| Analyst | E.1 | V1 code, job configs, V1 output | BRDs + output manifests |
| Architect | E.2 | BRDs | FSDs + test strategy/cases |
| Builder | E.4 | FSDs, test cases | V4 code + unit tests |
| Triage | E.6 | V1/V4 output, Proofmark results, curated errata | Fixes + errata log entries |

Workers do NOT:
- Review their own output (independence requirement)
- See other workers' assignments
- Access the sabotage directory

### Layer 3 — Reviewers

Independent from writers. Cannot be the same agent instance that produced the
artifact being reviewed. Receives the artifact, the source material it claims
to reference, and phase-specific review criteria.

Review passes per phase:
- **E.1:** (1) Output accuracy / output manifest correctness, (2) Requirement accuracy / evidence support
- **E.2:** (1) FSD accuracy (BRD coverage, evidence, schema match, AP avoidance), (2) Test accuracy (BRD coverage, evidence)
- **E.4:** (1) Unit test coverage, (2) Anti-pattern elimination, (3) Smoke test appropriateness

**Multi-analyst requirement (doctrine §2.1):** The governed run requires 2+
independent reviewers at each gate. For the dry run, single reviewer per
artifact is acceptable (governance suspended).

### Standalone — Saboteur

Launched by BD, not Orchestrator. Completely isolated context — cannot see
Orchestrator blueprints, worker output beyond what it needs to plant defects,
or other standalone agents.

- **E.3:** Plants plausible errors in BRDs, propagates through FSDs and test docs
- **E.5:** Plants plausible errors in V4 code only (not docs)
- Documents all sabotage in a restricted directory barred from all other agents

### Standalone — Errata Curator

Launched by Orchestrator during E.6 at defined trigger points (after each
effective date's triage completes). Reads raw errata log, produces curated
summaries organized by job profile and common issue patterns. Workers read
curated errata, never the raw log.

### Standalone — Pat

Launched by BD after E.6 Orchestrator completes. Audits ALL evidence
accumulated across E.1-E.6. Adversarial posture — assumes the process
cut corners until proven otherwise.

---

## Topology

```
Dan
 └── BD
      ├── Orchestrator (E.1) ── Analysts + Reviewers
      ├── Orchestrator (E.2) ── Architects + Reviewers
      ├── Saboteur (E.3)
      ├── Orchestrator (E.4) ── Builders + Reviewers
      ├── Saboteur (E.5)
      ├── Orchestrator (E.6) ── Triage Workers + Errata Curator
      ├── Pat (post-E.6 audit)
      └── Orchestrator (E.7) ── Summary agent
```

---

## Session Model

**Phase boundaries are hard stops:**
1. Orchestrator stops and reports completion to BD
2. BD validates existence of all required outputs
3. Dan manually approves
4. Dan checks token usage
5. Dan recycles BD (fresh session, clean context)

**Within-phase:**
- Workers are subagents: spawn, receive assignment, do work, return results, die
- Orchestrator manages all worker lifecycle
- Batch sizing: Orchestrator processes jobs in configurable batches
- Concurrency cap: 10 simultaneous agents (POC3 lesson — 34 concurrent agents bricked the machine)
- First-batch gate: quality checks fire after batch 1, not phase end

**Cross-phase state:**
- Artifacts on disk are the only persistent memory between phases
- No agent carries context across a phase boundary
- BD's recycled session loads clean context from MEMORY.md + phase definitions

---

## Dry Run Simplifications

For Phase III.5 (~5 jobs, governance suspended):

- **Single reviewer** per artifact (skip multi-analyst redundancy)
- **Single batch** per phase (5 jobs = no batching needed)
- **No formal batch boundary checkpoints** within phases
- **No Jim stop authority mechanics** (governance suspended)
- **Errata curator may be skipped** if 5 jobs don't generate enough errata to warrant curation
- **Sabotage rounds may be skipped or reduced** (1-2 jobs instead of 10) at Dan's discretion
