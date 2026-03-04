# POC4 Planning Progression

**Created:** 2026-03-04
**Output of:** Step 2.5 — Define planning steps and create step-specific doctrine slices
**Status:** Sequence defined. Doctrine slices not yet created.

---

## Purpose

The program doctrine is the governing document, but it's too large to sit in every agent's context.
This file defines the sequential planning steps from "start POC4 pre-work" to "press the button."
Each step gets a doctrine slice — the minimum subset of the full doctrine relevant to that step's work.

**Governance always uses the full doctrine.** Jim, Pat, and Layer 2/3 reviews never see the sliced
versions. The slices are for the working sessions, not the review sessions.

---

## The Sequence

### 1. Scope & Success Criteria
**Depends on:** nothing
**Doctrine sections:** 1.1 (fidelity standard), 1.2 (code quality), 1.3 (human interaction)
**Question:** What is POC4 proving? How many jobs? What does "done" look like?

### 2. Write Mode Decision
**Depends on:** nothing (scope frames it, but not a hard dependency)
**Doctrine sections:** 1.1 (fidelity standard — what counts as byte-perfect when output structure changes)
**Question:** Curated output data architecture. Overwrite vs append vs partitioned vs something else.

### 3. Framework Changes Evaluation
**Depends on:** 2
**Doctrine sections:** 3.1 (tooling readiness gate)
**Question:** What does the write mode decision require from MockEtlFramework?

### 4. Existing Job Config Triage
**Depends on:** 2
**Doctrine sections:** 3.1 (tooling readiness gate), 1.1 (fidelity standard)
**Question:** Which V1 configs survive the write mode decision? Which need rewrite? BRD/FSD revision needed?

### 5. Job Scope Manifest
**Depends on:** 1, 4
**Doctrine sections:** 3.3 (scope governance)
**Question:** The governed list of every job in scope with current status.

### 6. Execution Phase Structure
**Depends on:** 1, 2
**Doctrine sections:** 3.5 (session boundaries), 2.3 (phase gates as hard stops)
**Question:** What are the actual reverse engineering execution phases?

### 7. Agent Architecture
**Depends on:** 6
**Doctrine sections:** 3.6 (named blueprints — worker roles), 3.5 (session boundaries), 2.1 (adversarial review), 2.2 (saboteur)
**Question:** How many roles, what topology, what session model?

### 8. Document Taxonomy
**Depends on:** 6, 7
**Doctrine sections:** 3.2 (document architecture)
**Question:** Every document type — audience, lifecycle, staleness, location. Real entries, not framework.

### 9. Errata System Design
**Depends on:** 7
**Doctrine sections:** 3.6 (errata mechanism — raw log, curator, curated by job profile)
**Question:** How do execution-time discoveries propagate to future agents?

### 10. Session Boundary Implementation
**Depends on:** 6, 7
**Doctrine sections:** 3.5 (agent session boundaries), 2.3 (phase gates as hard stops)
**Question:** What makes boundaries hard stops mechanically? Batch sizing?

### 11. Named Blueprints
**Depends on:** 7, 8
**Doctrine sections:** 3.6 (named blueprints), 1.2 (code quality + anti-patterns reference), 1.4 (enforcement layers)
**Question:** One blueprint per worker role — complete operating context, reviewed by Layer 2.

### 12. Runbook
**Depends on:** 6, 7, 8, 9, 10, 11
**Doctrine sections:** 3.4 (Jim's firing points), 3.5 (boundary enforcement), 3.7 (doctrine change management)
**Question:** The operational manual tying phases, agents, blueprints, boundaries, and governance together.

### 13. FMEA / Jim Sign-Off
**Depends on:** all above
**Doctrine sections:** 3.4 (full Jim section), full doctrine (Jim reviews the assembled whole)
**Question:** Jim reviews everything. Assumes it's broken until proven otherwise.

### 14. Tooling Readiness Gate
**Depends on:** all above
**Doctrine sections:** 3.1 (tooling readiness gate), full doctrine
**Question:** All tooling stable. All docs in place. Press the button.

---

## Notes

- **Framework changes implementation** (actual coding work) can start after Step 3 and run parallel
  with Steps 6–12. Must complete before Step 14. Not a numbered step because it's execution, not
  a planning conversation — but it's a prerequisite for the gate.
- **Config fixes** same deal — triage is Step 4, fixes happen as implementation work before Step 14.
- **Doctrine slices** for each step have not been created yet. The "Doctrine sections" listed above
  are the initial mapping. Slices get written as we approach each step.
- **Coverage vs. old roadmap Steps 3–7:** Not yet formally reconciled. Old Step 6 ("Make Changes
  Outside POC4") is implementation work captured in the notes above, not a numbered planning step.
  Reconciliation happens when we verify full coverage.
