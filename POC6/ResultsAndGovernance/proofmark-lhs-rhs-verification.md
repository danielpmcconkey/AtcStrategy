# Proofmark LHS/RHS Path Verification

**Date:** 2026-03-17
**Scope:** All 40 completed jobs (41 including job 5 manual verification)

## Summary

**LHS (left-hand side): All 40 jobs PASS.** Every LHS path points to `Output/curated/` — the OG (original) output directory. No exceptions.

**RHS (right-hand side): 37 of 40 jobs use the standard `Output/re-curated/` path.** Three jobs use variant RHS paths that still represent RE output, just from different directories.

## Non-Standard RHS Jobs

| Job ID | Job Name | RHS Path Used | Assessment |
|--------|----------|---------------|------------|
| 21 | CustomerCreditSummary | `/workspace/MockEtlFrameworkPython/Output/re-curated-fixed/...` | RE output via a fixed/corrected directory. Still RE, just a patched version. |
| 23 | BranchVisitLog | `{ETL_ROOT}/Output/proofmark-proxy/re/...` | RE output routed through a proofmark proxy directory. The `re/` subfolder indicates it's the RE side. |
| 118 | WireTransferDaily | `{ETL_ROOT}/RE/Jobs/WireTransferDaily_re/output/...` | RE output pulled directly from the RE job's output directory rather than the centralized `re-curated` folder. |

## Interpretation

All 3 non-standard RHS paths point at reverse-engineered output — they're sourced from alternative locations (`re-curated-fixed`, `proofmark-proxy/re`, or `RE/Jobs/*/output`). None accidentally point at OG data. The LHS/RHS polarity (OG vs RE) is correct across all 40 jobs.

The variant paths reflect iterative fixes during development (the `re-curated-fixed` directory, multiple `patfix` runs for BranchVisitLog, etc.).

## The 37 Clean Jobs

All use the standard pattern:
- **LHS:** `{ETL_ROOT}/Output/curated/<job>/.../` (OG)
- **RHS:** `{ETL_ROOT}/Output/re-curated/<job>/.../` (RE)

Jobs: AccountBalanceSnapshot, AccountCustomerJoin, AccountStatusSummary, AccountTypeDistribution, AccountVelocityTracking, BranchDirectory, BranchTransactionVolume, BranchVisitPurposeBreakdown, BranchVisitsByCustomerCsvAppendTrailer, BranchVisitSummary, CardTransactionDaily, CreditScoreAverage, CreditScoreDelta, CreditScoreSnapshot, CustomerAccountSummary, CustomerAddressHistory, CustomerContactInfo, CustomerDemographics, CustomerFullProfile, CustomerSegmentMap, CustomerTransactionActivity, DailyBalanceMovement, DailyTransactionSummary, DansTransactionSpecial, DormantAccountDetection, HighBalanceAccounts, InterAccountTransfers, LargeTransactionLog, LoanPortfolioSnapshot, LoanRiskAssessment, MonthlyTransactionTrend, OverdraftDailySummary, PeakTransactionTimes, TopBranches, TransactionAnomalyFlags, TransactionCategorySummary, TransactionSizeBuckets.

## Conclusion

**PASS.** No OG-vs-OG contamination detected. All Proofmark comparisons used the correct source polarity.
