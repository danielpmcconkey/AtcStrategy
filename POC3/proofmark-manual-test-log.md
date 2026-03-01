# Proofmark Manual Test Log

**Date:** 2026-03-01
**Tester:** Dan McConkey
**Tool version:** Proofmark v0.1.0
**Test data:** Synthetic credit card transactions — CSV (1,656 rows, 9 columns) and Parquet (500 rows, 9 columns)
**Test location:** `proofmark/tests/fixtures/dan_manual_test/`

---

## Purpose

Manual validation of Proofmark's comparison engine against realistic, hand-crafted
test scenarios. These tests supplement the 205 automated unit/BDD tests with
exploratory testing using larger datasets and adversarial edge cases.

---

## Test Results

| # | Test Case | Expected | Actual | Exit Code |
|---|-----------|----------|--------|-----------|
| 001 | Identical files (baseline) | PASS | PASS | 0 |
| 002 | Missing row in RHS (different sort order) | FAIL | FAIL | 1 |
| 003 | Data mutation (merchant_category_code "7011" → "7011_", 92 rows affected) | FAIL | FAIL | 1 |
| 004 | Line break mismatch (LF vs CRLF, entire file) | FAIL | FAIL | 1 |
| 005 | Mixed line break (1 rogue LF in otherwise CRLF file) | FAIL | **PASS** | 0 |
| 006 | Schema mismatch — missing column (amount removed from RHS) | FAIL | FAIL | 1 |
| 007 | Schema mismatch — extra column (junk_column added to RHS) | FAIL | FAIL | 1 |
| 008 | Floating point precision drift — all STRICT | FAIL | FAIL | 1 |
| 009 | Floating point precision drift — FUZZY absolute tolerance | PASS | PASS | 0 |
| 010 | Trailer rows — correctly configured | PASS | PASS | 0 |
| 011 | Trailer rows — config ignores trailers (trailer_rows: 0) | PASS | PASS | 0 |
| 012 | Trailer rows — misplaced in middle of RHS data | FAIL | FAIL | 1 |
| 013 | CSV quoting difference (quoted LHS vs unquoted RHS) | FAIL | FAIL* | 1 |
| 014 | Whitespace after delimiters (16 random rows, RHS only) | FAIL | FAIL | 1 |
| | **Parquet Tests** | | | |
| 015 | [Parquet] Identical files (baseline) | PASS | PASS | 0 |
| 016 | [Parquet] Missing row in RHS (shuffled) | FAIL | FAIL | 1 |
| 017 | [Parquet] Data mutation (merchant_category_code, 46 rows) | FAIL | FAIL | 1 |
| 018 | [Parquet] Schema mismatch — missing column | FAIL | FAIL | 1 |
| 019 | [Parquet] Schema mismatch — extra column | FAIL | FAIL | 1 |
| 020 | [Parquet] Float precision drift — all STRICT | FAIL | FAIL | 1 |
| 021 | [Parquet] Float precision drift — FUZZY absolute tolerance | PASS | PASS | 0 |
| 022 | [Parquet] Multi-part LHS vs single-part RHS (same data) | PASS | PASS | 0 |
| 023 | [Parquet] Column type mismatch (int64 vs int32) | FAIL | FAIL | 1 |

---

## Detail: Passing Tests

### 001 — Identical Files
- LHS and RHS are byte-identical copies of the same 1,656-row CSV.
- All 9 columns classified STRICT. 100% match. Clean PASS.
- Validates the happy path with realistic data volume.

### 002 — Missing Row + Different Sort Order
- RHS has 1,655 rows (one row removed). Rows are in a different sort order than LHS.
- Proofmark correctly identified the single missing row (txn 65285, Trader Joes, $37.76).
- 99.97% match rate, but threshold is 100% → FAIL.
- **Key validation:** Order-independent comparison works correctly. The hash-sort-diff
  engine matched 1,655 rows despite completely different row ordering.

### 003 — Data Mutation (merchant_category_code)
- RHS has 92 rows where `merchant_category_code` was changed from "7011" to "7011_".
- Proofmark flagged all 92 as mismatches. 94.4% match → FAIL.
- Report included full mismatch detail with surplus rows on both sides and correlation pairs.
- Report size: ~44K tokens due to 92 mismatch pairs with full row content.
  Acceptable for POC; vendor build should consider capping mismatch detail or
  offering a summary-only mode.

### 004 — Line Break Mismatch (Entire File)
- LHS uses LF line endings, RHS uses CRLF throughout.
- All row data matched (100% match percentage), but `line_break_mismatch: true` → FAIL.
- **Key validation:** Equivalence is total. Matching data with mismatched file format
  is still a failure.

### 006 — Schema Mismatch (Missing Column)
- RHS is missing the `amount` column (8 columns vs LHS's 9).
- Schema validation short-circuited: no row-level comparison attempted.
- Report: `"Column count mismatch: LHS has 9 columns, RHS has 8 columns"`

### 007 — Schema Mismatch (Extra Column)
- RHS has an extra `junk_column` (10 columns vs LHS's 9).
- Same short-circuit behavior as 006.
- Report: `"Column count mismatch: LHS has 9 columns, RHS has 10 columns"`

### 008 — Floating Point Precision Drift (STRICT)
- Aggregated dataset: 17 rows with `weirdness_coefficient` derived from
  `avg(amount * customer_id * 0.0001147956)` grouped by `merchant_category_code`.
- LHS and RHS produced by different execution paths, generating float precision
  differences at the ~8th–10th significant digit (e.g., 67.1410696582165770 vs
  67.1410696640653264).
- All columns classified STRICT. Every single row failed — 0% match, 17/17 mismatches.
- Correlator correctly paired all 17 rows with high confidence, identifying
  `weirdness_coefficient` as the sole differing column in every pair.
- **Key validation:** STRICT classification treats any string difference as a mismatch.
  Floating point variance that is functionally irrelevant still causes total failure
  under STRICT rules. This is the correct behavior — and the motivation for FUZZY.

### 009 — Floating Point Precision Drift (FUZZY)
- Same data files as 008. Only the config changed.
- `weirdness_coefficient` classified as FUZZY with absolute tolerance of 0.0001.
- All 17 rows matched. 100% match. Clean PASS.
- Actual deltas (~5e-9) were well within the 0.0001 tolerance.
- **Key validation:** FUZZY classification with appropriate tolerance absorbs
  expected floating point variance without masking real data differences. The
  008/009 pair demonstrates the complete STRICT-vs-FUZZY workflow: fail first,
  then configure tolerance with documented justification.

### 010 — Trailer Rows (Correctly Configured)
- Added 2 trailing control records to both LHS and RHS: `expected_rows:165` and
  `created:2024-11:13 06:19:12.034`. Config set `trailer_rows: 2`.
- Proofmark separated trailers from data, compared them independently, and matched.
- 1,656 data rows matched. Both trailer lines matched. Clean PASS.

### 011 — Trailer Rows (Config Ignores Trailers)
- Same files as 010, but config set `trailer_rows: 0`.
- Trailer lines were treated as data rows. Since both sides have identical trailers,
  they hashed the same and matched.
- Row count inflated to 1,658 (1,656 data + 2 trailer-as-data). Still PASS.
- **Key observation:** Misconfiguring `trailer_rows` doesn't cause a false FAIL here
  because the trailers are identical. But it inflates the row count and would mask
  a trailer-only difference. The config must match the file format.

### 012 — Trailer Rows Misplaced in Middle of Data
- LHS has trailers at the end (correct). RHS has the same trailer lines manually
  moved to the middle of the data section.
- Config set `trailer_rows: 2`, so Proofmark grabbed the last 2 lines from each file.
  LHS got real trailers; RHS got the last 2 data rows (Whole Foods, Starbucks).
- **Trailer comparison:** Both positions `match: false`. LHS has control records,
  RHS has transaction data.
- **Data comparison:** The misplaced trailer lines in the RHS middle were parsed as
  data rows with 8 empty columns (`"expected_rows:165||||||||"`). The 2 data rows
  pulled as "trailers" went missing from the RHS data. Result: 4 mismatched rows
  (2 junk data on RHS, 2 missing data on RHS).
- **Real-world relevance:** This exact scenario occurs in production when Spark jobs
  concatenate data and trailer DataFrames. Teams assume `union`/`concat` preserves
  order, but Spark's lazy evaluation and partition shuffling can place the trailer
  rows anywhere in the output. The bug is intermittent — it works in dev and UAT
  where data volumes are small enough for single-partition execution, then fails
  unpredictably at production scale. Without a comparison tool, the misplacement
  ships silently.

### 014 — Whitespace After Delimiters
- 16 random RHS rows had a space inserted after every comma (`3001` → ` 3001`).
- Python's csv module preserves leading whitespace (unlike quoting, which it strips).
  All 16 rows hashed differently and were flagged as mismatches. 99.03% match → FAIL.
- Correlator returned zero correlated pairs — every column in the modified rows had
  a leading space, so they fell below the >50% column match threshold.
- **Key validation:** Whitespace is data. The parser preserves it, the hasher catches
  it. Unlike the quoting gap in test 013, whitespace handling is correct by default.

### 015 — [Parquet] Identical Files (Baseline)
- 500 rows, 9 columns (int64, string, float64). Identical parquet files on both sides.
- 100% match. Clean PASS. Establishes baseline for parquet reader.

### 016 — [Parquet] Missing Row (Shuffled)
- LHS has 500 rows, RHS has 499 (row 42 removed, remaining rows shuffled).
- Proofmark caught the single missing row (txn 70042, Delta Airlines, $241.01).
- Identical behavior to CSV test 002. Order independence confirmed for parquet.

### 017 — [Parquet] Data Mutation
- 46 rows where `merchant_category_code` changed from "7011" to "7011_".
- All 46 flagged. 90.8% match → FAIL. Same behavior as CSV test 003.

### 018 — [Parquet] Schema Mismatch (Missing Column)
- `amount` column dropped from RHS. Schema short-circuit.
- `"Column count mismatch: LHS has 9 columns, RHS has 8 columns"`

### 019 — [Parquet] Schema Mismatch (Extra Column)
- `junk_column` added to RHS. Schema short-circuit.
- `"Column count mismatch: LHS has 9 columns, RHS has 10 columns"`

### 020 — [Parquet] Float Precision Drift (STRICT)
- ~1e-10 noise added to `amount` on all 500 RHS rows. All STRICT.
- 0% match, 500/500 mismatches. Float noise invisible to humans, lethal to hashing.

### 021 — [Parquet] Float Precision Drift (FUZZY)
- Same files as 020. `amount` classified FUZZY with absolute tolerance 0.0001.
- 100% match. Clean PASS. Tolerance absorbs the ~1e-10 noise easily.

### 022 — [Parquet] Multi-Part vs Single-Part
- LHS: 3 part files (~167 rows each). RHS: 1 part file (500 rows). Same data.
- 100% match. Clean PASS. Part file boundaries are invisible to the pipeline.
- **Key validation:** A rewrite that coalesces partitions (common Spark optimization)
  produces different physical layout but identical data. Proofmark handles this
  correctly — this is core to the parquet value proposition (BR-3.15, BR-3.16).

### 023 — [Parquet] Column Type Mismatch
- `card_txn_id` is int64 on LHS, int32 on RHS. Same values, different types.
- Schema short-circuit: `"Column \"card_txn_id\" type mismatch: int64 vs int32"`
- **Parquet-only capability.** CSV has no type metadata. Parquet's embedded schema
  catches type changes even when no data is truncated (BR-4.12).

---

## Detail: Critical Gap Found

### 013 — CSV Quoting Difference (FAIL for the Wrong Reason)
- LHS has all fields quoted (`"Nordstrom","5311","375.67"`). RHS has no quotes
  (`Nordstrom,5311,375.67`). Same data values, different CSV formatting.
- **Expected:** FAIL — the files are not byte-equivalent (BR-5.4: "Byte-level exact
  match required. No tolerance, no normalization").
- **Actual:** FAIL — but not because of data comparison. **The data matched 100%.**
  The FAIL came from header mismatch (raw string comparison catches quoting) and an
  incidental line break difference.
- **Root cause:** Python's csv module strips quoting during parsing (BR-14.1: "Use a
  standard parser"). By the time data reaches the hasher, `"Nordstrom"` and `Nordstrom`
  are both just `Nordstrom`. The hash-sort-diff pipeline operates on parsed values,
  not raw file bytes.
- **Why this isn't a simple fix:** If you hash raw strings to preserve quoting, FUZZY
  tolerance comparison breaks. `"375.67"` and `375.67` become different strings, and
  you'd need to selectively strip quoting for numeric columns before float parsing
  while preserving it for string columns. The clean separation of "parse once, then
  classify and compare" falls apart. You're effectively reinventing CSV dialect handling
  — which the BRD explicitly defers to vendor build (Section 14).
- **The BRD tension:** BR-5.4 says "byte-level exact match, no normalization" — intent
  is clearly that different bytes = mismatch. But BR-14.1 says "use a standard parser"
  — which inherently normalizes quoting. The BRD language was written with data values
  in mind (NULL vs empty, precision), not CSV formatting artifacts. The intent is "don't
  normalize the data," not "don't parse the format." But the language doesn't make that
  distinction.
- **Risk assessment: HIGH for production.** Quoting differences between ETL outputs are
  common. Different Spark write modes, different frameworks, manual exports — all produce
  valid CSV with different quoting conventions. The POC is saved by header comparison
  (which catches quoting in the header row), but a file with unquoted headers on both
  sides and different data quoting would produce a false PASS on data comparison.
- **Disposition:** Accepted for POC — the header comparison provides a partial safety net.
  **The vendor build MUST address this.** Full CSV dialect specification (BR-14.1 production
  requirement) should include per-target quoting configuration or raw-byte comparison mode.
  This is the single most significant gap identified in manual testing.

---

## Detail: Known Limitation (Low Risk)

### 005 — Mixed Line Breaks (False PASS)
- RHS had 1,656 CRLF line endings and 1 LF line ending (simulating manual file editing).
- **Expected:** FAIL (the files are not byte-equivalent).
- **Actual:** PASS. Proofmark did not detect the mixed line break.
- **Root cause:** Line break detection in `csv_reader.py` (FSD-5.3.11 / FSD-6.10) is
  binary: if any `\r\n` exists → "CRLF", otherwise → "LF". A file with 1,656 CRLF
  and 1 LF is classified as "CRLF" on both sides. After internal normalization to `\n`,
  all row data matches.
- **Risk assessment:** Low. This scenario requires manual editing of a CSV file
  (e.g., opening in Excel). ETL pipeline outputs use consistent line endings.
- **Disposition:** Documented as vendor build note at FSD-6.10. Vendor build should
  detect mixed line breaks as a distinct state.

---

## Observations

1. **Order independence works.** Test 002 confirmed that different row ordering does not
   affect comparison results. This is critical for ETL rewrites that may change sort behavior.

2. **Schema validation is a hard gate.** Tests 006 and 007 confirmed that column count
   mismatches short-circuit the pipeline. No wasted compute on row comparison when the
   schemas don't agree.

3. **Report size scales with mismatches.** Test 003 produced a 44K-token report for 92
   mismatches. For POC3 agent consumption, workers should read the summary section first
   and only inspect mismatch detail if needed for diagnosis.

4. **One false PASS found.** Test 005 exposed a gap in mixed line break detection.
   Documented and deferred to vendor build. Low real-world risk.

5. **FUZZY tolerance works as designed.** Tests 008 and 009 used identical data files
   with different configs. STRICT produced 0% match; FUZZY with absolute tolerance
   produced 100% match. This is the expected workflow: a job fails under STRICT,
   the team investigates, determines the variance is acceptable floating point drift,
   and configures FUZZY with a documented reason. The reason string appears in the
   report for audit traceability.

6. **Trailer misconfiguration is detectable but diagnostics are indirect.** Test 012
   demonstrated that misplaced trailers produce a FAIL through trailer mismatch and
   displaced data rows, but the report doesn't explicitly say "trailers are in the
   wrong place." A human familiar with ETL recognizes the pattern immediately; an
   agent consuming the report may need coaching to identify this failure mode.

7. **Config correctness matters.** Test 011 showed that misconfiguring `trailer_rows`
   doesn't necessarily cause a failure — if trailers are identical, they pass as data.
   This reinforces that Proofmark validates equivalence *given a config*, not config
   correctness itself. The config is the team's responsibility.

8. **CSV quoting is invisible to data comparison.** Test 013 revealed that the standard
   CSV parser normalizes quoting before the hash pipeline sees the data. The POC's
   header comparison partially mitigates this (quoting differences in the header row
   cause auto-FAIL), but the data pipeline itself cannot distinguish quoted from
   unquoted values. **This is the highest-priority gap for the vendor build** and
   directly motivates the BRD's production requirement for full CSV dialect
   specification (Section 14).

9. **Parquet and CSV pipelines behave identically after reader handoff.** Tests 015–021
   ported the CSV scenarios to parquet. Every test produced the same result — the
   comparison engine is format-agnostic once the reader produces rows. This validates
   the pluggable reader architecture (BR-3.6).

10. **Multi-part file assembly is transparent.** Test 022 confirmed that 3 part files
    on LHS vs 1 part file on RHS compares correctly. Part file boundaries are an
    implementation detail of the compute engine. Rewrites that coalesce partitions
    do not affect comparison results (BR-3.15, BR-3.16).

11. **Parquet type checking catches what CSV cannot.** Test 023 demonstrated schema
    type mismatch detection (int64 vs int32). This is a parquet-only capability —
    CSV has no embedded type metadata. A rewrite that changes a column type is flagged
    even when no data values change (BR-4.12).
