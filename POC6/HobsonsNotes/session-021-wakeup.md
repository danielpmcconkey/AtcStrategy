# POC6 Session 022 — Wake-Up Prompt

## Copy-paste this into Hobson when you start the next session:

```
Go read /media/dan/fdrive/codeprojects/AtcStrategy/POC6/HobsonsNotes/session-022-wakeup.md — that's your wakeup prompt. Read it, absorb it, then tell me you're ready.
```

---

## Who You Are

You are Hobson. Your CLAUDE.md and MEMORY.md are already loaded.

## What Happened Session 021

### System health after power outages

Four unclean shutdowns in 48 hours (2 power outages + 1 memory leak hard cycle + 1 more). Full system check:

- **dmesg:** Clean. Only pre-existing ACPI BIOS bugs on the Z170XP-SLI (Gigabyte SATA port references — cosmetic, every boot).
- **journalctl -b -p err:** Clean. SGX disabled (irrelevant), keyring confusion on hard boot (self-resolved), casper-md5check (live USB leftover).
- **PostgreSQL:** 4 crash recoveries logged, all completed in ~1 second. No corruption, no PANIC, no FATAL during recovery. WAL replay worked as designed.
- **Filesystem (ext4):** No errors. `e4defrag -c` on fdrive: fragmentation score 0.

### Swap space fix

Swap was 2GB (default Ubuntu) on a 16GB RAM machine — useless. Resized to **16 GiB** (`/swapfile` on SSD `sdb`). This gives the OOM killer room to act before the system goes comatose from thrashing.

Commands run:
```bash
sudo swapoff /swapfile
sudo fallocate -l 16G /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

### RAM upgrade planned

Dan has a third 8GB DDR4 stick ready to install this weekend (16GB → 24GB). Intel flex mode: 16GB dual-channel + 8GB single-channel. Negligible bandwidth difference.

### Proofmark — Gold Star

**POC6 validation run (from session 020):** 1,215 tasks, 0 failures, 51 seconds wall clock. Memory flat at ~40%. The pipeline.run() `del` fix (F1) and correlator cap (F6) resolved the memory leak completely.

**Manual test suite (23 fixtures, run this session):** All 23 behaved correctly:
- should_pass tests → PASS (001, 009, 010, 011, 015, 021, 022)
- should_fail tests → FAIL (002, 003, 004, 006, 007, 008, 012, 013, 014, 016, 017, 018, 019, 020, 023)
- 005_should_fail_sneaky_line_break → PASS (known gap — too sneaky for Proofmark, by design)

**013 config name fix:** `comparison_target` in `013_should_fail_no_quotes.yaml` said `013_should_pass_no_quotes`. Corrected to `013_should_fail_no_quotes`. The test itself was always behaving correctly (FAIL via header comparison).

**013 quote detection gap:** Confirmed as documented and deliberately deferred. FSD-v1.md Section 12 rates it HIGH risk for production and recommends a two-layer architecture (pre-parse dialect + parsed data). MVP intentionally does header-only detection because `csv.reader` strips quotes before Proofmark sees data values.

### MockEtlFrameworkPython — Gold Star

The Python rewrite produces **equivalent output within documented tolerances** across all 65 CSV jobs × 21 dates. Failures from earlier runs were all cosmetic formatting differences between .NET and Python ecosystems (quoting, line endings, float representation), evaluated and accepted.

### Cleanup — 5.4GB reclaimed

- `/media/dan/fdrive/codeprojects/MockEtlFramework/Output/*` — nuked (2.3GB). C# original output, no longer needed.
- `/media/dan/fdrive/ai-sandbox/workspace/MockEtlFramework/Output/*` — nuked (3.1GB). BD's copy, same.
- `Output/` directories themselves preserved (empty).

### fdrive health

`e4defrag -c`: Fragmentation score 0. Only fragmented files were a handful of 4KB PersonalFinance Monte Carlo logs. No defrag needed.

## State of POC6 — What's Changed

`state-of-poc6.md` (dated 2026-03-11) is now stale on several points:

| Item | Was | Now |
|------|-----|-----|
| CSV Proofmark validation (P3) | Not started | **DONE.** 1,215/1,215 PASS. |
| Known issue #3 (CSV run not completed) | Open | **Resolved.** |
| Known issue #6 (RAM constraint) | 16GB, OOM risk | Swap fixed (16GiB). RAM upgrade to 24GB planned for weekend. |
| C# Output directories | Reference data for Proofmark | **Deleted.** No longer needed. |
| Proofmark memory leak (known issue) | Fixes applied, not validated at scale | **Validated.** 1,215 tasks, flat memory, 51 seconds. |

### Still open from state-of-poc6.md

| Priority | Task | Status |
|----------|------|--------|
| P1 | Investigate OverdraftAmountDistribution 11 missing dates | Not started |
| P2 | Cross-check weekend gaps (HoldingsBySector, FundAllocationBreakdown) vs C# | Not started |
| P4 | Sort order differences (if any surfaced in Proofmark run) | Check Proofmark results |
| P5 | Timestamp format in `inter_account_transfers` | Not started |

### Orchestrator side (BD)

No changes this session. Still at Phase 1 planning (GSD). No code written.

## Your Job Next Session

Dan wanted to "move on to ATC POC6" — the session ended before we got into specifics. Follow his lead.

## Key Files

| What | Path |
|------|------|
| State of POC6 (stale — update if needed) | `AtcStrategy/POC6/HobsonsNotes/state-of-poc6.md` |
| Job manifest (103 jobs) | `AtcStrategy/POC6/HobsonsNotes/job-scope-manifest.json` |
| Memory leak RCA | `AtcStrategy/POC6/HobsonsNotes/rca-memory-leak-pipeline.md` |
| Proofmark FSD (013 quote gap, Section 12) | `/media/dan/fdrive/codeprojects/proofmark/Documentation/OriginalBuildDocs/Design/FSD-v1.md` |
| Manual test fixtures | `/media/dan/fdrive/codeprojects/proofmark/tests/fixtures/dan_manual_test/` |
| Python repo | `/media/dan/fdrive/codeprojects/MockEtlFrameworkPython/` |
| Proofmark repo | `/media/dan/fdrive/codeprojects/proofmark/` |
| Queue table (validation results) | `atc` DB → `control.proofmark_test_queue` |

## Standing Rules

- Only Hobson writes code to MockEtlFrameworkPython.
- Read the C# source before writing each Python component.
- Job conf files must work as-is (same JSON format, same field names).
- 103 jobs in scope (2 burned: repeat_overdraft_customers, suspicious_wire_flags).
- CSV validation: accepted as "good enough" — all failures are cosmetic.
- Parquet validation: use data profiling, not Proofmark.
- **Do NOT run `pytest tests/` in Proofmark without understanding that test_queue.py will DROP and recreate `control._test_proofmark_queue`.** The production table is `control.proofmark_test_queue` — they are separate, but be aware.
