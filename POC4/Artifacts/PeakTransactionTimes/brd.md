# BRD: PeakTransactionTimes

**Job ID:** 165
**Job Name:** PeakTransactionTimes
**Config:** `MockEtlFramework/JobExecutor/Jobs/peak_transaction_times.json`
**First Effective Date:** 2024-10-01

---

## 1. Overview

PeakTransactionTimes aggregates daily transaction data by hour-of-day, producing a summary of transaction counts and total amounts per hour. The output is a single CSV file with a trailer line showing record count and date.

**Business Purpose:** Identify peak transaction hours for operational planning and capacity analysis.

---

## 2. Source Tables

### 2.1 datalake.transactions (resultName: "transactions")
- **Columns sourced:** transaction_id, account_id, txn_timestamp, txn_type, amount, description
- **Date filter:** ifw_effective_date = __etlEffectiveDate (single day)
- **Additional filters:** None
- **Evidence:** Job config modules[0]; DataSourcing.cs default behavior when no date mode flags set

### 2.2 datalake.accounts (resultName: "accounts")
- **Columns sourced:** account_id, customer_id, account_type, interest_rate
- **Date filter:** ifw_effective_date = __etlEffectiveDate (single day)
- **Additional filters:** None
- **Evidence:** Job config modules[1]

---

## 3. Business Rules

### BR1: Hourly Aggregation
Transactions are grouped by the hour component of `txn_timestamp`. For each hour bucket, the job counts the number of transactions (`txn_count`) and sums the `amount` field (`total_amount`).
- **Confidence:** HIGH
- **Evidence:** PeakTransactionTimesWriter.cs lines 31-46 — foreach loop over transactions, extracting hour from txn_timestamp, accumulating count and decimal sum per hour

### BR2: Total Amount Rounding
The `total_amount` for each hour is rounded to 2 decimal places using `Math.Round`.
- **Confidence:** HIGH
- **Evidence:** PeakTransactionTimesWriter.cs line 53 — `Math.Round(kvp.Value.total, 2)`

### BR3: Output Ordering
Output rows are ordered by `hour_of_day` ascending.
- **Confidence:** HIGH
- **Evidence:** PeakTransactionTimesWriter.cs line 49 — `hourlyGroups.OrderBy(k => k.Key)`

### BR4: Effective Date Stamping
Each output row is stamped with the effective date (as string "yyyy-MM-dd") from `__etlEffectiveDate`.
- **Confidence:** HIGH
- **Evidence:** PeakTransactionTimesWriter.cs lines 27-28 — `maxDate.ToString("yyyy-MM-dd")`

### BR5: Trailer Record
A trailer line is appended in the format `TRAILER|{count}|{date}`. The count is the number of INPUT transaction rows (pre-aggregation), NOT the number of output rows.
- **Confidence:** HIGH
- **Evidence:** PeakTransactionTimesWriter.cs lines 24, 61, 90 — `inputCount = transactions.Count`, then passed to WriteDirectCsv, trailer uses inputCount

### BR6: Direct File Write (Bypasses Framework Writer)
The External module writes directly to `Output/curated/peak_transaction_times.csv` using `StreamWriter`, bypassing the framework's CsvFileWriter entirely. The file is overwritten on each run (no date partitioning).
- **Confidence:** HIGH
- **Evidence:** PeakTransactionTimesWriter.cs lines 69-70 — hardcoded path; line 76 — `append: false`

### BR7: Empty DataFrame Returned to Framework
After writing the CSV directly, the module sets `sharedState["output"]` to an EMPTY DataFrame. The framework receives no rows to process further.
- **Confidence:** HIGH
- **Evidence:** PeakTransactionTimesWriter.cs line 63 — `new DataFrame(new List<Row>(), outputColumns)`

### BR8: Timestamp Parsing Fallback
If `txn_timestamp` is not a `DateTime`, the code attempts `DateTime.TryParse`. If parsing fails, hour defaults to 0.
- **Confidence:** HIGH
- **Evidence:** PeakTransactionTimesWriter.cs lines 35-39 — fallback chain: DateTime cast, then TryParse, else hour = 0

### BR9: Empty Input Handling
When transactions DataFrame is null or empty, the job writes a CSV with header only plus a `TRAILER|0|{date}` line.
- **Confidence:** HIGH
- **Evidence:** PeakTransactionTimesWriter.cs lines 16-21

---

## 4. Output Schema

| Column | Type | Source | Transformation |
|--------|------|--------|----------------|
| hour_of_day | int | txn_timestamp from datalake.transactions | Extract hour component (0-23) |
| txn_count | int | Computed | Count of transactions in that hour bucket |
| total_amount | decimal | amount from datalake.transactions | Sum of amounts per hour, rounded to 2 decimals |
| ifw_effective_date | string | __etlEffectiveDate from shared state | Formatted as yyyy-MM-dd |

**Trailer row:** `TRAILER|{input_row_count}|{effective_date_yyyy-MM-dd}`

---

## 5. Anti-Patterns Identified

### AP1 — Dead-End Sourcing
The `accounts` DataFrame is sourced (account_id, customer_id, account_type, interest_rate) but NEVER referenced anywhere in the External module. The code only reads `sharedState["transactions"]`. The entire accounts sourcing step is wasted I/O.
- **Evidence:** PeakTransactionTimesWriter.cs — no reference to "accounts" key; only "transactions" is accessed (line 15)

### AP3 — Unnecessary External Module
The entire aggregation logic (GROUP BY hour, SUM, COUNT) could be expressed as a SQL Transformation + CsvFileWriter. There is no imperative logic here that requires C# — it's a straightforward GROUP BY. The External module also bypasses framework features (date partitioning, etl_effective_date injection, trailer format).
- **Evidence:** The SQL equivalent would be: `SELECT EXTRACT(HOUR FROM txn_timestamp) as hour_of_day, COUNT(*) as txn_count, ROUND(SUM(amount), 2) as total_amount FROM transactions GROUP BY EXTRACT(HOUR FROM txn_timestamp) ORDER BY hour_of_day`

### AP4 — Unused Columns
From `transactions`: `transaction_id`, `account_id`, `txn_type`, `description` are sourced but never used in the output. Only `txn_timestamp` and `amount` are actually referenced.
From `accounts`: ALL columns are unused (see AP1 above).
- **Evidence:** PeakTransactionTimesWriter.cs — only `row["txn_timestamp"]` (line 33) and `row["amount"]` (line 45) are accessed

### AP6 — Row-by-Row Iteration
The External module uses a `foreach` loop to iterate through every transaction row, manually building a dictionary of hourly aggregates. This is a textbook case where a SQL `GROUP BY` would be cleaner and faster.
- **Evidence:** PeakTransactionTimesWriter.cs lines 31-46 — foreach loop with manual dictionary accumulation

### AP7 — Magic Values
The output path `"Output/curated/peak_transaction_times.csv"` is hardcoded in the External module rather than being configurable via the job config.
- **Evidence:** PeakTransactionTimesWriter.cs line 70 — hardcoded path string

---

## 6. Edge Cases

1. **No transactions for a date:** Handled — writes header + TRAILER|0|{date}
2. **Timestamp parsing failure:** Hour defaults to 0, silently bucketing unparseable timestamps into hour 0
3. **File overwrite on multi-date runs:** Each run overwrites the single output file. When processing Oct 1-7 sequentially, only the last date's data survives. Historical data is lost.
4. **Trailer count mismatch:** Trailer reports INPUT row count (e.g., 4284 transactions) but the file contains far fewer OUTPUT rows (e.g., 19 hourly buckets). This is misleading for downstream consumers expecting trailer count to match data row count.
5. **Decimal precision in amounts:** Uses `decimal` arithmetic for totals (appropriate), but `Math.Round(total, 2)` could exhibit banker's rounding (MidpointRounding.ToEven) which may differ from what downstream consumers expect.

---

## 7. Traceability Matrix

| Business Rule | Source Code Reference | Config Reference | Output Evidence |
|---------------|----------------------|------------------|-----------------|
| BR1: Hourly Aggregation | PeakTransactionTimesWriter.cs:31-46 | N/A (logic in C#) | Output rows grouped by hour_of_day (0-18 in sample) |
| BR2: Amount Rounding | PeakTransactionTimesWriter.cs:53 | N/A | total_amount values show 2 decimal places |
| BR3: Output Ordering | PeakTransactionTimesWriter.cs:49 | N/A | Rows ordered 0, 1, 2, ... in output |
| BR4: Date Stamping | PeakTransactionTimesWriter.cs:27-28 | N/A | ifw_effective_date column matches run date |
| BR5: Trailer Record | PeakTransactionTimesWriter.cs:24,61,90 | N/A | TRAILER\|4284\|2024-10-06 in output |
| BR6: Direct File Write | PeakTransactionTimesWriter.cs:69-76 | N/A | File at Output/curated/ not Output/poc4/ |
| BR7: Empty DataFrame | PeakTransactionTimesWriter.cs:63 | N/A | Framework receives 0 rows |
| BR8: Timestamp Fallback | PeakTransactionTimesWriter.cs:35-39 | N/A | Default hour=0 for parse failures |
| BR9: Empty Input | PeakTransactionTimesWriter.cs:16-21 | N/A | Header-only file with TRAILER\|0 |
