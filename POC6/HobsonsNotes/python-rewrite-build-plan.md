# MockEtlFrameworkPython — Build Plan

Written 2026-03-10, session 011. This is the primary reference for building the Python rewrite.

## Scope

**Phase 1 (this plan):** Framework + unit tests. All existing job.conf files must work. Same output formats. Same DB interactions. Same service mode. External module = stub (Phase 2).

**Phase 2 (later):** External modules — dynamically loaded `.py` files via `importlib`.

**Final validation:** Run all 105 jobs, Proofmark against C# output.

## Source of Truth

The C# codebase at `/media/dan/fdrive/codeprojects/MockEtlFramework/` is the reference implementation. The Python repo is at `/media/dan/fdrive/codeprojects/MockEtlFrameworkPython/`.

## Feasibility Research

See `/media/dan/fdrive/codeprojects/AtcStrategy/POC5/hobson-notes/external-module-loading-future.md` for the original analysis (pandas, psycopg3, pyarrow, importlib mapping).

---

## Architecture Decisions

### Use pandas directly — no custom DataFrame wrapper

The C# version has a custom immutable DataFrame (~400 LOC) with Select, Filter, WithColumn, Drop, GroupBy, OrderBy, Join, Union, Distinct, Limit. All of these map 1:1 to pandas operations. No wrapper needed.

**Impact on tests:** DataFrame tests will verify pandas behavior rather than a custom class. The business outcomes are the same (e.g., "filter returns only matching rows"), but the test code will use pandas idioms.

### Library choices

| Concern | C# | Python |
|---------|-----|--------|
| DataFrame | Custom `DataFrame.cs` | pandas |
| Postgres | Npgsql | psycopg (v3) |
| Parquet | Parquet.Net | pyarrow |
| CSV | Manual RFC 4180 | stdlib `csv` module |
| SQLite transforms | Microsoft.Data.Sqlite | stdlib `sqlite3` + pandas `read_sql` |
| Threading | System.Threading | `threading` module |
| Config | Custom + System.Text.Json | `dataclasses` + `json` |
| CLI | Manual args parsing | `argparse` |
| Testing | xUnit | pytest |
| Logging (NEW) | N/A | `logging` module |

### New enhancement: Per-job-run log files

- Env var: `ETL_LOG_PATH` (added to PathSettings)
- File naming: `{task_id}_{job_name}_{effective_date}.log`
- Not too verbose: module start/end, row counts, errors, timing
- RE agents need to see what the framework did during a job run

---

## Directory Structure

```
MockEtlFrameworkPython/
├── src/
│   └── etl/
│       ├── __init__.py
│       ├── app_config.py
│       ├── path_helper.py
│       ├── connection_helper.py
│       ├── job_conf.py
│       ├── job_runner.py
│       ├── module_factory.py
│       ├── date_partition_helper.py
│       ├── modules/
│       │   ├── __init__.py
│       │   ├── base.py              # ABC: execute(shared_state) -> shared_state
│       │   ├── data_sourcing.py
│       │   ├── transformation.py
│       │   ├── dataframe_writer.py
│       │   ├── csv_file_writer.py
│       │   ├── parquet_file_writer.py
│       │   └── external.py          # Stub — raises NotImplementedError
│       └── control/
│           ├── __init__.py
│           ├── control_db.py
│           ├── execution_plan.py
│           ├── task_queue_service.py
│           └── job_executor_service.py
├── tests/
│   ├── conftest.py
│   ├── test_app_config.py
│   ├── test_data_sourcing.py
│   ├── test_transformation.py
│   ├── test_module_factory.py
│   ├── test_csv_file_writer.py
│   ├── test_parquet_file_writer.py
│   ├── test_v4_jobs.py
│   └── test_dataframe_ops.py        # Pandas equivalents of DataFrame tests
├── cli.py
├── appsettings.json
├── pyproject.toml
└── .gitignore
```

---

## Module-by-Module Specs

### IModule → ABC `base.py`

```python
from abc import ABC, abstractmethod

class Module(ABC):
    @abstractmethod
    def execute(self, shared_state: dict) -> dict:
        ...
```

### DataSourcing

Reads from Postgres datalake. Five mutually exclusive date resolution modes:

1. **Static dates:** `min_effective_date` + `max_effective_date` (fixed range)
2. **Lookback:** `lookback_days: N` → effective_date - N through effective_date
3. **Most recent prior:** `most_recent_prior: true` → latest date < effective_date
4. **Most recent:** `most_recent: true` → latest date <= effective_date
5. **Default:** both min/max = `__etlEffectiveDate` from shared state

Config fields from job conf JSON:
- `type`: "DataSourcing"
- `resultName`: key in shared_state to store result
- `schema`: Postgres schema (e.g., "datalake")
- `table`: table name
- `columns`: list of column names
- `additionalFilter`: optional extra WHERE clause
- `minEffectiveDate`, `maxEffectiveDate`: optional static date range
- `lookbackDays`: optional int
- `mostRecentPrior`: optional bool
- `mostRecent`: optional bool

Always injects `ifw_effective_date` column. Returns empty DataFrame with correct schema when no rows found.

### Transformation

In-memory SQLite. Registers all pandas DataFrames in shared_state as SQLite tables. Executes free-form SQL. Returns result as new DataFrame.

Config: `type`, `resultName`, `sql`

Key: empty DataFrames registered as schema-only tables. Non-DataFrame entries in shared_state silently skipped.

### DataFrameWriter

Writes pandas DataFrame to Postgres curated schema.

Config: `type`, `source`, `targetTable`, `writeMode` ("Overwrite" or "Append"), `targetSchema` (default "curated")

Auto-creates table if doesn't exist. Overwrite = TRUNCATE + INSERT. Append = INSERT only. Wrapped in transaction.

### CsvFileWriter

Writes date-partitioned CSV files.

Config: `type`, `source`, `outputDirectory`, `jobDirName`, `outputTableDirName`, `fileName`, `includeHeader` (default true), `trailerFormat` (optional), `writeMode`, `lineEnding` (default "LF")

Output path: `{outputDirectory}/{jobDirName}/{outputTableDirName}/{effective_date}/{fileName}`

Key behaviors:
- Injects `etl_effective_date` column
- UTF-8 no BOM
- RFC 4180 quoting (fields with commas, quotes, newlines)
- NULLs render as empty (bare comma)
- Append mode: reads prior partition, strips trailer, unions
- Trailer tokens: `{row_count}`, `{date}`, `{timestamp}`

### ParquetFileWriter

Writes date-partitioned Parquet files.

Config: `type`, `source`, `outputDirectory`, `jobDirName`, `outputTableDirName`, `fileName`, `numParts` (default 1), `writeMode`

Output path: `{outputDirectory}/{jobDirName}/{outputTableDirName}/{effective_date}/{fileName}/part-NNNNN.parquet`

Key behaviors:
- Injects `etl_effective_date` column
- Splits rows across numParts files
- Consistent schema across all parts
- Append mode: reads prior partition, drops etl_effective_date, unions

### External (Phase 2 stub)

Raises `NotImplementedError("External modules are Phase 2")`.

---

## Config System (AppConfig)

Layered: compiled defaults → appsettings.json → environment variables.

```python
@dataclass
class PathSettings:
    etl_root: str          # from ETL_ROOT env var
    etl_re_output: str     # from ETL_RE_OUTPUT env var
    etl_re_root: str       # from ETL_RE_ROOT env var
    etl_log_path: str      # from ETL_LOG_PATH env var (NEW)

@dataclass
class DatabaseSettings:
    host: str = "localhost"
    username: str = "claude"
    database_name: str = "atc"
    timeout: int = 15
    command_timeout: int = 300
    # password ONLY from ETL_DB_PASSWORD env var, never from JSON

@dataclass
class TaskQueueSettings:
    thread_count: int = 5
    poll_interval_ms: int = 5000
    idle_shutdown_seconds: int = 28_800

@dataclass
class AppConfig:
    paths: PathSettings
    database: DatabaseSettings
    task_queue: TaskQueueSettings
```

---

## Path Resolution (PathHelper)

Token expansion: `{ETL_ROOT}`, `{ETL_RE_OUTPUT}`, `{ETL_RE_ROOT}` in paths.

Solution root: if `ETL_ROOT` is set, use it. Otherwise walk up from script location looking for marker (pyproject.toml or similar).

---

## Control / Service Mode

### TaskQueueService

- N worker threads (default 5)
- Claim-by-job: each worker claims ALL pending tasks for one job via `pg_try_advisory_xact_lock(hashtext(job_name))`
- Tasks within a job processed in effective_date order
- Batch failure: if one task fails, remaining tasks in batch marked Failed
- Idle shutdown: watchdog thread checks once/minute, shuts down after IdleShutdownSeconds of inactivity

### JobExecutorService (single effective date)

- Loads active jobs + dependencies
- ExecutionPlan via Kahn's algorithm (topological sort)
- SameDay deps: must succeed on same date
- Latest deps: must have ever succeeded
- Skips jobs whose upstream deps failed

### ControlDb

All queries against the `control` schema:
- `get_active_jobs()` → list of job registrations
- `get_all_dependencies()` → list of dependencies
- `get_succeeded_job_ids(run_date)` → set
- `get_ever_succeeded_job_ids()` → set
- `get_last_succeeded_max_effective_date(job_id)` → date or None
- `get_next_attempt_number(job_id, min_date, max_date)` → int
- `insert_run(...)` → run_id
- `mark_running(run_id)`, `mark_succeeded(run_id, rows)`, `mark_failed(run_id, error)`, `mark_skipped(run_id)`

### task_queue table schema

```sql
control.task_queue (
    task_id         serial PK,
    job_name        varchar(255),
    effective_date  date,
    status          varchar(20) DEFAULT 'Pending',  -- Pending/Running/Succeeded/Failed
    started_at      timestamp,
    completed_at    timestamp,
    error_message   text,
    execution_mode  varchar(50)  -- legacy, unused
)
```

---

## CLI Entry Point

```
python cli.py --service                        # long-running queue executor
python cli.py --show-config                    # dump config and exit
python cli.py <effective_date>                 # run all active jobs for date
python cli.py <effective_date> <job_name>      # run one job for date
```

---

## Unit Test Inventory (195 tests → pytest)

### test_app_config.py (16 tests)
- Default values for all settings
- Password reads from ETL_DB_PASSWORD env var
- Password empty when env var missing
- Connection string formatting
- Special chars in password

### test_data_sourcing.py (18 tests)
- Mutual exclusivity of date modes (6 invalid combos throw)
- Valid single-mode construction (4 modes)
- Date range resolution for each mode
- Missing __etlEffectiveDate throws

### test_dataframe_ops.py (24 tests)
- Core pandas operations: filter, select columns, add column, drop, sort, limit, union, distinct, join, groupby+count, groupby+agg
- Empty DataFrame with schema
- CSV parsing (FromCsvLines equivalent)
- Union schema mismatch raises

### test_transformation.py (10 tests)
- Basic SELECT, WHERE, column projection, JOIN, GROUP BY
- Preserves existing shared state
- Non-DataFrame objects in state ignored
- Empty DataFrame registered as table with schema
- Left join with empty table → nulls

### test_module_factory.py (23 tests)
- Each module type deserializes correctly
- Optional fields handled
- Mutual exclusivity validation for DataSourcing
- Missing required fields throw
- Unknown type throws

### test_csv_file_writer.py (22 tests)
- Header + data rows
- etl_effective_date injection
- No header mode
- RFC 4180 quoting (commas, quotes)
- NULL → empty field
- Trailer format with tokens
- Overwrite vs append modes
- UTF-8 no BOM
- LF vs CRLF line endings
- Directory creation
- Missing DataFrame/date throws
- Append strips prior trailer

### test_parquet_file_writer.py (16 tests)
- Single and multi-part files
- Row count preserved across parts
- Overwrite deletes existing
- Directory creation
- NULL values
- etl_effective_date injection
- Schema matches DataFrame + etl_date
- DateOnly and DateTime column types
- Append mode unions with prior

### test_v4_jobs.py (27 tests)
- 5 real job SQL transformations with fixture data
- PeakTransactionTimes: hourly aggregation, ordering, empty input, rounding
- DailyBalanceMovement: debit/credit totals, net movement, unmatched accounts
- CreditScoreDelta: change detection, null prior, customer enrichment
- BranchVisits: customer join, ordering, missing customer
- DansTransactionSpecial: multi-join denormalization, CTE dedup, chained transforms

---

## Build Order

Recommended sequence to minimize blocking:

1. **pyproject.toml + .gitignore** — project scaffold
2. **app_config.py + test_app_config.py** — config foundation
3. **path_helper.py** — token expansion
4. **connection_helper.py** — DSN builder
5. **modules/base.py** — ABC
6. **job_conf.py** — JSON deserialization
7. **module_factory.py + test_module_factory.py** — module creation
8. **DataFrame operations tests (test_dataframe_ops.py)** — validate pandas assumptions
9. **data_sourcing.py + test_data_sourcing.py** — first real module (date resolution only, no DB in tests)
10. **transformation.py + test_transformation.py** — SQLite integration
11. **csv_file_writer.py + test_csv_file_writer.py** — file output
12. **parquet_file_writer.py + test_parquet_file_writer.py** — file output
13. **dataframe_writer.py** — DB output (no standalone tests, tested via integration)
14. **test_v4_jobs.py** — real job SQL validation
15. **job_runner.py** — pipeline executor
16. **control_db.py** — DAL
17. **execution_plan.py** — topological sort
18. **job_executor_service.py** — single-date orchestrator
19. **task_queue_service.py** — multi-threaded service
20. **cli.py** — entry point
21. **Job run logging** — per-task log files

---

## Key C# Files to Reference

| Component | C# File |
|-----------|---------|
| Job conf schema | `Lib/JobConf.cs` |
| Module interface | `Lib/Modules/IModule.cs` |
| Module factory | `Lib/ModuleFactory.cs` |
| DataSourcing | `Lib/Modules/DataSourcing.cs` |
| Transformation | `Lib/Modules/Transformation.cs` |
| DataFrameWriter | `Lib/Modules/DataFrameWriter.cs` |
| CsvFileWriter | `Lib/Modules/CsvFileWriter.cs` |
| ParquetFileWriter | `Lib/Modules/ParquetFileWriter.cs` |
| External | `Lib/Modules/External.cs` |
| DataFrame | `Lib/DataFrames/DataFrame.cs` |
| Row | `Lib/DataFrames/Row.cs` |
| GroupedDataFrame | `Lib/DataFrames/GroupedDataFrame.cs` |
| AppConfig | `Lib/AppConfig.cs` |
| PathHelper | `Lib/PathHelper.cs` |
| ConnectionHelper | `Lib/ConnectionHelper.cs` |
| JobRunner | `Lib/JobRunner.cs` |
| ControlDb | `Lib/Control/ControlDb.cs` |
| ExecutionPlan | `Lib/Control/ExecutionPlan.cs` |
| TaskQueueService | `Lib/Control/TaskQueueService.cs` |
| JobExecutorService | `Lib/Control/JobExecutorService.cs` |
| CLI | `JobExecutor/Program.cs` |
| appsettings.json | `JobExecutor/appsettings.json` |
| Tests | `Lib.Tests/*.cs` (8 files) |
| SQL schema | `SQL/CreateControlSchema.sql` |

All C# paths relative to `/media/dan/fdrive/codeprojects/MockEtlFramework/`.
