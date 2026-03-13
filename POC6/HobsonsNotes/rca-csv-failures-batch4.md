# RCA: CSV Comparison Failures — Batch 4 (6 Jobs)

**Date:** 2026-03-11
**Context:** Proofmark comparison failures for date 2024-10-01
**Status:** All 6 root causes identified. Three distinct formatting issues, zero data issues.

---

## Summary

All six jobs produce **identical data** in both C# and Python. Every failure is a
formatting difference in how values are serialised to CSV. There are no logic
bugs, no sort order problems, no missing or extra rows.

Three root causes cover all six failures:

| # | Root Cause | Jobs Affected |
|---|-----------|---------------|
| 1 | Decimal place formatting on floats (`152224.00` vs `152224.0`) | 4 jobs |
| 2 | Date format in data columns (`10/1/2024` vs `2024-10-01`) | 2 jobs |
| 3 | Integer-as-float formatting (`35` vs `35.0`) | 1 job |

---

## Root Cause 1: Decimal Places on Float/Money Columns

**Pattern:** C# writes `.00` (two decimal places). Python writes `.0` (one decimal place, Python's default `float.__str__`).

**Jobs affected:**
- **investment_risk_profile** (428 rows, 0.2% match) — `current_value` column: `152224.00` vs `152224.0`
- **large_wire_report** (35 rows, 2.9% match) — `amount` column: `20012.00` vs `20012.0`
- **monthly_revenue_breakdown** (3 rows, 33.3% match) — `total_revenue` column: `35.00` vs `35.0`
- **overdraft_daily_summary** (2 rows, 50% match) — `total_fees` column: `35.00` vs `35.0`

**Why match % varies:** The header row always matches. For investment_risk_profile, 1 of 428 data rows happened to match (0.2%). For monthly_revenue_breakdown, the header matches = 1 of 3 rows = 33.3%. For overdraft_daily_summary, the header matches = 1 of 2 rows = 50%.

**Fix:** Force Python to format these columns with two decimal places (e.g., `f"{value:.2f}"`), or normalise the C# side to drop trailing zeros. The former is almost certainly correct — C# is the reference output.

---

## Root Cause 2: Date Format in Data Columns

**Pattern:** C# writes dates in `M/d/yyyy` format (`10/1/2024`). Python writes `yyyy-MM-dd` format (`2024-10-01`). This only affects _data_ columns (like `ifw_effective_date` and `event_date`), not the `etl_effective_date` column which is already `yyyy-MM-dd` on both sides.

**Jobs affected:**
- **overdraft_amount_distribution** (2 rows, 0% match) — `ifw_effective_date` column: `10/1/2024` vs `2024-10-01`
- **overdraft_daily_summary** (2 rows, 50% match) — `event_date` AND `ifw_effective_date` columns: `10/1/2024` vs `2024-10-01`

**Note:** overdraft_daily_summary has BOTH root causes 1 and 2 simultaneously (date format + decimal places).

**Why overdraft_amount_distribution is 0%:** The header matches, but there's no trailer row, and both data rows differ in the date column. Actually, there IS a trailer row — so 3 total rows. Header differs? No, headers match. Let me reclarify: the file has header + 2 data rows + trailer = 4 lines. Proofmark reports "2 rows" meaning 2 data rows. 0% of data rows match because every data row has the date format difference.

**Fix:** Python needs to format date columns as `M/d/yyyy` to match C# output, or use whichever format the original C# job specifies.

---

## Root Cause 3: Integer Values Written as Float vs Int

**Pattern:** C# writes whole-number values without a decimal point (`35`, `0`). Python writes them with `.0` suffix (`35.0`, `0.0`). This is distinct from Root Cause 1 — here the C# output has NO decimal point at all, suggesting the source column is integer-typed in C# but gets cast to float in Python.

**Jobs affected:**
- **overdraft_fee_summary** (3 rows, 33.3% match) — `total_fees`, `avg_fee` columns: `35` vs `35.0`, `0` vs `0.0`

**Fix:** Detect integer-valued floats and write without decimal point, or explicitly cast these columns to int before writing.

---

## Per-Job Detail

### 1. investment_risk_profile — Root Cause 1
- **Match:** 0.2% (1 of 428 rows)
- **Difference:** `current_value` column. C#: `152224.00`. Python: `152224.0`.
- Same rows, same order, same data. Pure formatting.

### 2. large_wire_report — Root Cause 1
- **Match:** 2.9% (1 of 35 rows)
- **Difference:** `amount` column. C#: `20012.00`. Python: `20012.0`.
- Same rows, same order, same data. Pure formatting.

### 3. monthly_revenue_breakdown — Root Cause 1
- **Match:** 33.3% (1 of 3 rows)
- **Difference:** `total_revenue` column. C#: `35.00`. Python: `35.0`.
- Same rows, same order, same data. Pure formatting.

### 4. overdraft_amount_distribution — Root Cause 2
- **Match:** 0% (0 of 2 rows)
- **Difference:** `ifw_effective_date` column. C#: `10/1/2024`. Python: `2024-10-01`.
- Same rows, same order, same data. Pure formatting.

### 5. overdraft_daily_summary — Root Causes 1 + 2
- **Match:** 50% (1 of 2 rows)
- **Differences:**
  - `event_date`: C# `10/1/2024` vs Python `2024-10-01`
  - `ifw_effective_date`: C# `10/1/2024` vs Python `2024-10-01`
  - `total_fees`: C# `35.00` vs Python `35.0`
- Header row matches. Trailer row matches. Single data row has both issues.

### 6. overdraft_fee_summary — Root Cause 3
- **Match:** 33.3% (1 of 3 rows)
- **Difference:** `total_fees` and `avg_fee` columns. C#: `35` / `0`. Python: `35.0` / `0.0`.
- Same rows, same order, same data. Pure formatting.

---

## Recommended Fix Priority

All three root causes can likely be addressed in the Python CSV writer layer rather
than in individual job logic:

1. **Float formatting** (RC1): Format money/decimal columns to 2 decimal places.
2. **Date formatting** (RC2): Format date columns as `M/d/yyyy` where C# uses that format.
3. **Int-as-float** (RC3): Detect and write integer-valued numbers without decimal point.

A single pass through the C# reference output to catalogue column types and formats
would let the Python writer match automatically.
