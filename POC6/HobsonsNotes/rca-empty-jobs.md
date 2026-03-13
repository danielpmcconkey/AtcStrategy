# RCA: repeat_overdraft_customers and suspicious_wire_flags — Empty Output

**Date:** 2026-03-11
**Investigator:** Hobson

## Symptom

Both jobs create date-partitioned directory scaffolding but never write any
Parquet data files into those directories:

| Job | Python | C# |
|---|---|---|
| repeat_overdraft_customers | 31 date dirs, all empty | 92 date dirs, all empty, 1 stray top-level parquet |
| suspicious_wire_flags | 31 date dirs, all empty | 92 date dirs, all empty, 1 stray top-level parquet |

The stray top-level `part-00000.parquet` files in the C# output are 0-row
artefacts with an `as_of` column (not `ifw_effective_date`), likely from an
early test run or code-gen pass. They are unrelated to the main failure.

## Root Cause

**Both jobs share the same compound failure: single-day data sourcing combined
with filter criteria the seed data can never satisfy on a single day.**

### Mechanism (identical on both frameworks)

1. Neither job config specifies a date mode (`lookbackDays`, `mostRecent`,
   `mostRecentPrior`, or static dates). The `DataSourcing` module therefore
   falls back to `__etlEffectiveDate` for both min and max, producing a
   single-day query:
   ```sql
   WHERE ifw_effective_date >= '{date}' AND ifw_effective_date <= '{date}'
   ```

2. The `ParquetFileWriter` calls `Directory.CreateDirectory()` / `os.makedirs()`
   **before** the empty-row check, so a date-partitioned directory is created on
   every run regardless of whether any rows will be written.

3. The External processor then applies a filter that the single-day data can
   never satisfy:

### repeat_overdraft_customers

**Intent:** Flag customers with 2+ overdraft events (repeat offenders).

**Why it fails:** The seed data (`SeedExpansion_NewTables.sql`, Section 8)
generates overdraft events at ~0.17% per checking account per day
(`hash % 600 = 0`). This produces 1-4 events per day across all ~700 checking
accounts, with at most **1 event per account per day**. The processor filters
for `count >= 2` per customer, but no customer ever has two overdraft events on
the same calendar day.

Across the full Q4 date range, 10+ customers do accumulate 2+ overdrafts.
The job would work if it used `lookbackDays` or a wider date window.

**DB evidence:**
```
-- Customers with 2+ overdrafts on the same day: 0
-- Customers with 2+ overdrafts across all Q4 dates: 10+
```

### suspicious_wire_flags

**Intent:** Flag wire transfers with offshore counterparties or high amounts
(> $50,000).

**Why it fails:** Two independent data-generation problems make the filter
criteria impossible to satisfy regardless of date windowing:

1. **No "OFFSHORE" counterparty exists.** The seed data (`SeedExpansion_NewTables.sql`,
   Section 5) draws counterparty names from a hardcoded array of 20 US domestic
   business names (Global Trading Corp, Pacific Holdings LLC, etc.). None
   contain the string "OFFSHORE". The `OFFSHORE_COUNTERPARTY` flag path can
   never trigger.

2. **No amount exceeds $50,000.** The seed formula is
   `1000 + (hash & 2147483647) % 49001`, producing amounts in the range
   $1,000 to $50,000 inclusive. The processor checks `amount > 50000` (strict
   inequality), so the `HIGH_AMOUNT` flag path can also never trigger.

**DB evidence:**
```
-- Wire transfers matching OFFSHORE: 0
-- Wire transfer max amount: $49,959.00
-- Wire transfers with amount > 50000: 0
```

## Common Failure Mode

Yes. Both jobs share the same structural deficiency:

1. **Single-day data sourcing with no lookback** makes aggregation-style jobs
   (repeat overdraft) impossible when the underlying events are sparse.
2. **Filter criteria that the deterministic seed data can never produce** makes
   detection-style jobs (suspicious wires) impossible on any date window.

The `repeat_overdraft_customers` job could be fixed with a `lookbackDays`
parameter. The `suspicious_wire_flags` job is fundamentally broken against this
seed data and would require either modifying the seed (adding OFFSHORE
counterparties and/or higher amounts) or lowering the thresholds.

## Files Examined

### Job configs (identical on both frameworks)
- `MockEtlFramework/JobExecutor/Jobs/repeat_overdraft_customers.json`
- `MockEtlFramework/JobExecutor/Jobs/suspicious_wire_flags.json`
- `MockEtlFrameworkPython/JobExecutor/Jobs/repeat_overdraft_customers.json`
- `MockEtlFrameworkPython/JobExecutor/Jobs/suspicious_wire_flags.json`

### External processors — C#
- `MockEtlFramework/ExternalModules/RepeatOverdraftCustomerProcessor.cs`
- `MockEtlFramework/ExternalModules/SuspiciousWireFlagProcessor.cs`

### External processors — Python
- `MockEtlFrameworkPython/src/etl/modules/externals/repeat_overdraft_customer_processor.py`
- `MockEtlFrameworkPython/src/etl/modules/externals/suspicious_wire_flag_processor.py`

### Framework modules
- `MockEtlFramework/Lib/Modules/DataSourcing.cs` (date resolution logic)
- `MockEtlFramework/Lib/Modules/ParquetFileWriter.cs` (directory-before-empty-check)
- `MockEtlFrameworkPython/src/etl/modules/data_sourcing.py`
- `MockEtlFrameworkPython/src/etl/modules/parquet_file_writer.py`

### Seed data
- `MockEtlFramework/SQL/SeedExpansion_NewTables.sql` (Sections 5 & 8)
