# POC6 Session 016 — Wake-Up Prompt

## Copy-paste this into Hobson when you start the next session:

```
Go read /media/dan/fdrive/codeprojects/AtcStrategy/POC6/HobsonsNotes/session-015-wakeup.md — that's your wakeup prompt. Read it, absorb it, then tell me you're ready.
```

---

## Who You Are

You are Hobson. Your CLAUDE.md and MEMORY.md are already loaded.

## What Happened Session 015

Housekeeping and preparation for the Proofmark validation run.

### Session 015 deliverables:

- **Integration test: PASSED.** Control layer (control_db, job_executor_service, task_queue_service) tested against real Postgres. All 13 tests passed — reads, writes, execution plan.
- **End-to-end test: 5/6 jobs passed.** One failure (Parquet Append mode) due to C#-written Decimal types mixing with Python float64. Fixed.
- **Bug fix: Parquet Append Decimal coercion** — `_read_parquet_dir()` in `parquet_file_writer.py` now detects `Decimal` objects from C# Parquet files and coerces to `float64`.
- **Bug fix: CSV date format mismatch** — `_format_field()` in `csv_file_writer.py` now formats `datetime.date` objects as `M/d/yyyy` (matching C#'s `DateOnly.ToString()`). Uses `type(val) is date` to avoid catching `datetime.datetime`.
- **Bug fix: `datetime.utcnow()` deprecation** — Replaced with `datetime.now(timezone.utc)` in `csv_file_writer.py`. Outstanding since session 013, now resolved.
- **Job confs copied to Python repo** — 105 job conf files at `MockEtlFrameworkPython/JobExecutor/Jobs/`. Reconciled against sealed POC5 manifest. 5 inactive v4 test jobs purged.
- **Control table cleaned up:**
  - 17 `_RE` jobs deleted (with 1,762 run history records). Table now has exactly 105 active jobs matching the sealed manifest.
  - `control.task_queue` and `control.proofmark_test_queue` truncated.
- **Env vars reference doc** written at `MockEtlFrameworkPython/Documentation/env-vars.md`.
- **All 156 unit tests pass.** Zero warnings.

### Env var situation:

| Variable | Host Value | Notes |
|---|---|---|
| `ETL_ROOT` | `/media/dan/fdrive/codeprojects/MockEtlFrameworkPython` | Changed from C# repo. Set in Dan's terminal. |
| `ETL_RE_ROOT` | `/media/dan/fdrive/ai-sandbox/workspace` | BD's workspace root. In .bashrc. |
| `ETL_RE_OUTPUT` | TBD | Needs to be BD-mountable. Future session. |
| `ETL_DB_PASSWORD` | `claude` | In .bashrc. |

Full reference: `MockEtlFrameworkPython/Documentation/env-vars.md`

## Current State

```
MockEtlFrameworkPython/
├── cli.py
├── pyproject.toml
├── .gitignore
├── appsettings.json
├── JobExecutor/Jobs/              ✅ 105 job confs (matches sealed manifest)
├── Documentation/                 17 docs + env-vars.md
├── src/etl/
│   ├── app_config.py
│   ├── path_helper.py
│   ├── connection_helper.py
│   ├── date_partition_helper.py
│   ├── job_conf.py
│   ├── job_runner.py
│   ├── module_factory.py
│   ├── modules/
│   │   ├── base.py
│   │   ├── data_sourcing.py
│   │   ├── transformation.py
│   │   ├── csv_file_writer.py       ✅ date format + utcnow fixes
│   │   ├── parquet_file_writer.py   ✅ Decimal coercion fix
│   │   ├── dataframe_writer.py
│   │   ├── external.py
│   │   └── externals/               73 module files
│   └── control/
│       ├── control_db.py
│       ├── execution_plan.py
│       ├── job_executor_service.py
│       └── task_queue_service.py
└── tests/                           156 tests, all passing
```

## Your Job Next Session

Dan was about to verify `ETL_ROOT` is set correctly in his terminal and run a single-job sanity check. If that passed:

1. **Run all 105 jobs** through the Python framework for a single effective date.
2. **Proofmark validation** — compare Python output against C# output. This is the final exam.

If the sanity check did NOT pass, debug from there.

### Important context for the Proofmark run:

- C# output (reference): `/media/dan/fdrive/codeprojects/MockEtlFramework/Output/curated/`
- Python output (challenger): `/media/dan/fdrive/codeprojects/MockEtlFrameworkPython/Output/curated/`
- Proofmark repo: `/media/dan/fdrive/codeprojects/proofmark/`
- Proofmark `compare` mode takes `--left`, `--right`, `--config` — no env vars needed for compare mode.
- Proofmark `serve` mode reads from `control.proofmark_test_queue` and uses env var tokens.

## Key Files

| What | Path |
|------|------|
| Build plan | `AtcStrategy/POC6/HobsonsNotes/python-rewrite-build-plan.md` |
| Python repo | `/media/dan/fdrive/codeprojects/MockEtlFrameworkPython/` |
| C# repo (dead, reference only) | `/media/dan/fdrive/codeprojects/MockEtlFramework/` |
| Proofmark | `/media/dan/fdrive/codeprojects/proofmark/` |
| Env vars reference | `MockEtlFrameworkPython/Documentation/env-vars.md` |
| Sealed job manifest | `AtcStrategy/POC5/hobson-notes/job-scope-manifest.json` |

## Standing Rules

- Only Hobson writes code to MockEtlFrameworkPython.
- Read the C# source before writing each Python component.
- Job conf files must work as-is (same JSON format, same field names).
- Same output formats — Proofmark must not be able to tell the difference.
