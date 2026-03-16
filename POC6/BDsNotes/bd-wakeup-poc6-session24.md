# BD Wake-Up — POC6 Session 24

## Paste this to start the session:

```
Read /workspace/AtcStrategy/POC6/BDsNotes/bd-wakeup-poc6-session24.md then tell me where we are.
```

---

## What Happened in Sessions 22-23

### Engine Changes (Committed, Pushed)

1. **FBR gates removed (nodes 19-24).** Happy path is 22 nodes. Publish →
   ExecuteJobRuns directly. Commit `40abb75`.

2. **Triage dead-letter bug fixed.** Step handler hydrates
   `job.triage_results` from process artifact files after Triage_Check*
   nodes execute. Commit `40abb75`.

3. **Agent crash path fixed.** Non-zero CLI exit with no process artifact
   now returns `Outcome.FAILURE` instead of `None`. Commit `40abb75`.

4. **Test harness rebuilt.** 165 tests passing. Safety guard blocks tests
   while engine is active. All test job IDs use `TEST_JOB_` prefix.
   Per-test cleanup. No truncate. Commits `40abb75`, `3c82c5b`.

5. **Publisher blueprint reverted.** Had added `rm -rf` of RE output dir
   before deploy, but agents don't have write access to re-curated. Hobson
   fixed append-mode cleanup in the MockEtlFramework instead. Commit
   `1449d7f` has the old version — needs recommit with revert.

### Batch-12 Final Results

| Job | Status | Notes |
|-----|--------|-------|
| 1 | COMPLETE | |
| 2 | COMPLETE | |
| 3 | COMPLETE | |
| 4 | COMPLETE | |
| 5 | DEAD_LETTER | Proofmark config fault, burned all 5 retries |
| 6 | DEAD_LETTER | Append-mode duplicates. FW fixed by Hobson. ETL re-run done manually. Dan spot-checked output — issue is fixed. Proofmark re-validation still needed (RE engine must re-run from ExecuteProofmark). |
| 7 | DEAD_LETTER | Non-deterministic phone/email. OG heap scan order is unreproducible. See holistic triage below. |
| 8 | COMPLETE | |
| 9 | DEAD_LETTER | Triage kept routing to WriteBrd. 5 retries exhausted. |
| 10 | COMPLETE | |
| 11 | DEAD_LETTER | Triage kept routing through FSD rewrites. 5 retries exhausted. |
| 12 | COMPLETE | |

**7 COMPLETE, 5 DEAD_LETTER.** Engine has exited. No active tasks.

### Key Finding: Triage Can Diagnose But Can't Fix

Fired an Opus agent with holistic authority (no blueprint constraints) to
investigate job 7 (CustomerDemographics). It confirmed:

- OG primary_phone/primary_email selection depends on Postgres heap scan
  order, which shifted during the OG's own run
- No deterministic ORDER BY can replicate the OG output
- This is unfixable — the RE correctly reproduces the OG's logic but can't
  reproduce its random number generator
- Correct resolution: exclude primary_phone and primary_email from
  proofmark comparison, document why

**The automated triage pipeline got the diagnosis right but couldn't act on
it.** It kept routing to "rewrite the FSD" because that's its only tool.

### Dan's Triage Redesign (Design, Not Implemented)

Three agents instead of the current 7-node diagnostic-only pipeline:

1. **RCA agent** — root cause analysis with holistic authority. Diagnoses
   without constraint. Can conclude "this is unfixable, here's why."
2. **Fix agent** — makes the recommended change. Updates proofmark config,
   SQL, jobconf — whatever the RCA agent prescribed.
3. **Upstream citation agent** — edits BRD, FSD, proofmark config docs to
   record why the change was made, with evidence citations.

Job 7 is the perfect test case for this design.

### Other Findings

- **`control.task_queue` status contract:** Framework polls for `'Pending'`,
  not `'Queued'`. The column defaults to `'Pending'`. When inserting
  manually, do NOT specify a status value — let the default handle it.
  The job-executor blueprint is correct (omits status).

- **Job 6 append-mode bug:** RE output accumulated duplicate rows across
  re-runs. Hobson fixed this in the MockEtlFramework. Dan manually queued
  a re-run via `control.task_queue` and confirmed the output is correct.
  Proofmark re-validation still needed (job 6 is DEAD_LETTER in the RE
  engine, so proofmark wasn't re-run automatically).

### Uncommitted Changes

- `blueprints/publisher.md` — reverted the rm -rf step. Needs commit.
- `AtcStrategy/POC6/BDsNotes/session22-fbr-removal.md` — rationale doc
- `AtcStrategy/POC6/BDsNotes/session22-test-coverage-audit.md` — coverage audit
- `AtcStrategy/POC6/BDsNotes/bd-wakeup-poc6-session23.md` — prior wakeup

## What's Queued for Session 24

### 1. Triage Redesign

Design and implement the three-agent triage model. Use job 7 as the test
case:
- RCA: already done (Opus holistic triage output exists)
- Fix: update proofmark config to exclude primary_phone, primary_email
- Citation: update BRD/FSD with documentation of why those columns are
  excluded, citing the non-deterministic heap scan order evidence

### 2. Job 6 Proofmark Re-validation

Job 6's ETL re-ran with Hobson's framework fix. Need to:
- Queue proofmark entries for `CustomerDemographics_re` (wait, that's
  job 7 — job 6 is `MonthlyTransactionTrend_re`)
- Actually: queue proofmark entries for `MonthlyTransactionTrend_re`
  with the new (correct) RE output
- Or: resurrect job 6 in the RE engine and let it re-run from
  ExecuteProofmark

### 3. Jobs 5, 9, 11 Post-Mortem

All three exhausted retries in triage loops. Need holistic investigation
(like job 7) to determine if they're fixable or need excluded columns /
other remediation.

### 4. Commit Cleanup

Publisher blueprint revert needs to be committed and pushed.

## DB State

```sql
SELECT status, count(*) FROM control.re_job_state
WHERE job_id NOT LIKE 'val-%' AND job_id NOT LIKE 'TEST_JOB_%'
GROUP BY status;
-- COMPLETE: 13, DEAD_LETTER: 5, RUNNING: 0

SELECT clutch_engaged FROM control.re_engine_config;
-- false

SELECT count(*) FROM control.re_task_queue WHERE status IN ('pending', 'claimed');
-- 0 (engine is NOT running)
```

## RAM WARNING — READ THIS

Dan's host has 15GB RAM + 16GB swap. This container shares the host's swap.
**Subagent spawning is dangerous.** GSD executor subagents have OOM'd the host twice.

**Standing order:**
- Do NOT use `/gsd:execute-phase`. It will spawn subagents and OOM.
- Execute TDD cycles directly — read the plan, write the code.
- Before heavy work, run `free -h` to confirm available memory.
