# POC6 Session 013 — Wake-Up Prompt

## Copy-paste this into Hobson when you start the next session:

```
Go read /media/dan/fdrive/codeprojects/AtcStrategy/POC6/HobsonsNotes/session-012-wakeup.md — that's your wakeup prompt. Read it, absorb it, then tell me you're ready.
```

---

## Who You Are

You are Hobson. Your CLAUDE.md and MEMORY.md are already loaded.

## What Happened Session 012

Built the Python framework. Wrote ALL source code and MOST test files.

### Source files written (steps 1-13 of build plan — ALL DONE):

```
MockEtlFrameworkPython/
├── pyproject.toml
├── .gitignore
├── appsettings.json
├── src/etl/
│   ├── __init__.py
│   ├── app_config.py
│   ├── path_helper.py
│   ├── connection_helper.py
│   ├── date_partition_helper.py
│   ├── job_conf.py
│   ├── module_factory.py
│   ├── modules/
│   │   ├── __init__.py
│   │   ├── base.py
│   │   ├── data_sourcing.py
│   │   ├── transformation.py
│   │   ├── csv_file_writer.py
│   │   ├── parquet_file_writer.py
│   │   ├── dataframe_writer.py
│   │   └── external.py
│   └── control/
│       └── __init__.py
└── tests/
    ├── conftest.py
    ├── test_app_config.py        ✅ 16 tests
    ├── test_data_sourcing.py     ✅ 18 tests
    ├── test_dataframe_ops.py     ✅ 24 tests
    ├── test_transformation.py    ✅ 10 tests
    ├── test_module_factory.py    ✅ 23 tests
    ├── test_csv_file_writer.py   ✅ 22 tests
    ├── test_parquet_file_writer.py ✅ 16 tests
    └── test_v4_jobs.py           ❌ NOT WRITTEN YET (27 tests)
```

### Venv is set up:
- `.venv` exists at `/media/dan/fdrive/codeprojects/MockEtlFrameworkPython/.venv`
- Dependencies installed: pandas, psycopg, pyarrow, pytest

### Tests have NOT been run yet. There will be bugs.

## Your Job Next Session

1. **Write `test_v4_jobs.py`** — Port from C# `V4JobTests.cs` (27 tests). Read the C# file at `/media/dan/fdrive/codeprojects/MockEtlFramework/Lib.Tests/V4JobTests.cs`. These are all Transformation module tests — SQL against in-memory SQLite with fixture DataFrames. No DB needed.

2. **Run all tests and fix failures.** Use `.venv/bin/pytest tests/ -v`. The source was written from reading C# but never executed — expect import issues, pandas idiom bugs, etc.

3. **After tests pass:** Continue build plan steps 14-21:
   - 14: test_v4_jobs.py (will be done in step 1 above)
   - 15: job_runner.py
   - 16: control_db.py
   - 17: execution_plan.py
   - 18: job_executor_service.py
   - 19: task_queue_service.py
   - 20: cli.py
   - 21: Job run logging

### Build plan reference:
`/media/dan/fdrive/codeprojects/AtcStrategy/POC6/HobsonsNotes/python-rewrite-build-plan.md`

### C# reference:
`/media/dan/fdrive/codeprojects/MockEtlFramework/`

## Key Files

| What | Path |
|------|------|
| Build plan | `AtcStrategy/POC6/HobsonsNotes/python-rewrite-build-plan.md` |
| Python repo | `/media/dan/fdrive/codeprojects/MockEtlFrameworkPython/` |
| C# repo (reference) | `/media/dan/fdrive/codeprojects/MockEtlFramework/` |
| C# test files | `/media/dan/fdrive/codeprojects/MockEtlFramework/Lib.Tests/` |

## Standing Rules

- Only Hobson writes code to MockEtlFrameworkPython.
- Read the C# source before writing each Python component.
- Job conf files must work as-is (same JSON format, same field names).
- Same output formats — Proofmark must not be able to tell the difference.
