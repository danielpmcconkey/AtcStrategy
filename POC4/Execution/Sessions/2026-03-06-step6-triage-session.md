# Session Handoff: Step 6 Job Config Triage & Framework Changes

**Written:** 2026-03-06
**Previous handoff:** `2026-03-06-queue-runner-session.md`

---

## What We Accomplished

### 1. Priority 1 — Burned Deprecated Docs
Deleted `planning-progression.md` and `memory/poc4-roadmap.md`. Removed both from doc-registry.md.

### 2. Job Inventory & Cleanup
- Full DB inventory: 207 jobs existed at session start
- Deleted all 101 V2 jobs (DB + config files)
- Deleted POC3 reverse engineering artifacts (`AtcStrategy/POC3/artifacts/`)
- Cleaned control tables (truncated comparison_queue, verified no orphans)
- Consolidated Step 4 test jobs: kept CreditScoreDelta (CSV overwrite) and renamed BranchVisitsByCustomer → BranchVisitsByCustomerCsvAppendTrailer (CSV append with trailer). Deleted the other 2 test jobs.
- Final state: 105 V1 jobs, all `is_active = false`

### 3. Config Compatibility Evaluation
Background agent evaluated all 104 V1 configs (before DansTransactionSpecial) against Steps 4-5 framework changes. **Zero breaks.** All backward compatible. Written to `step6-config-eval.md`.

### 4. Anti-Pattern Coverage Evaluation
Background agent assessed anti-pattern density. 85-90% of jobs have at least one anti-pattern. All 10 official patterns represented. 4 are THIN but present (AP2, AP5, AP8, AP9, AP10). Dan said coverage is sufficient — no changes needed. Written to `step6-antipattern-coverage.md`.

### 5. Dual-Output Audit
62 jobs have both External + framework writer. All 62 are COMPUTE-ONLY — External does processing, framework writer does file output. No duplicate file writing. Written to `step6-dual-output-audit.md`.

### 6. Framework Change: Effective Date Required
Auto-advance removed from JobExecutorService. Effective date is now a required parameter. CLI fails without a date argument. 113 tests passing. Architecture.md and CLAUDE.md updated.

### 7. Framework Change: outputTableDirName
New required config field for CsvFileWriter and ParquetFileWriter. Output path is now:
```
{outputDirectory}/{jobDirName}/{outputTableDirName}/{etl_effective_date}/{fileName}
```
This fixes the append bug where two writers sharing a jobDirName would confuse each other's partition lookup. All 97 configs with framework writers updated (98 writer modules total). 113 tests passing (2 new). Architecture.md updated.

### 8. Doctrine Update: Job Boundary Preservation
Added to §1.1: "One V1 job produces one V2 job. Agents must not split a single V1 job into multiple V2 jobs."

### 9. DansTransactionSpecial — New Multi-Output Job (job_id 373)
Detail/aggregate pattern: sources transactions (T-0), accounts/customers/addresses (mostRecent), joins into enriched detail (CSV overwrite), aggregates by state/province (CSV append).

Verified: append accumulates correctly (32 → 63 → 94 lines over 3 dates).

Independent reviewer found issues — see open items below.

---

## Open Items for Next Session

### DISCUSS WITH DAN: Multi-Address Join Duplication (DansTransactionSpecial)
Customer 1001 has two addresses starting Oct 2. The LEFT JOIN on customer_id fans out, duplicating transactions — inflates both detail rows and aggregate sums. Small impact now (1 extra row per day out of ~4200) but it's a real data integrity bug. The Transformation SQL needs deduplication (e.g., ROW_NUMBER() to pick one address per customer, or a more specific join key). Dan acknowledged this — needs to discuss approach.

### DISCUSS WITH DAN: Append Mode Loses Date Provenance
The CsvFileWriter append mode drops etl_effective_date from prior data and re-stamps ALL rows with the current run date. In the aggregate file, you can't tell which rows came from which day. This is framework behavior. Options: add etl_effective_date as a grouping dimension in the Transformation SQL, or change the framework's append behavior to preserve original dates. Dan acknowledged this — needs to discuss approach.

### Minor: DB Path Inconsistency
5 jobs (IDs 32, 33, 369, 371, 373) use relative paths in job_conf_path while the other 100 use absolute paths. All resolve correctly. Cosmetic only.

---

## What To Do Next

### Priority 1: Resolve the two DansTransactionSpecial open items above

### Priority 2: Continue Step 6 — is it done?
The triage question was: "Which configs survive the new write mode architecture? Which need rewrite?" Answer: all survive, zero breaks. Anti-pattern coverage is sufficient. Framework changes are complete. The remaining question is whether Step 6 needs a formal close-out governance packet, or if the eval docs (`step6-config-eval.md`, `step6-antipattern-coverage.md`, `step6-dual-output-audit.md`) are sufficient evidence.

### Priority 3: Step 7 — External Changes & Known Gap Fixes
Per canonical steps: T-0/T-N no-data crash fix, any gaps surfaced by Step 6, CreditScoreDelta Parquet variants.

---

## What To Read
1. **This file**
2. **Canonical steps:** `Governance/canonical-steps.md`
3. **Config eval:** `Execution/step6-config-eval.md`
4. **Anti-pattern coverage:** `Execution/step6-antipattern-coverage.md`
5. **Program Doctrine:** `ProgramDoctrine/program-doctrine.md` (updated with job boundary rule)

## What NOT To Read
- Dual-output audit (all COMPUTE-ONLY, no action needed)
- AAR log, POC3 docs
- Queue runner code (done and tested)
