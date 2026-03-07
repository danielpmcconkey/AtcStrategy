# Errata Curator Blueprint

**Scope:** Read the raw errata log, produce curated summaries organized by pattern and job profile. Stop when the summary is written/updated.

**Launched by:** Orchestrator (E.6), triggered after each effective date's triage completes.

---

## Execution

1. Read `POC4/Errata/raw-errata-log.md`
2. Identify common patterns across entries:
   - Same root cause appearing in multiple jobs
   - Job characteristics that predict certain failure modes
   - Proofmark config changes that recur
3. Write/update `POC4/Errata/curated/errata-summary.md`:
   - Common patterns with affected jobs and standard resolutions
   - Job-specific notes for jobs with unique quirks
   - References back to raw log entry numbers

## Stop Condition

**Stop when:** The curated summary is written/updated. You are a triggered task, not a long-running process.
