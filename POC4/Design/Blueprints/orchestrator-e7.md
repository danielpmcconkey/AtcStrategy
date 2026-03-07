# Orchestrator Blueprint — E.7: Close-Out

**Scope:** Produce the final evidence package and summary documents. Stop when all deliverables are written.

---

## Inputs

- All artifacts from E.1-E.6: BRDs, FSDs, test strategies, V4 code, Proofmark results, errata, reviews
- Definition of success: `Governance/definition-of-success.md`
- Pat's audit report (if available)
- List of any flagged failures from E.6

## Your Team

- **Summary writer** — spawn as subagent

## Execution

### If E.1-E.6 Succeeded

1. Spawn summary writer to create the final evidence package:
   - Per-job evidence rollup: for each job, compile BRD → FSD → test strategy → V4 code → Proofmark results into a single evidence chain
   - Verify each job meets all criteria in `Governance/definition-of-success.md` §2
2. Write evidence rollup summary (§1.2 of definition of success)
3. Write executive summary (§1.3 of definition of success):
   - What POC4 accomplished above and beyond POC2
   - Why that should increase confidence in the approach
   - Key metrics: jobs completed, effective dates validated, anti-patterns eliminated, fix iterations required

### If E.1-E.6 Did Not Succeed

1. Write lessons learned document:
   - What worked
   - What failed and why
   - Recommendations for future attempts
2. Close out POC4 with eye toward another AAR

## Outputs

- `POC4/Governance/evidence-rollup.md`
- `POC4/Governance/executive-summary.md`
- Or: `POC4/Governance/lessons-learned.md` (failure case)

## Stop Condition

**Stop and report to BD when:** All summary documents are written. Your job is done.
