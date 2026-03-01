# Project ATC: Program TAR Register
# Weekend POC Build + March 24 CIO Presentation Preparation

**Author:** Program Management Office (Senior PM Assessment)
**Date:** 2026-02-27
**Classification:** INTERNAL -- Working Document
**Scope:** Weekend POC build (Feb 27-Mar 2), with forward-looking narrative for March 24 CIO presentation

---

## How to Read This Document

This is a Tasks, Actions, and Risks register for a **weekend POC build**. It is not a production deployment plan. It is not a regulatory compliance checklist. It is the plan for building a demo that proves Dan understands every concern the adversarial reviewers raised, has a credible answer for each one, and can show working software that demonstrates the concept.

The March 24 CIO presentation is the target. The weekend POC is the ammunition.

**Key framing decision:** Proofmark is a POC stand-in. The production comparison tool will be built by an independent systems integrator (Infosys, Accenture, or equivalent). This is documented in `/workspace/proofmark/Documentation/scope-and-intent.md` and is the single most important strategic decision in the entire program. It neutralizes approximately 40% of the adversarial concerns in one move.

---

# Section 1: Weekend POC Scope Definition

## What We Are Building

A working demonstration that proves:

1. **Proofmark can compare real output types.** Delta Parquet files, simple CSV, and CSV with trailing control records -- the three patterns that cover ~95% of production output.

2. **The three-tier threshold model works.** Per-job configuration that classifies columns as excluded (Tier 1), exact match (Tier 2), or tolerance-based (Tier 3). Configuration-driven, auditable, documented justification for every exclusion.

3. **Day-over-day match reports are generated.** Not just pass/fail -- full evidence output showing what matched, what didn't, what was excluded and why.

4. **The expanded MockEtlFramework runs with real output types.** Jobs that produce actual parquet files and CSV files (including trailing control records), not just PostgreSQL tables.

5. **Builder agents believe Proofmark is COTS.** Information isolation is demonstrated, not just described. The builder agent session's context contains no reference to Proofmark's internals, authorship, or development process.

6. **An evidence package exists.** A governance deliverable that shows what the CIO, CRO, and OCC examiner would actually review -- not a design document describing what it might look like someday.

## What We Are NOT Building

- A production-ready tool. Proofmark is a functional specification for a vendor build.
- Full SDLC compliance artifacts. Those come with the vendor build.
- An SR 11-7 model risk framework. That's institutional work measured in months.
- A TPRA for Anthropic. Standard institutional process, initiated after CIO approval.
- Infrastructure-level security controls. Required before production data access, not before a POC on synthetic data.
- A cost model. This IS a weekend deliverable (see T-09), but the cost model is a spreadsheet, not software.

## Definition of "Done" for the Weekend

The POC is done when Dan can sit in front of a screen and demonstrate:

1. A Proofmark run against parquet output that shows the three-tier threshold model working
2. A Proofmark run against CSV output (with and without trailing control records)
3. A day-over-day match report with full evidence
4. Builder agent logs showing the agent interacting with Proofmark as if it were COTS
5. A sample evidence package in the format the governance team would review
6. A cost model spreadsheet with three scenarios

## What Success Looks Like for March 24

The CIO presentation is not "approve production." It is "here's how Phase 1 is going and here's why your decision to explore this was right." Specifically:

- **Working demo:** "Let me show you the comparison tool running against real output types."
- **Governance story:** "Here's the three-layer validation model. Layer 1 is deterministic comparison. Layer 2 is human domain expert review. Layer 3 is an organizationally independent governance function."
- **Vendor strategy:** "Proofmark is the functional specification. We recommend hiring Infosys/Accenture to build the production version. That gives you true organizational independence."
- **Risk awareness:** "We've been through five rounds of adversarial review. Here are the top concerns and our plan for each one."
- **The ask:** "Continue Phase 1 with the conditions you set. Here's the progress against those conditions."

---

# Section 2: TAR Register -- Weekend POC Tasks

## Proofmark Core Build

### T-01: Proofmark Comparison Engine -- Core

- **Task:** Build the format-agnostic comparison engine that takes two tabular datasets and produces a match report based on three-tier column classification.
- **Owner:** BD (Claude)
- **Dependencies:** None (foundational)
- **Definition of Done:** Engine accepts two DataFrames (or equivalent), a column classification config (Tier 1/2/3), and produces a structured result object with: matched row count, mismatched row count, excluded columns list, tolerance violations list, and per-column match statistics.
- **Priority:** P0

### T-02: Parquet Reader (Pluggable)

- **Task:** Build a pluggable reader that loads Delta Parquet part files into the comparison engine's input format. Must handle part files (data spread across multiple physical files), schema inference, and reassembly into a single logical dataset.
- **Owner:** BD (Claude)
- **Dependencies:** T-01
- **Definition of Done:** Reader loads a directory of parquet part files, reassembles into a single dataset, and feeds it to the comparison engine. Tested with at least one multi-file parquet output.
- **Priority:** P0

### T-03: CSV Reader (Pluggable) -- Simple

- **Task:** Build a pluggable reader for simple CSV files (DataFrame-to-CSV dumps with header row). This covers ~76% of production output.
- **Owner:** BD (Claude)
- **Dependencies:** T-01
- **Definition of Done:** Reader loads a CSV file with headers, infers or applies configured types, and feeds to the comparison engine. Handles quoting, escaping, and encoding edge cases.
- **Priority:** P0

### T-04: CSV Reader -- Trailing Control Record Handling

- **Task:** Extend the CSV reader to handle files with trailing control records (expected row counts, checksums, etc.). Must detect and separate the control record from data rows before comparison. Must compare the control record separately (e.g., verify row count matches actual data rows).
- **Owner:** BD (Claude)
- **Dependencies:** T-03
- **Definition of Done:** Reader correctly identifies trailing control record, excludes it from data comparison, validates control record values (row count) against actual data, reports control record validation separately in results.
- **Priority:** P0

### T-05: Per-Job Configuration Schema

- **Task:** Design and implement the per-job comparison configuration. Each job gets a config file (YAML or JSON) that specifies: output type (parquet/csv/csv-with-control), column tier classifications, tolerance values for Tier 3 columns, exclusion justifications for Tier 1 columns, and any reader-specific settings.
- **Owner:** BD (Claude), Dan reviews schema
- **Dependencies:** T-01, T-02, T-03, T-04
- **Definition of Done:** A documented config schema with at least three example configs (one per output type). Config validation that rejects invalid or incomplete configurations. Every Tier 1 exclusion requires a `justification` field.
- **Priority:** P0

### T-06: Day-Over-Day Match Report Generator

- **Task:** Build the report generator that produces human-readable day-over-day match reports. Reports must show: per-date pass/fail status, aggregate statistics, all mismatches (not just failures -- show everything regardless of threshold), Tier 1 exclusion justifications, Tier 3 tolerance results, and an overall summary.
- **Owner:** BD (Claude)
- **Dependencies:** T-01, T-05
- **Definition of Done:** Report generated as markdown (for demo) that a governance reviewer could read and understand without knowing anything about Proofmark's internals. Report always shows 100% of mismatches even when the overall result is PASS.
- **Priority:** P0

### T-07: Evidence Package Template

- **Task:** Produce a sample evidence package in the format that would be the governance deliverable. This is the artifact the CIO presentation demonstrates. Must include: BRD (from existing Phase 3 artifacts), comparison results from Proofmark, configuration showing what was compared and how, day-over-day report, sign-off page template.
- **Owner:** BD (Claude) + Dan
- **Dependencies:** T-06, T-05
- **Definition of Done:** One complete evidence package for one mock job, formatted and structured for a governance audience. Includes the attestation disclaimer (output equivalence certifies equivalence to the original, not absolute correctness).
- **Priority:** P1

## MockEtlFramework Expansion

### T-08: Add Real Output Types to MockEtlFramework

- **Task:** Extend the MockEtlFramework to produce actual parquet files and CSV files (with and without trailing control records) as output, in addition to the existing PostgreSQL table output. This requires adding at least 2-3 jobs that write parquet via pyarrow and 2-3 jobs that write CSV (one with trailing control record).
- **Owner:** BD (Claude)
- **Dependencies:** None (can proceed in parallel with Proofmark build)
- **Definition of Done:** At least 5 new or modified jobs producing non-PostgreSQL output. Jobs run successfully via `dotnet run --project JobExecutor`. Output files exist on disk in expected formats.
- **Priority:** P0

## Cost Model

### T-09: Three-Scenario Cost Model

- **Task:** Produce a cost model spreadsheet with three scenarios (optimistic, expected, pessimistic) covering: token costs (extrapolated from POC data with buffers), Azure compute for sandbox environments, developer time (3 developers x 6 months), Proofmark vendor build estimate, contingency (30% on expected), and the comparison: cost of doing nothing (status quo maintenance cost).
- **Owner:** Dan (BD provides POC data extrapolation)
- **Dependencies:** None
- **Definition of Done:** A spreadsheet or document that answers "what does Phase 1 cost?" with three numbers and shows the derivation. The CIO and CFO can review it without asking follow-up questions about methodology.
- **Priority:** P0

## Information Isolation Demonstration

### T-10: Builder Agent COTS Interface Design

- **Task:** Design and document the interface that builder agents see when interacting with Proofmark. This is the "COTS product" presentation layer. Builder agents see: a CLI interface, documented capabilities (input types, output format, configuration options), and nothing about authorship, development process, or internals.
- **Owner:** BD (Claude) + Dan
- **Dependencies:** T-05, T-06
- **Definition of Done:** A COTS-style README that a builder agent would read, a CLI invocation pattern, and sample output. Zero references to Claude, AI, weekend development, or Dan in any artifact the builder agent can access.
- **Priority:** P1

### T-11: Information Isolation Dry Run

- **Task:** Run a builder agent session against at least one mock job where the builder agent uses Proofmark through the COTS interface. The builder agent's context must contain no reference to Proofmark's internals. Capture the session log as evidence of information isolation.
- **Owner:** BD (Claude)
- **Dependencies:** T-10, T-08, all Proofmark core (T-01 through T-06)
- **Definition of Done:** Session log showing a builder agent interacting with Proofmark as COTS. No evidence in the session that the agent knows Proofmark is Claude-built or knows its internal architecture. The agent's behavior demonstrates genuine information isolation.
- **Priority:** P1

## Test Infrastructure

### T-12: Proofmark TDD/BDD Test Suite

- **Task:** Write test cases BEFORE implementation (per SDLC commitment). Dan reviews every test case. Tests cover: exact match detection, tolerance comparison, excluded column handling, parquet loading, CSV loading, trailing control record detection, config validation, and deliberately planted mismatches that must be caught.
- **Owner:** BD (Claude), Dan reviews
- **Dependencies:** None (tests written first)
- **Definition of Done:** pytest test suite with >90% coverage of comparison engine. Tests include known-good comparisons (should pass), known-bad comparisons (should fail and report specific mismatches), and edge cases (empty files, single-row files, schema mismatches). Dan has reviewed and approved every test case.
- **Priority:** P0
- **Progress (2026-02-28):** BDD scenarios complete (60 scenarios, test-architecture v2.1 approved). 97 test fixtures generated (55 parquet, 22 CSV, 20 configs). FSD v1.1 provides module-level spec with 167 tags and test-to-module mapping (Appendix A). Two adversarial audit rounds completed against the full requirements stack. Next: unit test implementation from BDD scenarios.

### T-13: Adversarial Test Cases for Proofmark

- **Task:** Design test cases that deliberately try to break Proofmark. Include: type coercion differences that should fail but might silently pass, floating-point edge cases, null vs empty string vs missing value, Unicode normalization differences, timestamp timezone handling, and the "two bugs that cancel out" scenario.
- **Owner:** BD (Claude), Dan reviews
- **Dependencies:** T-12
- **Definition of Done:** At least 10 adversarial test cases, each documented with: what it tests, why it matters, expected behavior, and what a failure would mean for governance. All pass.
- **Priority:** P1

## Presentation Preparation

### T-14: Adversarial Concern Response Matrix

- **Task:** Produce a one-page matrix mapping every significant concern from the five adversarial evaluations to a response strategy. This is Section 3 of this document, condensed into a presentation-ready format.
- **Owner:** BD (Claude)
- **Dependencies:** This document (T-14 is downstream of the TAR register itself)
- **Definition of Done:** A matrix that Dan can put on a slide or hand to the CIO showing: concern, source, response strategy, status. No concern is unaddressed. Every "Deferred to vendor build" item explicitly names the vendor strategy.
- **Priority:** P1

### T-15: CIO Presentation Narrative Outline

- **Task:** Draft the narrative arc for the March 24 presentation. Not a slide deck -- an outline of the story Dan tells, the order he tells it, and the talking points for the top 10 concerns.
- **Owner:** Dan + BD (Claude)
- **Dependencies:** T-07 (evidence package), T-14 (concern matrix), T-09 (cost model)
- **Definition of Done:** A narrative document that Dan can rehearse from. Includes the opening, the governance story, the vendor strategy, the top 5 preemptive concern responses, and the ask.
- **Priority:** P1

---

# Section 3: TAR Register -- Adversarial Concern Responses

## Consensus Concerns (All Five Reviewers Agree)

### AC-01: Proofmark Maturity -- "A Weekend Project as Governance Lynchpin"

- **Concern:** Proofmark is a design document, not working software. It was designed in a single Saturday session. It has no code, no tests, no SDLC artifacts. (CIO Section 2.1, Risk Partners RR-006/RF-12/RF-13, CRO Section 2, Independent Section 2.1, CEO Section 7)
- **Response Strategy:** Addressed in POC + Deferred to vendor build
- **Evidence/Talking Point:** "Proofmark is the functional specification, not the production tool. This weekend's POC proves the architecture works. The production comparison tool will be built by an independent systems integrator -- Infosys, Accenture, or equivalent -- using Proofmark as the spec. That gives you true organizational independence, formal SDLC, and removes the 'weekend project' concern entirely. What I'm showing you today is working software that demonstrates the concept. What you'll get in production is an enterprise tool built by a firm your auditors already trust."
- **Status:** In Progress (POC build this weekend; vendor strategy documented)
- **SDLC Evidence (2026-02-28):** Proofmark's requirements stack is now three deep: BRD v3.1 (128 requirements, 18 design decisions), Test Architecture v2.1 (60 BDD scenarios with full traceability matrix), FSD v1.1 (167 specification tags). Two rounds of adversarial audit completed — the first found 2 critical, 5 high, 5 medium, 4 low findings; the second (post-fix cross-document consistency review) found 1 critical, 1 high, 5 medium, 3 low. All critical/high findings from round 1 resolved; round 2 critical is a JSON example update. The SDLC artifacts (BRD→Test Arch→FSD→adversarial review→corrections) are version-controlled with full revision history. This is more SDLC rigor than most production tools receive.

### AC-02: No Cost Model

- **Concern:** No cost analysis exists for token costs, Azure compute, developer time, or the rebuild investment. The governance committee cannot approve without knowing cost. (CIO Section 6.2, Risk Partners RR-025, CRO Section I.7, Independent Section 2.2, CEO Section 8, Skeptic C-13/C-14/C-31/C-32/C-33)
- **Response Strategy:** Demonstrated in POC (cost model deliverable)
- **Evidence/Talking Point:** "Here's the three-scenario cost model. Phase 1 all-in: $2-3MM in the expected case. That includes three developers for six months, token costs extrapolated from our POC with a 3x buffer, Azure compute, and 30% contingency. Against a $750MM opportunity, even at 10% realization, the ROI is self-evident. Here's the spreadsheet with the derivation."
- **Status:** Open (T-09, due this weekend)

### AC-03: Segregation of Duties -- Information Isolation Is Not Enough

- **Concern:** One person (Dan) designed both the builder pipeline and the validation tool. Information isolation between AI instances does not satisfy regulatory SoD requirements. The operative word in regulatory frameworks is "people." (CIO Section 3.2, Risk Partners RF-10/RF-11/RR-002/RR-017, CRO Section I.2, Independent Section 7, CEO Section 7)
- **Response Strategy:** Addressed in presentation narrative + Deferred to vendor build
- **Evidence/Talking Point:** "Three points. First, the production comparison tool will be built by an independent vendor with their own management chain. That's organizational independence by any regulatory definition. Second, the governance model has three layers: Layer 1 is deterministic comparison that mathematically cannot be gamed. Layer 2 is human domain expert review of inferred business requirements. Layer 3 is an organizationally independent governance function that owns the validation methodology. No single person or system controls all three layers. Third, information isolation isn't the primary control -- it's defense in depth. Even if a builder agent knew Proofmark's architecture, it can't produce code that outputs wrong values while passing exact match comparison. That's a logical impossibility, not a governance argument."
- **Status:** Ready (vendor strategy documented; three-layer model defined by Independent Evaluator Section 7.4)

### AC-04: Executive Sponsorship Required

- **Concern:** An initiative of this magnitude requires a VP-level-or-above sponsor. Dan cannot carry this alone. (CIO Section 1.1, CRO Section I.4, Independent Section 6 Priority 2, CEO Section 4)
- **Response Strategy:** Addressed in presentation narrative
- **Evidence/Talking Point:** "The CDO has seen the POC and is the proposed executive sponsor. The organizational structure: CDO owns the initiative, CIO owns technology governance, CRO co-authors the governance framework, I'm the technical lead. A steering committee with all four meets monthly with stage gates at 1, 10, and 50 jobs."
- **Status:** Ready (CEO evaluation pre-decided this: CDO as sponsor)

### AC-05: Third-Party Risk Assessment for Anthropic

- **Concern:** The entire project depends on Anthropic's Claude. No TPRA, no DPA review, no data residency assessment, no contractual protections documented. (CIO Section 5.2, Risk Partners RR-003/RF-07, CRO Section I.3, Independent Section 2.5, CEO Section 8)
- **Response Strategy:** Addressed in presentation narrative (initiated, not complete)
- **Evidence/Talking Point:** "TPRA is a standard institutional process. We'll initiate it immediately upon Phase 1 authorization. It runs in parallel with technical work. This is paperwork, not architecture -- we know how to do TPRAs. The TPRA must be complete before Phase 2 scaling, not before Phase 1 piloting on synthetic data."
- **Status:** Open (will be initiated post-CIO approval)

### AC-06: Infrastructure-Level Security Controls

- **Concern:** Policy-level enforcement (CLAUDE.md saying "don't touch production data") is not a control. Infrastructure-level enforcement is required before agents touch production data. (CIO Section 4.2, Risk Partners RR-015, CRO Section I.5, Independent Section 2.6, CEO Section 8, Skeptic C-34/C-35)
- **Response Strategy:** Addressed in presentation narrative (Phase 1 prerequisite, not weekend scope)
- **Evidence/Talking Point:** "Agreed completely. Before any agent touches production data: read-only database users, Azure Key Vault for secrets, network isolation of agent sandboxes, comprehensive audit logging of every agent-executed query. Policy enforcement is for POCs. Infrastructure enforcement is for production. We won't request production data access until these controls are in place."
- **Status:** Open (Gate 1 item, not weekend scope)

## CIO-Specific Concerns

### AC-07: "Who Validates the Validator?" / Build-vs-Buy for Proofmark

- **Concern:** Why not use QBV or another existing vendor tool instead of building Proofmark? The CIO demands a formal build-vs-buy analysis. (CIO Section 5.1)
- **Response Strategy:** Addressed in presentation narrative
- **Evidence/Talking Point:** "Two reasons. First, information isolation requires a tool the builders have never seen. QBV was used during cloud migration -- every ETL developer on the platform knows it exists and roughly how it works. Using QBV means the builder agents could be told about it, breaking isolation. Second, we're NOT building the production tool ourselves. Proofmark is the functional spec. The production tool will be built by a vendor -- which could be the QBV vendor, or Infosys, or Accenture. The build-vs-buy decision for the production tool is downstream. Right now, we need a spec, and building the spec as working software means we can demo it, test it, and hand it to a vendor with confidence."
- **Status:** Ready

### AC-08: The "Hero Problem" / Bus Factor

- **Concern:** The entire initiative exists in Dan's head. If he leaves, nobody can run it. (CIO Section 1.3, CRO Section I.4, CEO Section 4, Skeptic C-22/C-23)
- **Response Strategy:** Addressed in presentation narrative
- **Evidence/Talking Point:** "Three developers will be named before Phase 1 begins. By end of Phase 1, at least two of them run an end-to-end job independently without my involvement. That's a hard gate -- the CRO requires it, and I agree with him. The documentation we've produced is significantly more thorough than most technology proposals. But documentation doesn't replace experience, which is why the 120-day Phase 1 is as much a knowledge transfer exercise as a technical one."
- **Status:** Open (developers not yet named; Phase 1 deliverable)

### AC-09: Board Communication Readiness

- **Concern:** The CIO cannot tell the board about "autonomous AI agent swarms" with a weekend governance tool. The board has been receiving AI scare articles. (CIO Section 7.1, CEO Section 6)
- **Response Strategy:** Addressed in presentation narrative
- **Evidence/Talking Point:** Never say "autonomous." Never say "agent swarm." Never say "zero human intervention." The framing: "AI-assisted modernization with human oversight at every gate." The board narrative: "We're proceeding with a controlled pilot -- 50 to 100 jobs from a single business line, with formal governance, independent validation, and stage gates at every step. The pilot investment is approximately $2-3MM. Our CRO co-authored the governance framework. We briefed the OCC proactively."
- **Status:** Ready (narrative defined by CEO evaluation)

### AC-10: CIO's Ten Questions

- **Concern:** The CIO requires written answers to 10 specific questions before advancing past POC stage. (CIO Section "Specific Questions")
- **Response Strategy:** Addressed in presentation narrative (answer 4, plan the remaining 6)
- **Evidence/Talking Point:** Per the Independent Evaluator's recommendation (Section 9): Answer the top 4 before presenting (cost model, sponsor, Proofmark status, regulatory approach). Present the plan to answer the remaining 6 with timelines. The CIO's questions are legitimate, but treating them as sequential prerequisites creates a 6-month delay before any presentation occurs.
  - Q1 Cost model: Delivered (T-09)
  - Q2 Executive sponsor: CDO (decided)
  - Q3 Proofmark maturity: POC demo + vendor build plan
  - Q4 Regulatory readiness: CRO co-authoring governance framework
  - Q5 Comparison strategies: Demonstrated in POC
  - Q6 Rollback plan: Defined in Phase 1 proposal (90-day parallel run for critical jobs)
  - Q7 Human validation protocol: Defined (5-10% spot-check, declining to 5% as confidence builds)
  - Q8 Production support model: Phase 1 deliverable
  - Q9 Vendor risk assessment: TPRA initiated post-approval
  - Q10 Board-ready narrative: Drafted
- **Status:** In Progress (4 of 10 answerable by March 24)

## Risk Partners Concerns

### AC-11: SR 11-7 Model Risk Management

- **Concern:** The agent swarm is a model under SR 11-7. No model risk management framework exists. MRM has not been engaged. (Risk Partners RF-01/RF-02/RR-001, CIO Section 3.2, CRO Section I.5)
- **Response Strategy:** Addressed in presentation narrative
- **Evidence/Talking Point:** "We agree. We're treating both the agent system and the comparison tool as models for governance purposes, even though the legal classification is debatable for Proofmark (it's a deterministic comparison tool, not a statistical model). MRM registration will be initiated as part of Phase 1. We'll work with MRM to define a pragmatic scope -- the agent swarm and Proofmark are different systems with different risk profiles and should be registered separately. We're not waiting for full SR 11-7 compliance before Phase 1, but we are starting the process before any production deployment."
- **Status:** Open (MRM engagement is a Phase 1 activity)

### AC-12: Privacy Impact Assessment

- **Concern:** AI agents will process production data through Anthropic's API. No PIA conducted. GLBA implications. (Risk Partners RR-004/RF-08/RF-09)
- **Response Strategy:** Addressed in presentation narrative (Gate 1 item)
- **Evidence/Talking Point:** "PIA will be conducted before any agent accesses production data. The key question is what data actually transits to the API -- we can implement data masking and aggregation to minimize exposure. The POC runs on synthetic data and no production data is involved until the PIA clears. This is a standard process with known timelines."
- **Status:** Open (Gate 1 item)

### AC-13: Audit Trail Provenance

- **Concern:** Evidence citations in BRDs reference file:line numbers not tied to immutable artifact versions. Citations become stale after migration. Reviewer caught off-by-one errors. (Risk Partners RR-007/RF-03, CIO Section 3.3, Skeptic C-36)
- **Response Strategy:** Deferred to Phase 1 prototype
- **Evidence/Talking Point:** "Valid concern. All evidence citations will reference commit hashes and immutable artifact identifiers. Original source code will be archived alongside the attestation package. We'll implement automated citation verification to confirm each citation resolves to the claimed content. This is engineering work that happens during Phase 1, not weekend scope."
- **Status:** Open (Phase 1 deliverable)

### AC-14: Change Management Pathway

- **Concern:** No defined process for how AI-generated code enters the existing change management process. No interaction with the Change Management Office. (Risk Partners RR-009/OF-01/OF-02/OF-03)
- **Response Strategy:** Deferred to Phase 1 prototype
- **Evidence/Talking Point:** "We'll engage the Change Management Office during Phase 1. The process needs to address: how Change Requests are submitted, what evidence satisfies CAB review, and how to handle volume at scale. We anticipate needing an expedited pathway for validated, attestation-packaged code changes -- similar to how automated deployment pipelines eventually got their own CAB process."
- **Status:** Open (Phase 1 deliverable)

### AC-15: Parallel Run Requirements

- **Concern:** No parallel-run period defined. Standard institutional practice requires minimum 90 days. (Risk Partners RR-011/OF-08, CIO Section 3.1, CRO Section IV)
- **Response Strategy:** Addressed in presentation narrative
- **Evidence/Talking Point:** "We agree on parallel run, but it should be risk-tiered, not a blanket 90 days. Our proposal: Tier 1 jobs (regulatory reporting, risk calculations) get a full business cycle -- minimum 90 days. Tier 2 (client-facing, financial reporting) gets 60 days. Tier 3 (internal analytics) gets 30 days. Tier 4 (ad-hoc, batch reports) gets pre-deployment validation only. The Risk Partners' blanket 90-day requirement would make the initiative unworkable at scale and doesn't differentiate by risk."
- **Status:** Ready (framework defined by Independent Evaluator Section 3.4)

### AC-16: Incident Response Runbook

- **Concern:** No incident response procedure for AI-rewritten jobs. No one on call knows the code. Agent reasoning is ephemeral. (Risk Partners RR-012/OF-13/OF-14, CIO Section 4.1)
- **Response Strategy:** Deferred to Phase 1 prototype (Gate 2 item)
- **Evidence/Talking Point:** "The runbook will be developed before any AI-rewritten job enters production. It will include: diagnostic procedure using the evidence package, escalation path, per-job rollback procedure, and communication templates. We'll train the on-call team and conduct a tabletop exercise before first production deployment. This is standard operational readiness work."
- **Status:** Open (Gate 2 item)

### AC-17: Rollback Plan

- **Concern:** No rollback strategy defined. Legacy decommission removes the fallback. (Risk Partners RR-013/OF-07, CIO Section 4.1, Skeptic C-48)
- **Response Strategy:** Addressed in presentation narrative
- **Evidence/Talking Point:** "Legacy code and infrastructure remain operational and restorable for a minimum of 12 months after V2 promotion for any critical-path job. Individual jobs can be rolled back independently. No legacy decommission until the parallel-run period is complete with zero divergences. The cost of maintaining the legacy environment during this period is included in the cost model."
- **Status:** Ready

### AC-18: Downstream Impact Assessment

- **Concern:** No identification of downstream consumers. If curated data feeds CCAR/DFAST, a subtle output difference is a potential material weakness. (Risk Partners RR-010/OF-05)
- **Response Strategy:** Deferred to Phase 1 prototype
- **Evidence/Talking Point:** "Downstream impact assessment will be produced for every curated table before the job enters the AI pipeline. Jobs feeding Tier 1 regulatory reporting get enhanced validation: extended comparison windows covering all calendar edge cases, mandatory human BRD review by domain experts, and full business-cycle parallel run."
- **Status:** Open (Phase 1 deliverable, informed by CRO's risk-tiering framework)

### AC-19: Code Review Policy for AI-Generated Code

- **Concern:** The institution's code review policy requires review by "at least one qualified developer who did not write the code." AI agents don't satisfy this. (Risk Partners RR-008/OF-02)
- **Response Strategy:** Deferred to Phase 1 prototype
- **Evidence/Talking Point:** "We'll work with the policy team to either amend the Code Review Policy to address AI-generated code or define a formal exception process. In either case, all AI-generated code will undergo human code review by a qualified developer before production deployment."
- **Status:** Open (Phase 1 deliverable)

## CRO-Specific Concerns

### AC-20: Precedent Risk -- The Quiet Failure Scenario

- **Concern:** An AI agent correctly infers 16 of 17 business rules. The 17th involves a quarterly adjustment not in the comparison window. Comparison passes. Six months later, a regulatory filing is wrong. (CRO Section I.1, CRO Section IV, CEO Section 3)
- **Response Strategy:** Addressed in presentation narrative (multiple mitigations)
- **Evidence/Talking Point:** "This is the scenario we design our controls around. Five mitigations: (1) Comparison window for regulatory jobs covers all calendar edge cases -- month-end, quarter-end, year-end, holidays. (2) Any business rule inferred at MEDIUM or LOW confidence in a critical-path job triggers mandatory human review by a domain expert. (3) Full business-cycle parallel run before legacy decommission. (4) The attestation package explicitly disclaims that output equivalence certifies equivalence to the original, not correctness in an absolute sense. (5) Human spot-check protocol where independent engineers verify a random sample against actual data."
- **Status:** Ready (framework defined across CRO and Independent Evaluator)

### AC-21: Vendor Dependency / Business Continuity

- **Concern:** Deep structural dependency on Anthropic. Service degradation, model quality regression, corporate risk, pricing changes. (CRO Section I.3, CIO Section 5.2, Risk Partners OF-15/OF-16/RR-014)
- **Response Strategy:** Addressed in presentation narrative + Deferred to Phase 2
- **Evidence/Talking Point:** "For Phase 1, we pin the model version and establish a canary job -- a known, well-understood production job re-processed monthly as a regression check. If the canary's output changes with no instruction changes, we pause for investigation. The TPRA will assess pricing stability, API availability, model deprecation policy, and contractual coverage. For Phase 2, we'll assess portability -- can this approach work with a different model provider? The pilot is the right time to evaluate that."
- **Status:** Open (Phase 1 item: canary job; Phase 2 item: portability assessment)

### AC-22: CRO Wants a Seat at the Table

- **Concern:** The CRO explicitly offers to co-author the governance framework. This is an offer, not a demand. (CRO Section V)
- **Response Strategy:** Accepted
- **Evidence/Talking Point:** "The CRO is a co-author of the governance framework, not an approver after the fact. This is the single most important organizational decision we've made. Risk as a partner, not a gate."
- **Status:** Ready (organizational decision made)

## Independent Evaluator Concerns

### AC-23: CLAUDE.md as Critical Artifact / Instruction Set Risk

- **Concern:** The jump from Run 1 (0%) to Run 2 (100%) was entirely instruction quality. A small CLAUDE.md mistake can cause catastrophic quality degradation. The instruction set needs its own change management. None of the adversarial reviews mention this. (Independent Section 4.1)
- **Response Strategy:** Addressed in presentation narrative
- **Evidence/Talking Point:** "The CLAUDE.md is the single most critical artifact in the system. It gets version control, change management, and peer review. Any change to the instruction set triggers a regression run on the canary job. This is a lesson from our own POC: same model, same data, same framework -- the only variable between 0% and 100% was the instructions."
- **Status:** Ready (protocol defined)

### AC-24: Latent Error Attestation Problem

- **Concern:** If original code has a bug producing wrong output, and V2 faithfully reproduces it, comparison says PASS. This converts an unknown defect into an attested defect -- which is legally and regulatorily worse. (Independent Section 4.2, Risk Partners OF-06)
- **Response Strategy:** Addressed in POC (attestation disclaimer)
- **Evidence/Talking Point:** "Every attestation package includes this statement: 'This validation confirms that the V2 job produces output equivalent to the original job. It does not validate the correctness of the original job's business logic.' This is explicit, documented, and reviewed by Legal. We are certifying equivalence, not correctness. If anyone discovers the original was wrong, that's a pre-existing condition we've now made visible and documentable."
- **Status:** Ready (disclaimer included in evidence package template, T-07)

### AC-25: Information Isolation Robustness

- **Concern:** What happens if information isolation breaks? Can a builder agent game Proofmark if it knows the architecture? (CRO Section I.2, Independent Section 7)
- **Response Strategy:** Addressed in presentation narrative
- **Evidence/Talking Point:** "The answer is no. Even if a builder agent knew Proofmark's architecture, it cannot produce code that outputs wrong values while passing exact match comparison on business columns. That's a logical impossibility. Information isolation is defense in depth, not the primary control. The primary control is mathematical: you cannot fake exact equivalence. The production version built by the vendor will also have this property -- the comparison is deterministic and ungameable regardless of what the builder knows."
- **Status:** Ready

### AC-26: Model Capability Regression / Canary Job

- **Concern:** LLM providers change models without always announcing it. Version pinning alone is insufficient. (Independent Section 4.4, Risk Partners RR-014/OF-15)
- **Response Strategy:** Addressed in presentation narrative
- **Evidence/Talking Point:** "We'll maintain a canary job -- a known, well-understood production job re-processed periodically. If the canary's BRD, FSD, or V2 code changes materially between runs with no instruction changes, something in the model has shifted and all in-flight work pauses for investigation. This supplements version pinning with behavioral monitoring."
- **Status:** Ready (protocol defined by Independent Evaluator)

## Skeptic Report Concerns (Not Covered Above)

### AC-27: Output Target Diversity (C-03)

- **Concern:** POC compared PostgreSQL-to-PostgreSQL. Production has 6 output targets. EXCEPT comparison doesn't apply to 5 of 6. (Skeptic C-03, rated CRITICAL by both Skeptic and Evaluator)
- **Response Strategy:** Demonstrated in POC
- **Evidence/Talking Point:** "This weekend's POC demonstrates working comparison for the two actual patterns: Delta Parquet (covers ADLS, DB-out, vanilla Salesforce) and TIBCO MFT files (95% are simple CSV). The Proofmark design session already resolved the scary-sounding '6 targets' into 2 comparison patterns. I can show you both working. The remaining edge cases (EBCDIC, custom Salesforce ADF) are out of scope for Phase 1 with documented risk acceptance."
- **Status:** In Progress (POC build this weekend)

### AC-28: Comparison Loop Convergence at Scale (C-06/C-09/C-21)

- **Concern:** Full-truncate-and-restart protocol is catastrophically expensive at scale. Date-dependent discrepancies cause infinite loops. (Skeptic C-06/C-09/C-21, CIO Section 2.3)
- **Response Strategy:** Addressed in presentation narrative + Deferred to Phase 1
- **Evidence/Talking Point:** "The POC's nuclear restart was right for a 31-job proof point. Production needs targeted restart: track what's been validated, only re-run affected jobs and dates when a fix is applied. This is an engineering problem with known solutions -- similar to incremental build systems. We'll design and test the targeted restart before the 20-job experiment."
- **Status:** Open (Phase 1 deliverable, before 20-job gate)

### AC-29: Governance Circularity (C-25/C-26)

- **Concern:** Evidence package produced by the same system being validated. No independent verification mechanism. POC had Dan as independent validator; at scale there's no Dan. (Skeptic C-25/C-26/C-27)
- **Response Strategy:** Addressed in presentation narrative (three-layer model)
- **Evidence/Talking Point:** "The three-layer validation model addresses this directly. Layer 1: deterministic comparison tool (not the builder system). Layer 2: human domain experts reviewing inferred requirements for critical jobs and a statistical sample of others. Layer 3: organizationally independent governance function owning the overall methodology. The evidence package is produced by the builder system, but the validation of that evidence is independent at every layer."
- **Status:** Ready

### AC-30: Test Plans Were Never Executed (C-37/C-38)

- **Concern:** POC test plans are markdown prose, not executable tests. Comparison loop validated output equivalence, not business rule correctness. (Skeptic C-37/C-38)
- **Response Strategy:** Addressed in presentation narrative + Partially addressed in Proofmark SDLC
- **Evidence/Talking Point:** "Fair point, and we're fixing it. The comparison loop is the actual validation -- it tests that the output is equivalent across every date in the window. The test plans are documentation artifacts that trace requirements to evidence. For Phase 1, we'll implement executable test cases for critical-path jobs that validate business rules independently of the comparison loop."
- **Status:** In Progress — Proofmark's 60 BDD scenarios (test-architecture v2.1) are fully specified with expected values, fixture references, and BRD traceability. Unit test implementation is next in the SDLC. The comparison tool's test plans are no longer "just markdown" — they have specific fixture data, expected counts, and pass/fail criteria that translate directly to pytest assertions.

### AC-31: Constraint Workaround Unpredictability (C-28/C-29)

- **Concern:** Agents work around constraints in unpredictable ways. The targetSchema problem was only discovered post-run. (Skeptic C-28/C-29)
- **Response Strategy:** Accepted risk with mitigation
- **Evidence/Talking Point:** "This is inherent to autonomous systems and was the single biggest lesson from the POC. Run 1's failure wasn't a bug -- it was a lesson in how agents behave when constraints force suboptimal paths. The mitigation is iterative: post-run workaround audits, guardrail review before each run, and the progressive scaling path that catches these issues at 5 jobs, not 500. We can't predict every constraint-workaround interaction, but we can detect them early and adapt."
- **Status:** Ready (mitigation is the progressive scaling approach itself)

## CEO-Specific Concerns

### AC-32: Phase 1 Non-Negotiable Conditions

- **Concern:** CEO requires 6 conditions before Phase 1 authorization: executive sponsor, cost model, Proofmark as working software, steering committee, Risk as co-author, three named developers. (CEO Section 8)
- **Response Strategy:** Addressed in presentation narrative
- **Evidence/Talking Point:**
  - Sponsor: CDO (decided)
  - Cost model: Delivered (T-09)
  - Proofmark: Working POC demonstrated
  - Steering committee: CDO + CIO + CRO + Dan, monthly reviews
  - Risk co-authorship: CRO's offer accepted
  - Three developers: To be named before Phase 1 begins (hard gate)
- **Status:** In Progress (4 of 6 addressable by March 24; developers are a Phase 1 pre-condition)

### AC-33: Regulatory Framing

- **Concern:** The CEO wants proactive OCC briefing. The framing matters enormously. (CEO Section 5, CRO Section I.5)
- **Response Strategy:** Addressed in presentation narrative
- **Evidence/Talking Point:** The framing, verbatim: "We are using AI-assisted tooling to accelerate modernization of our data platform. The AI analyzes existing code and generates improved replacements. Every replacement is validated through an independent comparison tool built through our standard development process. Human engineers review and approve every production change. We have a formal governance framework with stage gates, independent validation, and human decision points at every level."
- **Status:** Ready (language agreed across CRO and CEO evaluations)

---

# Section 4: TAR Register -- Risks to the POC Itself

What could go wrong this weekend that prevents us from having a demo on Monday?

### R-01: Parquet Reader Complexity

- **Risk:** Parquet part files are more complex than expected. Schema evolution, partitioning schemes, or nested types create edge cases that consume most of the weekend.
- **Probability:** MEDIUM
- **Impact:** HIGH (parquet comparison is the #1 demo requirement)
- **Mitigation:** Start with simple, flat-schema parquet files. Use pyarrow, which handles part files natively. Punt nested types and complex schemas to post-weekend scope. The demo needs to show the concept working, not handle every edge case.
- **Contingency:** If parquet is a blocker, demonstrate CSV comparison (which covers 76% of production output) and show the parquet reader design with test fixtures. Less impressive but still viable.

### R-02: MockEtlFramework Parquet Writer

- **Risk:** Adding parquet output to the C#/.NET MockEtlFramework is harder than expected. The framework is C#; parquet writing in .NET is less mature than pyarrow.
- **Probability:** MEDIUM
- **Impact:** HIGH (need real output files to compare)
- **Mitigation:** Don't fight the .NET parquet ecosystem. Write a thin Python script that takes the PostgreSQL output and writes it as parquet files. The comparison tool doesn't care how the files were created -- it cares that they exist in the right format.
- **Contingency:** Use pre-built parquet test fixtures for the Proofmark demo. Less end-to-end, but still demonstrates the comparison capability.

### R-03: Scope Creep

- **Risk:** The TAR register identifies 15 tasks. Weekend scope creep is the #1 killer of POC deadlines. Dan and BD spend too long on polish, edge cases, or "just one more feature."
- **Probability:** HIGH
- **Impact:** HIGH (exhaustion, incomplete demo, missed deadline)
- **Mitigation:** Strict P0/P1/P2 prioritization. P0 tasks are the demo. P1 tasks make the demo better. P2 tasks don't happen this weekend. If it's Sunday night and P0 isn't done, everything else stops.
- **Contingency:** A working CSV comparison with a match report and an evidence package template is a viable demo even without parquet. Ship what works.

### R-04: Test-First Development Slows the Build

- **Risk:** The SDLC commitment (test cases BEFORE implementation, Dan reviews every test) creates overhead that conflicts with weekend speed.
- **Probability:** MEDIUM
- **Impact:** MEDIUM (slower progress, but the tests are part of the demo's credibility)
- **Mitigation:** Write tests and implementation in tight cycles. Dan reviews test batches, not individual tests. The review is a lightweight check ("does this test case make sense?"), not a formal approval gate. The SDLC story matters, but weekend SDLC is "rigorous intent," not "six-sigma process."
- **Contingency:** If test-first is blocking progress, write implementation first and add tests immediately after. Document that the formal SDLC was compressed for the POC. The production vendor build will have full test-first discipline.

### R-05: Information Isolation Demo Requires Full Pipeline

- **Risk:** Demonstrating information isolation (T-11) requires the entire pipeline working: Proofmark built, MockEtlFramework producing output files, a builder agent session configured with no Proofmark internals in context. This is the last piece and the most fragile.
- **Probability:** MEDIUM
- **Impact:** MEDIUM (information isolation can be described without live demo if necessary)
- **Mitigation:** Build the COTS interface (T-10) early, even before Proofmark is complete. The interface definition is independent of the implementation. If time runs out, the COTS README and CLI interface serve as evidence of the isolation design.
- **Contingency:** Show the builder agent's CLAUDE.md and the COTS README side by side. "Here's what the builder sees. Here's what it doesn't see." Narrative evidence instead of live demo.

### R-06: Token Costs for POC Run

- **Risk:** Running the expanded MockEtlFramework with builder agents plus Proofmark comparison could consume significant tokens if the comparison loop iterates many times.
- **Probability:** LOW
- **Impact:** LOW (POC token costs are small relative to the overall budget)
- **Mitigation:** Limit the comparison window for the demo (e.g., 5 dates instead of 31). The demo shows the concept; it doesn't need to prove convergence across a full month.
- **Contingency:** Pre-compute some comparison results if live execution is too slow for a demo setting.

### R-07: Dan's Availability

- **Risk:** Dan has other weekend commitments. If his review bandwidth is limited, the test-first SDLC commitment creates a bottleneck.
- **Probability:** UNKNOWN
- **Impact:** HIGH (Dan reviews every test case; no review = no SDLC compliance)
- **Mitigation:** Batch test reviews. Send Dan a batch of 10-15 test cases at once for a single review session rather than individual approvals.
- **Contingency:** BD proceeds with implementation on test cases that follow established patterns (e.g., "same structure as the first three Dan approved") and flags any novel test cases for separate review.

---

# Section 5: The March 24 Narrative

## The Story Dan Tells the CIO

### The Opening: Start with the Problem, Not the Solution

Do NOT open with "let me show you a tool" or "we built an AI system." Open with the problem everyone in the room already knows about.

> "We have tens of thousands of ETL jobs on our data platform. Most were written by rotating teams over years, documented poorly or not at all, and riddled with inefficiencies nobody touches because nobody fully understands them. This isn't a technology problem. It's a balance sheet problem. We're paying for complexity we didn't choose. And every day we don't address it, we accumulate operational risk from a platform nobody fully controls."

Pause. Let that land. Every executive in the room has heard this complaint from their teams. This is not news. This is validation.

> "The traditional approach to fixing this is a multi-year rewrite by a large team of contractors. That's a $50-100 million engagement that takes 3-5 years and has a mixed track record at best. We found a different approach."

### The POC Results: Lead with Numbers

> "We ran a proof of concept. 32 ETL jobs, processed autonomously by AI agents. Results: 100% output equivalence across every job and every date in the comparison window. 56% reduction in code volume. 115 anti-patterns identified and addressed. Four hours and nineteen minutes, zero human intervention during execution."

Then immediately undercut the impression that you're selling:

> "Those numbers are real, but they're from a controlled environment with synthetic data. We are not here to tell you this is production-ready. We are here to tell you we've found something that works in the lab, and we have a credible plan to take it to production -- with your skepticism built into the governance model."

### The Governance Story: Three Layers

> "The question everyone asks about AI-generated code is: who checks the AI's work? Here's our answer. Three layers, no single point of control."

**Layer 1: Deterministic comparison.** "We built an independent comparison tool -- think of it as a proof house stamp. The tool checks whether the AI's output matches the original. This comparison is mathematical. You cannot produce wrong data that passes an exact match check. The AI that writes the code never sees how the comparison tool works. Even if it did, it couldn't game exact equivalence."

**Layer 2: Human domain expert review.** "For every job that feeds a critical data product, a human domain expert reviews the inferred business requirements. Not the code -- the requirements. Does the AI correctly understand what this job is supposed to do? This is where organizational independence lives. The reviewers are from the business, not the project team."

**Layer 3: Independent governance function.** "The overall methodology -- how we compare, what thresholds we use, how we sample for review -- is owned by an organizationally independent function. The CRO's team co-authored this framework. They're not reviewing our work after the fact. They helped design the controls."

### The Proofmark Strategy: Neutralize the "Weekend Project" Attack

This is where you flip the adversarial concern into a strength.

> "The comparison tool I just showed you is called Proofmark. I built it to prove the architecture works. It handles parquet files, CSV files, and the three-tier comparison model. It's working software, not a PowerPoint slide."

Pause.

> "It is also a proof of concept. The production comparison tool will not be Proofmark. Our recommendation is to hire an independent systems integrator -- Infosys, Accenture, or equivalent -- to build the production version. Proofmark becomes the functional specification: 'build this, but for real.'"

> "This achieves three things. First, true organizational independence -- a different vendor, different team, different management chain. Second, formal SDLC that satisfies Technology Risk. Third, it eliminates the 'one guy built it over a weekend' concern entirely. The weekend project becomes the spec. The production tool is built by a firm your auditors already trust."

### Preemptive Concern Responses: The Top 5

Address these before anyone asks. This demonstrates awareness and earns credibility.

**1. "How do you validate AI-generated code before production?"**
> "Three layers: deterministic comparison, human domain review, organizationally independent governance. The comparison tool will be built by an external vendor. No single person or system controls all three layers."

**2. "What about regulatory compliance? SR 11-7?"**
> "We're treating the AI system as a model for governance purposes. MRM registration will be initiated during Phase 1. The CRO is co-authoring the governance framework. We plan to brief the OCC proactively -- before they ask, not after they find out."

**3. "What does this cost?"**
> "Phase 1, all-in, expected case: $2-3 million. Three scenarios are in the cost model. Against a $750 million opportunity -- even at 10% realization -- the ROI speaks for itself."

**4. "What if the AI makes a mistake?"**
> "We maintain full rollback capability. Legacy code stays operational for a minimum of 12 months after V2 promotion for any critical job. We run old and new in parallel for a full business cycle before any switchover. We risk-tier our controls: regulatory reporting jobs get the most scrutiny. If anything goes wrong at any point, we stop and investigate. The kill switch is real."

**5. "Who owns this if it goes wrong?"**
> "The CDO is the executive sponsor. A steering committee -- CDO, CIO, CRO, and me as technical lead -- meets monthly with stage gates at 1, 10, and 50 jobs. Each gate requires steering committee approval to advance."

### The Ask: Not Approval to Deploy -- Approval to Continue

> "We are not asking you to approve production deployment. We're asking you to continue Phase 1 under the conditions you've already set. Here's the progress against those conditions."

Then walk through the CEO's six non-negotiables and show status on each.

> "The ask is straightforward: continue the pilot, fund the vendor engagement for the production comparison tool, and let us bring you the Phase 1 results in [X] months. If it works, we come back with a Phase 2 proposal. If it doesn't, we've spent $2-3 million and learned something valuable."

### The Close: Competitive Framing

> "Every bank our size is running AI pilot programs. Most are chatbots and document summarizers. This is categorically different: using AI to perform a structural transformation of core data infrastructure. The first institution to do this with the OCC's awareness and acceptance defines the playbook. I would rather we be the ones writing it."

---

## Appendix: Task Priority Summary

| Priority | Tasks | Weekend Status |
|----------|-------|----------------|
| **P0** | T-01 through T-06, T-08, T-09, T-12 | Must complete |
| **P1** | T-07, T-10, T-11, T-13, T-14, T-15 | Should complete |
| **P2** | (none identified) | -- |

## Appendix: Concern Response Strategy Summary

| Strategy | Count | Examples |
|----------|-------|---------|
| **Demonstrated in POC** | 4 | Proofmark working, comparison strategies, three-tier model, evidence package |
| **Addressed in presentation narrative** | 14 | SoD three-layer model, cost model, regulatory framing, rollback plan, sponsor, steering committee |
| **Deferred to vendor build** | 3 | Production comparison tool, formal SDLC for comparison tool, organizational independence |
| **Deferred to Phase 1 prototype** | 8 | Audit trail provenance, change management, incident response, downstream impact assessment, executable tests, code review policy, targeted restart |
| **Accepted risk with mitigation** | 3 | Constraint workaround unpredictability, anti-pattern guide completeness, model capability regression |
| **Institutional process (initiated post-approval)** | 3 | TPRA, PIA, MRM registration |

## Appendix: Critical Path for the Weekend

```
Day 1 (Saturday):
  Morning:  T-12 (test cases designed, Dan review batch 1)
            T-01 (comparison engine core)
            T-08 (MockEtlFramework output types -- parallel track)
  Afternoon: T-03 (CSV reader)
             T-04 (trailing control record)
             T-02 (parquet reader)
  Evening:  T-05 (per-job config schema)
            T-06 (match report generator)

Day 2 (Sunday):
  Morning:  T-09 (cost model -- Dan-driven, BD provides data)
            T-13 (adversarial test cases)
            T-10 (COTS interface design)
  Afternoon: T-07 (evidence package template)
             T-11 (information isolation dry run)
             T-14 (concern response matrix)
  Evening:  T-15 (CIO narrative outline)
            Final integration testing
            Dan reviews everything
```

This schedule assumes approximately 16 hours of focused work across two days. Scope is aggressive but achievable if P0 tasks stay clean and scope creep is ruthlessly managed.

---

*This TAR register is a living document. Update it as tasks complete and new risks materialize. The March 24 presentation narrative will evolve as Phase 1 progress provides real data points to replace projections.*
