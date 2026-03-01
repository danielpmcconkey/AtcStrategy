# Project ATC: Joint Risk Assessment — Risk Partner Evaluation

**Authors:**
- Partner 1a — Compliance & Regulatory Risk (12 years GSIB experience)
- Partner 1b — Operational & Technology Risk

**Date:** 2026-02-27
**Classification:** INTERNAL — RISK ASSESSMENT — DO NOT DISTRIBUTE WITHOUT RISK COMMITTEE APPROVAL
**Distribution:** CIO, CRO, Head of Technology Risk, Head of Model Risk, Head of Operational Risk, Project Sponsor

---

## Prefatory Note

This assessment was requested by the Risk Committee following receipt of a project proposal ("Project ATC") to deploy autonomous AI agent swarms for large-scale reverse-engineering and rebuilding of production ETL infrastructure at this institution. The project proposes that AI agents, powered by Anthropic's Claude large language model, will autonomously analyze tens of thousands of ETL jobs, infer business requirements from code and data, produce improved replacement code, and validate output equivalence using an independently developed comparison tool called "Proofmark."

We have reviewed the following materials:
1. MockEtlFramework POC documentation (ProjectSummary.md, Phase3 artifacts)
2. Proofmark design session notes (001-initial-design-2026-02-27.md)
3. Production deployment plan (KickoffPrompt.md)
4. Prior adversarial technical review (SkepticReport.md — 48 concerns)
5. Prior balanced technical evaluation (EvaluatorReport.md — concern-by-concern adjudication)

We have also reviewed the CLAUDE.md instruction sets governing agent behavior, the Phase 3 comparison logs, the governance artifact templates, and the Proofmark CLAUDE.md.

This is a joint assessment. Sections are attributed to the relevant partner. The risk register is unified with clear ownership markers. Our job is not to determine whether this technology is interesting. Our job is to determine whether this institution can deploy it within its regulatory, operational, and governance obligations.

---

# SECTION A: COMPLIANCE & REGULATORY RISK ASSESSMENT

**Author: Partner 1a**

## A.1 SR 11-7 Applicability — Is This a Model?

The OCC's Supervisory Guidance on Model Risk Management (SR 11-7, April 2011; OCC Bulletin 2011-12) defines a model as "a quantitative method, system, or approach that applies statistical, economic, financial, or mathematical theories, techniques, and assumptions to process input data into quantitative estimates." The guidance further states that the definition "covers quantitative approaches whose inputs are partially or wholly qualitative or based on expert judgment, provided that the output is quantitative in nature."

**The AI agent swarm is a model under SR 11-7.** It takes input data (source code, configuration files, database contents), applies a complex computational method (large language model inference), and produces quantitative outputs (rewritten code that determines data transformation outcomes across financial data). The fact that the intermediate outputs include natural language (BRDs, FSDs) does not exempt it — the terminal output is executable code that directly determines the values in curated financial datasets consumed by downstream risk, finance, and reporting systems.

**Proofmark may also be a model under SR 11-7**, depending on implementation. If Proofmark applies tolerance thresholds, statistical profiling, or configurable exclusion logic to render a pass/fail determination on output equivalence, it is making a quantitative determination that directly influences a production promotion decision. The three-tier threshold model described in the design session (Tier 1: excluded columns, Tier 2: exact match, Tier 3: tolerance-based comparison) is a decision framework with configurable parameters. Under SR 11-7, the threshold configuration and exclusion logic constitute model assumptions that require documentation, validation, and ongoing monitoring.

**Regulatory Finding (RF-01):** No model risk management framework has been proposed for either the agent swarm or Proofmark. There is no model inventory registration, no model validation plan, no model owner designation, no ongoing monitoring protocol, and no annual model review schedule. SR 11-7 requires all of these.

**Regulatory Finding (RF-02):** The project materials describe no interaction with the institution's Model Risk Management (MRM) function. MRM has not reviewed, approved, or been consulted on the methodology, the validation approach, or the governance model. This is a threshold regulatory violation — no model may be deployed at this institution without MRM sign-off.

## A.2 Audit Trail and Regulatory Reconstruction

Federal regulators — including the OCC, the Federal Reserve, and the FDIC — require that institutions maintain records sufficient to reconstruct business decisions and data processing activities. The OCC's Heightened Standards (12 CFR Part 30, Appendix D) require a "comprehensive system of internal controls" with "documented policies, procedures, and processes" sufficient to ensure data integrity and auditability.

BCBS 239 (Principles for Effective Risk Data Aggregation and Risk Reporting, January 2013) Principle 2 (Data Architecture and IT Infrastructure) requires that "a bank's data architecture and IT infrastructure should fully support its risk data aggregation capabilities and risk reporting practices... under both normal and stress conditions." Principle 6 (Adaptability) requires the ability to "produce aggregated risk data that can be used for a broad range of ad hoc risk management reporting requests, including requests during stress situations and during periods of market and economic turbulence."

**The audit trail for AI-generated code is fundamentally novel and untested with regulators.** The project proposes that for each of tens of thousands of ETL jobs, an AI agent will:
1. Analyze source code, configuration, and database state
2. Produce a Business Requirements Document with evidence citations
3. Design and implement replacement code
4. Validate output equivalence through automated comparison
5. Package the evidence for human review

**Critical question: Can this institution demonstrate, for any specific job, the complete chain of reasoning from original code to inferred requirement to replacement implementation to validation result?**

The POC evidence suggests a qualified yes — the Phase 3 artifacts include BRDs with file:line citations, FSDs tracing to BRD requirements, and comparison logs with per-table-per-date results. However:

**Regulatory Finding (RF-03):** The evidence citations in BRDs reference line numbers in source files that are specific to a point in time. Post-migration, the original code remains in the repository, but the citations are not tied to a specific commit hash or immutable artifact version. Under examination, a regulator could challenge the provenance of any citation. The Phase 3 reviewer caught an off-by-one line citation error (Phase3Observations.md, Check #2). At scale, citation accuracy degrades, and there is no automated verification that citations remain valid.

**Regulatory Finding (RF-04):** The BRDs, FSDs, and governance reports are produced by the same AI system whose output they are attesting to. Under SR 11-7 Section V.3 ("Effective Challenge"), effective challenge requires "critical analysis by objective, informed parties." The agent-produced evidence package fails the objectivity requirement. The Evaluator Report (C-25, C-26) concurs, rating this as a HIGH concern. The human spot-check protocol recommended by the Evaluator is necessary but not sufficient — regulators will expect the validation methodology itself to be independently validated, not just spot-checked.

**Regulatory Finding (RF-05):** The project proposes that governance teams review "evidence packages, not code" (KickoffPrompt.md, Phase 2). This creates a dependency on the evidence package's accuracy that has no independent verification mechanism at scale. Under OCC Heightened Standards, "front line units should have an effective process to identify, measure, and monitor the risks of their activities." Reviewing only the AI-produced summary, without independent access to the underlying comparison methodology's correctness, does not constitute effective monitoring.

## A.3 Regulatory Disclosure and Precedent

**Regulatory Finding (RF-06):** There is no established regulatory precedent for AI-generated production code at a GSIB, particularly for data transformation logic that feeds risk reporting, financial reporting, and regulatory reporting pipelines. When the OCC asks — and they will ask — "how was this code produced?", the answer is "an AI large language model autonomously inferred business requirements and wrote replacement code, validated by an AI-assisted comparison tool." This institution must be prepared for examiner scrutiny that currently has no established playbook.

The OCC's Third-Party Risk Management guidance (OCC Bulletin 2013-29, updated 2023-17) states that institutions "should ensure that their operations are not adversely affected by activities conducted by third parties." Anthropic, the provider of Claude, is a third party whose model behavior directly determines the quality of production code. The project materials contain no reference to a Third-Party Risk Assessment (TPRA) for Anthropic.

**Regulatory Finding (RF-07):** No Third-Party Risk Assessment exists for Anthropic. Required elements include: financial stability assessment, business continuity and disaster recovery capabilities, data security and privacy practices, subcontractor management, model versioning and stability guarantees, data residency and sovereignty compliance, incident notification obligations, and contractual right-to-audit provisions.

## A.4 Data Governance and Classification

**Regulatory Finding (RF-08):** The project proposes that AI agents will have read access to production data for validation purposes. The project materials do not address data classification implications. At this institution, production data is classified under a tiered data governance framework. AI agent access to production data — even read-only — constitutes a new data processing activity that must be assessed under the institution's Data Loss Prevention (DLP) policy, Privacy Impact Assessment (PIA) requirements, and applicable data residency rules.

Specifically: if production data transits to Anthropic's API for processing (as it does when agents analyze database contents using the LLM), this constitutes data transmission to a third party. The project materials do not address:
- Whether production data is sent to Anthropic's API during agent analysis
- If so, whether the data is classified as Restricted, Confidential, or Internal
- Whether Anthropic's data processing agreement (DPA) permits this use
- Whether the data traverses jurisdictional boundaries (data residency)
- Whether the institution's records retention obligations apply to API interactions

The KickoffPrompt.md states agents will have "read-only access to production data for validation — zero write permissions outside their sandboxed namespace." This confirms agents process production data. The CLAUDE.md instruction set confirms agents execute SQL queries against production databases and transmit query results through the LLM for analysis.

**Regulatory Finding (RF-09):** The project has not conducted a Privacy Impact Assessment (PIA) for AI agent processing of production data. Depending on the datasets involved (customer data, transaction data, credit data), this may implicate GLBA (Gramm-Leach-Bliley Act) requirements, state privacy laws, and the institution's own privacy policy commitments to customers.

## A.5 Segregation of Duties

The project claims that "information isolation" between the builder agent (which rewrites ETL jobs) and Proofmark (which validates the output) constitutes segregation of duties. The Proofmark design session states: "This is real segregation of duties through information isolation, not authorship theater."

**I disagree.**

Segregation of duties under COSO Internal Control Framework (which this institution has adopted) requires that "no single individual should control all key aspects of a transaction or event." The FFIEC IT Examination Handbook (Information Security, Section II.C.7) states that segregation of duties "reduces the risk of error or fraud by dividing the tasks and associated privileges among multiple people."

**The operative word is "people."**

Information isolation between two AI instances, both governed by the same individual (Dan), both running on the same infrastructure, both using the same underlying model (Claude), does not satisfy the regulatory definition of segregation of duties. The design session's own framing reveals the problem: "Dan reviews and approves every test case personally." Dan is the sole human in both the builder pipeline and the validation pipeline. He designed the builder agent's instructions (CLAUDE.md). He designed Proofmark's architecture. He reviews Proofmark's test cases. He is the single human point of control across the entire system.

**Regulatory Finding (RF-10):** The claimed segregation of duties does not satisfy regulatory requirements under COSO, FFIEC, or this institution's own Segregation of Duties Policy. Information isolation between AI agents is a technical control, not a governance control. Regulatory segregation requires independent human oversight of the validation function by personnel who are organizationally independent from the development function. The fact that the builder agent doesn't know about Proofmark's internals is irrelevant if the same human designed, built, tested, and approves both systems.

**Regulatory Finding (RF-11):** There is no independent validation function as defined by SR 11-7 Section V.2. The guidance states: "Validation involves a set of activities intended to verify that models are performing as expected, in line with their design objectives and business uses. It encompasses all the activities carried out by the validation group." The "validation group" must be "independent of the development and use of the model" and have "appropriate expertise, authority, and corporate stature." A single technical lead who designed both the model and its validation tool is the antithesis of this requirement.

## A.6 Proofmark as an Independent Validation Tool

Proofmark is described as being in early design phase. The design session document (001-initial-design-2026-02-27.md) records an active design conversation with significant open questions. The "Weekend Scope" section targets Delta Parquet, simple CSV, and CSV with trailing control record — three of an indeterminate number of output types.

**Regulatory Finding (RF-12):** Proofmark has not undergone Software Development Life Cycle (SDLC) review by the institution's Technology Risk function. It has no formal requirements document (the design session is an informal conversation transcript, not a requirements specification). It has no formal test plan approved by QA. It has no change management record. It has no production readiness review. The claim that it follows "traditional SDLC" (Proofmark CLAUDE.md) is aspirational — at the time of this review, Proofmark is a design concept, not a delivered product.

**Regulatory Finding (RF-13):** The Proofmark design session explicitly states it was built "over a weekend" (as referenced in the project proposal). Weekend development timelines are not consistent with the institution's SDLC governance requirements, which mandate documented requirements, peer-reviewed design, approved test plans, independent QA validation, and production readiness review prior to deployment in a production governance role.

---

# SECTION B: OPERATIONAL & TECHNOLOGY RISK ASSESSMENT

**Author: Partner 1b**

## B.1 Change Management

The institution's Change Management Policy (CMP) requires that all changes to production systems follow the established change management process, including: Change Request documentation, Change Advisory Board (CAB) review, impact assessment, test evidence, rollback plan, and post-implementation review.

**Operational Finding (OF-01):** The project proposes deploying AI-generated code to production without specifying how that code enters the existing change management process. The KickoffPrompt.md describes an "attestation package" per job, but this package is a project-specific governance artifact, not a Change Request as defined by this institution's CMP. Who submits the Change Request? Who reviews the code? The project says governance teams review "evidence packages, not code" — but CMP requires that code changes be reviewed by qualified personnel who understand the code being deployed.

**Operational Finding (OF-02):** The project's code review model is fundamentally different from the institution's existing code review process. In the current process, a human developer writes code, another human developer reviews it, and both are accountable. In the proposed process, an AI agent writes code, another AI agent reviews it (the "Watcher Protocol"), and a human reviews an evidence summary. The institution's Code Review Policy requires that "all production code changes are reviewed by at least one qualified developer who did not write the code." An AI agent is not a "qualified developer" under any current policy definition.

**Operational Finding (OF-03):** At the proposed scale (50-100 jobs in 120 days, scaling to thousands), the volume of Change Requests will overwhelm the existing CAB process. The project does not propose a batched or expedited change management pathway. Either every job is a separate Change Request (CAB bottleneck), or jobs are batched (increased blast radius per change). Neither approach has been discussed with the Change Management Office.

## B.2 Production Stability and Blast Radius

**Operational Finding (OF-04):** The project's comparison methodology validates output equivalence for a defined comparison window (e.g., Oct 1-31 in the POC). It does not validate behavior outside that window. Seasonal patterns, year-end processing, leap year handling, fiscal calendar boundaries, and regulatory reporting period cutoffs are all potential sources of behavioral divergence that will not manifest in a 31-day comparison window. The POC explicitly used synthetic data with no such edge cases.

**Operational Finding (OF-05):** The blast radius of a defective AI-rewritten job depends on downstream consumers. The project materials do not include a downstream impact assessment. If a rewritten ETL job feeds a risk aggregation pipeline, a regulatory reporting pipeline, or a financial reporting pipeline, a subtle output difference that passes Proofmark could propagate into material misstatement of risk or financial position. This is not theoretical — this institution's curated data layer feeds CCAR/DFAST stress testing, Basel III capital calculations, and SEC/FINRA reporting.

The Skeptic Report (C-15 through C-18) identifies several categories where output equivalence comparison may miss behavioral differences: non-deterministic output, stateful transformations, and external side effects. The Evaluator Report downgrades these to MEDIUM severity. **I disagree with the downgrade for our context.** In a GSIB feeding regulatory reporting pipelines, a subtle behavioral difference that manifests only during a stress testing window or quarter-end processing cycle is not a MEDIUM risk. It is a potential material weakness finding.

**Operational Finding (OF-06):** The "Output is King" principle (KickoffPrompt.md) assumes that if the original output was acceptable to the business, equivalent output is also acceptable. This assumption fails when the original output contained a latent error that was never detected. The rewritten job faithfully reproducing that error passes the comparison — but the institution now has two jobs producing wrong output instead of one, and a governance artifact attesting that the rewrite is correct. This converts an unknown defect into an attested defect, which has worse regulatory implications than the original unknown defect.

## B.3 Rollback and Recovery

**Operational Finding (OF-07):** The project has no rollback plan. The KickoffPrompt.md describes a scaling ladder (1 -> 10 -> 50 -> 100) but does not describe what happens when a rewritten job fails in production. Specific questions:

1. If 50 jobs have been rewritten and deployed, and job #47 is found to produce incorrect output post-deployment, can job #47 be rolled back independently without affecting the other 49?
2. If the 50 jobs have inter-dependencies, what is the rollback sequence? Does rolling back job #47 require rolling back its downstream consumers?
3. What is the Mean Time to Recovery (MTTR) for an AI-rewritten job that fails in production? The team that maintains the jobs did not write the code. Even with documentation, debugging AI-generated code requires understanding the agent's decision chain.
4. The Skeptic Report (C-48) notes that "legacy curated zone is decommissioned" after V2 promotion. If V2 has a latent defect discovered after decommission, what is the recovery path? The Evaluator says "re-run the legacy code" — but on what infrastructure? With what configuration? After how much time has elapsed?

**Operational Finding (OF-08):** The project does not define a parallel-run period. Standard institutional practice for production migrations of this criticality requires a minimum 90-day parallel-run period where both old and new systems produce output, results are compared daily, and any divergence triggers investigation. The project's comparison methodology (Proofmark + pre-deployment validation) is positioned as a replacement for parallel run. This is not acceptable for systems feeding regulatory reporting.

## B.4 Testing

**Operational Finding (OF-09):** The POC's "test plans" (31 markdown documents with prose descriptions) were never executed. The Skeptic Report (C-37) and Evaluator Report both confirm this. The comparison loop (EXCEPT-based SQL across 31 dates) is the actual validation — but it tests output equivalence, not business rule correctness. These are different things. A job can produce equivalent output for the wrong reasons (e.g., two bugs that cancel out, or a test window that doesn't exercise an edge case). The institution's Testing Policy requires that production code changes be validated by executed test cases that map to business requirements, not just output comparison.

**Operational Finding (OF-10):** Proofmark, the proposed independent validation tool, does not exist yet. As of this review, it is a design conversation captured in a markdown file. It has no code, no tests, no deployment artifacts. The project timeline assumes Proofmark will be built, tested, and production-ready in time to validate the first batch of rewritten jobs. The project materials offer no contingency if Proofmark development encounters delays, defects, or design inadequacies.

**Operational Finding (OF-11):** The project proposes that Proofmark will be "tested through traditional SDLC" with "Dan reviewing every test case." Dan is one person. One person reviewing all test cases for a validation tool that will make pass/fail determinations on thousands of production ETL jobs does not constitute adequate test governance. The institution's QA function has not been engaged. Independent testing by a separate QA team is required for any tool in a production governance role.

**Operational Finding (OF-12):** Who tested the tester? Proofmark's correctness is assumed, not proven. If Proofmark has a bug in its comparison logic (e.g., it silently truncates DECIMAL(38,18) to DECIMAL(38,2) during parquet comparison), every job it validates is potentially compromised. The design session mentions "Independent Claude reviewers audit the tool for gaps" — but this is the same circularity problem identified in the agent swarm: AI reviewing AI. There is no plan for independent human validation of Proofmark's comparison logic by a party other than its developer.

## B.5 Incident Response

**Operational Finding (OF-13):** There is no incident response runbook for AI-rewritten jobs. If a production incident is traced to an AI-rewritten ETL job, the current incident response process assumes a human developer wrote the code, understands the logic, and can diagnose the issue. For AI-generated code:

1. Who is on call? The three developers assigned to the project? They did not write the code.
2. What is the diagnostic procedure? Read the BRD, then the FSD, then the code? The evidence package is optimized for governance review, not production debugging.
3. Can the on-call team reproduce the agent's reasoning? The agent's context window, intermediate reasoning, and decision chain are ephemeral — they exist during the session and are not persisted in a debuggable format.
4. What is the escalation path if the on-call team cannot diagnose the issue? Call Anthropic? Anthropic has no SLA for production incident support for agent-generated code.

**Operational Finding (OF-14):** The institution's Incident Management Policy requires a Root Cause Analysis (RCA) for all P1 and P2 incidents. For AI-generated code, the root cause may be: (a) an incorrect business requirement inference, (b) a correct requirement with incorrect implementation, (c) a comparison tool deficiency that allowed the defect through, or (d) a model behavior change due to an Anthropic update. Categories (a) through (c) are diagnosable from the evidence package. Category (d) may not be — if Anthropic updates Claude between the time the code was generated and the time the incident occurs, reproducing the original reasoning may be impossible.

## B.6 Dependency Risk and Vendor Stability

**Operational Finding (OF-15):** The entire project depends on a single vendor: Anthropic's Claude model. The project materials reference specific model behavior observed during the POC (e.g., Claude's tendency to create workaround code when faced with constraints, the quality improvement between Run 1 and Run 2 reviewer behavior). These behaviors are properties of a specific model version at a specific point in time.

Anthropic updates Claude regularly. Model updates can change:
- Reasoning quality (could improve or degrade)
- Instruction following fidelity
- Code generation patterns
- Hallucination rates
- Context window utilization efficiency

The project materials contain no model version pinning strategy. The KickoffPrompt.md does not specify which version of Claude will be used. If the team develops and tests instructions on Claude Opus 4.6 and Anthropic releases Opus 5, every instruction set, guardrail, and behavioral assumption must be revalidated. The POC demonstrated that instruction quality matters enormously (Run 1 vs Run 2 performance difference was driven entirely by instruction changes, not model changes). A model change is an instruction-quality-change multiplied across every interaction.

**Operational Finding (OF-16):** There is no contractual SLA with Anthropic for model availability, performance, or behavioral consistency. If Anthropic experiences an outage, rate-limits the institution, deprecates the model version in use, or changes pricing, the project has no continuity plan. The institution's Business Continuity Policy requires that critical vendor dependencies have documented continuity plans, including alternative supplier arrangements.

## B.7 Scalability

**Operational Finding (OF-17):** The POC processed 32 jobs with synthetic data. The production target is 50-100 jobs in the first phase, eventually scaling to tens of thousands. The project materials identify no specific scalability risks beyond the Skeptic Report's concerns. Specific unexamined scalability issues:

1. **Database load:** During the comparison loop, agents execute SQL queries against production databases for each job, each date, each comparison iteration. At 100 jobs x 365 dates x 5 iterations, that is 182,500 query pairs. What is the impact on production database performance? Has capacity planning been engaged?

2. **Concurrent agent sessions:** The architecture proposes "hundreds of parallel agents." Each agent session consumes API resources, maintains state, and may hold database connections. What are the concurrency limits? What happens when agents contend for the same database resources?

3. **Evidence storage:** Each job produces a BRD, FSD, test plan, comparison log, and governance report. At 50,000 jobs, that is 250,000+ artifacts. Where are they stored? How are they indexed? How does the governance team navigate them? How are they retained per the institution's records retention policy?

4. **Comparison loop at scale:** The POC's full-truncate-and-restart protocol is acknowledged as unscalable by both the Skeptic and Evaluator reports. The Evaluator recommends "targeted restart" as a Tier 2 action item. This is architecturally significant — it changes the comparison loop from stateless (always restart from scratch) to stateful (track what has been validated and what needs re-validation). The stateful design has not been specified, let alone tested.

---

# SECTION C: UNIFIED RISK REGISTER

Items are numbered RR-NNN. Severity scale: CRITICAL (must remediate before any deployment), HIGH (must remediate before production deployment), MEDIUM (must remediate before full-scale deployment), LOW (monitor and address as encountered).

## CRITICAL Severity

| ID | Risk | Owner | Regulatory/Policy Basis | Description | Required Remediation |
|----|------|-------|------------------------|-------------|---------------------|
| RR-001 | No Model Risk Management framework | 1a | SR 11-7; OCC 2011-12 | Neither the agent swarm nor Proofmark has been registered in the model inventory, assessed by MRM, or validated per SR 11-7 requirements. No model owner designated. No validation plan. No ongoing monitoring protocol. | Register both systems in the model inventory. Engage MRM for initial model validation. Designate a model owner. Develop a model monitoring plan including performance metrics, back-testing requirements, and annual review schedule. MRM must approve before any production deployment. |
| RR-002 | Segregation of duties violation | 1a | COSO ICF; FFIEC IT Handbook; SR 11-7 V.2; Institutional SoD Policy | A single individual (the project lead) designed, built, and controls both the builder agent pipeline and the independent validation tool (Proofmark). Information isolation between AI instances does not satisfy regulatory SoD requirements. | Assign an organizationally independent team to own, develop, and operate the validation function. The validation tool's test cases and comparison methodology must be reviewed and approved by personnel who have no role in the builder agent pipeline. At minimum, the institution's existing QA function or a designated second-line validation team must own Proofmark's acceptance criteria. |
| RR-003 | No Third-Party Risk Assessment for Anthropic | 1a | OCC 2013-29 / 2023-17; Institutional TPRA Policy | Anthropic is a critical vendor — the entire project depends on their model. No TPRA has been conducted. No assessment of data handling, model stability, contractual protections, or business continuity. | Complete a TPRA for Anthropic per institutional policy. Include: data processing agreement review, data residency assessment, model versioning and deprecation policy, incident notification obligations, right-to-audit provisions, financial stability assessment, subprocessor disclosure. TPRA must be approved by Third-Party Risk Committee before production data is processed through the API. |
| RR-004 | Production data processing without PIA | 1a | GLBA; State Privacy Laws; Institutional PIA Policy | AI agents will process production data (customer records, transaction data, financial data) by executing SQL queries and sending results to Anthropic's API for LLM analysis. No Privacy Impact Assessment has been conducted. Data classification of processed data has not been determined. | Conduct a PIA covering all data categories the agents will access. Determine data classification under institutional policy. Assess whether data transmitted to Anthropic's API complies with GLBA requirements, the institution's DPA with Anthropic, and any applicable data residency requirements. If Restricted or Confidential data is involved, engage Information Security and Legal before proceeding. |
| RR-005 | No independent validation function | 1a | SR 11-7 V.2; Institutional Model Validation Policy | The evidence package (BRDs, FSDs, comparison results, governance reports) is produced entirely by the AI system being validated. No independent validation function as defined by SR 11-7 exists. The proposed human spot-check protocol (5-10% sample) is insufficient as the sole independent validation mechanism. | Establish a formal independent validation function staffed by personnel organizationally independent of the project team. This function must: (a) validate the comparison methodology itself using known test cases with deliberately introduced defects, (b) independently verify a statistically significant sample of agent-produced BRDs against subject matter expert knowledge, (c) audit the evidence package for completeness and accuracy, (d) report directly to the model owner and MRM, not to the project team. |
| RR-006 | Proofmark does not exist | 1b | Institutional SDLC Policy; Institutional Testing Policy | The proposed independent validation tool is in early design. No code, no tests, no deployment artifacts. The project timeline assumes Proofmark will be built, tested, and production-ready. There is no contingency plan if Proofmark is delayed or inadequate. | Proofmark must complete the institution's SDLC process: formal requirements, approved design, implementation, unit testing, integration testing, UAT, production readiness review. The SDLC must be conducted by or with oversight from the institution's Technology Risk function. Proofmark must not be used in a production governance capacity until it passes production readiness review. |

## HIGH Severity

| ID | Risk | Owner | Regulatory/Policy Basis | Description | Required Remediation |
|----|------|-------|------------------------|-------------|---------------------|
| RR-007 | Audit trail provenance | 1a | OCC Heightened Standards; BCBS 239; Institutional Records Retention Policy | Evidence citations in BRDs reference file:line locations not tied to immutable artifact versions. Post-migration, citations may become stale or unverifiable. Reviewer caught off-by-one errors in POC. | All evidence citations must reference immutable artifact identifiers (commit hashes, artifact version IDs). Original source code must be archived as an immutable artifact alongside the BRD. Automated citation verification must be implemented to confirm each citation resolves to the claimed content. |
| RR-008 | AI-generated code not covered by existing code review policy | 1b | Institutional Code Review Policy; CMP | Code review policy requires review by "at least one qualified developer who did not write the code." AI agents do not satisfy this definition. The Watcher Protocol (AI reviewing AI) is not a substitute. | Amend the Code Review Policy to address AI-generated code, OR require that all AI-generated code undergo human code review by a qualified developer before production deployment. This review must assess not just functional correctness but also coding standards, security implications, and maintainability. |
| RR-009 | No change management pathway defined | 1b | Institutional CMP | The project does not describe how AI-generated code enters the existing change management process. No interaction with the Change Management Office. No proposed approach for Change Request submission, CAB review, or post-implementation verification at scale. | Engage the Change Management Office. Define a change management pathway for AI-generated code changes, including: how Change Requests are submitted (per-job or batched), what evidence satisfies CAB review requirements, what the impact assessment process is for AI-generated changes, and what the post-implementation verification process is. |
| RR-010 | No downstream impact assessment | 1b | Institutional Change Impact Assessment Policy | The project does not identify downstream consumers of the curated data that AI-rewritten jobs produce. If curated data feeds CCAR/DFAST, Basel III, or SEC reporting, a subtle output difference is a potential material weakness. | Produce a downstream impact assessment for every curated table that AI-rewritten jobs produce. Identify all downstream consumers, their criticality classification, and the potential regulatory impact of incorrect data. Jobs feeding Tier 1 regulatory reporting must have enhanced validation requirements (extended comparison windows, additional human review). |
| RR-011 | No parallel-run period | 1b | Institutional Production Migration Policy | The project proposes pre-deployment validation as a replacement for parallel run. For systems feeding regulatory reporting, this is not acceptable. Production behavior may diverge from pre-deployment behavior due to data conditions, timing dependencies, or environmental differences. | Require a minimum 90-day parallel-run period for all AI-rewritten jobs feeding regulatory reporting pipelines. During parallel run, both old and new jobs produce output, results are compared daily, and any divergence triggers investigation. Jobs NOT feeding regulatory reporting may use a shorter parallel-run period (30 days minimum) with risk-based justification. |
| RR-012 | No incident response runbook | 1b | Institutional Incident Management Policy | No incident response procedure exists for production failures in AI-generated code. On-call teams are unfamiliar with the code. Agent reasoning is ephemeral. Root cause analysis for model-behavior-related failures may be impossible. | Develop an incident response runbook specific to AI-rewritten jobs. Include: diagnostic procedure using the evidence package, escalation path for failures not diagnosable from the evidence package, rollback procedure per job, communication templates for regulatory reporting if affected pipelines are impacted. Train the on-call team. Conduct a tabletop exercise before production deployment. |
| RR-013 | No rollback plan | 1b | Institutional Production Migration Policy | No rollback strategy defined. No assessment of whether individual jobs can be rolled back independently. No consideration of dependency ordering during rollback. Legacy decommission removes the fallback. | Define a per-job rollback procedure before production deployment. Maintain legacy execution capability for a defined period post-promotion (minimum 90 days). Validate that rollback can be performed for individual jobs without affecting other rewritten jobs. Document the dependency-aware rollback sequence. |
| RR-014 | Model version dependency | 1b | Institutional Vendor Management Policy; Institutional BCP | The project depends on a specific Claude model version. Anthropic updates models regularly, potentially changing reasoning quality, instruction following, and code generation patterns. No version pinning strategy. No regression testing protocol for model updates. | Document the model version in use. Establish a regression testing protocol: when Anthropic releases a new model version, re-run a representative sample of jobs and compare results before adopting the new version. Negotiate with Anthropic (through the TPRA process) for advance notification of model changes and a deprecation timeline that allows the institution to validate new versions before mandatory migration. |
| RR-015 | Credential and data security in agent sessions | 1b | Institutional Information Security Policy; Institutional DLP Policy | POC used policy-level enforcement only (CLAUDE.md instructions saying "never modify"). Production requires infrastructure-level enforcement. Agents decode database passwords from environment variables. At scale, hundreds of sessions with production credentials. | Implement infrastructure-level access controls before any agent accesses production data: read-only database users, Azure Key Vault for secrets management, network isolation of agent sandbox environments, comprehensive audit logging of all agent-executed database queries. Agents must never have direct access to credentials — use managed identity or service principal authentication. |
| RR-016 | Comparison methodology blind spots | 1a/1b | SR 11-7 (Model Limitation Documentation) | The output equivalence approach cannot validate: non-deterministic output, external side effects, behavior outside the comparison window, and latent errors in original code. These are documented limitations that must be disclosed to governance reviewers. | Document all known limitations of the comparison methodology in the governance framework. For each limitation, specify which jobs are affected, what additional validation is required, and what residual risk is accepted. Governance reviewers must acknowledge each limitation when reviewing evidence packages. Jobs with known comparison blind spots must have enhanced human review. |
| RR-017 | Single point of human control | 1a | COSO ICF; Institutional SoD Policy | One individual designed the agent instructions (CLAUDE.md), designed the validation tool (Proofmark), reviews all Proofmark test cases, and will serve as the validation authority. This creates key-person risk and violates SoD principles. | Distribute control across multiple individuals. Minimum: separate ownership of (a) agent instruction design, (b) validation tool development, (c) validation methodology approval, (d) evidence package review. No individual should participate in more than two of these four functions. |

## MEDIUM Severity

| ID | Risk | Owner | Description | Required Remediation |
|----|------|-------|-------------|---------------------|
| RR-018 | Comparison window adequacy | 1b | 31-day POC window did not exercise seasonal, year-end, or regulatory period-end patterns. Production comparison window must cover all relevant temporal patterns. | Define minimum comparison window requirements based on job classification: daily jobs require minimum 1 quarter including quarter-end; monthly jobs require minimum 6 months including year-end; regulatory reporting jobs require minimum 1 full reporting cycle. |
| RR-019 | CAB throughput bottleneck | 1b | At scale (50-100+ jobs), individual Change Requests will overwhelm CAB. Batched changes increase blast radius. | Work with Change Management Office to design an expedited pathway for AI-rewritten jobs that have passed the full validation process, including a batch review protocol with defined maximum batch size. |
| RR-020 | Evidence storage and retention | 1b | 50,000 jobs producing 5+ artifacts each = 250,000+ documents. No storage, indexing, or retention plan. Regulatory records retention obligations apply. | Design an evidence repository with appropriate indexing, search capability, and retention policy aligned to the institution's Records Retention Schedule. Evidence packages are regulatory records and must be retained per applicable retention periods (typically 5-7 years for operational records). |
| RR-021 | Database capacity impact | 1b | Comparison queries at scale (100 jobs x 365 dates x 5 iterations = 182,500 query pairs) may impact production database performance. | Engage capacity planning. Assess comparison query impact on production database performance. Consider dedicated read replicas for comparison queries to avoid production impact. |
| RR-022 | Stateful comparison loop design | 1b | The POC's full-truncate-and-restart protocol is acknowledged as unscalable. The proposed replacement (targeted restart) changes the comparison loop from stateless to stateful but has not been designed or tested. | Design and test the stateful comparison loop before scaling past the initial pilot. The stateful design must maintain a verifiable record of what has been validated and what needs re-validation after any code change. |
| RR-023 | Agent Teams feature maturity | 1b | The project uses Anthropic's Agent Teams feature, which is a relatively new capability with undocumented scaling behavior. | Document Agent Teams' observed behavior at each scaling step. Maintain a fallback plan (standard subagents) if Agent Teams exhibits reliability issues at production scale. |
| RR-024 | Comparison tool scope gaps | 1b | Proofmark's weekend scope covers 3 of an indeterminate number of output types. TIBCO MFT files may include XML, JSON, EBCDIC, or binary formats not yet designed for. | Complete a full inventory of output types across the target portfolio before beginning job rewrites. Ensure Proofmark supports every output type in the portfolio, or explicitly exclude unsupported types with documented risk acceptance. |
| RR-025 | Cost model absence | 1a/1b | No cost model exists for token costs, Azure compute, developer time, or iteration costs. Governance committee asked to approve without financial analysis. | Produce a three-scenario cost model (optimistic, expected, pessimistic) for Phase 1. Include token costs, Azure compute, developer opportunity cost, and contingency. Present to governance committee before authorization. |

## LOW Severity

| ID | Risk | Owner | Description | Required Remediation |
|----|------|-------|-------------|---------------------|
| RR-026 | Reviewer rubber-stamping at scale | 1a | POC Run 1 reviewer approved all BRDs on first pass despite quality issues. Reviewer quality may degrade at scale. | Monitor reviewer quality through human spot-checks at each scaling step. Tighten reviewer instructions if degradation detected. |
| RR-027 | Anti-pattern guide completeness | 1b | POC's anti-pattern categories were designed by the author. Real platform anti-patterns may not fit the taxonomy. | Extend the anti-pattern guide iteratively based on findings at each scaling step. Track discovery rate of new categories. |
| RR-028 | Context window management | 1b | At scale, agent context windows overflow, potentially causing degraded reasoning. | Monitor for signs of context degradation. Design orchestration hierarchy with appropriate delegation before scaling past 20 jobs. |
| RR-029 | Executive report headline accuracy | 1a | POC executive report headline ("15 External modules replaced with SQL") was found to be misleadingly compressed vs. the detailed data. | Require that evidence package summaries are reviewed for accuracy against underlying data before governance presentation. All claims must be verifiable from the evidence package without interpretation. |

---

# SECTION D: REQUIRED REMEDIATION ACTIONS — SEQUENCED

## Gate 0: Before Seeking Governance Authorization

These actions must be completed before the project is presented to the governance committee for Phase 1 authorization.

1. **Register with Model Risk Management.** Engage MRM. Register the agent swarm and Proofmark in the model inventory. Begin the model validation process. (RR-001)
2. **Complete Third-Party Risk Assessment for Anthropic.** Engage TPRM. Full assessment per institutional policy. (RR-003)
3. **Conduct Privacy Impact Assessment.** Engage Privacy Office. Assess data classification implications of AI processing of production data. (RR-004)
4. **Produce cost model.** Three scenarios. Token costs, compute, developer time, contingency. (RR-025)
5. **Resolve segregation of duties.** Assign independent validation function ownership to an organizationally independent team. (RR-002, RR-005, RR-017)

## Gate 1: Before First Production Data Access

These actions must be completed before any AI agent processes production data (as opposed to synthetic POC data).

6. **Implement infrastructure-level security controls.** Read-only users, Key Vault, network isolation, audit logging. (RR-015)
7. **Complete data governance assessment.** Confirm that data transmitted to Anthropic's API complies with all applicable data handling requirements. (RR-004, RR-008)
8. **Establish model version baseline.** Document the Claude model version in use. Define regression testing protocol for model updates. (RR-014)

## Gate 2: Before First Production Deployment

These actions must be completed before any AI-rewritten job is promoted to production.

9. **Proofmark completes SDLC.** Formal requirements, design, implementation, testing, production readiness review — all under Technology Risk oversight. (RR-006, RR-012)
10. **Amend Code Review Policy** (or define exception process) for AI-generated code. (RR-008)
11. **Define change management pathway.** Engage Change Management Office. (RR-009)
12. **Complete downstream impact assessment** for all curated tables affected. (RR-010)
13. **Define parallel-run requirements** based on downstream consumer criticality. (RR-011)
14. **Develop incident response runbook.** Train on-call team. Conduct tabletop exercise. (RR-012)
15. **Define per-job rollback procedure.** Validate rollback capability. (RR-013)
16. **Implement audit trail controls.** Immutable artifact versioning, automated citation verification. (RR-007)
17. **Document comparison methodology limitations.** Disclose to governance reviewers. (RR-016)
18. **Establish independent validation function.** Staff, authorize, and operationalize. (RR-005)

## Gate 3: Before Full-Scale Deployment

19. **Design and test stateful comparison loop.** (RR-022)
20. **Complete output type inventory and Proofmark coverage assessment.** (RR-024)
21. **Engage capacity planning for database query impact.** (RR-021)
22. **Establish evidence repository with retention compliance.** (RR-020)
23. **Design expedited change management pathway for scale.** (RR-019)

---

# SECTION E: CONDITIONAL VERDICT

## Partner 1a (Compliance & Regulatory Risk)

**I cannot approve this project in its current form.**

The project has six CRITICAL regulatory findings that must be remediated before any governance committee presentation, let alone production deployment. The most significant are:

1. **SR 11-7 non-compliance.** This is a model. It must be treated as a model. MRM has not been engaged. This alone is a regulatory violation.

2. **Segregation of duties failure.** "Information isolation between two AI instances controlled by the same person" is not segregation of duties. It is a novel construct with no regulatory precedent. The institution cannot present this to examiners as satisfying SoD requirements without inviting a Matter Requiring Attention (MRA).

3. **Third-party risk.** The institution is deploying a critical dependency on a vendor (Anthropic) with no TPRA, no DPA review, no data residency assessment, and no contractual protections documented in the project materials. This is a known deficiency that the OCC cites in examination findings.

4. **Data governance.** Production data will be processed through a third-party API without a PIA. Full stop.

I want to be clear: I am not saying this project cannot work. The POC results are technically impressive. The progressive scaling approach is sound engineering. But impressive technology deployed outside the institution's risk management framework is not innovative — it is reckless. This institution has consent orders and MOUs that constrain exactly this kind of unilateral deployment. The project team must engage Risk before presenting to the CIO, not after.

**My conditional approval requires:** Completion of all Gate 0 items, completion of all Gate 1 items, and a satisfactory model validation plan approved by MRM. With those in place, I would support a limited Phase 1 pilot on non-regulatory-reporting data with enhanced monitoring.

## Partner 1b (Operational & Technology Risk)

**I cannot approve this project in its current form.**

The operational gaps are significant. The project is asking this institution to deploy AI-generated code into production without:
- A defined change management pathway
- A code review process that addresses AI-generated code
- An incident response runbook
- A rollback plan
- A parallel-run period
- A downstream impact assessment
- A production-ready validation tool
- Database capacity planning

These are not bureaucratic objections. These are the basic operational controls that prevent a clever technology project from becoming a production incident that makes the Wall Street Journal. I have written post-mortems for projects that skipped exactly these steps. The post-mortems are not interesting reading.

The POC demonstrated genuine technical capability. The scaling plan is thoughtful. The governance model has the right instincts — evidence packages, adversarial review, progressive scaling. But the gap between "we demonstrated this on synthetic data in a sandbox" and "we deployed this into a GSIB's production data infrastructure" is not a technology gap. It is an operational maturity gap. Every item in my risk register is a standard operational control that this institution already requires for any production change. The project simply has not engaged with the existing operational framework.

**My conditional approval requires:** Completion of all Gate 0 through Gate 2 items for the first batch. For subsequent batches, the Gate 2 items become part of the standard deployment checklist. I would support a phased approach: Gate 0/1 completion unlocks a sandbox experiment with production data (but no production deployment); Gate 2 completion unlocks a limited production pilot with enhanced monitoring; Gate 3 completion unlocks scaling.

---

## Joint Recommendation

We recommend the following path forward:

1. **Pause any CIO presentation** until Gate 0 items are complete. Presenting to the CIO without MRM engagement, a TPRA, a PIA, or a cost model exposes the project sponsor to reputational risk if the CIO asks questions we know the regulatory function will ask later.

2. **Engage Risk as a partner, not a gate.** The project team should come to us now, not after the CIO says yes. We can work through the Gate 0 items in parallel with continued technical development. This is faster than getting CIO approval, then discovering the regulatory requirements, then going back to the CIO to explain the delay.

3. **Scope the initial pilot tightly.** Non-regulatory-reporting data only. Jobs with simple, deterministic output. Single output target (choose one and nail it). This gives the project the best chance of demonstrating success within the operational framework.

4. **Accept that the timeline will extend.** 120 days was already aggressive for the technical work. Adding the operational readiness work (SDLC for Proofmark, incident response, change management pathway, parallel run) adds time. A realistic timeline for a production-deployed pilot is 6-9 months, not 4.

The technology is promising. The approach is thoughtful. The governance model shows the right instincts. But this institution does not deploy "promising" and "thoughtful" into production. It deploys "validated," "controlled," and "approved." The project is not there yet. We are prepared to help it get there.

---

**Partner 1a — Compliance & Regulatory Risk**
*12 years GSIB Risk Partner experience. SR 11-7 SME. BCBS 239 implementation lead (2015-2017). OCC examination liaison (2018-present).*

**Partner 1b — Operational & Technology Risk**
*14 years Technology Risk experience. Change Management and SDLC governance. Production incident RCA lead. Three consent order remediation programs.*

**Date:** 2026-02-27
**Next Review:** Upon completion of Gate 0 items, or 30 days from this assessment, whichever is sooner.
