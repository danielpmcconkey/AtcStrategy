# Group 2 Adversarial Review — "Insufficient Up-Front Planning"

**Reviewer:** Adversarial evaluator (skeptical bureaucrat persona)
**Date:** 2026-03-03
**Scope:** Evaluate problem statement, root cause analysis, and mitigation plan for AAR Group 2
**Documents reviewed:** AAR log (Sessions 1-6, all decisions), NewWay Of Working.md (bible Section 3, plus Section 1 for cross-references), condensed-mission.md, poc4-lessons-learned.md, doc-reorganization-plan.md, doc-reorganization-completed.md, orchestrator-observations.md, design-decisions.md (#20, #26), Group 1 adversarial review (format template)

---

## Summary Grades

| Category | Grade | One-Line Verdict |
|----------|-------|------------------|
| Problem Statement | **A** | Clean scope, correct shared root cause, explicit compound failure chain with Group 3, all 5 items properly attributed |
| Root Cause Analysis | **A-** | Strong causal chain with evidence, one item fits the root cause less cleanly than the others |
| Mitigation Plan | **B** | Five solid prescriptions with real teeth, but two structural gaps and one prescription that's softer than it appears |

---

## 1. Problem Statement — Grade: A

### What they got right

The problem statement in bible Section 3 opens with a precise claim: five findings share a root cause ("the POC launched without answering basic questions about structure, scope, and risk") and every one was preventable with planning that should have happened before the first agent was spawned. This is a testable claim. I can check each of the five items against it.

More importantly, the problem statement does something the Group 1 statement did not: it explicitly addresses the compound failure chain across groups. The second paragraph of Section 3 connects Group 2's planning failures to Group 3's execution failures via a specific causal narrative — documentation divergence + context rot + BD running off = the Phase C calamity. This is not hand-waving. The AAR log (Session 5, lines 572-582) contains the detailed walkthrough of how these three individually survivable failures stacked into confident wrong execution. The bible captures the conclusion accurately.

The scope is correctly drawn. Five items, one shared root cause, no attempt to absorb items that belong elsewhere. The statement correctly notes that Group 2 "encompasses Group 1" conceptually but that #1 is too important to bury in this group (AAR log Session 2, line 285). This is clean boundary management.

Each of the five items is attributed with enough specificity to distinguish it from the others:
- #7 is about document placement, staleness, and loading discipline
- #10 is about unmanaged duplication between documents serving different audiences
- #8 is about infrastructure work lacking a completion gate
- #5 is about no proactive risk assessment
- #13 is about no authoritative scope document

These are genuinely different symptoms of the same disease. They aren't the same finding restated five ways. That's evidence of real analytical work, not grouping for convenience.

### What's missing

Nothing material. The problem statement is the strongest component of the Group 2 write-up.

---

## 2. Root Cause Analysis — Grade: A-

### The causal chains

For each of the five items, I'll trace the causal chain from the AAR log and verify it against the bible.

**#7 — Documentation sprawl.** Root cause per AAR log (Session 5): documentation structure wasn't planned before execution started. Nobody asked "what docs will we produce, who are they for, where do they live, and when do they become stale" before the first agent was spawned. BD identified three layers: docs in wrong repos (fixed reactively mid-POC3 via the doc-reorganization-plan.md on 2026-02-28), docs with stale/contradictory content (the actual context poison), and no loading discipline. Evidence is strong — the doc-reorganization-plan.md is a real artifact that proves the problem existed and was fixed reactively, not proactively. Dan confirmed the symptom: "when Dan needed to re-focus BD, contradictory docs were polluting BD's context."

**#10 — Confused runbook/blueprint.** Root cause per AAR log (Session 5): unmanaged duplication, not duplication itself. Dan explicitly rejected DRY — the blind lead compartmentalization requires two versions of the same state. The failure was that tactical changes under pressure landed in whichever document was open, with no propagation process. Dan's "no plan survives contact with the enemy" framing is honest — it acknowledges that propagation discipline will be tested hardest when it matters most.

**#8 — Mixed tooling with ATC.** Root cause per AAR log (Session 6): no tooling readiness gate plus repo boundary neglect. Dan identified four instances of tooling work bleeding into POC3: Proofmark (built from scratch during POC3), MockEtlFramework file-based conversion, data lake expansion, and queue executor rewrite. Key clarification from Dan: items 1, 2, and 3 were planned — the failure was sequencing without clean boundaries, not failure to identify prerequisites. The queue executor is the sharpest example because POC3 should have been formally paused. Evidence: the queue executor rewrite is documented in orchestrator-observations.md and poc4-lessons-learned.md.

**#5 — Missing FMEA.** Root cause per AAR log (Session 6): no proactive risk assessment process existed. Dan confirmed which failures FMEA would have caught (resource saturation, clutch failure) and which it wouldn't (overwrite mode — a design flaw, not a risk assessment gap). The prescription (Jim) was Dan's own proposal, not BD's, which is notable because it means the problem owner designed the fix.

**#13 — Dropped job / no scope manifest.** Root cause per AAR log (Session 6): no single authoritative list of what's in scope. Evidence: Design Decision #26 documents exactly how 102 V1 jobs became 101 processed jobs without detection. The math is clean (POC2 deactivated 1 of 32 → POC3 added 70 → 101 active, 1 inactive → phases processed 101 → discrepancy discovered at Phase D prep). Dan's memory was the only safety net.

### Does "insufficient up-front planning" hold for all 5?

Four of the five map cleanly to the shared root cause. The fifth is weaker.

**#7, #10, #5, #13** are unambiguously planning failures. In each case, a specific planning activity (document taxonomy, propagation protocol, FMEA process, scope manifest) would have prevented the failure, and the activity obviously belongs in a pre-launch planning phase.

**#8 is the weaker fit.** "Mixed tooling with ATC" is partially a planning failure (no readiness gate, no formal "tooling done" checkpoint) and partially an execution discipline failure (running two Claudes in parallel without good doc discipline, per Dan's own words in Session 6). The readiness gate is a planning artifact — you define it up front. But the repo boundary neglect happened during execution (data lake expansion left ATC artifacts in MockEtlFramework). And the queue executor rewrite is a mid-execution infrastructure response, not a pre-launch planning gap — the decision to do the rewrite was correct, the failure was not pausing the POC to do it.

The bible's Section 3.1 handles this nuance reasonably well: it distinguishes between "all known infrastructure work completes before the POC starts" (the planning gate) and "if infrastructure work surfaces mid-POC, the POC formally pauses" (the execution discipline). But the second half is an execution-phase protocol masquerading as a pre-launch planning prescription. If the POC has already launched and infrastructure work surfaces, the planning phase is over — what's being prescribed is a mid-execution governance mechanism.

This isn't wrong enough to challenge the grouping. The pre-launch gate is genuinely a planning item. The mid-POC pause protocol is a reasonable companion prescription. But calling #8 purely an "insufficient up-front planning" failure elides the execution discipline component. A more precise framing would be: "insufficient boundary enforcement between tooling work and POC execution, starting with no pre-launch gate and extending to no pause protocol during execution."

Minor deduction. The root cause analysis is solid for 4 of 5 items and serviceable for the fifth.

### Where I'd push back harder

The root cause analysis for #10 (runbook/blueprint confusion) includes a critical claim from Dan: "no plan survives contact with the enemy." This is invoked to explain why tactical changes landed in whichever document was open under pressure. The prescription (propagation discipline) is the correct response. But the root cause analysis doesn't probe whether the runbook and blueprint had clearly defined, non-overlapping scopes from the start.

From the AAR log (Session 5, line 564): "two different audiences, two different purposes, but they bled into each other." Were the purposes actually different and well-defined, or were the documents created without clear boundary definitions? If the documents were well-scoped from the start and diverged only under tactical pressure, the root cause is execution discipline. If they were poorly scoped from the start, the root cause is planning — consistent with the group's theme. The AAR log suggests the latter (Dan said they "bled into each other," implying the boundaries were never clean), but this is inference, not stated evidence. The bible's Section 3.2 treats it as a planning failure, which is probably correct, but the evidence trail could be tighter.

---

## 3. Mitigation Plan — Grade: B

### What's proposed

Five prescriptions, organized into bible Sections 3.1 through 3.5:

1. **Tooling readiness gate (3.1):** Named gate before POC launch. All infrastructure done first. Mid-POC tooling work requires formal pause. Repo boundaries enforced.
2. **Document architecture (3.2):** Four-question taxonomy (audience, lifecycle, staleness, location). Intentional compartmentalization between orchestrator and blind lead. Propagation discipline with orchestrator ownership.
3. **Scope governance (3.3):** Job manifest as governance document. Phase-boundary reconciliation. Count mismatch = hard stop.
4. **Risk assessment — Jim (3.4):** FMEA persona with blocking authority. Pre-launch firing on assembled design. Phase-boundary firing on transitions.
5. **Context health as forcing function (3.5):** Structural checkpoints at natural pause points. Context-heavy = pause, capture state, reboot.

### What's genuinely good

**The manifest (3.3) is the tightest prescription in the group.** It directly addresses a specific, documented failure (Design Decision #26: 102 V1 jobs, 101 processed, nobody noticed). It has a concrete mechanism (reconciliation at phase boundaries), a concrete enforcement rule (count mismatch = hard stop), and a clear evidentiary standard (name-level verification, not count comparison — this detail comes from poc4-lessons-learned.md and adds real rigor). A future team could implement this from the bible text alone. No ambiguity, no tribal knowledge required.

**Jim (3.4) is well-designed as a process.** Three questions (what could go wrong, how to watch, what to do), blocking authority, defined firing cadence. The pre-launch vs. phase-boundary distinction is correct — pre-launch reviews the assembled whole (after Layer 2's job is done), phase-boundary reviews transitions and assumption carry-forward. The persona framing serves a practical purpose: it makes the adversarial process embodied and persistent rather than a checklist someone runs through. The POC3 evidence (resource saturation, clutch failure) is appropriately cited — these are specific failures that a structured risk assessment plausibly would have caught.

**The compound failure chain in 3.5 is genuinely insightful.** Connecting Group 2's planning failures to Group 3's execution failures through a specific causal mechanism (documentation divergence + context rot + running off = Phase C calamity) is the kind of systems thinking that makes a governing document useful rather than decorative. It explains why context health checkpoints are in this section rather than in a standalone hygiene section — they're a forcing function that prevents planning-level failures from cascading into execution-level catastrophes.

**The intentional compartmentalization framing in 3.2 is the right structural response to the DRY instinct.** Rejecting DRY when information asymmetry is a design feature is a non-obvious decision that would trip up a future BD who hasn't internalized the architecture. Making it explicit in the bible — with the reasoning that the blind lead must not see orchestrator-level context — prevents a well-intentioned refactoring from breaking the security model. This is the kind of operational wisdom that justifies a governing document.

### What concerns me

**Gap 1: The document taxonomy (3.2) defines what to ask but not what the answers are.** Section 3.2 says "every document type is defined before execution starts" and provides four questions: audience, lifecycle, staleness, where. It then says this "does not need to anticipate every document that will ever exist — it defines the categories." This is reasonable in principle. In practice, the bible should include at least the initial category definitions for POC4's known document types.

POC4 will produce, at minimum: a runbook, blueprints (per-phase), agent instructions, BRDs, FSDs, test plans, V2 code, the manifest, FMEA reports, errata files, session state files, and the bible itself. The four questions have answers for each of these. If the taxonomy is built during POC4 Step 7 (setup), that's implementation — fine. But if a future BD arrives at Step 7 with only the four questions and no worked examples, they'll derive the taxonomy from scratch. The bible could include a starter table without prescribing every row. The taxonomy framework is here; the taxonomy content is not.

This matters because the root cause of #7 was that "nobody asked these questions before execution." The prescription says "ask these questions." But asking questions doesn't prevent doc sprawl — having answers does. A future BD who dutifully asks "who is the audience for this FSD?" and answers "the developer" is no better off than POC3's BD unless the taxonomy tells them "FSDs live in this directory, are created during Phase B, become stale at V2 code acceptance, and are owned by the architect."

**Gap 2: Jim's scope relative to Layer 2 and Layer 3 is underspecified.** Section 3.4 defines Jim as a pre-launch and phase-boundary FMEA process. Section 1.4 defines Layer 2 as a design-phase gate and Layer 3 as an execution-phase gate. Dan clarified the distinction in Session 4 (line 527): Layer 2 reviews design artifacts as they're produced, Jim reviews the assembled whole before launch. Layer 3 reviews execution output, Jim reviews phase transitions.

The concern: Jim's phase-boundary firing and Layer 3's first-batch-boundary firing are close enough to collide. If Jim fires between Phase A and Phase B to review the transition, and Layer 3 fires at Phase B's first batch boundary to check code quality — who reviews what? Jim asks "what could go wrong in Phase B?" Layer 3 asks "did Phase B's first batch reproduce anti-patterns?" These are different questions, but they fire in close temporal proximity, review overlapping artifacts, and are both adversarial processes with blocking authority.

The bible doesn't address this. A future BD implementing both will need to decide: Does Jim fire first, then Layer 3? Do they overlap? Can Jim's pre-Phase-B assessment subsume Layer 3's first-batch review, or are they structurally independent? This isn't a fatal gap — both processes have clear mandates. But the interaction between them is undefined, and a BD under context pressure (exactly when this matters) might skip one, thinking the other covers it.

**Gap 3: Section 3.5 (context health as forcing function) is the softest prescription in the group.** Every other prescription has a concrete mechanism: 3.1 has a named gate, 3.2 has four questions, 3.3 has phase-boundary reconciliation with hard stops, 3.4 has Jim with blocking authority. What does 3.5 have? "At natural pause points, the orchestrator assesses context health before continuing."

This is a standing order. The very type of governance mechanism that the AAR repeatedly identified as decay-prone (Decision 8: "standing orders decay over long runs"; agent-lessons-learned.md: "standing orders decay"; POC3 evidence: the clutch, the context rot, the running-off behavior). The bible's own Section 1.4 was designed specifically because standing orders don't work for BD — that's why Layer 1 uses recursive self-reinforcement instead.

Section 3.5 doesn't have a mechanical trigger. It doesn't have a blocking gate. It says "the orchestrator assesses" — which is the same BD whose context degradation is the problem being addressed. You're asking the patient to diagnose themselves. The very scenario 3.5 is designed to prevent (orchestrator with heavy context pushing through instead of pausing) is the scenario where BD is least likely to comply with 3.5.

I acknowledge that context health monitoring is intrinsically hard to mechanize — you can't build a gate that fires when context is "heavy" because there's no reliable metric. But the prescription should at least acknowledge this limitation and propose a structural approximation. The batch-boundary checkpoints from poc4-lessons-learned.md (forced context refresh every 20 jobs) are one such approximation — they fire mechanically, not based on self-assessment. The bible's Layer 3 already uses first-batch-boundary timing. Section 3.5 could adopt the same cadence: "at every batch boundary (not just natural pause points), the orchestrator checks context health." That's still partially self-assessed, but it at least fires at a defined interval rather than relying on the orchestrator to recognize their own degradation.

### Could a future team execute this without tribal knowledge?

**3.1 (tooling readiness gate):** Yes. Clear and self-contained. A future BD could implement this from the text. The repo boundary guidance could be more specific (which specific artifacts in MockEtlFramework are ATC-specific?), but the principle is clear.

**3.2 (document architecture):** Partially. The four-question framework is clear, but as noted above, the actual taxonomy answers don't exist yet. A future BD would need to derive the taxonomy during Step 7. Possible, but unnecessary if the bible included a starter version.

**3.3 (scope governance):** Yes. Tight, specific, immediately implementable.

**3.4 (Jim):** Mostly yes. The FMEA process is well-defined. The persona framing is clear. Two ambiguities: the scope overlap with Layer 2/3 (noted above), and the "natural phase or sub-phase boundaries" language. "Natural" is doing work here — who decides what's natural? POC4's phase structure will determine the firing cadence, and that structure doesn't exist yet. This is a Step 7 implementation detail, not a bible gap, but it's worth noting.

**3.5 (context health):** No. A future BD with degraded context will not reliably execute a prescription that requires them to recognize their own degraded context. The prescription describes the problem accurately and the solution aspirationally but doesn't provide the mechanical enforcement that every other prescription in this section has.

---

## Overall Verdict: Is Group 2 Ready to Close?

**Conditionally yes.** Per the agreed definition of done (AAR Session 4): "root cause understood, prescriptions landed in the governing document, confidence that the prescriptions address the root cause." On those criteria:

- **Root cause understood:** Yes. "Insufficient up-front planning" holds for all five items, with #8 being the weakest fit (partially an execution discipline failure, not purely planning). The compound failure chain with Group 3 is well-documented and adds genuine analytical value.
- **Prescriptions landed in the governing document:** Yes. Bible Section 3 (3.1-3.5) covers all 8 prescriptions drafted in Sessions 5-6. The consolidation from 8 separate prescriptions into 5 subsections was well-executed — no content was lost in the merge, and the structure is cleaner.
- **Confidence that prescriptions address root cause:** High for 4 of 5 prescriptions, moderate for 3.5.

**The caveats that should be on the record before closing:**

1. **Section 3.2 needs a starter taxonomy, not just a framework.** The four questions are necessary but not sufficient. A future BD needs worked examples for POC4's known document types, not just a template. This can be a Step 7 deliverable, but the bible should say explicitly that the taxonomy must be populated before the tooling readiness gate (3.1) clears. Currently 3.2 says "defined before execution starts" — but it should cross-reference 3.1 to make the sequencing a hard dependency: no readiness gate clearance without a populated document taxonomy.

2. **Jim's interaction with Layer 2 and Layer 3 needs a one-paragraph clarification.** Not a redesign — just a statement of how the three adversarial processes relate. Something like: "Layer 2 reviews design artifacts as they're produced. Jim reviews the assembled whole at phase boundaries. Layer 3 reviews execution output at batch boundaries. All three have blocking authority. They do not substitute for each other." This prevents a future BD from conflating them under context pressure.

3. **Section 3.5 is a standing order dressed up as a forcing function.** The prescription accurately diagnoses the problem (context degradation causes every other discipline to break down) but prescribes self-assessment by the entity whose self-assessment is impaired. At minimum, the bible should acknowledge this limitation. Better: tie context health checks to the same mechanical cadence as batch boundaries, so they fire on a schedule rather than on self-recognition. Best: make context health one of Jim's phase-boundary review items — Jim asks "is the orchestrator's context heavy?" before signing off on the phase transition. That gives the assessment to an independent reviewer, which is the structural pattern that works everywhere else in this bible.

4. **#8's root cause attribution is slightly loose.** The mid-POC pause protocol (if infrastructure work surfaces, POC stops) is an execution-phase governance mechanism, not a pre-launch planning item. It's in the right section for practical reasons (it's the companion to the readiness gate), but the root cause framing should acknowledge that #8 spans planning and execution. Not blocking — the prescription is correct regardless of where the root cause is attributed.

**Disposition recommendation for each caveat:**

- **Caveat 1 (starter taxonomy):** Capture as a Step 7 deliverable with an explicit cross-reference from 3.2 to 3.1. Add one sentence to 3.2: "The populated taxonomy is a prerequisite for the tooling readiness gate (Section 3.1)." Quick bible edit.
- **Caveat 2 (Jim vs. Layer 2/3):** Add a one-paragraph "how the adversarial processes relate" clarification to either Section 3.4 or a new interstitial paragraph between Sections 1 and 3. Quick bible edit.
- **Caveat 3 (Section 3.5):** This is the most substantive gap. The prescription needs teeth. Recommend adding Jim as an explicit context health reviewer at phase boundaries (he's already reviewing transitions — add "orchestrator context health" to his checklist). Recommend tying intra-phase context checks to batch boundaries rather than "natural pause points." These are structural changes to the prescription, not cosmetic edits.
- **Caveat 4 (#8 attribution):** No action required. Log for the record.

**Of these, Caveat 3 is the only one I'd consider gating.** Caveats 1, 2, and 4 are refinements that can be addressed without reopening Group 2's analysis. Caveat 3 is a structural weakness in the mitigation plan — the prescription doesn't have the enforcement mechanism that its own analysis says is necessary. Whether this is blocking depends on Dan's judgment of how much mechanical enforcement Section 3.5 needs vs. how much can be deferred to Step 7 implementation design.

**Close Group 2 with these four caveats logged. Caveat 3 should be discussed before finalizing — if Dan agrees that tying context health to batch boundaries and Jim's phase-boundary reviews closes the gap, make those edits to the bible and close. If Dan wants to defer the mechanical design to Step 7, that's defensible but should be stated explicitly as an acknowledged limitation.**
