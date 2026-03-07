# Test Strategy: CreditScoreDelta

**Job ID:** 369
**Job Name:** CreditScoreDelta
**FSD Reference:** `POC4/Artifacts/CreditScoreDelta/fsd.md`
**BRD Reference:** `POC4/Artifacts/CreditScoreDelta/brd.md`

---

## 1. Test Cases

### TC1: Customer Scope Enforcement
**Traces to:** BRD BR1, FSD FR1
**Description:** Verify that only customer_ids 2252, 2581, and 2632 appear in the output.
**Method:** Check all output CSVs across all effective dates for customer_id values.
**Expected Result:** No customer_id outside {2252, 2581, 2632} in any output.

### TC2: Score Comparison — Today vs Prior
**Traces to:** BRD BR2, FSD FR2
**Description:** Verify LEFT JOIN semantics: current score with no prior shows NULL prior_score; prior with no current is excluded.
**Method:** Check 2024-10-01 output (first run, no prior) — all rows should have empty prior_score. Check 2024-10-02+ for populated prior_scores.
**Expected Result:** Oct 1: all prior_score empty. Oct 2+: prior_score populated where prior data exists.

### TC3: Change Detection Filter
**Traces to:** BRD BR3, FSD FR3
**Description:** Verify only changed scores or new scores (no prior) are included.
**Method:** For each effective date, query the datalake for current and prior scores. Verify only rows where score changed or prior is NULL appear in output.
**Expected Result:** No rows where current_score == prior_score.

### TC4: Customer Name Enrichment
**Traces to:** BRD BR4, FSD FR4
**Description:** Verify sort_name is correctly joined from customers table.
**Method:** Cross-reference output sort_name values with customers table for customer_ids 2252, 2581, 2632.
**Expected Result:** Correct sort_name for each customer_id (e.g., 2252 -> "Reyes Gabriel").

### TC5: Output Ordering
**Traces to:** BRD BR5, FSD FR5
**Description:** Verify rows ordered by customer_id ASC, then bureau ASC.
**Method:** Inspect row order in each output CSV.
**Expected Result:** customer_id ascending; within same customer_id, bureau alphabetically ascending.

### TC6: Missing Data Failure
**Traces to:** BRD BR7, FSD FR7
**Description:** Verify job FAILS for effective dates with no credit_scores data (Oct 5, Oct 6).
**Method:** Confirm no output partition exists for 2024-10-05 and 2024-10-06. Verify task_queue shows failure status.
**Expected Result:** No output for Oct 5/6; job fails with error.

### TC7: NULL Prior Score Rendering
**Traces to:** BRD BR2, FSD Section 5.2
**Description:** Verify NULL prior_score renders as empty string in CSV (not literal "NULL" or "None").
**Method:** Inspect Oct 1 output where all prior_scores should be NULL.
**Expected Result:** Empty field between commas (e.g., `623,,2024-10-01`).

### TC8: Full Proofmark Comparison
**Traces to:** All BRD requirements
**Description:** Proofmark STRICT comparison of V4 vs V1 across all effective dates that produce output.
**Method:** Proofmark STRICT on all date partitions where V1 output exists.
**Expected Result:** STRICT PASS on all comparable dates.

### TC9: Anti-Pattern Fix — Customer Filter
**Traces to:** BRD AP1, AP10; FSD Section 2
**Description:** Verify V4 config adds `additionalFilter` to customers DataSourcing module.
**Method:** Inspect V4 job config customers module.
**Expected Result:** `"additionalFilter": "id IN (2252, 2581, 2632)"` present.

---

## 2. Edge Cases

| Edge Case | BRD Reference | Test Approach |
|-----------|---------------|---------------|
| No credit_scores for date | BR7, Edge Case 1 | TC6 — job fails for Oct 5/6 |
| First run (no prior) | Edge Case 2 | TC2 — all prior_scores NULL on Oct 1 |
| All scores unchanged | Edge Case 3 | Check if any date produces empty output |
| Customer not in customers table | Edge Case 4 | Verify sort_name NULL handling |
| 3 customers x 3 bureaus = 9 rows max | Edge Case 5 | Verify row count per date |

---

## 3. Anti-Pattern Verification

| Anti-Pattern | Verification Method |
|-------------|-------------------|
| AP1 — Dead-End Sourcing (Partial) | TC9: additionalFilter on customers DataSourcing |
| AP7 — Magic Values | Documented in FSD; inherent to business rule |
| AP10 — Over-Sourcing (Partial) | TC9: additionalFilter reduces customers scope |

---

## 4. Additional Anti-Patterns Discovered During Test Design

None. CreditScoreDelta is already well-structured (SQL Transformation, no External module). The only V1 issues are config-level sourcing inefficiencies.

---

## 5. Comparison Strategy

- **Primary:** Proofmark STRICT comparison
- **Effective Dates:** 2024-10-01 through 2024-10-07, excluding Oct 5 and Oct 6 (job failures)
- **Known Deviations:** None expected
- **FUZZY candidates:** None — all values are integers or strings, no floating-point concerns
- **Failure parity:** Verify Oct 5/6 fail in V4 just as in V1
