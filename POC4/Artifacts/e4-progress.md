# E.4 Progress

| Job | Builder | Config | Tests | Build | Smoke | Review | Status |
|-----|---------|--------|-------|-------|-------|--------|--------|
| PeakTransactionTimes | done | done | done | pass | pass | pass | COMPLETE |
| DailyBalanceMovement | done | done | done | pass | pass | pass | COMPLETE |
| CreditScoreDelta | done | done | done | pass | pass (Oct5-6 fail expected) | pass | COMPLETE |
| BranchVisitsByCustomerCsvAppendTrailer | done | done | done | pass | pass | pass | COMPLETE |
| DansTransactionSpecial | done | done | done | pass | pass | pass | COMPLETE |

## Summary
- **All 5 jobs built, tested, smoke-tested, and reviewed.**
- **140 tests passing** (including 29 new V4 job tests)
- **Clean build** (0 errors)
- **Smoke test artifacts cleaned up**
- **All 3 independent reviews approved for all 5 jobs**

## Build Discoveries (logged, not blueprint amendments)
1. **DailyBalanceMovement accounts sourcing:** Changed from single-day to `mostRecent: true`. V1 External module handled empty accounts on weekends gracefully; V4 SQL Transformation needs the table registered in SQLite. `mostRecent` ensures accounts data is always available. No fidelity impact — same data, same results.
2. **PeakTransactionTimes decimal formatting:** SQLite ROUND returns integers for whole numbers. V4 External module uses explicit `F2` formatting to match V1's `Math.Round(decimal, 2)` output which preserves trailing zeros (e.g., `453380.00`).

## Artifacts Produced
- `/workspace/MockEtlFramework/JobExecutor/Jobs/peak_transaction_times_v4.json`
- `/workspace/MockEtlFramework/JobExecutor/Jobs/daily_balance_movement_v4.json`
- `/workspace/MockEtlFramework/JobExecutor/Jobs/credit_score_delta_v4.json`
- `/workspace/MockEtlFramework/JobExecutor/Jobs/branch_visits_by_customer_csv_append_trailer_v4.json`
- `/workspace/MockEtlFramework/JobExecutor/Jobs/dans_transaction_special_v4.json`
- `/workspace/MockEtlFramework/ExternalModules/PeakTransactionTimesWriterV4.cs`
- `/workspace/MockEtlFramework/Lib.Tests/V4JobTests.cs`
- `/workspace/AtcStrategy/POC4/Artifacts/PeakTransactionTimes/build-review.md`
- `/workspace/AtcStrategy/POC4/Artifacts/DailyBalanceMovement/build-review.md`
- `/workspace/AtcStrategy/POC4/Artifacts/CreditScoreDelta/build-review.md`
- `/workspace/AtcStrategy/POC4/Artifacts/BranchVisitsByCustomerCsvAppendTrailer/build-review.md`
- `/workspace/AtcStrategy/POC4/Artifacts/DansTransactionSpecial/build-review.md`
