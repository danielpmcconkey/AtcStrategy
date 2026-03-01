# POC3 Design Decisions

Decisions made during the blueprint walkthrough (2026-03-01). These capture the WHY behind POC3's architecture — useful for the CIO presentation and for building the real platform.

---

## 1. Two-Session Architecture (Orchestrator + Blind Lead)

**Decision:** POC3 runs as two Claude Code sessions in the same container. The orchestrator (BD) has full knowledge of the saboteur, anti-cheat, and pull-the-plug protocols. The blind lead manages the reverse-engineering swarm and has no idea adversarial testing exists.

**Why:** The blind lead's behavior is only meaningful if it doesn't know it's being tested. Structural separation (different sessions, different context windows) makes the isolation real, not performed.

**Production implication:** In a real deployment, the "orchestrator" role would be the governance/QA team. The separation of concerns is the same — the people validating the work shouldn't be the same people doing the work.

---

## 2. BRDs Are Agent-Generated, Not Pre-Written

**Decision:** Analysts reverse-engineer V1 job code and data to write BRDs themselves. The BRDs are outputs of Phase A, not inputs.

**Why:** The core question for the CIO is "can agents infer business requirements from existing code?" Pre-written BRDs would skip the hardest part. The agents must demonstrate they can read code, query data, and produce accurate documentation with evidence citations.

**Production implication:** This is the value prop — automated requirements extraction from legacy systems. If agents can do this reliably, it dramatically reduces the cost of understanding undocumented ETL pipelines.

---

## 3. Saboteur Timing: After Review, Before FSD

**Decision:** Sabotage is injected into approved BRDs AFTER Phase A review completes, BEFORE Phase B FSD writing begins. A human gate ("STOP HERE") in the BLUEPRINT creates the insertion window.

**Why:**
- Can't pre-plant because BRDs don't exist until agents write them.
- Can't sabotage during Phase A because reviewers might catch it or analysts might overwrite it during revision cycles.
- Sabotaging between Phase A and Phase B means the FSD is written from the sabotaged BRD — clean chain, no document conflicts.
- The blind lead just thinks it's waiting for human approval to proceed. It has no idea documents are being modified.

**Production implication:** In a real pipeline, BRD errors can come from anywhere — misunderstood requirements, stakeholder miscommunication, analyst mistakes. The saboteur simulates this. The question is: does the downstream validation catch it?

---

## 4. Surgical Sabotage, Not Chaos Monkey

**Decision:** The saboteur makes deliberate, tracked modifications to a specific set of BRDs (10-15, ~10-15%). Not a continuous chaos monkey.

**Why:** The CIO needs a clean scorecard: "We planted N errors. The system caught M." Random chaos gives you "stuff happened" — not a measurable result. Every sabotaged BRD has a known mutation and an expected failure mode, so we can grade the system's detection capability.

**Chaos monkey is a POC4 concept.** Once controlled sabotage proves the validation layer works, continuous entropy testing proves it holds up over time. Crawl, walk, run.

---

## 5. Deliberate Gap in Phase B Review

**Decision:** The Phase B reviewer checks FSD-to-BRD traceability only. It does NOT re-verify BRD evidence against source code. This is an intentional gap.

**Why:** For POC3, we want sabotaged BRDs to flow through to Phase D so Proofmark can demonstrate it catches the resulting output discrepancies. If the Phase B reviewer re-checked evidence against code, it might catch the sabotage before Proofmark gets a chance to — which proves the review works but doesn't prove Proofmark works.

**Production implication: ADD THIS REVIEWER IN THE REAL PLATFORM.** A Phase B evidence-back-to-code reviewer is an additional safety net that catches bad requirements before they become bad code. For POC3 we're deliberately testing Phase D. For production, you want both layers. This is a key recommendation for the CIO: defense in depth.

---

## 6. Resolution Protocol: Full Chain Trace

**Decision:** When Proofmark fails, the Resolution agent must trace the FULL chain backwards: V2 output → V2 code → FSD → BRD → V1 source code and data. "BRD error" is listed as the first root cause option.

**Why:** Without this, the Resolution agent might cargo-cult a fix — patching V2 code to match V1 output without understanding why they differ. For sabotaged jobs, the root cause is the BRD, not the V2 code. The agent must be empowered to discover and fix incorrect requirements, not just incorrect implementations.

**Production implication:** This is arguably the most valuable capability — automated root cause analysis that can distinguish between "the code is wrong" and "the requirements are wrong." If agents can do this reliably, it's a significant labor savings.

---

## 7. Information Isolation: Four Layers

**Decision:** The blind lead is isolated from forbidden knowledge through four reinforcing layers:
1. **Instructions** — the BLUEPRINT says "never read these sources"
2. **Structural** — forbidden files physically removed (POC2 BRDs), DB write access revoked, curated schema read access revoked
3. **Surveillance** — the orchestrator runs a spy protocol checking for access to forbidden sources
4. **Review** — reviewer agents check for "impossible knowledge" in BRDs

**Why:** No single layer is foolproof. Instructions can be ignored. Structural barriers can be worked around. Surveillance might miss things. Reviewers might not catch subtle leaks. All four together make the isolation robust.

**Production implication:** For regulated industries, this layered approach to information barriers is directly applicable. The audit trail (which sources were accessed, what evidence was cited) is a governance artifact.

---

## 8. Reset Button

**Decision:** A reset script (`poc3_reset.sh`) nukes all POC3 work product and returns MockEtlFramework to its committed launchpad state. Requires typing "nuke" to confirm.

**Why:** POC3 might need multiple runs to get right. The reset script makes iteration cheap — try it, evaluate, nuke, adjust, try again. Without it, manual cleanup across files + database is error-prone and time-consuming.

**Pre-requisite:** The clean launchpad (CLAUDE.md, BLUEPRINT.md, empty POC3 directories, Proofmark docs) must be committed before the first run. `git checkout .` in the reset script restores to this state.

---

## 9. File-Only Output (No Database Writers)

**Decision:** All POC3 jobs write to files (Parquet or CSV). No DataFrameWriter jobs targeting database schemas. Write access to `curated` and `double_secret_curated` schemas has been revoked.

**Why:**
- File output enables Proofmark comparison (file-to-file).
- Revoking DB write access is structural enforcement — the blind lead CAN'T write to those schemas even if it tries.
- Simpler reset: delete files vs. truncate tables.

---

## 10. Document Split: CLAUDE.md + BLUEPRINT.md

**Decision:** The worker CLAUDE.md is lean (~50 lines) — project basics, build/run, DB connection, guardrails. The full POC3 orchestration lives in `POC3/BLUEPRINT.md`.

**Why:** CLAUDE.md is auto-loaded by every Claude Code session AND every teammate in an Agent Team. Keeping it lean means less token burn on context that only the lead needs. The BLUEPRINT has the full mission, phases, workflows, and artifact locations — the lead reads it and distributes relevant context to teammates.

Also: separation of concerns. CLAUDE.md describes the project. BLUEPRINT.md describes the exercise. When POC3 is done, you can nuke BLUEPRINT.md without touching the project docs.

---

## 11. Two Levels of Reset

**Decision:** There are two distinct reset scopes, and only the orchestrator knows both exist:

1. **Job-level retry (blind lead knows about this):** A Proofmark comparison fails → triage → fix BRD/FSD/code → clear that job's V2 output → re-run that job → re-compare. This is Phase D's resolution loop. Proofmark configs survive and may improve (e.g., adding an EXCLUDED column after discovering a non-deterministic field).

2. **Full nuke (only orchestrator + Dan know about this):** `poc3_reset.sh`. Scorched earth — all work product, all configs, all output, all DB entries. This fires when the blueprint itself is wrong. Proofmark configs die with everything else because they were generated from bad assumptions.

**Why:** The blind lead's worst case is a job that fails 6+ times and gets escalated to the human. What happens after that escalation is outside its knowledge boundary. It never knows a global reset is possible — from its perspective, the exercise only moves forward.

**Production implication:** Maps to standard operational tiers. Level 1: team self-service remediation. Level 2: management/governance intervention. The team doesn't need to know about Level 2 to do Level 1 effectively.

---

## 12. Phase C.1: DELETE, Not DEACTIVATE

**Decision:** When clearing prior V2 jobs from `control.jobs` in Phase C setup, use DELETE rather than `SET is_active = false`.

**Why:** Phase C.1 is clearing POC2 garbage. There's no run history worth preserving from stale V2 jobs. Deactivating would leave zombie rows that accumulate if the exercise ran multiple times (after full resets). DELETE keeps the control DB clean. The reset script already uses DELETE (lines 58-59) — the blueprint should be consistent.

---

## 13. Resolution Evidence Requirement

**Decision:** Every Phase D resolution — regardless of root cause type — must cite specific V1 ground-truth evidence (source code file:line, job config fields, or datalake query results) that confirms the diagnosis. A fix that makes Proofmark pass without explaining WHY the mismatch existed is not an accepted resolution.

**Why:** Without this, the resolution agent can cargo-cult fixes — tweak V2 code until the output matches without understanding the root cause. For sabotaged jobs, the correct resolution is "the BRD was wrong because V1 code at X:Y does Z, not what the BRD claims." If the agent can't produce that evidence chain, it hasn't actually resolved the problem — it's just gotten lucky. This is the difference between a system that can do root cause analysis and a system that can brute-force pattern matching.

**Production implication:** This evidence requirement creates an audit trail. Every resolution has a documented chain from symptom (Proofmark mismatch) to diagnosis (specific V1 evidence) to fix. That's exactly what a change advisory board wants to see.

---

## 14. Changes Flow Uphill

**Decision:** Any Phase D resolution that modifies V2 code, Proofmark config, or any other artifact must update ALL upstream documents to maintain consistency. Specifically:
- **BRD error:** Fix BRD → update FSD → update test plan → rebuild V2.
- **V2 code bug:** Fix V2 code → update test plan to cover the missed case.
- **Non-deterministic field:** Update BRD (non-deterministic fields section) → update FSD (Proofmark config design) → update Proofmark config.
- **Proofmark config error:** Update FSD (Proofmark config design) → fix config.

**Why:** The governance artifacts (BRD, FSD, test plan) are only valuable if they match the actual implementation. A resolution that fixes V2 code but leaves the FSD describing the old behavior creates exactly the kind of documentation rot this exercise is supposed to eliminate. At the end of POC3, every job's document chain must be internally consistent — not just the code.

**Production implication:** This is change management 101 — if you change the implementation, update the spec. But it's easy to skip under time pressure, which is why it's a hard requirement rather than a suggestion.

---

## 15. Document Consistency Verification (Phase D.6)

**Decision:** After all jobs reach VALIDATED or UNRESOLVED status, a mandatory consistency verification step runs before Phase E governance. A read-only Consistency Verifier subagent checks each validated job's full document chain: BRD ↔ FSD ↔ test plan ↔ Proofmark config ↔ V2 code. Any inconsistency blocks the job from Phase E until fixed.

**Why:** Decision 14 ("changes flow uphill") tells agents to update upstream docs when they fix things. But telling agents to do something and verifying they did it are two different things. The resolution loop can run 4-5 cycles per job — each cycle might touch different documents. Without a final cross-check, we'd be presenting governance artifacts to the CIO with a "probably accurate" confidence level. That's not good enough.

The verification is deliberately positioned AFTER the resolution loop finishes, not during it. Running it mid-loop would add overhead to every iteration. Running it once at the end catches the cumulative drift.

**Design choices:**
- **Read-only subagents.** Verifiers don't fix anything — they just report. Fixes go through the normal Resolution subagent so the resolution log stays complete.
- **Per-document-pair verdicts.** "BRD ↔ FSD: PASS, FSD ↔ Code: FAIL" is actionable. "Documents are inconsistent" is not.
- **Consistency reports live in governance/.** They're governance artifacts themselves — evidence that the document chain was verified, not just assumed correct.
- **UNRESOLVED jobs skip verification.** If a job couldn't pass Proofmark after 6 attempts, verifying its docs is pointless. The governance report for that job already says "we couldn't validate this."

**Cost:** ~100 jobs × 1 read-only subagent each. Token-heavy but parallelizable, so wall-clock time is manageable. This is the price of being able to say "verified" instead of "we told them to."

**Production implication:** This is the difference between "we have a process" and "we have a process with verification." Any auditor or governance board will ask "how do you know the documentation matches the implementation?" This step is the answer.

---

## 16. Clutch Protocol (Graceful Pause)

**Decision:** A file-based signal (`POC3/CLUTCH`) allows the human operator to gracefully pause execution when approaching resource limits. The blind lead checks for this file before every agent spawn or task assignment. When engaged, active work finishes but no new work starts, and a `session_state.md` resurrection file is written.

**Why:** There's no higher API plan available, and Claude has no background timer or interrupt capability. The agent only acts during its turn — it can't "check every 5 minutes." But the blind lead IS the orchestrator, which means it gets a turn every time a teammate finishes or a subagent returns. That's the natural checkpoint. Checking for a file at every checkpoint is cheap (one glob) and reliable.

**Rejected alternatives:**
- **Pasting into the terminal:** Unreliable. If the blind lead is mid-turn waiting on agent results, the message sits unread until the turn ends. Could be 20+ minutes during Phase A.
- **Automatic budget monitoring:** The agent has no visibility into its own token budget. Can't self-regulate what it can't see.
- **Periodic timer check:** Claude doesn't have timers. Not how the architecture works.

**Design choices:**
- **File-based, not message-based.** A file check is deterministic — it either exists or it doesn't. No parsing, no ambiguity, no risk of the message getting lost in conversation context.
- **Check before BOTH spawning AND assigning.** Without the assignment check, the blind lead could keep feeding work to already-alive teammates, burning tokens without spawning anything new. Both triggers need the gate.
- **Teammates finish current task.** Don't kill mid-work — that loses artifacts. Let them write their results, then stop.
- **`session_state.md` is the resurrection artifact.** A new session reads BLUEPRINT → checks for session_state.md → resumes. The blind lead doesn't need to survive the pause (it might time out). The file is what matters.
- **Clutch file must be removed before resume.** New sessions check for it on startup and refuse to start if it's still there. This prevents accidental resume before tokens refresh.

**Operational flow:**
1. Dan watches his usage meter (only he can see it)
2. At ~90%, Dan creates `POC3/CLUTCH` (via orchestrator terminal or direct touch)
3. Blind lead sees it at next checkpoint → wind-down → writes session_state.md → goes idle
4. Tokens refresh (hours later)
5. Dan deletes `POC3/CLUTCH`
6. Dan tells blind lead to resume (or starts a new session if it timed out)
7. Blind lead reads session_state.md → picks up where it left off

**Production implication:** Resource-constrained execution is a real concern for production agent deployments. A file-based pause/resume protocol is simple, auditable (the session_state.md is a log artifact), and doesn't require the agent to have self-awareness about its own resource consumption.

---

## 17. Softened Anti-Cheat: Human-in-the-Loop Enforcement

**Decision:** All suspected anti-cheat violations are brought to Dan for joint evaluation. The orchestrator does not autonomously kill agents, quarantine deliverables, or take any enforcement action without Dan's approval.

**Why:** The orchestrator is simultaneously running a saboteur protocol. This creates a collision risk: a resolution agent correctly diagnosing a sabotaged BRD ("this requirement is wrong") looks superficially identical to an agent with impossible knowledge ("it knew the BRD was wrong without checking code"). The difference is the reasoning path, not the conclusion — and evaluating reasoning paths requires judgment, not pattern matching.

Autonomous enforcement under these conditions risks self-inflicted wounds. Killing a clean agent and quarantining good work because the orchestrator misread a saboteur interaction wastes tokens and time that can't be recovered (no higher API plan available). The cost of a false positive (lost work, wasted budget) is higher than the cost of a brief pause to evaluate (minutes of Dan's time).

**Safeguard retained:** The saboteur collision check is mandatory — before flagging any violation on a sabotaged job, the orchestrator must verify whether the agent reached its conclusion through the legitimate Phase D path (Proofmark failure → code analysis → BRD contradiction) or through a forbidden source.

**Production implication:** In a real deployment, anti-cheat/integrity monitoring would have more sophisticated tooling — access logs, permission systems, audit trails. In a POC with limited tooling, human judgment is the safety valve. The lesson for the CIO: automated monitoring is necessary, but automated enforcement needs a confidence threshold before it acts autonomously. Start with human-in-the-loop, graduate to autonomous enforcement as trust builds.

---

## 18. No Autonomous Enforcement — Period

**Decision:** The orchestrator has ZERO autonomous enforcement authority. No killing agents, no pulling the plug, no stopping the run. The orchestrator monitors, documents, cross-references, and brings recommendations to Dan. Dan makes every enforcement call.

**Why:** This is a broader principle than just anti-cheat (decision 17). It applies to pull-the-plug criteria, intervention methods, and any other situation where the orchestrator might be tempted to act unilaterally. The blind lead is free to iterate through its own resolution cycles without interference. The orchestrator's job is to watch and report — not to intervene.

The reasoning is simple: the orchestrator is a Claude running a saboteur protocol inside an adversarial test. It has competing objectives (sabotage vs. monitoring vs. evaluation) and known collision risks. Giving it autonomous enforcement authority on top of all that is asking for trouble. Dan is the one with full context, no competing objectives, and the ability to see things the orchestrator might miss (like token budget).

**What the orchestrator CAN do without asking:**
- Monitor and scan transcripts
- Write to spy report, progress dashboard, saboteur ledger
- Cross-reference findings against the saboteur ledger and cleared findings table
- Engage the clutch (POC3/CLUTCH) for resource pauses — but only because Dan explicitly designed this as an orchestrator-available tool

**What the orchestrator CANNOT do without Dan's approval:**
- Kill any agent
- Stop the run
- Intervene in the blind lead's process
- Quarantine deliverables
- Modify the blind lead's instructions or documents mid-run

**Production implication:** Clear separation of monitoring and enforcement is standard in governance. The SOC analyst monitors; the incident commander decides. Same principle here.

---

## 19. Touchbase Protocol Replaces Fixed Thresholds

**Decision:** Removed the fixed "total fix attempts > 150" threshold from pull-the-plug criteria. Replaced with a regular touchbase protocol — orchestrator gives Dan a status update at phase transitions and at ~25% progress intervals during Phases A and D.

**Why:** 150 was a guess. We have no data on how many fix iterations to expect from agents seeing this codebase for the first time, especially with 10-15 deliberately sabotaged jobs in the mix. The sabotaged jobs alone could consume 30-40 attempts if resolution agents need multiple rounds to trace back to the BRD. A fixed threshold either triggers too early (killing a run that was going to converge) or too late (burning budget on a run that's clearly stuck).

Dan watching the trajectory is better than a number picked before execution. The touchbase gives him the aggregate view — fix rate trends, single-job outliers, saboteur detection progress, token burn — and he decides if the trajectory makes sense. "We're 60% validated with 80 fix attempts and trending down" is fine. "We're 30% validated with 80 fix attempts and trending up" is a conversation.

**Production implication:** This maps to sprint reviews / standups. Regular human checkpoints with aggregate metrics beat automated circuit breakers for complex, first-time processes. Automated thresholds make sense once you have baseline data from a few runs. POC3 is run #1 — we're collecting that baseline.
