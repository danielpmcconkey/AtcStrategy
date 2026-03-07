# Test Strategy: BranchVisitsByCustomerCsvAppendTrailer

**Job ID:** 371
**Job Name:** BranchVisitsByCustomerCsvAppendTrailer
**FSD Reference:** `POC4/Artifacts/BranchVisitsByCustomerCsvAppendTrailer/fsd.md`
**BRD Reference:** `POC4/Artifacts/BranchVisitsByCustomerCsvAppendTrailer/brd.md`

---

## 1. Test Cases

### TC1: Customer Scope Filter
**Traces to:** BRD BR1, FSD FR1
**Description:** Verify only customer_ids < 1500 appear in output.
**Method:** Check all output CSVs across all effective dates for customer_id values.
**Expected Result:** No customer_id >= 1500 in any output row.

### TC2: Customer Name Enrichment
**Traces to:** BRD BR2, FSD FR2
**Description:** Verify sort_name is correctly joined from customers table.
**Method:** Cross-reference output sort_name values with customers table for customer_ids in the output.
**Expected Result:** Correct sort_name for each customer_id. NULL for any customer not in customers table.

### TC3: Output Ordering
**Traces to:** BRD BR3, FSD FR3
**Description:** Verify rows ordered by customer_id ASC, then visit_timestamp ASC.
**Method:** Inspect row order in each output CSV. Note: for accumulated files, ordering applies to the current day's new rows appended after prior data. The full file may not be globally sorted (prior rows maintain their original order within the accumulated block).

**Critical clarification:** The framework's append logic unions prior data with current data. The SQL ORDER BY applies only to the current day's transformation output. The prior data retains whatever order it had when written. So the FULL accumulated file is not globally sorted by customer_id/visit_timestamp — it's sorted within each day's contribution. Proofmark comparison must account for this.

**Expected Result:** Within each day's contribution, rows sorted by customer_id then visit_timestamp.

### TC4: Append Mode — Cumulative Growth
**Traces to:** BRD BR4, FSD FR4
**Description:** Verify each date partition contains all prior data plus current day's data.
**Method:** Count data rows in each date partition. Verify monotonic growth (each partition >= prior partition row count). Verify final partition contains sum of all daily contributions.
**Expected Result:** Oct 1 has day-1 rows only. Oct 2 has day-1 + day-2 rows. Etc.

### TC5: Trailer Record — Total Count
**Traces to:** BRD BR5, FSD FR5
**Description:** Verify trailer line shows total accumulated row count and correct date.
**Method:** Parse trailer from each output CSV. Verify count matches actual data row count (excluding header and trailer).
**Expected Result:** `TRAILER|{N}|{date}` where N = number of data rows in the file.

### TC6: Trailer Format
**Traces to:** BRD BR5
**Description:** Verify trailer format is exactly `TRAILER|{count}|{date}`.
**Method:** Regex validation of last line of each output CSV.
**Expected Result:** Match: `^TRAILER\|\d+\|\d{4}-\d{2}-\d{2}$`

### TC7: etl_effective_date Overwrite
**Traces to:** BRD BR4, FSD FR4
**Description:** Verify ALL rows (including accumulated prior data) have etl_effective_date set to the current run's effective date.
**Method:** Check etl_effective_date column in accumulated files (e.g., Oct 7 file should show 2024-10-07 for ALL rows).
**Expected Result:** Single etl_effective_date value per file matching the partition date.

### TC8: First Run — No Prior Data
**Traces to:** BRD Edge Case 3, FSD FR8
**Description:** Verify Oct 1 output contains only that day's visits (no prior accumulation).
**Method:** Compare Oct 1 row count to the number of branch visits for Oct 1 with customer_id < 1500.
**Expected Result:** Row count matches single-day data.

### TC9: Column Pass-Through Fidelity
**Traces to:** BRD BR6, FSD FR6
**Description:** Verify all visit columns pass through unchanged.
**Method:** Proofmark STRICT comparison of V4 vs V1 output.
**Expected Result:** Byte-identical data values.

### TC10: Full Proofmark Comparison
**Traces to:** All BRD requirements
**Description:** Proofmark comparison of V4 vs V1 across all effective dates.
**Method:** Proofmark STRICT on all date partitions. Note: order within accumulated files must be handled correctly (order-independent comparison or pre-sorted).
**Expected Result:** STRICT PASS on all dates.

### TC11: Anti-Pattern Fix — Customer Filter
**Traces to:** BRD AP1; FSD Section 2
**Description:** Verify V4 config adds additionalFilter to customers DataSourcing.
**Method:** Inspect V4 job config.
**Expected Result:** `"additionalFilter": "id < 1500"` on customers module.

---

## 2. Edge Cases

| Edge Case | BRD Reference | Test Approach |
|-----------|---------------|---------------|
| No visits for a date | Edge Case 1 | TC4: accumulated file grows by 0 rows |
| Customer not in customers table | Edge Case 2 | TC2: sort_name = NULL |
| First run (no prior partition) | Edge Case 3 | TC8: single day only |
| etl_effective_date overwrite | Edge Case 4 | TC7: all rows show current date |
| Trailer stripping on append | Edge Case 5 | TC5: verify trailer count accuracy across accumulated files |
| Re-run with existing output | Edge Case 6 | Note: requires clean output dir; not a V4 test case but operational requirement |

---

## 3. Anti-Pattern Verification

| Anti-Pattern | Verification Method |
|-------------|-------------------|
| AP1 — Dead-End Sourcing (Partial) | TC11: additionalFilter on customers DataSourcing |
| AP7 — Magic Values | Documented in FSD; inherent to business rule |

---

## 4. Additional Anti-Patterns Discovered During Test Design

### AP-NEW: Accumulated File Ordering Ambiguity
The append mode unions prior data with current data. The SQL ORDER BY only applies to the current day's data. The accumulated file's global ordering is undefined — prior data retains its prior order, and new data is sorted and appended. This means the full accumulated file is NOT globally sorted, which could be confusing for downstream consumers. However, this is existing V1 framework behavior, not a V4 anti-pattern. Document and preserve.

---

## 5. Comparison Strategy

- **Primary:** Proofmark STRICT comparison of V4 vs V1 per date partition
- **Effective Dates:** 2024-10-01 through 2024-10-07
- **Known Deviations:** None expected
- **FUZZY candidates:** None — all values are integers, strings, or timestamps
- **Ordering note:** Accumulated files may have order differences between V1 and V4 if prior data ordering differs. Proofmark should use order-independent mode.
- **Trailer comparison:** Separate verification of trailer line (TC5/TC6)
