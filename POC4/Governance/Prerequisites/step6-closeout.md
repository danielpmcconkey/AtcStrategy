# Step 6 Close-Out: Job Config Triage

**Completed:** 2026-03-06
**Signed off by:** Dan

## Triage Question

"Which configs survive the new write mode architecture? Which need rewrite?"

## Answer

All 105 V1 job configs survive. Zero breaks. No rewrites needed.

## Evidence

### Evaluation Docs
- `Execution/step6-config-eval.md` — All 104 configs (pre-DansTransactionSpecial) evaluated against Steps 4-5 framework changes. Zero compatibility issues.
- `Execution/step6-antipattern-coverage.md` — All 10 anti-patterns represented across the job inventory. 85-90% of jobs have at least one. Coverage sufficient for POC4, no synthetic jobs needed.
- `Execution/step6-dual-output-audit.md` — 62 jobs with both External + framework writer. All 62 are COMPUTE-ONLY (External does processing, framework writer does file output). No duplicate file writing conflicts.

### Inventory Cleanup
- Deleted all 101 V2 jobs (DB rows + config files) — stale artifacts from prior runs.
- Deleted POC3 reverse engineering artifacts (`AtcStrategy/POC3/artifacts/`).
- Consolidated Step 4 test jobs to 2 (CreditScoreDelta, BranchVisitsByCustomerCsvAppendTrailer). Deleted 2 redundant test jobs.
- Truncated `control.comparison_queue`, verified no orphan rows.
- Cleared `control.job_runs` — no stale run history.
- Final state: 105 V1 jobs in DB, 105 config files on disk, 1:1 match, all `is_active = true`.

### Framework Changes
- **`outputTableDirName`** — New required config field for CsvFileWriter and ParquetFileWriter. Output path is now `{outputDirectory}/{jobDirName}/{outputTableDirName}/{etl_effective_date}/{fileName}`. Fixes the append bug where two writers sharing a `jobDirName` would confuse each other's partition lookup. All 97 configs with framework writers updated (98 writer modules total). 2 new tests. See `Documentation/Architecture.md`.
- **Effective date required** — Auto-advance removed from JobExecutorService. CLI fails without a date argument. See `Documentation/Architecture.md`.

### DansTransactionSpecial (job_id 373)
New multi-output exemplar job: detail/aggregate pattern sourcing transactions (T-0), accounts/customers/addresses (mostRecent). Two fixes applied:
1. **Address dedup** — CTE with `ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY start_date DESC)` to eliminate fan-out from multi-address customers.
2. **Date provenance** — `ifw_effective_date` sourced from datalake and carried through to output. Aggregate groups by `ifw_effective_date` + `state_province`, preserving day-over-day history in the append file.

### Doctrine Update
Added to §1.1: "One V1 job produces one V2 job. Agents must not split a single V1 job into multiple V2 jobs."

### Burned Deprecated Docs
- Deleted `planning-progression.md` and `memory/poc4-roadmap.md`. Removed from doc-registry.

## Transcript Evidence

All Step 6 work was performed during 2026-03-06 sessions. Full transcripts at `/workspace/.transcripts/` — filter by date for detailed execution logs.

## Tests

113 tests passing at step close. No regressions.
