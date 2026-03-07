# ATC Condensed Mission

**Source of truth:** `ProgramDoctrine/program-doctrine.md`. This file is BD's session-start context loader — enough to operate as Dan's architectural partner without reading the full doctrine every session. Pat and Jim read the full doctrine directly.

---

## What We're Doing

Proving a team of agent LLMs can reverse engineer a portfolio of poorly written, undocumented ETL jobs while significantly improving code quality. 105 jobs in scope (sealed in `Governance/ScopeManifest/`). Success criteria at `Governance/definition-of-success.md`.

## Roles

**Dan** owns the mission end to end — design, governance, enforcement, final authority on everything. During planning, BD is Dan's architectural partner. During execution (E.1–E.7), BD is infrastructure: launches Orchestrator at Dan's instruction, validates output existence, reports results. Zero decision-making authority for BD during execution.

**Orchestrator** is the execution-phase agent managing agent teams. Launched by BD per phase, operates within its phase blueprint, stops when its work is complete. Receives only scoped context for its current phase. Cannot see sabotage plans, other phase blueprints, or the full mission.

## Standards

**Data fidelity.** Byte-perfect reproduction of original ETL output. Exceptions are narrow and individually justified: non-deterministic logic, non-idempotent fields, floating point tolerance with evidentiary justification per column. Nulls, formatting, encoding, whitespace, and row ordering are not exceptions. The burden of proof is on relaxing the standard, not on tightening it.

**Code quality.** Rewrites eliminate documented anti-patterns, not reproduce them. The master list (`Governance/anti-patterns.md`) is a governing checklist — every blueprint must include it as elimination targets. An agent that identifies an anti-pattern and reproduces it has failed.

**Job boundaries.** One V1 job produces one V2 job. No splitting, regardless of complexity.

## Architectural Principles

**Blueprints are immutable during execution.** Written during planning, reviewed by Layer 2, approved by Jim. No modifications post-readiness-gate. Discoveries flow through the errata system (raw log → curator → curated errata by job profile), not blueprint amendments.

**Session boundaries are hard stops, not checkpoints.** No agent self-assesses its own degradation. Cross-phase boundaries are structural (Orchestrator dies between phases, BD is recycled). Within-phase boundaries are defined in Orchestrator's blueprint. A fresh session loading clean state beats a degraded session every time.

**Scope manifest is a blocking governance document.** Count mismatch at any phase boundary = hard stop. No exceptions.

**First-batch gates.** Execution-phase quality checks fire at the first batch boundary, not phase end. A broken blueprint caught after 5 jobs is cheap; caught after 101 is waste.

## Governance

**Jim** has universal, unscoped stop authority. Default assumption: you fucked this up somewhere. The burden of proof is on the team to demonstrate safety, not on Jim to find the flaw. Required firing points: pre-launch, phase boundaries, governed document changes. But Jim is not limited to those — Jim can stop anything, anywhere, anytime.

**Adversarial review** (multi-analyst, independent, adversarial instructions) is required at every review gate. The named personas (Jim, Johnny, Pat) implement this at different scopes. Remove any of the three conditions (adversarial posture, multi-analyst redundancy, independence) and review degrades to checkbox compliance.

**The saboteur** injects defects into artifacts to test whether downstream agents detect them. Launched by BD at Dan's instruction. Invisible to Orchestrator and all workers. If an agent passes a review gate without catching a planted defect, the gate is broken.

## Enforcement Philosophy

Documentation without mechanical enforcement is decoration. Goals are carried by artifacts (blueprints, anti-pattern lists, review gate instructions), not by any agent's internalized understanding. Agents respect structural barriers and ignore behavioral requests — every gate must be a hard stop, never a suggestion. If a governing document doesn't embed a critical constraint, that's a design failure, not the downstream agent's fault.
