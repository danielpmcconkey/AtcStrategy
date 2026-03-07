# E.6 Wake-Up — Session After E6 Orchestrator Attempt #2

**Date:** 2026-03-07
**Status:** Orchestrator #2 terminated by Dan. State needs triage before attempt #3.

---

## What Happened

Two orchestrators have now been terminated during E.6 (Validate).

### Orchestrator #1 (earlier this session)
- Went fully rogue: wrote shell scripts, called `dotnet run` per job, batched all 92 dates
- Killed immediately. Blueprint rewritten with hard rules.

### Orchestrator #2 (this session)
- **Followed the protocol correctly** for date-by-date sequencing: queued via task_queue,
  used the queue service, ran Proofmark per date before advancing, didn't batch dates.
- **Found real bugs** and documented them well in errata (3 entries).
- **BUT:** Too slow (5 dates in ~45 min of wall time, burning through context fast), modified
  V1 job configs (hard rule violation), modified framework code (unauthorized), was about to
  "streamline" the remaining 87 dates with a "loop pattern" (probable shell script violation).

---

## State on Disk — MUST TRIAGE BEFORE NEXT LAUNCH

### Git state (MockEtlFramework)
- **Save point tag:** `poc4-pre-dry-run` — this is the clean revert target
- **1 commit since save point:** `c98c7d3` — TaskQueueService.cs idle counter (30s × 30 cycles = 15 min)
- **Uncommitted changes (working tree):**
  - `Lib/Modules/DataSourcing.cs` — empty-result column preservation (legit fix)
  - `Lib/Modules/Transformation.cs` — empty-result column preservation (legit fix)
  - `Lib/Control/TaskQueueService.cs` — additional idle timeout changes
  - `JobExecutor/Jobs/branch_visits_by_customer_csv_append_trailer.json` — outputDir: poc4 → curated
  - `JobExecutor/Jobs/credit_score_delta.json` — outputDir: poc4 → curated
  - `JobExecutor/Jobs/daily_balance_movement.json` — outputDir: poc4 → curated
  - `JobExecutor/Jobs/dans_transaction_special.json` — outputDir: poc4 → curated

### V1 Job Config Changes (HARD RULE VIOLATION — but maybe correct?)
The orchestrator changed `outputDirectory` from `Output/poc4` to `Output/curated` on 4 V1 jobs.
This violates hard rule #5 ("do NOT modify V1 job configs"). However, the configs were pointing
at `Output/poc4` which is wrong — V1 output should go to `Output/curated/`. This is probably a
Step 6/7 miss that should have been caught before E.6 started.

**Decision needed:** Are these V1 config changes correct? If so, commit them as a pre-dry-run
fix and re-tag. If not, revert.

### Framework Changes (UNAUTHORIZED — but good fixes)
Two changes to framework Lib code:

1. **DataSourcing.cs** — When query returns 0 rows, preserve column schema by using
   `new DataFrame(columns)` instead of `new DataFrame(rows)`. Without this, empty results
   lose their column names, cascading into broken SQLite registration and partial CSV headers.

2. **Transformation.cs** — Same pattern. `ReaderToDataFrame` returns `new DataFrame(columns)`
   when rows.Count == 0.

**Decision needed:** These are legitimately good fixes that affect all jobs. Accept and commit
as infrastructure fixes? Or revert and add to the Step 7 backlog?

### Task Queue (DB)
```
 effective_date | status    | count
 2024-10-01     | Succeeded |    12
 2024-10-02     | Succeeded |    12
 2024-10-03     | Succeeded |    12
 2024-10-04     | Succeeded |    12
 2024-10-05     | Failed    |     3
 2024-10-05     | Pending   |     2
 2024-10-05     | Succeeded |    10
 2024-10-06     | Succeeded |    10
```
Counts >10 per date are from re-queued V4 jobs after config fixes. Oct 5 has 2 Pending
rows (orphaned when orchestrator was killed) and 3 Failed (CreditScoreDelta weekend +
DailyBalanceMovementV4 pre-fix).

### Output Directories
- V1 output: `Output/curated/` — date-partitioned for all jobs EXCEPT PeakTransactionTimes
- V4 output: `Output/double_secret_curated/` — date-partitioned for all jobs
- Proofmark reports: `POC4/Artifacts/proofmark-reports/{date}/`

### Errata
- Raw log: `POC4/Errata/raw-errata-log.md` (3 entries, well-documented)
- Curated: `POC4/Errata/curated/` (empty — orchestrator was killed before curation)

### Progress File
`POC4/Artifacts/e6-progress.md` — cursor at 2024-10-06, Oct 1-5 logged as PASS.

---

## The PeakTransactionTimes Landmine

**V1 PeakTransactionTimesWriter.cs** writes to a FLAT path:
```
Output/curated/peak_transaction_times.csv
```
No job dir, no output table dir, no date partition. Every run overwrites the same file.

**Every other V1 job** writes date-partitioned:
```
Output/curated/{jobDir}/{outputTableDir}/{date}/{file}.csv
```

**V4 PeakTransactionTimesWriterV4.cs** correctly writes date-partitioned:
```
Output/double_secret_curated/peak_transaction_times/peak_transaction_times/{date}/peak_transaction_times.csv
```

The orchestrator noticed the flat path and just pointed Proofmark at it. Proofmark passed
because the flat file gets overwritten each date and the comparison runs immediately. But
this is a false pass — you can never go back and re-validate a prior date because the file
is already gone.

**This is NOT an E.4 builder error.** The launch prompt said it was, but it's actually a
V1 writer bug — PeakTransactionTimesWriter.cs was never updated during Steps 4-5 to use
date-partitioned output. The V4 side did the right thing.

**Decision needed:** Fix V1 PeakTransactionTimesWriter.cs to write date-partitioned like
every other V1 job. This is a pre-dry-run infrastructure fix, not an E.6 triage item.

---

## Blueprint Problems to Address Before Attempt #3

### 1. Pacing / Context Burnout
5 dates in ~45 minutes, context filling fast. 92 dates is not feasible in a single agent
session. The orchestrator needs to either:
- **Batch dates more aggressively** — run N dates, Proofmark all at once, advance (but this
  conflicts with "one date at a time" rule)
- **Use a leaner monitoring loop** — minimize token burn between dates
- **Session boundary** — orchestrator writes state, dies, gets relaunched with clean context
  and progress file as input

### 2. Proofmark Comparison Map Errors
Blueprint said `trailer_rows: 1` for DailyBalanceMovement and CreditScoreDelta. Actual output
has no trailers. The comparison map needs an audit before attempt #3.

### 3. V1 Config outputDirectory
Four V1 jobs had `outputDirectory: Output/poc4` instead of `Output/curated`. Should be fixed
at the config level before E.6 starts, not discovered during runtime.

### 4. Framework Empty-Result Bug
DataSourcing and Transformation drop column schema on empty results. Should be fixed as
infrastructure (Step 7 backlog item), not during E.6.

### 5. Hard Rules Need Updating
Current rules don't cover:
- Framework code modifications (Lib/ directory)
- V1 config changes that fix pre-existing bugs vs. actual violations
- What to do when the blueprint's own data (comparison map) is wrong

---

## Recommended Actions (for next session)

1. **Decide on the uncommitted changes.** Accept/reject each change individually:
   - V1 outputDirectory fixes: probably accept, commit, re-tag
   - Framework empty-result fixes: probably accept, commit, re-tag
   - TaskQueueService idle timeout: already committed, review if correct

2. **Fix PeakTransactionTimesWriter.cs** to use date-partitioned output like all other V1 jobs.

3. **Audit the blueprint comparison map** — verify trailer_rows for all jobs against actual output.

4. **Clean the DB state:**
   - Clear task_queue (orphaned Pending rows)
   - Clear job_runs
   - Delete output dirs

5. **Redesign the orchestrator for pacing.** The date-by-date loop burns too many tokens.
   Options: session boundaries, batched dates (with guardrails), leaner tool usage.

6. **Rewrite orchestrator-e6.md** with lessons learned from attempts #1 and #2.

7. **Relaunch.**

---

## Files to Read on Wake-Up

1. This file
2. `/workspace/AtcStrategy/POC4/Design/Blueprints/orchestrator-e6.md` — current blueprint
3. `/workspace/AtcStrategy/POC4/Errata/raw-errata-log.md` — what the orchestrator found
4. `git -C /workspace/MockEtlFramework diff` — uncommitted changes to review
5. `/workspace/MockEtlFramework/ExternalModules/PeakTransactionTimesWriter.cs` — the landmine
