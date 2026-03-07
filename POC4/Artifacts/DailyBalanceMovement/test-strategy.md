# Test Strategy: DailyBalanceMovement

**Job ID:** 166
**Job Name:** DailyBalanceMovement
**FSD Reference:** `POC4/Artifacts/DailyBalanceMovement/fsd.md`
**BRD Reference:** `POC4/Artifacts/DailyBalanceMovement/brd.md`

---

## 1. Test Cases

### TC1: Account-Level Aggregation
**Traces to:** BRD BR1, FSD FR1
**Description:** Verify transactions are grouped by account_id with correct debit and credit totals.
**Method:** Run V4 job for 2024-10-01. Compare account_id set and per-account totals against V1 output.
**Expected Result:** Same set of account_ids with identical debit_total and credit_total values.

### TC2: Debit/Credit Classification
**Traces to:** BRD BR2, FSD FR2
**Description:** Verify only "Debit" and "Credit" txn_type values contribute to respective totals. Other txn_type values are silently excluded.
**Method:** Cross-reference V4 output with raw datalake transactions. Verify amounts match manual calculation.
**Expected Result:** debit_total = SUM(amount) WHERE txn_type='Debit'; credit_total = SUM(amount) WHERE txn_type='Credit'.

### TC3: Net Movement Calculation
**Traces to:** BRD BR3, FSD FR3
**Description:** Verify net_movement = credit_total - debit_total for every row.
**Method:** Arithmetic verification on every output row.
**Expected Result:** net_movement = credit_total - debit_total for all rows.

### TC4: Double Precision Fidelity
**Traces to:** BRD BR4, FSD FR4
**Description:** Verify V4 numeric output matches V1 exactly, accounting for double precision.
**Method:** Proofmark STRICT comparison on debit_total, credit_total, net_movement columns across all effective dates.
**Expected Result:** STRICT PASS. If epsilon differences found, document per-column with FUZZY justification.

### TC5: Customer ID Lookup — Default 0
**Traces to:** BRD BR5, FSD FR5
**Description:** Verify customer_id is correctly looked up from accounts and defaults to 0 when no match exists.
**Method:** Check for any account_ids in V1 output with customer_id=0. Verify V4 produces the same. Cross-reference with accounts table.
**Expected Result:** Identical customer_id values including default-0 cases.

### TC6: ifw_effective_date Format
**Traces to:** BRD BR6, FSD FR6
**Description:** Verify ifw_effective_date column format matches V1 (MM/DD/YYYY).
**Method:** Compare ifw_effective_date column format in V4 vs V1 output.
**Expected Result:** Format is `MM/DD/YYYY` (e.g., `10/01/2024`), matching V1.

### TC7: etl_effective_date Injection
**Traces to:** BRD BR7, FSD FR7
**Description:** Verify etl_effective_date column is present and formatted as yyyy-MM-dd.
**Method:** Check last column in every output CSV.
**Expected Result:** etl_effective_date present with correct format.

### TC8: Empty Input Handling
**Traces to:** BRD BR8, FSD FR8
**Description:** When no transactions or accounts exist, output should be header-only CSV.
**Method:** If testable with available data (an effective date with no transactions), verify. Otherwise document as untestable edge case.
**Expected Result:** Header-only CSV with etl_effective_date column.

### TC9: Full Proofmark Comparison
**Traces to:** All BRD requirements
**Description:** Proofmark comparison of V4 vs V1 across all effective dates.
**Method:** Run Proofmark STRICT on all date partitions.
**Expected Result:** STRICT PASS on all dates.

### TC10: Unused Source Elimination
**Traces to:** BRD AP4; FSD Section 2
**Description:** Verify V4 config does not source `transaction_id`.
**Method:** Inspect V4 job config columns list.
**Expected Result:** Only `account_id`, `txn_type`, `amount` sourced from transactions.

### TC11: No External Module
**Traces to:** BRD AP3; FSD Section 2
**Description:** Verify V4 config uses Transformation, not External module.
**Method:** Inspect V4 job config — no External module type present.
**Expected Result:** Module chain is DataSourcing -> DataSourcing -> Transformation -> CsvFileWriter.

---

## 2. Edge Cases

| Edge Case | BRD Reference | Test Approach |
|-----------|---------------|---------------|
| No transactions for date | BR8, Edge Case 1 | TC8 — header-only output |
| No accounts for date | BR8, Edge Case 2 | TC8 — empty DataFrame |
| Account with only non-Debit/non-Credit txns | Edge Case 3 | Verify account appears with 0/0/0 |
| Floating-point precision | BR4, Edge Case 4 | TC4 — Proofmark STRICT comparison |
| Multiple transactions per account | Edge Case 5 | TC1 — standard aggregation test |
| Unmatched account_id (customer_id=0) | Edge Case 6 | TC5 — verify default behavior |

---

## 3. Anti-Pattern Verification

| Anti-Pattern | Verification Method |
|-------------|-------------------|
| AP3 — Unnecessary External | TC11: No External module in V4 config |
| AP4 — Unused Columns | TC10: transaction_id not sourced |
| AP5 — Asymmetric Null/Default | Code review: COALESCE(customer_id, 0) documented; CASE only matches Debit/Credit |
| AP6 — Row-by-Row Iteration | Code review: SQL GROUP BY, no foreach |
| AP7 — Magic Values | Code review: default 0 preserved but documented via COALESCE |

---

## 4. Additional Anti-Patterns Discovered During Test Design

### AP-NEW: Undefined Row Ordering
V1 output row order depends on C# Dictionary iteration order, which is not guaranteed. The V1 config has no ORDER BY and the External module does not sort output. V4 SQL Transformation also has no ORDER BY. Proofmark should use order-independent comparison, or both V1 and V4 should be sorted before comparison. This is not an anti-pattern per se but a testing consideration.

---

## 5. Comparison Strategy

- **Primary:** Proofmark STRICT comparison of CSV data rows (order-independent)
- **Effective Dates:** 2024-10-01 through 2024-10-07
- **Known Deviations:** None expected. If ifw_effective_date format differs, document as FUZZY with per-column evidence.
- **FUZZY candidates:** Double precision values (FR4) — only if accumulation-order differences produce epsilon errors. Must be justified per-column.
