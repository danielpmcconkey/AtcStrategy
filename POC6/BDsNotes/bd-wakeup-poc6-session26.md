# BD Wake-Up — POC6 Session 26

## Paste this to start the session:

```
Read /workspace/AtcStrategy/POC6/BDsNotes/bd-wakeup-poc6-session26.md then tell me where we are.
```

---

## What Happened in Session 25

### Job 7 Cleanup & Batch-13

Wiped job 7 (CustomerDemographics) from DB and disk — clean slate for retry.
Built batch-13 manifest with job 7 + 5 fresh jobs (13, 17, 97, 118, 127)
across accounts, credit, cards, wire, and overdrafts domains.

### Hot-Loading Discovery

Discovered idle workers will pick up manually injected DB rows. Recipe:
```sql
INSERT INTO control.re_job_state (job_id, current_node, status)
VALUES ('NEW_ID', 'LocateOgSourceFiles', 'RUNNING');
INSERT INTO control.re_task_queue (job_id, node_name)
VALUES ('NEW_ID', 'LocateOgSourceFiles');
```
No filesystem scaffolding needed — agent_node.py creates dirs on the fly.
Hot-loaded jobs 14, 15, 16, 18, 22 during the batch.

### Token Budget Management

Dan provided usage readings. Burn rate averaged ~0.6%/min with 6 workers.
5-hour session refresh means ~160 min of budget per cycle, ~140 min dead air.
Standing order: keep 6 threads occupied, throw clutch at 90%. Always inject
new jobs even if clutch is imminent — jobs mid-flight will be RUNNING state
and resume next session.

### Pat Pattern — Documentation/Test Drift

Every job that went through triage hit the same problem: triage fixes the
code but doesn't update FSD, tests, or artifact jobconf. Pat (evidence
auditor) correctly catches the drift and REJECTs. Output is always correct
(Proofmark passes), but the evidence chain is broken.

Affected jobs this session: 7, 97, 118, 127. All fixed by background agents
(update FSD, sync jobconf, rebuild tests) and Dan-overridden to COMPLETE.

### Engine Changes (Committed: `770ee81`)

1. **FinalSignOff removed** — was rubber-stamping everything, zero value.
   ExecuteProofmark flows directly to FBR_EvidenceAudit. 21 nodes, was 22.

2. **Pat gets CONDITIONAL outcome** — for fixable documentation/test drift
   with clean Proofmark results:
   - APPROVED → COMPLETE (clean)
   - CONDITIONAL → PatFix → COMPLETE (auto-fix, no re-review)
   - REJECTED → DEAD_LETTER (output correctness issues, human problem)
   - PatFix blueprint at `blueprints/pat-fix.md`
   - Pat's `conditions` array must list specific mechanical fixes

3. **triage-fix blueprint updated** — added constraint: "Update everything
   your changes invalidate." Should reduce how often Pat sees drift going
   forward.

4. **Graceful shutdown** — SIGINT/SIGTERM handler stops workers, cleans up
   DB pool, runs `stty sane`. Workers are non-daemon. Claude subprocesses
   run in own session (`start_new_session=True`).

### Recurring Error: Double-Nested Parquet Paths

Seen multiple times across sessions. Pattern:
```
ReaderError: Parquet reader expects a directory, got:
.../wire_transfer_daily/wire_transfer_daily/2024-10-20/wire_transfer_daily/part-00000.parquet
```
Job name repeated in the output path structure. Triage has always figured it
out eventually, but it burns tokens re-diagnosing. Worth investigating if
there's a common root cause in the Publish or BuildJobArtifacts blueprint.

### Proofmark Trailer Feature — KILLED

Dan explicitly rejected building the `compare_trailer` Proofmark feature.
Burned out of the to-do list. Job 5 stays dead-lettered.

### Pat Override Pattern — LEFT AS-IS

Pat's strictness on documentation traceability stays. The CONDITIONAL flow
is the proper fix — no need to soften Pat.

## Batch Status

**33 total jobs in re_job_state.**
- COMPLETE: 28
- DEAD_LETTER: 1 (job 5 — trailer comparison, accepted)
- RUNNING: 4 (jobs 14, 15, 16, 18)

### Running Jobs at Session End (clutch engaged, winding down)

| Job | Name | Current Node | Notes |
|-----|------|-------------|-------|
| 14 | AccountTypeDistribution | Publish | Clean run |
| 16 | AccountCustomerJoin | Triage | Retry 1 |
| 18 | CreditScoreAverage | ReviewProofmarkConfig | Clean run |
| 19 | LoanPortfolioSnapshot | WriteBrd | Hot-loaded, early pipeline |
| 20 | LoanRiskAssessment | ReviewBrd | Hot-loaded, early pipeline |

Job 15 (HighBalanceAccounts) — COMPLETE via manual PatFix injection.
First successful CONDITIONAL → PatFix → COMPLETE flow (manual bypass).

## What's Queued for Session 26

### 1. Debug FBR→PatFix Transition Failure

Job 15 (HighBalanceAccounts): Pat returned CONDITIONAL, `_resolve_outcome`
processed it correctly (conditional_counts shows 1, last_rejection_reason
set). But the step handler threw an exception before enqueueing PatFix —
task status is `failed`, no PatFix task created, job stuck in RUNNING.

Manually injected PatFix task to unblock job 15. Need to figure out what
threw. The stdout buffering bug (item 2) means no error logs were visible.
Fix the logging first, then reproduce on the next CONDITIONAL to see the
actual traceback.

Possible causes:
- Race condition between `complete_task` and `enqueue_task` with the
  unique constraint `ix_re_task_queue_one_active`
- `save_job_state` failing on the CONDITIONAL update
- Something in the `_resolve_outcome` CONDITIONAL path that we're not seeing

Diagnostic stderr logging added to step_handler.py (not committed yet).
Next CONDITIONAL will print the traceback to stderr regardless of the
stdout buffering bug.

### 2. Fix Stdout Buffering

Engine logs stopped appearing in terminal after the graceful shutdown changes.
Workers are running (DB shows progress) but no log output visible. Likely
cause: Python stdout buffering in worker threads.

**Fix to try first:** `PYTHONUNBUFFERED=1 python3 -m workflow_engine ...`

If that doesn't work, switch structlog to stderr (`PrintLoggerFactory(file=sys.stderr)`)
or add explicit flush calls.

### 2. Let Running Jobs Finish

4 jobs are in-flight. Engine is running with clutch disengaged. Check status
on startup — they may have completed or dead-lettered overnight.

### 3. Continue Hot-Loading

Pool of untouched jobs is large (~70+). Keep 6 workers occupied. Watch for
dependency chains — jobs 24, 25 depend on job 22 (now COMPLETE, so they're
unblocked).

### 4. Monitor Pat CONDITIONAL Flow

First real test of the new CONDITIONAL → PatFix → COMPLETE pipeline. Watch
for:
- Does Pat correctly distinguish CONDITIONAL vs REJECTED?
- Does PatFix resolve conditions and pass UTs?
- Does the auto-complete work end-to-end?

### 5. Investigate Double-Nested Parquet Path Pattern

If time permits, look at why RE jobs produce `job_name/job_name/date/job_name/`
paths. May be a Publish or BuildJobArtifacts blueprint issue.

## DB State

```sql
SELECT status, count(*) FROM control.re_job_state
WHERE job_id NOT LIKE 'val-%' AND job_id NOT LIKE 'TEST_JOB_%'
GROUP BY status;
-- COMPLETE: 28, DEAD_LETTER: 1, RUNNING: 4

SELECT clutch_engaged FROM control.re_engine_config;
-- false (engine running)

SELECT count(*) FROM control.re_task_queue WHERE status IN ('pending', 'claimed');
-- 3 (in-flight tasks for running jobs)
```

## Resource Notes

Host can handle ~13 concurrent agents before OOM. Token burn rate is the
actual constraint — 6 workers is the sweet spot for budget management.
