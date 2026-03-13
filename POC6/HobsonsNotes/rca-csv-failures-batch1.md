# RCA: CSV Comparison Failures -- Batch 1

**Date:** 2026-03-11
**Run date:** 2024-10-01
**Analyst:** Hobson

---

## Summary

Seven jobs investigated. Five distinct root causes identified. None represent
logic errors in the Python rewrite -- all are formatting/serialisation
differences between C# and Python output.

---

## Root Cause Categories

### RC-1: Decimal Trailing-Zero Suppression (Python `float` vs C# `decimal`)

**Pattern:** C# writes `140839.90`, `3545.00`, `-1450`; Python writes
`140839.9`, `3545.0`, `-1450.0`. C# preserves the scale from PostgreSQL
`numeric`/`money` types (2 decimal places for currency), while Python's
`float` or `Decimal.__str__` strips insignificant trailing zeros -- except it
always keeps at least one decimal digit (so `0` becomes `0.0`).

The inconsistency runs both ways: C# sometimes drops the decimal entirely for
round numbers (`-1450`, `3545`, `125`) while Python always shows `.0`. For
non-round numbers, C# keeps the source precision (`140839.90`) while Python
strips it (`140839.9`).

**Affected jobs:**
| Job | Differing rows | Total rows | Root causes combined |
|-----|---------------|------------|---------------------|
| customer_account_summary | 2211/2230 | 2231 | RC-1 only |
| customer_compliance_risk | 2230/2230 | 2231 | RC-1 only |
| customer_credit_summary | 2222/2230 | 2231 | RC-1 + RC-2 |
| account_velocity_tracking | 2489/2489 | 2490 (Python) | RC-1 + RC-3 + RC-4 |

### RC-2: High-Precision Decimal Digit Count (PostgreSQL `numeric` scale)

**Pattern:** The `avg_score` / `avg_credit_score` column comes from a
PostgreSQL `AVG()` over integers, producing a `numeric` with up to 28
significant digits. C# preserves the full database scale (25 or 26 decimal
places), while Python consistently outputs 25 decimal places.

Example:
- C#:     `782.33333333333333333333333333` (26 decimal places)
- Python: `782.3333333333333333333333333` (25 decimal places)

C# itself is inconsistent: 1,224 rows have 26 decimal places, 235 have 25.
Python always has 25. The values are numerically equivalent to at least 25
significant digits; the last digit is a rounding artefact of the database
driver or serialiser.

**Affected jobs:**
| Job | Differing rows (this cause) | Total rows |
|-----|----------------------------|------------|
| credit_score_average | 1638/2230 | 2231 |
| customer_credit_summary | ~2222/2230 | 2231 |

### RC-3: Date Format -- `M/d/yyyy` vs `yyyy-MM-dd`

**Pattern:** The `txn_date` column in account_velocity_tracking uses
`10/1/2024` (C# / US short-date) vs `2024-10-01` (Python / ISO-8601).

**Affected jobs:**
- account_velocity_tracking (every row)

### RC-4: Concatenated Output File (C# file corrupted)

**Pattern:** The C# output file for account_velocity_tracking contains 4,980
lines -- exactly double the expected 2,490. Lines 1-2490 are the original C#
output; line 2491 is a second header row, followed by the complete Python
output (2,489 data rows). The Python output was appended to the C# file,
likely during a test run that wrote to the wrong location.

The Python standalone file (2,490 lines) is clean.

**Affected jobs:**
- account_velocity_tracking (C# file only)

**Action:** The C# file needs to be regenerated or truncated to 2,490 lines
before re-running Proofmark. Even after that, RC-1 and RC-3 will still cause
mismatches.

### RC-5: Timestamp Format -- `T` separator vs space

**Pattern:** The `visit_timestamp` column uses ISO-8601 with `T` separator in
C# (`2024-10-01T10:42:29`) vs space separator in Python
(`2024-10-01 10:42:29`). Every row differs.

**Affected jobs:**
- branch_visits_by_customer (59/59 data rows = 100% mismatch on this column)

### RC-6: Randomised Phone Numbers (Actual Data Difference)

**Pattern:** The `phone` column in communication_channel_map has different
phone numbers between C# and Python for ~323 of 2,230 customers (14.5%).
Names, emails, and all other fields match. The area codes differ
(`(847) 555-1348` vs `(829) 555-4948`), suggesting the phone number is
randomly generated at ETL time with a different seed or no seed.

This is the only genuine data difference in the batch. All other failures are
formatting.

**Affected jobs:**
- communication_channel_map (323/2230 data rows)

---

## Per-Job Summary

| # | Job | Match% | Root Causes | Fix Category |
|---|-----|--------|-------------|-------------|
| 1 | account_velocity_tracking | 66.7% | RC-1, RC-3, RC-4 | Corrupted C# file + formatting |
| 2 | branch_visits_by_customer | 1.7% | RC-5 | Timestamp format |
| 3 | communication_channel_map | 85.5% | RC-6 | Random data (phone numbers) |
| 4 | credit_score_average | 45.1% | RC-2 | Decimal precision |
| 5 | customer_account_summary | 0.9% | RC-1 | Trailing-zero formatting |
| 6 | customer_compliance_risk | 0.04% | RC-1 | Trailing-zero formatting |
| 7 | customer_credit_summary | 0.4% | RC-1, RC-2 | Trailing zeros + decimal precision |

---

## Recommended Fixes (Priority Order)

1. **RC-4 (corrupted file):** Regenerate the C# account_velocity_tracking
   output, or truncate the existing file to its first 2,490 lines.

2. **RC-1 (trailing zeros):** Standardise numeric formatting in the Python
   CSV writer. Match C#'s behaviour: preserve source scale for
   non-integer decimals, drop `.00` for whole numbers. Alternatively, add a
   normalisation pass to Proofmark that strips insignificant trailing zeros
   before comparison.

3. **RC-2 (decimal precision):** Either truncate to 25 decimal places on
   both sides, or handle in Proofmark with a configurable numeric tolerance.
   The values are mathematically equivalent.

4. **RC-3 (date format):** Change Python's `txn_date` serialisation from
   `yyyy-MM-dd` to `M/d/yyyy` to match C#, or vice versa.

5. **RC-5 (timestamp separator):** Change Python to emit `T` between date
   and time, or change C# to emit a space. One line fix.

6. **RC-6 (random phone numbers):** Seed the random number generator
   identically in both implementations, or accept this as a known
   non-deterministic field and exclude the phone column from comparison.
