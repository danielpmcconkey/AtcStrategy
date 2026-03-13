# RCA: overdraft_amount_distribution Output Gaps

## Summary

The irregular date gaps are **not a bug**. Both C# and Python produce output only for dates that have rows in `datalake.overdraft_events`. Dates with no overdraft activity produce no output file. The gaps are a faithful reflection of the underlying data.

## Root Cause

### Data flow

1. Job config (`overdraft_amount_distribution.json`, identical on both sides) defines two modules:
   - **DataSourcing**: queries `datalake.overdraft_events` filtered to `ifw_effective_date = <run_date>`
   - **External**: `OverdraftAmountDistributionProcessor` — buckets overdraft amounts and writes CSV

2. DataSourcing has no `lookbackDays`, `mostRecentPrior`, `mostRecent`, or static date overrides. It falls through to the default path where both min and max resolve to `__etlEffectiveDate` (the single run date). This means it queries for **exactly one date** per execution.

3. Both processors have an early-return guard:
   - **Python** (line 31): `if overdraft_events is None or overdraft_events.empty:` — sets empty DataFrame, returns. No CSV written.
   - **C#** (line 37): `if (overdraftEvents == null || overdraftEvents.Count == 0)` — same behaviour.

4. When the query returns rows, the processor writes a CSV to `Output/curated/overdraft_amount_distribution/overdraft_amount_distribution/{date}/`. When it returns nothing, no file is created.

### The data confirms it

```
datalake.overdraft_events — October 2024
  Dates with data: 20 of 31
  Missing: Oct 4, 6, 8, 11, 17, 18, 20, 21, 23, 28, 31

datalake.overdraft_events — Oct-Dec 2024
  Dates with data: 69 of 92
```

These counts match exactly:
- Python output: 20 date folders (Oct only — Python was run for October only)
- C# output: 69 date folders (Oct-Dec — C# was run for the full Q4 range)

The "irregular gaps with no clear weekday/weekend pattern" is simply the random distribution of overdraft events in the mock datalake. Some days had overdrafts, some didn't.

## Verification

```sql
-- Dates with overdraft events in October
SELECT ifw_effective_date, COUNT(*) FROM datalake.overdraft_events
WHERE ifw_effective_date BETWEEN '2024-10-01' AND '2024-10-31'
GROUP BY 1 ORDER BY 1;
-- Returns exactly 20 rows, matching the 20 output dates

-- Total distinct dates Oct-Dec
SELECT COUNT(DISTINCT ifw_effective_date) FROM datalake.overdraft_events
WHERE ifw_effective_date BETWEEN '2024-10-01' AND '2024-12-31';
-- Returns 69, matching the 69 C# output dates
```

## Implications for Proofmark

This is **expected sparse output**. The comparison should be done only over dates where both sides were run (Oct 2024). On those dates, both sides should produce identical output since the processor logic is equivalent. Missing dates are not failures — they are correct "no data, no output" behaviour.

## Files Examined

- Job config: `JobExecutor/Jobs/overdraft_amount_distribution.json` (identical both sides)
- Python processor: `MockEtlFrameworkPython/src/etl/modules/externals/overdraft_amount_distribution_processor.py`
- C# processor: `MockEtlFramework/ExternalModules/OverdraftAmountDistributionProcessor.cs`
- Python DataSourcing: `MockEtlFrameworkPython/src/etl/modules/data_sourcing.py`
- C# DataSourcing: `MockEtlFramework/Lib/Modules/DataSourcing.cs`
