# Step 6 — Anti-Pattern Coverage Evaluation

**Date:** 2026-03-06
**Evaluator:** Basement Dweller
**Scope:** 102 V1 jobs (IDs 1-33, 97-166, excluding test jobs 369 and 371)
**Inputs:** 71 External module jobs, 31 SQL Transformation jobs, ~100 External module C# files, anti-patterns.md

---

## 1. Executive Summary

The anti-pattern density is **good enough for the mission.** A reverse engineering agent will find substantial material across all 10 official anti-patterns. No anti-pattern is completely absent. The distribution favors AP3, AP6, and AP7 (heavy coverage) with AP2, AP5, AP8, and AP9 being thinner but present. AP1 and AP4 are well-represented in configs. AP10 has a small but clear footprint.

**Overall density estimate:** ~85-90% of the 102 V1 jobs exhibit at least one anti-pattern. The remaining ~10-15% are structurally clean but are simple pass-through or aggregation jobs that might not need dirtying.

---

## 2. Per-Anti-Pattern Assessment

### AP1 — Dead-End Sourcing
**Coverage: SUFFICIENT (20-25 jobs)**

DataSourcing modules that pull data never used by the processing logic.

**Config-level dead-end sourcing (SQL jobs — 15 confirmed):**
These jobs source entire tables that are never referenced in the Transformation SQL:

| Job | Dead-End Source |
|-----|----------------|
| `branch_card_activity` | `segments` |
| `branch_transaction_volume` | `customers`, `branches` |
| `branch_visit_purpose_breakdown` | `segments` |
| `customer_address_history` | `branches` |
| `customer_contact_info` | `segments` |
| `customer_segment_map` | `branches` |
| `daily_transaction_summary` | `branches` |
| `email_opt_in_rate` | `phone_numbers` |
| `merchant_category_directory` | `cards` |
| `monthly_transaction_trend` | `branches` |
| `preference_change_count` | `customers` |
| `securities_directory` | `holdings` |
| `transaction_category_summary` | `segments` |
| `transaction_size_buckets` | `accounts` |

**External module jobs with dead-end sourcing (5-10 additional):**
These source DataFrames that the External module never reads from `sharedState`:

- `suspicious_wire_flags` — sources `accounts` and `customers` (with `suffix`), but `SuspiciousWireFlagProcessor` only uses `wire_transfers`. Comment in code confirms: "AP1: accounts sourced but never used."
- `customer_contactability` — sources `segments`, never used. Comment confirms: "AP1: segments sourced but never used."
- `executive_dashboard` — sources `branches` and `segments`, neither used by `ExecutiveDashboardBuilder`.
- `loan_portfolio_snapshot` — sources `branches`, never used by `LoanSnapshotBuilder`.
- `account_balance_snapshot` — sources `branches`, never used by `AccountSnapshotBuilder`.
- `credit_score_average` — sources `segments`, `CreditScoreAverager` never uses it.
- `credit_score_snapshot` — sources `branches`, `CreditScoreProcessor` is a pure pass-through that ignores it.
- `customer_demographics` — sources `segments`, `CustomerDemographicsBuilder` never uses it.
- `customer_credit_summary` — sources `segments`, unclear if used.
- `loan_risk_assessment` — sources `segments`, unclear if used.

**Verdict: SUFFICIENT.** ~20-25 jobs have at least one dead-end source. The pattern appears across both SQL and External jobs. Good spread.

---

### AP2 — Duplicated Logic
**Coverage: THIN (3-5 jobs)**

Jobs that re-derive data another job already computes.

**Identified instances:**
- `quarterly_executive_kpis` duplicates logic from `executive_dashboard` — both compute total_customers, total_accounts, total_balance, total_transactions, total_txn_amount via the same row-by-row pattern. The code comment confirms: "AP2: Duplicates logic from executive_dashboard."
- `email_opt_in_rate` and `sms_opt_in_rate` are structurally identical SQL queries differing only in the `WHERE preference_type =` filter. A single parameterized job would suffice.
- `account_status_summary` (via `AccountStatusCounter`) and `account_type_distribution` (via `AccountDistributionCalculator`) both count accounts by type, just with different grouping columns.
- `portfolio_value_summary` and `portfolio_concentration` both aggregate holdings by customer with securities lookups — overlapping data paths.

**Verdict: THIN.** The quarterly/executive dashboard pair is the clearest duplicate. The opt-in rate pair is structural duplication. More instances could exist but are harder to confirm without running the jobs. A reverse engineering agent will find 3-5 clear cases. This is the weakest anti-pattern numerically, but it's present enough to be findable.

**Suggestion if more needed:** Create a job that re-derives the total_balance metric from transactions instead of using the accounts table — a different computation path for the same conceptual value.

---

### AP3 — Unnecessary External Module
**Coverage: SUFFICIENT (15-20 jobs)**

External C# modules doing work that a SQL Transformation could handle.

**Clear AP3 candidates (External does simple join + aggregate or filter):**
- `AccountSnapshotBuilder` — pure row-by-row pass-through. 41 lines. Just copies account rows.
- `CreditScoreProcessor` — pure pass-through. 40 lines. Copies credit score rows verbatim.
- `LoanSnapshotBuilder` — pure pass-through. 44 lines. Copies loan rows, skipping 2 columns.
- `AccountStatusCounter` — GROUP BY (account_type, account_status). Trivial SQL.
- `AccountDistributionCalculator` — GROUP BY account_type with percentage. Trivial SQL.
- `PreferenceSummaryCounter` — GROUP BY preference_type with counts. Comment: "AP6: Row-by-row iteration where SQL GROUP BY would suffice."
- `HighBalanceFilter` — Simple WHERE balance > 10000 with JOIN. SQL one-liner.
- `CardTypeDistributionProcessor` — GROUP BY card_type with count/percentage.
- `HighRiskMerchantActivityProcessor` — JOIN + WHERE risk_level = 'High'. Trivial SQL.
- `CustomerComplianceRiskCalculator` — Code comment says "AP3: unnecessary External — SQL could handle this."
- `AccountCustomerDenormalizer` — Simple JOIN accounts to customers. Textbook SQL.
- `DormantAccountDetector` — LEFT JOIN accounts to transactions, WHERE txn IS NULL. SQL anti-join.
- `RepeatOverdraftCustomerProcessor` — GROUP BY customer_id HAVING count >= 2. Trivial SQL.
- `LargeTransactionProcessor` — WHERE amount > 500 with JOINs. Easy SQL.
- `CardFraudFlagsProcessor` — JOIN + WHERE with threshold filter.

**Additionally, the 8 self-writing External modules are AP3 by definition** — they bypass both the Transformation AND the framework writer:
- `AccountVelocityTracker`, `ComplianceTransactionRatioWriter`, `FundAllocationWriter`, `HoldingsBySectorWriter`, `OverdraftAmountDistributionProcessor`, `PeakTransactionTimesWriter`, `PreferenceBySegmentWriter`, `WireDirectionSummaryWriter`

**Verdict: SUFFICIENT.** 15-20 clear cases where SQL Transformation would have been cleaner, plus 8 that go further by bypassing the writer too. A reverse engineering agent will have no trouble identifying these.

---

### AP4 — Unused Columns
**Coverage: SUFFICIENT (15-20 jobs)**

Config sources columns never used in processing or output.

**Confirmed instances:**
- `marketing_eligible_customers` — sources `prefix`, `suffix`, `birthdate` from customers and `email_type` from email_addresses. Code comment: "AP4: unused columns prefix, suffix, birthdate sourced from customers; email_type from email_addresses."
- `customer_contactability` — sources `prefix`, `suffix` from customers. Code comment: "AP4: unused columns prefix, suffix from customers."
- `suspicious_wire_flags` — sources `counterparty_bank` from wire_transfers, `suffix` from customers. Code comment: "AP4: unused columns."
- `customer_360_snapshot` — sources `prefix`, `suffix` from customers; `interest_rate`, `credit_limit`, `apr` from accounts; `card_number_masked` from cards. None appear in output columns.
- `account_overdraft_history` — sources `interest_rate`, `credit_limit` from accounts. SQL only uses `account_type`.
- `fee_waiver_analysis` — sources `interest_rate`, `credit_limit`, `apr` from accounts. SQL only uses `account_id` for JOIN.
- `branch_transaction_volume` — sources `description` from transactions, `prefix` from customers, `city`/`state_province` from branches. SQL uses none of these.
- `card_transaction_daily` — sources 8 columns from card_transactions and pulls accounts and cards tables; likely has unused columns.
- `card_customer_spending` — sources `prefix`, `suffix` from customers; `authorization_status` from card_transactions.
- `large_transaction_log` — sources 9 columns from accounts including `interest_rate`, `credit_limit`, `apr`, `open_date`. External likely doesn't use all.
- `overdraft_customer_profile` — sources 6 columns from customers including `prefix`, `suffix`, `sort_name`.
- `customer_investment_summary` — sources `advisor_id` from investments, `birthdate` from customers, full `securities` table. External only uses investment aggregation.
- `compliance_open_items` — sources `prefix`, `suffix` from customers.
- `holdings_by_sector` — sources 7 cols from holdings, 6 from securities. External only uses `security_id`, `current_value`, and `sector`.
- `preference_change_count` — sources `prefix` from customers. SQL doesn't use customers table at all.

**Verdict: SUFFICIENT.** Heavy coverage across both SQL and External jobs. The pattern of sourcing `prefix`, `suffix`, `birthdate`, `interest_rate`, `credit_limit`, `apr` and then not using them is widespread.

---

### AP5 — Asymmetric Null/Default Handling
**Coverage: THIN (5-8 jobs)**

Inconsistent NULL treatment within a single job.

**Identified instances:**
- `CrossSellCandidateFinder` — Has explicit example with comments: no card becomes string "No Card" but no investment becomes integer `0`. `has_card` is output as "Yes"/"No Card" (string), `has_investment` is output as 1/0 (int). Three different null representations in one job.
- `InvestmentRiskClassifier` — null `current_value` becomes `0m`, null `risk_profile` becomes `"Unknown"`. Comment: "AP5: Asymmetric NULLs."
- `PreferenceBySegmentWriter` — Uses MidpointRounding.ToEven (Banker's rounding) for opt-in rate. This is a W5 pattern, not strictly AP5.
- `ComplianceTransactionRatioWriter` — Integer division truncation (W4). Related but not exactly AP5.
- Several External modules use `?? ""` for some fields and `?? 0` for others without consistency, but these are mild.

**Verdict: THIN.** The `CrossSellCandidateFinder` is the flagship example (three different null strategies in one job). `InvestmentRiskClassifier` adds a second clear case. The pattern exists but isn't widespread enough. A reverse engineering agent will find 3-5 instances.

**Suggestion if more needed:** Add asymmetric handling to a few more External modules — e.g., one where missing `first_name` becomes `""` but missing `last_name` becomes `"N/A"`, or where a null balance becomes `0` in one aggregation and `DBNull.Value` in another output column.

---

### AP6 — Row-by-Row Iteration
**Coverage: SUFFICIENT (30-40+ jobs)**

Foreach loops where SQL set operations would work.

This is the most heavily planted anti-pattern. **Every External module that does a JOIN, GROUP BY, or filter uses row-by-row iteration by definition** — that's inherent to the External module pattern. Specific jobs with explicit AP6 comments:

- `TransactionAnomalyFlagger` — "AP6: Row-by-row iteration to collect per-account amounts"
- `DormantAccountDetector` — "AP6: Row-by-row iteration where SQL set operation would do" (x2)
- `CrossSellCandidateFinder` — "AP6: Row-by-row iteration through customers"
- `CustomerAttritionScorer` — "AP6: Row-by-row iteration computing attrition score"
- `MarketingEligibleProcessor` — "AP6: Row-by-row"
- `DoNotContactProcessor` — "AP6: Row-by-row"
- `RepeatOverdraftCustomerProcessor` — "AP6: Row-by-row iteration to count overdrafts per customer"
- `CardExpirationWatchProcessor` — "AP6: Row-by-row iteration to find cards expiring within 90 days"
- `CustomerComplianceRiskCalculator` — "AP6: row-by-row iteration"
- `PreferenceSummaryCounter` — "AP6: Row-by-row iteration where SQL GROUP BY would suffice"
- `PortfolioValueCalculator` — "AP6: Row-by-row iteration to compute totals (where SQL JOIN+GROUP BY would do)"
- `HighRiskMerchantActivityProcessor` — "AP6: Row-by-row iteration to join and filter (SQL would work)"
- `Customer360SnapshotBuilder` — "AP6: Row-by-row iteration building full customer view"

Plus every External module that does dictionary lookups + foreach is implicitly AP6 — that's at least 30-40 of the 71 External jobs.

**Verdict: SUFFICIENT.** This is the strongest anti-pattern by volume. A reverse engineering agent cannot avoid tripping over it.

---

### AP7 — Magic Values
**Coverage: SUFFICIENT (15-20 jobs)**

Hardcoded thresholds with no documentation or parameterization.

**Identified instances (C# External modules):**
- `TransactionAnomalyFlagger` — `3.0m` standard deviation threshold. Comment: "AP7: Magic value — hardcoded 3.0 threshold."
- `CardFraudFlagsProcessor` — `$500m` amount threshold. Comment: "AP7: Magic value — hardcoded $500 threshold."
- `HighBalanceFilter` — `10000` balance threshold. Hardcoded, no docs.
- `LargeTransactionProcessor` — `500` amount threshold. Hardcoded.
- `WealthTierAnalyzer` — `10000m`, `100000m`, `500000m` tier boundaries. Comment: "AP7: Magic value thresholds for tier assignment."
- `CustomerAttritionScorer` — `3` transactions ("declining"), `100.0` balance ("low"), `40.0`/`75.0` risk level thresholds. Comments: "AP7: Magic threshold."
- `RepeatOverdraftCustomerProcessor` — `2` overdraft count threshold. Comment: "AP7: Magic threshold."
- `SuspiciousWireFlagProcessor` — `"OFFSHORE"` string and `50000` amount. Comment: "AP7: magic values."
- `InvestmentRiskClassifier` — `200000`, `50000` value tiers. Comment: "AP7: Magic values — hardcoded thresholds for risk tier."
- `CustomerComplianceRiskCalculator` — `5000` high-value threshold, `30.0`/`20.0`/`10.0` risk weights.
- `CustomerValueCalculator` — `10.0m`, `50.0m`, `1000m` cap values, `0.4m`/`0.35m`/`0.25m` weights.
- `OverdraftAmountDistributionProcessor` — `50`, `100`, `250`, `500` bucket boundaries.
- `CardExpirationWatchProcessor` — `90` days threshold.

**SQL-level magic values:**
- `daily_wire_volume` — hardcoded `'2024-10-01'` and `'2024-12-31'` in SQL.
- `monthly_transaction_trend` — hardcoded `'2024-10-01'` in SQL WHERE.
- `top_branches` — hardcoded `'2024-10-01'` in SQL WHERE.
- `FundAllocationWriter` — hardcoded trailer date `"2024-10-01"` (W8 pattern).

**Verdict: SUFFICIENT.** Widespread across External modules. 15-20 jobs have clear magic values. An agent will find plenty.

---

### AP8 — Complex/Dead SQL
**Coverage: THIN (5-8 jobs)**

Unused CTEs, redundant subqueries, unnecessary window functions.

**Identified instances:**
- `transaction_size_buckets` — Three CTEs (`txn_detail`, `bucketed`, `summary`). The `txn_detail` CTE adds `ROW_NUMBER()` that is never used in the downstream CTEs. Dead window function.
- `preference_change_count` — CTE `all_prefs` adds `RANK()` window function that is never referenced in the `summary` CTE.
- `branch_visit_purpose_breakdown` — CTE `purpose_counts` computes `SUM(COUNT(*)) OVER (...)` window function (`total_branch_visits`) but the final SELECT never outputs it. Dead computed column.
- `daily_transaction_summary` — Unnecessary subquery wrapper: `SELECT ... FROM (SELECT ... GROUP BY ...) sub ORDER BY ...`. The subquery adds no filtering or transformation — the outer SELECT just passes through all columns. Also: `total_amount` is computed as `SUM(debit) + SUM(credit)` which is redundant with just `SUM(amount)`.
- `compliance_resolution_time` — CTE with `ROW_NUMBER()` that is never used in the final aggregation.
- `product_penetration` — Overly complex: 5 CTEs, UNION ALL, cross-join to customers just to get `ifw_effective_date`, `LIMIT 3`.
- `customer_address_history` — Unnecessary subquery wrapper around a simple SELECT.

**SQL integer division (W4, related to dead complexity):**
- `email_opt_in_rate`, `sms_opt_in_rate`, `product_penetration`, `compliance_resolution_time`, `card_authorization_summary` — All use `CAST(... AS INTEGER) / CAST(... AS INTEGER)` which truncates to 0 for rates < 1. This isn't dead SQL, but it's bad SQL that produces wrong-looking results.

**Verdict: THIN.** There are 5-8 instances of genuinely dead SQL elements (unused window functions, unnecessary subqueries, dead CTE columns). The integer division issues add badness but aren't strictly AP8. A reverse engineering agent will find some material, but this is one of the weaker anti-patterns.

**Suggestion if more needed:** Add unused CTEs to 3-4 more SQL transformation jobs. For example, add a CTE that computes a moving average or running total that's never used in the final SELECT.

---

### AP9 — Misleading Names
**Coverage: THIN (3-5 jobs)**

Names that contradict what the code actually does.

**Identified instances:**
- `quarterly_executive_kpis` — Named "quarterly" but produces daily KPIs. The `QuarterlyExecutiveKpiBuilder` code comment confirms: "AP9: Misleading name — 'quarterly' but actually produces daily KPIs."
- `monthly_transaction_trend` — Named "monthly" but the SQL outputs daily rows (`GROUP BY ifw_effective_date`).
- `branch_transaction_volume` — Named "branch transaction volume" but the SQL groups by `account_id` — there's no branch in the output at all. Branches are sourced but never used. The name implies branch-level aggregation.
- `credit_score_snapshot` — Named "snapshot" but `CreditScoreProcessor` is a pure pass-through that just copies rows. No snapshot logic.
- `account_balance_snapshot` — Named "snapshot" but `AccountSnapshotBuilder` is also a pure pass-through.

**Verdict: THIN.** The quarterly/monthly naming mismatches are clear wins. The "snapshot" misnomers are milder. 3-5 instances total. A reverse engineering agent will spot the date-granularity mismatches quickly.

**Suggestion if more needed:** Rename some resultName values in configs to be misleading — e.g., a DataSourcing with `resultName: "active_accounts"` that sources ALL accounts (no filter). Or an External module named "Calculator" that does no calculation, just passes through data.

---

### AP10 — Over-Sourcing Date Ranges
**Coverage: THIN (3-5 jobs)**

Broad date ranges sourced through config, then filtered down in processing.

**Confirmed instances via config static dates + External filtering:**
- `fee_revenue_daily` — Config sources overdraft_events with `minEffectiveDate: "2024-10-01"` / `maxEffectiveDate: "2024-12-31"` (full quarter). `FeeRevenueDailyProcessor` immediately filters: `overdraftEvents.Rows.Where(r => ... d == maxDate)` — uses only today's rows. Comment: "AP10: Over-sourced full date range via config, but External filters to current date only."
- `weekend_transaction_pattern` — Config sources transactions with same static date range. `WeekendTransactionPatternProcessor` filters: `if (asOf != maxDate) continue;` — only uses today. Comment: "AP10: Over-sourced full date range via config."
- `daily_wire_volume` — Config sources wire_transfers with static date range. SQL then adds `WHERE ifw_effective_date >= '2024-10-01' AND ifw_effective_date <= '2024-12-31'` — redundant with the config date range.

**Implicit over-sourcing (default date range pulls all historical data):**
- Most DataSourcing modules without explicit `minEffectiveDate`/`maxEffectiveDate` fall back to `__etlEffectiveDate` which pulls only the current day. This is actually correct behavior, so they're NOT over-sourcing. The 3 static-date jobs are the main AP10 carriers.

**Verdict: THIN.** Only 3 clear instances, all using the same `2024-10-01 / 2024-12-31` pattern. The anti-pattern exists but is concentrated.

**Suggestion if more needed:** Add static date ranges to 3-5 more DataSourcing configs where the External or Transformation only needs one day's data. E.g., `overdraft_by_account_type` could source `overdraft_events` with a full quarter range even though the External only processes the current effective date.

---

## 3. Additional Anti-Patterns (Not in the official 10 but present)

These were catalogued in the config eval and provide extra material for reverse engineering agents:

| Pattern | Jobs | Description |
|---------|------|-------------|
| **Self-writing External (bypasses writer)** | 8 | External modules write directly to `Output/curated/` via `StreamWriter`, bypassing date partitioning, `etl_effective_date` injection, and framework write modes. |
| **Inflated trailer counts (W7)** | 7 | Self-writing modules use input row count instead of output row count in TRAILER lines. |
| **Header re-emission on append (W12)** | 1 | `AccountVelocityTracker` re-emits CSV header on every append. |
| **Stale trailer date (W8)** | 1 | `FundAllocationWriter` hardcodes `2024-10-01` in trailer instead of current date. |
| **Integer division (W4)** | 7 | Both SQL (5 jobs) and C# (2 jobs — `OverdraftRecoveryRateProcessor`, `DebitCreditRatioCalculator`) use integer division producing truncated results. |
| **Banker's rounding (W5)** | 8+ | `MidpointRounding.ToEven` instead of `MidpointRounding.AwayFromZero`. |
| **Double epsilon (W6)** | 5+ | `double` instead of `decimal` for financial calculations — `FeeRevenueDailyProcessor`, `CustomerAttritionScorer`, `DebitCreditRatioCalculator`, `CardTypeDistributionProcessor`, `CustomerComplianceRiskCalculator`. |
| **Excessive numParts** | 4 | Parquet writers with `numParts: 50` for small datasets. |
| **Direct DB access (bypasses DataSourcing)** | 2 | `CoveredTransactionProcessor` and `CustomerAddressDeltaProcessor` use `NpgsqlConnection` directly. |

---

## 4. Distribution Assessment

### By anti-pattern density per job:

| Density Level | Estimated Job Count | Examples |
|---------------|-------------------|----------|
| **3+ anti-patterns** | ~15-20 | `suspicious_wire_flags` (AP1, AP4, AP7), `customer_contactability` (AP1, AP4, AP6), `executive_dashboard` (AP1, AP3, AP6), `quarterly_executive_kpis` (AP2, AP3, AP6, AP9) |
| **2 anti-patterns** | ~25-30 | `high_balance_accounts` (AP3, AP7), `card_fraud_flags` (AP3, AP7), `transaction_size_buckets` (AP1, AP8) |
| **1 anti-pattern** | ~30-35 | Most simple External module jobs (AP3 or AP6 alone) |
| **0 anti-patterns** | ~10-15 | Simple SQL pass-throughs like `branch_directory`, `branch_visit_summary`, `daily_transaction_volume` |

### By carrier job type:

- **External module jobs (71):** Carry the bulk of AP3, AP5, AP6, AP7. These are the primary anti-pattern carriers.
- **SQL Transformation jobs (31):** Carry AP1 (dead-end sourcing), AP4 (unused columns), AP8 (dead SQL), AP10 (over-sourcing). Also carry AP7 via hardcoded dates and integer division.
- **Self-writing External jobs (8):** Carry unique anti-patterns (W7, W8, W12) plus AP3.

### Spread vs. concentration:

The distribution is **reasonably spread.** AP6 is everywhere (inherent to External modules). AP7 is well-distributed across 15-20 jobs. AP1 and AP4 span both SQL and External jobs. The concentration risk is in AP2, AP5, AP9, and AP10 — each has fewer than 5 clear instances, making them potentially harder for an agent to discover.

---

## 5. Jobs That Are Suspiciously Clean

These V1 jobs have **zero identified anti-patterns** and could be candidates for dirtying if needed:

| Job | Type | Why It's Clean |
|-----|------|---------------|
| `branch_directory` | SQL | Simple pass-through, 1 DataSourcing, clean SQL. |
| `branch_visit_summary` | SQL | Simple GROUP BY, no dead sources. |
| `daily_transaction_volume` | SQL | Single source, simple aggregation. |
| `preference_trend` | SQL | Single source, simple SQL. |
| `overdraft_fee_summary` | SQL | Single source, clean aggregation. |
| `customer_account_summary` | SQL | Clean SQL with proper JOIN + GROUP BY. |
| `do_not_contact_list` | External | Clean logic, no magic values, proper null handling. |

These 7 jobs are the cleanest. They work fine and produce correct output with minimal code. If the anti-pattern density needs to increase, these are where to add smells.

---

## 6. Overall Verdict

### Is there enough bad code for reverse engineering agents?

**Yes.** The corpus has:
- **~90 jobs with at least one anti-pattern** (out of 102)
- **All 10 official anti-patterns present** in the codebase
- **30-40+ jobs with AP6** (the most common)
- **15-20 jobs each with AP1, AP3, AP4, AP7** (well-distributed)
- **Additional "wrinkle" anti-patterns** (W4-W12) adding depth

### What's at risk of being missed?

| Anti-Pattern | Risk | Mitigation |
|-------------|------|------------|
| AP2 (Duplicated Logic) | Medium — only 3-5 clear pairs | Agent needs cross-job analysis capability |
| AP5 (Asymmetric Nulls) | Medium — only 3-5 jobs | `CrossSellCandidateFinder` is the flagship; rest are subtle |
| AP8 (Dead SQL) | Low-Medium — 5-8 jobs but requires SQL comprehension | Dead window functions are clear signals |
| AP9 (Misleading Names) | Medium — 3-5 jobs, subjective | Quarterly/monthly mismatches are obvious to a human |
| AP10 (Over-Sourcing) | Medium — only 3 jobs, all same pattern | Very concentrated |

### Recommendations (if density increase is desired):

1. **AP2:** Add 2-3 more jobs that duplicate existing computations via different code paths.
2. **AP5:** Add asymmetric null handling to 3-4 External modules that currently handle nulls consistently.
3. **AP8:** Add unused CTEs to 3-4 SQL transformation jobs.
4. **AP9:** Make 2-3 more job names misleading (e.g., rename resultNames or add "daily" to a job that outputs aggregated data).
5. **AP10:** Add static date ranges to 3-5 more DataSourcing configs.

### Bottom line:

The V1 codebase delivers on the mission. These jobs convincingly simulate the output of a junior developer who knows just enough to make things work but not enough to make them good. The anti-pattern distribution ensures that a reverse engineering agent will have material to find no matter which job it picks up first. The thin areas (AP2, AP5, AP9, AP10) are discoverable but will require more sophisticated analysis — which is exactly the kind of challenge we want to present.
