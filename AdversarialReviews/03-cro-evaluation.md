# Strategic Risk Assessment: Project ATC

**From:** Chief Risk Officer
**To:** Executive Committee
**Date:** 2026-02-27
**Classification:** CONFIDENTIAL -- Executive Risk Committee
**Subject:** AI-Driven ETL Modernization ("Project ATC") -- Risk Posture and Conditional Recommendation

---

## Executive Risk Summary

Project ATC proposes using autonomous AI agent swarms to reverse-engineer and rebuild the bank's ETL infrastructure -- tens of thousands of jobs on a production Big Data platform processing petabytes of data across every business line. The potential savings are real: $750MM in technical debt remediation is a credible estimate for a platform of this scale. A successful proof of concept demonstrates genuine technical capability. But the proposal asks this institution to allow AI systems to autonomously rewrite data pipelines that feed regulatory reporting, risk calculations, and client-facing products -- and the governance infrastructure around that capability is still under construction. **I would conditionally approve a tightly scoped Phase 1 pilot with enhanced governance controls. I would not approve scaling beyond that pilot without the conditions outlined in this memo being met.**

---

## I. Strategic Risk Assessment

### 1. Precedent Risk

**Severity: HIGH**

This is the risk I lose sleep over.

If this succeeds, we are the institution that cracked the ETL modernization problem at scale using AI. If it fails -- if a regulatory filing is wrong because an AI agent misunderstood a business rule, or if a consent order cites AI-generated code that nobody reviewed properly -- the headline writes itself: *"GSIB Lets AI Rewrite Critical Data Pipelines Without Adequate Human Oversight."*

The precedent risk is asymmetric. Success gets shared across technology and the CDO organization. Failure lands on this office. The OCC will not care that the CDO presentation went well. They will care whether we had adequate risk management controls around a novel technology operating on production data infrastructure.

What makes this particularly dangerous is that the failure mode is not an explosion -- it is a slow leak. An AI agent that infers 98% of business rules correctly and misses 2% will produce output that passes automated comparison. The comparison passes because the comparison only validates that the new output matches the old output. If the old output was wrong and nobody knew, the new output is also wrong and the comparison says "PASS." If the new output is wrong in a way the comparison methodology cannot detect -- type coercion that silently rounds, timezone handling that shifts timestamps by hours, null semantics that differ between engines -- the evidence package says "100% match" and we promote defective code with a governance stamp on it.

**The defense story must be:** We identified the risk. We implemented enhanced governance controls above the project team's baseline proposal. We briefed the OCC proactively. We maintained independent validation at every stage. We did not rely solely on AI-generated evidence packages. We had humans in the loop where it mattered, and we can prove it.

### 2. Governance Architecture

**Severity: HIGH -- with a clear path to MEDIUM**

Dan's "information isolation" model for Proofmark -- the independent validation tool -- is the most intellectually honest governance design I have seen from a technology team proposing an AI initiative. The core insight is real: the builder agents never see the validator's internals, so they cannot game the validation. This is genuine segregation of duties through information asymmetry, not security through obscurity. The analogy to proof houses stamping firearms is apt.

However, I have three concerns with the governance architecture as currently constructed:

**First, Proofmark is a weekend project.** It was designed over a single day and has not been built yet. The design session document is thoughtful -- the three-tier threshold model (excluded, exact-match, and tolerance columns) is the right framework, and the insight that CSV and Parquet are loading problems, not comparison problems, is architecturally sound. But there is a distance between a good design document and a battle-tested governance tool. Before Proofmark bears weight as governance infrastructure, it needs to pass its own validation: independent code review, adversarial testing (deliberately introduce known differences and verify detection), and coverage testing against all output target types. The design document itself acknowledges this work is pending.

**Second, the governance circularity identified by the prior adversarial review (Concern C-25) remains the single most important structural risk.** The evidence package -- BRDs, comparison results, governance reports -- is produced by the same agent system whose output is being validated. If the comparison methodology has a systematic blind spot, the evidence package will report success and the governance committee has no independent signal. Proofmark addresses part of this (independent comparison tooling), but the BRDs, FSDs, and attestation narratives are still agent-produced and agent-reviewed. The human spot-check protocol recommended by the evaluator report is necessary but must be formalized with statistical rigor, not left as informal guidance.

**Third, what happens when information isolation breaks?** The model depends on builder agents never learning about Proofmark's internals. In an organization of our size, information containment is aspirational. A developer mentions it in a Slack channel. A configuration file references it by name. A future Claude instance is given context that includes Proofmark documentation. The design needs to be robust to information leakage, not just dependent on isolation. The question is: even if a builder agent knew Proofmark's architecture, could it game the comparison? If the answer is "yes, it could optimize to pass Proofmark while encoding wrong business rules," then information isolation is load-bearing and we need stronger containment. If the answer is "no, because Proofmark does exact comparison on business columns and you cannot fake exact equivalence," then the isolation is a defense-in-depth layer, not the primary control. The project team should answer this question explicitly.

### 3. Concentration Risk -- Vendor Dependency

**Severity: HIGH**

This proposal creates deep, structural dependency on a single AI vendor (Anthropic) and a single model family (Claude). The entire capability -- requirements inference, code generation, review, governance artifact production -- runs on Claude. The architecture document assigns different Claude model tiers to different agent roles (Opus for reasoning, Sonnet for execution), but they are all Claude.

**Business continuity scenarios I need answers for:**

- **Anthropic service degradation:** If Claude's API has a 4-hour outage during a production run, what happens? Partial state? Corrupted outputs? The POC ran for 4+ hours uninterrupted. Production runs will be longer. What is the recovery model for interrupted runs?
- **Model quality regression:** LLM providers update models. If a Claude update degrades performance on code analysis or business rule inference, we might not know until comparison results start failing. Do we pin model versions? Do we have regression tests for model capability?
- **Anthropic corporate risk:** If Anthropic is acquired, pivots its business model, changes pricing dramatically, or restricts GSIB access, our entire modernization capability goes dark. What is the exit strategy? Is there a model-portable version of the approach?
- **Regulatory action against AI providers:** If regulators impose restrictions on AI providers serving financial institutions (not implausible given the current policy environment), what is our contingency?

None of these are reasons to reject the proposal. All of them are reasons to demand a vendor dependency assessment and a business continuity plan before we scale past a pilot. The pilot is the right time to evaluate portability -- can this approach work with a different model provider if needed?

### 4. The Human Element -- Bus Factor

**Severity: CRITICAL for current state, MEDIUM if addressed**

Dan is one person. He designed the POC, built the mock framework, planted the anti-patterns, wrote the anti-pattern guide, served as the independent validator, designed the governance model, designed Proofmark, and authored the kickoff prompt for the production rollout. The entire initiative exists in his head. The project documents are good -- significantly better than most technology proposals I review -- but documents are not the same as institutional knowledge.

If Dan leaves, gets promoted, or is unavailable for an extended period, can anyone else:
- Run the agent swarms?
- Interpret comparison results that require platform-specific judgment?
- Evolve the CLAUDE.md instructions when new anti-patterns are discovered?
- Maintain and extend Proofmark?
- Brief the OCC on the governance model?

Today, the answer to all of those is "no." The kickoff prompt assigns three developers to learn the approach over 120 days, which is the right instinct. But those developers do not exist yet (or have not been identified in the materials I have reviewed). The 120-day timeline is already aggressive for a full portfolio rewrite; it is even more aggressive if it must simultaneously serve as a knowledge transfer exercise.

**My requirement:** Before Phase 1 begins, identify the three developers by name. Before Phase 1 ends, at least two of them must be able to independently run a single-job experiment end-to-end without Dan's involvement. This is a hard gate. I will not approve scaling beyond Phase 1 until this is demonstrated.

### 5. Regulatory Posture

**Severity: HIGH**

We need to brief the OCC proactively. Waiting for them to discover this through a routine examination is the worst possible outcome. I have seen what happens when regulators learn about novel technology practices from exam findings rather than from institutional disclosure -- the conversation shifts from "tell us about your risk management" to "why didn't you tell us?"

**The story I want to tell the OCC:**

> We are using AI-assisted tooling to accelerate the modernization of our ETL infrastructure. The AI performs analysis and generates code improvements. All output is validated through an independent comparison tool developed through traditional SDLC. Human engineers review and approve every production change. We maintain full audit trails, independent validation at every stage, and a human-in-the-loop governance gate that no automated process can bypass. We are sharing this proactively because we believe it represents a significant operational improvement and we want your feedback on our risk management approach.

**What I need before I have that conversation:**

1. A documented governance framework that I can hand to an examiner -- not a design session transcript, but a formal control document with control objectives, control activities, testing procedures, and evidence requirements.
2. Proofmark in a state where I can demonstrate it -- built, tested, independently reviewed. Not a design document.
3. At least one completed end-to-end pilot on a real production job, with the full evidence package, that an examiner can walk through.
4. A vendor risk assessment for Anthropic, consistent with our existing third-party risk management framework.
5. An information security assessment covering agent access to production data, credential management, and audit logging.
6. A model risk management framework for the AI components, consistent with SR 11-7 (or its successor guidance). The AI models are not making credit decisions, but they are making decisions that affect data integrity. Model risk management applies.

Items 1 and 6 are the long poles. A formal governance framework and an SR 11-7-aligned model risk assessment are not weekend projects. I will need Risk partners engaged, not just Technology.

### 6. Risk Appetite Alignment

**Severity: MEDIUM -- but requires explicit board-level acknowledgment**

Our stated risk appetite for technology risk acknowledges that innovation requires accepting controlled uncertainty. Our stated risk appetite for operational risk emphasizes process maturity, control environment strength, and evidence-based decision-making.

AI agents autonomously rewriting production data pipelines sits squarely in the tension between those two statements. This is novel. No GSIB that I am aware of has done this at scale. That cuts both ways: we have no precedent to follow, but we also have no precedent of failure to defend against.

The risk appetite question is not "is this risky?" -- everything we do is risky. The question is: "Is the residual risk, after controls, within our stated appetite?" My assessment:

- **Phase 1 pilot (50-100 jobs, single business line, enhanced controls):** Yes, within appetite. The blast radius is contained. The financial exposure is bounded. The learning value is high.
- **Phase 2 scaling (full business line portfolios):** Conditional. Requires demonstrated control effectiveness from Phase 1, OCC briefing completed without objection, and model risk framework in place.
- **Full platform deployment (50,000 jobs):** Outside current appetite. Would require a board-level risk acceptance and likely updated risk appetite language. We should not be planning for this today.

### 7. Risk Partner Calibration

I have reviewed the prior adversarial review (48 concerns) and the evaluator's assessment. Here is my calibration on which concerns are real blockers versus process theater:

**Genuine Blockers (must resolve before proceeding):**

| Concern | Why It Blocks |
|---------|---------------|
| C-03: Output target diversity | The POC compared PostgreSQL-to-PostgreSQL. Production has 6 output targets. We cannot validate what we cannot compare. Proofmark's design addresses this, but Proofmark does not exist yet. |
| C-25/C-26: Governance circularity | The evidence package is self-produced. Without independent human validation, we are trusting the system to grade itself. This is unacceptable for a GSIB. |
| C-13/C-31: No cost model | I cannot present an initiative to the board without a cost estimate. Neither can the CIO. This is table stakes. |
| C-34/C-35: Security controls | Policy-level enforcement ("the CLAUDE.md says don't touch production data") is not a control. Infrastructure-level enforcement is a control. Before agents touch production data, this must be real. |

**Legitimate Concerns That Are Manageable (address during execution):**

| Concern | Why It Is Manageable |
|---------|---------------------|
| C-06: Full restart at scale | The POC's nuclear restart option does not scale, but the architecture document already describes targeted-fix alternatives. This is an engineering problem with known solutions. Address before the 20-job experiment. |
| C-07/C-08: Framework complexity | The production platform is more complex than the mock. True. That is why there is a progressive scaling path. The Strategy Doc will be wrong in places; the progressive approach catches errors early. |
| C-28/C-29: Agent workarounds | Agents invent workarounds around constraints. This is inherent to autonomous systems and was demonstrated in Run 1. The mitigation -- post-run audits and iterative instruction refinement -- is appropriate. Budget for iteration. |
| C-22/C-43: Timeline and learning curve | 120 days is aggressive. But Phase 1 is a pilot, not a commitment. If 120 days is not enough, we scope down. We do not compress quality. |

**Concerns That Are Process Theater (acknowledge and move on):**

| Concern | Why It Is Theater |
|---------|------------------|
| C-30: External module count reporting | A headline number was slightly misleading but the details were transparent. This is a communications issue, not a risk. |
| C-41: Weekday-only data patterns | The comparison loop is pattern-agnostic. Choose a comparison window that exercises all patterns. Solved. |
| C-42: Single database for all schemas | This is a sub-issue of C-03 (output target diversity) and adds no independent risk. |
| C-45: Agent Teams feature maturity | Worked in the POC. If it breaks at scale, fall back to sequential subagents. Not blocking. |
| C-47: Data quality findings as side effects | This is actually a benefit, not a risk. If the process surfaces data quality issues, that is value. |

### 8. The Upside Risk

I am paid to see downside. But I am also paid to see the full picture, and the full picture includes the competitive risk of inaction.

$750MM in potential cost savings is a real number. Even if the actual savings are half that, it dwarfs the investment in this initiative by orders of magnitude. More importantly:

- **If a competitor does this first,** the board will ask why we did not. They will ask what our risk function said. If the answer is "Risk blocked it because a weekend project was used for governance tooling," that is a career conversation I do not want to have.
- **The modernization problem does not go away.** Tens of thousands of poorly documented, poorly understood ETL jobs are a risk in themselves. Every day we do not modernize, we accumulate operational risk from a platform that nobody fully understands. The question is not "do we modernize?" -- it is "how?"
- **The talent leverage is significant.** Three developers, augmented by AI, doing the work that would otherwise require an army of contractors over years. If this works, it is a force multiplier that transforms our technology operating model.
- **The CDO presentation apparently went well.** Momentum exists. The CIO presentation is March 24th. If we insert risk concerns now and they are perceived as obstructionist rather than constructive, we lose credibility for the concerns that actually matter.

My role is not to block this. My role is to make sure that if we do it, we do it with our eyes open and our controls in place.

---

## II. What I Need Before Briefing the OCC

This is not a wish list. These are prerequisites.

| # | Requirement | Owner | Target Date |
|---|-------------|-------|-------------|
| 1 | Formal governance control framework document (not a design session transcript -- a proper control document with objectives, activities, testing, evidence) | Risk + Technology | Before OCC briefing |
| 2 | Proofmark built, tested, and independently reviewed. At minimum: Parquet comparison, CSV comparison, three-tier threshold model operational, adversarial tests passed. | Technology (Dan) | Before OCC briefing |
| 3 | One completed end-to-end pilot on a real production job with full attestation package that an examiner can walk through | Technology | Before OCC briefing |
| 4 | Vendor risk assessment for Anthropic consistent with third-party risk management framework | Vendor Risk | Before OCC briefing |
| 5 | Information security assessment covering agent access to production data, credential management, network isolation, audit logging | InfoSec | Before Phase 1 production data access |
| 6 | Model risk management framework for AI components, aligned to SR 11-7 principles: model development, model validation, model use, ongoing monitoring | Model Risk | Before Phase 2 scaling |
| 7 | Human spot-check protocol: statistical sampling methodology, sample sizes, independence requirements, escalation criteria | Risk + Technology | Before Phase 1 |
| 8 | Three-scenario cost model (optimistic, expected, pessimistic) covering token costs, Azure compute, developer time, iteration budget | Finance + Technology | Before CIO presentation |
| 9 | Bus factor mitigation plan: named developers, knowledge transfer milestones, capability demonstration gates | Technology | Before Phase 1 end |
| 10 | Business continuity plan for Anthropic dependency: model version pinning, provider portability assessment, service disruption playbook | Technology + BCM | Before Phase 2 scaling |

---

## III. Conditional Recommendation

**Phase 1 Pilot: APPROVE with conditions.**

Conditions:
- Scope limited to 50-100 jobs from a single, non-critical business line (not a line that feeds regulatory reporting or risk calculations)
- Enhanced governance controls in place before production data access (items 5, 7 from the table above)
- Cost model completed and approved before resource commitment (item 8)
- Named team members identified with knowledge transfer plan (item 9)
- Proofmark at minimum viable capability before comparison results are used for governance decisions (item 2)
- Kill switch: any evidence that an agent has written to production data outside its sandbox, or that a comparison methodology has a systematic blind spot, triggers immediate project suspension and root cause analysis
- Monthly risk reporting to this office through Phase 1

**Phase 2 Scaling: HOLD for now.**

Decision deferred until Phase 1 demonstrates:
- Control effectiveness (spot-check protocol catches planted defects, comparison methodology is validated)
- OCC briefing completed without material objection
- Model risk framework operational
- At least two team members can run the process independently
- Vendor risk assessment complete

**Full Platform Deployment: NOT APPROVED.**

This is a board-level decision that requires updated risk appetite language. Not on the table today and should not be part of the CIO presentation narrative. The CIO presentation should frame this as a pilot with a scaling path, not as a platform-wide commitment.

---

## IV. The Nightmare Scenario

I want everyone in this room to hear this clearly.

**The nightmare is not a dramatic failure. The nightmare is a quiet one.**

Here is the scenario: Phase 1 succeeds. The evidence packages look clean. The comparison results say 100% match. The governance committee approves. We promote V2 code to production. Six months later, a regulatory filing contains incorrect data. The source is traced to an ETL job that was rewritten by Project ATC. The investigation reveals that the AI agent correctly inferred 16 of 17 business rules for that job. The 17th rule -- involving a complex interaction between a slowly-changing dimension lookup and a quarterly reconciliation adjustment -- was inferred at MEDIUM confidence. The reviewer agent accepted it. The comparison passed because the comparison window (3 months of daily runs) did not include the quarter-end edge case where the rule mattered. The human spot-check sample did not include this job. The evidence package shows "100% match" and the governance stamp is on the sign-off page.

The OCC examiner asks three questions:
1. "How did this pass your validation?"
2. "What was your independent verification of the AI's business rule inference?"
3. "Show me your model risk management framework for these AI systems."

If we cannot answer those three questions with documentation, process evidence, and demonstrated control effectiveness, we are in consent order territory. My predecessor lost his job over a failure to anticipate operational risk. I intend to keep mine.

**Containment strategy:**

- **Comparison window selection:** For every job that feeds regulatory reporting, risk calculations, or client-facing products, the comparison window must cover all calendar edge cases: month-end, quarter-end, year-end, holidays. No exceptions.
- **Confidence-based human review:** Any business rule inferred at MEDIUM or LOW confidence in a job that feeds a critical data product triggers mandatory human review by a domain expert. This is non-negotiable for critical path jobs.
- **Parallel run period:** V2 jobs run in parallel with legacy jobs for a minimum of one full business cycle (quarterly for most; annually for year-end-sensitive jobs) before legacy decommission. Both outputs are compared daily. Any divergence triggers investigation.
- **Regulatory job classification:** Before any job enters the AI pipeline, classify it: does it feed regulatory reporting? Risk calculations? Client-facing products? Jobs in those categories get enhanced controls (longer comparison windows, mandatory human BRD review, parallel run period). Jobs that are purely internal analytics get standard controls.
- **Rollback preservation:** Legacy code and infrastructure remain operational and restorable for a minimum of 12 months after V2 promotion for any critical path job. Cost of maintaining the legacy environment during this period is included in the cost model.

---

## V. Closing

This is a good proposal from a technically capable team. The POC results are genuine. The governance thinking -- particularly the information isolation model -- is more sophisticated than what I typically see from technology proposals. Dan appears to be a serious practitioner who is thinking about these problems from the right direction.

But "good proposal" and "ready for a GSIB" are different standards. We operate under regulatory expectations that do not care about the elegance of the architecture. They care about controls, evidence, and accountability. My job is to make sure that when we tell the OCC "we have this under control," we actually do.

I support this initiative going forward. I support the CIO presentation. I want my conditions met before we scale. And I want a seat at the table for the governance framework design -- not as an observer, but as a co-author. This office is not going to review a completed framework and stamp it. We are going to help build it right from the start.

If the project team is willing to accept enhanced governance controls as the price of my support, they have it. If they view Risk as an obstacle to be managed rather than a partner to be engaged, they will not have it, and the CIO will hear why.

---

*This memo represents the CRO's personal assessment and does not constitute formal Risk Committee approval. Formal approval requires Risk Committee review and vote, which will be scheduled upon receipt of the items identified in Section II.*
