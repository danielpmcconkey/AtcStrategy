# Test Strategy: DansTransactionSpecial

**Job ID:** 373
**Job Name:** DansTransactionSpecial
**FSD Reference:** `POC4/Artifacts/DansTransactionSpecial/fsd.md`
**BRD Reference:** `POC4/Artifacts/DansTransactionSpecial/brd.md`

---

## 1. Test Cases

### TC1: Address Deduplication
**Traces to:** BRD BR1, FSD FR1
**Description:** Verify one address per customer in the transaction details output.
**Method:** For customers with potentially multiple addresses, check that only one address appears per customer in output. Verify it's the most recent by start_date.
**Expected Result:** One row per transaction (not duplicated by multiple addresses). Address matches most recent start_date for each customer.

### TC2: Multi-Table Denormalization
**Traces to:** BRD BR2, FSD FR2
**Description:** Verify all four tables (transactions, accounts, customers, addresses) are correctly joined.
**Method:** Cross-reference output rows with source tables. Verify join keys and column values.
**Expected Result:** Each transaction row enriched with correct account, customer, and address data.

### TC3: Transaction Details — Overwrite Mode
**Traces to:** BRD BR3, FSD FR3
**Description:** Verify each date partition contains only that day's transactions (not cumulative).
**Method:** Compare row count per date partition against datalake transaction count for that date.
**Expected Result:** Each partition has only the current day's transactions.

### TC4: State/Province Aggregation
**Traces to:** BRD BR4, FSD FR4
**Description:** Verify transaction_count and total_amount are correctly aggregated by ifw_effective_date and state_province.
**Method:** Manually compute expected aggregation from transaction_details output and compare.
**Expected Result:** Correct COUNT(*) and SUM(amount) per (ifw_effective_date, state_province) group.

### TC5: State/Province — Append Mode
**Traces to:** BRD BR5, FSD FR5
**Description:** Verify cumulative growth of state/province output across date partitions.
**Method:** Count rows in each date partition. Verify each contains all prior dates' data plus current day.
**Expected Result:** Oct 1 has ~31 rows (1 day). Oct 7 has ~217 rows (7 days accumulated).

### TC6: Output Ordering — Transaction Details
**Traces to:** BRD BR6, FSD FR6
**Description:** Verify transaction_details rows ordered by transaction_id ASC.
**Method:** Check transaction_id column is monotonically increasing in each date partition.
**Expected Result:** Ascending transaction_id order.

### TC7: Output Ordering — State/Province
**Traces to:** BRD BR6, FSD FR6
**Description:** Verify state/province rows ordered by ifw_effective_date ASC, then state_province ASC.
**Method:** Check ordering within each day's contribution. Note: accumulated file's global order depends on append semantics.
**Expected Result:** Within each day's data, state_province is alphabetically ordered.

### TC8: NULL Enrichment Fields
**Traces to:** BRD BR7, FSD FR7
**Description:** Verify LEFT JOIN produces NULLs when enrichment data is missing.
**Method:** Check for any transactions without matching accounts, customers without names, customers without addresses.
**Expected Result:** NULL fields render as empty strings in CSV.

### TC9: NULL State/Province in Aggregation
**Traces to:** BRD Edge Case 3
**Description:** Verify transactions with NULL state_province are grouped under NULL in the state/province summary.
**Method:** Check state/province output for empty/NULL state_province rows.
**Expected Result:** Transactions without addresses contribute to a NULL state_province group.

### TC10: etl_effective_date Overwrite in Append
**Traces to:** BRD BR5, FSD FR5
**Description:** Verify ALL rows in accumulated state/province file have current run's etl_effective_date.
**Method:** Check etl_effective_date column in accumulated files.
**Expected Result:** Single etl_effective_date value per file matching partition date.

### TC11: ifw_effective_date Preservation in Append
**Traces to:** BRD Edge Case 5
**Description:** Verify ifw_effective_date column preserves original transaction dates in accumulated file.
**Method:** Check that Oct 7 accumulated file contains distinct ifw_effective_date values from multiple days.
**Expected Result:** Multiple distinct ifw_effective_date values in the accumulated file.

### TC12: Full Proofmark Comparison — Transaction Details
**Traces to:** All BRD requirements for Output 1
**Description:** Proofmark STRICT comparison of V4 vs V1 for transaction details across all dates.
**Method:** Proofmark STRICT on all date partitions.
**Expected Result:** STRICT PASS on all dates. If address dedup non-determinism causes mismatches, document as EXCLUDED with justification (FR9).

### TC13: Full Proofmark Comparison — State/Province
**Traces to:** All BRD requirements for Output 2
**Description:** Proofmark STRICT comparison of V4 vs V1 for state/province summary across all dates.
**Method:** Proofmark STRICT on all date partitions.
**Expected Result:** STRICT PASS on all dates.

### TC14: Unused Column Elimination
**Traces to:** BRD AP4; FSD Section 2
**Description:** Verify V4 config does not source first_name and last_name from customers.
**Method:** Inspect V4 job config customers module.
**Expected Result:** Columns list contains only `id` and `sort_name`.

---

## 2. Edge Cases

| Edge Case | BRD Reference | Test Approach |
|-----------|---------------|---------------|
| No transactions for date | Edge Case 1 | TC3: empty detail, TC5: append prior only |
| Transaction without matching account | Edge Case 2 | TC8: NULL enrichment fields |
| Customer without address | Edge Case 3 | TC8, TC9: NULL state_province |
| Address dedup tiebreaker | Edge Case 4 | TC1, TC12: non-determinism check |
| etl_effective_date overwrite in append | Edge Case 5 | TC10: current date for all rows |
| State/province GROUP BY with ifw_effective_date | Edge Case 6 | TC4: per-day granularity preserved |
| Re-run with existing output | Edge Case 7 | Operational requirement: clean output dirs |

---

## 3. Anti-Pattern Verification

| Anti-Pattern | Verification Method |
|-------------|-------------------|
| AP4 — Unused Columns | TC14: first_name, last_name removed from config |
| AP8 — Complex/Dead SQL (Minor) | Code review: CTE preserved for defensive dedup |
| AP7 — Magic Values (Minor) | Documented in FSD: ifw_effective_date explicitly sourced |

---

## 4. Additional Anti-Patterns Discovered During Test Design

### AP-NEW: Non-Deterministic ROW_NUMBER Tiebreaker (AP8-adjacent)
The `deduped_addresses` CTE uses `ORDER BY start_date DESC` with no tiebreaker column. If two addresses for the same customer share the same start_date, the result is non-deterministic. This was identified in the BRD (Edge Case 4) but deserves anti-pattern classification because it creates unreproducible output. However, since V4 preserves the same SQL, the non-determinism is identical — it's V1's problem, not V4's introduction.

**Test implication:** If Proofmark comparison fails on city, state_province, or postal_code columns, investigate whether address dedup tiebreaking is the cause. If confirmed, mark those columns as EXCLUDED for the affected rows with evidence.

---

## 5. Comparison Strategy

### Output 1: Transaction Details
- **Primary:** Proofmark STRICT comparison
- **Effective Dates:** 2024-10-01 through 2024-10-07
- **Known Risks:** Address dedup non-determinism (FR9)
- **FUZZY candidates:** None expected (amounts are direct pass-through, not aggregated)
- **EXCLUDED candidates:** city, state_province, postal_code IF address dedup tiebreaker causes mismatches (must be individually justified per row/customer)

### Output 2: State/Province Summary
- **Primary:** Proofmark STRICT comparison (order-independent for accumulated files)
- **Effective Dates:** 2024-10-01 through 2024-10-07
- **Known Risks:** If address dedup non-determinism changes which state_province is assigned, aggregation totals may differ
- **FUZZY candidates:** total_amount IF SQLite accumulation order differs (unlikely since both V1 and V4 use the same SQLite path)
- **Ordering note:** Accumulated files have append semantics — prior data order preserved, new data sorted. Use order-independent comparison.
