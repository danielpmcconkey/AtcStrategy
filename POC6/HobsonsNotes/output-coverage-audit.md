# POC6 Output Coverage Audit

**Date:** 2026-03-10
**Auditor:** Hobson
**Scope:** 105 jobs x 31 dates (Oct 1-31, 2024) = 3,255 expected outputs
**Output directory:** `/media/dan/fdrive/codeprojects/MockEtlFrameworkPython/Output/curated/`
**Manifest:** `/media/dan/fdrive/codeprojects/AtcStrategy/POC5/hobson-notes/job-scope-manifest.json`

---

## Summary

| Metric | Value |
|--------|-------|
| Jobs with complete output (31/31) | **102** |
| Jobs with partial output | **3** |
| Jobs with no output | **0** |
| Total outputs present | **3,228 / 3,255** |
| Coverage | **99.2%** |
| Empty output files | **0** |

All 105 jobs have output directories. No output files are zero bytes.

---

## Directory Structure

```
curated/<job_snake>/<dataset_snake>/<YYYY-MM-DD>/<dataset_snake>.csv
```

Most jobs produce a single dataset whose name matches the job directory. One job
(`DansTransactionSpecial`) produces two datasets: `dans_transaction_details` and
`dans_transactions_by_state_province`. Both have all 31 dates.

---

## Directory Naming Notes

Two jobs use directory names that don't match a naive PascalCase-to-snake_case
conversion of the manifest job name. Both have **complete output** (31/31):

| Job Name (manifest) | Expected Directory | Actual Directory |
|---|---|---|
| `BranchVisitsByCustomerCsvAppendTrailer` | `branch_visits_by_customer_csv_append_trailer` | `branch_visits_by_customer` |
| `Customer360Snapshot` | `customer360_snapshot` | `customer_360_snapshot` |

This is cosmetic, not a coverage gap, but any tooling that maps manifest names
to directories will need to handle these two cases.

---

## Complete Jobs (102 of 105)

All 102 jobs below have output for every date from 2024-10-01 through 2024-10-31.

| # | Job ID | Job Name |
|---|--------|----------|
| 1 | 12 | AccountBalanceSnapshot |
| 2 | 16 | AccountCustomerJoin |
| 3 | 135 | AccountOverdraftHistory |
| 4 | 13 | AccountStatusSummary |
| 5 | 14 | AccountTypeDistribution |
| 6 | 161 | AccountVelocityTracking |
| 7 | 115 | BondMaturitySchedule |
| 8 | 153 | BranchCardActivity |
| 9 | 22 | BranchDirectory |
| 10 | 162 | BranchTransactionVolume |
| 11 | 23 | BranchVisitLog |
| 12 | 25 | BranchVisitPurposeBreakdown |
| 13 | 371 | BranchVisitsByCustomerCsvAppendTrailer |
| 14 | 24 | BranchVisitSummary |
| 15 | 100 | CardAuthorizationSummary |
| 16 | 101 | CardCustomerSpending |
| 17 | 106 | CardExpirationWatch |
| 18 | 99 | CardFraudFlags |
| 19 | 98 | CardSpendingByMerchant |
| 20 | 103 | CardStatusSnapshot |
| 21 | 97 | CardTransactionDaily |
| 22 | 104 | CardTypeDistribution |
| 23 | 143 | CommunicationChannelMap |
| 24 | 117 | ComplianceEventSummary |
| 25 | 121 | ComplianceOpenItems |
| 26 | 124 | ComplianceResolutionTime |
| 27 | 155 | ComplianceTransactionRatio |
| 28 | 33 | CoveredTransactions |
| 29 | 18 | CreditScoreAverage |
| 30 | 369 | CreditScoreDelta |
| 31 | 17 | CreditScoreSnapshot |
| 32 | 150 | CrossSellCandidates |
| 33 | 147 | Customer360Snapshot |
| 34 | 1 | CustomerAccountSummary |
| 35 | 32 | CustomerAddressDeltas |
| 36 | 10 | CustomerAddressHistory |
| 37 | 151 | CustomerAttritionSignals |
| 38 | 29 | CustomerBranchActivity |
| 39 | 122 | CustomerComplianceRisk |
| 40 | 8 | CustomerContactInfo |
| 41 | 145 | CustomerContactability |
| 42 | 21 | CustomerCreditSummary |
| 43 | 7 | CustomerDemographics |
| 44 | 11 | CustomerFullProfile |
| 45 | 114 | CustomerInvestmentSummary |
| 46 | 9 | CustomerSegmentMap |
| 47 | 28 | CustomerTransactionActivity |
| 48 | 30 | CustomerValueScore |
| 49 | 166 | DailyBalanceMovement |
| 50 | 2 | DailyTransactionSummary |
| 51 | 5 | DailyTransactionVolume |
| 52 | 125 | DailyWireVolume |
| 53 | 373 | DansTransactionSpecial |
| 54 | 158 | DebitCreditRatio |
| 55 | 141 | DoNotContactList |
| 56 | 160 | DormantAccountDetection |
| 57 | 138 | EmailOptInRate |
| 58 | 31 | ExecutiveDashboard |
| 59 | 132 | FeeRevenueDaily |
| 60 | 129 | FeeWaiverAnalysis |
| 61 | 15 | HighBalanceAccounts |
| 62 | 102 | HighRiskMerchantActivity |
| 63 | 164 | InterAccountTransfers |
| 64 | 112 | InvestmentAccountOverview |
| 65 | 109 | InvestmentRiskProfile |
| 66 | 4 | LargeTransactionLog |
| 67 | 119 | LargeWireReport |
| 68 | 19 | LoanPortfolioSnapshot |
| 69 | 20 | LoanRiskAssessment |
| 70 | 140 | MarketingEligibleCustomers |
| 71 | 105 | MerchantCategoryDirectory |
| 72 | 152 | MonthlyRevenueBreakdown |
| 73 | 6 | MonthlyTransactionTrend |
| 74 | 128 | OverdraftByAccountType |
| 75 | 133 | OverdraftCustomerProfile |
| 76 | 127 | OverdraftDailySummary |
| 77 | 136 | OverdraftFeeSummary |
| 78 | 134 | OverdraftRecoveryRate |
| 79 | 149 | PaymentChannelMix |
| 80 | 165 | PeakTransactionTimes |
| 81 | 113 | PortfolioConcentration |
| 82 | 107 | PortfolioValueSummary |
| 83 | 144 | PreferenceBySegment |
| 84 | 142 | PreferenceChangeCount |
| 85 | 137 | PreferenceSummary |
| 86 | 146 | PreferenceTrend |
| 87 | 154 | ProductPenetration |
| 88 | 156 | QuarterlyExecutiveKpis |
| 89 | 126 | RegulatoryExposureSummary |
| 90 | 130 | RepeatOverdraftCustomers |
| 91 | 110 | SecuritiesDirectory |
| 92 | 139 | SmsOptInRate |
| 93 | 123 | SuspiciousWireFlags |
| 94 | 26 | TopBranches |
| 95 | 111 | TopHoldingsByValue |
| 96 | 163 | TransactionAnomalyFlags |
| 97 | 3 | TransactionCategorySummary |
| 98 | 159 | TransactionSizeBuckets |
| 99 | 148 | WealthTierAnalysis |
| 100 | 157 | WeekendTransactionPattern |
| 101 | 120 | WireDirectionSummary |
| 102 | 118 | WireTransferDaily |

---

## Partial Jobs (3 of 105)

### HoldingsBySector (Job 108) — 23/31 dates

Missing 8 dates — **all weekends**:

| Missing Date | Day |
|---|---|
| 2024-10-05 | Saturday |
| 2024-10-06 | Sunday |
| 2024-10-12 | Saturday |
| 2024-10-13 | Sunday |
| 2024-10-19 | Saturday |
| 2024-10-20 | Sunday |
| 2024-10-26 | Saturday |
| 2024-10-27 | Sunday |

Likely intentional: investment holdings data doesn't change on non-trading days.
Worth confirming whether the OG C# framework also skips weekends for this job.

### FundAllocationBreakdown (Job 116) — 23/31 dates

Missing 8 dates — **identical weekend pattern** as HoldingsBySector.

| Missing Date | Day |
|---|---|
| 2024-10-05 | Saturday |
| 2024-10-06 | Sunday |
| 2024-10-12 | Saturday |
| 2024-10-13 | Sunday |
| 2024-10-19 | Saturday |
| 2024-10-20 | Sunday |
| 2024-10-26 | Saturday |
| 2024-10-27 | Sunday |

Same analysis applies: likely market-calendar-aware jobs.

### OverdraftAmountDistribution (Job 131) — 20/31 dates

Missing 11 dates — **no day-of-week pattern**:

| Missing Date | Day |
|---|---|
| 2024-10-04 | Friday |
| 2024-10-06 | Sunday |
| 2024-10-08 | Tuesday |
| 2024-10-11 | Friday |
| 2024-10-17 | Thursday |
| 2024-10-18 | Friday |
| 2024-10-20 | Sunday |
| 2024-10-21 | Monday |
| 2024-10-23 | Wednesday |
| 2024-10-28 | Monday |
| 2024-10-31 | Thursday |

This one looks like genuine failures or data gaps. The missing dates are
scattered across all days of the week with no obvious pattern. Recommend
investigating logs for this job.

---

## Jobs With No Output

None. All 105 manifest jobs have corresponding output directories.

---

## File Integrity

- **Total output files on disk:** 3,259
- **Expected (105 jobs x 31 dates):** 3,255
- **Delta:** +4 (explained by `DansTransactionSpecial` producing 2 datasets x 31 dates = 62 files, where 31 was expected)
- **Zero-byte files:** 0

---

## Verdict

Coverage is strong at 99.2%. The 27 missing outputs break down as:

- **16 likely intentional** (weekend skips on 2 investment jobs) — verify against OG output
- **11 suspect** (scattered gaps on OverdraftAmountDistribution) — investigate

If the weekend skips are confirmed intentional, effective coverage on the
remaining scope is 3,228 / 3,239 = **99.7%**, with OverdraftAmountDistribution
as the sole problem child.
