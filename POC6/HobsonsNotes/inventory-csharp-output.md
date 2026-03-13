# C# MockEtlFramework Output Inventory

**Source:** `/media/dan/fdrive/codeprojects/MockEtlFramework/Output/curated/`
**Inventoried:** 2026-03-11

## Summary

| Metric | Value |
|---|---|
| Total files | 22,296 |
| Total size on disk | 2.3 GB |
| Parquet files | 16,259 (646 MB) |
| CSV files | 6,037 (1.7 GB) |
| Unique job names | 105 (plus 2 sub-jobs under `dans_transaction_special`) |
| Date range | 2024-10-01 through 2024-12-31 (92 days) |

## Directory Structure

Every job uses date-partitioned output. The canonical nesting pattern is:

```
curated/
  {job_name}/
    {job_name}/
      {YYYY-MM-DD}/
        {job_name}/
          part-00000.parquet    (or {job_name}.csv)
          part-00001.parquet    (if multi-part)
```

That is: the job name is repeated three levels deep, with a date directory in the middle. Parquet jobs use `part-NNNNN.parquet` filenames; CSV jobs use `{job_name}.csv`.

**43 jobs also have a bare CSV file** at the top level alongside their date-partitioned directory (e.g. `daily_transaction_summary.csv` sitting next to `daily_transaction_summary/`). These bare CSVs are mostly 4 KB stubs, with a few larger ones (the largest is `daily_transaction_summary.csv` at 6.6 MB).

**One special case:** `dans_transaction_special` contains two sub-jobs (`dans_transaction_details` and `dans_transactions_by_state_province`), each with 92 date directories producing CSV output.

## File Format Breakdown

Of the 105 job directories:
- **65 produce CSV** (one `.csv` file per date)
- **40 produce Parquet** (one or more `.parquet` parts per date)
- **0 mixed-format jobs**

## Per-Job Inventory

### Full-Coverage Jobs (92 dates, all populated)

#### CSV Jobs (1 file per date) -- 60 jobs

| Job | Dates | Files |
|---|---|---|
| account_type_distribution | 92 | 92 |
| account_velocity_tracking | 92 | 92 |
| branch_directory | 92 | 92 |
| branch_visit_purpose_breakdown | 92 | 92 |
| branch_visit_summary | 92 | 92 |
| branch_visits_by_customer | 92 | 92 |
| card_authorization_summary | 92 | 92 |
| card_fraud_flags | 92 | 92 |
| card_transaction_daily | 92 | 92 |
| card_type_distribution | 92 | 92 |
| communication_channel_map | 92 | 92 |
| compliance_event_summary | 92 | 92 |
| compliance_resolution_time | 92 | 92 |
| compliance_transaction_ratio | 92 | 92 |
| credit_score_average | 92 | 92 |
| credit_score_delta | 92 | 92 |
| credit_score_snapshot | 92 | 92 |
| cross_sell_candidates | 92 | 92 |
| customer_branch_activity | 92 | 92 |
| customer_compliance_risk | 92 | 92 |
| customer_credit_summary | 92 | 92 |
| customer_demographics | 92 | 92 |
| customer_investment_summary | 92 | 92 |
| customer_segment_map | 92 | 92 |
| customer_transaction_activity | 92 | 92 |
| customer_value_score | 92 | 92 |
| daily_balance_movement | 92 | 92 |
| daily_transaction_summary | 92 | 92 |
| daily_wire_volume | 92 | 92 |
| do_not_contact_list | 92 | 92 |
| executive_dashboard | 92 | 92 |
| fee_revenue_daily | 92 | 92 |
| fee_waiver_analysis | 92 | 92 |
| high_balance_accounts | 92 | 92 |
| high_risk_merchant_activity | 92 | 92 |
| investment_account_overview | 92 | 92 |
| investment_risk_profile | 92 | 92 |
| large_wire_report | 92 | 92 |
| marketing_eligible_customers | 92 | 92 |
| merchant_category_directory | 92 | 92 |
| monthly_revenue_breakdown | 92 | 92 |
| monthly_transaction_trend | 92 | 92 |
| overdraft_daily_summary | 92 | 92 |
| overdraft_fee_summary | 92 | 92 |
| overdraft_recovery_rate | 92 | 92 |
| peak_transaction_times | 92 | 92 |
| preference_by_segment | 92 | 92 |
| preference_summary | 92 | 92 |
| preference_trend | 92 | 92 |
| product_penetration | 92 | 92 |
| securities_directory | 92 | 92 |
| top_branches | 92 | 92 |
| transaction_anomaly_flags | 92 | 92 |
| transaction_category_summary | 92 | 92 |
| transaction_size_buckets | 92 | 92 |
| wealth_tier_analysis | 92 | 92 |
| weekend_transaction_pattern | 92 | 92 |
| wire_direction_summary | 92 | 92 |
| dans_transaction_details (sub-job) | 92 | 92 |
| dans_transactions_by_state_province (sub-job) | 92 | 92 |

#### Parquet Jobs (1 part per date) -- 18 jobs

| Job | Dates | Files |
|---|---|---|
| bond_maturity_schedule | 92 | 93 |
| card_spending_by_merchant | 92 | 93 |
| compliance_open_items* | 92 | 67 |
| credit_score_average | 92 | 92 |
| email_opt_in_rate | 92 | 93 |
| overdraft_daily_summary | 92 | 92 |
| payment_channel_mix | 92 | 93 |
| preference_change_count | 92 | 93 |
| sms_opt_in_rate | 92 | 93 |
| wire_transfer_daily | 92 | 93 |

*Note: jobs showing 93 files have a stray `part-00000.parquet` at the top of the job directory alongside the date-partitioned tree.*

#### Parquet Jobs (multi-part per date) -- 9 jobs

| Job | Dates | Parts/Date | Total Files |
|---|---|---|---|
| account_balance_snapshot | 92 | 2 | 184 |
| account_customer_join | 92 | 2 | 132 |
| account_overdraft_history | 92 | 50 | 2,600 |
| branch_card_activity | 92 | 50 | 3,350 |
| branch_visit_log | 92 | 3 | 276 |
| covered_transactions | 92 | 4 | 372 |
| customer_address_history | 92 | 2 | 184 |
| customer_contact_info | 92 | 2 | 184 |
| customer_full_profile | 92 | 2 | 132 |
| large_transaction_log | 92 | 3 | 276 |
| loan_risk_assessment | 92 | 2 | 132 |
| top_holdings_by_value | 92 | 50 | 3,350 |

### Jobs With Gaps

#### Missing 2024-10-15 Only (1 missing date) -- 4 jobs

| Job | Format | Dates | Files |
|---|---|---|---|
| account_status_summary | CSV | 91 | 91 |
| customer_account_summary | CSV | 91 | 91 |
| daily_transaction_volume | CSV | 91 | 91 |
| card_expiration_watch | Parquet | 91 | 64 |
| card_status_snapshot | Parquet (50 parts) | 91 | 3,300 |

#### Weekday-Only Jobs (26 missing weekend dates) -- 11 jobs

These jobs have all 92 date directories but only populate data on weekdays (66 of 92 dates contain files; all 26 Saturdays and Sundays are empty).

| Job | Format | Populated Dates | Files |
|---|---|---|---|
| branch_transaction_volume | Parquet | 66 | 67 |
| card_customer_spending | Parquet | 66 | 67 |
| compliance_open_items | Parquet | 66 | 67 |
| customer_360_snapshot | Parquet | 66 | 67 |
| customer_attrition_signals | Parquet | 66 | 67 |
| customer_contactability | Parquet | 66 | 67 |
| debit_credit_ratio | Parquet | 66 | 67 |
| dormant_account_detection | Parquet | 66 | 67 |
| fund_allocation_breakdown | CSV | 66 | 66 |
| holdings_by_sector | CSV | 66 | 66 |
| loan_portfolio_snapshot | Parquet | 66 | 66 |
| portfolio_concentration | Parquet | 66 | 67 |
| portfolio_value_summary | Parquet | 66 | 67 |
| quarterly_executive_kpis | Parquet | 66 | 67 |
| regulatory_exposure_summary | Parquet | 66 | 67 |

*Note: Parquet jobs showing 67 files have the same stray `part-00000.parquet` at the directory root.*

#### Heavily Sparse Jobs

| Job | Format | Dates with Data | Empty Dates | Total Files | Pattern |
|---|---|---|---|---|---|
| overdraft_by_account_type | Parquet | 51 | 41 | 52 | Weekdays only, additional gaps |
| overdraft_customer_profile | Parquet | 51 | 41 | 52 | Weekdays only, additional gaps |
| overdraft_amount_distribution | CSV | 69 | 23 | 69 | Irregular gaps |
| inter_account_transfers | Parquet | 3 | 89 | 4 | Only 3 dates + 1 stray file |
| repeat_overdraft_customers | Parquet | 0 | 92 | 1 | All date dirs empty; 1 top-level file |
| suspicious_wire_flags | Parquet | 0 | 92 | 1 | All date dirs empty; 1 top-level file |

## Top 10 Jobs by Size

| Job | Size |
|---|---|
| customer_segment_map | 673 MB |
| daily_transaction_summary | 421 MB |
| customer_transaction_activity | 241 MB |
| large_transaction_log | 182 MB |
| customer_contact_info | 143 MB |
| covered_transactions | 110 MB |
| account_balance_snapshot | 88 MB |
| dans_transaction_special | 61 MB |
| branch_visit_purpose_breakdown | 34 MB |
| customer_branch_activity | 30 MB |

## Observations

1. **Two output formats, cleanly split.** 65 jobs produce CSV, 40 produce Parquet. No job mixes formats.

2. **The majority pattern is 92 dates x 1 file.** Most jobs produce one output file per calendar day across the full Oct-Dec 2024 range. This is the baseline against which gaps are measured.

3. **43 "bare" CSV files at the top level** duplicate job names that also have date-partitioned directories. Most are 4 KB (likely headers-only or single-row summaries). `daily_transaction_summary.csv` is the outlier at 6.6 MB.

4. **Stray parquet files.** Several Parquet jobs have a `part-00000.parquet` sitting at the directory root alongside the date-partitioned tree (outside any date folder). This accounts for the `total files = dates + 1` discrepancy seen in ~14 jobs.

5. **Weekday-only is a real pattern, not data corruption.** 15 jobs only populate weekdays. All 26 missing dates are Saturdays and Sundays. Likely business-day-only reports.

6. **Three high-volume parquet jobs** each produce 50 parts per date: `account_overdraft_history`, `branch_card_activity`, and `top_holdings_by_value` (2,600 / 3,350 / 3,350 files respectively).

7. **Two effectively empty jobs** (`repeat_overdraft_customers`, `suspicious_wire_flags`) have the full 92-date directory scaffold but all date directories are empty. Each has a single `part-00000.parquet` at the directory root.

8. **`inter_account_transfers` is nearly empty** -- only 3 of 92 dates contain data (2024-10-08, 2024-11-21, 2024-12-20), plus one stray file.
