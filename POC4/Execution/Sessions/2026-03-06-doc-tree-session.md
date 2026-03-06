# Session Handoff: Doc Tree & Canonical Steps

**Written:** 2026-03-06
**Previous handoff:** `AtcStrategy/POC3/session_handoff.md` (Write Mode Variants)

---

## What We Accomplished

### 1. POC4 Doc Tree — BUILT
Full directory structure for all POC4 artifacts. Five top-level sections:
- `ProgramDoctrine/` — doctrine + condensed mission (moved from BdStartup/)
- `Governance/` — anti-patterns, runbook, canonical steps, doc registry, prerequisites, scope manifest, FMEA, audit trail, doctrine amendments
- `Design/` — blueprints, phase definitions (empty, populated at Step 7 equivalent)
- `Execution/` — sessions, errata, phase output, proofmark
- `Saboteur/` — orchestrator eyes only

### 2. File Moves
- `BdStartup/program-doctrine.md` → `ProgramDoctrine/`
- `BdStartup/condensed-mission.md` → `ProgramDoctrine/`
- `BdStartup/` directory deleted
- `anti-patterns.md` → `Governance/`
- `write-mode-decision.md` → `Governance/Prerequisites/`
- `step4-session-state.md` → `Governance/Prerequisites/`
- `rename-review-report.md` → `Governance/Prerequisites/`
- Updated references in: REBOOT.md, POC3/session_handoff.md, MEMORY.md

### 3. New Files Created
- `Governance/canonical-steps.md` — DRAFT. 18 steps across 5 phases. Reconciles the old roadmap (7 steps) and planning progression (14 steps).
- `Governance/runbook.md` — placeholder
- `Governance/doc-registry.md` — living index with current entries
- `Governance/Prerequisites/readiness-gate.md` — tracks prerequisite completion
- `Saboteur/plans.md` — placeholder

### 4. Canonical Steps — DRAFT WRITTEN, NOT REVIEWED
Dan was sleepy. The draft reconciliation is at `Governance/canonical-steps.md`. It needs Dan's review before we burn the source documents.

**Key design decisions in the draft:**
- 5 phases: Foundation (done), Tooling & Prerequisites, Process Design, Gate, Execution
- Merged evaluation + implementation for Steps 4-5 (reflects what we actually did)
- Scope & Success Criteria placed at Step 8, after Job Config Triage (Step 6) — can't define scope without knowing which jobs survive
- Doc tree marked as Step 9, already complete
- Runbook reframed as Dan's process checklist, not orchestrator's manual
- Phase definitions kept as separate Step 11, distinct from runbook

---

## What To Do Next

### Priority 1: Dan reviews canonical steps draft
Walk through `Governance/canonical-steps.md`. Address the three open questions at the bottom:
1. Scope & Success Criteria timing (iterative?)
2. Governance write-ups for completed Steps 4 and 5
3. Proofmark status and narrative

### Priority 2: Burn old step documents
Once canonical steps are approved:
- Delete or archive `planning-progression.md` (still at POC4 root)
- Delete `memory/poc4-roadmap.md`
- Update MEMORY.md references
- Update doc-registry.md to mark old docs as superseded

### Priority 3: Write governance close-outs for Steps 4 and 5
The evidence exists (write-mode-decision.md, step4-session-state.md, session handoffs) but
needs to be written up as formal prerequisite artifacts in `Governance/Prerequisites/`.
This is where the "cool shit we did" narrative lives — Proofmark cross-validation,
four write modes, 111 tests, weekend-gap discovery.

### Priority 4: Proofmark conversation
Doctrine says "promising, not proven" but we used it to validate the framework. What's its
actual status now? Where does its story get told?

---

## What NOT To Read
- AAR log — reference only
- POC3 governance reviews — historical
- `memory/poc4-roadmap.md` — being superseded (but don't delete yet)

## What To Read
1. **This file**
2. **Canonical steps draft:** `Governance/canonical-steps.md`
3. **Doc registry:** `Governance/doc-registry.md`
4. **Program doctrine:** `ProgramDoctrine/program-doctrine.md` (for governance discussions)
