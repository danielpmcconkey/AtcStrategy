# BRD: CreditScoreDelta

**Job ID:** 369
**Job Name:** CreditScoreDelta
**Config:** `MockEtlFramework/JobExecutor/Jobs/credit_score_delta.json`
**First Effective Date:** 2024-10-01

---

## 1. Overview

CreditScoreDelta identifies credit score changes for a specific set of customers across three credit bureaus. It compares today's scores against the most recent prior scores and outputs only records where a change occurred (or where no prior score exists). The output is a daily CSV showing current vs. prior scores per customer/bureau combination.

**Business Purpose:** Monitor credit score movement for targeted customers, enabling early detection of credit deterioration or improvement.

---

## 2. Source Tables

### 2.1 datalake.credit_scores (resultName: "todays_scores")
- **Columns sourced:** customer_id, bureau, score
- **Date filter:** ifw_effective_date = __etlEffectiveDate (single day)
- **Additional filter:** `customer_id IN (2252, 2581, 2632)`
- **Evidence:** Job config modules[0]

### 2.2 datalake.credit_scores (resultName: "prior_scores")
- **Columns sourced:** customer_id, bureau, score
- **Date filter:** `mostRecentPrior: true` — queries for MAX(ifw_effective_date) strictly BEFORE __etlEffectiveDate
- **Additional filter:** `customer_id IN (2252, 2581, 2632)`
- **Evidence:** Job config modules[1]; DataSourcing.cs lines 109-113 — `QueryMostRecentDate(t0, strict: true)`

### 2.3 datalake.customers (resultName: "customers")
- **Columns sourced:** id, sort_name
- **Date filter:** `mostRecent: true` — queries for MAX(ifw_effective_date) on or before __etlEffectiveDate
- **Additional filters:** None (loads ALL customers, not just the 3 targeted ones)
- **Evidence:** Job config modules[2]; DataSourcing.cs lines 117-121

---

## 3. Business Rules

### BR1: Customer Scope
Only customers 2252, 2581, and 2632 are in scope. This is enforced via `additionalFilter` on both score sourcing steps.
- **Confidence:** HIGH
- **Evidence:** Job config modules[0] and modules[1] — `"additionalFilter": "customer_id IN (2252, 2581, 2632)"`

### BR2: Score Comparison — Today vs Most Recent Prior
Today's scores are LEFT JOINed to prior scores on (customer_id, bureau). This means:
- If a customer/bureau has a current score but no prior, it appears with prior_score = NULL
- If a customer/bureau has a prior score but no current, it is excluded
- **Confidence:** HIGH
- **Evidence:** Job config modules[3] SQL — `FROM todays_scores t LEFT JOIN prior_scores p ON t.customer_id = p.customer_id AND t.bureau = p.bureau`

### BR3: Change Detection Filter
Only rows where the score changed OR where no prior score exists are included:
`WHERE p.score IS NULL OR t.score <> p.score`
- **Confidence:** HIGH
- **Evidence:** Job config modules[3] SQL WHERE clause

### BR4: Customer Name Enrichment
Customer sort_name is joined from the customers table via `t.customer_id = c.id` using LEFT JOIN.
- **Confidence:** HIGH
- **Evidence:** Job config modules[3] SQL — `LEFT JOIN customers c ON t.customer_id = c.id`

### BR5: Output Ordering
Results ordered by customer_id ASC, then bureau ASC.
- **Confidence:** HIGH
- **Evidence:** Job config modules[3] SQL — `ORDER BY t.customer_id, t.bureau`

### BR6: Prior Date Resolution
The "most recent prior" date is determined by the framework's DataSourcing module querying `MAX(ifw_effective_date) FROM credit_scores WHERE ifw_effective_date < __etlEffectiveDate`. If no prior date exists (first run), the prior_scores DataFrame is empty.
- **Confidence:** HIGH
- **Evidence:** DataSourcing.cs lines 150-170 — `QueryMostRecentDate` with `strict: true`

### BR7: Failure on Missing Current Data
When no credit_scores data exists for the effective date (and thus no `todays_scores` table can be registered in SQLite), the Transformation module throws `SQLite Error 1: 'no such table: todays_scores'`. This causes the job to fail entirely.
- **Confidence:** HIGH
- **Evidence:** Task queue failures for 2024-10-05 and 2024-10-06 — `SQLite Error 1: 'no such table: todays_scores'`; DataSourcing.cs returns empty DataFrame when `mostRecentPrior` finds no date, but for default mode (modules[0]) it returns empty DataFrame with no rows, and Transformation.cs `RegisterTable` skips tables with no columns (line 46: `if (!df.Columns.Any()) return`)

---

## 4. Output Schema

| Column | Type | Source | Transformation |
|--------|------|--------|----------------|
| customer_id | int | datalake.credit_scores.customer_id | Direct from todays_scores |
| sort_name | string | datalake.customers.sort_name | LEFT JOIN on customer_id = id |
| bureau | string | datalake.credit_scores.bureau | Direct from todays_scores |
| current_score | int/numeric | datalake.credit_scores.score (today) | Aliased from t.score |
| prior_score | int/numeric/null | datalake.credit_scores.score (prior) | Aliased from p.score; NULL if no prior |
| etl_effective_date | string (yyyy-MM-dd) | Framework injected | CsvFileWriter adds automatically |

---

## 5. Anti-Patterns Identified

### AP1 — Dead-End Sourcing (Partial)
The `customers` table is sourced with `mostRecent: true` and NO customer_id filter. This loads ALL customers' sort_names into memory, but only 3 customer_ids will ever match in the JOIN. The filter should be applied at the sourcing level.
- **Evidence:** Job config modules[2] — no additionalFilter; only customer_ids 2252, 2581, 2632 from todays_scores will ever match

### AP7 — Magic Values
The customer_id filter `IN (2252, 2581, 2632)` is hardcoded in the job config with no parameterization or documentation explaining why these three customers are monitored.
- **Evidence:** Job config modules[0] and modules[1] additionalFilter

### AP10 — Over-Sourcing Date Ranges (Partial)
The customers table is sourced with `mostRecent: true` which loads the entire latest snapshot of all customers. Since only 3 customer_ids are needed, this sources far more data than necessary.
- **Evidence:** Job config modules[2] — `mostRecent: true` with no additionalFilter

---

## 6. Edge Cases

1. **No credit scores for effective date:** Job FAILS with SQLite error (todays_scores table not registered). Observed for Oct 5-6. This is NOT a graceful failure — the framework doesn't handle the "empty DataFrame not registered as table" case well.
2. **No prior scores (first run):** prior_scores is empty. All current scores appear with prior_score = NULL (they pass the `p.score IS NULL` filter).
3. **Score unchanged:** Row is excluded by `t.score <> p.score` filter. If all scores for all 3 customers are unchanged, output is header-only.
4. **Customer not in customers table:** sort_name will be NULL due to LEFT JOIN.
5. **Multiple bureaus per customer:** Each bureau is a separate row (3 customers x 3 bureaus = up to 9 rows per day).

---

## 7. Traceability Matrix

| Business Rule | Source Code Reference | Config Reference | Output Evidence |
|---------------|----------------------|------------------|-----------------|
| BR1: Customer Scope | N/A | Config modules[0,1] additionalFilter | Output only shows customer_ids 2252, 2581, 2632 |
| BR2: Today vs Prior | Transformation.cs (SQL execution) | Config modules[3] SQL | current_score and prior_score columns |
| BR3: Change Detection | Transformation.cs | Config modules[3] SQL WHERE | Oct 1 shows NULL prior (first run); Oct 2+ shows changes |
| BR4: Name Enrichment | Transformation.cs | Config modules[3] SQL JOIN | sort_name populated (e.g., "Reyes Gabriel") |
| BR5: Output Ordering | Transformation.cs | Config modules[3] SQL ORDER BY | Rows sorted by customer_id, bureau |
| BR6: Prior Date Resolution | DataSourcing.cs:109-113,150-170 | Config modules[1] mostRecentPrior | prior_score NULL on Oct 1, populated Oct 2+ |
| BR7: Missing Data Failure | Transformation.cs:55-56, DataSourcing.cs | Config modules[0] | Failed tasks for Oct 5-6 in task_queue |
