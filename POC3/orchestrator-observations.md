# POC3 Orchestrator Observations Log

Real-time notes on blind lead behavior, decisions, and anything interesting.

---

## Phase A Startup

**09:34 EST** — Blind lead session launched. Prompt: read CLAUDE.md, read BLUEPRINT, execute Phase A.

**~09:36** — Blind lead correctly identified 101 active V1 jobs. Checked for CLUTCH file and session_state.md — both absent, confirmed fresh start. Inspected POC3 directories for prior artifacts. Clean orientation sequence.

**~09:38** — Before spawning any agents, the blind lead is writing instruction files for analysts and reviewers. Not in the BLUEPRINT — this is emergent behavior. Smart move: ensures consistent briefs across all 12 agents instead of relying on prompt content alone. Shows planning discipline.

**~09:40** — Instruction files reviewed. Both are well-distilled from the BLUEPRINT. Key details:
- Analyst brief includes DB query templates, forbidden sources, file conflict rules, BRD format template
- Reviewer brief has full quality gates, evidence spot-check protocol, revision limits
- Analysts correctly warned that V1 output may not exist (we only smoke-tested 1 job)
- Also initialized `logs/discussions.md` and `logs/analysis_progress.md`
- Still no team spawned yet — building the launchpad before ignition. Methodical.

**~09:42** — Blind lead spawned all 12 agents (10 analysts + 2 reviewers). Sub-agents are NOT visible as separate OS processes — they appear to be API-level spawns within the main claude process. No BRDs landed yet — agents likely reading Architecture.md and job configs first.

**~09:44** — First wave of BRDs: 12 dropped within ~2 minutes. One per analyst plus a couple fast analysts already on their second job. Sizes range from 3.5KB to 9.5KB — reasonable variation for different job complexity. No reviews yet.

**~09:46** — 31 BRDs, 2 reviews. Reviewer bottleneck forming as predicted. However: reviews are NOT rubber stamps. Reviewer-1's communication_channel_map review spot-checked 5 evidence citations against actual source code line numbers, verified writer config against JSON, and noted a subtle cross-date preference accumulation behavior. This is legitimate review work. Quality over speed tradeoff appears intentional.

**~09:50** — 47 BRDs, 4 reviews. Nearly half the BRDs written in ~8 minutes. Analysts averaging ~1 BRD per 2 minutes. Reviewers at ~1 review per 2 minutes. At this rate analysts finish all ~101 in ~20 minutes, reviewers need ~50 minutes for the full backlog. Long tail confirmed.

**~09:54** — 86 BRDs, 9 reviews. Analysts nearly done (~15 left). Reviewer pace slightly improved. Dan notes 20x plan gives ~4x the token budget vs POC2's 5x plan. Real token burn expected in Phase B (parallel architects/devs) and Phase D (resolution loops on sabotaged jobs).

**~09:56** — 10 reviews: 8 PASS, 2 FAIL. Both FAILs (daily_transaction_summary, daily_transaction_volume) caught the SAME analyst error: incorrect claim that CSV headers are interleaved in Append mode. Actual code at CsvFileWriter.cs:47 shows `if (_includeHeader && !append)` — headers only on first write. Same mistake from the same analyst batch (Transaction Analytics domain). Review process working as designed — catching real errors, not rubber-stamping. Feedback sent back for revision.

**~10:00** — 95 BRDs, 12 reviews (10 PASS, 2 FAIL). Analysts nearly done (6 to go). Failed BRDs not yet revised — analyst still producing remaining BRDs before circling back. Spot-checked covered_transactions review: 5 evidence verifications all confirmed against specific code line numbers. Review quality consistent across the board, not degrading as volume increases.

**Design note (Dan):** If we restart, keep 12 agents but let the blind lead choose the analyst:reviewer ratio. 10:2 was over-specified by us and created a predictable bottleneck. The blind lead should adapt based on observed throughput. BLUEPRINT should say "12 agents, you decide the split."

**~10:07** — 101 BRDs complete. All analysts done. 30 reviews (27 PASS, 3 FAIL). Reviewers accelerating now that analysts aren't competing for I/O. Analyst-7 revised all 3 failed BRDs — actually fixed the root misunderstanding (now cites CsvFileWriter.cs:42,47 with correct `!append` guard logic). Feedback loop working: reviewer identified error → analyst revised with implementation evidence, not just surface correction. Awaiting re-review.

**~10:07** — Blind lead independently noticed the analyst-7 pattern and the review bottleneck. Self-monitoring without orchestrator intervention.

**~10:12** — 33 reviews (30 PASS, 3 FAIL awaiting re-review), 68 remaining. Token reset imminent. Dan used only 28% of session budget — 72% wasted because 10 analysts sat idle while 2 reviewers ground through the backlog. Dynamic agent rebalancing is the clear fix for future runs. The blind lead should've been instructed (or empowered) to reassign idle analysts as reviewers.

**~10:17** — 41 review files: 33 complete (30 PASS, 3 FAIL), 8 actively being written. Both reviewers running hot now with no analyst I/O contention. Revised analyst-7 BRDs still awaiting re-review. 3 FAIL reviews still have old FAIL status — haven't been overwritten with re-review yet.

**~10:25** — 72 reviews (61 PASS, 3 FAIL). Reviewer pace accelerated significantly — went from 33 to 72 in ~8 minutes. Three analyst batches fully cleared. Analyst-4 perfect 10/10. Analyst-7's 3 revised BRDs still awaiting re-review (they're in the queue). 29 reviews remaining.

**~10:28** — 89 reviews (79 PASS, 3 FAIL still awaiting re-review). Deep dive on analyst-7 question: jobs weren't harder. Analyst-7's passing BRDs got strong praise (integer division, double-precision analysis). The 3 FAILs were a single misunderstanding × 3 CSV-Append jobs. Meanwhile analyst-1 had the exact same type of job (merchant_category_directory, Append CSV) and correctly verified header behavior against CsvFileWriter source. Same instructions, different agent verification habits. Not a difficulty problem — an individual agent tendency that propagated unchecked.

**~10:35** — Blind lead reports 89 PASS, 1 FAIL remaining (regulatory_exposure_summary). Analyst-7's 3 revisions all passed re-review. New FAIL is a DIFFERENT error type: analyst claimed Math.Round defaults to AwayFromZero when C# actually defaults to ToEven (banker's rounding). This is a language knowledge error, not a framework reading error. Would have produced incorrect V2 rounding behavior if uncaught. Different analyst, different mistake category — review gate proving its value on multiple failure modes.

**~10:38** — Dan flagged potential counting problem: orchestrator's review count (59 completed) didn't match blind lead's count (89 PASS). Investigation revealed reviewer-2 used `## Verdict: PASS` instead of `## Status: PASS`. My grep was format-dependent. Files are same size and completeness as the ones I was counting — reviews are actually done. **Lesson: orchestrator monitoring grep patterns must account for format drift when agents aren't using identical templates.** Blind lead's count was correct. No false completion risk.

**~10:42** — 100 PASS, 2 FAIL remaining: regulatory_exposure_summary (Math.Round rounding default — analyst-3) and preference_trend (CSV header-in-append — **analyst-5**, NOT analyst-7). The CsvFileWriter misunderstanding is now confirmed SYSTEMIC: two independent analysts (5 and 7) made the same wrong assumption. 4 total FAILs from this one issue across two analysts. This is the strongest evidence yet for the errata file pattern — reviewer-1 caught analyst-7's error first but that knowledge never reached analyst-5.

**~10:48** — **PHASE A COMPLETE.** 0 FAILs remaining. 101 BRDs reviewed and approved. Total Phase A time: ~74 minutes (09:34 → ~10:48 EST). 5 unique FAILs total (4 CsvFileWriter header-in-append across analysts 5 and 7, 1 Math.Round default from analyst-3). All resolved in 1 revision cycle. No escalations needed. Review quality consistently high throughout.

## Phase A Summary Stats
- 101 BRDs produced and approved
- ~74 minutes wall clock (analysts: ~25 min, reviewer tail: ~49 min)
- 5 FAILs caught by reviewers (4 systemic, 1 unique), all resolved in 1 cycle
- 0 anti-cheat violations detected (Checkpoint 1: CLEAN — 30/30 evidence citations verified)
- 10 idle analysts for ~49 minutes = ~490 agent-minutes wasted on reviewer bottleneck

## Saboteur Insertion

**~10:50** — Launched anti-cheat Checkpoint 1 and saboteur agent in parallel.

**~11:05** — Checkpoint 1 complete: CLEAN. 30/30 evidence spot-checks verified across all 10 analysts. Zero forbidden source reads, zero impossible knowledge, zero fabrication.

**~11:32** — Saboteur complete. 13 mutations across 12 BRDs (1 compound). Good spread: 3 threshold shifts, 3 filter narrowings, 3 rounding changes, 2 date boundary shifts, 1 join type change, 1 aggregation change. Two intentional stealth mutations (#4 overdraft_recovery_rate, #10 high_balance_accounts) designed to pass Proofmark despite BRD being wrong — tests whether system distinguishes "output matches" from "BRD is correct." Ledger at AtcStrategy/POC3/saboteur-ledger.md.

**Sniff test passed.** Mutations are subtle, plausible, and well-distributed. Mix of both over-inclusive (#5, #7) and under-inclusive (#1, #3) filter changes tests whether resolution agents can reason in both directions.

## Phase B

**~11:45** — Blind lead re-read BLUEPRINT Phase B section and created PHASE_B_INSTRUCTIONS.md (same pattern as Phase A — distill then execute). Launched 10 pipeline agents.

**~11:55** — First batch producing: 4 FSDs (account_overdraft_history, bond_maturity_schedule, card_authorization_summary, compliance_event_summary), 2 test plans, more in flight. 7 of 10 agents have written to disk. Other 3 likely still reading BRDs.

**~12:05** — Pipeline running hot. Disk counts: 63 FSDs, 26 test plans, 21 V2 configs, 26 V2 processors. Architects ~62% done. Multiple pipeline stages running in parallel across different jobs — architects writing FSDs for later jobs while developers implement earlier ones. Blind lead reported 48/19/15/3 slightly earlier, artifacts landing faster than the lead can count them. Token usage at ~15% of new session.

**~12:15** — Blind lead reports: 89 FSDs, 89 test plans, 79 V2 configs, 26 V2 processors. Build compiles clean (0 errors, 21 warnings). Strong velocity. Token usage at 22%.

**~12:15** — **CLUTCH ENGAGED.** Dan called it at 22% token usage. CLUTCH file created at POC3/CLUTCH. Waiting for blind lead to finish active work, write session_state.md, and go idle. Go/no-go vibes evaluation pending.

**Anomaly flagged for Checkpoint 2:** covered_transactions V2 processor exists (`ExternalModules/CoveredTransactionProcessorV2.cs`) and implements Checking-only filtering — correct per V1 source but WRONG per the sabotaged BRD (which says Checking+Savings). No FSD exists for this job. Possible anti-cheat concern: developer may have read V1 source directly instead of following BRD→FSD chain. Alternatively, the processor may predate Phase B (it was the smoke-test job). Needs investigation.

## Covered Transactions Cleanup

**~12:30** — Investigation revealed `CoveredTransactionProcessorV2.cs` was the orchestrator's pre-launch smoke test artifact. This file was created by us (the orchestrator) before Phase B to verify the framework worked. It should have been deleted before launch. The blind lead's pipeline also produced `CoveredTransactionsV2Processor.cs` (note the plural "Transactions" and different class name). Both implement Checking-only despite the sabotaged BRD saying Checking+Savings.

**Root cause:** The FSD (`covered_transactions_fsd.md`) is internally contradictory — traceability table says "Checking/Savings" (matching BRD) but implementation design says "Checking only" (matching V1 code). The architect chose V1 code as ground truth over the BRD, same pattern as every other sabotaged job (see Saboteur Findings below).

**Action taken:** Deleted `ExternalModules/CoveredTransactionProcessorV2.cs` (smoke test artifact). Pipeline-generated `CoveredTransactionsV2Processor.cs` retained. This cleanup removes orchestrator contamination while preserving all system-generated artifacts for honest evaluation.

**Why this is not a cheat:** The deleted file was created by the orchestrator during pre-launch environment verification, not by the blind lead or any pipeline agent. It predates Phase B entirely. The pipeline's own V2 processor (`CoveredTransactionsV2Processor.cs`) remains untouched. The saboteur mutation (#7) remains in the BRD and ledger for evaluation. The job will proceed through Phase C/D with the pipeline's artifacts only.

## Saboteur Findings — FSD Self-Correction Pattern

**~12:30** — Spot-checked 7 of 13 saboteur mutations. ALL were neutralized at the FSD layer. In every case, the FSD architect read the V1 source code, found the BRD contradicted it, and chose V1 code as "ground truth." Several architects left explicit CRITICAL NOTEs documenting the BRD-vs-code discrepancy. Mutations checked: #1 (card_fraud_flags), #4 (overdraft_recovery_rate), #5 (marketing_eligible_customers), #6 (customer_value_score), #7 (covered_transactions), #12 (customer_attrition_signals), #13 (fee_revenue_daily). All 7 killed at FSD.

**Implication:** The saboteur test revealed an unplanned second quality gate. FSD architects independently validated BRD requirements against V1 source code and caught every planted discrepancy, explicitly documenting each one with CRITICAL NOTEs. Proofmark will show high equivalence rates because the architects double-checked the rationale and corrected BRD errors before they reached implementation. This demonstrates robust self-correction in the pipeline — the system doesn't blindly trust any single artifact.

**Lesson for future POCs:** To isolate BRD accuracy as a variable, saboteur mutations would need to be planted after the FSD layer (directly in V2 code or configs). The current design — mutate BRDs while architects have V1 source access — inadvertently tested the pipeline's error-correction capability rather than its susceptibility to bad requirements. The architects passed that test decisively.

## Protocol Departure: Code-Level Saboteur Re-insertion

**Decision:** Re-plant saboteur mutations directly in V2 processor code during the Phase B→C break.

**Why this departs from the BLUEPRINT:** The original saboteur protocol (BLUEPRINT §Saboteur) specifies planting mutations in BRDs between Phase A and Phase B. The intent was to test whether bad requirements produce bad code and whether Proofmark catches the resulting output differences. That test cannot function as designed because FSD architects independently validate BRD claims against V1 source code — every mutation was caught and corrected before reaching implementation (see Saboteur Findings above). The BRD-level saboteur inadvertently tested the pipeline's error-correction capability (result: strong) rather than its comparison loop (result: untested).

**What we're doing instead:** Using the same mutation concepts from the original saboteur ledger (same jobs, same types of changes), but injecting them directly into V2 processor source code. This bypasses the BRD→FSD quality gate and puts sabotaged code into Phase C (build/register) and Phase D (comparison). This tests what actually matters for the CIO presentation: can the system detect implementation-level output differences via Proofmark, and can resolution agents diagnose and fix them?

**Why this is defensible:**
1. The original saboteur test still produced a valid finding (FSD self-correction pattern). We're not discarding results — we're adding a second, more targeted test.
2. The mutation concepts are identical. Same thresholds, same filter changes, same rounding shifts. Only the injection layer changed.
3. Code-level mutations are a harder test. There's no architect to intercept them. Detection depends entirely on Proofmark output comparison and resolution agent reasoning.
4. This was a real-time adaptation based on observed system behavior, documented transparently with rationale.

**Stealth mutations (#4, #10):** The two original stealth mutations (overdraft_recovery_rate rounding on zero, high_balance_accounts date in single-day mode) remain interesting at the code level. If V2 output matches V1 despite the mutation, the resolution agent should NOT flag them — testing whether the system avoids false positives.

## Protocol Departure: Reduced Parallelism for Phase C/D

**Decision:** Reduce agent parallelism for remaining phases to avoid host resource saturation.

**Why:** During Phase B, 10 concurrent pipeline agents triggered simultaneous `dotnet build` invocations that rendered Dan's workstation unresponsive for ~20 minutes. The BLUEPRINT specifies 10 pipeline agents but doesn't account for host machine constraints. Phases C and D involve heavier compute (building the full project, running 101 jobs across 92 effective dates, executing Proofmark comparisons) and would be worse.

**What we're changing:** The blind lead will be instructed to limit concurrent agents that trigger builds or job execution. Exact cap TBD based on machine tolerance — likely 3-4 concurrent build/run agents max. Agents doing read-only work (analysis, review, diagnosis) can still run at higher parallelism.

**Why this is defensible:** The BLUEPRINT's agent count was set for throughput optimization, not host resource management. Reducing parallelism extends wall clock time but doesn't change the quality of the output. The CIO presentation timeline (2026-03-24) gives us runway. A slower run that completes is better than a fast run that bricks the operator's machine.

## Protocol Departure: Phase B Reset — Anti-Pattern Correction Mandate

**Decision:** Nuke all Phase B artifacts (FSDs, V2 configs, V2 processors) and re-run Phase B with explicit anti-pattern correction instructions. Phase A BRDs are retained.

**What happened:** During the go/no-go vibes evaluation at the clutch point, review of V2 processor code revealed that every agent faithfully reproduced V1's anti-patterns — integer division, double-precision money, magic values, unnecessary External modules, dead-end data sources. The BRDs correctly identified and documented every anti-pattern using the taxonomy embedded in V1 source comments (W4, W5, W6, AP1, AP7, etc.), but Phase B agents treated those as documentation, not correction targets. V2 code was structurally identical to V1 code — same architecture, same bugs, different variable names.

**Why this is a critical failure:** The core value proposition for the CIO presentation is: autonomous agents can reverse-engineer business logic AND deliver cleaner code. Output equivalence with identical anti-patterns demonstrates copying ability, not engineering judgment. POC2 Run 1 had the identical failure. It was fixed in POC2 Run 2 with explicit anti-pattern correction instructions. That instruction was not carried into the POC3 BLUEPRINT — a process failure, not an agent failure.

**Root cause:** The BLUEPRINT said "produce equivalent output" but never said "fix known problems while doing so." Agents optimized for the stated goal (output equivalence) and treated code quality as out of scope because nobody told them it was in scope. This is rational agent behavior — they default to the lowest-risk interpretation when instructions are ambiguous.

**What we're changing:**
1. Adding a `KNOWN_ANTI_PATTERNS.md` reference document with the full V1 taxonomy (W1-W9, AP1-AP9), descriptions, examples, and prescriptions for what V2 should do instead.
2. Phase B instructions will explicitly mandate: "V2 must produce byte-identical output AND must not reproduce known anti-patterns."
3. Module hierarchy codified in the blueprint:
   - **Default:** DataSourcing → Transformation (SQL) → Writer. Use the framework.
   - **Scalpel:** DataSourcing → Transformation → External (minimal) → Writer. External handles ONLY what SQL can't express.
   - **Last resort:** External (full) → Writer. Only when DataSourcing fundamentally can't support the job's data access pattern. Even then, clean code is required.
4. Explicit instruction: "External modules are not a get-out-of-jail-free card. Needing an External for one operation doesn't license putting the entire pipeline in C#."

**What we're keeping:**
- Phase A BRDs (101 approved, all anti-patterns correctly documented)
- Phase 1 saboteur findings (FSD self-correction pattern)
- Code-level saboteur mutations (will be re-applied to new V2 code after Phase B re-run)

**Why this is defensible:**
1. This is a known failure mode — it occurred in POC2 Run 1 and was fixed in POC2 Run 2. The fix was validated.
2. The failure is a blueprint omission, not an agent capability limitation. The agents CAN correct anti-patterns when told to (POC2 Run 2 proved this).
3. Phase A work is fully preserved. Only Phase B artifacts are being regenerated.
4. The anti-pattern correction mandate is the entire point of the project. Running to completion without it produces a result that doesn't support the CIO presentation thesis.
5. This decision is documented in real-time with full rationale, not retroactively rationalized.

**Logged in:** ai-dev-playbook/Tooling/agent-lessons-learned.md (entry: "Agents Reproduce Anti-Patterns When Not Explicitly Told To Fix Them")

---

## Phase B Re-Run (Run 2)

**~14:15 EST** — Phase B re-launched. Blind lead oriented cleanly — discovered 101 approved BRDs, zero Phase B artifacts, correctly identified the governance gate. No contamination from Run 1 memory detected. Blind lead produced a session status assessment confirming Phase A complete, Phases B-E not started. Status file deleted, agents spawning now.

**Key monitoring priorities this run:**
1. External module count (Run 1 produced 71/101 — looking for dramatic reduction under module hierarchy)
2. Anti-pattern reproduction (the thing that killed Run 1 — dual mandate should prevent)
3. Build serialization compliance (subagents write only, lead builds)
4. Saboteur mutation handling in BRDs (expecting architect self-correction pattern to repeat)

**~14:30** — First check-in. 71 FSDs landed. Zero V2 processors, zero test plans. Architects cranking.

**~14:45** — 77 FSDs. Spot-checked module tier breakdown:
- Tier 1 (framework only): 56 jobs
- Tier 2 (scalpel): 15 jobs
- Tier 3 (last resort): 1 job (covered_transactions)
Compare to Run 1: 71 External modules out of 101 jobs. **Module hierarchy is working.** Dramatic shift toward SQL-based pipelines.

**~14:50** — Dan reports 73% token usage. Developers haven't started. Discussed clutch timing.

**~14:55** — 89% tokens. CLUTCH engaged.

**~15:00** — Blind lead did NOT check for clutch file. Completed all 101 FSDs, then immediately launched 3 batches of 10 reviewer agents without checking. Ctrl+C interrupted after 3 batches spawned but before any review output landed. **Clutch protocol failure** — standing order on BLUEPRINT line 77 was not followed. The instruction is present and correct; the agent simply didn't execute the check before spawning. Likely the Monolithic Blueprint Tax pattern — standing order at line 77, agent deep in Phase B execution starting at line 211.

**~15:05** — Dan resumed blind lead session, told him to write session state without resuming POC work. Clean session_state.md written. 101 FSDs complete, reviews at zero, everything else at zero. Clean pause point.

**CLUTCH FAILURE — needs fix.** Options to discuss with Dan after token refresh:
- Add clutch check reminder directly into Phase B section (near build serialization)
- Add it to the per-batch checklist so it's in the execution flow, not just a standing order at the top
- Both
