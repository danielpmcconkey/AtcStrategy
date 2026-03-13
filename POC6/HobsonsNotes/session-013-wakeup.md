# POC6 Session 014 — Wake-Up Prompt

## Copy-paste this into Hobson when you start the next session:

```
Go read /media/dan/fdrive/codeprojects/AtcStrategy/POC6/HobsonsNotes/session-013-wakeup.md — that's your wakeup prompt. Read it, absorb it, then tell me you're ready.
```

---

## Who You Are

You are Hobson. Your CLAUDE.md and MEMORY.md are already loaded.

## What Happened Session 013

Completed ALL build plan steps (1-21). The entire Python framework is written.

### Session 013 deliverables:

- **test_v4_jobs.py** — 27 tests ported from C# V4JobTests.cs. All passing.
- **job_runner.py** — Pipeline executor. Loads job conf, runs modules in sequence. Per-job log file support (step 21).
- **control_db.py** — DAL for control schema. JobRegistration/JobDependency dataclasses. CRUD for job_runs table.
- **execution_plan.py** — Kahn's algorithm topological sort. Imports dataclasses from control_db.
- **job_executor_service.py** — Single-date orchestrator. Module-level `run()` function (not a class).
- **task_queue_service.py** — Multi-threaded service. `TaskQueueService` class. Advisory locks, batch claiming, idle watchdog.
- **cli.py** — Entry point at repo root. argparse. Four modes: `--service`, `--show-config`, `<date>`, `<date> <job>`.
- **app_config.py** — Added `get_config()` / `_current_config` global for job_runner log path access.

### Test suite: 156 passed, 0 failed.

### Context management note:
Session 013 used background agents heavily to keep main context lean. All drafting and C# reading was offloaded to agents. Hobson reviewed and wrote files. This worked well — recommend continuing the pattern.

## Current State

```
MockEtlFrameworkPython/
├── cli.py                          ✅ Step 20
├── pyproject.toml
├── .gitignore
├── appsettings.json
├── src/etl/
│   ├── __init__.py
│   ├── app_config.py               ✅ Updated (get_config added)
│   ├── path_helper.py
│   ├── connection_helper.py
│   ├── date_partition_helper.py
│   ├── job_conf.py
│   ├── job_runner.py                ✅ Step 15 + 21 (per-job logging)
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
│       ├── __init__.py
│       ├── control_db.py            ✅ Step 16
│       ├── execution_plan.py        ✅ Step 17
│       ├── job_executor_service.py  ✅ Step 18
│       └── task_queue_service.py    ✅ Step 19
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

All source code is written. Build plan steps 1-21 are complete. What remains:

1. **Integration testing against the real DB.** The control layer (control_db, job_executor_service, task_queue_service) has never touched a real Postgres instance. Need the control schema (control.jobs, control.job_dependencies, control.job_runs, control.task_queue) created in the `atc` database.

2. **End-to-end test with real job confs.** Pick a simple job, run it via `cli.py <date> <job_name>`, verify output matches C# output.

3. **Proofmark validation.** Run all 105 jobs through the Python framework, then run Proofmark against C# output to verify byte-identical results.

4. **Minor cleanup:** `datetime.utcnow()` deprecation warning in csv_file_writer.py:96 — replace with `datetime.now(datetime.UTC)`.

### Key question for Dan:
Does the control schema already exist in the `atc` database, or does it need to be created? If it needs creating, the table DDL should be derived from the C# migrations or the build plan's task_queue schema section.

## Key Files

| What | Path |
|------|------|
| Build plan | `AtcStrategy/POC6/HobsonsNotes/python-rewrite-build-plan.md` |
| Python repo | `/media/dan/fdrive/codeprojects/MockEtlFrameworkPython/` |
| C# repo (reference) | `/media/dan/fdrive/codeprojects/MockEtlFramework/` |
| Proofmark | `/media/dan/fdrive/codeprojects/proofmark/` |

## Standing Rules

- Only Hobson writes code to MockEtlFrameworkPython.
- Read the C# source before writing each Python component.
- Job conf files must work as-is (same JSON format, same field names).
- Same output formats — Proofmark must not be able to tell the difference.
