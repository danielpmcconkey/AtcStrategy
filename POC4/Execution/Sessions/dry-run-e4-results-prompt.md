# Post Dry Run E.4 — Session Prompt

Paste this to start the next session.

---

We're in Phase III.5 of POC4 — the dry run. Read these files in order:

1. `/workspace/AtcStrategy/POC4/ProgramDoctrine/condensed-mission.md` — what we're doing
2. `/workspace/AtcStrategy/POC4/Governance/canonical-steps.md` — where we are (Steps 1-16 done, Phase III.5 in progress)
3. `/workspace/AtcStrategy/POC4/Artifacts/e4-progress.md` — E.4 results

## Where we are

Dry run E.1 (BRD), E.2 (FSD + test strategy), and E.4 (build) are **complete**.
E.3 and E.5 (sabotage rounds) were **skipped** — only 5 jobs, sabotage adds no value
at this scale. Reviewer adversarialism is unvalidated and should be flagged for FMEA.

Next up: **E.6 (Validate)** — run all V1 and V4 jobs across 92 effective dates
(Oct 1 – Dec 31, 2024), compare output with Proofmark, triage failures.

### E.1 stats (round 2)
- 92 tool calls, ~101K tokens, ~14 minutes wall clock
- 5 analyst agents + 5 reviewer agents + 1 orchestrator = 11 total agents
- V1 task queue: 33/35 succeeded (2 CreditScoreDelta weekend failures — expected)

### E.2 stats
- 63 tool calls, ~114K tokens, ~10.8 minutes wall clock
- 5 architect agents + 10 reviewer agents + 1 orchestrator = 16 total agents
- 10/10 reviews passed first cycle, zero rejections

### E.4 stats
- 103 tool calls, ~145K tokens, ~13 minutes wall clock
- 5 builder agents + reviewers + 1 orchestrator
- 140 tests passing, clean build
- All 5 smoke tests passed (Oct 1-7), all 3 independent reviews passed per job

### Observations accumulated across E.1–E.4 (Dan has the full list)

- **Progress file stale every phase.** Root cause: Orchestrator launches all subagents
  as parallel Task calls and blocks until all return. No "await any" — only "await all."
  Progress updates can only happen at batch boundaries. This is a tooling constraint,
  not a behavioral failure. Blueprints should be written for batch-boundary updates.
- **Reviewer gating is the same root cause.** Orchestrator can't launch reviewers as
  builders finish — it's blocked waiting for ALL builders to return.
- **25/25 first-cycle passes across E.1–E.4.** Zero rejections total. Reviewers may not
  be adversarial enough. Unvalidated without sabotage.
- **Orchestrator queued V1 jobs during E.4 smoke test.** Used `is_active = true` instead
  of scoping to V4 names. Double the queue entries, double the runs. Fixed in E.6
  blueprint with explicit job name instructions.
- **V1/V4 output path collision.** Both V1 and V4 configs originally wrote to `Output/poc4/`.
  Fixed: V1 → `Output/curated/`, V4 → `Output/double_secret_curated/`.
- **DailyBalanceMovement `mostRecent: true` deviation.** Orchestrator changed accounts
  sourcing from single-day to `mostRecent: true` to handle weekends. FSD didn't authorize
  this. V1 returns empty output on weekends; V4 returns data. Proofmark WILL catch this
  in E.6. Left intentionally to validate E.6's ability to surface fidelity issues.
- **PeakTransactionTimes decimal formatting.** SQLite ROUND returns integers for whole
  numbers; V1's `Math.Round(decimal, 2)` preserves trailing zeros. Fixed with F2 format.
- **Edit permission denied for Orchestrator.** Fell back to `cat` file rewrites. Functional
  but ugly. POC5 tooling investigation item.

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
- `build-review.md` — independent build review (E.4)

Global:
- `/workspace/AtcStrategy/POC4/Artifacts/e1-progress.md`
- `/workspace/AtcStrategy/POC4/Artifacts/e2-progress.md`
- `/workspace/AtcStrategy/POC4/Artifacts/e4-progress.md`

V4 code at `/workspace/MockEtlFramework/`:
- Job configs: `JobExecutor/Jobs/*_v4.json`
- External module: `ExternalModules/PeakTransactionTimesWriterV4.cs`
- Unit tests: `Lib.Tests/V4JobTests.cs` (29 tests, 140 total passing)

## Output directory scheme

- V1 output → `Output/curated/{jobDirName}/{outputTableDirName}/{date}/{fileName}`
- V4 output → `Output/double_secret_curated/{jobDirName}/{outputTableDirName}/{date}/{fileName}`
- Proofmark compares LHS (curated) vs RHS (double_secret_curated)

## Pre-flight status for E.6

- [x] Task queue clean (empty)
- [x] Job run history clean (no queue-triggered runs)
- [x] Output directories clean and created
- [x] All configs updated to correct output dirs
- [x] E.6 blueprint has Proofmark paint-by-numbers instructions
- [x] E.6 blueprint has explicit queue scoping (no `is_active = true`)
- [x] Errata directory exists at `POC4/Errata/`
- [x] 5 V1 + 5 V4 jobs registered in control.jobs
- [x] `dotnet build` passes, `dotnet test` passes (140 tests)

## What to do

Launch E.6 Orchestrator with blueprint at:
`/workspace/AtcStrategy/POC4/Design/Blueprints/orchestrator-e6.md`

Same pattern as prior phases: BD launches Orchestrator in background, sets up 60s
progress timer, reports to Dan.

## Key context

- MockEtlFramework repo: `/workspace/MockEtlFramework/`
- DB: `PGPASSWORD=claude psql -h 172.18.0.1 -U claude -d atc`
- Proofmark: `cd /workspace/MockEtlFramework && python3 -m proofmark compare --config <yaml> --left <v1> --right <v4>`
- The scope manifest is currently trimmed to 5 jobs (NOT committed). Full 105 recoverable from git tag `poc4-pre-dry-run`
- E.6 blueprint: `/workspace/AtcStrategy/POC4/Design/Blueprints/orchestrator-e6.md`
- Phase definitions: `/workspace/AtcStrategy/POC4/Design/PhaseDefinitions/phase-v-execution.md`
