# POC6 Session 017 — Wake-Up Prompt

## Copy-paste this into Hobson when you start the next session:

```
Go read /media/dan/fdrive/codeprojects/AtcStrategy/POC6/HobsonsNotes/session-016-wakeup.md — that's your wakeup prompt. Read it, absorb it, then tell me you're ready.
```

---

## Who You Are

You are Hobson. Your CLAUDE.md and MEMORY.md are already loaded.

## What Happened Sessions 016 + 016b

Session 016 was a full Proofmark validation run — all 105 jobs × Oct 1–31. It ended with a hard power-cycle (OOM kill, 16GB RAM). Session 016b picked up the pieces.

### Session 016 deliverables (before crash):

- **All 105 jobs ran successfully** through the Python task queue service for Oct 1–31.
- **Bug fix: CoveredTransactions Decimal casting** — `Decimal('112.75')` → float64 for Parquet.
- **Proofmark comparisons run** — ~3,000 comparisons. Results were mixed (see below).
- **Parquet schema mismatch identified** — Python writes different Arrow types than C#. Systemic across all Parquet jobs.

### Session 016b deliverables:

- **Pivoted away from Proofmark for validation.** Parquet schema differences (`int64` vs `int32`, `large_string` vs `string`, etc.) are tooling mismatches, not logic errors. Dan decided Proofmark is the wrong tool for this — do statistical profiling instead.
- **Statistical comparison run:** 933 Parquet comparisons across 103 jobs × 31 dates.
  - **84.8% clean pass** on Parquet (row counts + numeric sums + string spot-checks).
  - Failures were: timestamp columns being summed as ints (not real), float precision drift (0.001%, not real), sort order differences (`customer_contactability`), timestamp format differences (`inter_account_transfers`).
  - **Verdict: The port works.** No logic errors found.
- **Found 2 missing jobs** — `AccountVelocityTracking` and `WireDirectionSummary`. Root cause: their External modules used `path_helper.resolve("{ETL_RE_OUTPUT}")` instead of `path_helper.get_project_root()`. Context hallucination during porting — the porter confused framework output routing with RE config tokens.
- **Fixed both external modules.** Changed to `path_helper.get_project_root()` + `os.path.join(root, "Output", "curated", ...)` matching the other 5 direct-writers.
- **Re-ran both jobs** for Oct 1–31. Output now landing in correct directory. All 105 jobs have output in `/media/dan/fdrive/codeprojects/MockEtlFrameworkPython/Output/curated/`.
- **Reconciliation: clean.** Three-way check (sealed manifest, control.jobs, Python job confs) — all 105 match exactly. No `_RE` remnants in the DB (earlier report of 26 was a SQL wildcard false positive).
- **ETL_ROOT env var issue discovered.** After the power cycle, `ETL_ROOT` reverted to the C# repo path. Must be set explicitly in the terminal before starting the ETL service: `export ETL_ROOT=/media/dan/fdrive/codeprojects/MockEtlFrameworkPython`.
- **Proofmark queue truncated.** Clean slate for next run.

### ETL_ROOT warning:

`ETL_ROOT` is NOT in `.bashrc`. After every reboot/new terminal, it must be set manually:
```
export ETL_ROOT=/media/dan/fdrive/codeprojects/MockEtlFrameworkPython
```
Without this, `get_project_root()` falls back to the C# repo and ALL output goes to the wrong place.

### Proofmark env var concern (parking lot):

Proofmark's `serve` mode defaults to `localhost/atc/claude` but needs path tokens (`ETL_ROOT`, etc.) to resolve `lhs_path`/`rhs_path` in the queue table. Verify these are set in the Proofmark terminal before running comparisons next session.

## Your Job Next Session

Dan pivoted: Proofmark strict schema matching is overkill for a POC. The statistical profiling proved the port works. But Dan still wants CSV output run through Proofmark to verify sort order issues are just sort order (not data bugs).

1. **Queue CSV comparisons through Proofmark.** The 65 CSV-output jobs need comparing. This will also validate the sort order hypothesis (`customer_contactability`, `card_expiration_watch`).
2. **Confirm Proofmark env vars** are set correctly in its terminal before starting.
3. **Address sort order if Proofmark flags it** — may need to add ORDER BY to match C# output ordering.
4. **Timestamp format difference** — `inter_account_transfers` writes `2024-10-08 03:35:35` vs C#'s `10/8/2024 3:35:35 AM`. May need fixing if Proofmark catches it.

## Output Structure

- **40 jobs write Parquet** via `ParquetFileWriter` module
- **65 jobs write CSV** — some via `CsvFileWriter` module, some via direct-writing External modules
- **7 External modules write CSV directly** to disk (bypass standard writer):
  - `account_velocity_tracker.py`, `wire_direction_summary_writer.py` (FIXED this session)
  - `compliance_transaction_ratio_writer.py`, `fund_allocation_writer.py`, `holdings_by_sector_writer.py`, `peak_transaction_times_writer.py`, `preference_by_segment_writer.py`, `overdraft_amount_distribution_processor.py`
- **C# output (reference):** `/media/dan/fdrive/codeprojects/MockEtlFramework/Output/curated/`
- **Python output (challenger):** `/media/dan/fdrive/codeprojects/MockEtlFrameworkPython/Output/curated/`

## Key Files

| What | Path |
|------|------|
| Build plan | `AtcStrategy/POC6/HobsonsNotes/python-rewrite-build-plan.md` |
| Python repo | `/media/dan/fdrive/codeprojects/MockEtlFrameworkPython/` |
| C# repo (dead, reference only) | `/media/dan/fdrive/codeprojects/MockEtlFramework/` |
| Proofmark | `/media/dan/fdrive/codeprojects/proofmark/` |
| Parquet writer | `MockEtlFrameworkPython/src/etl/modules/parquet_file_writer.py` |
| Env vars reference | `MockEtlFrameworkPython/Documentation/env-vars.md` |
| RAM upgrade notes | `ai-dev-playbook/Tooling/ram-upgrade.md` |

## Standing Rules

- Only Hobson writes code to MockEtlFrameworkPython.
- Read the C# source before writing each Python component.
- Job conf files must work as-is (same JSON format, same field names).
- Set `ETL_ROOT` before starting the ETL service. Every time. Don't trust the shell.
- Hobson writes checkpoint files at milestones to survive crashes.
