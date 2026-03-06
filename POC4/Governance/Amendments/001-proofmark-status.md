# Doctrine Amendment 001: Proofmark Status Update

**Proposed:** 2026-03-06
**Section:** §2.5 (Proofmark — Promising, Not Proven)
**Status:** APPROVED
**Jim review:** CONDITIONAL APPROVE — conditions met (header revised, test 013 severity preserved, residual accuracy risk noted)
**Dan approval:** 2026-03-06

## Observation

Doctrine §2.5 was written during the AAR (2026-03-04), before Proofmark's manual validation campaign. The section header "Promising, Not Proven" and the statement "It has never run at scale against real POC output" no longer reflect the tool's demonstrated status.

## Evidence Since Doctrine Was Written

**Manual testing (2026-03-01):** Dan personally ran 23 manual tests (14 CSV, 9 Parquet) using hand-crafted test fixtures covering: order independence, schema validation, floating point strict/fuzzy, trailer handling, whitespace, quoting, multi-part Parquet assembly, type mismatch detection. 21/23 tests passed as expected. Two known gaps documented:
- Critical: CSV quoting differences invisible to data comparison (test 013). Header comparison is partial safety net. Vendor build must address via CSV dialect spec.
- Low-risk: Mixed line breaks in single file not detected (test 005).

**Cross-validation during Step 4 (2026-03-05):** Proofmark cross-validated CSV vs Parquet output parity across 10 dates — 10/10 STRICT comparison passed.

**Automated test suite:** 205 unit tests, 66 BDD scenarios, all passing.

Evidence: `AtcStrategy/POC3/proofmark-manual-test-log.md`, `proofmark/tests/fixtures/dan_manual_test/`, transcript summary `2026-03-05_c972a808.md`

## Proposed Change

**Current header:** "Proofmark — Promising, Not Proven"

**Proposed header:** "Proofmark — Accuracy Validated Within Tested Scope, Untested at Scale"

**Current text (replace final paragraph):**
> Proofmark (the COTS comparison tool) passed 205 automated tests, 23 manual tests, and 66 BDD scenarios. It has never run at scale against real POC output. It is the right tool for data fidelity validation, but it is unproven at production volume. Treat it as essential infrastructure that needs a shakedown run early in POC4 execution, not as a validated tool that can be trusted sight-unseen.

**Proposed text:**
> Proofmark (the COTS comparison tool) passed 205 automated tests, 23 manual tests, and 66 BDD scenarios. Manual testing by Dan covered order independence, schema validation, floating point tolerance, trailer handling, whitespace, quoting, and multi-part Parquet assembly. Cross-validation during Step 4 confirmed CSV/Parquet parity across 10 dates (10/10 STRICT pass). Two known gaps are documented and accepted for POC scope: CSV quoting differences are invisible to the data comparison pipeline (test 013 — HIGH risk for production; POC mitigation is header comparison only; vendor build must address via CSV dialect spec), and mixed line breaks within a single file are not detected (test 005 — LOW risk). Proofmark's accuracy is validated within tested scenarios. What remains untested is operational scale — 101 jobs with varied schemas, edge cases in real ETL output, and configurations not yet written. The scale shakedown serves double duty: validating volume handling and surfacing accuracy gaps under conditions not covered by manual testing. Treat it as validated-in-scope infrastructure, not an unproven prototype — but do not assume tested accuracy extends to untested conditions.

## Rationale

The distinction matters for posture. "Promising, not proven" invites skepticism about whether to use the tool. "Proven accurate, untested at scale" correctly focuses attention on the remaining engineering work (performance, volume handling) rather than questioning whether the tool works at all.

## Blast Radius

- No other doctrine sections reference §2.5 by name
- No blueprints exist yet that depend on this language
- Condensed mission does not mention Proofmark
- Change is factual correction, not philosophical shift
