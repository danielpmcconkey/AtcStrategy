# RCA: CSV Comparison Failures — Batch 3 (7 Jobs)

**Date:** 2026-03-11
**Context:** Proofmark comparison failures for date 2024-10-01
**Status:** All 7 root causes identified. Four distinct formatting issues, zero data issues.

---

## Summary

All seven jobs produce **identical data** in both C# and Python. Every failure is a
formatting difference in how values are serialised to CSV. There are no logic
bugs, no sort order problems, no missing or extra rows.

Four root causes cover all seven failures:

| # | Root Cause | Jobs Affected |
|---|-----------|---------------|
| 1 | Timestamp format (`2024-10-01T09:12:00` vs `2024-10-01 09:12:00`) | 1 job |
| 2 | Date format in ifw_effective_date (`2024-10-01T00:00:00` vs `2024-10-01`) | 2 jobs |
| 3 | Integer-as-float formatting (`500` vs `500.0`, `15400` vs `15400.0`) | 6 jobs |
| 4 | Floating-point precision artefact (`91674.98999999999` vs `91674.99`) | 1 job |

Additionally, **executive_dashboard** has a trailer timestamp difference (different run
times), but this is expected and not a bug.

---

## Root Cause 1: Timestamp Separator — `T` vs Space

**Pattern:** C# writes datetime columns with ISO 8601 `T` separator (`2024-10-01T09:12:00`).
Python writes with a space separator (`2024-10-01 09:12:00`). This is Python's default
`datetime.__str__` behaviour.

**Jobs affected:**
- **dans_transaction_details** — `txn_timestamp` column

**Fix:** Format timestamps with `T` separator in Python (e.g., `dt.isoformat()` or
`dt.strftime('%Y-%m-%dT%H:%M:%S')`).

---

## Root Cause 2: Date Column Format — `2024-10-01T00:00:00` vs `2024-10-01`

**Pattern:** C# writes the `ifw_effective_date` column as a full datetime with midnight
timestamp (`2024-10-01T00:00:00`). Python writes it as a date-only string (`2024-10-01`).
This is separate from RC1 because it affects a date (not datetime) column and the C#
value includes an explicit `T00:00:00` suffix that Python omits entirely.

**Jobs affected:**
- **dans_transaction_details** — `ifw_effective_date` column: `2024-10-01T00:00:00` vs `2024-10-01`
- **dans_transactions_by_state_province** — `ifw_effective_date` column: `2024-10-01T00:00:00` vs `2024-10-01`

**Note:** dans_transaction_details has BOTH RC1 and RC2 simultaneously, which is why
only 1 of 4265 lines (the header) matches — every data row has at least the timestamp
and ifw_effective_date differences.

**Fix:** Format `ifw_effective_date` as `yyyy-MM-ddTHH:mm:ss` when the C# reference
uses that format.

---

## Root Cause 3: Integer Values Written as Float

**Pattern:** C# writes whole-number values without a decimal point or with `.00` (two
decimal places). Python writes them with `.0` suffix (one decimal place — Python's
default `float.__str__`). This manifests in two sub-patterns:

- **Sub-pattern A (`.00` vs `.0`):** C# formats money columns to 2 decimal places.
  Python uses default float formatting. Examples: `10822.00` vs `10822.0`,
  `152224.00` vs `152224.0`.
- **Sub-pattern B (no decimal vs `.0`):** C# writes what appear to be integer values
  with no decimal point at all. Python writes them as floats. Examples: `500` vs
  `500.0`, `35` vs `35.0`, `2230` vs `2230.0`.

**Jobs affected:**
- **dans_transaction_details** — `amount` and `current_balance` columns: `500` vs `500.0`, `15400` vs `15400.0`
- **dans_transactions_by_state_province** — `total_amount` column: `189326` vs `189326.0`
- **executive_dashboard** — `metric_value` column (count metrics): `2230` vs `2230.0`, `2869` vs `2869.0`, `4263` vs `4263.0`, `894` vs `894.0`, `244` vs `244.0`
- **fee_revenue_daily** — `charged_fees`, `waived_fees`, `net_revenue` columns: `35` vs `35.0`, `0` vs `0.0`
- **fee_waiver_analysis** — `total_fees`, `avg_fee` columns: `35` vs `35.0`, `0` vs `0.0`
- **high_balance_accounts** — `current_balance` column: `10822.00` vs `10822.0`
- **investment_account_overview** — `current_value` column: `152224.00` vs `152224.0`

**Why match % varies:**
- **high_balance_accounts** (0.4%): Header matches + 1 row with non-`.00` cents (`10875.55`) = 2 of 535 lines.
- **investment_account_overview** (0.2%): Header matches = 1 of 428 lines. All data rows have `.00` values.
- **executive_dashboard** (50%): Header + 4 data rows with already-decimal values (`10429347.73`, `3871936.14`, `908.27`, `114330325.25`) = 5 of 11 lines. But trailer differs too (see below).
- **fee_revenue_daily** (50%): Header matches = 1 of 2 lines.
- **fee_waiver_analysis** (33.3%): Header matches = 1 of 3 lines.

**Fix:** Match C#'s formatting per column. For money columns, use `f"{value:.2f}"`.
For integer-typed columns, cast to `int` before writing.

---

## Root Cause 4: Floating-Point Precision Artefact

**Pattern:** C# writes a sum with a floating-point artefact: `91674.98999999999`.
Python writes the correctly rounded value: `91674.99`. This is the **only** case
where Python is arguably more correct than C#.

**Jobs affected:**
- **dans_transactions_by_state_province** — `total_amount` for MO: `91674.98999999999` vs `91674.99`

**Note:** This is a single row (MO) in a 32-row file. Combined with RC2 and RC3, only
1 of 32 lines matches (the header) — 3.1%.

**Fix:** This one is interesting — C# has the bug. The Python side rounded correctly.
For equivalence testing, either fix the C# side to round, or accept this as a known
deviation in proofmark config.

---

## Trailer Row Difference (executive_dashboard only)

The executive_dashboard has a `SUMMARY` trailer row with a run timestamp:
- C#: `SUMMARY|9|2024-10-01|2026-03-08T17:50:58Z`
- Python: `SUMMARY|9|2024-10-01|2026-03-10T15:01:54Z`

This is expected — the runs happened at different times. The trailer format itself is
correct. Proofmark should (and likely does) exclude trailer rows from comparison, but
this is worth confirming.

---

## Per-Job Detail

### 1. dans_transaction_details — Root Causes 1 + 2 + 3
- **Match:** 0.02% (1 of 4265 lines — header only)
- **Differences:**
  - `txn_timestamp`: `2024-10-01T09:12:00` vs `2024-10-01 09:12:00` (RC1)
  - `ifw_effective_date`: `2024-10-01T00:00:00` vs `2024-10-01` (RC2)
  - `amount`: `500` vs `500.0` (RC3)
  - `current_balance`: `15400` vs `15400.0` (RC3, on whole-number balances)
- Same rows, same order, same data. Pure formatting.

### 2. dans_transactions_by_state_province — Root Causes 2 + 3 + 4
- **Match:** 3.1% (1 of 32 lines — header only)
- **Differences:**
  - `ifw_effective_date`: `2024-10-01T00:00:00` vs `2024-10-01` (RC2)
  - `total_amount`: `189326` vs `189326.0` (RC3, most rows)
  - `total_amount` for MO: `91674.98999999999` vs `91674.99` (RC4)
- Same rows, same order, same data. Pure formatting.

### 3. executive_dashboard — Root Cause 3 + trailer timestamp
- **Match:** 50% (5 of 10 data-bearing lines)
- **Differences:**
  - `metric_value` for count metrics: `2230` vs `2230.0` (RC3)
  - Trailer timestamp differs (different run times — expected)
- Same rows, same order, same data. Pure formatting.

### 4. fee_revenue_daily — Root Cause 3
- **Match:** 50% (1 of 2 lines — header only)
- **Difference:** `charged_fees`, `waived_fees`, `net_revenue`: `35` vs `35.0`, `0` vs `0.0` (RC3)
- Same row, same data. Pure formatting.

### 5. fee_waiver_analysis — Root Cause 3
- **Match:** 33.3% (1 of 3 lines — header only)
- **Difference:** `total_fees`, `avg_fee`: `35` vs `35.0`, `0` vs `0.0` (RC3)
- Same rows, same order, same data. Pure formatting.

### 6. high_balance_accounts — Root Cause 3
- **Match:** 0.4% (2 of 535 lines — header + 1 row with `10875.55`)
- **Difference:** `current_balance`: `10822.00` vs `10822.0` (RC3, sub-pattern A)
- Same rows, same order, same data. Pure formatting.

### 7. investment_account_overview — Root Cause 3
- **Match:** 0.2% (1 of 428 lines — header only)
- **Difference:** `current_value`: `152224.00` vs `152224.0` (RC3, sub-pattern A)
- Same rows, same order, same data. Pure formatting.

---

## Recommended Fix Priority

Three of the four root causes are Python formatting issues fixable in the CSV writer:

1. **Timestamp `T` separator** (RC1): Use `isoformat()` or explicit `strftime` with `T`.
2. **Date-as-datetime** (RC2): Write `ifw_effective_date` with `T00:00:00` suffix when C# does.
3. **Number formatting** (RC3): Format money columns to `.2f`. Cast integer columns to `int`.
4. **Floating-point artefact** (RC4): This is a C# bug. Either fix C# to round, or
   whitelist the MO row in proofmark.

RC3 is by far the highest-impact fix — it affects 6 of 7 jobs in this batch.
