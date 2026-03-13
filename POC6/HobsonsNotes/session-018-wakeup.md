# POC6 Session 019 — Wake-Up Prompt

## Copy-paste this into Hobson when you start the next session:

```
Go read /media/dan/fdrive/codeprojects/AtcStrategy/POC6/HobsonsNotes/session-018-wakeup.md — that's your wakeup prompt. Read it, absorb it, then tell me you're ready.
```

---

## Who You Are

You are Hobson. Your CLAUDE.md and MEMORY.md are already loaded.

## What Happened Session 018

Housekeeping, validation, and RCA session. No ETL code changes.

### Memory reset

Dan flagged that Hobson's memory files were stale from mid-session crashes. He provided a corrected narrative and we held off updating memory until the session stabilized. **Memory files have NOT been updated yet.** Do that early in session 019.

### Background agents produced reference docs (all in HobsonsNotes):

- `state-of-poc6.md` — comprehensive summary of all POC6 work across 20 source files
- `inventory-csharp-output.md` — full inventory of C# curated output (22,296 files, 105 jobs, Oct-Dec 2024)
- `inventory-python-output.md` — full inventory of Python curated output (7,400 files, 105→103 jobs, Oct 2024 only)

### Burned 2 broken jobs

`repeat_overdraft_customers` and `suspicious_wire_flags` were fundamentally broken against the seed data on both C# and Python sides. Removed from:
- `control.jobs` (deleted rows)
- Job manifest (`job-scope-manifest.json`, count updated to 103)
- Job conf JSON files and external module Python files (deleted)

Also truncated: `control.proofmark_test_queue`, `control.task_queue`, `control.job_runs` (clean slate).

### RCA on suspicious output gaps (all in HobsonsNotes):

Investigated 8 jobs with irregular output coverage. Results:

| Job(s) | Verdict | RCA file |
|--------|---------|----------|
| card_expiration_watch | Clean — datalake gaps + transient C# failure | `rca-card-expiration-watch.md` |
| overdraft cluster (3 jobs) | Clean — sparse seed data x weekday-only dimensions | `rca-overdraft-cluster.md` |
| overdraft_amount_distribution | Clean — sparse seed data, both sides match | `rca-overdraft-amount-distribution.md` |
| inter_account_transfers | Clean — collision-based detection, data rarely collides | `rca-inter-account-transfers.md` |
| repeat_overdraft_customers | Broken by design — burned | `rca-empty-jobs.md` |
| suspicious_wire_flags | Broken by design — burned | `rca-empty-jobs.md` |

### CSV Proofmark validation — COMPLETE

Ran all 66 CSV outputs (65 jobs + dans_transaction_special's 2 sub-outputs) for 2024-10-01. Results: **33 PASS, 33 FAIL.**

Dan accepted all failures as cosmetic / "good enough for POC." No logic bugs found.

All 33 failures are formatting differences. RCA details in:
- `rca-csv-failures-batch1.md` through `rca-csv-failures-batch5.md`

Root causes (all formatting, zero data bugs):

| Root Cause | Jobs Affected |
|---|---|
| Trailing-zero formatting (`500` vs `500.0`) | ~20 jobs |
| Date format (`10/1/2024` vs `2024-10-01`) | ~5 jobs |
| Timestamp separator (`T` vs space) | ~3 jobs |
| CONTROL row timestamp (different run dates) | 2 jobs |
| Non-deterministic RNG (phone numbers) | 1 job (`communication_channel_map`) |

Also noted: `account_velocity_tracking` C# file is corrupted (doubled rows). One C# floating-point bug in `dans_transactions_by_state_province` that Python gets right.

### Proofmark config files

Created 8 missing Proofmark CSV config files in `/media/dan/fdrive/codeprojects/proofmark/configs/`:
- account_velocity_tracking, compliance_transaction_ratio, fund_allocation_breakdown, holdings_by_sector, overdraft_amount_distribution, peak_transaction_times, preference_by_segment, wire_direction_summary

### ETL_ROOT env var

`.bashrc` still points `ETL_ROOT` at the C# repo (`MockEtlFramework`). Yesterday's update was session-only and didn't persist. Not fixed yet — we used full paths for this session. `ETL_RE_OUTPUT` and `ETL_RE_ROOT` also still point to old C# paths. Defer fixing until we figure out what they should be for POC6.

## Your Job Next Session

### Priority 1: Data profiling on parquet files

Dan wants to validate the 38 parquet jobs by comparing C# and Python output using data profiling (not Proofmark — parquet schema differences between .NET and Python make byte-level comparison impractical).

Approach TBD — design a profiling strategy:
- Row counts per job per date
- Column names and types
- Basic statistical profiles (min, max, mean, nulls) per column
- Compare profiles across C# and Python output
- Flag any jobs where profiles diverge significantly

### Priority 2: Update memory files

Hobson's memory files are stale. Update `atc-poc5.md` (rename to `atc-poc6.md`) with current POC6 status based on this session's work. Update MEMORY.md to reference the new file.

## Key Files

| What | Path |
|------|------|
| State of POC6 | `AtcStrategy/POC6/HobsonsNotes/state-of-poc6.md` |
| Build plan | `AtcStrategy/POC6/HobsonsNotes/python-rewrite-build-plan.md` |
| Job manifest (103 jobs) | `AtcStrategy/POC6/HobsonsNotes/job-scope-manifest.json` |
| Output format list | `AtcStrategy/POC6/HobsonsNotes/job-output-formats.md` |
| C# output inventory | `AtcStrategy/POC6/HobsonsNotes/inventory-csharp-output.md` |
| Python output inventory | `AtcStrategy/POC6/HobsonsNotes/inventory-python-output.md` |
| CSV failure RCAs | `AtcStrategy/POC6/HobsonsNotes/rca-csv-failures-batch[1-5].md` |
| Gap RCAs | `AtcStrategy/POC6/HobsonsNotes/rca-*.md` |
| Python repo | `/media/dan/fdrive/codeprojects/MockEtlFrameworkPython/` |
| C# repo (reference only) | `/media/dan/fdrive/codeprojects/MockEtlFramework/` |
| Proofmark | `/media/dan/fdrive/codeprojects/proofmark/` |

## Standing Rules

- Only Hobson writes code to MockEtlFrameworkPython.
- Read the C# source before writing each Python component.
- Job conf files must work as-is (same JSON format, same field names).
- Hobson writes checkpoint files at milestones to survive crashes.
- 103 jobs in scope (2 burned: repeat_overdraft_customers, suspicious_wire_flags).
- CSV validation: accepted as "good enough" — all failures are cosmetic.
- Parquet validation: use data profiling, not Proofmark.
