# Test Strategy: PeakTransactionTimes

**Job ID:** 165
**Job Name:** PeakTransactionTimes
**FSD Reference:** `POC4/Artifacts/PeakTransactionTimes/fsd.md`
**BRD Reference:** `POC4/Artifacts/PeakTransactionTimes/brd.md`

---

## 1. Test Cases

### TC1: Hourly Aggregation Correctness
**Traces to:** BRD BR1, FSD FR1
**Description:** Verify that transactions are correctly grouped by hour and that txn_count and total_amount are accurately computed for each hour bucket.
**Method:** Run V4 job for a representative effective date (e.g., 2024-10-01). Compare output hour_of_day values, txn_count per hour, and total_amount per hour against V1 output. Use Proofmark STRICT comparison on the data rows (excluding trailer).
**Expected Result:** Identical hourly buckets with identical counts and amounts.

### TC2: Total Amount Rounding
**Traces to:** BRD BR2, FSD FR2
**Description:** Verify that total_amount values are rounded to exactly 2 decimal places and match V1 output.
**Method:** Compare total_amount column across all effective dates. Check for any midpoint rounding discrepancy between banker's rounding (V1) and standard rounding (V4 SQL ROUND).
**Expected Result:** All total_amount values match V1 to 2 decimal places. If a discrepancy is found, document it as FUZZY with per-column justification.

### TC3: Output Ordering
**Traces to:** BRD BR3, FSD FR3
**Description:** Verify rows are ordered by hour_of_day ascending (0, 1, 2, ..., 23).
**Method:** Inspect output CSV for each effective date.
**Expected Result:** Monotonically increasing hour_of_day values.

### TC4: Effective Date Column
**Traces to:** BRD BR4, FSD FR4
**Description:** Verify ifw_effective_date column is present and formatted as yyyy-MM-dd matching the run's effective date.
**Method:** Check ifw_effective_date value in every output row for each effective date.
**Expected Result:** All rows show the correct effective date in yyyy-MM-dd format.

### TC5: Trailer Record — Input Count
**Traces to:** BRD BR5, FSD FR5
**Description:** Verify the trailer line uses the INPUT transaction count (pre-aggregation), not the output row count.
**Method:** For each effective date, count the number of transactions in the datalake for that date and compare to the trailer count in the V4 output. Cross-reference with V1 trailer.
**Expected Result:** `TRAILER|{N}|{date}` where N matches the input transaction count from V1.

### TC6: Trailer Format
**Traces to:** BRD BR5, FSD FR5
**Description:** Verify trailer format is exactly `TRAILER|{count}|{date}` with pipe delimiters, no spaces, date in yyyy-MM-dd.
**Method:** Parse the last line of each output CSV.
**Expected Result:** Regex match: `^TRAILER\|\d+\|\d{4}-\d{2}-\d{2}$`

### TC7: Empty Input — Header-Only Output
**Traces to:** BRD BR9, FSD FR9
**Description:** When no transactions exist for the effective date, the output should be a CSV with header only and TRAILER|0|{date}.
**Method:** If an effective date with no transactions exists in the test range, verify output. Otherwise, this is an edge case that requires a synthetic test or documentation that the scenario was not testable with available data.
**Expected Result:** Header line + TRAILER|0|{date}, no data rows.

### TC8: Timestamp Parsing — Default Hour 0
**Traces to:** BRD BR8, FSD FR8
**Description:** Verify behavior when txn_timestamp is not parseable. If all timestamps in the datalake are valid ISO format, this edge case may not be testable with real data.
**Method:** Inspect datalake data for non-standard timestamps. If none exist, document as untestable edge case with real data.
**Expected Result:** Non-parseable timestamps bucketed into hour 0.

### TC9: Full Proofmark Comparison
**Traces to:** All BRD requirements
**Description:** Run Proofmark comparison of V4 output vs V1 output across all effective dates (2024-10-01 through 2024-10-07, excluding dates with no data).
**Method:** Proofmark STRICT comparison on data rows. Trailer comparison handled separately (TC5/TC6).
**Expected Result:** STRICT PASS on all comparable effective dates.

### TC10: Unused Source Elimination
**Traces to:** BRD AP1, AP4; FSD Section 2
**Description:** Verify that the V4 config does NOT source the `accounts` table and sources only `txn_timestamp` and `amount` from transactions.
**Method:** Inspect V4 job config. Verify no accounts DataSourcing module exists. Verify transactions DataSourcing sources only required columns.
**Expected Result:** Config sources only what is needed.

---

## 2. Edge Cases

| Edge Case | BRD Reference | Test Approach |
|-----------|---------------|---------------|
| No transactions for date | BR9, Edge Case 1 | TC7 — verify header-only + TRAILER\|0 |
| Non-parseable timestamp | BR8, Edge Case 2 | TC8 — check if testable with real data |
| Single-hour concentration | N/A | All transactions in one hour — verify single output row |
| All 24 hours represented | N/A | Verify 24 output rows if data spans full day |
| Large decimal sums | BR2, Edge Case 5 | TC2 — banker's rounding vs standard rounding check |

---

## 3. Anti-Pattern Verification

| Anti-Pattern | Verification Method |
|-------------|-------------------|
| AP1 — Dead-End Sourcing | TC10: Confirm accounts table not sourced in V4 config |
| AP3 — Unnecessary External | Verify External module is minimal (trailer logic only); aggregation is in SQL |
| AP4 — Unused Columns | TC10: Confirm only txn_timestamp, amount sourced from transactions |
| AP6 — Row-by-Row Iteration | Code review: confirm no foreach aggregation loops in V4 |
| AP7 — Magic Values | Code review: confirm no hardcoded file paths in V4 |

---

## 4. Additional Anti-Patterns Discovered During Test Design

None discovered. The BRD's anti-pattern analysis is comprehensive for this job.

---

## 5. Comparison Strategy

- **Primary:** Proofmark STRICT comparison of CSV data rows (excluding trailer line)
- **Trailer:** Custom comparison of trailer line format and count value
- **Effective Dates:** 2024-10-01 through 2024-10-07 (7 dates, may have gaps for dates with no transactions)
- **Known Deviations:** File path differs (curated vs poc4 date-partitioned). This is expected and not a fidelity concern.
- **FUZZY candidates:** Rounding differences (FR2) — only if midpoint values are encountered. Must be documented per-column with evidence.
