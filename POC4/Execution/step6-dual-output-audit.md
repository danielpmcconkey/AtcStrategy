# Step 6: Dual-Output Audit — External Module + Framework Writer Jobs

**Date:** 2026-03-06
**Scope:** 62 V1 jobs that have BOTH an External C# module AND a framework file writer (CsvFileWriter or ParquetFileWriter) in the same job config.

## Executive Summary

**All 62 jobs are COMPUTE-ONLY.** Not a single External module in this set writes its own output file. Every one of them follows the same pattern:

1. Receive data from `sharedState` (populated by preceding DataSourcing modules)
2. Perform computation (joins, aggregations, filtering, scoring, etc.)
3. Deposit the result into `sharedState["output"]` as a `DataFrame`
4. Return `sharedState` to the framework

The framework writer (CsvFileWriter or ParquetFileWriter) then reads `sharedState["output"]` and writes the sole output file.

**There are zero DUPLICATE cases. There are zero COMPLEMENTARY cases.**

## Methodology

1. Read all 62 job config JSONs from `/workspace/MockEtlFramework/JobExecutor/Jobs/`
2. Identified the External module class referenced by each config's `typeName`
3. Searched all 62 External module C# source files for file-writing patterns:
   - `StreamWriter`, `File.WriteAll*`, `File.Create`, `FileStream`, `TextWriter`, `BinaryWriter`, `OpenWrite`, `CreateText`, `AppendText`
   - `DscWriterUtil`, `WriteCsv`, `WriteParquet`, `.Save(`
   - Database write operations (`INSERT`, `UPDATE`, `NpgsqlCommand` with non-SELECT)
   - Network/process IO (`HttpClient`, `WebRequest`, `Process.Start`)
4. Verified every module implements `IExternalStep` and sets `sharedState["output"]`
5. Read the framework's `External.cs` to confirm the execution contract

### Key Finding: File-Writing Code Exists Only in V2 and Standalone Writer Modules

The grep for file-writing patterns across ALL ExternalModules/*.cs files found hits only in:
- V2 processors (e.g., `AccountVelocityTrackingV2Processor.cs`, `ComplianceTransactionRatioV2Processor.cs`)
- Standalone writer modules (e.g., `FundAllocationWriter.cs`, `HoldingsBySectorWriter.cs`)
- `DscWriterUtil.cs` (a shared utility used by the above)

**None of these are referenced by any of the 62 target jobs.**

### Notable Outliers (Still COMPUTE-ONLY)

Two modules do their own database reads instead of relying on DataSourcing modules:
- **CoveredTransactionProcessor** (job 33): Opens its own `NpgsqlConnection` to run complex queries with snapshot fallback logic. Still deposits result into `sharedState["output"]`.
- **CustomerAddressDeltaProcessor** (job 32): Opens its own `NpgsqlConnection` to fetch current and previous day's addresses for delta detection. Still deposits result into `sharedState["output"]`.

These are data *sourcing* operations, not output operations. They are COMPUTE-ONLY by the audit criteria.

## Full Inventory

| job_id | job_name | External Module | Writer Type | Category | Notes |
|--------|----------|----------------|-------------|----------|-------|
| 4 | LargeTransactionLog | LargeTransactionProcessor | ParquetFileWriter | COMPUTE-ONLY | Joins txns+accounts+customers+addresses, filters large txns |
| 7 | CustomerDemographics | CustomerDemographicsBuilder | CsvFileWriter | COMPUTE-ONLY | Assembles customer demographic profile |
| 11 | CustomerFullProfile | FullProfileAssembler | ParquetFileWriter | COMPUTE-ONLY | Joins customers+phones+emails+segments |
| 12 | AccountBalanceSnapshot | AccountSnapshotBuilder | ParquetFileWriter | COMPUTE-ONLY | Builds account balance snapshot |
| 13 | AccountStatusSummary | AccountStatusCounter | CsvFileWriter | COMPUTE-ONLY | Counts accounts by status |
| 14 | AccountTypeDistribution | AccountDistributionCalculator | CsvFileWriter | COMPUTE-ONLY | Calculates account type distribution |
| 15 | HighBalanceAccounts | HighBalanceFilter | CsvFileWriter | COMPUTE-ONLY | Filters high-balance accounts |
| 16 | AccountCustomerJoin | AccountCustomerDenormalizer | ParquetFileWriter | COMPUTE-ONLY | Denormalizes accounts+customers+addresses |
| 17 | CreditScoreSnapshot | CreditScoreProcessor | CsvFileWriter | COMPUTE-ONLY | Processes credit score snapshot |
| 18 | CreditScoreAverage | CreditScoreAverager | CsvFileWriter | COMPUTE-ONLY | Averages credit scores per customer |
| 19 | LoanPortfolioSnapshot | LoanSnapshotBuilder | ParquetFileWriter | COMPUTE-ONLY | Builds loan portfolio snapshot |
| 20 | LoanRiskAssessment | LoanRiskCalculator | ParquetFileWriter | COMPUTE-ONLY | Calculates loan risk scores |
| 21 | CustomerCreditSummary | CustomerCreditSummaryBuilder | CsvFileWriter | COMPUTE-ONLY | Summarizes credit per customer |
| 23 | BranchVisitLog | BranchVisitEnricher | ParquetFileWriter | COMPUTE-ONLY | Enriches branch visits with customer/branch data |
| 28 | CustomerTransactionActivity | CustomerTxnActivityBuilder | CsvFileWriter | COMPUTE-ONLY | Aggregates transaction activity per customer |
| 29 | CustomerBranchActivity | CustomerBranchActivityBuilder | CsvFileWriter | COMPUTE-ONLY | Aggregates branch activity per customer |
| 30 | CustomerValueScore | CustomerValueCalculator | CsvFileWriter | COMPUTE-ONLY | Calculates customer value scores |
| 31 | ExecutiveDashboard | ExecutiveDashboardBuilder | CsvFileWriter | COMPUTE-ONLY | Builds executive dashboard metrics |
| 32 | CustomerAddressDeltas | CustomerAddressDeltaProcessor | ParquetFileWriter | COMPUTE-ONLY | Detects address changes (own DB reads) |
| 33 | CoveredTransactions | CoveredTransactionProcessor | ParquetFileWriter | COMPUTE-ONLY | Filters covered checking txns (own DB reads) |
| 97 | CardTransactionDaily | CardTransactionDailyProcessor | CsvFileWriter | COMPUTE-ONLY | Processes daily card transactions |
| 98 | CardSpendingByMerchant | CardSpendingByMerchantProcessor | ParquetFileWriter | COMPUTE-ONLY | Aggregates card spending by merchant |
| 99 | CardFraudFlags | CardFraudFlagsProcessor | CsvFileWriter | COMPUTE-ONLY | Flags potential card fraud |
| 101 | CardCustomerSpending | CardCustomerSpendingProcessor | ParquetFileWriter | COMPUTE-ONLY | Aggregates card spending per customer |
| 102 | HighRiskMerchantActivity | HighRiskMerchantActivityProcessor | CsvFileWriter | COMPUTE-ONLY | Identifies high-risk merchant activity |
| 104 | CardTypeDistribution | CardTypeDistributionProcessor | CsvFileWriter | COMPUTE-ONLY | Distributes cards by type |
| 106 | CardExpirationWatch | CardExpirationWatchProcessor | ParquetFileWriter | COMPUTE-ONLY | Watches for expiring cards |
| 107 | PortfolioValueSummary | PortfolioValueCalculator | ParquetFileWriter | COMPUTE-ONLY | Calculates portfolio values |
| 109 | InvestmentRiskProfile | InvestmentRiskClassifier | CsvFileWriter | COMPUTE-ONLY | Classifies investment risk |
| 112 | InvestmentAccountOverview | InvestmentAccountOverviewBuilder | CsvFileWriter | COMPUTE-ONLY | Builds investment account overview |
| 113 | PortfolioConcentration | PortfolioConcentrationCalculator | ParquetFileWriter | COMPUTE-ONLY | Calculates portfolio concentration |
| 114 | CustomerInvestmentSummary | CustomerInvestmentSummaryBuilder | CsvFileWriter | COMPUTE-ONLY | Summarizes investments per customer |
| 115 | BondMaturitySchedule | BondMaturityScheduleBuilder | ParquetFileWriter | COMPUTE-ONLY | Builds bond maturity schedule |
| 117 | ComplianceEventSummary | ComplianceEventSummaryBuilder | CsvFileWriter | COMPUTE-ONLY | Summarizes compliance events |
| 118 | WireTransferDaily | WireTransferDailyProcessor | ParquetFileWriter | COMPUTE-ONLY | Processes daily wire transfers |
| 119 | LargeWireReport | LargeWireReportBuilder | CsvFileWriter | COMPUTE-ONLY | Reports large wire transfers |
| 121 | ComplianceOpenItems | ComplianceOpenItemsBuilder | ParquetFileWriter | COMPUTE-ONLY | Lists open compliance items |
| 122 | CustomerComplianceRisk | CustomerComplianceRiskCalculator | CsvFileWriter | COMPUTE-ONLY | Calculates compliance risk per customer |
| 123 | SuspiciousWireFlags | SuspiciousWireFlagProcessor | ParquetFileWriter | COMPUTE-ONLY | Flags suspicious wire transfers |
| 126 | RegulatoryExposureSummary | RegulatoryExposureCalculator | ParquetFileWriter | COMPUTE-ONLY | Calculates regulatory exposure |
| 127 | OverdraftDailySummary | OverdraftDailySummaryProcessor | CsvFileWriter | COMPUTE-ONLY | Summarizes daily overdrafts |
| 128 | OverdraftByAccountType | OverdraftByAccountTypeProcessor | ParquetFileWriter | COMPUTE-ONLY | Breaks down overdrafts by account type |
| 130 | RepeatOverdraftCustomers | RepeatOverdraftCustomerProcessor | ParquetFileWriter | COMPUTE-ONLY | Identifies repeat overdraft customers |
| 132 | FeeRevenueDaily | FeeRevenueDailyProcessor | CsvFileWriter | COMPUTE-ONLY | Calculates daily fee revenue |
| 133 | OverdraftCustomerProfile | OverdraftCustomerProfileProcessor | ParquetFileWriter | COMPUTE-ONLY | Profiles overdraft customers |
| 134 | OverdraftRecoveryRate | OverdraftRecoveryRateProcessor | CsvFileWriter | COMPUTE-ONLY | Calculates overdraft recovery rates |
| 137 | PreferenceSummary | PreferenceSummaryCounter | CsvFileWriter | COMPUTE-ONLY | Counts preference summaries |
| 140 | MarketingEligibleCustomers | MarketingEligibleProcessor | CsvFileWriter | COMPUTE-ONLY | Identifies marketing-eligible customers |
| 141 | DoNotContactList | DoNotContactProcessor | CsvFileWriter | COMPUTE-ONLY | Builds do-not-contact list |
| 143 | CommunicationChannelMap | CommunicationChannelMapper | CsvFileWriter | COMPUTE-ONLY | Maps communication channels per customer |
| 145 | CustomerContactability | CustomerContactabilityProcessor | ParquetFileWriter | COMPUTE-ONLY | Assesses customer contactability |
| 147 | Customer360Snapshot | Customer360SnapshotBuilder | ParquetFileWriter | COMPUTE-ONLY | Builds 360-degree customer snapshot |
| 148 | WealthTierAnalysis | WealthTierAnalyzer | CsvFileWriter | COMPUTE-ONLY | Analyzes wealth tiers |
| 150 | CrossSellCandidates | CrossSellCandidateFinder | CsvFileWriter | COMPUTE-ONLY | Identifies cross-sell candidates |
| 151 | CustomerAttritionSignals | CustomerAttritionScorer | ParquetFileWriter | COMPUTE-ONLY | Scores customer attrition risk |
| 152 | MonthlyRevenueBreakdown | MonthlyRevenueBreakdownBuilder | CsvFileWriter | COMPUTE-ONLY | Breaks down monthly revenue |
| 156 | QuarterlyExecutiveKpis | QuarterlyExecutiveKpiBuilder | ParquetFileWriter | COMPUTE-ONLY | Builds quarterly KPIs |
| 157 | WeekendTransactionPattern | WeekendTransactionPatternProcessor | CsvFileWriter | COMPUTE-ONLY | Analyzes weekend transaction patterns |
| 158 | DebitCreditRatio | DebitCreditRatioCalculator | ParquetFileWriter | COMPUTE-ONLY | Calculates debit/credit ratios |
| 160 | DormantAccountDetection | DormantAccountDetector | ParquetFileWriter | COMPUTE-ONLY | Detects dormant accounts |
| 163 | TransactionAnomalyFlags | TransactionAnomalyFlagger | CsvFileWriter | COMPUTE-ONLY | Flags transaction anomalies |
| 164 | InterAccountTransfers | InterAccountTransferDetector | ParquetFileWriter | COMPUTE-ONLY | Detects inter-account transfers |
| 166 | DailyBalanceMovement | DailyBalanceMovementCalculator | CsvFileWriter | COMPUTE-ONLY | Calculates daily balance movements |

## Summary Counts

| Category | Count | Percentage |
|----------|-------|------------|
| COMPUTE-ONLY | 62 | 100% |
| COMPLEMENTARY | 0 | 0% |
| DUPLICATE | 0 | 0% |

## Implications for POC4

The "dual-output" concern is a non-issue for these 62 jobs. The architecture is clean:
- External modules are pure computation (data in via shared state, data out via shared state)
- Framework writers are the sole file output mechanism
- No External module in this set bypasses the framework to write its own files

This means:
1. **No deduplication work needed** -- there is only one output path per job
2. **Framework writer changes (e.g., date-partitioning) will capture all output** -- no risk of missed files from External modules writing independently
3. **V2 migration for these jobs only needs to replace External + framework writer** with equivalent V2 logic -- the output contract is already singular

### Where File-Writing External Modules DO Exist (Out of Scope)

For reference, file-writing code exists in these External modules (NOT part of the 62 under audit):
- `FundAllocationWriter.cs`, `HoldingsBySectorWriter.cs`, `ComplianceTransactionRatioWriter.cs`, `PeakTransactionTimesWriter.cs`, `PreferenceBySegmentWriter.cs`, `WireDirectionSummaryWriter.cs`
- Various V2 processors that use `DscWriterUtil.cs`

These are used by other jobs outside this audit scope and may warrant a separate review.
