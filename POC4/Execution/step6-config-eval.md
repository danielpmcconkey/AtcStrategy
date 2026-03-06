# Step 6 — V1 Job Config Compatibility Evaluation

**Date:** 2026-03-06
**Evaluator:** Basement Dweller
**Scope:** All 104 V1 job configs in `MockEtlFramework/JobExecutor/Jobs/` (excluding `_v2.json` files)
**DB query:** `control.jobs WHERE job_id < 200 OR job_id IN (369, 371)` — 104 jobs

---

## 1. Summary

- **104 V1 configs evaluated**
- **0 configs will break** due to framework changes in Steps 4-5
- All configs have already been migrated to use `CsvFileWriter`/`ParquetFileWriter` (no remaining `DataFrameWriter` references)
- All configs include `writeMode`, `outputDirectory`, `jobDirName`, and `fileName` where applicable
- All configs have `firstEffectiveDate`

The Steps 4-5 framework changes are **fully backward compatible** with the current V1 configs.

---

## 2. Framework Change Impact Analysis

### 2.1 Date-partitioned output paths
- **Change:** `CsvFileWriter` writes to `{outputDirectory}/{jobDirName}/{etl_effective_date}/{fileName}` instead of flat paths
- **Impact on V1:** No breakage. All 96 configs with file writers specify `outputDirectory: "Output/poc4"`, `jobDirName`, and `fileName`. The date partition is injected automatically by the writer — no config change needed.
- **Note:** The 8 External self-writing jobs still write to `Output/curated/` via their own hardcoded paths. This is an intentional anti-pattern, not a breakage.

### 2.2 WriteMode (Overwrite/Append) — REQUIRED field
- **Change:** `ModuleFactory.CreateCsvFileWriter()` and `CreateParquetFileWriter()` call `el.GetProperty("writeMode")`, which throws if the field is missing.
- **Impact on V1:** No breakage. All 96 configs with `CsvFileWriter` or `ParquetFileWriter` already include `writeMode`. Verified programmatically across all 104 files.
- **Potential risk if a new config is added without writeMode:** It would throw `KeyNotFoundException`. The factory does NOT provide a default — `writeMode` is effectively required.

### 2.3 etl_effective_date column injection
- **Change:** `CsvFileWriter` and `ParquetFileWriter` now inject an `etl_effective_date` column into every row before writing.
- **Impact on V1:** No breakage. This adds a column to output files that wasn't there before, but it doesn't interfere with the pipeline. It's additive.
- **Note:** This means V1 output in `Output/poc4/` will have `etl_effective_date` as an extra column. This is by design for POC4.

### 2.4 `__etlEffectiveDate` shared-state injection
- **Change:** `JobExecutorService` injects `__etlEffectiveDate` into `initialState` before running the pipeline.
- **Impact on V1:** No breakage. `DataSourcing` falls back to `__etlEffectiveDate` when no `minEffectiveDate`/`maxEffectiveDate` is specified (256 of 259 DataSourcing modules use this fallback). The executor has always injected this key — Steps 4-5 didn't change that behavior.

### 2.5 DataSourcing `lookbackDays` and `mostRecentPrior`/`mostRecent`
- **Change:** New optional parameters added to `DataSourcing` constructor.
- **Impact on V1:** No breakage. These all have defaults (`null`, `false`, `false`). `ModuleFactory.CreateDataSourcing()` uses `TryGetProperty` for all of them, so missing JSON fields are handled gracefully.
- **Usage in V1:** `mostRecentPrior` used by 1 config (CreditScoreDelta), `mostRecent` used by 2 configs (CreditScoreDelta, BranchVisitsByCustomerCsvAppendTrailer). `lookbackDays` is not used by any V1 config. All 3 are the Step 4 test jobs (369, 371).

### 2.6 `DataFrame.FromParquet()` and `DataFrame.FromCsvLines()`
- **Change:** New static methods for reading prior partition data in Append mode.
- **Impact on V1:** No breakage. These are only called when `writeMode == Append` AND a prior partition directory exists. On first run, there are no prior partitions, so the code path is never hit.

### 2.7 `DatePartitionHelper` extraction
- **Change:** Helper extracted from `CsvFileWriter` to shared utility class.
- **Impact on V1:** No breakage. Internal refactor only — no config-facing changes.

### 2.8 Trailer stripping for Append mode
- **Change:** In `CsvFileWriter` Append mode, if `trailerFormat` is set and a prior partition exists, the last line of the prior file is stripped before unioning.
- **Impact on V1:** No breakage. Only triggers when appending to a prior partition that has a trailer. The logic is correct: `lines[..^1]` removes the trailer line before parsing.

---

## 3. Broken Configs

**None.** All 104 V1 configs will execute correctly with the current framework code.

---

## 4. Anti-Pattern Inventory

### AP1: External module used for data sourcing (Direct DB access)
- **8 jobs** use External modules that query the database directly, bypassing `DataSourcing`.
- Examples: `CoveredTransactionProcessor`, `CustomerAddressDeltaProcessor`
- These External modules use `NpgsqlConnection` and construct their own SQL, ignoring the framework's date-range management.
- **Not broken** — they still work. They're just an anti-pattern where the developer chose to bypass the framework.

### AP2: External module does its own file writing (bypasses framework writer)
- **8 jobs** end with an External module and have no framework file writer:
  - `account_velocity_tracking.json`
  - `compliance_transaction_ratio.json`
  - `fund_allocation_breakdown.json`
  - `holdings_by_sector.json`
  - `overdraft_amount_distribution.json`
  - `peak_transaction_times.json`
  - `preference_by_segment.json`
  - `wire_direction_summary.json`
- These External modules write directly to `Output/curated/` using `StreamWriter`, bypassing date partitioning, `etl_effective_date` injection, and the framework's write modes.
- **Not broken** — they produce output. But the output goes to `Output/curated/` (the old V1 baseline location), not `Output/poc4/`.

### AP3: Inflated trailer row counts (W7 pattern)
- Several External-writer modules (e.g., `WireDirectionSummaryWriter`, `HoldingsBySectorWriter`) use the INPUT row count in the trailer instead of the OUTPUT row count.
- This is an intentional V1 bug/anti-pattern, not a framework issue.

### AP4: Header re-emission on append (W12 pattern)
- `AccountVelocityTracker` opens the output file with `append: true` and re-writes the header every time, creating duplicate headers in the output.
- Intentional anti-pattern.

### AP5: Hardcoded date ranges
- 3 DataSourcing modules use hardcoded `minEffectiveDate`/`maxEffectiveDate` (2024-10-01 to 2024-12-31):
  - `daily_wire_volume.json`
  - `fee_revenue_daily.json`
  - `weekend_transaction_pattern.json`
- These will always pull the same date range regardless of the executor's effective date. Intentional anti-pattern.

### AP6: Excessive numParts
- Several ParquetFileWriter configs specify `numParts: 50` (e.g., `branch_card_activity`, `account_overdraft_history`, `card_status_snapshot`).
- This creates 50 part files even when row counts are small. Not broken, just unnecessary.

### AP7: External modules doing data sourcing AND writing
- Some jobs (like `CoveredTransactions`, `CustomerAddressDeltas`) start with External and have a framework writer after them, but the External module itself queries the database directly (bypassing `DataSourcing`). The config has NO `DataSourcing` modules — the External module is the sole data source.
- These work fine but represent the most extreme version of AP1.

---

## 5. Config Patterns

### Module chain patterns (by frequency):

| Pattern | Count |
|---------|-------|
| DataSourcing(N) -> External -> CsvFileWriter | 33 |
| DataSourcing(N) -> Transformation -> CsvFileWriter | 22 |
| DataSourcing(N) -> External -> ParquetFileWriter | 27 |
| DataSourcing(N) -> Transformation -> ParquetFileWriter | 11 |
| DataSourcing(N) -> External (self-writing) | 8 |
| External -> ParquetFileWriter (no DataSourcing) | 2 |
| DataSourcing(N) -> External -> CsvFileWriter (w/ trailer) | varies |

### Writer type distribution:
- **CsvFileWriter Overwrite:** 43 jobs
- **CsvFileWriter Append:** 13 jobs
- **ParquetFileWriter Overwrite:** 33 jobs
- **ParquetFileWriter Append:** 7 jobs
- **External self-writing (no framework writer):** 8 jobs

### DataSourcing date mode distribution:
- **Default (uses `__etlEffectiveDate`):** 256 modules across all configs
- **Static `minEffectiveDate`/`maxEffectiveDate`:** 3 modules (3 configs)
- **`mostRecentPrior`:** 1 module (CreditScoreDelta only)
- **`mostRecent`:** 2 modules (CreditScoreDelta, BranchVisitsByCustomerCsvAppendTrailer)
- **`lookbackDays`:** 0 modules

---

## 6. Jobs 369 (CreditScoreDelta) and 371 (BranchVisitsByCustomerCsvAppendTrailer)

### Job 369 — CreditScoreDelta
- **Config:** `credit_score_delta.json`
- **Pattern:** DataSourcing x3 -> Transformation -> CsvFileWriter
- **Uses new features:** `mostRecentPrior` (for `prior_scores`), `mostRecent` (for `customers`), `additionalFilter`
- **Writer:** CsvFileWriter, Overwrite mode, LF line endings, no trailer
- **Status:** Clean. Config is well-formed and exercises the new multi-date DataSourcing features correctly. No anti-patterns.

### Job 371 — BranchVisitsByCustomerCsvAppendTrailer
- **Config:** `branch_visits_by_customer_csv_append_trailer.json`
- **Pattern:** DataSourcing x2 -> Transformation -> CsvFileWriter
- **Uses new features:** `mostRecent` (for `customers`), `additionalFilter`, CSV Append with trailer
- **Writer:** CsvFileWriter, Append mode, LF line endings, trailer format `TRAILER|{row_count}|{date}`
- **Status:** Clean. Config exercises the Append + trailer combination correctly. No anti-patterns.

Both Step 4 test jobs are confirmed working and free of anti-patterns.
