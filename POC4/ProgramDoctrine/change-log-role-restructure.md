# Doctrine Role Restructure — Change Log

**Date:** 2026-03-06
**Authorized by:** Dan
**Reason:** BD is no longer the orchestrator during execution phases. The role model has been fundamentally restructured.

## Role Definitions

| Name | Role | Description |
|---|---|---|
| **Dan** | Human authority | Owns the mission end to end. Directs BD to launch phases. Makes all cross-phase decisions. Carries the mission. Engages Jim/Pat directly. Has final authority on everything. |
| **Orchestrator** | Background execution agent | Launched by BD for each execution phase. Manages agent teams — spawns workers, assigns tasks, manages batch progression. Operates within its phase blueprint. Stops when phase work is complete. Replaces the old "blind lead" concept but is not blind — receives scoped context appropriate to its phase. |
| **BD** | Infrastructure / launcher | During pre-execution planning (Steps 1–16): Dan's architectural partner. During execution (E.1–E.7): launches Orchestrator, validates output existence, reports results. Zero decision-making authority during execution. |

**Note:** During the editing process (2026-03-06), placeholder names `Dan` and `Orchestrator` were used for traceability. Final names (`Dan`, `Orchestrator`) applied 2026-03-07 after Pat validated the restructure.

---

## Changes by Section

### Header
- Added role model revision note with pointer to this change log.

### Section 1 — Mission (opening paragraph)
- **Was:** Second-person address to BD as "the architect and orchestrator." Single actor owning the entire process.
- **Now:** Third-person description of the initiative. Dan owns the mission. BD is architectural partner during planning, infrastructure during execution. Orchestrator is defined as the execution-phase agent managing teams.
- **Why:** BD no longer holds the orchestrator role during execution. The mission owner is Dan.

### Section 1.1 — Data Output Fidelity
- No changes. No role references in this section.

### Section 1.2 — Code Quality
- Added a blanket caveat note after the first POC3 reference: POC2/POC3 references throughout describe failures under the previous role model. Lessons remain valid; role assignments have changed.
- **Why:** Dan's instruction to caveat changelog-type / historical references as using old role definitions.

### Section 1.3 — Human Interaction
- **Was:** Framed as collaboration "between the orchestrator and Dan" during planning. Execution model assumed the AI orchestrator (BD) running autonomously. Resource constraint and #2 failure mode paragraphs addressed BD's specific vulnerabilities.
- **Now:** Planning = Dan and BD as architectural partners. Execution = Dan instructs BD to launch Orchestrator; Orchestrator runs autonomously. Resource constraint risk reframed to Dan (budget-driven shortcuts like skipping Jim review). #2 failure mode declared structurally eliminated during execution — Orchestrator has no human interaction, BD has no decision authority.
- **Why:** The entire section was written to a specific failure mode (BD getting momentum-overridden in conversation). That failure mode cannot manifest in the new architecture.

### Section 1.4 — Enforcement
- **Was:** "This mission lives with the orchestrator" (BD). Layer 1 was recursive condensed mission for BD's long-running session.
- **Now:** Mission lives with Dan. Layer 1 reframed: Dan ensures BD loads condensed mission during planning; Orchestrator gets mission elements in its blueprint. Layer 2/3 substance unchanged but actor references updated. "The orchestrator does not grade its own homework" → "the designers do not grade their own homework."
- **Why:** Mission ownership moved from AI agent to human. Enforcement layers still needed but the actor carrying them changed.

### Section 2 — Sustain (header)
- Added blanket caveat note: POC3 operated under previous role model. Sustain items describe patterns that worked regardless of role. Structural patterns preserved; role references updated.
- "A future orchestrator implementing new processes" → "Any proposed change" (removed actor-specific reference).

### Section 2.1 — Adversarial Review
- No substantive changes. No role references requiring update.

### Section 2.2 — The Saboteur
- **Was:** "threaded by the orchestrator, invisible to the agents being tested."
- **Now:** "launched by BD at Dan's instruction (see E.3, E.5), operates independently, invisible to Orchestrator and all worker agents."
- **Why:** Saboteur is no longer threaded by an AI orchestrator session. It's a discrete phase launched by BD per the phase execution plan.

### Section 2.3 — Phase Gates
- Added caveat: failures described (clutch, #2, context rot) occurred "under the previous role model."
- Removed specific reference to "Section 3.5 (session boundaries as hard stops, not checkpoints)" — simplified to just "Section 3.5 (session boundaries as hard stops)."
- **Why:** Historical accuracy. The evidence is real but the actor context has changed.

### Section 2.4 — BRD Review Quality
- No changes. No role references.

### Section 2.5 — Proofmark
- No changes. No role references.

### Section 3 — Pre-Launch Planning (header)
- Updated compound failure description: "the orchestrator confidently executed" → "the AI orchestrator" with caveat "under the previous role model."
- Changed "BD running off" to generic phrasing since BD is no longer the actor who ran off in the new model.

### Section 3.1 — Tooling Readiness Gate
- No changes. No role references requiring update.

### Section 3.2 — Document Architecture
- **Was:** Audience list included "Orchestrator, blind lead, worker agents, Dan." Intentional compartmentalization described dual-document maintenance between orchestrator and blind lead. Propagation discipline section described the compound failure of parallel document versions diverging.
- **Now:** Audience list updated to "Orchestrator, worker agents, Dan, review personas." Compartmentalization reframed: Dan sees everything, Orchestrator sees only its phase blueprint and assignments. Dual-document maintenance problem declared eliminated — Dan maintains single sources of truth, Orchestrator receives curated views, no parallel versions exist to diverge.
- **Why:** The entire compartmentalization model was designed for two AI actors with different information access. Now it's one human (full access) and one bounded agent (scoped access). The propagation failure that killed POC3 is structurally impossible.

### Section 3.3 — Scope Governance
- No substantive changes. No role references requiring update.

### Section 3.4 — Risk Assessment (Jim)
- **Was:** "Dan and the orchestrator discuss mitigations." "The orchestrator can't silently inject unplanned state." "A future orchestrator under context pressure..."
- **Now:** "Dan and BD (during planning) discuss mitigations." Added: "During execution, Dan engages Jim directly." Governed-document rule: changed from orchestrator-specific to role-neutral ("regardless of who is requesting the change"). Removed actor-specific "future orchestrator" warning — made the principle general.
- **Why:** Jim's authority is unchanged. Only the actors Jim interacts with changed.

### Section 3.5 — Agent Session Boundaries
- **Was:** Long section primarily about orchestrator (BD) context rot, with the key message that orchestrator sessions need the same hard boundaries as worker sessions. Between-boundary enforcement left to runbook/blueprint design.
- **Now:** Split into cross-phase and within-phase boundaries. Cross-phase boundaries are structurally enforced by the architecture (Orchestrator dies between phases, BD is recycled). Within-phase boundaries are Orchestrator's responsibility per its blueprint. Added explicit acknowledgment that Orchestrator is not exempt from within-phase context rot (E.6 in particular). Removed self-assessment language specific to BD. Removed the paragraph about "this applies to the orchestrator, not just worker agents" — replaced with structural enforcement description.
- **Why:** The #1 concern of this section — orchestrator context rot — is solved at the cross-phase level by architecture. Within-phase rot remains a real concern for Orchestrator during complex phases and is addressed by blueprint-defined internal boundaries.

### Section 3.6 — Named Blueprints
- **Was:** "blind lead" throughout. "The blind agent's job is to assign work." Blueprint jailing scoped to blind lead. Single blueprint assumption.
- **Now:** "Orchestrator" throughout. Orchestrator assigns work and points agents at blueprints. Blueprint jailing preserved but reframed for Orchestrator. Added: Orchestrator may have multiple blueprints across phases (E.1 vs E.6 are very different). Added: blueprint-per-phase decision made during pre-launch planning. Opening updated to include Orchestrator alongside worker roles. Authorship updated to "Dan and BD during planning."
- **Why:** Direct actor rename. The jailing principle is identical — only the name of the jailed agent changed. Multiple blueprint possibility reflects Dan's stated intent.

### Section 3.7 — Doctrine Change Management
- **Was:** "The orchestrator, Jim, and Pat" at phase boundary review. "Dan has final authority" (already correct).
- **Now:** "Dan, Jim, and Pat." Observation sources updated to include BD explicitly. "Dan" → "Dan" for consistency.
- **Why:** Actor rename. Substance unchanged.

### Section 4 — Enterprise Deployment
- No changes. No role references.

---

## Changes to Other Documents

### canonical-steps.md
- Step 15: "all roles incl. orchestrator" → "all roles incl. Orchestrator"
- Step 11 description: "BD/orchestrator separation formalized" → updated to describe Dan → BD → Orchestrator operating model
- Step 15 description: "Includes orchestrator blueprint" → "Orchestrator may have different blueprints per execution phase"
- Step 16 description: "NOT the orchestrator's operating manual" → "NOT Orchestrator's operating manual"; "Dan's process checklist" → "Dan's process checklist"

### doc-registry.md
- Saboteur Plans intent: "Orchestrator-only mutation plans" → "Dan-only mutation plans — Orchestrator and all worker agents barred"
- Condensed Mission intent: updated to reflect BD loads during planning, Orchestrator gets mission via blueprint
- Added entry for this change log

### runbook.md
- Owner: "Dan" → "Dan"
- Purpose: updated to reference Dan
- "NOT the orchestrator's operating manual. The orchestrator gets a named blueprint" → "NOT Orchestrator's operating manual. Orchestrator gets a named blueprint"

### condensed-mission.md
- Full rewrite. Was second-person address to BD as "the architect and orchestrator." Now describes mission ownership (Dan), BD's dual role (architect in planning, infrastructure in execution), and enforcement via artifacts.

### Saboteur/plans.md
- "ORCHESTRATOR EYES ONLY" → "DAN EYES ONLY"
- "The blind lead never sees this directory" → "Orchestrator and all worker agents are barred from this directory"

### phase-v-execution.md
- All "orchestrator" → "Orchestrator" throughout
- All "Dan" → "Dan" where referring to the human authority role
- Operating model section reworded to use new role names
- Added role model note in header pointing to this change log

### definition-of-success.md
- Reviewed, no changes needed. Bare "Dan" refers to Dan as executive sponsor, not as a role reference.

### Session handoffs (historical — caveated, not rewritten)
- 2026-03-06-step8-10-11-session.md: Added caveat note about role terminology. Updated BD/orchestrator line to new role names.
- 2026-03-06-doc-tree-session.md: "orchestrator eyes only" → "Dan eyes only"
