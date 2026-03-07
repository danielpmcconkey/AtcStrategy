# E.2 Progress

| Job | Architect | FSD | Test Strategy | FSD Review | Test Review | Status |
|-----|-----------|-----|---------------|------------|-------------|--------|
| PeakTransactionTimes | done | done | done | pass | pass | COMPLETE |
| DailyBalanceMovement | done | done | done | pass | pass | COMPLETE |
| CreditScoreDelta | done | done | done | pass | pass | COMPLETE |
| BranchVisitsByCustomerCsvAppendTrailer | done | done | done | pass | pass | COMPLETE |
| DansTransactionSpecial | done | done | done | pass | pass | COMPLETE |

---

## Final Summary

**Phase:** E.2 — Functional Specs and Test Strategy
**Status:** COMPLETE
**Date:** 2026-03-07

### Stats
- **Jobs processed:** 5/5
- **FSDs written:** 5
- **Test strategies written:** 5
- **FSD reviews:** 5 (all PASS)
- **Test strategy reviews:** 5 (all PASS)
- **Rejections/revisions:** 0
- **Review cycles used:** 1 of 3 max

### Key Findings

**PeakTransactionTimes (Job 165):**
- External module justified in V4 (trailer uses INPUT row count, framework {row_count} produces OUTPUT count)
- Aggregation logic moved from C# foreach to SQL GROUP BY (eliminates AP6)
- 5 anti-patterns addressed (AP1, AP3 partial, AP4, AP6, AP7)
- Open: banker's rounding vs standard rounding for midpoint values

**DailyBalanceMovement (Job 166):**
- Full External-to-SQL conversion (eliminates AP3, AP6)
- 5 anti-patterns addressed (AP3, AP4, AP5, AP6, AP7)
- Open: ifw_effective_date format (MM/DD/YYYY from DateOnly), undefined row ordering
- CAST(amount AS REAL) may be needed to preserve double arithmetic

**CreditScoreDelta (Job 369):**
- V1 already uses preferred pattern (SQL Transformation, no External)
- Only config-level changes needed (additionalFilter on customers)
- 3 anti-patterns addressed (AP1, AP7, AP10)
- Must preserve failure behavior for dates with no credit_scores data (Oct 5-6)

**BranchVisitsByCustomerCsvAppendTrailer (Job 371):**
- V1 already uses preferred pattern
- Only config-level changes needed (additionalFilter on customers)
- 2 anti-patterns addressed (AP1, AP7)
- Append mode ordering clarification: SQL ORDER BY applies only to current day's data, not accumulated file

**DansTransactionSpecial (Job 373):**
- V1 already uses preferred pattern (most complex: dual-output, 8-module chain)
- Only config-level changes needed (remove unused columns from customers)
- 3 anti-patterns addressed (AP4, AP7, AP8)
- Non-deterministic address dedup tiebreaker is a known V1 issue; V4 preserves it
- Proofmark EXCLUDED strategy needed for address columns if tiebreaker causes mismatches

### Anti-Pattern Distribution Across Jobs
- AP1 (Dead-End Sourcing): 3 jobs (PeakTransactionTimes, CreditScoreDelta, BranchVisitsByCustomerCsvAppendTrailer)
- AP3 (Unnecessary External): 2 jobs (PeakTransactionTimes, DailyBalanceMovement)
- AP4 (Unused Columns): 3 jobs (PeakTransactionTimes, DailyBalanceMovement, DansTransactionSpecial)
- AP5 (Asymmetric Null/Default): 1 job (DailyBalanceMovement)
- AP6 (Row-by-Row Iteration): 2 jobs (PeakTransactionTimes, DailyBalanceMovement)
- AP7 (Magic Values): 5 jobs (all)
- AP8 (Complex/Dead SQL): 1 job (DansTransactionSpecial)
- AP10 (Over-Sourcing Date Ranges): 1 job (CreditScoreDelta)

### New Anti-Patterns Discovered During Test Design
- Undefined row ordering (DailyBalanceMovement) — testing consideration, not new AP code
- Accumulated file ordering ambiguity (BranchVisitsByCustomerCsvAppendTrailer) — framework behavior
- Non-deterministic ROW_NUMBER tiebreaker (DansTransactionSpecial) — AP8-adjacent
