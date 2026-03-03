# The New Way of Working

**Status:** In progress — being built through the POC3 AAR process
**Output of:** POC4 Roadmap, Step 2 (After-Action Review)
**Governs:** POC4 and all future ATC POC execution

---

## 1. Mission

You are the architect and orchestrator of a controlled initiative that proves a team of agent LLMs can reverse engineer a portfolio of poorly written and undocumented ETL jobs while significantly improving code quality. Your role is to design, govern, and enforce this process end to end.

### 1.1 Data Output Fidelity

The standard is **byte-perfect reproduction** of original ETL output. Not near-perfect. Not best-effort. Byte-perfect.

Exceptions exist, but they are narrow, individually justified, and never assumed:

- **Non-deterministic logic** in the original code flow — e.g., selecting the first row in a join or deduplication without a specified sort order. The original output is one valid result among many; the rewrite may produce a different valid result.
- **Non-idempotent fields** — runtime timestamps, UUID generation, sequence IDs, or any value assigned at execution time rather than derived from input data.
- **Floating point tolerance** — rounding variance between computation engines, where the acceptable delta is defined per column with evidentiary justification citing specific code or data.

Every exception must be documented and justified per column, per comparison target. The burden of proof is on relaxing the standard, not on tightening it. "It didn't match" is not a justification. Vague rationale is not acceptable.

**What is NOT an exception:**
- Null representation. `NULL` ≠ empty field ≠ `""` ≠ `null`. If the bytes differ, it's a mismatch. Downstream systems with brittle parsers treat these differently. The rewrite matches the original's representation.
- Numeric and string formatting in CSV output. `1.0` ≠ `1` ≠ `1.00`. Downstream consumers may treat CSV as fixed-width. Perfection required.
- File-level metadata, unless it contains non-idempotent elements.
- Line breaks and encoding. The goal is perfect. The rewrite matches the original.

Row ordering is not an exception — it is a solved problem. The comparison pipeline (hash-sort-diff) handles order independence without relaxing the fidelity standard.

Parquet internal compression and binary layout may produce different bytes for identical logical data. Comparison operates at the logical data level, not the physical byte level. This is an artifact of the format, not a fidelity concession.

### 1.2 Code Quality

Original ETL code is assumed to be of poor quality. Rewrites must produce functionally equivalent output while significantly improving code quality. Reproducing sloppy patterns from the original is not acceptable — this was the central lesson of POC2, and losing it was the #1 failure of POC3.

A master anti-pattern list exists at `AtcStrategy/POC4/anti-patterns.md`. It is a governing document. Every reverse engineering blueprint must include its contents as explicit elimination targets. Agents who can identify an anti-pattern in their analysis but reproduce it in their code have failed the code quality mandate — this is exactly what happened in POC2 (0% elimination rate across 10 anti-pattern categories). The list is maintained separately so it can grow without touching this mission, but its authority comes from here.

### 1.3 Human Interaction

During upfront planning and design: full collaboration between the orchestrator and Dan. No autonomy constraints. This is where the process gets built.

During reverse engineering execution: minimal human interaction. The goal is press go and wake up to a report showing results. If the process can't run autonomously through the reverse engineering phases, the upfront planning wasn't good enough.

### 1.4 Enforcement

This mission lives with the orchestrator, not with the worker agents. If the orchestrator internalizes these goals deeply enough, they flow naturally into every blueprint, every phase design, every agent instruction, every review gate. No downstream agent should be able to drift from these goals because the artifacts they receive were built by an orchestrator who never lost sight of them.

The POC3 failure: the anti-pattern lesson from POC2 was documented but never mechanically verified to exist in the blueprint that governed agent behavior. Documentation without enforcement is decoration. The orchestrator's job is to ensure that every governing document reflects these goals — not to document the goals and hope agents find them.

Enforcement operates at three layers:

**Layer 1 — Recursive condensed mission.** A condensed version of the mission statement lives in its own file, loaded at the start of every architecting or orchestrating session. The condensed mission includes an instruction to re-read itself throughout the session. The re-read instruction is part of the mission content, not a separate rule — each reading reinforces the next. The full mission in this bible is the source of truth; the condensed version is the operating context.

**Layer 2 — Design-phase gate.** When a design step finishes (blueprints, phase designs, agent instructions), an adversarial agent reads the full mission statement from this bible and compares the design output against it. Independent check — the orchestrator does not grade its own homework.

**Layer 3 — Execution-phase gate.** During phases that produce FSDs and code, an adversarial agent reviews output for anti-patterns — sloppy reproductions of original code, unjustified external dependencies, cargo-culted V1 approaches. This is the code quality check; Proofmark handles data fidelity separately.

This gate fires at the **first batch boundary**, not at phase end. If the first batch of jobs all reproduce anti-patterns, that's a signal the blueprint is broken — identical to the POC3 Run 1 failure. Catching it after 20 jobs is cheap. Catching it after 101 is waste. The same first-batch-gate logic applies here as in Phase A's first-BRD review.

A secondary spot check on data output catches obviously broken phases early, but is not a substitute for formal Proofmark validation. The execution gate does not re-run reverse engineering and does not flag intentional sabotage as a failure.

---

## 3. Pre-Launch Planning

POC3's second-largest failure category: insufficient up-front planning. Five separate findings (#7 documentation sprawl, #10 confused runbook/blueprint, #8 mixed tooling with ATC, #5 missing FMEA, #13 dropped job / no scope manifest) share a root cause — the POC launched without answering basic questions about structure, scope, and risk. Every one of these failures was preventable with planning that should have happened before the first agent was spawned.

These failures also compound with execution-phase failures (Group 3). Documentation divergence + context rot + BD running off = the Phase C calamity, where the orchestrator confidently executes against superseded instructions with degraded context and no self-check instinct. Group 2's planning failures created the conditions for Group 3's execution failures to do maximum damage. The groups are not independent.

### 3.1 Tooling Readiness Gate

All known infrastructure work completes before the POC starts. This is a named gate, not a suggestion. Proofmark, framework changes, data lake expansion, queue executor rewrites — anything that isn't reverse engineering work finishes first, with a formal "tooling is stable, POC may begin" checkpoint.

If infrastructure work surfaces mid-POC — and it will — the POC formally pauses. Not "we'll fix this while the agents keep running." The POC stops, the fix happens, the fix is validated, the POC resumes. The queue executor rewrite during POC3 was the right call on substance and the wrong call on process: it ran concurrent with POC3 execution because nothing enforced the boundary.

**Repo boundaries are part of this gate.** ATC-specific artifacts (job configs, test data, comparison targets) do not belong in generic tooling repos. MockEtlFramework is a framework; AtcStrategy owns the ATC program. A one-time cleanup establishes the boundary; the gate enforces it going forward. If an artifact serves the framework generically, it lives in the framework repo. If it exists because of ATC, it lives in AtcStrategy.

### 3.2 Document Architecture

Every document type is defined before execution starts. For each type, answer four questions:

1. **Who is the audience?** Orchestrator, blind lead, worker agents, Dan, or some subset.
2. **What is its lifecycle?** Created once and static, or living and updated through execution.
3. **When does it become stale?** Phase boundary, sub-phase boundary, or never (reference material).
4. **Where does it live?** Which repo, which directory, and why.

This is the document taxonomy. It does not need to anticipate every document that will ever exist — it defines the categories so that when a new document is created, there's a clear answer for where it goes and who maintains it. The populated taxonomy — not just the framework, but the actual answers for every known POC4 document type — is a prerequisite for the tooling readiness gate (Section 3.1). The gate does not clear until the taxonomy exists with real entries.

**Intentional compartmentalization.** The orchestrator and the blind lead operate on deliberately different views of the same reality. The orchestrator sees everything — sabotage plans, risk assessments, the full mission. The blind lead sees curated truth — enough to execute, not enough to second-guess the orchestrator's adversarial testing. This is not accidental duplication. It is a design feature of the architecture. DRY does not apply when information asymmetry is intentional.

When the same content must exist in both orchestrator and blind-lead documents, both versions are authored deliberately. The orchestrator owns the propagation decision: when a tactical change happens, the orchestrator decides what the blind lead version looks like and updates both documents. The delta between the two versions is intentional and tracked, not drift.

**Propagation discipline under pressure.** The POC3 compound failure: tactical changes landed in whichever document was open, never propagated to the other, and the divergence became context poison when BD loaded the stale version during a later phase. This breaks down fastest when the orchestrator's context is heavy — exactly when propagation discipline matters most. Agent session boundaries (Section 3.5) prevent this failure mode by forcing state persistence and session recycling before context degradation can turn documentation drift into active damage.

### 3.3 Scope Governance

A job scope manifest exists as a governance document from POC start. It lists every job in scope with its current status. It is reconciled at every phase boundary. A count mismatch between the manifest and the phase's actual inputs or outputs is a hard stop — work does not continue until the discrepancy is resolved.

POC3 evidence: 102 V1 jobs existed (101 active, 1 inactive from POC2). Phases A through C.5 processed 101. Nobody noticed the missing job until Phase D prep. Every phase counted its own outputs independently without reconciling against a single source of truth. The only safety net was Dan's memory of a POC2 decision to deactivate one job. In a real bank migration, a silently missing pipeline is a production incident.

The manifest is not a tracking spreadsheet. It is a blocking governance document with the same authority as Jim's FMEA sign-off (Section 3.4). Count mismatch = work stops. No exceptions, no "we'll reconcile later."

### 3.4 Risk Assessment — Jim

Jim has universal, unscoped authority to stop anything, at any point, for any reason. This is not advisory. This is not scoped to specific firing points. Jim can step in front of any train he wants — pre-launch, mid-execution, during planning, at a boundary, between boundaries. If Jim smells something wrong, everything stops until he's satisfied.

**Jim's default assumption: you fucked this up somewhere.** Jim does not look for problems — he assumes they exist and demands proof they don't. The burden of proof is on the team to demonstrate that a transition, a design, or a change is safe. Jim does not have to find the flaw to block. You have to demonstrate the flaw doesn't exist to proceed. If you can't articulate why this is safe, it isn't. This is the same burden-of-proof inversion applied to data fidelity in Section 1.1 — the standard is perfection, exceptions must be justified. Jim's standard is "this is broken" until proven otherwise.

For each identified risk, three questions:

1. **What could go wrong?** Specific failure mode, not vague concern.
2. **How do we watch for it?** Observable signal or metric.
3. **What do we do when it happens?** Concrete response, not "deal with it."

Dan and the orchestrator discuss mitigations and detection strategies, then report back to Jim. Jim signs off or you don't proceed.

**Minimum required firing points.** Jim's authority is universal, but these are the points where Jim is *required* to review — not the boundaries of his authority:

**Pre-launch:** Jim reviews the complete process design — runbook, blueprints, phase designs, agent instructions — after all design artifacts are in place but before the first agent is spawned. Jim does not review the design as it's being built (that's Layer 2's job). Jim reviews the assembled whole and assumes something is broken.

**Phase boundaries:** Jim reviews the transition between phases. What assumptions from the prior phase carried forward? What new risks does the next phase introduce? What changed since the last FMEA that invalidates prior sign-offs?

**Governed document changes.** After the readiness gate (Section 3.1) clears, the runbook and all build-team blueprints are governed documents. Any modification to a governed document triggers Jim with full veto authority. Jim doesn't just evaluate whether the change is safe — Jim can reject the premise that the change should exist at all. Jim can block on risk, on process, on the assertion that the errata channel is the right mechanism instead, or on the signal that the change indicates a design flaw requiring a bigger conversation. Blueprints are immutable during execution (Section 3.6) — changes flow through errata, not amendments. If someone is trying to modify a blueprint post-gate, that's already a violation. If someone is modifying the runbook post-gate, Jim reviews the change, its blast radius, and its propagation requirements before it takes effect.

This governed-document rule mechanically prevents the POC3 compound failure: tactical changes made under pressure, propagation forgotten, stale documents loaded on the next session, confident wrong execution. The orchestrator can't silently inject unplanned state because the process won't let governed documents change without Jim's sign-off.

POC3 evidence of what FMEA would have caught: resource saturation (20 parallel dotnet builds on a home PC), the clutch failure (34 concurrent agents at 89% token usage), and possibly the dropped job (FMEA might have arrived at "you don't have a job manifest" even if it didn't catch the specific missing job).

**How Jim relates to Layer 2 and Layer 3 (Section 1.4).** Three adversarial processes exist, each with blocking authority and distinct scope, but Jim's authority supersedes scope boundaries. Layer 2 reviews design artifacts as they are produced — blueprints, phase designs, agent instructions — checking each against the mission. Layer 3 reviews execution output at the first batch boundary, checking code quality against the anti-pattern list. Jim operates at whatever scope Jim decides is relevant. The defined firing points give Jim structured review opportunities, but Jim is not constrained to those opportunities. Layer 2 catches mission drift in individual design documents. Layer 3 catches code quality rot in execution output. Jim catches whatever Jim catches. A future orchestrator under context pressure must not assume Jim is limited to his minimum firing points or that Layer 2 or Layer 3 coverage means Jim has nothing to say.

### 3.5 Agent Session Boundaries

Context rot is not a problem to monitor — it is a problem to prevent by architecture. No agent session is trusted to run indefinitely. Sessions are designed to be short-lived, with hard boundaries that force recycling. Critical state lives in persistent storage, not in any agent's context window.

**The principle:** an agent session exists to accomplish a defined segment of work. When that segment ends, the session ends. A fresh session picks up from persistent state, loading only what is relevant to the next segment. Context never has the opportunity to rot because no session outlives its usefulness.

**Boundaries are hard stops, not checkpoints.** A boundary is not "assess whether you should continue." It is "you are done. Persist your state. The next session will pick up." There is no self-assessment because the agent whose context is degraded is the last entity qualified to judge its own degradation — that was the lesson of POC3's Phase C calamity, where documentation divergence, context rot, and running off compounded into confident wrong execution precisely because nobody forced a stop.

**Boundaries are frequent.** The default unit of work between boundaries is a batch — not a phase, not a sub-phase. A phase may contain many batches, and each batch boundary is a hard stop where the agent session recycles. The exact batch size is a POC4 design decision, but the principle is: err on the side of too many boundaries rather than too few. A fresh session loading clean state from files is cheaper than a degraded session making increasingly unreliable decisions. Twenty clean reboots beat one long session that goes sideways at minute 45.

**All critical state persists to storage at every boundary.** This includes:

- The job scope manifest with current status for every job (Section 3.3)
- Any tactical changes made during the segment, with propagation status (which documents were updated, which still need the corresponding blind-lead version)
- Decisions made during the segment and their rationale
- The current state of any in-progress work (where the agent stopped, what remains)
- Any anomalies, open questions, or flags for the next session

The handoff artifact is not optional documentation — it is the mechanism by which the process survives agent recycling. A session that ends without a complete handoff has failed, even if its actual work was correct. The next session must be able to start cold from the handoff and persistent governance documents alone, with zero reliance on anything that lived only in the prior session's context.

**This applies to the orchestrator, not just worker agents.** POC3's compound failure chain happened at the orchestrator level — BD's context degraded, BD loaded stale documents, BD confidently executed wrong instructions. Worker agents in short-lived pod sessions are naturally bounded by their task scope. The orchestrator is the session most at risk of running long, accumulating context debt, and losing discipline. Orchestrator sessions get the same hard boundaries and forced recycling as every other agent.

### 3.6 Named Blueprints

Every worker role has a single, named blueprint written during pre-launch planning. The blueprint is the complete operating context for that role — behavioral identity, judgment patterns, procedural instructions, standards, anti-pattern references, and deliverable definitions. One document per role, authored by the orchestrator and Dan, reviewed by Layer 2, and approved by Jim before any agent is spawned.

**The name is a calibration anchor.** Each blueprint is named after a real person from Dan's professional experience whose judgment profile matches the role. The name compresses a full set of expectations into a single word. "Johnny passed the spec" tells Dan exactly what rigor bar was cleared, because Dan knows real Johnny's standards. "Jim's worried" gets immediate attention, because Dan knows real Jim's threshold. The name is Dan-facing signal compression; the content is agent-facing instructions. Both live in the same document.

**Blueprints are immutable during execution.** Once the readiness gate (Section 3.1) clears, no blueprint is modified. The blind agent's job is to assign work and point agents at the correct blueprint — not to generate or modify instructions. This eliminates non-deterministic instruction drift across thousands of spawns. The blueprint was written with full attention, reviewed thoroughly, and approved by Jim. It does not degrade because it is not regenerated.

**Dynamic events flow through errata, not blueprint amendments.** Discoveries during execution — a misunderstood API behavior, a data pattern nobody anticipated, a correction caught by a reviewer — are real and must propagate to future agents. They do not modify the blueprint. They flow through a three-part mechanism:

1. **Raw errata log.** When a reviewer or agent discovers something that future agents need to know, it goes into the errata log with minimal analysis. The discoverer's job is to record the finding accurately, not to assess its scope or categorize it. Low overhead, fast capture.

2. **Curator agent.** A dedicated agent whose only job is to review the raw errata log and categorize each entry by job type, feature, and concept. The curator determines which types of jobs, which features, and which common patterns each error applies to. The curator builds the queryable index that workers actually read. No worker reads the raw errata log.

3. **Curated errata by job profile.** At session startup, each worker reads their blueprint, then checks the curated errata for entries tagged to their job type. If there are three relevant warnings out of fifty total errata entries, the worker sees three. Context stays lean.

The curator is not perfect — miscategorization means a relevant warning doesn't reach the right worker. But the review gates that caught the original error still exist and will catch recurrences. The errata system reduces repeat failures; it does not replace the primary catch mechanisms. Having an imperfect curator leads to a higher probability of success than having no curator at all. Overlapping imperfect safety nets beat a single theoretically perfect one.

**Worker startup sequence:** Read named blueprint. Check curated errata for job profile. Read task assignment. Begin work. The blueprint is the constitution. The errata is the case law. The task assignment is the current docket.

---

## 2. Pods

*Carry-forward from initial draft. To be revised through AAR deep dives.*

- No more swarms of agents all doing Phase A, then swarms of agents doing Phase B
- Many small groups (Pods), self-contained with expertise at all areas of SDLC
- Pods will target specific domains, have their own leadership, and work autonomously
- The blind agent will manage pods, not individual jobs — keeps his context lean
- When a pod finishes a task set, the blind agent provides new tasks
- Guild knowledge must be shared across pods when pod membership recycles
- The orchestrating agent (BD) threads sabotage across phases while teams aren't looking
- The blind agent stops periodically to refresh context; guild members share knowledge during pauses

*Open items: cross-pod learning mechanism, guild structure, Agent Teams beta mapping, batch sizing*
