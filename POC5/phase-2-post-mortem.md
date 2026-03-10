# Phase 2 Post-Mortem: GSD Quality Assessment

**Date:** 2026-03-09
**Phase:** 02 — Tier 2 Simple Multi-Source (10 jobs)
**Execution:** 4 parallel GSD executor agents, 1 wave, ~55 min wall clock

## What Was Tested

Phase 2 RE'd 10 multi-source ETL jobs (6 CSV, 4 Parquet) using GSD's parallel
execution workflow. This was the first phase with Parquet output and the first
at 10-job scale. After GSD reported completion, two independent background agents
were dispatched to manually verify quality — one auditing anti-pattern remediation,
one profiling actual output data.

## Anti-Pattern Remediation Audit

**Method:** Agent read every V1 job conf, every external module, every RE job conf,
and every anti-pattern assessment. Cross-referenced claims against actual code.

**Result:** Solid reverse engineering. 9 of 10 jobs had real anti-patterns, all
substantively remediated.

| Job | Anti-Patterns Found (V1) | Remediated? | Notes |
|-----|--------------------------|-------------|-------|
| CustomerAccountSummary | None | N/A | Clean job, no APs |
| SecuritiesDirectory | AP1 (dead `holdings` source) | Yes | Entire DataSourcing module removed |
| TransactionSizeBuckets | AP1 (dead `accounts`), AP4 (3 unused cols), AP8 (dead CTE + ROW_NUMBER) | Yes | Source removed, cols trimmed, CTE eliminated |
| CardAuthorizationSummary | AP4 (3 unused cols), AP7 (integer division), AP8 (dead ROW_NUMBER + dead CTE) | Yes | Cols removed, dead code removed. AP7 intentionally preserved (load-bearing V1 behavior) |
| FeeWaiverAnalysis | AP1 (dead `accounts` JOIN), AP4 (9 unused cols) | Yes | Cols trimmed. Dead JOIN intentionally retained (conservative posture, documented) |
| TopBranches | AP4 (unused `visit_id`), AP8/AP10 (dead WHERE clause) | Yes | Column removed, WHERE eliminated |
| CardStatusSnapshot | AP4 (5 of 6 sourced cols unused) | Yes | Reduced to 1 sourced column |
| TopHoldingsByValue | AP4 (4 unused cols), AP8 (dead `unused_cte`) | Yes | Cols trimmed, CTE removed |
| AccountOverdraftHistory | AP4 (5 unused cols across 2 sources) | Yes | Both sources trimmed |
| PreferenceChangeCount | AP1 (dead `customers` source), AP4 (unused cols), AP8 (dead RANK()) | **Mostly** | Source removed, RANK removed. But `preference_id` still sourced despite being unused after RANK removal. Assessment doc claims it was removed — it wasn't. |

### Finding: PreferenceChangeCount Discrepancy

The anti-pattern assessment for PreferenceChangeCount states that `preference_id`
was removed from the DataSourcing columns. The actual RE job conf still has it.
With the RANK() window function removed (AP8), `preference_id` has no SQL reference.
This is a minor residual AP4 — one extra column sourced with no functional impact —
but the documentation is inaccurate about what was delivered.

**GSD did not catch this.** The executor agent wrote the assessment claiming removal,
the verifier agent confirmed via grep patterns but didn't cross-check the specific
column against the actual conf. The verification report's anti-pattern section was
too compressed to surface this level of detail.

## Data Output Spot-Check

**Method:** Agent pulled actual files off disk for 10 run dates per job (100 total
checks). Profiled row counts, schemas, file sizes. Diffed 3 dates per job against
V1 original output.

**Result:** Clean bill of health.

| Job | Format | Row Range | Cols | V1 Match | Notes |
|-----|--------|-----------|------|----------|-------|
| CustomerAccountSummary | CSV | 0-2,230 | 6 | 3/3 exact | Zero-row dates match V1 |
| SecuritiesDirectory | CSV | 50 | 8 | 3/3 exact | Static ref data, constant |
| TransactionSizeBuckets | CSV | 5 | 6 | 3/3 exact | 5 buckets always |
| CardAuthorizationSummary | CSV | 0-2 | 7 | 3/3 exact | Zero-row dates match V1 |
| FeeWaiverAnalysis | CSV | 0-2 | 6 | 3/3 exact | Zero-row dates match V1 |
| TopBranches | CSV | 40 | 6 | 3/3 data match | Trailer timestamp differs (expected — wall clock) |
| CardStatusSnapshot | Parquet | 0-3 | 4 | Match | Empty dates consistent with V1 |
| TopHoldingsByValue | Parquet | 0-20 | 9 | Match | Empty dates consistent with V1 |
| AccountOverdraftHistory | Parquet | 0-3 | 9 | Match | Empty dates consistent with V1 |
| PreferenceChangeCount | Parquet | 2,230 | 6 | 3/3 exact | 1 row per customer, constant |

No empty files masquerading as populated. No schema drift. No corruption. No
suspicious patterns across dates.

## Execution Issues

### Race Condition: File Write vs Task Queue

All 4 agents exhibited a race condition where they queued framework tasks and/or
Proofmark comparisons before the config files were written to disk.

- **Framework side:** First task in batch hits "Could not find a part of the path
  '{job_conf}.json'" → fail-fast cascades → entire batch SKIPPEd
- **Proofmark side:** Workers claim tasks → "FileNotFoundError: No such file or
  directory: '{proofmark_config}.yaml'" → task marked Failed permanently

Agents self-recovered by writing the files and re-queuing. Framework retries
succeeded. Proofmark required deleting failed rows and re-queuing those dates.

**Impact:** Added ~15-20 min of wall clock time per agent. Lots of ugly console
output. No data integrity impact.

**Root cause:** Plans don't enforce "write all config files → verify on disk →
then queue tasks" ordering. The lesson was captured in SUMMARY.md deviation notes
but NOT in any file that future planner agents will read (re-blueprint.md,
PROJECT.md, or CLAUDE.md).

**Likelihood of recurrence:** High. The lesson is buried in a SUMMARY that
executors don't reference. Needs to be added to re-blueprint.md or PROJECT.md
constraints to actually propagate.

## Verification Report Quality

The GSD verifier produced a passing report (7/7 must-haves) that was technically
accurate but poorly structured for human review:

- Anti-pattern remediation details were crammed into a single table cell with
  abbreviations ("AP1: holdings/accounts/customers removed from SD/TSB/PCC confs")
- The same information appeared in 3 different places at 3 different detail levels
- No per-job breakdown — impossible to tell which patterns were in which jobs
- The PreferenceChangeCount `preference_id` discrepancy was not caught

The verification report answers "did they do it?" but not "what did they do?"
For a human reviewer, the report is close to useless for understanding the actual
remediation work.

## Scorecard

| Metric | Result |
|--------|--------|
| Proofmark PASS | 920/920 (100%) |
| Anti-pattern remediation | 9/9 jobs substantively remediated (1 minor residual) |
| Data integrity | 100/100 spot-checks clean |
| Documentation accuracy | 1 inaccuracy (PreferenceChangeCount assessment) |
| Execution efficiency | ~55 min wall clock (with ~15 min wasted on race conditions) |
| Verification report quality | Technically correct, practically opaque |
| Self-healing | Agents recovered from race conditions autonomously |

## Verdict

GSD delivered correct output. The RE work itself is solid — anti-patterns found,
remediated, data verified. The tooling around it (verification reports, execution
ordering, documentation accuracy) has rough edges that compound as phase complexity
grows.
