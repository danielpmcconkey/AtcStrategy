# Python ETL Output Inventory — Curated Layer

**Location:** `/media/dan/fdrive/codeprojects/MockEtlFrameworkPython/Output/curated/`
**Generated:** 2026-03-11

## Summary

| Metric | Value |
|---|---|
| Total files | 7,400 |
| Total size on disk | 376 MB |
| Job directories | 105 |
| File formats | Parquet (5,381), CSV (2,019) |
| Date range | 2024-10-01 through 2024-10-31 |
| Total directories | 4,711 |

## Directory Structure

Four-level nesting:

```
curated/
  {job_name}/
    {output_name}/            ← usually same as job_name (one exception below)
      {YYYY-MM-DD}/
        {output_name}.csv     ← CSV jobs: single file per date
        — or —
        {output_name}/        ← Parquet jobs: subdirectory containing part files
          part-00000.parquet
          part-00001.parquet
          ...
```

**Special case:** `dans_transaction_special` produces two outputs:
- `dans_transaction_details/` (31 CSV files)
- `dans_transactions_by_state_province/` (31 CSV files)

## Unique Job Names (105)

account_balance_snapshot, account_customer_join, account_overdraft_history,
account_status_summary, account_type_distribution, account_velocity_tracking,
bond_maturity_schedule, branch_card_activity, branch_directory,
branch_transaction_volume, branch_visit_log, branch_visit_purpose_breakdown,
branch_visit_summary, branch_visits_by_customer, card_authorization_summary,
card_customer_spending, card_expiration_watch, card_fraud_flags,
card_spending_by_merchant, card_status_snapshot, card_transaction_daily,
card_type_distribution, communication_channel_map, compliance_event_summary,
compliance_open_items, compliance_resolution_time, compliance_transaction_ratio,
covered_transactions, credit_score_average, credit_score_delta,
credit_score_snapshot, cross_sell_candidates, customer_360_snapshot,
customer_account_summary, customer_address_deltas, customer_address_history,
customer_attrition_signals, customer_branch_activity, customer_compliance_risk,
customer_contact_info, customer_contactability, customer_credit_summary,
customer_demographics, customer_full_profile, customer_investment_summary,
customer_segment_map, customer_transaction_activity, customer_value_score,
daily_balance_movement, daily_transaction_summary, daily_transaction_volume,
daily_wire_volume, dans_transaction_special, debit_credit_ratio,
do_not_contact_list, dormant_account_detection, email_opt_in_rate,
executive_dashboard, fee_revenue_daily, fee_waiver_analysis,
fund_allocation_breakdown, high_balance_accounts, high_risk_merchant_activity,
holdings_by_sector, inter_account_transfers, investment_account_overview,
investment_risk_profile, large_transaction_log, large_wire_report,
loan_portfolio_snapshot, loan_risk_assessment, marketing_eligible_customers,
merchant_category_directory, monthly_revenue_breakdown,
monthly_transaction_trend, overdraft_amount_distribution,
overdraft_by_account_type, overdraft_customer_profile, overdraft_daily_summary,
overdraft_fee_summary, overdraft_recovery_rate, payment_channel_mix,
peak_transaction_times, portfolio_concentration, portfolio_value_summary,
preference_by_segment, preference_change_count, preference_summary,
preference_trend, product_penetration, quarterly_executive_kpis,
regulatory_exposure_summary, repeat_overdraft_customers, securities_directory,
sms_opt_in_rate, suspicious_wire_flags, top_branches,
top_holdings_by_value, transaction_anomaly_flags, transaction_category_summary,
transaction_size_buckets, wealth_tier_analysis, weekend_transaction_pattern,
wire_direction_summary, wire_transfer_daily

## Job Coverage Tiers

### Tier 1: Full coverage — 31 dates, all calendar days (67 jobs)

**CSV — 1 file per date (63 outputs across 62 job dirs):**

account_status_summary, account_type_distribution, account_velocity_tracking,
branch_directory, branch_visit_purpose_breakdown, branch_visit_summary,
branch_visits_by_customer, card_authorization_summary, card_fraud_flags,
card_transaction_daily, card_type_distribution, communication_channel_map,
compliance_event_summary, compliance_resolution_time, compliance_transaction_ratio,
credit_score_average, credit_score_delta, credit_score_snapshot,
cross_sell_candidates, customer_account_summary, customer_branch_activity,
customer_compliance_risk, customer_credit_summary, customer_demographics,
customer_investment_summary, customer_segment_map, customer_transaction_activity,
customer_value_score, daily_balance_movement, daily_transaction_summary,
daily_transaction_volume, daily_wire_volume, dans_transaction_special (details),
dans_transaction_special (by_state_province), do_not_contact_list,
executive_dashboard, fee_revenue_daily, fee_waiver_analysis,
high_balance_accounts, high_risk_merchant_activity, investment_account_overview,
investment_risk_profile, large_wire_report, marketing_eligible_customers,
merchant_category_directory, monthly_revenue_breakdown, monthly_transaction_trend,
overdraft_daily_summary, overdraft_fee_summary, overdraft_recovery_rate,
peak_transaction_times, preference_by_segment, preference_summary,
preference_trend, product_penetration, securities_directory, top_branches,
transaction_anomaly_flags, transaction_category_summary, transaction_size_buckets,
wealth_tier_analysis, weekend_transaction_pattern, wire_direction_summary

**Parquet — 31 dates:**

| Job | Parts/date | Total files |
|---|---|---|
| account_balance_snapshot | 2 | 62 |
| bond_maturity_schedule | 1 | 31 |
| branch_visit_log | 3 | 93 |
| card_spending_by_merchant | 1 | 31 |
| covered_transactions | 4 | 124 |
| customer_address_deltas | 1 | 31 |
| customer_address_history | 2 | 62 |
| customer_contact_info | 2 | 62 |
| email_opt_in_rate | 1 | 31 |
| large_transaction_log | 3 | 93 |
| payment_channel_mix | 1 | 31 |
| preference_change_count | 1 | 31 |
| sms_opt_in_rate | 1 | 31 |
| wire_transfer_daily | 1 | 31 |

### Tier 2: Weekday-only — 23 dates (22 jobs)

Skips all Saturdays and Sundays (Oct 5-6, 12-13, 19-20, 26-27).

**CSV — 1 file per date (2 jobs):**

fund_allocation_breakdown, holdings_by_sector

**Parquet — 23 dates:**

| Job | Parts/date | Total files |
|---|---|---|
| account_customer_join | 2 | 46 |
| branch_card_activity | 50 | 1,150 |
| branch_transaction_volume | 1 | 23 |
| card_customer_spending | 1 | 23 |
| card_status_snapshot | 50 | 1,150 |
| compliance_open_items | 1 | 23 |
| customer_360_snapshot | 1 | 23 |
| customer_attrition_signals | 1 | 23 |
| customer_contactability | 1 | 23 |
| customer_full_profile | 2 | 46 |
| debit_credit_ratio | 1 | 23 |
| dormant_account_detection | 1 | 23 |
| loan_portfolio_snapshot | 1 | 23 |
| loan_risk_assessment | 2 | 46 |
| portfolio_concentration | 1 | 23 |
| portfolio_value_summary | 1 | 23 |
| quarterly_executive_kpis | 1 | 23 |
| regulatory_exposure_summary | 1 | 23 |
| top_holdings_by_value | 50 | 1,150 |

### Tier 3: Weekday-only, minus Oct 1-2 — 21 dates (1 job)

| Job | Format | Parts/date | Total files |
|---|---|---|---|
| card_expiration_watch | Parquet | 1 | 21 |

### Tier 4: Sparse weekday — 14 dates (3 jobs)

All three share the same 14 dates: Oct 1-3, 7, 9-10, 14-16, 22, 24-25, 29-30.
Skips all weekends plus sporadic weekdays.

| Job | Format | Parts/date | Total files |
|---|---|---|---|
| account_overdraft_history | Parquet | 50 | 700 |
| overdraft_by_account_type | Parquet | 1 | 14 |
| overdraft_customer_profile | Parquet | 1 | 14 |

### Tier 5: Irregular — 20 dates (1 job)

| Job | Format | Total files |
|---|---|---|
| overdraft_amount_distribution | CSV | 20 |

No clear weekday/weekend pattern. Missing: Oct 4, 6, 8, 11, 17-18, 20-21, 23, 28, 31.

### Tier 6: Minimal — 1 date (1 job)

| Job | Format | Date | Total files |
|---|---|---|---|
| inter_account_transfers | Parquet | 2024-10-08 only | 1 |

### Tier 7: Empty — directory scaffolding only, 0 files (2 jobs)

| Job | Notes |
|---|---|
| repeat_overdraft_customers | 31 date dirs created, all empty |
| suspicious_wire_flags | 31 date dirs created, all empty |

## Gap Analysis

**97 of 105 jobs** produce output for the full date range they're expected to cover (either all 31 days or all 23 weekdays).

**8 jobs with notable gaps or anomalies:**

| Job | Expected | Actual | Gap |
|---|---|---|---|
| account_overdraft_history | 23 or 31 | 14 | 9-17 missing dates |
| overdraft_by_account_type | 23 or 31 | 14 | same 14-date pattern |
| overdraft_customer_profile | 23 or 31 | 14 | same 14-date pattern |
| overdraft_amount_distribution | 31? | 20 | irregular gaps |
| card_expiration_watch | 23 | 21 | missing Oct 1-2 |
| inter_account_transfers | 31? | 1 | only Oct 8 |
| repeat_overdraft_customers | 31 | 0 | completely empty |
| suspicious_wire_flags | 31 | 0 | completely empty |

The three overdraft jobs (account_overdraft_history, overdraft_by_account_type, overdraft_customer_profile) share the exact same 14-date coverage, suggesting a common upstream dependency or filter condition.

## Parquet Partitioning Summary

| Parts/date | Jobs |
|---|---|
| 50 | account_overdraft_history, branch_card_activity, card_status_snapshot, top_holdings_by_value |
| 4 | covered_transactions |
| 3 | branch_visit_log, large_transaction_log |
| 2 | account_balance_snapshot, account_customer_join, customer_address_history, customer_contact_info, customer_full_profile, loan_risk_assessment |
| 1 | All remaining parquet jobs |

## Disk Usage — Top 10 by Size

| Job | Size |
|---|---|
| customer_segment_map | 79 MB |
| daily_transaction_summary | 56 MB |
| customer_transaction_activity | 28 MB |
| large_transaction_log | 27 MB |
| dans_transaction_special | 19 MB |
| covered_transactions | 18 MB |
| customer_contact_info | 15 MB |
| account_balance_snapshot | 9.4 MB |
| top_holdings_by_value | 9.3 MB |
| branch_card_activity | 8.4 MB |
