# E.6 Launch — Session Prompt

Paste this to start the next session.

---

We're in Phase III.5 of POC4 — the dry run. Read these files in order:

1. `/workspace/AtcStrategy/POC4/ProgramDoctrine/condensed-mission.md` — what we're doing
2. `/workspace/AtcStrategy/POC4/Governance/canonical-steps.md` — where we are (Steps 1-16 done, Phase III.5 in progress)
3. `/workspace/AtcStrategy/POC4/Design/Blueprints/orchestrator-e6.md` — the E.6 blueprint (READ CAREFULLY)

## Where we are

E.1 (BRD), E.2 (FSD + test strategy), E.4 (build) are **complete**.
E.3 and E.5 (sabotage) were **skipped** — 5 jobs, no value at this scale.

**E.6 (Validate) has NOT started.** We attempted a launch but the orchestrator
went rogue — wrote shell scripts, called `dotnet run` per job instead of using
the queue service, batched all 92 dates ignoring the date-by-date protocol.
He was terminated. The blueprint has been rewritten with hard constraints.

State is **fully clean**: empty task queue, empty job_runs, empty output dirs,
empty errata, build passing. Ready for a fresh E.6 launch.

## What changed since the original blueprint

The blueprint at `orchestrator-e6.md` was rewritten with:
- **HARD RULES section** — no dotnet run, no shell scripts, no batching dates
- **Exact SQL** for queue population and completion monitoring
- **Step-by-step protocol** (Steps A-G) instead of conceptual overview
- **Queue service instructions** — the service runs jobs, not the orchestrator
- **pgrep guard** to avoid stacking service instances

## Queue service (critical — this is what the last guy got wrong)

The MockEtlFramework has a built-in queue service:
```bash
dotnet run --project /workspace/MockEtlFramework/JobExecutor -- --service
```
- Polls `control.task_queue` for `status = 'Pending'` rows
- 4 parallel threads + 1 serial thread
- Claims tasks with `FOR UPDATE SKIP LOCKED`
- Auto-exits after 15 minutes of empty queue (MaxIdleCycles=30 × 30s)
- **Smoke tested and confirmed working this session**

The orchestrator's job is to INSERT into the queue, start the service, and
monitor `control.task_queue` status. NOT to call `dotnet run` per job.

## Known landmine

V4 PeakTransactionTimesWriterV4.cs writes to a date-partitioned path:
`Output/double_secret_curated/peak_transaction_times/peak_transaction_times/{date}/peak_transaction_times.csv`

V1 PeakTransactionTimesWriter.cs writes to a flat path:
`Output/curated/peak_transaction_times.csv`

This is an E.4 builder error. E.6 should catch it via Proofmark and triage the
fix. We left it intentionally to validate the process.

## The 5 dry run jobs (10 total with V4 counterparts)

PeakTransactionTimes (165/374), DailyBalanceMovement (166/375),
CreditScoreDelta (369/376), BranchVisitsByCustomerCsvAppendTrailer (371/377),
DansTransactionSpecial (373/378).

## Key context

- MockEtlFramework repo: `/workspace/MockEtlFramework/`
- DB: `PGPASSWORD=claude psql -h 172.18.0.1 -U claude -d atc`
- Proofmark: `cd /workspace/MockEtlFramework && python3 -m proofmark compare --config <yaml> --left <v1> --right <v4>`
- E.6 blueprint: `/workspace/AtcStrategy/POC4/Design/Blueprints/orchestrator-e6.md`
- Scope manifest trimmed to 5 jobs (full 105 recoverable from git tag `poc4-pre-dry-run`)

## What to do

Launch E.6 Orchestrator with the blueprint. Same pattern: BD launches
Orchestrator in background, sets up 60s progress timer, reports to Dan.
