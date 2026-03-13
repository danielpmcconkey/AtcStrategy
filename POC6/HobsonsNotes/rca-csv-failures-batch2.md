# RCA: CSV Comparison Failures -- Batch 2

**Date:** 2026-03-11
**Run date:** 2024-10-01
**Analyst:** Hobson

---

## Summary

Seven jobs investigated. Three distinct root causes identified. None represent
logic errors in the Python rewrite -- all are formatting/serialisation
differences between C# and Python output.

After normalising for these formatting differences, every job produces
**identical data in identical order**. Zero data/logic discrepancies.

---

## Root Cause Categories

### RC-1: Trailing-Zero Formatting on Numeric Fields (5 jobs)

**Pattern:** Python's `float.__str__` always emits at least one decimal digit
(`500.0`, `220.0`, `-220.0`), while C# drops the decimal portion entirely for
integer-valued numbers (`500`, `220`, `-220`). For non-integer values both
agree (e.g. `142.5` / `142.5`).

This is the same root cause as Batch 1 RC-1 -- the Python `float` vs C#
`decimal`/`int` serialisation mismatch. The direction is consistent: Python
adds `.0` where C# writes bare integers.

**Affected jobs:**

| Job | Differing rows | Total data rows | Notes |
|-----|---------------|-----------------|-------|
| customer_transaction_activity | 2004 / 2006 | 2006 | `total_amount` column |
| customer_value_score | 447 / 2230 | 2230 | `balance_score`, `composite_score` -- only rows where a score lands on .X0 |
| daily_balance_movement | 2489 / 2489 | 2489 | `debit_total`, `credit_total`, `net_movement` |
| daily_transaction_summary | 2489 / 2489 | 2489 | `total_amount`, `debit_total`, `credit_total` |
| daily_wire_volume | 92 / 92 | 92 | `total_amount` (all integer wire amounts) |

**Why customer_value_score is 80% match while others are near 0%:**
The score columns are already decimal (e.g. `3.54`, `-0.74`), so only
the ~20% of rows where a score happens to end in a trailing zero
(e.g. C# `1.60` vs Python `1.6`, or C# `30.00` vs Python `30.0`)
produce a mismatch. The other jobs have currency/amount columns where
most values are round numbers, so nearly every row differs.

### RC-2: Date-Time Formatting with Unicode Narrow No-Break Space (1 job)

**Pattern:** The `birthdate` column in `customer_demographics` is formatted as
a US-style date. C# emits the full DateTime string including a time component:
`1/12/1954 12:00:00`**\u202f**`AM` (note: the space before "AM" is U+202F,
a narrow no-break space, not ASCII 0x20). Python emits date-only: `1/12/1954`.

This affects every data row (2230/2230). The header row matches.

**Affected jobs:**

| Job | Differing rows | Total data rows |
|-----|---------------|-----------------|
| customer_demographics | 2230 / 2230 | 2230 |

### RC-3: CONTROL Row Timestamp (1 job)

**Pattern:** `daily_transaction_volume` has 100% data match (both data rows are
byte-identical). The only difference is the CONTROL trailer row, which contains
an ETL execution timestamp:

- C#: `CONTROL|2024-10-01|1|2026-03-08T17:51:56Z`
- Python: `CONTROL|2024-10-01|1|2026-03-10T14:54:48Z`

This is expected -- the timestamp reflects when each system ran, not business
data. Proofmark should either ignore CONTROL/TRAILER rows or compare only the
non-timestamp fields.

**Affected jobs:**

| Job | Differing rows | Total data rows |
|-----|---------------|-----------------|
| daily_transaction_volume | 0 / 1 | 1 (plus header + CONTROL) |

---

## Remediation Options

All three root causes can be resolved in one of two places:

1. **In the Python writer** -- format numeric output to match C# conventions
   (strip trailing `.0` from integer-valued floats; include `12:00:00 AM` on
   date-only fields). This makes the Python output byte-identical to C#.

2. **In Proofmark** -- add a normalisation pass before comparison:
   - Numeric: treat `500` and `500.0` as equivalent.
   - Date: treat `1/12/1954` and `1/12/1954 12:00:00 AM` as equivalent.
   - CONTROL/TRAILER rows: compare non-timestamp fields only, or skip entirely.

Option 2 is arguably the better long-term call. The Python output is not
*wrong* -- it's just *different*. Proofmark's job is to verify data
equivalence, not byte-identity.

---

## Cross-Reference

- **RC-1** is the same root cause as Batch 1 RC-1.
- **RC-2** is new to this batch (no date columns appeared in Batch 1 jobs).
- **RC-3** is new to this batch (Batch 1 didn't include jobs with CONTROL rows,
  or they happened to run at the same time).
