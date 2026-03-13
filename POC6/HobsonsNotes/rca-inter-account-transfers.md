# RCA: inter_account_transfers — Sparse Output

## Problem Statement

The `inter_account_transfers` job produces output on almost no dates:
- **C# output:** 3 parquet files with data (Oct 8, Nov 21, Dec 20) out of 92 run dates, plus 1 stray leftover file.
- **Python output:** 1 parquet file with data (Oct 8) out of 31 run dates.
- Each file that does have data contains exactly 1 row.

## Root Cause: By Design

This is **not a bug**. The sparsity is an artefact of the mock data generation, not a defect in either implementation.

### How the Job Works

1. **DataSourcing** fetches `datalake.transactions` filtered to a single `ifw_effective_date` (the current run date). No lookback, no date range -- just one day's transactions.
2. **InterAccountTransferDetector** (the External module) does an O(n^2) nested-loop match looking for Debit/Credit pairs where:
   - `amount` matches exactly
   - `txn_timestamp` matches exactly
   - `account_id` differs
3. **ParquetFileWriter** writes the output. If the DataFrame is empty (no matches), it creates the date directory but skips writing the parquet file.

### Why Matches Are Extremely Rare

The seed data generates transactions using deterministic `hashtext()` functions:

| Dimension | Value space | Notes |
|-----------|------------|-------|
| `amount` | ~1,781 values | `20 + (hash % 1781)`, rounded to 2dp |
| `txn_timestamp` | ~28,800 values | `as_of::timestamp + (hash % 28800 seconds)` (8hr window) |
| Transactions/day | ~4,300 | ~2,850 debits, ~1,450 credits |
| Distinct amounts/day | ~1,643 | |
| Distinct timestamps/day | ~4,020 | |

For a match, two transactions on the **same date** need identical amounts AND identical timestamps AND opposite debit/credit types AND different account IDs. The probability of any single debit-credit pair matching is roughly `1/1781 * 1/28800 ~= 0.00000002`. Even with ~4.1 million candidate pairs per day (~2850 debits x ~1450 credits), the expected matches per day is about 0.08. Over 92 dates, you'd expect ~7 matches total.

The DB confirms exactly 3 dates have a match:

```
 ifw_effective_date | match_count
--------------------+-------------
 2024-10-08         |           1
 2024-11-21         |           1
 2024-12-20         |           1
```

This is within the expected range for a low-probability random process.

### Why Python Has Fewer Dates Than C#

Python only ran October (31 dates). C# ran Oct-Dec (92 dates). The two Nov/Dec matches (Nov 21, Dec 20) fall outside Python's run range. The single October match (Oct 8) appears in both.

### The Stray File

`Output/curated/inter_account_transfers/part-00000.parquet` in the C# tree is a 760-byte leftover from Feb 28. It has 0 rows, all-string column types, and uses the old column name `as_of` instead of `ifw_effective_date`. Artefact from an earlier run; irrelevant.

## Verification

Both implementations produce identical output for Oct 8:

| Field | Value |
|-------|-------|
| debit_txn_id | 46058 |
| credit_txn_id | 46318 |
| ifw_effective_date | 2024-10-08 |

## Conclusion

**No action required.** The job is working correctly on both sides. The mock data simply doesn't contain many coincidental debit/credit pairs with matching amounts and timestamps across different accounts. This is realistic -- genuine inter-account transfers in production data would be explicitly linked, not detected by timestamp/amount collision.

The only discrepancy between C# and Python is the date range (Python hasn't been run for Nov-Dec yet). Once it is, expect matching output on all 3 dates.
