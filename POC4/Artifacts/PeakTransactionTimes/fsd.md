# FSD: PeakTransactionTimes

**Job ID:** 165
**Job Name:** PeakTransactionTimes
**BRD Reference:** `POC4/Artifacts/PeakTransactionTimes/brd.md`
**Config Reference:** `MockEtlFramework/JobExecutor/Jobs/peak_transaction_times.json`

---

## 1. Functional Requirements

### FR1: Hourly Transaction Aggregation
**Traces to:** BRD BR1
Group all transactions by the hour component (0-23) extracted from `txn_timestamp`. For each hour bucket, compute:
- `txn_count` = COUNT of transactions in that hour
- `total_amount` = SUM of `amount` values in that hour

### FR2: Total Amount Rounding
**Traces to:** BRD BR2
Round `total_amount` to 2 decimal places. The V1 code uses `Math.Round` (banker's rounding / MidpointRounding.ToEven). The V4 SQL implementation must reproduce this behavior. SQLite's `ROUND()` function uses standard rounding (half-away-from-zero), which may differ for values exactly at the midpoint (e.g., 2.5). Evidence from observed V1 output should be checked to determine whether any midpoint values actually occur; if not, `ROUND(SUM(amount), 2)` is functionally equivalent.

### FR3: Output Ordering
**Traces to:** BRD BR3
Output rows ordered by `hour_of_day` ASC.

### FR4: Effective Date Stamping
**Traces to:** BRD BR4
Each output row includes `ifw_effective_date` as a string formatted `yyyy-MM-dd`, sourced from the framework's `__etlEffectiveDate` shared state value.

**V4 Design Note:** In the V4 SQL Transformation approach, `ifw_effective_date` is available as a column on the sourced `transactions` DataFrame (the framework injects it during DataSourcing). The SQL can reference it directly. However, the V1 code formats it from the shared state DateOnly, producing `yyyy-MM-dd`. The framework's DataSourcing injects `ifw_effective_date` as a DateOnly object, and its string representation in SQLite depends on how the framework registers it. The Transformation SQL should use an explicit date formatting function or the output should be verified against V1 to ensure format parity.

### FR5: Trailer Record
**Traces to:** BRD BR5
A trailer line in format `TRAILER|{count}|{date}` where:
- `count` = number of INPUT transaction rows (pre-aggregation), NOT the number of output rows
- `date` = effective date formatted as `yyyy-MM-dd`

**V4 Design Note:** The framework's CsvFileWriter supports `trailerFormat` with `{row_count}` and `{date}` placeholders. However, `{row_count}` in the framework refers to the OUTPUT DataFrame row count (post-aggregation hourly buckets). The V1 behavior writes the INPUT count (e.g., 4284 transactions -> TRAILER|4284, not TRAILER|19 for 19 hourly buckets). This is a critical fidelity requirement: the V4 design must reproduce the INPUT count in the trailer. This requires either:
- (a) An External module that can pass the input count to the trailer, or
- (b) A framework enhancement to support input-count trailers, or
- (c) Accepting this as a known deviation and documenting it

**Resolution:** Since the trailer count is the INPUT row count and the framework's `{row_count}` placeholder uses the OUTPUT row count, an External module is justified for this job to handle the trailer correctly. This is NOT an AP3 violation -- the External module is required specifically because of the trailer count semantics, not because the aggregation logic needs C#. The aggregation itself should still be done in SQL within the External module or via a Transformation step that feeds into the External module's trailer-writing logic.

**Alternative approach:** Use a two-step pipeline: (1) SQL Transformation for the aggregation, (2) External module that reads the aggregated output AND the original transactions count to write the file with the correct trailer. This keeps the aggregation in SQL (eliminating AP6) while handling the trailer requirement.

### FR6: Direct File Write
**Traces to:** BRD BR6
V1 writes directly to `Output/curated/peak_transaction_times.csv` bypassing the framework. V4 should use the framework's CsvFileWriter with date-partitioned output at `Output/double_secret_curated/peak_transaction_times/peak_transaction_times/{etl_effective_date}/peak_transaction_times.csv`. The move from direct write to framework writer is a design improvement, not a fidelity concern -- the DATA content must match, not the file path.

### FR7: Empty DataFrame to Framework
**Traces to:** BRD BR7
V1 returns an empty DataFrame to the framework after writing directly. In V4, the framework writer handles the output, so this behavior is eliminated. The framework receives the actual aggregated data.

### FR8: Timestamp Parsing Fallback
**Traces to:** BRD BR8
If `txn_timestamp` cannot be parsed as a DateTime, the hour defaults to 0. In V4 SQL, `strftime('%H', txn_timestamp)` handles standard ISO format timestamps. If non-parseable timestamps exist in the data, they would produce NULL from strftime, and COALESCE to 0 can replicate the fallback behavior.

### FR9: Empty Input Handling
**Traces to:** BRD BR9
When no transactions exist for the effective date, produce a CSV with header only plus `TRAILER|0|{date}`.

---

## 2. Anti-Pattern Analysis

### AP1 — Dead-End Sourcing (V1)
**Identified in BRD:** The `accounts` DataFrame is sourced but never referenced.
**V4 Avoidance:** Remove the `accounts` DataSourcing module entirely from the job config. Only source `transactions`.
**Fidelity Impact:** None -- accounts data has zero influence on V1 output.

### AP3 — Unnecessary External Module (V1, partially retained in V4)
**Identified in BRD:** The aggregation logic is a straightforward GROUP BY.
**V4 Avoidance:** Move the aggregation to a SQL Transformation. However, an External module is still justified for the trailer-writing logic (see FR5 above). The V4 External module is minimal -- it reads the aggregated DataFrame and the input transaction count, then writes the CSV with the correct trailer.
**Evidence of alternative achieving same output:** SQL `SELECT strftime('%H', txn_timestamp) AS hour_of_day, COUNT(*) AS txn_count, ROUND(SUM(amount), 2) AS total_amount FROM transactions GROUP BY strftime('%H', txn_timestamp) ORDER BY hour_of_day` produces identical hourly aggregation.

### AP4 — Unused Columns (V1)
**Identified in BRD:** `transaction_id`, `account_id`, `txn_type`, `description` from transactions are sourced but unused.
**V4 Avoidance:** Source only `txn_timestamp` and `amount` from transactions (plus `ifw_effective_date` if needed for date stamping).
**Fidelity Impact:** None -- unused columns don't affect output.

### AP6 — Row-by-Row Iteration (V1)
**Identified in BRD:** foreach loop with manual dictionary accumulation.
**V4 Avoidance:** SQL GROUP BY in Transformation module.
**Evidence of alternative achieving same output:** The SQL GROUP BY produces identical aggregation results.

### AP7 — Magic Values (V1)
**Identified in BRD:** Hardcoded output path.
**V4 Avoidance:** Output path configured via CsvFileWriter module in job config (or External module config). The framework's date-partitioned output path is deterministic from config.

---

## 3. Output DataFrames

### Output 1: peak_transaction_times.csv

| Column | Type | Source | Transformation | BRD Reference |
|--------|------|--------|----------------|---------------|
| hour_of_day | int | transactions.txn_timestamp | strftime('%H', txn_timestamp) cast to int | BR1 |
| txn_count | int | Computed | COUNT(*) per hour group | BR1 |
| total_amount | decimal (2dp) | transactions.amount | ROUND(SUM(amount), 2) per hour group | BR1, BR2 |
| ifw_effective_date | string (yyyy-MM-dd) | __etlEffectiveDate | Formatted from effective date | BR4 |

**Trailer:** `TRAILER|{input_transaction_count}|{effective_date_yyyy-MM-dd}` (BR5)

---

## 4. Module Chain Design

### Preferred: DataSourcing -> Transformation -> External (Justified)

1. **DataSourcing** — Source `transactions` table with columns `txn_timestamp`, `amount` only. Single-day filter on `ifw_effective_date`.
2. **Transformation** — SQL aggregation:
   ```sql
   SELECT CAST(strftime('%H', txn_timestamp) AS INTEGER) AS hour_of_day,
          COUNT(*) AS txn_count,
          ROUND(SUM(amount), 2) AS total_amount
   FROM transactions
   GROUP BY strftime('%H', txn_timestamp)
   ORDER BY hour_of_day
   ```
   Result name: `hourly_aggregation`
3. **External** — PeakTransactionTimesWriterV4: Reads `hourly_aggregation` DataFrame and `transactions` DataFrame (for input count). Adds `ifw_effective_date` column. Writes CSV with header, data rows, and `TRAILER|{transactions.Count}|{date}` line.

**External Module Justification:** The framework's CsvFileWriter `{row_count}` placeholder produces the OUTPUT row count (number of hourly buckets, typically ~19). The V1 trailer uses the INPUT transaction count (e.g., 4284). No framework mechanism exists to inject an arbitrary count into the trailer. An External module is the only way to achieve trailer fidelity without a framework change. This is a narrow, well-justified use of External -- the business logic (aggregation) remains in SQL.

### Alternative Considered: DataSourcing -> Transformation -> CsvFileWriter
Rejected because `{row_count}` in trailer would produce the wrong count (output rows vs input rows). Would require a framework enhancement to support `{input_row_count}` or similar.

---

## 5. Open Questions

1. **Banker's rounding vs standard rounding:** V1 uses `Math.Round(x, 2)` which defaults to MidpointRounding.ToEven. SQLite ROUND uses half-away-from-zero. Need to verify whether any actual data produces midpoint values where these differ. If yes, the External module may need to handle rounding explicitly.

2. **Timestamp parsing edge cases:** V1 has a fallback chain (DateTime cast -> TryParse -> default hour 0). In practice, are there any non-standard timestamps in the datalake? If all timestamps are ISO format, `strftime('%H', txn_timestamp)` handles them correctly and the fallback is moot.

3. **ifw_effective_date format in SQL:** The framework injects `ifw_effective_date` as a DateOnly during DataSourcing. When registered in SQLite, its string representation needs verification. The External module can format it explicitly from `__etlEffectiveDate`.
