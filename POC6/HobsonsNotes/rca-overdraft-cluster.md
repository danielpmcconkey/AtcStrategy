# RCA: Overdraft Cluster Sparse Output Pattern

**Date:** 2026-03-11
**Jobs:** account_overdraft_history, overdraft_by_account_type, overdraft_customer_profile
**Status:** Root cause identified. No code bug -- data availability mismatch.

---

## Summary

All three jobs share the same 14 Python output dates because the underlying
`datalake.overdraft_events` table only has data on those 14 weekdays in October.
The sparse hash-based seeding (`% 600 = 0`) produces events on only 20 of 31
October days, and 6 of those 20 fall on weekends where the required join tables
(`accounts`, `customers`) have no data. 20 minus 6 = 14.

The C# output shows 51 dates across Q4 for the same reason: 69 total overdraft
event dates minus 18 weekends = 51 weekday dates with both overdraft events AND
supporting dimension data.

All three jobs have **identical** data-date sets on both sides. There is no
difference between them.

---

## Root Cause: Weekend Gap in Dimension Tables

### Data availability matrix

| Table              | Loaded on | Oct dates | Q4 dates |
|--------------------|-----------|-----------|----------|
| overdraft_events   | All 7 days (calendar) | 20 of 31 (sparse hash) | 69 of 92 |
| accounts           | Weekdays only         | 23 of 31              | 66 of 92 |
| customers          | Weekdays only         | 23 of 31              | 66 of 92 |

The seed script (`SeedExpansion_NewTables.sql`) crosses `tmp_checking_accounts`
with `tmp_q4_all` (all 92 calendar days) for `overdraft_events`, but `accounts`
and `customers` use `tmp_q4_wd` / `tmp_oct_wd` (weekdays only).

### What happens on a weekend effective date

1. **DataSourcing** fetches `overdraft_events` for that date -- may return rows
   (e.g., Oct 5 has 1 event).
2. **DataSourcing** fetches `accounts` for that same date -- returns **zero
   rows** because accounts is weekday-only.
3. Each job fails at the join/lookup/empty-check:
   - **account_overdraft_history:** SQL `JOIN accounts a ON ... AND
     oe.ifw_effective_date = a.ifw_effective_date` returns zero rows (no
     matching accounts row).
   - **overdraft_by_account_type:** Early exit `if accounts.empty` triggers.
   - **overdraft_customer_profile:** Early exit `if customers.empty` triggers.
     (The W2 weekend-fallback logic is also structurally broken -- see below.)
4. **ParquetFileWriter** receives an empty DataFrame, creates the date
   directory, writes zero parquet files.

### What happens on a weekday with no overdraft events

Same as above but inverted: `accounts` has data, `overdraft_events` is empty.
The early-exit or empty-join produces zero rows. The writer creates the
directory with no files.

### Net result

Output = intersection of {dates with overdraft events} AND {weekdays}.

- **October (Python):** 20 event dates AND 23 weekdays = **14 output dates**
- **Q4 (C#):** 69 event dates AND 66 weekdays = **51 output dates**

---

## Correction to the Problem Statement

The original framing stated C# `account_overdraft_history` has "92 dates (full),
50 parts/date". This is directories, not data. All three C# jobs create 92 date
directories (one per calendar day in Q4) but write parquet files in only 51 of
them. The three C# jobs have identical data-date sets. Same for Python: 31
directories, 14 with data.

---

## Aside: W2 Weekend Fallback in overdraft_customer_profile Is Broken

The `OverdraftCustomerProfileProcessor` implements a W2 weekend fallback
(shift Saturday/Sunday to preceding Friday). However, it operates **after**
DataSourcing has already narrowed `overdraft_events` to the current effective
date.

On a Saturday:
1. DataSourcing fetches `overdraft_events WHERE ifw_effective_date = Saturday`
2. Processor sets `target_date = Friday`
3. Processor filters `overdraft_events["ifw_effective_date"] == Friday` --
   finds zero matches because the sourced data only contains Saturday rows
4. Returns empty output

The fallback would need the DataSourcing step to also shift its date query,
or the processor would need access to a wider date range. As implemented, it
does nothing useful. This is consistent across both C# and Python (the C#
processor has the same structural issue).

In practice this is moot because `customers` is also weekday-only, so the
early-exit triggers before the W2 logic ever matters. But if the data model
were fixed to include weekend customers, the W2 bug would surface.

---

## Common Upstream Dependency

The linking factor is trivial: all three jobs source from
`datalake.overdraft_events` and join against weekday-only dimension tables
(`accounts` and/or `customers`). The sparse output is not a bug in any job
logic -- it is the inevitable consequence of the data seeding strategy.

### File references

- Seed script: `MockEtlFramework/SQL/SeedExpansion_NewTables.sql` (line 579, `% 600 = 0` filter)
- Python data sourcing: `MockEtlFrameworkPython/src/etl/modules/data_sourcing.py`
- Python processors:
  - `MockEtlFrameworkPython/src/etl/modules/externals/overdraft_by_account_type_processor.py`
  - `MockEtlFrameworkPython/src/etl/modules/externals/overdraft_customer_profile_processor.py`
- C# processors:
  - `MockEtlFramework/ExternalModules/OverdraftByAccountTypeProcessor.cs`
  - `MockEtlFramework/ExternalModules/OverdraftCustomerProfileProcessor.cs`
- Job configs (identical on both sides):
  - `JobExecutor/Jobs/account_overdraft_history.json`
  - `JobExecutor/Jobs/overdraft_by_account_type.json`
  - `JobExecutor/Jobs/overdraft_customer_profile.json`
