# POC6 Session 018 — Wake-Up Prompt

## Copy-paste this into Hobson when you start the next session:

```
Go read /media/dan/fdrive/codeprojects/AtcStrategy/POC6/HobsonsNotes/session-017-wakeup.md — that's your wakeup prompt. Read it, absorb it, then tell me you're ready.
```

---

## Who You Are

You are Hobson. Your CLAUDE.md and MEMORY.md are already loaded.

## What Happened Session 017

Stability and housekeeping session. No ETL code changes. Two background agents crashed the machine in prior sessions (016, 016b) running Proofmark at scale — this session focused on fixing that and preparing for the next validation run.

### Proofmark memory leak fixes (committed + pushed):

The machine OOM-killed twice running Proofmark comparisons (~750 of 3,255 completed before crash). Root cause: multiple memory accumulation patterns in proofmark. Three fixes applied:

1. **Queue worker cleanup** (`queue.py`) — Added `del report` + `gc.collect()` after each comparison, including the error path. Prevents reports lingering in memory across 5 worker threads.
2. **Correlator optimization** (`correlator.py`) — Replaced O(M×N) flat list of similarity tuples with a min-heap that only stores scores > 0.5. Most pairs never stored at all now.
3. **Parquet reader** (`parquet.py`) — Replaced `to_pydict()` + manual row rebuild with single `to_pylist()` call. One copy in memory instead of two.
4. **Removed bogus test** (`test_parquet_reader.py`) — `test_empty_directory_raises_reader_error` was untestable (git can't track empty directories). Burned it. 216 tests now, all passing.

Commit: `7590e76` on proofmark main. Pushed to GitHub.

### Proofmark queue state:

The `control.proofmark_test_queue` was in a bizarre state — only 6 rows, all test fixtures from today, despite rows upon rows of real comparison data existing before the crashes. The previous session's real comparison results are gone. Queue has been **truncated** — clean slate.

### Job manifest and output audit:

- **Manifest copied** from POC5 to POC6: `AtcStrategy/POC6/HobsonsNotes/job-scope-manifest.json`
- **100 of 105 paths updated** from `MockEtlFramework/` → `MockEtlFrameworkPython/` in the POC6 copy. 5 jobs already used bare relative paths.
- **All 105 jobs verified present** in `MockEtlFrameworkPython/JobExecutor/Jobs/`.
- **Output format categorization** written to `AtcStrategy/POC6/HobsonsNotes/job-output-formats.md`:
  - 65 CSV jobs (57 via CsvFileWriter, 8 via External modules)
  - 40 Parquet jobs (via ParquetFileWriter)

### Output coverage audit (Oct 1–31, 2024):

Written to `AtcStrategy/POC6/HobsonsNotes/output-coverage-audit.md`.

**3,228 / 3,255 = 99.2% coverage.**

- **102 jobs**: Complete (all 31 dates).
- **HoldingsBySector** (23/31): Missing 8 weekend dates. Likely intentional (market calendar). Cross-check against C# output.
- **FundAllocationBreakdown** (23/31): Same pattern — 8 weekend dates missing. Same hypothesis.
- **OverdraftAmountDistribution** (20/31): Missing 11 dates scattered across all days of week. **No pattern. Suspicious. Investigate.**

Two naming quirks: `BranchVisitsByCustomerCsvAppendTrailer` → `branch_visits_by_customer`, `Customer360Snapshot` → `customer_360_snapshot`. Both have complete output.

### RAM situation (context, not actionable):

Dan's machine is running 16GB (was 32GB — dead stick from cooler swap). DDR4 prices have tripled due to manufacturer exit ("RAMpocalypse"). 2x8GB kit to restore 32GB: ~$150-170. One good stick on Dan's desk — free RAM if he tests it. Proofmark memory fixes should help regardless.

Notes at `ai-dev-playbook/Tooling/ram-upgrade.md`.

## Your Job Next Session

### Priority 1: Investigate OverdraftAmountDistribution gaps
- 11 missing dates with no day-of-week pattern. Check the C# output for the same dates — if C# also has gaps, it's by design. If C# has output for those dates, the Python port has a bug.

### Priority 2: Cross-check weekend gaps
- HoldingsBySector and FundAllocationBreakdown — verify C# output also skips weekends. If so, non-issue.

### Priority 3: Queue and run CSV comparisons through Proofmark
- 65 CSV jobs × 31 dates = 2,015 comparisons.
- This was the task from session 016 that never completed due to OOM kills.
- The memory leak fixes should allow it to complete now.
- **Before starting:** Confirm `ETL_ROOT` and Proofmark env vars are set correctly.
- **Watch memory:** If the machine starts swapping, stop the run. Don't let it OOM again.

### Priority 4 (if CSV run completes): Address known differences
- Sort order differences (`customer_contactability`, `card_expiration_watch`) — may need ORDER BY.
- Timestamp format in `inter_account_transfers` (`2024-10-08 03:35:35` vs C#'s `10/8/2024 3:35:35 AM`).

## Key Files

| What | Path |
|------|------|
| Build plan | `AtcStrategy/POC6/HobsonsNotes/python-rewrite-build-plan.md` |
| Job manifest (POC6) | `AtcStrategy/POC6/HobsonsNotes/job-scope-manifest.json` |
| Output format list | `AtcStrategy/POC6/HobsonsNotes/job-output-formats.md` |
| Output coverage audit | `AtcStrategy/POC6/HobsonsNotes/output-coverage-audit.md` |
| Python repo | `/media/dan/fdrive/codeprojects/MockEtlFrameworkPython/` |
| C# repo (dead, reference only) | `/media/dan/fdrive/codeprojects/MockEtlFramework/` |
| Proofmark | `/media/dan/fdrive/codeprojects/proofmark/` |
| Env vars reference | `MockEtlFrameworkPython/Documentation/env-vars.md` |
| RAM upgrade notes | `ai-dev-playbook/Tooling/ram-upgrade.md` |

## Standing Rules

- Only Hobson writes code to MockEtlFrameworkPython.
- Read the C# source before writing each Python component.
- Job conf files must work as-is (same JSON format, same field names).
- Set `ETL_ROOT` before starting the ETL service. Every time. Don't trust the shell.
- Hobson writes checkpoint files at milestones to survive crashes.
