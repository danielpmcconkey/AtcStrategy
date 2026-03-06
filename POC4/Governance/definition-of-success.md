# Definition of Success — Project ATC, POC4

**Status:** DRAFT — Pending Dan approval
**Created:** 2026-03-06
**Doctrine references:** §1.1 (fidelity), §1.2 (code quality), §1.3 (human interaction), §3.3 (scope governance)
**Depends on:** Step 6 output (config triage — all 105 jobs viable, zero breaks)

---

## 1. High-Level Definition of Success

Success for this POC can only be declared when **all** of the following conditions have been met:

1.1. 100% of jobs in the job scope manifest have been successfully reengineered (see Section 2 for per-job success criteria).

1.2. A human-readable summary of evidence of job completion and program governance adherence has been created and signed off on by Dan.

1.3. An executive summary of what this POC accomplished above and beyond POC2 — and why that should increase confidence in the approach — has been created and signed off on by Dan.

---

## 2. Definition of Success for a Specific Job Reengineering

Any given job can only be declared as successfully reengineered when **all** of the following conditions have been met:

2.1. All job outputs have been identified, with evidence citing V1 source code.

2.2. A business requirements document (BRD) has been inferred from V1 code and created, with evidence citing all requirements from either source code or data.

2.3. A functional specification document (FSD) has been created, with evidence citations to the BRD or source code.

2.4. A test strategy document has been created, citing evidence in the FSD or BRD for all test requirements.

2.5. Tests defined in the test strategy have been implemented, executed, and all pass.

2.6. A V4 job configuration has been created, along with any external modules necessary to satisfy output fidelity. External modules are a last resort — each must include evidence that the required behavior cannot be accomplished through standard ETL Framework modules. External module code must be scoped to the specific evidenced use case and nothing more. Any logic within an external module must include comments citing the FSD or test cases that justify its existence.

2.7. Evidence that all anti-patterns defined in the program governance anti-pattern guide (`Governance/anti-patterns.md`) have either been eliminated from the V4 code or are explicitly required to achieve output fidelity, with per-instance justification.

2.8. Evidence that the complete document chain (BRD → FSD → test cases → V4 code → Proofmark configuration) is internally consistent. Any modification to code or Proofmark configuration made during execution must be traced backward through the chain, with updates to upstream documents as necessary. No artifact in the chain may contradict another without documented justification.

2.9. Evidence that all output files have been compared to their V1 counterparts using Proofmark, for all ETL effective dates that the V1 job produces output, and received PASS.

2.10. Evidence that any EXCLUDED column in the Proofmark configuration is required due to non-deterministic output in the V1 job. As the POC progresses, Dan retains the right to determine what types of anomalies or patterns qualify as non-deterministic. Such decisions must be noted in amendments to program governance documentation.

2.11. Evidence that any FUZZY column in the Proofmark configuration is required due to floating point uncertainty in either V1 or V4 code. As the POC progresses, Dan retains the right to determine what types of anomalies or patterns may acceptably be designated FUZZY. Such decisions must be noted in amendments to program governance documentation.

---

## 3. What This Document Does Not Define

- **The job scope manifest.** The list of in-scope jobs is a separate governance artifact (Step 10), sealed at POC start and reconciled at every phase boundary per doctrine §3.3.
- **The evidence ledger.** The runtime tracking of per-job, per-output status and proof artifacts lives in the database. It is populated during execution and generated on demand for governance reviews.
- **Runtime performance criteria.** If anti-patterns have been eliminated per criterion 2.7, the resulting runtime characteristics are accepted. Anti-patterns may represent patterns that are appropriate at enterprise scale; their elimination is a code quality measure, not a performance target.
