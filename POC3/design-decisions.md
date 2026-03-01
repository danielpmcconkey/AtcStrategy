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

---

## 20. Anti-Pattern Correction Mandate Added to Governing Documents

**Decision:** Updated both the blind lead's BLUEPRINT (Phase B) and the orchestrator runbook (Phase B monitoring) to include explicit anti-pattern correction requirements. The `KNOWN_ANTI_PATTERNS.md` reference doc already existed but was not referenced by either governing document.

**What happened:** Phase B completed with all 101 jobs producing V2 code that faithfully reproduced every V1 anti-pattern — integer division, double-precision money, magic values, unnecessary External modules, dead-end data sources. The BRDs had correctly identified and documented every anti-pattern, but Phase B agents treated those as documentation, not correction targets. This was the identical failure mode as POC2 Run 1, which was fixed in POC2 Run 2 with explicit instructions. The fix was not carried into the POC3 BLUEPRINT — a process failure.

**What changed:**

1. **BLUEPRINT Phase B** now includes:
   - Mandatory reference to `KNOWN_ANTI_PATTERNS.md` for all architects and developers
   - Explicit dual mandate: output equivalence AND anti-pattern elimination
   - Module hierarchy (Tier 1 framework-only → Tier 2 scalpel → Tier 3 last resort)
   - Clean code requirements for External modules regardless of tier

2. **Orchestrator Runbook Phase B** now includes:
   - Spot-check watchpoint for anti-pattern reproduction in V2 code
   - Specific things to look for (unnecessary External modules, integer division, magic values)
   - Verification that agents are referencing `KNOWN_ANTI_PATTERNS.md`

**Why this is logged:** This is a corrective action to governing documents mid-POC. For program governance, it's important to document that (a) we identified a gap in the instructions, (b) we traced the root cause to a blueprint omission rather than agent failure, (c) we updated the instructions before re-running Phase B, and (d) Phase A artifacts were preserved — only Phase B was reset. The agents did exactly what they were told; we told them the wrong thing.

**Production implication:** This is the strongest argument yet for a pre-launch blueprint review checklist. The anti-pattern correction mandate was a known requirement (POC2 proved it). It was documented in the lessons-learned file. It still got dropped from the POC3 BLUEPRINT because there was no mechanical check ensuring it was present. In a production deployment, a "blueprint completeness" gate — verifying that every lesson-learned entry has a corresponding blueprint instruction — would have caught this before launch, not after Phase B.

---

## 21. Saboteur Moved to Code Layer; Governance Gates Added Between All Phases

**Decision:** Two changes to the governing documents:

1. **Saboteur timing moved from A→B to B→C.** The orchestrator runbook's saboteur protocol now targets V2 processor code and job configs after Phase B completes, rather than BRDs after Phase A. Mutation types are the same (filter narrowing, threshold shift, rounding change, etc.) but applied to implementation artifacts instead of requirements documents.

2. **Governance gates added between every phase in the BLUEPRINT.** The blind lead must pause and wait for explicit human go-ahead before proceeding from any phase to the next. Previously only Phase A had a "STOP HERE" instruction.

**Why the saboteur moved:** BRD-level sabotage was proven ineffective in POC3 Run 1. FSD architects independently validated every BRD claim against V1 source code and caught all 13 mutations before they reached implementation (see Decision 5, observations log "Saboteur Findings" section, and lessons-learned entry "FSD Architects Self-Correct Against Source Code"). The saboteur's purpose is to stress-test Proofmark and the Phase D resolution loop — neither of which got exercised because the mutations never survived to Phase C. Planting mutations in V2 code after Phase B bypasses the BRD→FSD quality gate and puts sabotaged implementations directly into the comparison pipeline. This is a harder test: no architect to intercept, detection depends entirely on output comparison and resolution agent reasoning.

**Why governance gates:** The Phase B anti-pattern failure and the saboteur insertion both require the orchestrator to inspect and potentially modify artifacts between phases. A single gate after Phase A wasn't sufficient — the orchestrator needs a reliable pause point between every phase to: (a) run anti-cheat checkpoints, (b) execute the saboteur protocol at the correct time, (c) spot-check artifact quality before the next phase consumes them, and (d) consult with Dan on go/no-go. Without gates, the blind lead may barrel from Phase B into Phase C before the orchestrator has inspected Phase B output or inserted saboteur mutations.

**What changed:**
- **Orchestrator Runbook §2 (Execution Sequence):** Saboteur insertion block moved to between Phase B and Phase C. Phase D watchpoints updated to reference V2 code mutations instead of BRD mutations.
- **Orchestrator Runbook §3 (Saboteur Protocol):** Rewritten for code-level mutations. New objective, timing, selection criteria, mutation types, execution steps, and "what not to mutate" — all targeting V2 processors and job configs instead of BRDs.
- **BLUEPRINT:** "STOP HERE" governance gates added after Phase B, Phase C, and Phase D (Phase A already had one).

**Production implication:** Governance gates between phases are standard in any regulated change process. The real platform would have automated quality gates (build passes, test coverage thresholds, review approvals) plus human sign-off at phase boundaries. The POC's manual gates simulate this. The saboteur layer change demonstrates that adversarial testing must target the layer you actually want to validate — testing upstream of the quality gate you're evaluating is testing the gate, not the downstream process.

---

## 22. Half-Rollback: Preserve Phase A, Nuke Phase B, Commit Doc Fixes First

**Decision:** Before cleaning Phase B artifacts, commit the updated `BLUEPRINT.md` and new `KNOWN_ANTI_PATTERNS.md` to the MockEtlFramework repo. Then delete all Phase B artifacts (V2 processors, V2 job configs, FSDs, test plans, Phase B instruction files, stale session state, clutch file) and clean V2 job registrations from the database. Phase A artifacts (101 BRDs, reviews, analysis progress, discussions) are untouched.

**Why:** The BLUEPRINT.md in the working tree contains the corrected Phase B instructions (dual mandate, module hierarchy, build serialization, governance gates — Decisions 20 and 21). If we cleaned the working tree first (e.g., `git checkout .`), we'd revert the blueprint to its pre-fix state and re-introduce the exact failure that killed Run 1. Committing the doc fixes first locks them into git before the cleanup pass touches anything.

`KNOWN_ANTI_PATTERNS.md` is a new untracked file that the updated blueprint references. It must be committed alongside the blueprint or the blueprint's `KNOWN_ANTI_PATTERNS.md` references would point to nothing after cleanup.

**What survives:**
- All 101 BRDs in `POC3/brd/`
- All BRD reviews in `POC3/brd/*_review.md`
- `POC3/KNOWN_ANTI_PATTERNS.md`
- `POC3/logs/analysis_progress.md`
- `POC3/logs/discussions.md`
- Saboteur mutations still embedded in BRDs (inert — architects will catch them again per Decision 21's findings)

**What gets nuked:**
- All V2 processors (`ExternalModules/*V2*.cs`)
- All V2 job configs (`JobExecutor/Jobs/*_v2.json`)
- All FSDs (`POC3/fsd/`)
- All test plans (`POC3/tests/`)
- `POC3/PHASE_B_INSTRUCTIONS.md` (blind lead artifact from Run 1)
- `POC3/logs/session_state.md` (stale)
- `POC3/CLUTCH` (stale)
- V2 output in `Output/double_secret_curated/`
- V2 job registrations from `control.jobs`

**Production implication:** This is a controlled partial rollback — preserve the validated upstream artifacts, discard the failed downstream artifacts, fix the root cause in governing documents, and retry. In a real pipeline, this maps to "the requirements are good, the implementation was wrong because of bad instructions, fix the instructions and re-implement." The commit-before-cleanup ordering is basic change management: never destroy your fix while cleaning up the mess.

---

## 23. Covered Transactions Job Retained Despite Smoke Test History

**Decision:** Keep the covered_transactions job in the POC3 run (101 jobs, not 100). Do not remove its BRD, review, or saboteur mutation (#7).

**Context:** During Run 1, the orchestrator's pre-launch smoke test left a stale `CoveredTransactionProcessorV2.cs` in `ExternalModules/`, which confused the blind lead's Phase B (two competing V2 implementations with different naming conventions). The FSD produced was internally contradictory — traceability said "Checking/Savings" (matching the sabotaged BRD) but the design said "Checking only" (matching V1 code). The smoke test artifact was cleaned during Run 1 and both V2 artifacts were nuked in the half-rollback.

**Why retain:** The conditions that caused the Run 1 confusion no longer exist. The smoke test artifact is gone. There are no Phase B leftovers to collide with. The sabotaged BRD (mutation #7: Checking → Checking+Savings) is a free retest of the architect self-correction pattern documented in the lessons-learned file — we already know architects cross-reference BRDs against V1 source code and choose code as ground truth. Letting it ride costs nothing and adds a data point.

**What stays:**
- `POC3/brd/covered_transactions_brd.md` (with saboteur mutation #7 still embedded)
- `POC3/brd/covered_transactions_review.md`
- Saboteur ledger entry #7

**Risk assessment:** Low. The only prior problem was the smoke test artifact, which is gone. The sabotaged BRD is no different from the other 12 sabotaged BRDs that architects already handled correctly.

---

## 24. Batch Boundaries with Forced Context Refresh (Phase B)

**Decision:** Phase B now runs in batches of ≤20 jobs with a mandatory checkpoint between each batch. At each batch boundary, the blind lead must: (1) check for CLUTCH, (2) run `dotnet build`, (3) re-read governance sections of the BLUEPRINT, (4) update `session_state.md`. Additionally, concurrent subagents are capped at 10 maximum.

**What happened (Run 2):** The blind lead produced all 101 FSDs in a continuous run, then launched 3 batches of 10 reviewer agents (30 total, plus the architects that were likely still tracked in context — ~34 concurrent agents at peak) without checking for the CLUTCH file. The CLUTCH file had been placed at ~89% token usage. The standing order to check for it was present at BLUEPRINT line 77 but was not executed. The agent was deep in Phase B execution flow and the governance instruction had been displaced from working priority by operational momentum.

**Root cause:** Governance instructions at the top of a large document lose priority in the agent's working context over sustained execution. After 2+ hours of continuous operation (Phase A + Phase B), the ratio of governance context to operational context had shifted heavily toward operational. The CLUTCH check wasn't forgotten — it was deprioritized. See lessons-learned entries "Standing Orders Decay Over Long Runs" and "Long-Running Agents Need Forced Context Resets."

**What changed in BOTH governing documents:**

1. **BLUEPRINT (blind lead's doc):**
   - New "Batch Structure & Context Refresh" section with mandatory 5-step checklist at every batch boundary
   - New "Concurrency Cap" section (max 10 concurrent subagents)
   - Per-Job Pipeline header updated to reference batch limits

2. **Orchestrator Runbook:**
   - New "Batch boundary compliance watchpoint" under Phase B monitoring
   - Specific things to watch for: batch size, CLUTCH check compliance, session_state updates, concurrency cap, governance re-reads
   - Touchbase schedule updated to include Phase B batch boundaries (~5 touchbases)

**Why batches of 20:** 101 jobs ÷ 20 = ~5 batches. This gives 5 context refresh points during Phase B. Smaller batches (e.g., 10) would give more refresh points but add more ceremony. Larger batches (e.g., 30-50) don't provide enough refresh frequency — Run 2 demonstrated that a single continuous run of 101 is too long.

**Why cap at 10 concurrent subagents:** Run 2 spawned 34 concurrent architects. This is expensive on tokens, creates a large amount of operational context for the blind lead to track, and contributed to the governance priority decay. 10 concurrent subagents keeps throughput reasonable while limiting both resource consumption and context accumulation.

**Why forced re-read:** The context refresh is not a suggestion — it's a mandatory re-read of specific BLUEPRINT sections. This mechanically re-promotes governance instructions in the agent's attention hierarchy. Without it, the batch boundary is just a pause, not a reset. The re-read is what makes it a governance checkpoint, not just a build checkpoint.

**Production implication:** Batch boundaries with governance re-reads are the manual equivalent of what a production system would do with automated policy enforcement. In production, the orchestration layer would programmatically verify governance compliance at each checkpoint. In a POC with agent-driven execution, the best available mechanism is instructing the agent to re-read its own rules. The lesson for the CIO: long-running autonomous processes need structural breaks, not just standing orders.
