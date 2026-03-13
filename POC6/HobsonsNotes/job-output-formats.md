# Job Output Formats

Generated: 2026-03-10

105 jobs total. Categorized by the writer module declared in each job's conf JSON.
8 jobs use `External` modules with no explicit writer type in the conf; those were
categorized by inspecting the actual output files in `Output/curated/` (all 8 produce CSV).

## CSV Jobs (65)

| Job ID | Job Name | Writer |
|--------|----------|--------|
| 1 | CustomerAccountSummary | CsvFileWriter |
| 2 | DailyTransactionSummary | CsvFileWriter |
| 3 | TransactionCategorySummary | CsvFileWriter |
| 5 | DailyTransactionVolume | CsvFileWriter |
| 6 | MonthlyTransactionTrend | CsvFileWriter |
| 7 | CustomerDemographics | CsvFileWriter |
| 9 | CustomerSegmentMap | CsvFileWriter |
| 13 | AccountStatusSummary | CsvFileWriter |
| 14 | AccountTypeDistribution | CsvFileWriter |
| 15 | HighBalanceAccounts | CsvFileWriter |
| 17 | CreditScoreSnapshot | CsvFileWriter |
| 18 | CreditScoreAverage | CsvFileWriter |
| 21 | CustomerCreditSummary | CsvFileWriter |
| 22 | BranchDirectory | CsvFileWriter |
| 24 | BranchVisitSummary | CsvFileWriter |
| 25 | BranchVisitPurposeBreakdown | CsvFileWriter |
| 26 | TopBranches | CsvFileWriter |
| 28 | CustomerTransactionActivity | CsvFileWriter |
| 29 | CustomerBranchActivity | CsvFileWriter |
| 30 | CustomerValueScore | CsvFileWriter |
| 31 | ExecutiveDashboard | CsvFileWriter |
| 97 | CardTransactionDaily | CsvFileWriter |
| 99 | CardFraudFlags | CsvFileWriter |
| 100 | CardAuthorizationSummary | CsvFileWriter |
| 102 | HighRiskMerchantActivity | CsvFileWriter |
| 104 | CardTypeDistribution | CsvFileWriter |
| 105 | MerchantCategoryDirectory | CsvFileWriter |
| 108 | HoldingsBySector | External (CSV output) |
| 109 | InvestmentRiskProfile | CsvFileWriter |
| 110 | SecuritiesDirectory | CsvFileWriter |
| 112 | InvestmentAccountOverview | CsvFileWriter |
| 114 | CustomerInvestmentSummary | CsvFileWriter |
| 116 | FundAllocationBreakdown | External (CSV output) |
| 117 | ComplianceEventSummary | CsvFileWriter |
| 119 | LargeWireReport | CsvFileWriter |
| 120 | WireDirectionSummary | External (CSV output) |
| 122 | CustomerComplianceRisk | CsvFileWriter |
| 124 | ComplianceResolutionTime | CsvFileWriter |
| 125 | DailyWireVolume | CsvFileWriter |
| 127 | OverdraftDailySummary | CsvFileWriter |
| 129 | FeeWaiverAnalysis | CsvFileWriter |
| 131 | OverdraftAmountDistribution | External (CSV output) |
| 132 | FeeRevenueDaily | CsvFileWriter |
| 134 | OverdraftRecoveryRate | CsvFileWriter |
| 136 | OverdraftFeeSummary | CsvFileWriter |
| 137 | PreferenceSummary | CsvFileWriter |
| 140 | MarketingEligibleCustomers | CsvFileWriter |
| 141 | DoNotContactList | CsvFileWriter |
| 143 | CommunicationChannelMap | CsvFileWriter |
| 144 | PreferenceBySegment | External (CSV output) |
| 146 | PreferenceTrend | CsvFileWriter |
| 148 | WealthTierAnalysis | CsvFileWriter |
| 150 | CrossSellCandidates | CsvFileWriter |
| 152 | MonthlyRevenueBreakdown | CsvFileWriter |
| 154 | ProductPenetration | CsvFileWriter |
| 155 | ComplianceTransactionRatio | External (CSV output) |
| 157 | WeekendTransactionPattern | CsvFileWriter |
| 159 | TransactionSizeBuckets | CsvFileWriter |
| 161 | AccountVelocityTracking | External (CSV output) |
| 163 | TransactionAnomalyFlags | CsvFileWriter |
| 165 | PeakTransactionTimes | External (CSV output) |
| 166 | DailyBalanceMovement | CsvFileWriter |
| 369 | CreditScoreDelta | CsvFileWriter |
| 371 | BranchVisitsByCustomerCsvAppendTrailer | CsvFileWriter |
| 373 | DansTransactionSpecial | CsvFileWriter (x2 outputs) |

## Parquet Jobs (40)

| Job ID | Job Name | Writer |
|--------|----------|--------|
| 4 | LargeTransactionLog | ParquetFileWriter |
| 8 | CustomerContactInfo | ParquetFileWriter |
| 10 | CustomerAddressHistory | ParquetFileWriter |
| 11 | CustomerFullProfile | ParquetFileWriter |
| 12 | AccountBalanceSnapshot | ParquetFileWriter |
| 16 | AccountCustomerJoin | ParquetFileWriter |
| 19 | LoanPortfolioSnapshot | ParquetFileWriter |
| 20 | LoanRiskAssessment | ParquetFileWriter |
| 23 | BranchVisitLog | ParquetFileWriter |
| 32 | CustomerAddressDeltas | ParquetFileWriter |
| 33 | CoveredTransactions | ParquetFileWriter |
| 98 | CardSpendingByMerchant | ParquetFileWriter |
| 101 | CardCustomerSpending | ParquetFileWriter |
| 103 | CardStatusSnapshot | ParquetFileWriter |
| 106 | CardExpirationWatch | ParquetFileWriter |
| 107 | PortfolioValueSummary | ParquetFileWriter |
| 111 | TopHoldingsByValue | ParquetFileWriter |
| 113 | PortfolioConcentration | ParquetFileWriter |
| 115 | BondMaturitySchedule | ParquetFileWriter |
| 118 | WireTransferDaily | ParquetFileWriter |
| 121 | ComplianceOpenItems | ParquetFileWriter |
| 123 | SuspiciousWireFlags | ParquetFileWriter |
| 126 | RegulatoryExposureSummary | ParquetFileWriter |
| 128 | OverdraftByAccountType | ParquetFileWriter |
| 130 | RepeatOverdraftCustomers | ParquetFileWriter |
| 133 | OverdraftCustomerProfile | ParquetFileWriter |
| 135 | AccountOverdraftHistory | ParquetFileWriter |
| 138 | EmailOptInRate | ParquetFileWriter |
| 139 | SmsOptInRate | ParquetFileWriter |
| 142 | PreferenceChangeCount | ParquetFileWriter |
| 145 | CustomerContactability | ParquetFileWriter |
| 147 | Customer360Snapshot | ParquetFileWriter |
| 149 | PaymentChannelMix | ParquetFileWriter |
| 151 | CustomerAttritionSignals | ParquetFileWriter |
| 153 | BranchCardActivity | ParquetFileWriter |
| 156 | QuarterlyExecutiveKpis | ParquetFileWriter |
| 158 | DebitCreditRatio | ParquetFileWriter |
| 160 | DormantAccountDetection | ParquetFileWriter |
| 162 | BranchTransactionVolume | ParquetFileWriter |
| 164 | InterAccountTransfers | ParquetFileWriter |

## Summary

- **CSV:** 65 jobs (57 CsvFileWriter + 8 External modules producing CSV)
- **Parquet:** 40 jobs (ParquetFileWriter)
- **Total:** 105 jobs
