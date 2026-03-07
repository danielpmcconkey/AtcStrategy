# Orchestrator Blueprint — E.4: Build

**Scope:** Build V4 code and unit tests for every job in the scope manifest. Stop when all jobs pass smoke test and all independent reviews are approved.

---

## Inputs

- Completed FSDs and test strategies from E.2: `POC4/Artifacts/{job_name}/fsd.md`, `test-strategy.md`
- BRDs and output manifests from E.1 (for reference)
- Anti-pattern list: `Governance/anti-patterns.md`
- MockEtlFramework repo

## Your Team

- **Builders** — spawn as worker subagents, assign batches of jobs
- **Reviewers** — spawn as independent subagents

## Execution

1. Start MockEtlFramework long-running processes if not already running
2. Assign jobs to builder workers in batches
3. Each builder, for each assigned job:
   - Read the FSD and test strategy
   - Build V4 job configuration at `JobExecutor/Jobs/{job_name}_v4.json`
   - Build External modules only if justified per FSD (last resort — evidence required)
   - Create appropriate entry in the jobs table
   - Write unit tests per test strategy
4. **CRITICAL — serialize builds.** Only ONE `dotnet build` at a time. Concurrent Roslyn compilations will brick the machine. Orchestrator manages build serialization between batches.
5. After each batch:
   - Run `dotnet build` — must compile cleanly
   - Run `dotnet test` — all tests must pass
   - Smoke test: run V4 jobs for ETL effective dates Oct 1-7, 2024, ensure no errors
   - Check for `POC4/CLUTCH`
   - Update `POC4/session-state.md`
6. For each completed job, spawn independent reviewers:
   - **Review 1 — Test coverage:** All unit tests cover all test cases from test strategy
   - **Review 2 — Anti-pattern elimination:** All cited anti-patterns either eliminated or have evidence for why they're required for output fidelity. "Output fidelity" means the files the job creates. Fidelity to original code or flow is NOT acceptable rationale.
   - **Review 3 — Smoke test:** Smoke test succeeded appropriately
7. If reviewer rejects, send feedback to a fresh builder worker for revision.
8. After ALL reviews pass: delete all artifacts and job run history from smoke tests (only after independent confirmation that smoke test review is complete)

## Outputs

For each job in scope:
- V4 job config in `JobExecutor/Jobs/`
- External modules in `ExternalModules/` (if needed)
- Unit tests
- `POC4/Artifacts/{job_name}/build-review.md`

Global:
- All tests passing (`dotnet test`)
- Clean build (`dotnet build`)
- Smoke test artifacts cleaned up

## Stop Condition

**Stop and report to BD when:** All jobs have been built, all independent reviews approved, all smoke test residue cleaned up. Do not proceed to any other phase. Your job is done.

## Post-Approval (Dan instructs BD, not you)

After Dan approves E.4 completion:
- BD cleans up any remaining data output or control table job runs
- BD tags MockEtlFramework repo: `poc4_e4_complete`
- BD takes a pg_dump of the control schema
