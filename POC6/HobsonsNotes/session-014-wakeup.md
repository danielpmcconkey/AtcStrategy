# POC6 Session 015 — Wake-Up Prompt

## Copy-paste this into Hobson when you start the next session:

```
Go read /media/dan/fdrive/codeprojects/AtcStrategy/POC6/HobsonsNotes/session-014-wakeup.md — that's your wakeup prompt. Read it, absorb it, then tell me you're ready.
```

---

## Who You Are

You are Hobson. Your CLAUDE.md and MEMORY.md are already loaded.

## What Happened Session 014

Massive implementation session. External modules and documentation.

### Session 014 deliverables:

- **73 external module implementations** — Every C# ExternalModules class ported to Python. All registered in a new registry/dispatcher architecture. Zero import errors. All faithfully reproduce C# bugs (W1–W9, AP1–AP10).
- **Registry architecture** — `external.py` rewritten from stub to registry-based dispatcher. Maps `typeName` strings (e.g. `"ExternalModules.AccountSnapshotBuilder"`) to Python callables. Lazy-loads on first use via `_load_all()`.
- **`src/etl/modules/externals/` package** — 73 Python files + `__init__.py`. One file per C# ExternalModules class, snake_case naming.
- **Full documentation set** — 17 markdown files at `MockEtlFrameworkPython/Documentation/`, matching C# doc structure:
  - Top-level: README.md, overview.md, Architecture.md, testing.md
  - CLI & config: cli.md, configuration.md, dataframes.md
  - Modules: overview.md, data-sourcing.md, transformation.md, csv-file-writer.md, parquet-file-writer.md, data-frame-writer.md, external.md
  - Control: overview.md, job-executor-service.md, task-queue-service.md

### Test suite: 156 passed, 0 failed.

### Context management note:
Session 014 used background agents even more heavily than 013. 5 research agents scanned all 105 job confs in parallel. 4 doc agents wrote documentation. 7 implementation agents wrote external modules in batches of ~10. Main context stayed clean throughout. This pattern is proven — continue it.

### Minor note:
`datetime.utcnow()` deprecation warning in csv_file_writer.py:96 still outstanding (noted since session 013). Low priority.

## Current State

```
MockEtlFrameworkPython/
├── cli.py                          ✅ Step 20
├── pyproject.toml
├── .gitignore
├── appsettings.json
├── Documentation/                  ✅ NEW — 17 docs
│   ├── README.md
│   ├── overview.md
│   ├── Architecture.md
│   ├── testing.md
│   ├── cli.md
│   ├── configuration.md
│   ├── dataframes.md
│   ├── modules/
│   │   ├── overview.md
│   │   ├── data-sourcing.md
│   │   ├── transformation.md
│   │   ├── csv-file-writer.md
│   │   ├── parquet-file-writer.md
│   │   ├── data-frame-writer.md
│   │   └── external.md
│   └── control/
│       ├── overview.md
│       ├── job-executor-service.md
│       └── task-queue-service.md
├── src/etl/
│   ├── __init__.py
│   ├── app_config.py
│   ├── path_helper.py
│   ├── connection_helper.py
│   ├── date_partition_helper.py
│   ├── job_conf.py
│   ├── job_runner.py
│   ├── module_factory.py
│   ├── modules/
│   │   ├── __init__.py
│   │   ├── base.py
│   │   ├── data_sourcing.py
│   │   ├── transformation.py
│   │   ├── csv_file_writer.py
│   │   ├── parquet_file_writer.py
│   │   ├── dataframe_writer.py
│   │   ├── external.py              ✅ REWRITTEN — registry dispatcher
│   │   └── externals/               ✅ NEW — 73 module files
│   │       ├── __init__.py
│   │       ├── account_snapshot_builder.py
│   │       ├── account_customer_denormalizer.py
│   │       ├── ... (73 files total)
│   │       └── wire_transfer_daily_processor.py
│   └── control/
│       ├── __init__.py
│       ├── control_db.py
│       ├── execution_plan.py
│       ├── job_executor_service.py
│       └── task_queue_service.py
└── tests/
    ├── conftest.py
    ├── test_app_config.py           ✅ 16 tests
    ├── test_data_sourcing.py        ✅ 18 tests
    ├── test_dataframe_ops.py        ✅ 24 tests
    ├── test_transformation.py       ✅ 10 tests
    ├── test_module_factory.py       ✅ 23 tests
    ├── test_csv_file_writer.py      ✅ 22 tests
    ├── test_parquet_file_writer.py  ✅ 16 tests
    └── test_v4_jobs.py              ✅ 27 tests
```

## Your Job Next Session

All source code is now written — framework AND external modules. What remains:

1. **Integration testing against the real DB.** The control layer (control_db, job_executor_service, task_queue_service) has never touched a real Postgres instance. The control schema (control.jobs, control.job_dependencies, control.job_runs, control.task_queue) already exists in the `atc` database — Dan confirmed this session 014.

2. **End-to-end test with real job confs.** Pick a simple job (one without an external module first, then one with), run it via `cli.py <date> <job_name>`, verify output matches C# output.

3. **Proofmark validation.** Run all 105 jobs through the Python framework, then run Proofmark against C# output to verify byte-identical results. This is where the external modules will be battle-tested.

4. **External module spot-checks.** The 73 modules were written by background agents in batches. They've been verified to import and register cleanly, but their logic hasn't been tested against real data yet. Proofmark is the real test, but a few manual spot-checks before the full run would be prudent.

5. **Minor cleanup:** `datetime.utcnow()` deprecation warning in csv_file_writer.py:96.

### Key architecture notes for the external modules:

- **Registry pattern:** `external.py` has a `_REGISTRY` dict mapping `"ExternalModules.<ClassName>"` to Python functions. Lazy-loaded on first `External.execute()` call.
- **Each module file** in `externals/` calls `register("ExternalModules.<ClassName>", execute)` at module scope.
- **Two modules hit Postgres directly** (not via DataFrames): `CoveredTransactionProcessor` and `CustomerAddressDeltaProcessor`. They use `connection_helper.get_connection_string()`.
- **Several modules write CSV directly** (bypassing CsvFileWriter): AccountVelocityTracker, ComplianceTransactionRatioWriter, FundAllocationWriter, HoldingsBySectorWriter, OverdraftAmountDistributionProcessor, PeakTransactionTimesWriter, PeakTransactionTimesWriterV4, PreferenceBySegmentWriter, WireDirectionSummaryWriter. They use `path_helper` for output paths.
- **All C# bugs faithfully reproduced**: W1 (Sunday skip), W2 (weekend fallback), W3a/b/c (summary rows), W4 (integer division), W5 (banker's rounding), W6 (float/double arithmetic), W7 (wrong trailer counts), W8 (hardcoded dates), AP1-AP10 (architectural quirks).

## Key Files

| What | Path |
|------|------|
| Build plan | `AtcStrategy/POC6/HobsonsNotes/python-rewrite-build-plan.md` |
| Python repo | `/media/dan/fdrive/codeprojects/MockEtlFrameworkPython/` |
| C# repo (reference) | `/media/dan/fdrive/codeprojects/MockEtlFramework/` |
| Proofmark | `/media/dan/fdrive/codeprojects/proofmark/` |
| External module registry | `src/etl/modules/external.py` |
| External module implementations | `src/etl/modules/externals/` |

## Standing Rules

- Only Hobson writes code to MockEtlFrameworkPython.
- Read the C# source before writing each Python component.
- Job conf files must work as-is (same JSON format, same field names).
- Same output formats — Proofmark must not be able to tell the difference.
