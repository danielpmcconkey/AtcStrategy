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

## Concurrency Target

**Keep 8-12 triage subagents in flight at all times** when triaging failures.
When one finishes, immediately launch the next. Do not wait for a full batch
to complete before starting the next batch.

## Progress Reporting

Maintain a structured progress file at `POC4/Artifacts/e6-progress.md` that BD
can poll. Update after each effective date completes. Format:

```markdown
# E.6 Progress

## Cursor: {current effective date}

| Effective Date | V1 Run | V4 Run | Proofmark | Failures | Triage | Status |
|----------------|--------|--------|-----------|----------|--------|--------|
| 2024-10-01 | done | done | done | 0 | n/a | PASS |
| 2024-10-02 | done | done | done | 2 | in-progress | TRIAGING |
| ... | | | | | | |

## Job Failure Tracker

| Job | Failures | Flagged? |
|-----|----------|----------|
| {name} | {count} | {yes if ≥5} |
```

## Task Queue Rules

When populating the task queue for V1 or V4 job runs:
**Append-mode jobs must be queued with execution_mode = 'serial'** to prevent
cross-date output contamination. All other jobs use 'parallel'.

## Execution

### Effective Date Progression

1. Begin with ETL effective date Oct 1, 2024
2. For the current effective date:
   - Populate task queue with all V1 and V4 jobs for that date (respecting
     serial/parallel rules above), then start the queue service
   - Run Proofmark on all output for that date
   - Review Proofmark output and triage any failures

### Triage Protocol

3. Before triage, check `POC4/Errata/curated/` for already-learned lessons
4. For jobs with failures, spawn triage workers to diagnose and fix
5. For jobs with errors believed fixed, re-run V4 code only (do NOT re-run V1)
6. A "fix" may include Proofmark config YAML changes — moving a column from STRICT to FUZZY or EXCLUDED — **only** with sufficient evidence to warrant it
7. When fixing any job config or Proofmark config: **re-run ALL effective dates up to and including the current cursor date.** No partial validation.
8. After each fix, triage worker appends an entry to `POC4/Errata/raw-errata-log.md`

### Errata Curation

9. After each effective date's triage completes, spawn the errata curator
10. Curator reads raw errata log, produces/updates curated summaries at `POC4/Errata/curated/`
11. Workers read curated errata, not the raw log

### Progression

12. When all jobs pass Proofmark for the current effective date, advance cursor to next date
13. Each new date follows the same protocol — any fix at date N requires re-running all dates 1 through N

### Failure Threshold

14. If any single job + effective date combination fails 5 times, flag as a failure. Execution continues for all other jobs.

### Final Review

15. When all jobs pass for all dates through Dec 31, 2024: spawn a separate review team to audit all non-STRICT Proofmark columns. Profile across all 92 effective dates. A field marked non-deterministic on day 1 that was never re-examined on subsequent days is a governance failure.

## Outputs

- Proofmark results for all jobs × all effective dates
- `POC4/Errata/raw-errata-log.md` (populated by triage workers)
- `POC4/Errata/curated/` (populated by errata curator)
- `POC4/Artifacts/{job_name}/proofmark-results.md` (summary per job)
- Non-STRICT column audit report
- List of any flagged failures
- `POC4/Artifacts/e6-progress.md`

## Stop Condition

**Stop and report to BD when:** All jobs have passing Proofmark grades for all effective dates through Dec 31, 2024, AND the non-STRICT column audit is complete. Report any flagged failures. Do not proceed to any other phase. Your job is done.
