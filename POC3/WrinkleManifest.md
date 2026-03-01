# Phase 3 Wrinkle Manifest

**CONFIDENTIAL — Not for Phase 3 agents. Post-run analysis only.**

This document records every wrinkle planted in the 70 Phase 3 jobs. Agents performing
the reverse-engineering run must discover these independently.

## Wrinkle Key

### File-Output Wrinkles
| ID | Name | Effect |
|---|---|---|
| W1 | Sunday skip | Returns empty DataFrame on Sundays (0-row file) |
| W2 | Weekend fallback | Uses previous Friday's data on Sat/Sun |
| W3a | End-of-week boundary | Daily output every day; appends WEEKLY_TOTAL row(s) on Sundays |
| W3b | End-of-month boundary | Daily output every day; appends MONTHLY_TOTAL row(s) on last day of month |
| W3c | End-of-quarter boundary | Daily output every day; appends QUARTERLY_TOTAL row(s) on Oct 31 (fiscal Q3→Q4) |
| W4 | Integer division | Percentages computed as int/int → truncates to 0 |
| W5 | Banker's rounding | MidpointRounding.ToEven instead of AwayFromZero |
| W6 | Double epsilon | Accumulates double arithmetic (0.1+0.2≠0.3) |
| W7 | Trailer inflated count | External writes CSV directly, trailer counts input rows not output |
| W8 | Trailer stale date | Trailer date hardcoded to "2024-10-01" |
| W9 | Wrong writeMode | Overwrite↔Append swapped |
| W10 | Absurd numParts | numParts:50 for tiny datasets |
| W12 | Header every append | External writes CSV in Append mode, re-emits header each day |

### Code-Quality Anti-Patterns
| ID | Name | Effect |
|---|---|---|
| AP1 | Dead-end sourcing | Config sources tables never used in processing |
| AP2 | Duplicated logic | Re-derives data another job already computed |
| AP3 | Unnecessary External | C# module where SQL Transformation suffices |
| AP4 | Unused columns | Config sources columns never referenced |
| AP5 | Asymmetric NULLs | Inconsistent NULL/empty/0 defaults |
| AP6 | Row-by-row iteration | foreach loop where SQL set operation would do |
| AP7 | Magic values | Hardcoded thresholds without documentation |
| AP8 | Complex SQL | Unused CTEs, unnecessary window functions |
| AP9 | Misleading names | Job/output name contradicts actual content |
| AP10 | Over-sourcing dates | Sources full table then filters in SQL WHERE |

---

## Domain A: Card Analytics

| # | Config | Format | Wrinkles | External Module | Notes |
|---|---|---|---|---|---|
| 1 | card_transaction_daily | CSV+Trailer | W3b, AP1 | CardTransactionDailyProcessor | End-of-month MONTHLY_TOTAL row; dead-end accounts + customers |
| 2 | card_spending_by_merchant | Parquet | AP3, AP4, AP6 | CardSpendingByMerchantProcessor | Row-by-row grouping; unused authorization_status, risk_level |
| 3 | card_fraud_flags | CSV | W5, AP7 | CardFraudFlagsProcessor | Banker's rounding on amounts; magic $500 threshold |
| 4 | card_authorization_summary | CSV+Trailer | W4, AP8 | *(SQL only)* | Int division: approved/total → 0; unused CTE + window func |
| 5 | card_customer_spending | Parquet | W2, AP1, AP4 | CardCustomerSpendingProcessor | Weekend→Friday fallback; dead-end accounts; unused prefix/suffix |
| 6 | high_risk_merchant_activity | CSV | AP3, AP6, AP7 | HighRiskMerchantActivityProcessor | Row-by-row join; magic "High" string |
| 7 | card_status_snapshot | Parquet | W10, AP4 | *(SQL only)* | numParts:50 for ~3 rows; unused card_number_masked, expiration_date |
| 8 | card_type_distribution | CSV+Trailer | W6, AP8 | CardTypeDistributionProcessor | Double arithmetic for pct; card_transactions sourced unused |
| 9 | merchant_category_directory | CSV | W9(Append), AP1 | *(SQL only)* | Append mode → duplicates; dead-end cards table |
| 10 | card_expiration_watch | Parquet | W2, AP3, AP6 | CardExpirationWatchProcessor | Weekend→Friday; row-by-row 90-day check |

## Domain B: Investment & Securities

| # | Config | Format | Wrinkles | External Module | Notes |
|---|---|---|---|---|---|
| 11 | portfolio_value_summary | Parquet | W2, AP3, AP6 | PortfolioValueCalculator | Weekend→Friday; row-by-row portfolio calc |
| 12 | holdings_by_sector | CSV+Trailer | W7, AP4 | HoldingsBySectorWriter | Direct CSV write; trailer uses input row count; unused cost_basis, exchange |
| 13 | investment_risk_profile | CSV | AP3, AP5, AP7 | InvestmentRiskClassifier | Magic $50K/$200K thresholds; null risk→"Unknown" vs null value→0 |
| 14 | securities_directory | CSV | W9(Overwrite), AP1 | *(SQL only)* | Overwrite loses prior days; dead-end holdings |
| 15 | top_holdings_by_value | Parquet | W10, AP8 | *(SQL only)* | numParts:50 for ~20 rows; unused CTE + ROW_NUMBER |
| 16 | investment_account_overview | CSV+Trailer | W1, AP4 | InvestmentAccountOverviewBuilder | Sunday skip; unused advisor_id, prefix, suffix |
| 17 | portfolio_concentration | Parquet | W4, W6, AP6 | PortfolioConcentrationCalculator | Int division for pct; double accumulation; nested loops |
| 18 | customer_investment_summary | CSV | W5, AP1, AP4 | CustomerInvestmentSummaryBuilder | Banker's rounding; dead-end securities; unused advisor_id, birthdate |
| 19 | bond_maturity_schedule | Parquet | AP3, AP4, AP6 | BondMaturityScheduleBuilder | Row-by-row bond filter; unused exchange, cost_basis |
| 20 | fund_allocation_breakdown | CSV+Trailer | W8, AP8 | FundAllocationWriter | Direct CSV write; trailer date hardcoded "2024-10-01" |

## Domain C: Compliance & Regulatory

| # | Config | Format | Wrinkles | External Module | Notes |
|---|---|---|---|---|---|
| 21 | compliance_event_summary | CSV+Trailer | W1, AP1 | ComplianceEventSummaryBuilder | Sunday skip; dead-end accounts |
| 22 | wire_transfer_daily | Parquet | W3b, AP3, AP6 | WireTransferDailyProcessor | End-of-month MONTHLY_TOTAL row; row-by-row daily aggregation |
| 23 | large_wire_report | CSV | AP7, W5 | LargeWireReportBuilder | Magic $10000 threshold; banker's rounding |
| 24 | wire_direction_summary | CSV+Trailer | W7, AP8 | WireDirectionSummaryWriter | Direct CSV write; trailer input count; complex grouping |
| 25 | compliance_open_items | Parquet | W2, AP4 | ComplianceOpenItemsBuilder | Weekend→Friday; unused review_date, prefix, suffix |
| 26 | customer_compliance_risk | CSV | W5, W6, AP3, AP6 | CustomerComplianceRiskCalculator | Double accumulation; banker's rounding; row-by-row composite score |
| 27 | suspicious_wire_flags | Parquet | AP7, AP1, AP4 | SuspiciousWireFlagProcessor | Magic "OFFSHORE"/50000; dead-end accounts; unused counterparty_bank, suffix |
| 28 | compliance_resolution_time | CSV+Trailer | W4, AP8 | *(SQL only)* | Int division: total_days/resolved_count; CTE + window func |
| 29 | daily_wire_volume | CSV | W9(Append), AP10 | *(SQL only)* | Append→duplicates; explicit date range over-sourcing |
| 30 | regulatory_exposure_summary | Parquet | W2, AP2, AP6 | RegulatoryExposureCalculator | Weekend→Friday; re-derives compliance risk from #26; row-by-row |

## Domain D: Overdraft & Fee Analysis

| # | Config | Format | Wrinkles | External Module | Notes |
|---|---|---|---|---|---|
| 31 | overdraft_daily_summary | CSV+Trailer | W3a, AP1 | OverdraftDailySummaryProcessor | End-of-week WEEKLY_TOTAL row on Sundays; dead-end transactions |
| 32 | overdraft_by_account_type | Parquet | W4, AP3, AP6 | OverdraftByAccountTypeProcessor | Int division; row-by-row join |
| 33 | fee_waiver_analysis | CSV | AP5, AP4 | *(SQL only)* | Asymmetric NULL handling; unused event_timestamp, interest_rate, credit_limit, apr |
| 34 | repeat_overdraft_customers | Parquet | AP3, AP6, AP7 | RepeatOverdraftCustomerProcessor | Magic threshold 2; row-by-row counting |
| 35 | overdraft_amount_distribution | CSV+Trailer | W7, AP8 | OverdraftAmountDistributionProcessor | Direct CSV write; trailer input count; bucketing |
| 36 | fee_revenue_daily | CSV | W3b, W6, AP10 | FeeRevenueDailyProcessor | End-of-month MONTHLY_TOTAL row; double arithmetic; over-sourcing dates |
| 37 | overdraft_customer_profile | Parquet | W2, AP1, AP4 | OverdraftCustomerProfileProcessor | Weekend→Friday; dead-end accounts; unused prefix, suffix, birthdate |
| 38 | overdraft_recovery_rate | CSV+Trailer | W4, W5 | OverdraftRecoveryRateProcessor | Int division then banker's rounding |
| 39 | account_overdraft_history | Parquet | W10, AP4 | *(SQL only)* | numParts:50; unused event_timestamp, interest_rate, credit_limit |
| 40 | overdraft_fee_summary | CSV | W9(Overwrite), AP8 | *(SQL only)* | Overwrite loses prior days; CTE + ROW_NUMBER |

## Domain E: Customer Preferences & Communication

| # | Config | Format | Wrinkles | External Module | Notes |
|---|---|---|---|---|---|
| 41 | preference_summary | CSV+Trailer | AP3, AP6 | PreferenceSummaryCounter | Row-by-row opt-in/opt-out counting |
| 42 | email_opt_in_rate | Parquet | W4, AP1 | *(SQL only)* | Int division; dead-end phone_numbers |
| 43 | sms_opt_in_rate | Parquet | W4, AP2 | *(SQL only)* | Int division; duplicated logic from #42 |
| 44 | marketing_eligible_customers | CSV | W2, AP3, AP4 | MarketingEligibleProcessor | Weekend→Friday; unused prefix, suffix, birthdate, email_type |
| 45 | do_not_contact_list | CSV+Trailer | W1, AP6 | DoNotContactProcessor | Sunday skip; row-by-row all-opted-out check |
| 46 | preference_change_count | Parquet | AP8, AP4 | *(SQL only)* | CTE + RANK; unused updated_date, prefix |
| 47 | communication_channel_map | CSV | AP3, AP5, AP6 | CommunicationChannelMapper | null email→"N/A" vs null phone→""; row-by-row |
| 48 | preference_by_segment | CSV+Trailer | W7, W5 | PreferenceBySegmentWriter | Direct CSV write; inflated trailer; banker's rounding |
| 49 | customer_contactability | Parquet | W2, AP1, AP4 | CustomerContactabilityProcessor | Weekend→Friday; dead-end segments; unused prefix, suffix |
| 50 | preference_trend | CSV | W9(Append), AP9 | *(SQL only)* | Append→duplicates; "trend" is just daily counts |

## Domain F: Cross-Domain Analytics

| # | Config | Format | Wrinkles | External Module | Notes |
|---|---|---|---|---|---|
| 51 | customer_360_snapshot | Parquet | W2, AP3, AP4, AP6 | Customer360SnapshotBuilder | Weekend→Friday; row-by-row; unused prefix, suffix, interest_rate, etc. |
| 52 | wealth_tier_analysis | CSV+Trailer | W5, AP7, AP8 | WealthTierAnalyzer | Banker's rounding; magic $10K/$100K/$500K tiers |
| 53 | payment_channel_mix | Parquet | AP2, AP4 | *(SQL only)* | UNION ALL; re-derives txn counts; unused description, merchant_name, etc. |
| 54 | cross_sell_candidates | CSV | AP3, AP5, AP6 | CrossSellCandidateFinder | null card→"No Card" vs null investment→0; row-by-row |
| 55 | customer_attrition_signals | Parquet | W6, AP3, AP6, AP7 | CustomerAttritionScorer | Double accumulation; magic balance<100, txn<3 |
| 56 | monthly_revenue_breakdown | CSV+Trailer | W3c, W5 | MonthlyRevenueBreakdownBuilder | End-of-quarter QUARTERLY_TOTAL rows on Oct 31; banker's rounding |
| 57 | branch_card_activity | Parquet | W10, AP1, AP4 | *(SQL only)* | numParts:50; dead-end segments; unused authorization_status, country |
| 58 | product_penetration | CSV | W4, AP8 | *(SQL only)* | Int division; CTEs + window functions |
| 59 | compliance_transaction_ratio | CSV+Trailer | W4, W7 | ComplianceTransactionRatioWriter | Direct CSV write; int division; inflated trailer |
| 60 | quarterly_executive_kpis | Parquet | W2, AP2, AP9 | QuarterlyExecutiveKpiBuilder | Weekend→Friday; re-derives KPIs; "quarterly" is daily |

## Domain G: Extended Transaction Analytics

| # | Config | Format | Wrinkles | External Module | Notes |
|---|---|---|---|---|---|
| 61 | weekend_transaction_pattern | CSV+Trailer | W3a, AP10 | WeekendTransactionPatternProcessor | Daily weekday/weekend split; end-of-week WEEKLY_TOTAL rows on Sundays; over-sourcing dates |
| 62 | debit_credit_ratio | Parquet | W4, W6, AP4 | DebitCreditRatioCalculator | Int division; double accumulation; unused description, interest_rate, credit_limit |
| 63 | transaction_size_buckets | CSV | AP7, AP8 | *(SQL only)* | Magic bucket boundaries; CTEs + window functions |
| 64 | dormant_account_detection | Parquet | W2, AP3, AP6 | DormantAccountDetector | Weekend→Friday; row-by-row zero-txn check |
| 65 | account_velocity_tracking | CSV+Trailer | W12, AP4 | AccountVelocityTracker | Direct CSV write; header re-emitted on every append |
| 66 | branch_transaction_volume | Parquet | AP1, AP2, AP4 | *(SQL only)* | Dead-end branches; re-derives txn volumes; unused description, interest_rate, prefix |
| 67 | transaction_anomaly_flags | CSV | W5, AP3, AP6, AP7 | TransactionAnomalyFlagger | Banker's rounding; magic 3.0 std dev threshold; row-by-row stats |
| 68 | inter_account_transfers | Parquet | AP3, AP6, AP8 | InterAccountTransferDetector | O(n²) nested loop matching; SQL self-join would work |
| 69 | peak_transaction_times | CSV+Trailer | W7, AP4 | PeakTransactionTimesWriter | Direct CSV write; inflated trailer; unused description, account_type, interest_rate |
| 70 | daily_balance_movement | CSV | W6, W9(Overwrite) | DailyBalanceMovementCalculator | Double accumulation; Overwrite loses prior days |

---

## Summary Statistics

| Metric | Count |
|---|---|
| Total jobs | 70 |
| Parquet output | 25 |
| CSV output | 23 |
| CSV+Trailer output | 22 |
| Jobs with External module | 47 |
| SQL-only jobs | 23 |
| Jobs with direct file I/O (bypass writer) | 7 (#12, #20, #24, #35, #48, #59, #69) + 1 (#65 W12) |

### Wrinkle Counts
| Wrinkle | Jobs |
|---|---|
| W1 Sunday skip | 3: #16, #21, #45 |
| W2 Weekend fallback | 10: #5, #10, #11, #25, #30, #37, #44, #49, #51, #60, #64 |
| W3a End-of-week boundary | 2: #31, #61 |
| W3b End-of-month boundary | 3: #1, #22, #36 |
| W3c End-of-quarter boundary | 1: #56 |
| W4 Integer division | 10: #4, #17, #28, #32, #38, #42, #43, #58, #59, #62 |
| W5 Banker's rounding | 8: #3, #18, #23, #26, #38, #48, #52, #56, #67 |
| W6 Double epsilon | 7: #8, #17, #26, #36, #55, #62, #70 |
| W7 Trailer inflated | 6: #12, #24, #35, #48, #59, #69 |
| W8 Trailer stale date | 1: #20 |
| W9 Wrong writeMode | 5: #9, #14, #29, #40, #50, #70 |
| W10 Absurd numParts | 4: #7, #15, #39, #57 |
| W12 Header every append | 1: #65 |
