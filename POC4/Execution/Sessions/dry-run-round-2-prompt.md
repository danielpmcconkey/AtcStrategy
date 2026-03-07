# Dry Run Round 2 — Session Prompt

Paste this to start the next session.

---

We're in Phase III.5 of POC4 — the dry run. Read these files in order:

1. `/workspace/AtcStrategy/POC4/ProgramDoctrine/condensed-mission.md` — what we're doing
2. `/workspace/AtcStrategy/POC4/Governance/canonical-steps.md` — where we are (Steps 1-16 done, Phase III.5 in progress)
3. `/workspace/AtcStrategy/POC4/Design/Blueprints/orchestrator-e1.md` — the blueprint we're testing

## Where we are

Dry run round 1 is complete. We ran E.1 (BRD generation) against 5 jobs and
learned 4 lessons that are now baked into the blueprints. Round 2 is a re-run
of E.1 with the updated blueprints.

## The 5 dry run jobs

PeakTransactionTimes (165), DailyBalanceMovement (166), CreditScoreDelta (369),
BranchVisitsByCustomerCsvAppendTrailer (371), DansTransactionSpecial (373).

## What to do

1. Cut scope for the dry run (DO NOT commit the scope cut):
   - Edit `/workspace/AtcStrategy/POC4/Governance/ScopeManifest/job-scope-manifest.json` to only include the 5 jobs above (copy from the tag if needed: `git show poc4-pre-dry-run:POC4/Governance/ScopeManifest/job-scope-manifest.json` has the full 105, trim to 5)
   - Deactivate other jobs: `PGPASSWORD=claude psql -h 172.18.0.1 -U claude -d atc -c "UPDATE control.jobs SET is_active = false WHERE job_id NOT IN (165, 166, 369, 371, 373);"`
   - Clean up any prior dry run residue: `PGPASSWORD=claude psql -h 172.18.0.1 -U claude -d atc -c "DELETE FROM control.task_queue; DELETE FROM control.job_runs WHERE triggered_by = 'queue';"`
   - Clean artifacts: `rm -rf /workspace/AtcStrategy/POC4/Artifacts/*/ /workspace/AtcStrategy/POC4/session-state.md /workspace/MockEtlFramework/Output/curated/*/`

2. Launch E.1 Orchestrator per the blueprint at `Design/Blueprints/orchestrator-e1.md`
   - BD launches Orchestrator as a background agent
   - Orchestrator manages analyst workers and reviewers
   - Key improvements from round 1: concurrency target 8-12, progress file at `POC4/Artifacts/e1-progress.md`, append jobs queued as serial

3. Monitor via the progress file (not the transcript dump)

4. When Orchestrator reports completion, validate outputs per runbook at `Design/runbook.md`

## Revert after dry run

See `/workspace/AtcStrategy/POC4/Backups/dry-run-revert.md` for full steps.
Quick version:
```bash
cd /workspace/AtcStrategy
git checkout poc4-pre-dry-run -- POC4/Governance/ScopeManifest/job-scope-manifest.json
PGPASSWORD=claude psql -h 172.18.0.1 -U claude -d atc -c "UPDATE control.jobs SET is_active = true; DELETE FROM control.task_queue; DELETE FROM control.job_runs WHERE triggered_by = 'queue';"
rm -rf POC4/Artifacts/*/ POC4/session-state.md
```

## Key context

- MockEtlFramework repo: `/workspace/MockEtlFramework/`
- DB: `PGPASSWORD=claude psql -h 172.18.0.1 -U claude -d atc`
- Task queue service: `cd /workspace/MockEtlFramework && dotnet run --project JobExecutor -- --service` (populate queue FIRST, then start — it exits on empty queue)
- Queue population pattern: INSERT into `control.task_queue` with execution_mode = 'parallel' for most jobs, 'serial' for append-mode jobs
- The scope manifest at 105 jobs is recoverable from git tag `poc4-pre-dry-run`
- Blueprint improvements are committed on main and should NOT be reverted
