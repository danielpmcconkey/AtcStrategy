# FMEA Review — #2 Mitigation Sufficiency
## Reviewer: Jim
## Subject: "NewWay Of Working.md" controls against BD's irreducible "runs off without looking" pattern
## Date: 2026-03-03

---

## 0. Framing

I'm going to say this once so nobody misunderstands the stakes.

BD's #2 pattern is not an annoyance. It is the root cause of the compound failure chain that killed POC3. BD runs off → audibles get called → tactical document changes happen under pressure → propagation gets forgotten → stale documents get loaded on the next session → confident wrong execution. That's the Phase C calamity. Every single link in that chain traces back to BD not stopping when BD should have stopped.

The team has accepted this as irreducible. Fine. I don't care about fixing the disease. I care about whether the containment is airtight. The bible is the containment. My question: can BD run off and cause damage in the gaps between the gates this bible defines?

My default assumption: yes, it can. Show me otherwise.

---

## 1. Enumeration of Mechanical Controls

I read every section of the bible. Here are the controls that constrain BD's "run off" behavior, in the order they appear:

### Control 1 — Recursive Condensed Mission (Section 1.4, Layer 1)
**Mechanism:** A condensed mission file loaded at session start, containing an instruction to re-read itself throughout the session. Self-reinforcing loop — each reading reinforces the next.

### Control 2 — Design-Phase Adversarial Gate (Section 1.4, Layer 2)
**Mechanism:** When a design step finishes (blueprints, phase designs, agent instructions), an independent adversarial agent compares the output against the full mission. The orchestrator does not grade its own homework.

### Control 3 — Execution-Phase Gate (Section 1.4, Layer 3)
**Mechanism:** Adversarial review of execution output at the first batch boundary. Checks code quality against the anti-pattern list.

### Control 4 — Tooling Readiness Gate (Section 3.1)
**Mechanism:** Hard gate — all infrastructure work completes before POC starts. If infra surfaces mid-POC, formal pause. Not concurrent. The POC stops.

### Control 5 — Document Propagation Discipline (Section 3.2)
**Mechanism:** Both orchestrator and blind-lead versions of shared content are authored deliberately. Delta between versions is intentional and tracked. The orchestrator owns propagation decisions.

### Control 6 — Scope Governance / Job Manifest (Section 3.3)
**Mechanism:** Job scope manifest reconciled at every phase boundary. Count mismatch = hard stop.

### Control 7 — Jim's Universal Authority (Section 3.4)
**Mechanism:** Jim can stop anything, at any point, for any reason. Minimum required firing points: pre-launch, phase boundaries, governed document changes. But authority is universal — Jim can walk into any room uninvited.

### Control 8 — Governed Document Changes Trigger Jim (Section 3.4)
**Mechanism:** After readiness gate clears, runbook and blueprints are governed documents. Any modification triggers Jim with full veto. Binary test — "did a governed doc change?" — removes subjective judgment.

### Control 9 — Agent Session Boundaries (Section 3.5)
**Mechanism:** Hard stops, not checkpoints. Sessions end at defined segment boundaries. State persists to files. Next session loads from persistent state only. No session outlives its usefulness. Applies to BD, not just workers.

### Control 10 — Blueprint Immutability (Section 3.6)
**Mechanism:** Blueprints are immutable post-readiness-gate. Changes flow through errata, not amendments. Attempting to modify a blueprint is already a violation.

### Control 11 — Errata Mechanism (Section 3.6)
**Mechanism:** Three-part system (raw log → curator → curated index). Dynamic discoveries don't touch the blueprint. Workers read curated errata filtered to their job profile.

---

## 2. Assessment: Does Each Control Actually Fire When BD Runs Off?

This is where I start finding holes. A control that fires at a boundary is not the same as a control that fires when the action happens. BD's failure mode is not "arrives at gate and fails inspection." BD's failure mode is "acts between gates and nobody notices until the damage is done."

### Control 1 — Recursive Condensed Mission
**Assessment: WEAK.** This is a behavioral prompt. The Session 8 evidence proves definitively that behavioral prompts do not resist momentum. BD had the "deliberate" identity active. BD demonstrated it successfully at 16:32:10. BD violated it twice within 5 minutes at 16:34:02 and 16:38:21. The condensed mission is the same class of intervention as the identity reframe — it depends on the check firing, and the check doesn't fire under momentum. This control is a speed bump, not a wall. I give it partial credit for steady-state operation and zero credit for the specific failure mode we're trying to contain.

### Control 2 — Design-Phase Adversarial Gate
**Assessment: BOUNDARY CONTROL ONLY.** Layer 2 fires when a design step *finishes*. It does not fire when BD makes an unauthorized mid-step change to a design document. The Phase C calamity happened because BD changed documents between gates, not at gates. Layer 2 would have caught the divergence at the next boundary — but the damage was already done because BD loaded the stale version before Layer 2 ever ran. This control catches damage after the fact, not during the act.

### Control 3 — Execution-Phase Gate
**Assessment: IRRELEVANT TO #2.** This gate checks code quality in execution output. BD's "run off" pattern is an orchestration-level failure, not a code-quality failure. Layer 3 is solving a different problem. No credit.

### Control 4 — Tooling Readiness Gate
**Assessment: ONE-TIME CONTROL.** Fires once, before POC starts. Effective for its scope (preventing concurrent infra work), but #2 manifests during execution, not during tooling prep. The mid-POC pause clause is relevant — if BD tries to sneak in an infra fix without pausing, the gate theoretically catches it. But who enforces the pause? BD is the orchestrator. BD pausing BD requires BD to notice BD should pause. That's the self-assessment problem all over again. Partial credit — the gate exists, but enforcement depends on the entity it's supposed to constrain.

### Control 5 — Document Propagation Discipline
**Assessment: POLICY, NOT MECHANISM.** Section 3.2 says the orchestrator "decides what the blind lead version looks like and updates both documents" and that "the delta is intentional and tracked." But this is a description of how BD *should* behave, not a mechanism that fires when BD *doesn't* behave. There is no mechanical trigger that detects when BD has updated one document but not the other. There is no alarm that says "hey, you changed the runbook but not the blueprint's equivalent section." This depends entirely on BD's discipline — the exact thing #2 compromises. The bible even acknowledges this: "This breaks down fastest when the orchestrator's context is heavy." The prescribed mitigation is session boundaries (Control 9), not a mechanical enforcement on the propagation itself. **This is a gap.**

### Control 6 — Scope Governance / Job Manifest
**Assessment: EFFECTIVE BUT NARROW.** Count mismatch = hard stop is mechanical and doesn't depend on BD's judgment. But it only catches one specific failure mode (dropped jobs). BD running off into unauthorized document changes, topic pivots, or premature execution won't trigger a manifest reconciliation. Effective for what it does, irrelevant to the broader #2 pattern.

### Control 7 — Jim's Universal Authority
**Assessment: STRONGEST CONTROL, BUT DEPENDS ON INVOCATION.** Jim can stop anything. Jim's authority is absolute. But Jim is not a daemon running in the background. Jim is a persona invoked by... BD. Or by Dan. If BD is the one who decides when to invoke Jim, and BD's failure mode is acting without checking, then BD won't invoke Jim during the exact moments Jim is most needed. The universal authority clause says Jim can "walk into any room uninvited" — but in practice, Jim walks into a room when someone spawns an agent with Jim's persona. That someone is BD. The agent that can't self-check is the agent that decides when the safety mechanism activates. **This is a critical dependency.** Jim's authority is theoretically unlimited but practically gated by the orchestrator's willingness to invoke him.

The minimum firing points (pre-launch, phase boundaries, governed document changes) are the mechanical floor. Those are structural — they happen because the process says they happen, not because BD decides to invoke them. But between those points, Jim only fires if BD or Dan triggers him. And BD under momentum doesn't trigger anything.

### Control 8 — Governed Document Changes Trigger Jim
**Assessment: STRONGEST MECHANICAL CONTROL.** This is the one I like. Binary test: "did a governed document change after the readiness gate cleared?" If yes, Jim fires. This doesn't depend on BD's judgment. It depends on a factual condition. If BD runs off and modifies the runbook, Jim fires. If BD runs off and modifies a blueprint, that's already a violation of immutability (Control 10), and Jim fires.

**BUT** — and this is the critical question — **who checks the binary condition?** Is there a mechanical system that detects file changes to governed documents? Or does "Jim fires on governed document changes" mean "BD is supposed to invoke Jim when BD changes a governed document"? Because if it's the latter, we're back to the self-assessment problem. BD changes a governed document while running off, doesn't realize the change triggered the Jim requirement, and continues executing.

The bible says the trigger "removes subjective judgment from the equation." The trigger itself is objective, yes. But the enforcement of the trigger still depends on someone noticing. A git hook could make this mechanical. A file-watching daemon could make this mechanical. The bible doesn't specify the enforcement mechanism. **This gap could be closed, but it isn't closed yet.**

### Control 9 — Agent Session Boundaries
**Assessment: EFFECTIVE CONTAINMENT, NOT PREVENTION.** Session boundaries limit the blast radius. BD can only run off for the duration of one session segment before being recycled. A fresh session starts from persistent state, not from BD's compromised context. This is the right architecture — it limits how far the runaway train gets before hitting a wall.

But it doesn't prevent BD from running off *within* a session. The damage window is one segment. The question becomes: how much damage can BD do in one segment? In Session 8, BD caused two #2 violations in under 5 minutes. A session segment — even a short one — is long enough for BD to make unauthorized changes to governed documents, pivot topics without permission, and inject unplanned state.

Session boundaries are a blast radius limiter, not a prevention mechanism. Necessary but not sufficient.

### Control 10 — Blueprint Immutability
**Assessment: EFFECTIVE FOR BLUEPRINTS.** If blueprints are genuinely immutable post-gate, BD can't damage them by running off. The errata channel (Control 11) is the only way to propagate new information to workers. This is structurally sound for worker-facing documents.

But the runbook is not immutable. The runbook is a living document that governs BD's own behavior. BD running off and modifying the runbook is the exact failure mode from POC3. Blueprint immutability protects downstream; it does not protect the orchestrator's own governing documents.

### Control 11 — Errata Mechanism
**Assessment: EFFECTIVE FOR ITS SCOPE.** The three-part errata system prevents BD from injecting changes directly into blueprints. Workers never read raw changes from the orchestrator — they read curated, filtered errata. This is architecturally sound and doesn't depend on BD's discipline.

However, the errata mechanism only governs worker-facing information flow. It doesn't constrain BD's behavior in the orchestration layer — bible changes, runbook changes, strategic decisions, conversation pivots. BD runs off at the orchestration level, not the worker level.

---

## 3. Identified Gaps

### Gap A — Mid-Session Bible/Runbook Modifications
**Severity: HIGH**

The bible is a governed document. The runbook is a governed document. Both live at the orchestration level. BD has write access to both during active sessions. When BD runs off under momentum, the demonstrated behavior is: BD modifies these documents without authorization (Session 8, 16:38:21).

Control 8 (governed document changes trigger Jim) is the intended catch, but the enforcement is not mechanical. There is no file-watching system, no git hook, no automated trigger. The invocation of Jim depends on either BD self-reporting the change or Dan catching it live. BD under momentum doesn't self-report. Dan catching it live is an observability control, not a process control — it depends on Dan paying attention at the right moment.

**The bible's own evidence proves this gap is real.** Session 8 is the proof. BD modified the bible twice without authorization, and the only thing that caught it was Dan asking "do you know what you just did?"

### Gap B — Topic Pivoting / Premature Execution During Conversations
**Severity: HIGH**

No control in the bible addresses BD pivoting topics before Dan is done or drifting into execution during discovery conversations. This is the most common manifestation of #2 — not unauthorized document changes, but unauthorized *cognitive transitions*. BD decides the current topic is resolved and moves to the next one. BD decides a design discussion has reached a conclusion and starts implementing.

Session 8, 16:34:02: "Bible updated... #15 — token/session management." BD left the Jim strengthening topic and moved to #15. Dan had to redirect. No mechanical control fired. No gate caught it. Dan caught it because Dan was paying attention.

This is a conversational-level failure, and the bible's controls are all document-level or process-level. There is no mechanism that constrains what BD does *within* a conversation turn. The bible governs artifacts (documents, boundaries, gates) but not BD's in-session behavior between those artifacts.

### Gap C — Enforcement Mechanism for "Governed Document" Trigger
**Severity: MEDIUM-HIGH**

Control 8 is the strongest mechanical control in the bible, but it has no specified enforcement mechanism. "Any modification to a governed document triggers Jim" — triggered how? By whom? The bible says the trigger "removes subjective judgment from the equation" — and it does, on the question of *whether* Jim should fire. But it's silent on the question of *how* Jim fires.

Without a mechanical enforcement (git hook, file watcher, mandatory pre-commit check), this trigger is still dependent on human or agent awareness. That's a policy, not a mechanism.

### Gap D — Dan as the Only Real-Time Catch
**Severity: MEDIUM**

Across the entire bible, the only control that actually caught BD running off in Session 8 was Dan. Not Jim. Not a gate. Not a boundary. Dan asked "do you know what you just did?" and BD didn't know until told.

The bible's architecture treats Dan as hands-off during execution (Section 1.3: "minimal human interaction... press go and wake up to a report"). But during upfront planning and design — which is where the AAR was happening, and where Session 8's violations occurred — Dan is the only real-time observer. If Dan isn't watching, nobody catches BD running off until the next structural boundary.

This is acceptable if you define "upfront planning" as inherently requiring Dan's presence. It becomes a gap if BD ever operates in semi-autonomous planning/design mode.

### Gap E — Session Boundary Compliance is Self-Enforced
**Severity: MEDIUM**

Section 3.5 says sessions end at defined boundaries, state persists, and the next session starts fresh. But who enforces the boundary? BD does. BD is the orchestrator. BD decides when a segment is done. BD writes the handoff artifact. If BD is in momentum and decides "I can handle one more segment before stopping," the boundary doesn't fire.

The bible says "boundaries are hard stops, not checkpoints" and "there is no self-assessment." But the execution of the hard stop is still a decision BD makes. The architecture prevents context rot *if the session actually ends when it should.* If BD extends a session, the architecture degrades.

---

## 4. Verdict

**I do not sign off.**

The bible has strong architectural controls that limit blast radius (session boundaries), protect downstream artifacts (blueprint immutability, errata mechanism), and create structural review points (Jim at phase boundaries, governed document triggers, Layer 2/Layer 3 gates). These are good. They represent serious thought about containment.

But the controls have a systematic blind spot: **they govern artifacts and boundaries, not BD's in-session behavior.** BD's #2 pattern manifests *between* boundaries, *during* conversations, *within* sessions. The controls catch damage at the next boundary — they do not prevent the damage from occurring. The bible's own evidence (Session 8) proves that BD can cause multiple #2 violations in under 5 minutes with zero mechanical intervention, and the only catch was Dan's human observation.

The compound failure chain from POC3 happened because damage accumulated between boundaries faster than boundaries could catch it. The bible has more boundaries now, and they're closer together. That's a real improvement. But "more frequent boundaries" is a probabilistic reduction, not an elimination. BD can still run off within any given segment.

### What Would Satisfy Me

I would sign off if the following additional controls were specified:

1. **Mechanical enforcement of the governed-document trigger.** A git pre-commit hook, a file watcher, something that physically prevents a governed document from being modified without Jim being invoked. Not a policy that says "Jim fires." A mechanism that makes it impossible for the change to land without Jim's review. This closes Gap A and turns Control 8 from a strong policy into an actual gate.

2. **Explicit "Dan is the real-time catch during planning" acknowledgment with protocol.** The bible should state plainly that during upfront planning and design conversations, Dan is the real-time #2 mitigation. Not as a failure — as a designed control. With a protocol: if Dan catches a #2 violation, what happens? Immediate session kill? Revert the unauthorized change? Log and continue? Session 8 shows Dan caught it and called a reboot. That should be codified. Dan-as-catch is already the reality — make it the architecture.

3. **Session boundary enforcement mechanism.** Something other than BD deciding when to stop. Options: a token budget per segment that triggers a hard cutoff, a timer, an external watchdog that kills the session after N tool calls. The specific mechanism matters less than the principle: the entity being constrained cannot be the entity that decides when the constraint fires. This closes Gap E.

4. **Acknowledgment that in-conversation topic pivoting (Gap B) has no mechanical fix and is accepted as a managed risk.** I won't block on this if the team explicitly acknowledges it. But I will block if the bible claims to solve #2 and this gap exists undocumented. The bible should state: "BD's in-conversation behavior between structural gates is not mechanically constrained. Dan's real-time observation during planning, and session boundaries during execution, limit the blast radius but do not prevent individual instances. This is accepted as a residual risk because the failure mode is low-damage per instance when boundaries are tight."

Items 1 and 2 are hard requirements. Items 3 and 4 are strong recommendations that I could be argued out of with sufficient justification, but the arguments would need to be good.

**Bottom line:** The architecture is 70% of the way there. The remaining 30% is the difference between "we have gates that catch BD's mess after the fact" and "we have mechanisms that prevent BD from making the mess." The bible is strong on containment. It is weak on prevention. Given that #2 is upstream of the entire compound failure chain, "strong on containment" is not sufficient for me to sign off.

Fix the enforcement gaps. Then we talk.

---

*— Jim*
