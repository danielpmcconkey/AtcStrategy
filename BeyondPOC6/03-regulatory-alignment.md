# Regulatory Alignment

How deterministic orchestration with independent verification maps to existing banking regulation. This is not a compliance filing — it is a reference for conversations with risk, compliance, and regulators about why this architecture was chosen.

---

## 1. SR 11-7 / OCC 2011-12 — Model Risk Management

The foundational US guidance on model risk management. Issued jointly by the Federal Reserve and OCC in April 2011. Defines a "model" as any quantitative method that processes inputs to produce quantitative estimates used for decision-making [OCC-SR11-7].

**Key question:** Is AI-generated code a "model" under SR 11-7?

If the output is used for decision-making, forecasting, data transformation, or risk measurement — yes. The method of code generation (human vs. AI) does not change the classification. SR 11-7's requirements apply to the output regardless of how it was produced.

**SR 11-7 requires three things:**

1. **Robust model development with documentation.** The process that generated the code must be documented — what instructions were given, what model was used, what constraints were applied. A deterministic state machine with structured agent blueprints provides this documentation inherently. Every step is defined, every input and output is captured, every transition is logged. Compare this to an autonomous agent operating in a single long-running session where the decision process is opaque.

2. **Independent validation ("effective challenge").** Someone with sufficient expertise must independently verify the output. SR 11-7 is explicit that rubber-stamping is insufficient — the validation must constitute an "effective challenge." An independent verification tool that compares AI-generated output against known-good output without knowledge of the generation process constitutes outcome-based validation. This is stronger than process-based validation (a human reviewing the code) because it directly verifies correctness of results rather than plausibility of approach.

3. **Ongoing monitoring and outcomes analysis.** The system must be monitored in production, with regular comparison of predicted vs. actual outcomes. A deterministic pipeline with structured output artifacts supports this — every run produces comparable, auditable results.

---

## 2. The Maker-Checker Principle

The four-eyes principle (maker-checker) is embedded throughout banking regulation. Under MiFID II, Basel operational risk frameworks, and US banking examination procedures, material decisions require independent review.

**Applied to AI agent pipelines:**

- The **maker** is the agent that generates the output (code, data transformations, business rules).
- The **checker** is a structurally independent process that verifies the output — operating with separate context, separate access, and no ability to influence the maker's work.

In a deterministic orchestration architecture:
- The agent that writes code cannot see the expected output (preventing evaluation gaming).
- The agent that reviews code starts fresh — no shared context with the writer (preventing confirmation bias from accumulated context).
- The verification tool that compares outputs operates independently of both (preventing collusion).

This maps directly to the maker-checker principle. An autonomous agent that generates and self-evaluates in the same context window is, in regulatory terms, a maker checking its own work. That is precisely what maker-checker is designed to prevent.

---

## 3. PRA SS1/23 — Model Risk Management (UK)

The Bank of England's Prudential Regulation Authority issued SS1/23 in May 2023, one of the most comprehensive supervisory statements on model risk [PRA-SS1-23]. It explicitly extends to AI/ML models. Key principles relevant to agent orchestration:

- **Principle 1 (Model identification and classification):** AI agent pipelines that produce data transformations or business logic fall within scope.
- **Principle 2 (Governance):** Model risk governance must include clear accountability for AI-generated outputs.
- **Principle 4 (Model development):** Development practices must ensure models are "fit for purpose" — which requires documented development processes and independent testing.
- **Principle 5 (Independent validation):** Models must be independently validated by personnel or processes not involved in development. A deterministic pipeline with independent verification at every gate implements this structurally.

---

## 4. NIST AI Risk Management Framework

NIST AI RMF 1.0 (AI 100-1, January 2023) is not banking-specific but is referenced by banking regulators as a complementary framework [NIST-AIRMF]. Its GOVERN, MAP, MEASURE, and MANAGE functions map cleanly to deterministic orchestration:

- **GOVERN:** The state machine definition IS the governance policy. It specifies what steps must occur, in what order, with what quality gates. It cannot be argued with or rationalised away by an agent.
- **MAP:** Each agent blueprint defines the scope, inputs, outputs, and constraints of a bounded task. Risk is mapped at the step level, not the pipeline level.
- **MEASURE:** Structured process artifacts at every step provide measurable outputs. Independent verification provides quantitative pass/fail metrics.
- **MANAGE:** Counter escalation, dead-lettering, and triage workflows provide explicit risk management responses when quality gates fail.

---

## 5. How This Architecture Answers Regulatory Questions

| Regulatory question | How deterministic orchestration answers it |
|---|---|
| "How do you know the AI-generated output is correct?" | Independent verification compares generated output against known-good baseline. Outcome-based, not process-based. |
| "Who is accountable for AI decisions?" | The state machine enforces the process. Human accountability is at the pipeline design level — the humans who defined the states, transitions, and quality gates. No autonomous AI makes routing decisions. |
| "Can you audit what the AI did?" | Every step produces structured process artifacts (JSON) and product artifacts (documents, code, configs). The complete decision trail is preserved. |
| "What happens when the AI gets it wrong?" | Deterministic quality gates catch errors. Review nodes can approve, conditionally approve, or reject. Counter escalation prevents infinite retry loops. Dead-lettering removes intractable jobs for human review. |
| "How do you prevent the AI from taking shortcuts?" | Scoped agent access — each agent sees only its required inputs. Independent verification cannot be observed or influenced by the generating agent. This is structurally enforced, not prompt-enforced. |
| "Does this comply with SR 11-7?" | The architecture implements effective challenge (independent verification), documentation (structured artifacts at every step), and ongoing monitoring (deterministic comparison of outputs). |

---

## 6. The Regulatory Advantage of Determinism

An autonomous agent operating in a single long-running session produces an opaque decision process. The agent's "reasoning" is embedded in a context window that degrades over time, cannot be reliably audited after the fact, and may not reflect what actually influenced the output (due to lost-in-the-middle effects).

A deterministic state machine produces a fully auditable execution trace. Every state transition is logged. Every quality gate decision is captured with its rationale. Every agent operates in a fresh context with defined inputs and outputs. The pipeline is reproducible — run it again on the same inputs, and the same state machine executes the same steps in the same order (though individual agent outputs may vary, the verification gates catch discrepancies).

In a regulatory environment, auditability is not a nice-to-have. It is a requirement. Deterministic orchestration provides it structurally. Autonomous agents do not.

---

*See [bibliography.md](bibliography.md) for full citations.*
