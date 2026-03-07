# FSD: CreditScoreDelta

**Job ID:** 369
**Job Name:** CreditScoreDelta
**BRD Reference:** `POC4/Artifacts/CreditScoreDelta/brd.md`
**Config Reference:** `MockEtlFramework/JobExecutor/Jobs/credit_score_delta.json`

---

## 1. Functional Requirements

### FR1: Customer Scope
**Traces to:** BRD BR1
Only customers 2252, 2581, and 2632 are in scope. This is enforced via `additionalFilter` on both the todays_scores and prior_scores DataSourcing modules: `"customer_id IN (2252, 2581, 2632)"`.

### FR2: Score Comparison — Today vs Most Recent Prior
**Traces to:** BRD BR2
Today's scores are LEFT JOINed to prior scores on `(customer_id, bureau)`:
- Customer/bureau with current score but no prior -> appears with prior_score = NULL
- Customer/bureau with prior score but no current -> excluded (LEFT JOIN from todays_scores)

### FR3: Change Detection Filter
**Traces to:** BRD BR3
Only rows where score changed OR no prior exists: `WHERE p.score IS NULL OR t.score <> p.score`

### FR4: Customer Name Enrichment
**Traces to:** BRD BR4
Customer `sort_name` joined from customers table via `LEFT JOIN customers c ON t.customer_id = c.id`.

### FR5: Output Ordering
**Traces to:** BRD BR5
Results ordered by `customer_id ASC, bureau ASC`.

### FR6: Prior Date Resolution
**Traces to:** BRD BR6
Prior scores use `mostRecentPrior: true` — framework queries `MAX(ifw_effective_date)` strictly BEFORE current effective date. If no prior date exists (first run), prior_scores DataFrame is empty.

### FR7: Failure on Missing Current Data
**Traces to:** BRD BR7
When no credit_scores data exists for the effective date, the todays_scores DataFrame is empty. The framework's Transformation module skips registering tables with no columns (`RegisterTable` returns early). The SQL then fails with `SQLite Error 1: 'no such table: todays_scores'`.

**V4 Design Decision:** This is existing V1 behavior that must be preserved for fidelity. The job FAILS for dates with no credit_scores data (observed: 2024-10-05, 2024-10-06). V4 will reproduce this failure behavior. No graceful handling is added.

---

## 2. Anti-Pattern Analysis

### AP1 — Dead-End Sourcing, Partial (V1)
**Identified in BRD:** Customers table sourced with no `additionalFilter`, loading ALL customers when only 3 are needed.
**V4 Avoidance:** Add `"additionalFilter": "id IN (2252, 2581, 2632)"` to the customers DataSourcing module to match the scope of the credit_scores filters.
**Fidelity Impact:** None — the LEFT JOIN only matches 3 customer_ids regardless. Reducing the sourced data does not change the output.

### AP7 — Magic Values (V1)
**Identified in BRD:** Hardcoded customer_id filter `IN (2252, 2581, 2632)`.
**V4 Avoidance:** This cannot be eliminated without changing the business requirement. The filter IS the business rule (these are the monitored customers). V4 preserves the filter but documents it in the FSD and config. If parameterization were desired, the framework would need a config-level variable system, which is out of scope for POC4.

### AP10 — Over-Sourcing Date Ranges, Partial (V1)
**Identified in BRD:** Customers table sourced with `mostRecent: true` (all customers) when only 3 are needed.
**V4 Avoidance:** Same fix as AP1 — add `additionalFilter` to customers DataSourcing.
**Fidelity Impact:** None.

---

## 3. Output DataFrames

### Output 1: credit_score_delta.csv

| Column | Type | Source | Transformation | BRD Reference |
|--------|------|--------|----------------|---------------|
| customer_id | int | credit_scores.customer_id | Direct from todays_scores | BR1 |
| sort_name | string | customers.sort_name | LEFT JOIN on customer_id = id | BR4 |
| bureau | string | credit_scores.bureau | Direct from todays_scores | BR2 |
| current_score | int/numeric | credit_scores.score (today) | Aliased from t.score | BR2 |
| prior_score | int/numeric/null | credit_scores.score (prior) | Aliased from p.score; NULL if no prior | BR2, BR3 |
| etl_effective_date | string (yyyy-MM-dd) | Framework injected | CsvFileWriter auto-injection | N/A |

---

## 4. Module Chain Design

### Preferred: DataSourcing -> DataSourcing -> DataSourcing -> Transformation -> CsvFileWriter

This is the EXISTING V1 module chain. CreditScoreDelta already uses the preferred pattern (SQL Transformation + CsvFileWriter, no External module). The V4 changes are config-level anti-pattern fixes only.

1. **DataSourcing** — Source `credit_scores` as `todays_scores`. Columns: `customer_id`, `bureau`, `score`. Single-day filter. additionalFilter: `customer_id IN (2252, 2581, 2632)`.
2. **DataSourcing** — Source `credit_scores` as `prior_scores`. Columns: `customer_id`, `bureau`, `score`. `mostRecentPrior: true`. additionalFilter: `customer_id IN (2252, 2581, 2632)`.
3. **DataSourcing** — Source `customers` as `customers`. Columns: `id`, `sort_name`. `mostRecent: true`. **V4 addition:** `additionalFilter: "id IN (2252, 2581, 2632)"`.
4. **Transformation** — SQL (unchanged from V1):
   ```sql
   SELECT t.customer_id, c.sort_name, t.bureau, t.score AS current_score, p.score AS prior_score
   FROM todays_scores t
   LEFT JOIN prior_scores p ON t.customer_id = p.customer_id AND t.bureau = p.bureau
   LEFT JOIN customers c ON t.customer_id = c.id
   WHERE p.score IS NULL OR t.score <> p.score
   ORDER BY t.customer_id, t.bureau
   ```
   Result name: `credit_score_deltas`
5. **CsvFileWriter** — Write `credit_score_deltas` with writeMode "Overwrite".

**No External Module.** V1 already uses the correct pattern. V4 preserves it.

---

## 5. Open Questions

1. **Failure behavior on missing data (Oct 5-6):** V1 fails with SQLite error. V4 will reproduce this. The framework's T-N hard failure mechanism (implemented in Step 7) may or may not interact with this. If DataSourcing returns an empty DataFrame for todays_scores and the Transformation fails, the job should fail in the task queue — same as V1. Need to verify that the Step 7 T-N hard failure doesn't preempt the SQLite error with a different failure mode.

2. **NULL rendering in CSV:** V1 renders NULL prior_score as empty string in CSV (RFC 4180). V4's CsvFileWriter should do the same (it uses `FormatField` which handles nulls). Verify during testing.
