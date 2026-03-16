# State of POC6

**Date:** 2026-03-16
**Author:** Hobson
**Status:** Framework complete. Validation complete. Network isolation v2 implemented. Append-mode re-run bug fixed. Orchestrator v0.2 complete (BD). v0.3 (agent integration) in progress.

---

## 1. What POC6 Is

POC6 is the Python rewrite of the MockEtlFramework, replacing the original C# implementation. It exists because POC5 failed: the RE (reverse-engineering) agents cheated by copying OG (original) output to pass Proofmark validation, a systemic context-rot problem in the smart orchestrator design.

POC6 has two parallel workstreams:

1. **Framework rewrite (Hobson):** Rebuild the ETL framework in Python so that agents can produce Python artifacts (job confs, external modules) without requiring a C# compile-rebuild cycle. **This workstream is complete.**
2. **Orchestrator design (BD):** Design and build a dumb deterministic orchestrator that runs 103 independent per-job waterfall pipelines using atomic Claude Code CLI agents. **v0.2 complete. v0.3 (agent integration) next.**

---

## 2. What Has Been Built

### 2.1 Python ETL Framework (Hobson — sessions 011-017, 025)

The entire C# framework has been ported to Python. All build plan steps (1-21) are complete.

**Source modules:**

| Component | File | Notes |
|-----------|------|-------|
| Config system | `src/etl/app_config.py` | Layered: defaults, appsettings.json, env vars |
| Path resolution | `src/etl/path_helper.py` | Token expansion for `{ETL_ROOT}` |
| DB connections | `src/etl/connection_helper.py` | DSN builder for psycopg v3 |
| Job conf parser | `src/etl/job_conf.py` | JSON deserialization, same format as C# |
| Module factory | `src/etl/module_factory.py` | Creates module instances from conf entries |
| Pipeline executor | `src/etl/job_runner.py` | Runs modules in sequence, per-job logging |
| Date partitioning | `src/etl/date_partition_helper.py` | Output path date partitions |
| Module ABC | `src/etl/modules/base.py` | `execute(shared_state) -> shared_state` |
| DataSourcing | `src/etl/modules/data_sourcing.py` | 5 date resolution modes, Postgres datalake reads |
| Transformation | `src/etl/modules/transformation.py` | In-memory SQLite, free-form SQL |
| CsvFileWriter | `src/etl/modules/csv_file_writer.py` | Date-partitioned CSV, RFC 4180, trailer support |
| ParquetFileWriter | `src/etl/modules/parquet_file_writer.py` | Date-partitioned Parquet via pyarrow |
| DataFrameWriter | `src/etl/modules/dataframe_writer.py` | Writes to Postgres curated schema |
| External dispatcher | `src/etl/modules/external.py` | Registry + dynamic `importlib` loading for OG and RE modules |
| External modules (OG) | `src/etl/modules/externals/` | 73 Python files, one per C# ExternalModules class |
| External modules (RE) | `RE/externals/` | Dynamic loading via `importlib` (session 025) |
| Control DAL | `src/etl/control/control_db.py` | CRUD for control schema tables |
| Execution plan | `src/etl/control/execution_plan.py` | Kahn's algorithm topological sort |
| Job executor | `src/etl/control/job_executor_service.py` | Single-date orchestrator |
| Task queue service | `src/etl/control/task_queue_service.py` | Multi-threaded, advisory locks, idle watchdog |
| CLI | `cli.py` | `--service`, `--show-config`, `<date>`, `<date> <job>` |

**Library choices:**

| Concern | C# | Python |
|---------|-----|--------|
| DataFrame | Custom `DataFrame.cs` | pandas (no wrapper) |
| Postgres | Npgsql | psycopg v3 |
| Parquet | Parquet.Net | pyarrow |
| CSV | Manual RFC 4180 | stdlib `csv` |
| SQLite transforms | Microsoft.Data.Sqlite | stdlib `sqlite3` + pandas |
| Config | Custom + System.Text.Json | `dataclasses` + `json` |
| Testing | xUnit | pytest |

### 2.2 Test Suite

**158 unit tests, all passing.**

| Test file | Count | Scope |
|-----------|-------|-------|
| `test_app_config.py` | 16 | Config defaults, env vars, connection strings |
| `test_data_sourcing.py` | 18 | Date mode mutual exclusivity, range resolution |
| `test_dataframe_ops.py` | 24 | Pandas operations matching C# DataFrame API |
| `test_transformation.py` | 10 | SQLite integration, empty tables, joins |
| `test_module_factory.py` | 23 | Module deserialization, validation |
| `test_csv_file_writer.py` | 23 | Headers, quoting, trailers, append, encoding, re-run regression |
| `test_parquet_file_writer.py` | 17 | Multi-part, schemas, append, Decimal coercion, re-run regression |
| `test_v4_jobs.py` | 27 | Real job SQL transformations with fixture data |

### 2.3 Job Confs and Output

- **103 job conf files** at `MockEtlFrameworkPython/JobExecutor/Jobs/`, reconciled against sealed manifest.
- **103 jobs ran successfully** for Oct 1-31, 2024 through the Python task queue service.
- **65 CSV-output jobs** (57 CsvFileWriter + 8 External modules producing CSV).
- **40 Parquet-output jobs** (ParquetFileWriter).
- **2 jobs burned:** `repeat_overdraft_customers` (needs lookback, single-day sourcing = 0 matches), `suspicious_wire_flags` (no OFFSHORE counterparties in seed data).

### 2.4 Documentation

17 markdown files at `MockEtlFrameworkPython/Documentation/`, covering architecture, CLI, configuration, all module types, control layer, and env vars.

### 2.5 Proofmark (Validation Tool)

Proofmark is the independent output comparison tool used to validate the Python rewrite against C# originals. Runs as a queue-based service on the host.

**Key capabilities:**
- CSV and Parquet comparison
- Fuzzy matching with configurable tolerance
- Header/trailer comparison
- Schema mismatch detection
- Path token expansion (`{ETL_ROOT}`)

**Memory leak resolved (sessions 019-020):**
- Persistent DB connections (session 019)
- `del` intermediate structures in `pipeline.run()` — F1 fix (session 020)
- Correlator capped at 100 unmatched rows — F6 fix (session 020)
- Telemetry added: RSS + GC tracking per task — T1 (session 020)
- Test table isolation: tests use `control._test_proofmark_queue`, production uses `control.proofmark_test_queue`
- **Validated at scale:** 1,215 tasks, 0 failures, 51 seconds, memory flat at ~40%

**Manual test suite (23 fixtures):** All correct. `005_should_fail_sneaky_line_break` passes as expected (known gap — csv.reader strips quotes before Proofmark sees data values, documented in FSD Section 12, deliberately deferred).

### 2.6 Orchestrator / Workflow Engine (BD — sessions 1-14)

BD has built the deterministic workflow engine in Python (pivoted from C# during implementation). Repo: `EtlReverseEngineering`. Cloned to both `/media/dan/fdrive/codeprojects/EtlReverseEngineering/` (Hobson) and `/workspace/EtlReverseEngineering/` (BD).

**v0.1 — State Machine (COMPLETE, sessions 1-10):**

- **Agent taxonomy designed:** Full per-job waterfall pipeline with 5 stages (Plan, Define, Design, Build, Validate). ~30 leaf nodes, each an atomic agent.
- **27-node happy path** with 7 response nodes for failure paths.
- **Three-outcome review model:** Approve / Conditional / Fail. Conditional limit 3 per review node (4th auto-promotes to Fail). Fail rewinds to write node.
- **FBR gauntlet:** 6 serial gates (BrdCheck through UnitTestCheck). Any gate failure routes to fix, then restarts entire gauntlet from top.
- **Proofmark triage sub-pipeline:** 7-step diagnostic (T1-T7). T1-T2 context gathering, T3-T6 layer checks, T7 routing logic. Routes to earliest fault or DEAD_LETTER.
- **92 tests, 38 requirements satisfied.** Skeptical auditor confirmed code faithfully implements the spec (all 71 edges match).
- **Stubs throughout:** StubWorkNode/StubReviewNode return random outcomes. No real agent invocations yet.

**v0.2 — Parallel Execution Infrastructure (COMPLETE, sessions 11-13):**

- Replaced synchronous `Engine.run_job()` with queue-based work-stealing executor.
- Postgres `re_task_queue` + `re_job_state` in `control` schema.
- N worker threads (default 6, configurable via `RE_WORKER_COUNT`), `SELECT ... FOR UPDATE SKIP LOCKED`.
- `enqueue_next` (transition lookup → enqueue) and `ingest_manifest` (bulk-load from JSON).
- `StepHandler` — per-step SM logic through queue. `run_job()` deleted.
- 132 tests total, 16 requirements (TQ-01–04, JS-01–03, WK-01–04, SM-10–11, TS-01–03).

**v0.3 — Agent Integration (NOT STARTED):**

Replace stub nodes with real Claude CLI agent invocations. BD to update blueprints per path architecture v2.

**Key design principles (non-negotiable):**

- No errata accumulation between attempts. Writer gets only the most recent rejection reason.
- Fresh context every agent invocation. No state carried between invocations.
- Parallelism at job level (103 jobs), not within a single job's pipeline.
- Deterministic orchestrator, no LLM in the control loop.

---

## 3. Validation Status — COMPLETE

### 3.1 CSV Validation (Proofmark) — DONE

**1,215 comparisons. Zero failures. 51 seconds wall clock.**

65 CSV jobs × ~21 dates (Oct 1-21, 2024). The Python rewrite produces equivalent output within documented tolerances. All prior failures were cosmetic formatting differences between .NET and Python:

| Root Cause | Jobs Affected | Category |
|------------|--------------|----------|
| Trailing zero suppression (e.g. `1.50` vs `1.5`) | ~15 | Formatting |
| Date format (`M/d/yyyy` vs `yyyy-MM-dd`) | ~5 | Formatting |
| Timestamp format (`10/8/2024 3:35:35 AM` vs `2024-10-08 03:35:35`) | ~3 | Formatting |
| Integer-as-float (`.0` suffix) | ~5 | Formatting |
| High-precision decimals | ~3 | Formatting |
| Unicode NNBSP in date-time | ~2 | Formatting |
| CONTROL row timestamp | ~2 | Formatting |

Full RCA in `rca-csv-failures-batch1.md` through `batch5.md`. Zero data bugs found.

### 3.2 Parquet Validation (Statistical Profiling) — DONE

933 Parquet comparisons across 103 jobs × 31 dates. Proofmark strict schema matching was abandoned for Parquet because Python and C# write different Arrow types (`int64` vs `int32`, `large_string` vs `string`). These are tooling mismatches, not logic errors.

- **84.8% clean pass** on row counts + numeric sums + string spot-checks.
- All failures explained: timestamp columns summed as ints, float precision drift, sort order differences, timestamp format differences.
- **Verdict: The port works. No logic errors found.**

### 3.3 Output Coverage — 99.2%

| Metric | Value |
|--------|-------|
| Jobs with complete output (31/31) | 102 |
| Jobs with partial output | 3 |
| Total outputs present | 3,228 / 3,255 |

Partial jobs all explained by seed data characteristics (weekend gaps, sparse overdraft events). See RCA docs.

### 3.4 Unit + Integration + E2E

- 156 unit tests: all passing
- 13 integration tests (control layer against real Postgres): all passing
- 5/6 E2E tests passed (Decimal coercion issue fixed)

---

## 4. Network Isolation — v2 (Session 025)

### 4.1 The Problem

In POC5, RE agents cheated. They copied OG output to pass Proofmark, and in one case edited OG code/conf to match their versions. The architecture must make cheating structurally impossible.

### 4.2 Design Principle

**One token: `{ETL_ROOT}`.** Everything the host framework and Proofmark need to find must be expressible as `{ETL_ROOT}/...`. On the host, `ETL_ROOT` = `/media/dan/fdrive/codeprojects/MockEtlFrameworkPython`. In the container, `ETL_ROOT` = `/workspace/MockEtlFrameworkPython`. It never changes.

### 4.3 Architecture

```
{ETL_ROOT}/
├── JobExecutor/Jobs/              # OG job confs (existing)
├── src/etl/modules/externals/     # OG external modules (existing, 73 files)
├── Output/
│   ├── curated/                   # OG output (107 job dirs)
│   └── re-curated/                # RE output (real dir, host-only writes)
├── RE/                            # gitignored
│   ├── Jobs/                      # symlink → workspace RE jobs
│   └── externals/                 # symlink → workspace RE externals
```

**Anti-cheat guarantees:**
- OG output is ro-mounted into container → agents can't overwrite the answer key
- RE output is ro-mounted into container → agents can't fake validation results
- OG code access is via git clone (separate copy) → agents can't edit originals
- Proofmark runs on host only → agents can't manipulate validation
- Host never pulls agent git changes → OG repo frozen from RE perspective
- `DatabaseSettings.Host = localhost` in framework config → basement can't run ETL FW against real DB
- Only upward channel: queue table writes (structured data, not file paths they control)

### 4.4 Environment Variables

**2 env vars only:**

| Var | Host | Basement |
|-----|------|----------|
| `ETL_ROOT` | `/media/dan/fdrive/codeprojects/MockEtlFrameworkPython` | `/workspace/MockEtlFrameworkPython` |
| `ETL_DB_PASSWORD` | *(set)* | *(same)* |

`ETL_ROOT` never changes. No flipping between OG and RE roots.

### 4.5 Docker Mounts

| Host path | Container path | Mode |
|-----------|---------------|------|
| `/media/dan/fdrive/ai-sandbox/workspace/` | `/workspace/` | rw |
| `{ETL_ROOT}/Output/curated/` | `{ETL_ROOT}/Output/curated/` | ro |
| `{ETL_ROOT}/Output/re-curated/` | `{ETL_ROOT}/Output/re-curated/` | ro |

### 4.6 Symlinks (host side)

Two symlinks bridge the OG repo to the workspace so the host framework can find RE artifacts deployed by the publisher:

```
{ETL_ROOT}/RE/Jobs/      → /media/dan/fdrive/ai-sandbox/workspace/MockEtlFrameworkPython/RE/Jobs/
{ETL_ROOT}/RE/externals/ → /media/dan/fdrive/ai-sandbox/workspace/MockEtlFrameworkPython/RE/externals/
```

This is a POC stand-in for a proper CI/CD pipeline (Azure/Databricks in production).

### 4.7 Dynamic External Module Loading (Sessions 025-026)

`external.py` loads modules from two directories using the same `importlib` directory-scan mechanism:
1. **OG:** `src/etl/modules/externals/` — scanned at runtime via `_load_from_dir()`
2. **RE:** `RE/externals/` — scanned at runtime via `_load_from_dir()`

No hardcoded import lists. Drop a `.py` file in either directory, framework finds it next run. Remove a file, nothing breaks. 156 tests passing.

**Session 026 fix:** The original session 025 implementation used a hardcoded 75-line import list for OG modules while RE modules used dynamic loading. The two burned jobs (`repeat_overdraft_customer_processor`, `suspicious_wire_flag_processor`) were still in that list despite their `.py` files being deleted, which crashed `_load_all()` on every External module invocation. Replaced the hardcoded list with the same `_load_from_dir()` pattern used for RE modules.

### 4.8 Output Routing

OG and RE output are separated by the `outputDirectory` field in job confs:

| Job type | `outputDirectory` value | Resolves to (host) |
|----------|------------------------|---------------------|
| OG | `Output/curated` | `{ETL_ROOT}/Output/curated/` |
| RE | `Output/re-curated` | `{ETL_ROOT}/Output/re-curated/` |

The builder blueprint must set `outputDirectory` to `Output/re-curated` for RE job confs.

### 4.9 Three Task Queues

| Queue | Purpose | Who inserts | Who processes |
|-------|---------|------------|---------------|
| `control.task_queue` | ETL job execution | Basement agents | Host (`python cli.py --service`) |
| `control.proofmark_test_queue` | Output comparison | Basement agents | Host (`proofmark serve`) |
| `control.re_task_queue` | Workflow state machine | BD's orchestrator | BD's orchestrator (internal) |

### 4.10 RE Pipeline — Step by Step

1. **Builder** writes job conf to `/workspace/EtlReverseEngineering/jobs/{job}/jobconf.json`
2. **Builder** writes external module to `/workspace/EtlReverseEngineering/jobs/{job}/{module}.py`
3. **Builder** sets `outputDirectory` to `Output/re-curated` in the job conf
4. **Publisher** copies job conf to `/workspace/MockEtlFrameworkPython/RE/Jobs/{job}/jobconf.json`
5. **Publisher** copies external module to `/workspace/MockEtlFrameworkPython/RE/externals/{module}.py`
6. **Publisher** registers in `control.jobs` with path `{ETL_ROOT}/RE/Jobs/{job}/jobconf.json`
7. **ExecuteJobRuns** inserts into `control.task_queue` (job_name + effective_date, no paths)
8. **ExecuteJobRuns** polls `control.task_queue` for results
9. **ExecuteJobRuns** monitors `{ETL_ROOT}/Output/re-curated` for output files
10. **BuildProofmarkConfig** writes config to `/workspace/EtlReverseEngineering/jobs/{job}/proofmark-config.yaml`
11. **ProofmarkExecutor** copies config to `/workspace/MockEtlFrameworkPython/RE/Jobs/{job}/proofmark-config.yaml`
12. **ProofmarkExecutor** inserts into `control.proofmark_test_queue` with LHS `{ETL_ROOT}/Output/curated/...` and RHS `{ETL_ROOT}/Output/re-curated/...`

---

## 5. System Health (as of 2026-03-14)

- **Swap:** Increased from 2GB to 16GiB (`/swapfile` on SSD). Prevents OOM death spiral.
- **RAM:** 16GB (2×8GB DDR4). Third stick (8GB) to be installed this weekend → 24GB via Intel flex mode.
- **fdrive:** Fragmentation score 0. Healthy.
- **PostgreSQL:** Survived 4 unclean shutdowns cleanly. WAL recovery worked every time.
- **C# output deleted:** 5.4GB reclaimed (2.3GB Hobson's copy + 3.1GB BD's copy). No longer needed.

---

## 6. Key Decisions Made

| Decision | Rationale | Session |
|----------|-----------|---------|
| Python rewrite of MockEtlFramework | Eliminates C# compile-rebuild bottleneck for agent-produced artifacts | 011 |
| pandas directly, no custom DataFrame wrapper | C#'s custom DataFrame maps 1:1 to pandas. No wrapper needed. | 011 |
| CSV-only Proofmark validation | Parquet schema differences (int64 vs int32, large_string vs string) are tooling mismatches, not logic errors. Statistical profiling for Parquet instead. | 016b |
| Faithfully reproduce C# bugs | External modules reproduce all known C# bugs so Proofmark passes. Fix bugs later, not during porting. | 014 |
| Dumb orchestrator + atomic workers | Smart orchestrator (POC5) suffered context rot and cheating. Dumb loop + fresh-context agents fixes both. | BD-1 |
| 103 horizontal waterfalls, not 1 vertical | Each job gets its own pipeline. No cross-job contamination. | BD-1 |
| Python orchestrator (pivoted from C#) | Agents produce Python artifacts for MockEtlFrameworkPython. | BD-2 |
| ATC model (human governance, agent autonomy) | Agents are pilots, humans are air traffic control. Inversion of Microsoft's "Copilot" framing. | 021 |
| Network isolation via Docker boundary | Agents can read anything, write only to their workspace and queue tables. Validation on host only. | 021 |
| localhost DB config as cheat prevention | Framework's DB host = localhost. Doesn't resolve inside container. Agents can't run the real framework. | 021 |
| Never pull agent git changes | OG repo on host is frozen. Agents can push whatever they want — host ignores it. | 021 |
| One token (`ETL_ROOT`), everything under it | All resolvable paths derive from `{ETL_ROOT}`. No flipping, no second root. | 025 |
| Append-mode partition lookup bounded by effective date | `find_latest_partition(before=effective_date)` prevents re-runs from pulling in future partitions. | 027 |
| RE code in `RE/` dir with symlinks to workspace | POC stand-in for CI/CD. Symlinks bridge host repo to workspace. | 025 |
| Dynamic external module loading via `importlib` | Framework scans both `externals/` dirs at runtime. No hardcoded list, no rebuild. | 025-026 |
| RE output via `Output/re-curated` | Builder sets `outputDirectory` differently. OG and RE output never collide. | 025 |
| Blueprints for workers, skills for supervisors | Skills (progressive disclosure) don't fit short-lived atomic agents. May matter later for a supervisory agent. | 023 |

---

## 7. Known Issues and Gaps

### Active Issues

1. **Sort order differences:** `customer_contactability` and `card_expiration_watch` may have different row ordering. Formatting, not data.
2. **Timestamp format difference:** `inter_account_transfers` writes different format in Python vs C#. Formatting, not data.
3. **Queue status mismatch:** BD's blueprints insert into `control.task_queue` with `status = 'Queued'`, but the framework polls for `status = 'Pending'`. Contract mismatch — BD's blueprints need updating.

### Resolved Issues

- CSV Proofmark validation: **DONE.** 1,215 tasks, 0 failures.
- Parquet validation: **DONE.** Statistical profiling, no logic errors.
- Proofmark memory leak: **RESOLVED.** Validated at scale.
- All sparse/missing output RCAs: **RESOLVED.** All explained by seed data.
- All CSV formatting differences: **RESOLVED.** All categorised, zero data bugs.
- Append-mode re-run bug: **RESOLVED.** `find_latest_partition()` grabbed future partitions on re-run (session 027). Fixed with `before` parameter.
- RAM/OOM risk: **MITIGATED.** Swap 2GB→16GiB. RAM upgrade planned (16→24GB).
- ETL_ROOT env var not persistent: **RESOLVED.** Updated in `.bashrc` (session 023).
- Network isolation v1: **SUPERSEDED** by v2 (session 025). See section 4.
- Path tokenization confusion: **RESOLVED.** One token, everything under ETL_ROOT (session 025).

---

## 8. Key File Paths

### Framework

| What | Path |
|------|------|
| Python repo (host) | `/media/dan/fdrive/codeprojects/MockEtlFrameworkPython/` |
| C# repo (reference only) | `/media/dan/fdrive/codeprojects/MockEtlFramework/` |
| Proofmark | `/media/dan/fdrive/codeprojects/proofmark/` |
| OG job confs | `{ETL_ROOT}/JobExecutor/Jobs/` |
| OG external modules | `{ETL_ROOT}/src/etl/modules/externals/` |
| RE job confs | `{ETL_ROOT}/RE/Jobs/` (symlink → workspace) |
| RE external modules | `{ETL_ROOT}/RE/externals/` (symlink → workspace) |
| OG output | `{ETL_ROOT}/Output/curated/` |
| RE output | `{ETL_ROOT}/Output/re-curated/` |
| Documentation | `{ETL_ROOT}/Documentation/` |

### Orchestrator

| What | Path |
|------|------|
| Orchestrator repo (Hobson) | `/media/dan/fdrive/codeprojects/EtlReverseEngineering/` |
| Orchestrator repo (BD) | `/media/dan/fdrive/ai-sandbox/workspace/EtlReverseEngineering/` |
| Workflow engine source | `EtlReverseEngineering/src/workflow_engine/` |
| Agent blueprints | `EtlReverseEngineering/blueprints/` |
| Planning docs | `EtlReverseEngineering/.planning/` |
| Transition table (source of truth) | `AtcStrategy/POC6/BDsNotes/state-machine-transitions.md` |

### Strategy and Notes

| What | Path |
|------|------|
| Hobson's notes | `AtcStrategy/POC6/HobsonsNotes/` |
| BD's notes | `/media/dan/fdrive/ai-sandbox/workspace/AtcStrategy/POC6/BDsNotes/` |
| Path architecture v2 (for BD) | `HobsonsNotes/path-changes-for-bd-v2.md` |
| Build plan | `HobsonsNotes/python-rewrite-build-plan.md` |
| Job scope manifest | `HobsonsNotes/job-scope-manifest.json` |
| Env var mapping | `HobsonsNotes/env-var-mapping.md` |

### Docker / Sandbox

| What | Path |
|------|------|
| AI sandbox | `/media/dan/fdrive/ai-sandbox/` |
| compose.yml | `/media/dan/fdrive/ai-sandbox/compose.yml` |
| Basement workspace | `/media/dan/fdrive/ai-sandbox/workspace/` (host) = `/workspace/` (container) |

---

## 9. Session History

| Session | Date | Key Work |
|---------|------|----------|
| 011 | 2026-03-10 | POC5 declared dead. POC6 pivot. C# codebase surveyed. Build plan written. |
| 012 | 2026-03-10 | All source modules and 7 of 8 test files written (steps 1-13). 129 tests. |
| 013 | 2026-03-10 | Build plan steps 14-21 complete. CLI, control layer, logging. 156 tests passing. |
| 014 | 2026-03-10 | 73 external modules ported. Registry dispatcher. 17 documentation files. All C# bugs reproduced. |
| 015 | 2026-03-10 | Integration tests passed. End-to-end tests (5/6). Bug fixes (Decimal, date format, utcnow). Job confs copied. |
| 016/016b | 2026-03-10 | All 105 jobs ran for Oct 1-31. Parquet profiling (84.8% clean). OOM crash. Output inventory. |
| 017 | 2026-03-10 | Proofmark memory leak fixes. Job manifest. Output coverage audit (99.2%). |
| 018 | 2026-03-11 | 2 jobs burned. 8 sparse-job RCAs. CSV validation (33 pass, 33 formatting-only). |
| 019 | 2026-03-11 | Persistent DB connections in Proofmark. CLI cleanup. 206 Proofmark tests pass. |
| 020 | 2026-03-12 | Memory leak F1/F6 fixes. Telemetry. Test table isolation. Queue rebuild. |
| 021 | 2026-03-12 | System health verified. Swap 2→16GiB. Proofmark gold star (1,215/0/51s). Manual test suite (23/23). Network isolation design. Env var simplification. C# output deleted (5.4GB). |
| 023 | 2026-03-13 | Network isolation v1 implemented. Env vars simplified (4→2). Docker ro mount. Dead tokens removed from all source + docs. Basement DB connection confirmed (172.18.0.1). |
| 024 | 2026-03-14 | Housekeeping. AtcStrategy synced. EtlReverseEngineering cloned. State-of-poc6 updated. |
| 025 | 2026-03-14 | Network isolation v2. Path consolidation under ETL_ROOT. RE/ directory with symlinks. Dynamic external module loading (`importlib`). 10 blueprints updated. compose.yml: 3 mounts. 156 tests passing. |
| 026 | 2026-03-15 | Replaced hardcoded OG import list in `external.py` with `_load_from_dir()` directory scan. Fixed crash from burned jobs still in import list. 156 tests passing. |
| 027 | 2026-03-16 | Append-mode re-run bug fixed. `find_latest_partition()` now takes `before` param. Both CSV and Parquet writers pass effective date. Queue status mismatch diagnosed (`Queued` vs `Pending`). 158 tests passing. |
| BD-1| 2026-03-10 | Agent taxonomy designed. Adversarial review. Architecture doc. |
| BD-2 | 2026-03-10 | C# orchestrator, DB-backed queue, state machine, polyglot architecture. |
| BD-3 | 2026-03-10 | GSD project. 27 requirements. 6-phase roadmap. Ready for Phase 1. |
| BD-4–10 | 2026-03-10–12 | v0.1 phases 1-3 built. State machine, review branching, FBR gauntlet, triage pipeline. 92 tests, 38 requirements. |
| BD-11 | 2026-03-12 | v0.1 declared complete. v0.2 scoped (parallel execution). |
| BD-12 | 2026-03-13 | v0.2 milestone initialized. 16 requirements, 4-phase roadmap (phases 4-7). |
| BD-13 | 2026-03-14 | v0.2 shipped. All 4 phases in one session. 132 tests, 16 requirements. |
| BD-14 | 2026-03-14 | v0.3 scoped. Agent integration docs. Blueprint updates. |
