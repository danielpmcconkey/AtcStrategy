# RCA: CSV Comparison Failures — Batch 5 (6 Jobs)

**Date:** 2026-03-11
**Effective date under test:** 2024-10-01
**Jobs:** overdraft_recovery_rate, top_branches, transaction_category_summary,
transaction_size_buckets, wealth_tier_analysis, weekend_transaction_pattern
**Status:** All root causes identified. Two distinct categories.

---

## Summary

Six Proofmark CSV comparison failures, all for effective date 2024-10-01. Every
failure falls into one of two root cause categories:

| Category | Jobs affected | Count |
|----------|--------------|-------|
| **Numeric formatting: trailing-zero suppression** | overdraft_recovery_rate, transaction_category_summary, transaction_size_buckets, wealth_tier_analysis, weekend_transaction_pattern | 5 |
| **CONTROL row timestamp** | top_branches | 1 |

There are **zero data differences**. Every row contains identical values on both
sides. The failures are entirely formatting artifacts.

---

## Root Cause 1: Trailing-Zero Suppression (5 jobs)

### Pattern

C# formats decimal values by dropping trailing zeros after the decimal point.
A value of exactly `1263665.00` renders as `1263665`. A value of `20653.20`
renders as `20653.20` (the trailing zero is kept because .2 != .20 in C#'s
default ToString).

Python's default CSV writer (via pandas `to_csv`) preserves the full float
representation, so `1263665.0` keeps its `.0` suffix.

The mismatch appears in every case where a monetary/rate column has a value
that is an exact integer or ends in zero:

### Per-job specifics

**overdraft_recovery_rate** (50% match — 1 of 2 data rows differs)
- C# row 2: `recovery_rate` = `0`
- Python row 2: `recovery_rate` = `0.0000`
- C# outputs bare `0`, Python outputs `0.0000` (4 decimal places). This is
  a more extreme variant — C# strips the entire decimal portion; Python pads
  to 4 places (likely a Decimal type with scale=4 in the source query).

**transaction_category_summary** (66.7% match — 1 of 2 data rows differs)
- C# row 2 (Credit): `total_amount` = `1263665`
- Python row 2 (Credit): `total_amount` = `1263665.0`
- The Debit row matches because its value `2608271.14` has significant
  trailing digits.

**transaction_size_buckets** (50% match — 3 of 5 data rows differ)
- Rows `0-25`, `1000+`, `500-1000` differ in `total_amount`:
  - `247` vs `247.0`
  - `2675608` vs `2675608.0`
  - `894386` vs `894386.0`
- Rows `100-500` and `25-100` match because their values (`289998.5`,
  `11696.64`) already have significant fractional parts.

**wealth_tier_analysis** (60% match — 2 of 5 data rows differ)
- Silver row: `avg_wealth` = `20653.20` (C#) vs `20653.2` (Python)
- Platinum row: `total_wealth` = `2018927.00` (C#) vs `2018927.0` (Python)
- Here the direction is reversed from the other jobs: C# *preserves*
  trailing zeros (`.20`, `.00`) while Python strips them (`.2`, `.0`).
  This is consistent with C# using a fixed-format Decimal type for these
  columns and Python using standard float representation.

**weekend_transaction_pattern** (66.7% match — 1 of 2 data rows differs)
- Weekend row: `total_amount` = `0` (C#) vs `0.0` (Python);
  `avg_amount` = `0` (C#) vs `0.0` (Python)
- The Weekday row matches because its values have significant digits.

### Fix options

1. **Python-side:** Force format strings on decimal columns to match C#'s
   output convention. Would need per-column or per-type formatting rules.
2. **Proofmark-side:** Add a numeric-equivalence comparison mode that parses
   values as numbers before comparing. `0` == `0.0` == `0.0000` would all
   match. This is the cleaner fix since the data is identical.
3. **Both sides:** Standardise on a formatting convention (e.g., always 2
   decimal places for monetary values, always 4 for rates).

---

## Root Cause 2: CONTROL Row Timestamp (1 job)

### Pattern

**top_branches** (100% row match but FAIL)

All 40 data rows are byte-identical. The only difference is the CONTROL
(trailer) row:

```
C#:     CONTROL|2024-10-01|40|2026-03-08T17:52:27Z
Python: CONTROL|2024-10-01|40|2026-03-10T15:06:09Z
```

The CONTROL row includes an ETL execution timestamp (ISO 8601). Since C# and
Python ran on different dates, the timestamps differ. The row count (`40`) and
effective date (`2024-10-01`) are identical.

### Fix options

1. **Proofmark-side:** Exclude CONTROL/TRAILER rows from comparison, or mask
   the timestamp field. This is the correct fix — execution timestamps are
   metadata, not data.
2. **Alternatively:** Strip the timestamp from the CONTROL row format in both
   implementations (only emit `CONTROL|date|count`).

---

## Disposition

No code bugs. No data discrepancies. All six failures are comparison-tooling
issues:

- 5 jobs need numeric-equivalence comparison (or consistent formatting)
- 1 job needs CONTROL row timestamp masking (or exclusion)

Both are Proofmark enhancement candidates rather than ETL fixes, though
standardising the Python output formatting would also resolve the numeric
cases.
