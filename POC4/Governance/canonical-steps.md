# POC4 Canonical Steps

**Status:** APPROVED
**Created:** 2026-03-06
**Approved:** 2026-03-06 by Dan
**Replaces:** `memory/poc4-roadmap.md` (Steps 1-7) and `planning-progression.md` (14 steps)
**Purpose:** Single source of truth for the POC4 step sequence.

This is a living document. Steps may be modified, reordered, split, or added as we proceed through execution and learn things the planning phase couldn't anticipate. Changes are governed — not frozen, not freewheeling.

---

## Phase I — Foundation (COMPLETE)

These are done. They produced the program doctrine and the planning framework.

| Step | Description | Status | Completed |
|------|-------------|--------|-----------|
| 1 | POC3 Close-Out | ✅ COMPLETE | 2026-03-02 |
| 2 | After-Action Review | ✅ COMPLETE | 2026-03-04 |
| 3 | Planning Progression Definition | ✅ COMPLETE | 2026-03-04 |

**Output:** Program doctrine, condensed mission, anti-pattern list, planning framework.

---

## Phase II — Tooling & Prerequisites

Engineering work. Build, test, validate. Prove the framework is ready.
Governance write-ups for completed steps live in `Governance/Prerequisites/`.

| Step | Description | Status | Depends On |
|------|-------------|--------|------------|
| 4 | Write Mode Decision & Implementation | ✅ COMPLETE | — |
| 5 | Tooling & Framework Changes | ✅ COMPLETE | 4 |
| 6 | Job Config Triage | ✅ COMPLETE | 4 |
| 7 | External Changes & Known Gap Fixes | ✅ COMPLETE | 6 |

### Step 4 — Write Mode Decision & Implementation
Decided on date-partitioned output with Overwrite and Append write modes. Built and validated
all four variants (CSV Overwrite, CSV Append, Parquet Overwrite, Parquet Append). Proofmark
cross-validated CSV vs Parquet parity. 10/10 runs passed STRICT comparison.

Evidence: `Governance/Prerequisites/write-mode-decision.md`
Governance write-up: `Governance/Prerequisites/step4-closeout.md`

### Step 5 — Tooling & Framework Changes
Framework: Writer restructure (date-partitioned paths, etl_effective_date injection, append mode
with prior-partition union), DataFrame.FromParquet(), DataSourcing multi-date (lookbackDays,
mostRecentPrior), DatePartitionHelper extraction, trailer stripping for append mode.
111 tests passing at session end.

Proofmark: Manual validation campaign (23 tests by Dan — 14 CSV, 9 Parquet). Covered order
independence, schema validation, floating point strict/fuzzy, trailer handling, whitespace,
quoting, multi-part Parquet. Two known gaps documented and accepted (CSV quoting dialect,
mixed line breaks). Cross-validated CSV/Parquet parity during Step 4 — 10/10 STRICT pass.

Evidence: `Governance/Prerequisites/step4-session-state.md`, `Governance/Prerequisites/rename-review-report.md`, `AtcStrategy/POC3/proofmark-manual-test-log.md`
Governance write-up: `Governance/Prerequisites/step5-closeout.md`

### Step 6 — Job Config Triage
Starting input: inventory of all V1 jobs currently registered in the database. Which configs
survive the new write mode architecture? Which need rewrite? Do BRDs/FSDs need revision?
Proofmark comparison strategy changes? Output feeds directly into Step 8 (scope definition).

Completed 2026-03-06. Answer: all 105 configs survive, zero breaks, no rewrites needed.
Framework changes (outputTableDirName, effective date required) applied. DansTransactionSpecial
added as multi-output exemplar. Job boundary preservation rule added to doctrine §1.1.
Governance write-up: `Governance/Prerequisites/step6-closeout.md`

### Step 7 — External Changes & Known Gap Fixes
All known fixes that aren't reverse engineering work. Includes:
- T-0/T-N no-data crash: default DataSourcing returns nothing when datalake has no data for
  effective date → Transformation throws "no such table". Dan's rules: no data = no output
  (graceful no-op, not a crash). Already agreed, not yet implemented.
- Any gaps surfaced by Step 6.
- CreditScoreDelta Parquet variants (Overwrite + Append) — low priority completeness items.

This is the doctrine's §3.1 in action: known infrastructure work finishes before POC4 starts.

Completed 2026-03-06. All three items resolved: T-N hard failure implemented (Step 5) with
requirement change (hard fail, not graceful no-op — weekend noise handled via blueprints).
Step 6 gaps fixed (DansTransactionSpecial address dedup + date provenance). Parquet variants
intentionally deleted — test scaffolding no longer needed after Steps 4-5 validation.
Governance write-up: `Governance/Prerequisites/step7-closeout.md`

---

## Phase III — POC4 Process Design

Architectural planning. Define the machine before you turn it on.
Steps within this phase have a default ordering but some can run in parallel.

| Step | Description | Status | Depends On |
|------|-------------|--------|------------|
| 8 | Scope & Success Criteria | ✅ COMPLETE | 6 |
| 9 | Doc Tree & Document Taxonomy | ✅ COMPLETE | — |
| 10 | Job Scope Manifest | ✅ COMPLETE | 6, 8 |
| 11 | Execution Phase Structure & Phase Definitions | ✅ COMPLETE | 8 |
| 12 | Agent Architecture | ⬜ NOT STARTED | 11 |
| 13 | Errata System Design | ⬜ NOT STARTED | 12 |
| 14 | Session Boundary Implementation | ⬜ NOT STARTED | 11, 12 |
| 15 | Named Blueprints (all roles incl. orchestrator) | ⬜ NOT STARTED | 12, 13 |
| 16 | Runbook (Dan's process checklist) | ⬜ NOT STARTED | 11-15 |

### Step 8 — Scope & Success Criteria
What is POC4 proving? How many jobs? What does "done" look like? This depends on Step 6
(config triage) because you can't define scope without knowing which jobs are viable.

Completed 2026-03-06. Scope is defined as "all jobs in the job scope manifest" (Step 10).
Success criteria defined in `Governance/definition-of-success.md` — covers high-level POC
success (100% completion, evidence rollup, executive summary) and per-job reengineering
criteria (BRD, FSD, test execution, external module justification, anti-pattern elimination,
doc chain consistency, Proofmark pass on all effective dates, EXCLUDED/FUZZY governance).

Doctrine: §1.1 (fidelity standard), §1.2 (code quality), §1.3 (human interaction)

### Step 9 — Doc Tree & Document Taxonomy
Directory structure for all POC4 artifacts. Living doc registry at `Governance/doc-registry.md`
tracks every document's creation date, intent, and validity status. Registry reviewed at
every phase boundary.

Completed 2026-03-06. Output: this directory structure + doc-registry.md.

### Step 10 — Job Scope Manifest
The governed list of every job in scope with current status. Blocking governance document —
count mismatch at any phase boundary = hard stop. Lives at `Governance/ScopeManifest/`.

Completed 2026-03-06. Generated from `control.jobs WHERE is_active = true`. 105 jobs sealed
in `Governance/ScopeManifest/job-scope-manifest.json`. This is the amber — the input contract.
The evidence ledger (runtime tracking of per-job/per-output status and proofmark results)
lives in the database and is generated on demand.

Doctrine: §3.3 (scope governance)

### Step 11 — Execution Phase Structure & Phase Definitions
What are the actual reverse engineering execution phases? Phase definitions (reference docs
for "what IS Phase A") live at `Design/PhaseDefinitions/`. This is the structure; the
runbook (Step 16) is the sequence and gates.

Completed 2026-03-06. Seven execution phases defined in `Design/PhaseDefinitions/phase-v-execution.md`:
E.1 (BRD + output manifest), E.2 (FSD + test strategy), E.3 (sabotage round 1), E.4 (build),
E.5 (sabotage round 2), E.6 (validate — 92 effective dates, errata, non-strict column audit),
E.7 (close-out). BD/orchestrator separation formalized. Dan approval + BD recycle at every boundary.

Doctrine: §3.5 (session boundaries), §2.3 (phase gates as hard stops)

### Step 12 — Agent Architecture
How many roles, what topology, what session model? BBC pattern or different?

Doctrine: §3.6 (named blueprints), §3.5 (session boundaries), §2.1 (adversarial review), §2.2 (saboteur)

### Step 13 — Errata System Design
Raw errata log → curator agent → curated errata by job profile. How do execution-time
discoveries propagate to future agents?

Doctrine: §3.6 (errata mechanism)

### Step 14 — Session Boundary Implementation
What makes boundaries hard stops mechanically? Batch sizing? How does Jim's between-boundary
authority get activated without depending on the entity being constrained?

Doctrine: §3.5 (agent session boundaries), §2.3 (phase gates as hard stops)

### Step 15 — Named Blueprints
One blueprint per worker role — complete operating context. Includes orchestrator blueprint.
Reviewed by Layer 2. Immutable post-readiness-gate.

Doctrine: §3.6 (named blueprints), §1.2 (code quality + anti-patterns), §1.4 (enforcement layers)

### Step 16 — Runbook
Dan's process checklist. Evidence trail that the POC followed its own rules. NOT the
orchestrator's operating manual (that's a blueprint). Ties phases, agents, blueprints,
boundaries, and governance together.

Doctrine: §3.4 (Jim's firing points), §3.5 (boundary enforcement), §3.7 (doctrine change management)

---

## Phase III.5 — Dry Run

A controlled, governance-suspended trial run of the full reverse engineering process on a
small batch of jobs (~5). The purpose is to validate that the process design from Phase III
actually works end-to-end before committing to 105 jobs — and before Jim's FMEA locks
everything down.

**Governance is intentionally suspended for this phase.** This is stated explicitly, not
hidden. The scope manifest count check (§3.3), blueprint immutability (§3.6), and all
phase boundary governance are not enforced during the dry run. Dan will approve actions
as they arise. The dry run is a learning exercise, not a governed execution.

**All artifacts are disposable.** The standing plan is to delete everything the dry run
produces and revert to a clean state:
- MockEtlFramework repo: revert to pre-dry-run commit
- Control schema: revert to pre-dry-run state
- Any BRDs, FSDs, test cases, V4 configs, proofmark results: deleted

A save point (git tag + DB dump) must be taken before the dry run begins, using the same
mechanism as the Phase II baseline (`Backups/`).

**The only durable output is the lessons learned.** Everything else gets thrown away. The
lessons learned document captures what worked, what broke, what the blueprints got wrong,
and what Jim needs to know. It feeds directly into Step 17 (FMEA) as evidence.

| Step | Description | Status | Depends On |
|------|-------------|--------|------------|
| X.1 | Dry Run: Save Point & Job Selection | ⬜ NOT STARTED | 16 |
| X.2 | Dry Run: Execute ~5 Jobs End-to-End | ⬜ NOT STARTED | X.1 |
| X.3 | Dry Run: Lessons Learned | ⬜ NOT STARTED | X.2 |
| X.4 | Dry Run: Revert to Save Point | ⬜ NOT STARTED | X.3 |

### Step X.1 — Save Point & Job Selection
Tag repos and dump control schema. Select ~5 representative jobs — pick for variety, not
ease. Should include at least one multi-output job, one with external modules likely needed,
and one straightforward job as a sanity check.

### Step X.2 — Execute ~5 Jobs End-to-End
Run the full reverse engineering process as designed in Phase III: BRD, FSD, test strategy,
test execution, V4 code, proofmark comparison. Use the blueprints as written. Dan approves
as needed. The goal is not to produce perfect output — it's to find out where the process
breaks.

### Step X.3 — Lessons Learned
The only artifact that survives. Document:
- What worked as designed
- What broke and why
- Blueprint gaps or structural problems
- Anything Jim should scrutinize in the FMEA
- Recommended changes to blueprints, phase structure, or runbook

This document goes into the Step 17 FMEA review package alongside the assembled design.

### Step X.4 — Revert to Save Point
Delete all dry run artifacts. Revert MockEtlFramework and control schema to the save point.
Apply lessons learned to Phase III design artifacts (blueprints, phase definitions, runbook)
while they are still mutable. Then proceed to Phase IV.

---

## Phase IV — Gate

Nothing moves until these clear.

| Step | Description | Status | Depends On |
|------|-------------|--------|------------|
| 17 | FMEA / Jim Sign-Off | ⬜ NOT STARTED | all above |
| 18 | Tooling Readiness Gate | ⬜ NOT STARTED | all above |

### Step 17 — FMEA / Jim Sign-Off
Jim reviews the assembled whole. Assumes it's broken until proven otherwise. Pre-launch
scope includes compute/infrastructure capacity assessment.

Doctrine: §3.4 (full Jim section), full doctrine

### Step 18 — Tooling Readiness Gate
All tooling stable. All docs in place. All governance sign-offs recorded. The formal
"POC4 may begin" checkpoint per doctrine §3.1.

Evidence: `Governance/Prerequisites/readiness-gate.md`

---

## Phase V — Execution

The actual POC4. Structure defined by Phase III steps. Not detailed here — that's the
runbook's job.

---

## Resolved Questions

1. **Scope & Success Criteria timing.** RESOLVED. Step 6 starts from a database inventory
   of all V1 jobs. Scope gets defined during triage, not before. Step 8 finalizes success
   criteria after triage output is known. No pre-scoping needed.

2. **Governance write-ups for Steps 1-5.** RESOLVED. Close-out packets written at
   `Governance/Prerequisites/step[1-5]-closeout.md`. All prerequisite steps closed.

3. **Proofmark's status.** RESOLVED. Doctrine amendment 001 updated §2.5 from
   "Promising, Not Proven" to "Accuracy Validated Within Tested Scope, Untested at Scale."
   Amendment at `Governance/Amendments/001-proofmark-status.md`. Jim: CONDITIONAL APPROVE
   (conditions met). Dan: APPROVED 2026-03-06. Doctrine updated.
