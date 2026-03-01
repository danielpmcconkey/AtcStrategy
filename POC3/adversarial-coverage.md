# POC3 Adversarial Concern Coverage Map

**Classification:** Internal strategy document. NOT for worker agents.

This document maps every concern raised during adversarial reviews (CIO, Risk Partners,
CRO, Independent Evaluator, CEO) to the specific POC3 element that addresses it.

**Corrected framing:** Dan has full chain-of-command support, business line CIO green light,
CDO sponsorship. This is proof of technology, not a production deployment pitch. These
concerns are valuable as CIO presentation prep material, not blocking issues.

---

## Coverage Matrix

| # | Concern | Source | POC3 Element | How It Addresses the Concern |
|---|---------|--------|-------------|------------------------------|
| 1 | "Error detection works?" — how do we know the comparison loop catches real errors? | AC-20, AC-24 | **Saboteur Protocol** | Plants 10-15 subtle logic errors in approved BRDs. If Proofmark catches 80%+ of them as FAILs, error detection is stress-tested. Any undetected sabotage is a genuine finding documented carefully. |
| 2 | "Output target diversity" — POC2 only proved PostgreSQL output comparison | C-03 (CRITICAL) | **3 output types** | V1 portfolio includes Parquet, CSV (plain), and CSV-with-trailer jobs. Proofmark handles all three via reader abstraction. Not just PostgreSQL anymore. |
| 3 | "Governance circularity" — the AI that builds is the same AI that validates | C-25, C-26 | **Proofmark COTS model** | Proofmark is presented to workers as an independently-built COTS tool. Workers receive only README and CONFIG_GUIDE — no source code, no algorithm details. Information isolation prevents gaming the validator. Production recommendation: vendor-built tool. |
| 4 | "CLAUDE.md is the critical document" — quality of instructions determines quality of output | Independent 4.1 | **This blueprint** | POC3's CLAUDE.md is deliberately designed with domain batching, evidence protocol, quality gates, Proofmark integration, targeted restart, and governance requirements. The blueprint IS the context engineering. |
| 5 | "Comparison window adequacy" — 31 days (Oct 2024) may miss month-end, quarter-end edge cases | AC-20 | **Full quarter** | 92 days: Oct 1 - Dec 31, 2024. Includes month-end boundaries (Oct 31, Nov 30, Dec 31) and quarter-end (Dec 31). Weekend/holiday patterns are exercised over 13 weekends. |
| 6 | "Comparison loop convergence" — full-truncate-restart doesn't scale | C-06, C-09 | **Targeted restart** | On failure: fix the V2 code, re-run ONLY the failed job, re-compare ONLY that job. No full truncate. No re-running 100+ other jobs that already passed. Per-job state tracking in validation_state.md. |
| 7 | "Latent error attestation" — equivalence != correctness. Both old and new could be wrong. | AC-24 | **Attestation disclaimer** | Every Proofmark report and governance artifact includes: "Output equivalence certifies equivalence to the original, NOT correctness in an absolute sense." This is stated in the COTS README and echoed in governance reports. |
| 8 | "Test plans not executed" — POC2 generated test plans but didn't run them as automated tests | C-37, C-38 | **Proofmark runs ARE executed tests** | Proofmark comparisons replace traditional test execution. Each comparison is a concrete test with a concrete pass/fail result against real data. 92 days × 100+ jobs = thousands of data points validated. |
| 9 | "Who watches the watchers?" — who validates the validation tool? | AC-07 | **COTS model + vendor build strategy** | For POC: Proofmark built via rigorous SDLC (BRD v3, 66 BDD scenarios, 205 unit tests, 3 rounds of adversarial audit). For production: recommendation to hire independent SI to build the tool from the BRD. Architectural separation, not just process separation. |
| 10 | "Scale concerns" — 32 jobs is too small to prove enterprise viability | General | **100+ jobs, 12 concurrent agents** | Portfolio expanded to 100+ V1 jobs across 10 business domains. 10 analysts + 2 reviewers working in parallel during Phase A. Domain batching demonstrates organizational scalability. |
| 11 | "Information isolation robustness" — how do we know agents aren't reading forbidden sources? | AC-25 | **Spy Protocol** | Active monitoring at 4 checkpoints. Transcript scanning for forbidden file reads, git history commands, Proofmark internals access. CRITICAL/HIGH/MEDIUM severity tiers with defined response protocol. |
| 12 | "Fix loop creates divergence" — iterating fixes might drift from original requirements | C-09 | **Resolution evidence + changes flow uphill + consistency verification** | Every resolution must cite V1 ground-truth evidence (decision 13). Every fix updates all upstream docs (decision 14). Phase D.6 verifies the entire document chain is internally consistent before governance reports are written (decision 15). Three layers preventing drift. |
| 13 | "Governance artifacts are AI-generated boilerplate" — no assurance they reflect reality | C-30 | **Consistency verification (D.6) + Proofmark config echo** | Read-only verifier subagents cross-check every document pair (BRD↔FSD, FSD↔test plan, FSD↔Proofmark config, FSD↔V2 code). Inconsistencies block Phase E. Governance reports include actual Proofmark configs and comparison results. Verified, not assumed. |
| 14 | "Single point of failure in CLAUDE.md" — bad instructions = bad everything | Independent 4.2 | **Phased execution with gates** | Phase A has reviewer gates. Phase B has architect + code reviewer gates. Phase D has Proofmark gates. Multiple independent checkpoints, not a single pass/fail. |
| 15 | "No negative testing" — POC2 never proved the process can find errors | CEO observation | **Saboteur** | Explicit negative testing. Planted errors with known mutations, tracked in a ledger, with success criteria (80% detection rate). If the process CAN'T find errors, we know. |
| 16 | "Anti-cheat could collide with saboteur" — orchestrator flags legitimate Phase D findings as violations | Walkthrough | **Softened anti-cheat + cleared findings table** | All suspected violations go to Dan for joint evaluation (decision 17-18). Mandatory saboteur ledger cross-check before flagging. Cleared findings table prevents re-flagging resolved false positives. |
| 17 | "Token budget could halt execution mid-run" — no higher API plan available | Walkthrough | **Clutch protocol** | File-based graceful pause (POC3/CLUTCH). Blind lead checks before every agent spawn or task assignment. Wind-down preserves all in-flight work. session_state.md enables resurrection after token refresh (decision 16). |
| 18 | "Fixed thresholds are guesses without baseline data" — arbitrary limits could trigger false alarms or miss real problems | Walkthrough | **Touchbase protocol + per-job threshold** | Aggregate thresholds replaced by regular orchestrator-to-Dan status updates at phase transitions and 25% progress intervals. Per-job escalation at 5 failed attempts preserved as a concrete signal (decision 19). |
| 19 | "No autonomous enforcement" — orchestrator acting unilaterally risks self-inflicted wounds | Walkthrough | **Human-in-the-loop for all enforcement** | Orchestrator monitors and recommends. Dan decides. No autonomous agent kills, plug pulls, or quarantines. Clutch is the only autonomous tool, and Dan designed it (decision 18). |

---

## Concerns NOT Addressed by POC3

These are legitimate concerns that are explicitly out of scope for this proof of technology:

| Concern | Source | Why Not Addressed | When Addressed |
|---------|--------|-------------------|----------------|
| Production-grade security (PII/PCI in reports) | AC-12 | POC uses synthetic data. Noted in Proofmark alignment doc. | Production tool build |
| Regulatory submission readiness | C-33 | This is a technology demonstration, not a regulatory filing | Program phase 2 |
| Multi-platform support (Oracle, SQL Server, S3) | AC-15 | Mock framework is PostgreSQL + files. Architecture supports it. | Production tool build |
| Cost modeling at enterprise scale | C-40 | Token costs measured but not optimized. | Program phase 2 |
| Change management / organizational readiness | CEO | Technology proof, not organizational transformation | Separate workstream |

---

## Mapping to CIO Presentation Beats

The CIO presentation (2026-03-24) has a narrative arc. Here's how POC3 results feed into it:

| Presentation Beat | POC3 Evidence |
|-------------------|---------------|
| "The AI can rewrite ETL jobs" | 100+ jobs reverse-engineered and rebuilt with zero human intervention |
| "The rewrites produce identical output" | Proofmark comparison results across 92 days × 100+ jobs |
| "The validation is independent" | COTS model, information isolation, worker agents have no knowledge of Proofmark internals |
| "The process catches errors" | Saboteur results — X% of planted errors detected by the comparison loop |
| "It scales" | 100+ jobs, 10 business domains, 12 concurrent agents, domain batching |
| "It produces governance artifacts" | Executive summary, per-job reports with Proofmark config echo, consistency-verified document chains |
| "Here's the production path" | Vendor-built comparison tool from Proofmark BRD, independent SI |

---

## Source Reference

Adversarial review documents:
- `AdversarialReviews/01-cio-evaluation.md`
- `AdversarialReviews/02-risk-partners-evaluation.md`
- `AdversarialReviews/03-cro-evaluation.md`
- `AdversarialReviews/04-independent-evaluation.md`
- `AdversarialReviews/05-ceo-evaluation.md`
- `AdversarialReviews/06-program-tar-register.md`

Concern IDs (C-XX, AC-XX) reference findings in these documents.
