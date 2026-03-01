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

## Phase B Launch

**~10:03** — 100 BRDs, 16 reviews (13 PASS, 3 FAIL). Third FAIL: monthly_transaction_trend — same CsvFileWriter header-in-append mistake. All three FAILs from the Transaction Analytics analyst (analyst-7 domain). Systematic misunderstanding by one analyst, consistently caught by reviewer-2. Pattern: analyst read the config (`includeHeader: true`, `writeMode: Append`) and assumed headers repeat, never checked the actual CsvFileWriter code that gates it with `!append`. Good reviewer, sloppy analyst.
