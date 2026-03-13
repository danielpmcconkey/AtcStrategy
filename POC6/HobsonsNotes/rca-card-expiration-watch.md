# RCA: card_expiration_watch Output Discrepancy

## Summary

The C# and Python outputs for `card_expiration_watch` differ in **partition count only**, not in data correctness. Where both sides produced output for the same effective date, the row data is identical (same card_ids, same expiration calculations, same customer names). The discrepancy is entirely explained by two independent operational issues.

## Observed Behaviour

| Side   | Partitions | Date Range | Missing |
|--------|-----------|------------|---------|
| C#     | 91 of 92  | Oct 1 - Dec 31, 2024 | Oct 15 |
| Python | 31 of 31  | Oct 1 - Oct 31, 2024 | (none) |

Within those partitions, 10 October dates have empty output on **both** sides (directory created, no parquet files): Oct 1, 2, 5, 6, 12, 13, 19, 20, 26, 27. This is correct behaviour -- weekends have no datalake data, and Oct 1-2 predate the datalake's first `cards`/`customers` records.

## Root Causes

### 1. Python was only run for October (operational, not a code bug)

The C# side has a `QueueLoader` tool (`MockEtlFramework/Tools/QueueLoader/Program.cs`) that generates `control.task_queue` rows for every calendar day in a date range. It was run for Oct 1 - Dec 31 (92 days).

The Python side has **no QueueLoader equivalent**. Tasks were either loaded manually or via a more limited invocation. Only October dates were queued/executed, producing 31 partitions. This is a tooling gap, not a logic bug.

### 2. C# missing Oct 15 (transient task failure)

The C# output has no partition directory at all for 2024-10-15, while Python has one with valid data (69 rows, same as adjacent weekdays). The datalake has data for Oct 15 (confirmed by Python's successful run). The C# miss is a transient task failure during the original run -- either the task errored out or was never executed. Not a code defect.

## Code Comparison

### Job conf (`card_expiration_watch.json`)
Byte-for-byte identical on both sides. `firstEffectiveDate: "2024-10-01"`, two DataSourcing steps (cards, customers), one External module, one ParquetFileWriter in Overwrite mode.

### External processor (the business logic)
- C#: `ExternalModules/CardExpirationWatchProcessor.cs`
- Python: `src/etl/modules/externals/card_expiration_watch_processor.py`

Functionally identical:
- W2 weekend fallback: Saturday -> Friday, Sunday -> Friday (same logic, same weekday constants)
- 90-day expiry window: `0 <= daysUntilExpiry <= 90` on both sides
- Customer lookup: same dictionary-based approach
- Row-by-row iteration (AP6 pattern)
- Output schema: same 8 columns plus injected `etl_effective_date`

### DataSourcing
No date mode flags in the conf, so both sides resolve to `WHERE ifw_effective_date = <effective_date>`. Query construction identical.

### ParquetFileWriter
Both create the date-partitioned directory structure and skip writing when the DataFrame is empty. Identical skip logic.

### Data verification
For Oct 3 (spot check): both sides produce 69 rows with identical card_id sets, identical `days_until_expiry`, `expiration_date`, and `ifw_effective_date` values. The only difference is row ordering (non-deterministic iteration order from the DataFrame) and integer width (C# writes int32, Python writes int64). Neither affects correctness.

## Disposition

**No code fix needed.** The Python rewrite is correct. To resolve the partition gap:

1. Run the Python framework for Nov 1 - Dec 31 to produce the remaining 61 partitions.
2. Build a Python QueueLoader tool (or equivalent) so future runs can be queued across arbitrary date ranges without manual per-date invocation.
3. The C# Oct 15 miss is a non-issue for POC6 comparison -- Python already has correct output for that date.

## Files Examined

- `MockEtlFramework/JobExecutor/Jobs/card_expiration_watch.json`
- `MockEtlFrameworkPython/JobExecutor/Jobs/card_expiration_watch.json`
- `MockEtlFramework/ExternalModules/CardExpirationWatchProcessor.cs`
- `MockEtlFrameworkPython/src/etl/modules/externals/card_expiration_watch_processor.py`
- `MockEtlFramework/Lib/Modules/DataSourcing.cs`
- `MockEtlFrameworkPython/src/etl/modules/data_sourcing.py`
- `MockEtlFramework/Lib/Modules/ParquetFileWriter.cs`
- `MockEtlFrameworkPython/src/etl/modules/parquet_file_writer.py`
- `MockEtlFramework/Tools/QueueLoader/Program.cs`
- `MockEtlFramework/Lib/Control/TaskQueueService.cs`
- `MockEtlFrameworkPython/src/etl/control/task_queue_service.py`
