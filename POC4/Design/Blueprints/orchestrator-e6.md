# Orchestrator Blueprint — E.6: Validate

**Scope:** Run all V1 and V4 jobs across all effective dates, compare output with Proofmark, triage failures, and iterate until all jobs pass for all dates. Stop when all jobs pass Proofmark for all effective dates through Dec 31, 2024.

---

## Inputs

- All V4 code from E.4 (built, tested, smoke-tested)
- BRDs, FSDs, output manifests from E.1/E.2 (for triage reference)
- Anti-pattern list: `Governance/anti-patterns.md`
- Errata directory: `POC4/Errata/`
- MockEtlFramework repo + Proofmark tool

## Your Team

- **Triage workers** — spawn as subagents, diagnose and fix Proofmark failures
- **Errata curator** — spawn after each effective date's triage completes

## Execution

### Effective Date Progression

1. Start MockEtlFramework and Proofmark long-running processes if not already running
2. Begin with ETL effective date Oct 1, 2024
3. For the current effective date:
   - Run all V1 and V4 jobs for that date
   - Run Proofmark on all output for that date
   - Review Proofmark output and triage any failures

### Triage Protocol

4. Before triage, check `POC4/Errata/curated/` for already-learned lessons
5. For jobs with failures, spawn triage workers to diagnose and fix
6. For jobs with errors believed fixed, re-run V4 code only (do NOT re-run V1)
7. A "fix" may include Proofmark config YAML changes — moving a column from STRICT to FUZZY or EXCLUDED — **only** with sufficient evidence to warrant it
8. When fixing any job config or Proofmark config: **re-run ALL effective dates up to and including the current cursor date.** No partial validation.
9. After each fix, triage worker appends an entry to `POC4/Errata/raw-errata-log.md`

### Errata Curation

10. After each effective date's triage completes, spawn the errata curator
11. Curator reads raw errata log, produces/updates curated summaries at `POC4/Errata/curated/`
12. Workers read curated errata, not the raw log

### Progression

13. When all jobs pass Proofmark for the current effective date, advance cursor to next date
14. Each new date follows the same protocol — any fix at date N requires re-running all dates 1 through N

### Failure Threshold

15. If any single job + effective date combination fails 5 times, flag as a failure. Execution continues for all other jobs.

### Final Review

16. When all jobs pass for all dates through Dec 31, 2024: spawn a separate review team to audit all non-STRICT Proofmark columns. Profile across all 92 effective dates. A field marked non-deterministic on day 1 that was never re-examined on subsequent days is a governance failure.

## Outputs

- Proofmark results for all jobs × all effective dates
- `POC4/Errata/raw-errata-log.md` (populated by triage workers)
- `POC4/Errata/curated/` (populated by errata curator)
- `POC4/Artifacts/{job_name}/proofmark-results.md` (summary per job)
- Non-STRICT column audit report
- List of any flagged failures

## Stop Condition

**Stop and report to BD when:** All jobs have passing Proofmark grades for all effective dates through Dec 31, 2024, AND the non-STRICT column audit is complete. Report any flagged failures. Do not proceed to any other phase. Your job is done.
