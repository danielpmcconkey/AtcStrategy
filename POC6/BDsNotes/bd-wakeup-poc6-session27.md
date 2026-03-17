# BD Wake-Up — POC6 Session 27

## Paste this to start the session:

```
Read /workspace/AtcStrategy/POC6/BDsNotes/bd-wakeup-poc6-session27.md then tell me where we are.
```

---

## What Happened in Session 26

### PatFix Fully Automated

The CONDITIONAL→PatFix→COMPLETE flow works end-to-end with zero manual
intervention. Jobs 16, 19, 20, 21, 23 all completed through this path.
PatFix handles the full cleanup: FSD updates, unit test rewrites, re-running
jobs through the framework, re-running Proofmark, fixing typeName mismatches.

Dan reviewed the last 5 Pat reports — all CONDITIONALs are legitimate
documentation/test drift after triage pivots (Transformation→External module
swaps). Pat is not being softened; the CONDITIONAL flow is the right fix.
Job 23's PatFix was particularly impressive — it re-ran the job through the
framework, produced proper 3-part parquet output, re-ran Proofmark, rebuilt
tests, and fixed all FSD contradictions.

### Proofmark Executor Blueprint Fixed (commit `20cd311`)

Old blueprint hardcoded CSV path templates. Parquet jobs need directory paths.
New blueprint:
- Added step 6: read jobconf for `jobDirName`, `outputTableDirName`, `fileName`
- Split step 7 into CsvFileWriter and ParquetFileWriter templates
- Parquet `fileName` is a directory, no extension, no part-file suffix

Won't retroactively fix jobs already past this step. New jobs should be clean.

### Job Feeder Automation

Bash script maintained 6 running jobs by hot-loading from eligible pool every
2 minutes. Checks `control.job_dependencies` before picking candidates.
`re_job_state.job_id` = `control.jobs.job_id` (same number). Kill the script
before engaging clutch or when winding down.

### Logging Confirmed Working

`log_config.py` sends structlog to stderr (unbuffered) + `engine.log` (file).
Diagnostic traceback blocks in step_handler (lines 88-93, 145-153) catch
transition failures. All confirmed working — this was done in session 25,
not session 26 as the previous wakeup notes suggested.

### Clutch Timer Timezone Bug

Container clock is UTC. Dan's local time is ET (UTC-4). `date -d "today 21:12"`
in the container targets UTC 21:12, not ET 21:12. For future clutch
automation, either use UTC times or compute the offset manually.

### Session Stats

- Started at 28 COMPLETE, ended at 37 COMPLETE (+9 jobs)
- 1 DEAD_LETTER (job 5 — trailer comparison, accepted)
- Token burn: ~0.4-0.5%/min with 6 workers
- Clutch engaged manually at ~83% used

## Batch Status

**37 COMPLETE, 1 DEAD_LETTER, 3 RUNNING** out of 102 OG jobs.

### Running Jobs at Session End

| Job | Name | Current Node | Notes |
|-----|------|-------------|-------|
| 18 | CreditScoreAverage | ExecuteProofmark | Proofmark data mismatches — heading to triage |
| 26 | TopBranches | Publish | Clean run |
| 28 | CustomerTransactionActivity | ReviewFsd | Mid-pipeline |

### Job 18 Saga

This job has been a pain all session:
1. Sat at ExecuteJobRuns with wrong typeName (`CreditScoreDecimalAvg_re` vs
   OG's `CreditScoreAverager`). Triage fixed it.
2. Now at ExecuteProofmark with data mismatches (every date FAILing). Will
   route to triage again.

## What's Queued for Session 27

### 1. Let Running Jobs Finish

3 jobs still in flight. Check status on startup — they may have completed,
dead-lettered, or still be grinding.

### 2. Continue Hot-Loading

65 untouched jobs remaining (~102 - 37 complete). Use the feeder script
or hot-load manually. Recipe:
```sql
INSERT INTO control.re_job_state (job_id, current_node, status)
VALUES ('{job_id}', 'LocateOgSourceFiles', 'RUNNING');
INSERT INTO control.re_task_queue (job_id, node_name)
VALUES ('{job_id}', 'LocateOgSourceFiles');
```
Check `control.job_dependencies` before picking. `re_job_state.job_id` =
`control.jobs.job_id`.

### 3. Monitor Proofmark Parquet Fix

First new parquet job to hit ExecuteProofmark will test the blueprint fix.
Watch for the old "Parquet reader expects a directory" error — if it still
appears, the agent isn't reading the updated blueprint (cache issue or
blueprint not loaded correctly).

### 4. Investigate Job 18 Data Mismatches

If job 18 dead-letters after triage, look at the Proofmark failure details.
CreditScoreAverage had the typeName saga — possible the triage fix introduced
a behavioral difference.

### 5. Watch for PatFix Edge Cases

The flow is working great, but watch for:
- PatFix trying to re-run jobs through the framework (does it handle
  `Output/re-curated` being a ro mount?)
- PatFix conditions that require changes beyond mechanical doc/test fixes
- Multiple CONDITIONALs on the same node (counter escalation to FAIL)

## DB State

```sql
SELECT status, count(*) FROM control.re_job_state
WHERE job_id NOT LIKE 'val-%' AND job_id NOT LIKE 'TEST_JOB_%'
GROUP BY status;
-- COMPLETE: 37, DEAD_LETTER: 1, RUNNING: 3

SELECT clutch_engaged FROM control.re_engine_config;
-- false (engine running, winding down)

SELECT count(*) FROM control.re_task_queue WHERE status IN ('pending', 'claimed');
-- 3 (in-flight tasks for running jobs)
```

## Resource Notes

Host can handle ~13 concurrent agents before OOM. Token burn rate is the
actual constraint — 6 workers is the sweet spot for budget management.
Container clock is UTC (ET = UTC-4).
