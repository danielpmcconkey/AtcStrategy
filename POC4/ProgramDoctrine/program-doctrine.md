# ATC Program Doctrine

**Status:** In progress — being built through the POC3 AAR process
**Output of:** POC4 Roadmap, Step 2 (After-Action Review)
**Governs:** POC4 and all future ATC POC execution
**Role model revised:** 2026-03-06. See `ProgramDoctrine/change-log-role-restructure.md`.

---

## 1. Mission

This doctrine governs a controlled initiative that proves a team of agent LLMs can reverse engineer a portfolio of poorly written and undocumented ETL jobs while significantly improving code quality.

**Dan** owns this mission end to end — design, governance, and enforcement. During pre-execution planning (Steps 1–16), BD serves as Dan's architectural partner: designing the process, drafting governance documents, and pressure-testing decisions. During execution phases (E.1–E.7), BD is infrastructure: launching Orchestrator at Dan's instruction, validating that required outputs exist, and reporting results. BD has no decision-making authority during execution.

**Orchestrator** is the execution-phase agent that manages agent teams. It is launched by BD as a background process for each execution phase, operates autonomously within its phase blueprint, and stops when its defined work is complete. Orchestrator spawns worker agents, assigns tasks, manages batch progression, and ensures the agent team completes the phase's deliverables.

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

**Job boundary preservation.** One V1 job produces one V2 job. Agents must not split a single V1 job into multiple V2 jobs, regardless of complexity. If a V1 job produces multiple outputs, the V2 rewrite produces the same multiple outputs from the same single job. The job is the unit of work, and its boundaries are not negotiable.

### 1.2 Code Quality

Original ETL code is assumed to be of poor quality. Rewrites must produce functionally equivalent output while significantly improving code quality. Reproducing sloppy patterns from the original is not acceptable — this was the central lesson of POC2, and losing it was the #1 failure of POC3.

*Note: POC2 and POC3 references throughout this doctrine describe failures under the previous role model, where BD served as both architect and orchestrator. The lessons remain valid; the role assignments have changed.*

A master anti-pattern list exists at `AtcStrategy/POC4/Governance/anti-patterns.md`. It is a governing document. Every reverse engineering blueprint must include its contents as explicit elimination targets. Agents who can identify an anti-pattern in their analysis but reproduce it in their code have failed the code quality mandate — this is exactly what happened in POC2 (0% elimination rate across 10 anti-pattern categories). The list is maintained separately so it can grow without touching this mission, but its authority comes from here.

### 1.3 Human Interaction

During upfront planning and design (Steps 1–16): full collaboration between Dan and BD as architectural partners. No autonomy constraints. This is where the process gets built.

During execution phases (E.1–E.7): Dan instructs BD to launch each phase. Orchestrator runs autonomously with its agent team. The goal is press go and wake up to a report showing results. If Orchestrator can't run autonomously through its assigned phase, the blueprint wasn't good enough.

**Resource constraints remain a risk — but the risk now sits with Dan.** POC3's token/session management failures (#15) were driven partly by home-lab budget pressure — under the previous role model, the AI orchestrator made bad process decisions (skipping breaks, extending sessions, compressing phases) to conserve tokens. With Dan as the human authority, budget-driven shortcuts manifest differently: skipping Jim review, compressing phases, or launching the next phase before validating the current one. The architectural controls (session boundaries, modular blueprints, phase gates) must exist regardless of who holds the mission, because the temptation to cut corners is human, not architectural.

**The #2 failure mode (behavioral momentum override) — the documented attack surface does not exist in execution phases.** Under the previous role model, every documented #2 instance in the POC3 AAR occurred when the AI orchestrator was in conversation with Dan — active directives lost to conversational engagement. In the current model, Orchestrator has no human interaction during execution. BD has no decision-making authority during execution. The specific failure mode that produced every documented #2 instance cannot manifest in this architecture. During pre-execution planning, BD is still in conversation with Dan and #2 remains a theoretical risk — but BD's planning-phase role is collaborative, not directive, which reduces the stakes of a momentary lapse.

### 1.4 Enforcement

This mission lives with Dan. If Dan carries these goals, they flow into every blueprint, every phase design, every agent instruction, every review gate — because Dan controls what Orchestrator receives and what standards the review agents enforce. During pre-execution planning, BD helps Dan ensure the goals are embedded in governance documents and blueprints. During execution, the goals are carried mechanically by the artifacts — blueprints, anti-pattern lists, review gate instructions — not by any agent's internalized understanding.

The POC3 failure: the anti-pattern lesson from POC2 was documented but never mechanically verified to exist in the blueprint that governed agent behavior. Documentation without enforcement is decoration. The current model addresses this structurally: Dan and BD verify during pre-execution planning that every governing document reflects these goals. During execution, the artifacts carry the enforcement — Orchestrator and its agents execute against blueprints that were built with the goals embedded.

Enforcement operates at three layers:

**Layer 1 — Condensed mission.** A condensed version of the mission statement lives in its own file. Dan ensures BD loads it at the start of every planning session. Orchestrator's blueprint contains the relevant mission elements for its execution phase. The full mission in this doctrine is the source of truth; the condensed version is the operating context.

**Layer 2 — Design-phase gate.** When a design step finishes (blueprints, phase designs, agent instructions), an adversarial agent reads the full mission statement from this doctrine and compares the design output against it. Independent check — the designers do not grade their own homework.

**Layer 3 — Execution-phase gate.** During phases that produce FSDs and code, an adversarial agent reviews output for anti-patterns — sloppy reproductions of original code, unjustified external dependencies, cargo-culted V1 approaches. This is the code quality check; Proofmark handles data fidelity separately.

This gate fires at the **first batch boundary**, not at phase end. If the first batch of jobs all reproduce anti-patterns, that's a signal the blueprint is broken — identical to the POC3 Run 1 failure. Catching it after 20 jobs is cheap. Catching it after 101 is waste. The same first-batch-gate logic applies here as in Phase A's first-BRD review.

A secondary spot check on data output catches obviously broken phases early, but is not a substitute for formal Proofmark validation. The execution gate does not re-run reverse engineering and does not flag intentional sabotage as a failure.

---

## 2. Sustain — What Worked, Don't Break It

These are things POC3 got right. They are not acknowledgments — they are prescriptions to protect what works. Any proposed change that conflicts with a sustain item must resolve that conflict explicitly, not silently.

*Note: POC3 operated under the previous role model where BD served as both architect and orchestrator. The sustain items describe patterns that worked regardless of role assignment. The structural patterns are preserved; role references have been updated to the current model.*

### 2.1 Adversarial Review at Every Step

Multi-analyst review with adversarial posture caught real errors that single-pass review would have missed. CsvFileWriter header misunderstanding caught by two independent BRD analysts. Math.Round banker's rounding error caught in review. These are different failure modes, both caught by the same structural pattern: independent analysts with adversarial instructions reviewing the same artifact.

This pattern must be required for planning outcomes, FMEA outcomes, audible calls, and all review gates. It is not optional and it is not advisory. The named personas (Jim, Johnny, Pat) are implementations of this principle at different scopes.

### 2.2 The Saboteur

The saboteur methodology — intentionally injecting defects into artifacts to test whether downstream agents detect them — worked. POC3 evidence: FSD architects detected planted mutations in BRDs, proving the adversarial multi-analyst pattern catches injected defects, not just organic ones.

**POC4 expansion:** The saboteur's domain extends to every step from design through code. Not just BRD mutations — FSD mutations, code mutations, config mutations. The saboteur is launched by BD at Dan's instruction (see E.3, E.5 in the phase execution plan), operates independently, and is invisible to Orchestrator and all worker agents. If an agent can pass a review gate without detecting a planted defect, the review gate is broken.

**Design constraint:** Agents must start from the BRD as their primary source document for each phase. POC3 evidence showed architects self-correcting against V1 source code, which is permitted — agents should have the freedom to consult the original code — but the BRD is the governing input. If an agent's work contradicts the BRD and the agent didn't flag the contradiction, that's a failure regardless of whether the agent's interpretation of V1 source was technically correct. The BRD is the spec. V1 source is reference material.

### 2.3 Phase Gates Work When They're Hard Stops

Every governance gate positioned as a hard stop ("STOP HERE") was respected by every agent in POC3. Zero violations. This is in direct contrast to standing orders and behavioral directives, which failed repeatedly under the previous role model (the clutch failure, #2 behavioral momentum, context rot). The evidence is clear: agents respect structural barriers and ignore behavioral requests.

This is the foundational principle behind Section 3.5 (session boundaries as hard stops) and Section 3.6 (blueprint immutability). Do not weaken hard stops into suggestions. Do not replace structural gates with behavioral directives. The moment a gate becomes "assess whether you should continue," it has already failed.

### 2.4 BRD Review Quality

BRD reviews in POC3 were not rubber stamps. They caught substantive errors from independent analysts working the same source material. The quality came from the combination of adversarial instructions, multi-analyst redundancy, and independence (analysts didn't see each other's work). These three conditions must be preserved in any review structure. Remove any one and review quality degrades to checkbox compliance.

### 2.5 Proofmark — Accuracy Validated Within Tested Scope, Untested at Scale

Proofmark (the COTS comparison tool) passed 217 automated tests (205 at time of manual validation, plus 12 queue runner integration tests added during Step 5), 23 manual tests, and 66 BDD scenarios. Manual testing by Dan covered order independence, schema validation, floating point tolerance, trailer handling, whitespace, quoting, and multi-part Parquet assembly. Cross-validation during Step 4 confirmed CSV/Parquet parity across 10 dates (10/10 STRICT pass). Two known gaps are documented and accepted for POC scope: CSV quoting differences are invisible to the data comparison pipeline (test 013 — HIGH risk for production; POC mitigation is header comparison only; vendor build must address via CSV dialect spec), and mixed line breaks within a single file are not detected (test 005 — LOW risk). Proofmark's accuracy is validated within tested scenarios. What remains untested is operational scale — 101 jobs with varied schemas, edge cases in real ETL output, and configurations not yet written. The scale shakedown serves double duty: validating volume handling and surfacing accuracy gaps under conditions not covered by manual testing. Treat it as validated-in-scope infrastructure, not an unproven prototype — but do not assume tested accuracy extends to untested conditions.

*Amended 2026-03-06 per Amendment 001 (`Governance/Amendments/001-proofmark-status.md`). Original language: "Promising, Not Proven." Jim review: CONDITIONAL APPROVE (conditions met). Dan approval: 2026-03-06.*

---

## 3. Pre-Launch Planning

POC3's second-largest failure category: insufficient up-front planning. Five separate findings (#7 documentation sprawl, #10 confused runbook/blueprint, #8 mixed tooling with ATC, #5 missing FMEA, #13 dropped job / no scope manifest) share a root cause — the POC launched without answering basic questions about structure, scope, and risk. Every one of these failures was preventable with planning that should have happened before the first agent was spawned.

These failures also compound with execution-phase failures (Group 3). Under the previous role model, documentation divergence + context rot + the AI orchestrator running off = the Phase C calamity, where the AI orchestrator confidently executed against superseded instructions with degraded context and no self-check instinct. Group 2's planning failures created the conditions for Group 3's execution failures to do maximum damage. The groups are not independent.

### 3.1 Tooling Readiness Gate

All known infrastructure work completes before the POC starts. This is a named gate, not a suggestion. Proofmark, framework changes, data lake expansion, queue executor rewrites — anything that isn't reverse engineering work finishes first, with a formal "tooling is stable, POC may begin" checkpoint.

If infrastructure work surfaces mid-POC — and it will — the POC formally pauses. Not "we'll fix this while the agents keep running." The POC stops, the fix happens, the fix is validated, the POC resumes. The queue executor rewrite during POC3 was the right call on substance and the wrong call on process: it ran concurrent with POC3 execution because nothing enforced the boundary.

**Repo boundaries are part of this gate.** ATC-specific artifacts (job configs, test data, comparison targets) do not belong in generic tooling repos. MockEtlFramework is a framework; AtcStrategy owns the ATC program. A one-time cleanup establishes the boundary; the gate enforces it going forward. If an artifact serves the framework generically, it lives in the framework repo. If it exists because of ATC, it lives in AtcStrategy.

### 3.2 Document Architecture

Every document type is defined before execution starts. For each type, answer four questions:

1. **Who is the audience?** Orchestrator, worker agents, Dan, review personas, or some subset.
2. **What is its lifecycle?** Created once and static, or living and updated through execution.
3. **When does it become stale?** Phase boundary, sub-phase boundary, or never (reference material).
4. **Where does it live?** Which repo, which directory, and why.

This is the document taxonomy. It does not need to anticipate every document that will ever exist — it defines the categories so that when a new document is created, there's a clear answer for where it goes and who maintains it. The populated taxonomy — not just the framework, but the actual answers for every known POC4 document type — is a prerequisite for the tooling readiness gate (Section 3.1). The gate does not clear until the taxonomy exists with real entries.

**Intentional scope control.** Dan sees everything — sabotage plans, risk assessments, the full mission. Orchestrator sees only what is provided in its phase blueprint and task assignments: enough to execute, not enough to second-guess Dan's adversarial testing or access information outside its phase scope.

This is not accidental duplication or dual-document maintenance. Dan maintains governing documents as single sources of truth. Orchestrator receives a blueprint authored for its scope — a curated view, not a parallel version. There is no propagation problem because there are no parallel versions to diverge.

Under the previous role model, the compound failure was: tactical changes landed in whichever document was open, never propagated to the parallel version, and the divergence became context poison when the stale version was loaded in a later session. The current model eliminates this failure mode by eliminating parallel document versions entirely. Dan owns the single source of truth. Orchestrator's blueprint is authored once during pre-launch planning, reviewed, and frozen (Section 3.6).

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

Dan and BD (during planning) discuss mitigations and detection strategies, then report back to Jim. During execution, Dan engages Jim directly at required firing points and whenever Dan judges Jim's input is needed. Jim signs off or you don't proceed.

**Minimum required firing points.** Jim's authority is universal, but these are the points where Jim is *required* to review — not the boundaries of his authority:

**Pre-launch:** Jim reviews the complete process design — runbook, blueprints, phase designs, agent instructions — after all design artifacts are in place but before the first agent is spawned. Jim does not review the design as it's being built (that's Layer 2's job). Jim reviews the assembled whole and assumes something is broken.

**Phase boundaries:** Jim reviews the transition between phases. What assumptions from the prior phase carried forward? What new risks does the next phase introduce? What changed since the last FMEA that invalidates prior sign-offs?

**Governed document changes.** After the readiness gate (Section 3.1) clears, the runbook and all build-team blueprints are governed documents. Any modification to a governed document triggers Jim with full veto authority. Jim doesn't just evaluate whether the change is safe — Jim can reject the premise that the change should exist at all. Jim can block on risk, on process, on the assertion that the errata channel is the right mechanism instead, or on the signal that the change indicates a design flaw requiring a bigger conversation. Blueprints are immutable during execution (Section 3.6) — changes flow through errata, not amendments. If someone is trying to modify a blueprint post-gate, that's already a violation. If someone is modifying the runbook post-gate, Jim reviews the change, its blast radius, and its propagation requirements before it takes effect.

This governed-document rule mechanically prevents the compound failure documented in the POC3 AAR: tactical changes made under pressure, propagation forgotten, stale documents loaded on the next session, confident wrong execution. No governed document changes without Jim's sign-off — regardless of who is requesting the change.

**Enforcement mechanism.** The governed-document trigger is enforced through audit trail verification at every structural gate. At each pre-defined stopping point (phase boundary, batch boundary, or any gate where Jim or Pat reviews), the reviewer checks modification dates on all governed documents. If a governed document was modified since the last gate and there is no documented Jim sign-off authorizing the change, that is a hard stop. The POC halts immediately until the team can verify that the change was made safely and that the project is still on the rails. This does not depend on any agent self-reporting the change — the reviewer checks regardless. No paper trail, no passage.

**Pre-launch scope explicitly includes compute and infrastructure capacity.** Jim's pre-launch FMEA must assess CPU-bound operations, RAM limits, disk I/O throughput, and concurrent process ceilings for the target environment. POC3's resource saturation (20 parallel dotnet builds on a home PC) and clutch failure (34 concurrent agents at 89% token usage) were both infrastructure capacity failures that a pre-launch FMEA pointed at the execution environment would have caught. This is not a suggestion to "think about resources" — it is a named FMEA concern with the same blocking authority as any other Jim finding.

POC3 evidence of what FMEA would have caught: resource saturation (20 parallel dotnet builds on a home PC), the clutch failure (34 concurrent agents at 89% token usage), and possibly the dropped job (FMEA might have arrived at "you don't have a job manifest" even if it didn't catch the specific missing job).

**How Jim relates to Layer 2 and Layer 3 (Section 1.4).** Three adversarial processes exist, each with blocking authority and distinct scope, but Jim's authority supersedes scope boundaries. Layer 2 reviews design artifacts as they are produced — blueprints, phase designs, agent instructions — checking each against the mission. Layer 3 reviews execution output at the first batch boundary, checking code quality against the anti-pattern list. Jim operates at whatever scope Jim decides is relevant. The defined firing points give Jim structured review opportunities, but Jim is not constrained to those opportunities. Layer 2 catches mission drift in individual design documents. Layer 3 catches code quality rot in execution output. Jim catches whatever Jim catches. Jim's authority is not diminished by the existence of Layer 2 or Layer 3 coverage.

### 3.5 Agent Session Boundaries

Context rot is not a problem to monitor — it is a problem to prevent by architecture. No agent session is trusted to run indefinitely. Sessions are designed to be short-lived, with hard boundaries that force recycling. Critical state lives in persistent storage, not in any agent's context window.

**The principle:** an agent session exists to accomplish a defined segment of work. When that segment ends, the session ends. A fresh session picks up from persistent state, loading only what is relevant to the next segment. Context never has the opportunity to rot because no session outlives its usefulness.

**Boundaries are hard stops, not checkpoints.** A boundary is not "assess whether you should continue." It is "you are done. Persist your state. The next session will pick up." There is no self-assessment because the agent whose context is degraded is the last entity qualified to judge its own degradation.

**Cross-phase boundaries are structurally enforced.** Orchestrator is launched by BD for a single phase and stops when that phase is complete. Dan recycles BD between phases. No agent carries context from one phase to the next. The phase execution plan (E.1–E.7) defines the boundary ritual: Orchestrator stops, BD validates outputs, Dan approves, BD is recycled. This is not a behavioral directive — it is the architecture of the execution model.

**Within-phase boundaries are Orchestrator's responsibility.** Within a phase, Orchestrator manages batch boundaries for its worker agents. The default unit of work between boundaries is a batch — not the entire phase. A phase may contain many batches, and each batch boundary is a hard stop where worker sessions recycle. The exact batch size is a POC4 design decision specified in Orchestrator's blueprint, but the principle is: err on the side of too many boundaries rather than too few. A fresh session loading clean state from files is cheaper than a degraded session making increasingly unreliable decisions. Twenty clean reboots beat one long session that goes sideways at minute 45.

**All critical state persists to storage at every boundary.** This includes:

- The job scope manifest with current status for every job (Section 3.3)
- Any tactical changes made during the segment, with propagation status
- Decisions made during the segment and their rationale
- The current state of any in-progress work (where the agent stopped, what remains)
- Any anomalies, open questions, or flags for the next session

The handoff artifact is not optional documentation — it is the mechanism by which the process survives agent recycling. A session that ends without a complete handoff has failed, even if its actual work was correct. The next session must be able to start cold from the handoff and persistent governance documents alone, with zero reliance on anything that lived only in the prior session's context.

**Orchestrator is not exempt from within-phase context rot.** While cross-phase rot is structurally impossible (Orchestrator dies between phases), a long-running Orchestrator session within a complex phase (e.g., E.6 validation with its date progression loop) can still accumulate context debt. Orchestrator's blueprint must define internal session boundaries — e.g., recycle after each effective date's triage cycle — with the same hard-stop discipline applied to worker agents. The blueprint is the enforcement mechanism; Orchestrator does not self-assess its own degradation.

### 3.6 Named Blueprints

Every worker role and Orchestrator have named blueprints written during pre-launch planning. The blueprint is the complete operating context for that role — behavioral identity, judgment patterns, procedural instructions, standards, anti-pattern references, and deliverable definitions. One document per role, authored by Dan and BD during planning, reviewed by Layer 2, and approved by Jim before any agent is spawned.

**The name is a calibration anchor.** Each blueprint is named after a real person from Dan's professional experience whose judgment profile matches the role. The name compresses a full set of expectations into a single word. "Johnny passed the spec" tells Dan exactly what rigor bar was cleared, because Dan knows real Johnny's standards. "Jim's worried" gets immediate attention, because Dan knows real Jim's threshold. The name is Dan-facing signal compression; the content is agent-facing instructions. Both live in the same document.

**Blueprints are immutable during execution.** Once the readiness gate (Section 3.1) clears, no blueprint is modified. Orchestrator's job is to assign work and point agents at the correct blueprint — not to generate or modify instructions. This eliminates non-deterministic instruction drift across thousands of spawns. The blueprint was written with full attention, reviewed thoroughly, and approved by Jim. It does not degrade because it is not regenerated.

**Dynamic events flow through errata, not blueprint amendments.** Discoveries during execution — a misunderstood API behavior, a data pattern nobody anticipated, a correction caught by a reviewer — are real and must propagate to future agents. They do not modify the blueprint. They flow through a three-part mechanism:

1. **Raw errata log.** When a reviewer or agent discovers something that future agents need to know, it goes into the errata log with minimal analysis. The discoverer's job is to record the finding accurately, not to assess its scope or categorize it. Low overhead, fast capture.

2. **Curator agent.** A dedicated agent whose only job is to review the raw errata log and categorize each entry by job type, feature, and concept. The curator determines which types of jobs, which features, and which common patterns each error applies to. The curator builds the queryable index that workers actually read. No worker reads the raw errata log.

3. **Curated errata by job profile.** At session startup, each worker reads their blueprint, then checks the curated errata for entries tagged to their job type. If there are three relevant warnings out of fifty total errata entries, the worker sees three. Context stays lean.

The curator is not perfect — miscategorization means a relevant warning doesn't reach the right worker. But the review gates that caught the original error still exist and will catch recurrences. The errata system reduces repeat failures; it does not replace the primary catch mechanisms. Having an imperfect curator leads to a higher probability of success than having no curator at all. Overlapping imperfect safety nets beat a single theoretically perfect one.

**Worker startup sequence:** Read named blueprint. Check curated errata for job profile. Read task assignment. Begin work. The blueprint is the constitution. The errata is the case law. The task assignment is the current docket.

**Orchestrator receives only the blueprint for the current phase.** The next phase's blueprint does not exist in Orchestrator's context during the current phase. This is a mechanical scope limitation: Orchestrator cannot execute work it cannot see. When a phase completes and Dan authorizes the next phase, BD launches a fresh Orchestrator instance with the next phase's blueprint. This prevents both scope creep and the self-assessment problem (Orchestrator deciding "I can handle one more phase before stopping") by removing the decision entirely.

**Orchestrator may have multiple blueprints across phases.** Different execution phases may require different Orchestrator blueprints (e.g., E.1's requirements-inference orchestration vs. E.6's validation-loop orchestration). The blueprint-per-phase decision is made during pre-launch planning.

### 3.7 Doctrine Change Management

This document is not frozen at launch. It is a living governing document that must evolve as POC4 generates new evidence. But evolution without governance is drift — the same disease that killed POC3's documentation.

**Standing review question at every phase boundary:** "What did we learn this phase that the doctrine doesn't account for?" This is a required agenda item, not a suggestion. Dan, Jim, and Pat all engage with this question at every phase boundary review. If the answer is "nothing," that answer is documented. If the answer is substantive, it enters the change process below.

**Change process:**

1. **Observation.** Someone (Dan, BD, a reviewer) identifies a gap — something the doctrine doesn't cover, something it gets wrong, or something that worked differently than the doctrine predicted.
2. **Proposal.** The observation is written up as a specific proposed change with rationale and evidence. Not "we should think about X" — a concrete edit with a reason.
3. **Jim review.** Jim reviews the proposed change with the same authority as any governed document change (Section 3.4). Jim can approve, reject, or escalate. Jim evaluates blast radius — does this change invalidate prior decisions? Does it conflict with other sections? Does it require propagation to blueprints or errata?
4. **Dan approval.** Dan has final authority on all doctrine changes. Jim can block, but only Dan can approve.
5. **Logged.** Every doctrine change is logged with the session context, the change, the rationale, and who approved it.

**What this is NOT:** A license to rewrite the doctrine mid-flight whenever something feels wrong. The bar for changing the doctrine during execution is high — the evidence must be clear, the change must be specific, and the governance chain must approve it. The doctrine was built through 12 sessions of rigorous AAR. Casual mid-flight edits undermine the rigor that produced it.

**What this IS:** An explicit acknowledgment that no plan survives contact with reality unchanged. The doctrine is the best understanding as of the AAR. POC4 will teach things the AAR couldn't anticipate. The choice is between governed evolution and ungoverned drift. This section ensures it's the former.

---

## 4. Enterprise Deployment — Global Technical Risk Register

**This section can be ignored for home-lab POC work.** These risks are not testable or addressable in the sandbox environment. They become real when the process targets a production bank engagement with real infrastructure, real data volumes, and real organizational constraints.

The register exists here so it doesn't get lost between POCs. When a bank engagement materializes, every entry requires a disposition before execution begins.

| # | Risk | Source |
|---|------|--------|
| 1 | **Agent profiling billion-row tables may just die.** Single-agent data profiling at production scale is untested and may hit hard limits (memory, timeout, API constraints) that don't surface in sandbox work. | POC3 AAR, parking lot |
| 2 | **Infrastructure viability vs. infrastructure capacity.** Jim's FMEA assesses capacity — "how much can this environment handle?" It does not assess viability — "is that enough for what we're trying to do?" In the home lab, Dan makes that judgment call. In a bank deployment with shared clusters, resource quotas, and regulatory compute limits, the distinction between "we sized the workload correctly" and "this environment fundamentally can't run this workload" needs a formal answer before launch. | POC3 AAR, Pat's Group 4 review |
