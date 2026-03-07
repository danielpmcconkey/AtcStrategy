# Post Dry Run E.2 — Session Prompt

Paste this to start the next session.

---

We're in Phase III.5 of POC4 — the dry run. Read these files in order:

1. `/workspace/AtcStrategy/POC4/ProgramDoctrine/condensed-mission.md` — what we're doing
2. `/workspace/AtcStrategy/POC4/Governance/canonical-steps.md` — where we are (Steps 1-16 done, Phase III.5 in progress)
3. `/workspace/AtcStrategy/POC4/Artifacts/e2-progress.md` — E.2 results (final progress file with anti-pattern distribution and key findings)

## Where we are

Dry run E.1 (BRD generation) and E.2 (FSD + test strategy) are both **complete**.
All 5 jobs have full artifact chains: BRD → output manifest → FSD → test strategy,
each with independent reviews. Every review passed first cycle across both phases.

### E.1 stats (round 2)
- 92 tool calls, ~101K tokens, ~14 minutes wall clock
- 5 analyst agents + 5 reviewer agents + 1 orchestrator = 11 total agents
- V1 task queue: 33/35 succeeded (2 CreditScoreDelta weekend failures — expected, no data for Oct 5-6)

### E.2 stats
- 63 tool calls, ~114K tokens, ~10.8 minutes wall clock
- 5 architect agents + 10 reviewer agents (5 FSD + 5 test) + 1 orchestrator = 16 total agents
- 10/10 reviews passed first cycle, zero rejections

### Combined dry run observations (not yet written into lessons learned)

**From E.1 (rounds 1 and 2):**
- Progress file stale for most of the run — Orchestrator only updates at phase boundaries
- Anti-pattern heatmap emerged organically (not in blueprint — Dan chose to keep it that way)
- Append contamination catch: `FindLatestPartition` picks up pre-existing output from prior runs
- DansTransactionSpecial multi-output handled cleanly
- All 5 E.1 reviews passed first cycle

**From E.2:**
- **Progress file stale again.** Same pattern — initialized, then not touched until all architects
  finished, then final summary. Blueprint explicitly says "update every time a job completes a
  stage." Orchestrator consistently ignores this across both phases.
- **Reviewers gated behind architects.** Blueprint says "as each FSD completes, immediately spawn
  an independent reviewer." Orchestrator waited for all 5 architects to finish, then launched all
  reviewers as a batch. On 5 jobs the throughput loss is negligible. At 105 jobs this is a
  meaningful pipeline stall.
- **15/15 first-cycle passes across E.1 and E.2.** Zero rejections total. Either the workers are
  very good or the reviewers aren't adversarial enough. This needs scrutiny before scaling to 105.
- **PeakTransactionTimes keeps External module in V4** — justified because trailer needs INPUT row
  count (4284 transactions) vs framework's `{row_count}` which gives OUTPUT count (19 hourly
  buckets). Aggregation logic still moves to SQL.
- **DailyBalanceMovement gets full External-to-SQL conversion.** AP3 and AP6 eliminated.
- **AP7 (Magic Values) is universal** — found in all 5 jobs.
- **Three new testing-relevant patterns discovered:** undefined row ordering, accumulated file
  ordering ambiguity, non-deterministic ROW_NUMBER tiebreaker.

## The 5 dry run jobs

PeakTransactionTimes (165), DailyBalanceMovement (166), CreditScoreDelta (369),
BranchVisitsByCustomerCsvAppendTrailer (371), DansTransactionSpecial (373).

## Artifacts on disk

Per job at `/workspace/AtcStrategy/POC4/Artifacts/{job_name}/`:
- `brd.md` — business requirements document (E.1)
- `output-manifest.md` — output file schemas (E.1)
- `brd-review.md` — independent BRD review (E.1)
- `fsd.md` — functional specification (E.2)
- `test-strategy.md` — test strategy with traced cases (E.2)
- `fsd-review.md` — independent FSD review (E.2)
- `test-review.md` — independent test strategy review (E.2)

Global:
- `/workspace/AtcStrategy/POC4/Artifacts/e1-progress.md`
- `/workspace/AtcStrategy/POC4/Artifacts/e2-progress.md`

## What to do

Dan decides. Options on the table:

1. **Continue dry run execution (E.3+)** — sabotage round 1, build phase, etc. per
   `Design/PhaseDefinitions/phase-v-execution.md`
2. **Write lessons learned (Step X.3)** — combine all observations into the durable
   lessons-learned doc. This is the only artifact that survives the dry run.
3. **Validate artifact quality** — spot-check BRDs and FSDs against V1 code to verify
   the agents got details right (not just whether reviewers passed them).
4. **Revert and proceed** — clean up dry run artifacts, restore scope manifest, move to
   Phase IV (FMEA / Jim sign-off).

## Revert when ready

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
- The scope manifest is currently trimmed to 5 jobs (NOT committed). Full 105 recoverable from git tag `poc4-pre-dry-run`
- Blueprint improvements from E.1 round 1 are committed on main and should NOT be reverted
- E.2 blueprint is at `/workspace/AtcStrategy/POC4/Design/Blueprints/orchestrator-e2.md`
