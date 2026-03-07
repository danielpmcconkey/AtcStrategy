# Orchestrator Blueprint — E.6: Validate

**Scope:** Run all V1 and V4 jobs across 92 effective dates (Oct 1 – Dec 31, 2024),
compare output with Proofmark, triage failures, iterate until all jobs pass.

---

## HARD RULES — VIOLATIONS ARE GROUNDS FOR TERMINATION

1. **You do NOT execute jobs directly.** No `dotnet run -- <date> <job>`. Ever.
   The queue service executes jobs. You populate the queue and monitor results.
2. **You do NOT write shell scripts.** No bash scripts, no automation wrappers.
   You are the automation. Use your tools directly.
3. **You do NOT batch all 92 dates at once.** You process date-by-date per the
   progression protocol below. Each date must pass Proofmark before advancing.
4. **You do NOT clear the task queue.** You INSERT into it. The service reads it.
   If you need to re-run, INSERT new rows.
5. **You do NOT modify V1 job configs, V1 External modules, or Proofmark source code.**
6. **You update the progress file after EVERY date completes.** Not after batches.
   Not at the end. After. Every. Date.

---

## How the ETL Framework Queue Service Works

The MockEtlFramework has a built-in queue service. You must understand this.

### Starting the service
```bash
dotnet run --project /workspace/MockEtlFramework/JobExecutor -- --service
```
The first `--` separates dotnet CLI args from program args. `--service` is the
program arg that activates queue mode.

**The service auto-exits after 15 minutes of empty queue.** Start it before
queuing work. If it has exited by the time you queue the next date, start it
again. It is safe to start multiple times — it just polls the queue.

### How it executes jobs
- Polls `control.task_queue` for rows with `status = 'Pending'`
- Claims tasks using `FOR UPDATE SKIP LOCKED` (thread-safe, no races)
- 4 threads handle `execution_mode = 'parallel'` tasks concurrently
- 1 thread handles `execution_mode = 'serial'` tasks sequentially
- Updates `task_queue.status`: `Pending` → `Running` → `Succeeded` or `Failed`
- Creates entries in `control.job_runs` with `triggered_by = 'queue'`

### Your job as orchestrator
1. INSERT rows into `control.task_queue` with: job_name, effective_date, execution_mode
2. Poll `control.task_queue` to monitor completion
3. React to results (run Proofmark, triage, advance cursor)

That's it. You are the brain. The service is the hands.

---

## The 10 Jobs

| Job Name | Job ID | Type | execution_mode |
|----------|--------|------|----------------|
| PeakTransactionTimes | 165 | V1 | parallel |
| DailyBalanceMovement | 166 | V1 | parallel |
| CreditScoreDelta | 369 | V1 | parallel |
| BranchVisitsByCustomerCsvAppendTrailer | 371 | V1 | serial |
| DansTransactionSpecial | 373 | V1 | serial |
| PeakTransactionTimesV4 | 374 | V4 | parallel |
| DailyBalanceMovementV4 | 375 | V4 | parallel |
| CreditScoreDeltaV4 | 376 | V4 | parallel |
| BranchVisitsByCustomerCsvAppendTrailerV4 | 377 | V4 | serial |
| DansTransactionSpecialV4 | 378 | V4 | serial |

**Why serial?** BranchVisitsByCustomerCsvAppendTrailer and DansTransactionSpecial
have append-mode CSV writers. Running them in parallel across dates causes
cross-date output contamination. Queue them as `execution_mode = 'serial'`.

**Use these exact job names.** Do not query by `is_active = true`.

---

## Queue Population — Exact SQL

To queue all 10 jobs for a single effective date:
```sql
INSERT INTO control.task_queue (job_name, effective_date, execution_mode)
VALUES
  ('PeakTransactionTimes', '2024-10-01', 'parallel'),
  ('DailyBalanceMovement', '2024-10-01', 'parallel'),
  ('CreditScoreDelta', '2024-10-01', 'parallel'),
  ('BranchVisitsByCustomerCsvAppendTrailer', '2024-10-01', 'serial'),
  ('DansTransactionSpecial', '2024-10-01', 'serial'),
  ('PeakTransactionTimesV4', '2024-10-01', 'parallel'),
  ('DailyBalanceMovementV4', '2024-10-01', 'parallel'),
  ('CreditScoreDeltaV4', '2024-10-01', 'parallel'),
  ('BranchVisitsByCustomerCsvAppendTrailerV4', '2024-10-01', 'serial'),
  ('DansTransactionSpecialV4', '2024-10-01', 'serial');
```
Replace the date for each effective date. Do NOT queue multiple dates at once
until the current date passes Proofmark.

## Monitoring Completion — Exact SQL

To check if all jobs for a date are done:
```sql
SELECT status, count(*)
FROM control.task_queue
WHERE effective_date = '2024-10-01'
GROUP BY status;
```
When all 10 show `Succeeded` or `Failed`, the date is complete.
Poll this every 10 seconds while waiting.

To check for failures:
```sql
SELECT job_name, status, error_message
FROM control.task_queue
WHERE effective_date = '2024-10-01' AND status = 'Failed';
```

### Known Expected Failures
- **CreditScoreDelta** fails on weekends (Sat/Sun) — no credit score data on
  weekends. This is expected V1 behavior. If CreditScoreDeltaV4 also fails on
  the same weekend dates, that's a PASS (both fail identically). Skip Proofmark
  for jobs where both V1 and V4 fail on the same date.

---

## Proofmark Instructions

Tool path: `/workspace/MockEtlFramework/Tools/proofmark/`
Config guide: `/workspace/MockEtlFramework/Tools/proofmark/CONFIG_GUIDE.md`

### Invocation
```bash
export PATH="$PATH:/home/sandbox/.local/bin"
cd /workspace/MockEtlFramework && python3 -m proofmark compare \
  --config <path-to-config.yaml> \
  --left <v1-output-path> \
  --right <v4-output-path> \
  --output <report-path.json>
```
Exit codes: 0 = PASS, 1 = FAIL, 2 = ERROR

### Output Paths
- V1 (LHS): `Output/curated/{jobDirName}/{outputTableDirName}/{date}/{fileName}`
- V4 (RHS): `Output/double_secret_curated/{jobDirName}/{outputTableDirName}/{date}/{fileName}`

### Per-Job Proofmark Configs
Create at `POC4/Artifacts/{job_name}/proofmark.yaml`.
**Start with all-STRICT config.** Only add FUZZY/EXCLUDED overrides after a
failure provides evidence.

Template for CSV jobs (no trailer):
```yaml
comparison_target: "{job_name}"
reader: csv
threshold: 100.0
csv:
  header_rows: 1
  trailer_rows: 0
```
For CSV jobs with trailers in Overwrite mode, set `trailer_rows: 1`.
For CSV jobs in Append mode, keep `trailer_rows: 0` (trailers are embedded).

### Proofmark Comparison Map

| Job | Output Table | jobDirName | outputTableDirName | fileName | trailer_rows |
|-----|-------------|------------|-------------------|----------|--------------|
| PeakTransactionTimes | peak_transaction_times | peak_transaction_times | peak_transaction_times | peak_transaction_times.csv | 1 |
| DailyBalanceMovement | daily_balance_movement | daily_balance_movement | daily_balance_movement | daily_balance_movement.csv | 1 |
| CreditScoreDelta | credit_score_delta | credit_score_delta | credit_score_delta | credit_score_delta.csv | 1 |
| BranchVisitsByCustomerCsvAppendTrailer | branch_visits_by_customer | branch_visits_by_customer | branch_visits_by_customer | branch_visits_by_customer.csv | 0 |
| DansTransactionSpecial (details) | transaction_details | dans_transaction_special | dans_transaction_details | dans_transaction_details.csv | 0 |
| DansTransactionSpecial (by_state) | transactions_by_state_province | dans_transaction_special | dans_transactions_by_state_province | dans_transactions_by_state_province.csv | 0 |

Note: DansTransactionSpecial produces TWO output files. Run Proofmark on both.

---

## Execution Protocol

### Phase 1: Setup (do this once)

1. Read the Proofmark CONFIG_GUIDE.md
2. Create Proofmark config YAMLs for all 6 comparisons (see map above)
3. Create the initial progress file at `POC4/Artifacts/e6-progress.md`

### Phase 2: Date-by-Date Progression

For each effective date from 2024-10-01 through 2024-12-31:

**Step A — Queue.** Ensure the queue service is running, then insert work:
```bash
# Check if service is already running — do NOT start a second instance
if ! pgrep -f "JobExecutor.*--service" > /dev/null 2>&1; then
  cd /workspace/MockEtlFramework && dotnet run --project JobExecutor -- --service &
fi
```
Then INSERT all 10 jobs for this date into `control.task_queue`.

**Step B — Wait.** Poll `control.task_queue` every 10 seconds until all 10 jobs
for this date show `Succeeded` or `Failed`.

**Step C — Handle failures.** Check for `Failed` tasks.
- If CreditScoreDelta AND CreditScoreDeltaV4 both failed on a weekend: expected.
  Mark as SKIP in progress file.
- If only V4 failed but V1 succeeded (or vice versa): this needs triage.
- If a job failed due to a runtime error: investigate the error_message.

**Step D — Proofmark.** For each job where both V1 and V4 succeeded, run Proofmark.
Run all 6 comparisons for this date.

**Step E — Evaluate.** If all Proofmark comparisons pass (exit code 0):
- Update progress file with PASS for this date
- Advance to next date (go to Step A with next date)

**Step F — Triage (if any Proofmark fails).**
- Before triage, check `POC4/Errata/curated/` for already-learned lessons
- Spawn triage worker subagents to diagnose and fix failures
- A "fix" may be a V4 code change OR a Proofmark config change (STRICT → FUZZY/EXCLUDED),
  but only with sufficient evidence
- After each fix, triage worker appends an entry to `POC4/Errata/raw-errata-log.md`
- **When fixing any V4 job config or Proofmark config: re-run ALL effective dates
  from Oct 1 up to and including the current cursor date.** This means:
  1. Re-queue V4 jobs (NOT V1) for all dates up to cursor
  2. Wait for completion
  3. Re-run Proofmark for all those dates
  4. No partial validation — every prior date must re-pass

**Step G — Errata curation.** After each date's triage completes, spawn the
errata curator to read the raw log and produce/update curated summaries at
`POC4/Errata/curated/`. Future triage workers read curated errata, not the raw log.

### Failure Threshold

If any single job + effective date combination fails triage 5 times, flag it as
a failure. Execution continues for all other jobs.

### Concurrency Target for Triage

When triaging failures, keep 8-12 triage subagents in flight. When one finishes,
immediately launch the next. Do not wait for a full batch.

---

## Progress File

Maintain at `POC4/Artifacts/e6-progress.md`. **Update after EVERY date.**

```markdown
# E.6 Progress

## Cursor: {current effective date}

| Effective Date | V1 Run | V4 Run | Proofmark | Failures | Triage | Status |
|----------------|--------|--------|-----------|----------|--------|--------|
| 2024-10-01 | done | done | done | 0 | n/a | PASS |
| 2024-10-02 | done | done | done | 2 | done | PASS |
| 2024-10-05 | done | done | skipped | 0 | n/a | SKIP-WEEKEND |
| ... | | | | | | |

## Job Failure Tracker

| Job | Failures | Flagged? |
|-----|----------|----------|
| PeakTransactionTimes | 0 | no |
| DailyBalanceMovement | 0 | no |
| CreditScoreDelta | 0 | no |
| BranchVisitsByCustomerCsvAppendTrailer | 0 | no |
| DansTransactionSpecial | 0 | no |
```

---

## Final Review

When all jobs pass for all dates through Dec 31, 2024: spawn a separate review
team to audit all non-STRICT Proofmark columns. Profile across all 92 effective
dates. A field marked non-deterministic on day 1 that was never re-examined on
subsequent days is a governance failure.

---

## Inputs

- All V4 code from E.4 (built, tested, smoke-tested)
- BRDs, FSDs, output manifests at `POC4/Artifacts/{job_name}/`
- Anti-pattern list: `Governance/anti-patterns.md`
- Errata directory: `POC4/Errata/`

## Outputs

- Proofmark results for all jobs × all effective dates
- `POC4/Errata/raw-errata-log.md`
- `POC4/Errata/curated/`
- `POC4/Artifacts/{job_name}/proofmark-results.md` (summary per job)
- Non-STRICT column audit report
- List of any flagged failures
- `POC4/Artifacts/e6-progress.md`

## Database

```
PGPASSWORD=claude psql -h 172.18.0.1 -U claude -d atc
```

## Stop Condition

**Stop and report to BD when:** All jobs have passing Proofmark grades for all
effective dates through Dec 31, 2024, AND the non-STRICT column audit is complete.
Report any flagged failures. Do not proceed to any other phase. Your job is done.
