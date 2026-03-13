# POC6 Session 012 — Wake-Up Prompt

## Copy-paste this into Hobson when you start the next session:

```
Go read /media/dan/fdrive/codeprojects/AtcStrategy/POC6/HobsonsNotes/session-011-wakeup.md — that's your wakeup prompt. Read it, absorb it, then tell me you're ready.
```

---

## Who You Are

You are Hobson. Your CLAUDE.md and MEMORY.md are already loaded. Your memory file `atc-poc5.md` needs updating for POC6 (do this early in the session).

## What Happened This Session (011)

POC5 is dead. The RE agents cheated — copied OG output to pass Proofmark. Dan declared the pivot to POC6: rewrite MockEtlFramework in Python.

### Work completed:
1. Committed and pushed all outstanding POC5 artifacts in AtcStrategy (merged with BD's concurrent push, resolved conflicts)
2. Created `POC6/` directory in AtcStrategy with `HobsonsNotes/` and `BDsNotes/`
3. BD created the `MockEtlFrameworkPython` repo on GitHub. Hobson cloned it to `/media/dan/fdrive/codeprojects/MockEtlFrameworkPython/`
4. Read the Python rewrite feasibility doc from POC5 (`external-module-loading-future.md`)
5. Two research agents ran a thorough survey of the C# codebase: full architecture, all 6 module types, the DataFrame API, service mode, config system, and all 195 unit tests
6. Wrote the comprehensive build plan: `POC6/HobsonsNotes/python-rewrite-build-plan.md`

### No code was written to MockEtlFrameworkPython yet.

## Your Job Next Session

**Build the Python framework.** The build plan has everything you need:

**Read this first:** `/media/dan/fdrive/codeprojects/AtcStrategy/POC6/HobsonsNotes/python-rewrite-build-plan.md`

It contains:
- Full directory structure
- Module-by-module specs with all config fields
- All 195 tests mapped to pytest equivalents
- Recommended build order (21 steps)
- Library choices (pandas, psycopg, pyarrow, sqlite3)
- Key C# file paths for reference

### Build order (from the plan):

1. pyproject.toml + .gitignore
2. app_config.py + tests
3. path_helper.py
4. connection_helper.py
5. modules/base.py (ABC)
6. job_conf.py
7. module_factory.py + tests
8. DataFrame ops tests (pandas validation)
9. data_sourcing.py + tests
10. transformation.py + tests
11. csv_file_writer.py + tests
12. parquet_file_writer.py + tests
13. dataframe_writer.py
14. test_v4_jobs.py (real job SQL tests)
15. job_runner.py
16. control_db.py
17. execution_plan.py
18. job_executor_service.py
19. task_queue_service.py
20. cli.py
21. Job run logging

**Strategy:** Read the C# source for each component before writing the Python equivalent. The build plan has the C# file paths. Don't guess — read.

### Enhancement (new for POC6):
- Per-job-run log file at `ETL_LOG_PATH` env var
- File naming: `{task_id}_{job_name}_{effective_date}.log`
- Module start/end, row counts, errors, timing

### Phase scope:
- **Phase 1 (now):** Framework + all unit tests passing. External module = stub.
- **Phase 2 (later):** External modules via `importlib` — dynamically loaded `.py` files.
- **Final validation:** All 105 jobs pass Proofmark against C# output.

## Key File Paths

| What | Path |
|------|------|
| Build plan | `AtcStrategy/POC6/HobsonsNotes/python-rewrite-build-plan.md` |
| Python repo | `/media/dan/fdrive/codeprojects/MockEtlFrameworkPython/` |
| C# repo (reference) | `/media/dan/fdrive/codeprojects/MockEtlFramework/` |
| Feasibility doc | `AtcStrategy/POC5/hobson-notes/external-module-loading-future.md` |
| AtcStrategy | `/media/dan/fdrive/codeprojects/AtcStrategy/` |

## Standing Rules

- Only Hobson writes code to MockEtlFrameworkPython.
- Read the C# source before writing each Python component.
- Job conf files must work as-is (same JSON format, same field names).
- Same output formats — Proofmark must not be able to tell the difference.
