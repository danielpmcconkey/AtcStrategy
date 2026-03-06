# Doctrine Amendment 002: Job Boundary Preservation

**Proposed:** 2026-03-06 (during Step 6 execution)
**Section:** §1.1 (Data Output Fidelity)
**Status:** APPROVED (retroactive governance — see note)
**Jim review:** Reviewed 2026-03-06 during Phase I-II FMEA audit. Jim flagged the process bypass (change made without formal amendment) but did not object to the content. This amendment formalizes the change retroactively.
**Dan approval:** 2026-03-06

## Observation

During Step 6 (Job Config Triage), the DansTransactionSpecial job demonstrated a multi-output pattern: one job producing both detail and aggregate CSV files. The question arose whether a V2 rewrite could split a complex V1 job into multiple simpler V2 jobs. Dan decided the answer is no — job boundaries are sacred.

## Change Made

Added to doctrine §1.1, after the paragraph on Parquet comparison:

> **Job boundary preservation.** One V1 job produces one V2 job. Agents must not split a single V1 job into multiple V2 jobs, regardless of complexity. If a V1 job produces multiple outputs, the V2 rewrite produces the same multiple outputs from the same single job. The job is the unit of work, and its boundaries are not negotiable.

## Rationale

Job boundaries are a fidelity constraint, not a convenience. If agents can split jobs, the scope manifest (§3.3) breaks — you can no longer reconcile "105 V1 jobs in, 105 V2 jobs out." It also changes the blast radius of failures: a single failed V2 job that was supposed to match a single V1 job is a contained problem. A V1 job split into three V2 jobs with cross-dependencies is a debugging nightmare.

## Blast Radius

- Scope manifest (§3.3) depends on 1:1 job mapping — this rule makes that dependency explicit
- Future blueprints must include this constraint as a hard rule
- No existing artifacts invalidated — this codifies an assumption that was already implicit

## Process Note

This change was made directly to the doctrine during Step 6 without a formal amendment or Jim review, violating §3.7. Jim's FMEA audit (2026-03-06) identified the process bypass. This amendment retroactively applies the governance process. The content was never in dispute — only the process was missing.
