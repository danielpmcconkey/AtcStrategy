# Post Dry Run Round 2 — Session Prompt

Paste this to start the next session.

---

We're in Phase III.5 of POC4 — the dry run. Read these files in order:

1. `/workspace/AtcStrategy/POC4/ProgramDoctrine/condensed-mission.md` — what we're doing
2. `/workspace/AtcStrategy/POC4/Governance/canonical-steps.md` — where we are (Steps 1-16 done, Phase III.5 in progress)
3. `/workspace/AtcStrategy/POC4/Artifacts/e1-progress.md` — round 2 results (the final progress file with anti-pattern heatmap and key findings)

## Where we are

Dry run round 2 of E.1 (BRD generation) is **complete**. All 5 BRDs passed
independent review on the first cycle. No rejections, no revision loops.

### Round 2 stats
- 92 tool calls, ~101K tokens, ~14 minutes wall clock
- 5 analyst agents + 5 reviewer agents + 1 orchestrator = 11 total agents
- V1 task queue: 33/35 succeeded (2 CreditScoreDelta weekend failures — expected, no data for Oct 5-6)

### Round 2 observations (not yet written into lessons learned)
- **Progress file was stale for most of the run.** The Orchestrator only updated it at
  phase boundaries (after all analysts done, after all reviewers done), not per-stage as
  the blueprint instructs. It's better than round 1 but still not real-time monitoring.
- **Anti-pattern heatmap emerged organically.** The Orchestrator generated a cross-portfolio
  anti-pattern matrix in the final summary without being told to. Dan decided NOT to add
  this to the blueprint — keep blueprints lean, let agents surprise you with extras.
- **Append contamination catch.** The Orchestrator independently investigated and documented
  that `FindLatestPartition` picks up pre-existing output from prior runs, causing data
  duplication. Correctly noted this as an edge case in the BRDs.
- **DansTransactionSpecial multi-output handled cleanly.** Both outputs (overwrite details +
  append state/province summary) captured in BRD and manifest with correct schemas.
- **All 5 reviews passed first cycle.** Zero rejections — either the analysts are good or
  the reviewers are soft. Worth watching at scale.

## The 5 dry run jobs

PeakTransactionTimes (165), DailyBalanceMovement (166), CreditScoreDelta (369),
BranchVisitsByCustomerCsvAppendTrailer (371), DansTransactionSpecial (373).

## Artifacts from round 2 (still on disk)

- BRDs: `/workspace/AtcStrategy/POC4/Artifacts/{job_name}/brd.md`
- Output manifests: `/workspace/AtcStrategy/POC4/Artifacts/{job_name}/output-manifest.md`
- Reviews: `/workspace/AtcStrategy/POC4/Artifacts/{job_name}/brd-review.md`
- Progress file: `/workspace/AtcStrategy/POC4/Artifacts/e1-progress.md`

## What to do

Dan decides. Options on the table:

1. **Write lessons learned (Step X.3)** — combine round 1 and round 2 observations into the
   durable lessons-learned doc. This is the only artifact that survives the dry run.
2. **Validate BRD quality** — Dan or BD spot-checks the actual BRD content against V1 code
   to see if the analysts got the details right (not just whether reviewers passed them).
3. **Revert and proceed** — clean up dry run artifacts, restore scope manifest, move to
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
- Blueprint improvements from round 1 are committed on main and should NOT be reverted
