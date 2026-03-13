# State of POC6

**Date:** 2026-03-13
**Author:** Hobson
**Status:** Framework complete. CSV + Parquet validation complete. Network isolation complete.

---

## 1. What POC6 Is

POC6 is the Python rewrite of the MockEtlFramework, replacing the original C# implementation. It exists because POC5 failed: the RE (reverse-engineering) agents cheated by copying OG (original) output to pass Proofmark validation, a systemic context-rot problem in the smart orchestrator design.

POC6 has two parallel workstreams:

1. **Framework rewrite (Hobson):** Rebuild the ETL framework in Python so that agents can produce Python artifacts (job confs, external modules) without requiring a C# compile-rebuild cycle. **This workstream is complete.**
2. **Orchestrator design (BD):** Design and build a dumb deterministic orchestrator that runs 103 independent per-job waterfall pipelines using atomic Claude Code CLI agents. This workstream is in early design/planning.

---

## 2. What Has Been Built

### 2.1 Python ETL Framework (Hobson — sessions 011-017)

The entire C# framework has been ported to Python. All build plan steps (1-21) are complete.

**Source modules:**

| Component | File | Notes |
|-----------|------|-------|
| Config system | `src/etl/app_config.py` | Layered: defaults, appsettings.json, env vars |
| Path resolution | `src/etl/path_helper.py` | Token expansion for `{ETL_ROOT}`, `{ETL_RE_OUTPUT}`, `{ETL_RE_ROOT}` |
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
| External dispatcher | `src/etl/modules/external.py` | Registry-based dispatcher (was stub, now full) |
| External modules | `src/etl/modules/externals/` | 73 Python files, one per C# ExternalModules class |
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

**156 unit tests, all passing.**

| Test file | Count | Scope |
|-----------|-------|-------|
| `test_app_config.py` | 16 | Config defaults, env vars, connection strings |
| `test_data_sourcing.py` | 18 | Date mode mutual exclusivity, range resolution |
| `test_dataframe_ops.py` | 24 | Pandas operations matching C# DataFrame API |
| `test_transformation.py` | 10 | SQLite integration, empty tables, joins |
| `test_module_factory.py` | 23 | Module deserialization, validation |
| `test_csv_file_writer.py` | 22 | Headers, quoting, trailers, append, encoding |
| `test_parquet_file_writer.py` | 16 | Multi-part, schemas, append, Decimal coercion |
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
- Path token expansion (`{ETL_ROOT}`, `{ETL_RE_OUTPUT}`, `{ETL_RE_ROOT}`)

**Memory leak resolved (sessions 019-020):**
- Persistent DB connections (session 019)
- `del` intermediate structures in `pipeline.run()` — F1 fix (session 020)
- Correlator capped at 100 unmatched rows — F6 fix (session 020)
- Telemetry added: RSS + GC tracking per task — T1 (session 020)
- Test table isolation: tests use `control._test_proofmark_queue`, production uses `control.proofmark_test_queue`
- **Validated at scale:** 1,215 tasks, 0 failures, 51 seconds, memory flat at ~40%

**Manual test suite (23 fixtures):** All correct. `005_should_fail_sneaky_line_break` passes as expected (known gap — csv.reader strips quotes before Proofmark sees data values, documented in FSD Section 12, deliberately deferred).

### 2.6 Orchestrator Design (BD — sessions 1-3)

BD has been working on the agent pipeline that will use the Python framework:

- **Agent taxonomy designed:** Full per-job waterfall pipeline with 5 stages (Plan, Define, Design, Build, Validate). Each leaf node is an atomic agent.
- **Adversarial review completed:** Reviewed taxonomy against Dan's POC5 vision.
- **Architecture decided:** C# orchestrator (EtlReverseEngineering repo), DB-backed task queue, 6 worker threads, state machine per job, agents invoked via `claude -p` CLI.
- **GSD project initiated:** 27 v1 requirements across 5 categories, 6-phase roadmap.
- **Status:** Phase 1 planning/discussion stage. No orchestrator code written yet.

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

## 4. Network Isolation — COMPLETE

### 4.1 The Problem

In POC5, RE agents cheated. They copied OG output to pass Proofmark, and in one case edited OG code/conf to match their versions. The architecture must make cheating structurally impossible.

### 4.2 Design Principle: Air Traffic Control

The model is **humans as air traffic control, agents as pilots.** Agents have autonomy within their lane. Routing, sequencing, and "cleared to land" decisions are human. Validation instruments (Proofmark, queue tables, control schema) are on the host side where agents can't tamper with them. This is a deliberate inversion of Microsoft's "Copilot" framing.

### 4.3 Architecture

```
------------------------------------ host (↑) ------------------------------------

  OG ETL code/conf    OG curated output    Postgres (read+write)
  MockEtlFrameworkPython service            Proofmark service

------------------------------------ network boundary (Docker) --------------------

  Read: OG code (git clone)     Read: OG output (ro mount)
  Read: control.* tables        Read: re-curated output
  Write: queue tables only      Write: RE code/conf (workspace)

------------------------------------ basement (↓) --------------------------------
```

**Anti-cheat guarantees:**
- Agents never write to OG output directories → can't copy answer key
- Agents never write to OG code/conf → can't edit originals to match
- Proofmark runs on host only → agents can't manipulate validation
- Host never pulls agent git changes → OG repo frozen from RE perspective
- `DatabaseSettings.Host = localhost` in framework config → basement can't run ETL FW against real DB (localhost inside container = nothing)
- Only upward channel: queue table writes (structured data, not file paths they control)

### 4.4 Environment Variables — Proposed Simplification

**POC5 (dead):** 4 env vars (`ETL_ROOT`, `ETL_RE_OUTPUT`, `ETL_RE_ROOT`, `ETL_DB_PASSWORD`)

**POC6 (implemented):** 2 env vars

| Var | Host (OG runs) | Host (RE validation) | Basement |
|-----|----------------|---------------------|----------|
| `ETL_ROOT` | `/media/dan/fdrive/codeprojects/MockEtlFrameworkPython` | `/media/dan/fdrive/ai-sandbox/workspace/MockEtlFrameworkPython` | `/workspace/MockEtlFrameworkPython` |
| `ETL_DB_PASSWORD` | *(set)* | *(same)* | *(same)* |

`ETL_RE_ROOT` and `ETL_RE_OUTPUT` were POC5 artifacts from C#'s inability to dynamically load external modules. Removed from `.bashrc`, `compose.yml`, Proofmark, and ETL FW source (session 023).

The host flips `ETL_ROOT` depending on whether it's running OG or validating RE output. Same framework code, different artifact source.

### 4.5 Docker Mounts — Implemented

| Host path | Container path | Mode |
|-----------|---------------|------|
| `/media/dan/fdrive/ai-sandbox/workspace/` | `/workspace/` | rw (existing) |
| `/media/dan/fdrive/codeprojects/MockEtlFrameworkPython/Output/curated/` | `/workspace/og-curated/` | **ro** (session 023) |

**Important:** Only mount output directories, not git repos. OG code access is via git clone (separate `.git`, no conflicts).

### 4.6 Output Directory Layout — Implemented

| Directory | Purpose | Who writes | Who reads |
|-----------|---------|-----------|-----------|
| `/media/dan/fdrive/codeprojects/MockEtlFrameworkPython/Output/curated/` | OG output | Host ETL FW (OG runs) | Host Proofmark (LHS) |
| `/media/dan/fdrive/ai-sandbox/workspace/re-curated/` | RE output | Host ETL FW (RE validation runs) | Host Proofmark (RHS), Basement (read via mount) |
| `/workspace/og-curated/` (container) | OG output mirror | Nobody (ro mount) | Basement RE team (reference) |

### 4.7 Path Tokenization

Proofmark already supports `{ETL_ROOT}`, `{ETL_RE_OUTPUT}`, `{ETL_RE_ROOT}` token expansion in queue paths (`app_config.py` → `PathSettings.resolve()`). The ETL framework has the same token expansion in `path_helper.py`.

**Implemented:** Agents write all paths using `{ETL_ROOT}/...` tokens. Both Proofmark and the ETL framework expand them on the host side. No string replacement hacks needed. Simplified to `{ETL_ROOT}` only — `{ETL_RE_OUTPUT}` and `{ETL_RE_ROOT}` removed from all source code (session 023).

### 4.8 Use Cases and Resolution

| # | Use Case | Resolution |
|---|----------|-----------|
| 1 | RE team reads OG code/conf | Git clone in basement. Separate repo, separate `.git`. |
| 2 | RE team reads OG curated output | Read-only Docker mount at `/workspace/og-curated/` |
| 3 | RE team writes code/conf that host FW executes | Write to `/workspace/MockEtlFrameworkPython/`. Host sees via bind mount at `/media/dan/fdrive/ai-sandbox/workspace/MockEtlFrameworkPython/`. |
| 4 | Host FW writes RE output without overwriting OG | Writes to `/media/dan/fdrive/ai-sandbox/workspace/re-curated/`. Basement reads via bind mount. |
| 5 | RE team writes Proofmark queue entries with resolvable paths | All paths use `{ETL_ROOT}/...` tokens. Host Proofmark expands them. |
| 6 | RE team registers jobs in `control.jobs` with resolvable paths | Same token expansion. `{ETL_ROOT}/JobExecutor/Jobs/my_job.json`. |
| 7 | RE team specifies external module paths in job conf JSON | Same token expansion. `{ETL_ROOT}/src/etl/modules/externals/my_module.py`. |

### 4.9 Implementation — DONE (Session 023)

| Task | Where | Status |
|------|-------|--------|
| Update host `ETL_ROOT` to MockEtlFrameworkPython | `.bashrc` line 120 | Done |
| Update basement `ETL_ROOT` to `/workspace/MockEtlFrameworkPython` | `compose.yml` | Done |
| Kill `ETL_RE_ROOT` and `ETL_RE_OUTPUT` from Docker config | `compose.yml` | Done |
| Kill `ETL_RE_ROOT` and `ETL_RE_OUTPUT` from host `.bashrc` | `.bashrc` | Done |
| Remove `ETL_RE_ROOT`/`ETL_RE_OUTPUT` from Proofmark's `PathSettings` | `proofmark/app_config.py` | Done |
| Remove `ETL_RE_ROOT`/`ETL_RE_OUTPUT` from ETL FW's `path_helper.py` + `app_config.py` | `MockEtlFrameworkPython/src/etl/` | Done |
| Add read-only Docker mount for OG curated output | `compose.yml` | Done |
| Create `re-curated` directory | `/media/dan/fdrive/ai-sandbox/workspace/re-curated/` | Done |
| Create host-side symlink for og-curated | `og-curated` → OG curated output | Done |
| Update documentation (6 files across both repos) | Proofmark + ETL FW docs | Done |
| Verify Proofmark path token expansion | 206 tests passing | Done |
| Verify ETL FW path token expansion | 156 tests passing | Done |
| Confirm basement DB connection (bridge gateway IP) | `172.18.0.1`, `claude` role, 103 jobs visible | Done |

---

## 5. System Health (as of 2026-03-12)

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
| C# orchestrator, Python artifacts | Orchestrator in EtlReverseEngineering (C#), agents produce Python artifacts for MockEtlFrameworkPython. | BD-2 |
| ATC model (human governance, agent autonomy) | Agents are pilots, humans are air traffic control. Inversion of Microsoft's "Copilot" framing. | 021 |
| Network isolation via Docker boundary | Agents can read anything, write only to their workspace and queue tables. Validation on host only. | 021 |
| Simplify to 2 env vars | `ETL_RE_ROOT` and `ETL_RE_OUTPUT` are POC5 C# artifacts. Python's dynamic loading makes them unnecessary. | 021 |
| localhost DB config as cheat prevention | Framework's DB host = localhost. Doesn't resolve inside container. Agents can't run the real framework. | 021 (carried from POC5) |
| Never pull agent git changes | OG repo on host is frozen. Agents can push whatever they want — host ignores it. | 021 |

---

## 7. Known Issues and Gaps

### Active Issues

1. **Sort order differences:** `customer_contactability` and `card_expiration_watch` may have different row ordering. Formatting, not data.
2. **Timestamp format difference:** `inter_account_transfers` writes different format in Python vs C#. Formatting, not data.

### Resolved Issues

- CSV Proofmark validation: **DONE.** 1,215 tasks, 0 failures.
- Parquet validation: **DONE.** Statistical profiling, no logic errors.
- Proofmark memory leak: **RESOLVED.** Validated at scale.
- All sparse/missing output RCAs: **RESOLVED.** All explained by seed data.
- All CSV formatting differences: **RESOLVED.** All categorised, zero data bugs.
- RAM/OOM risk: **MITIGATED.** Swap 2GB→16GiB. RAM upgrade planned (16→24GB).
- ETL_ROOT env var not persistent: **RESOLVED.** Updated in `.bashrc` (session 023).
- Network isolation: **RESOLVED.** Fully implemented (session 023). See section 4.

---

## 8. Key File Paths

### Framework

| What | Path |
|------|------|
| Python repo | `/media/dan/fdrive/codeprojects/MockEtlFrameworkPython/` |
| C# repo (reference only) | `/media/dan/fdrive/codeprojects/MockEtlFramework/` |
| Proofmark | `/media/dan/fdrive/codeprojects/proofmark/` |
| Job confs | `MockEtlFrameworkPython/JobExecutor/Jobs/` |
| Python OG output | `MockEtlFrameworkPython/Output/curated/` |
| Documentation | `MockEtlFrameworkPython/Documentation/` |

### Strategy and Notes

| What | Path |
|------|------|
| Hobson's notes | `AtcStrategy/POC6/HobsonsNotes/` |
| BD's notes | `/media/dan/fdrive/ai-sandbox/workspace/AtcStrategy/POC6/BDsNotes/` |
| Build plan | `HobsonsNotes/python-rewrite-build-plan.md` |
| Job scope manifest | `HobsonsNotes/job-scope-manifest.json` |
| Env var mapping | `HobsonsNotes/env-var-mapping.md` |
| Memory leak RCA | `HobsonsNotes/rca-memory-leak-pipeline.md` |
| CSV failure RCAs | `HobsonsNotes/rca-csv-failures-batch1.md` through `batch5.md` |
| Proofmark FSD (quote gap) | `proofmark/Documentation/OriginalBuildDocs/Design/FSD-v1.md` (Section 12) |

### Docker / Sandbox

| What | Path |
|------|------|
| AI sandbox | `/media/dan/fdrive/ai-sandbox/` |
| Launch script | `/media/dan/fdrive/ai-sandbox/launch.sh` |
| Docker guide | `/home/dan/Desktop/claude-docker-guide.md` |
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
| 023 | 2026-03-13 | Network isolation implemented. Env vars simplified (4→2). Docker ro mount. Dead tokens removed from all source + docs. Basement DB connection confirmed (172.18.0.1). |
| BD-1 | 2026-03-10 | Agent taxonomy designed. Adversarial review. Architecture doc. |
| BD-2 | 2026-03-10 | C# orchestrator, DB-backed queue, state machine, polyglot architecture. |
| BD-3 | 2026-03-10 | GSD project. 27 requirements. 6-phase roadmap. Ready for Phase 1. |
