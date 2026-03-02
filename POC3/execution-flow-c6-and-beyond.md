# POC3 Execution Flow: C.6 and Beyond

**Written:** 2026-03-02 by Basement Dweller
**Companion to:** `d1-postmortem-and-recommendations.md`
**Purpose:** Step-by-step execution flow for every job through the pipeline, assuming the task queue service and Proofmark batch mode are implemented.

---

## Job Portfolio Summary

| Writer Type | Write Mode | Count | Behavior Across 92 Dates |
|-------------|-----------|-------|--------------------------|
| CsvFileWriter | Overwrite | 42 | Each date replaces previous. Final file = last date only. |
| CsvFileWriter | Append | 12 | Each date appends rows. Final file = all 92 dates accumulated. |
| ParquetFileWriter | Overwrite | 33 | Each date replaces part files. Final directory = last date only. |
| ParquetFileWriter | Append | 7 | Each date appends part files. Final directory = all 92 dates accumulated. |
| External (own I/O) | varies | 7 | External modules handle their own file writing. Behavior per-job. |
| **Total** | | **101** | |

Note: Some jobs have both External modules AND framework writers. The 7 "External-only" jobs handle their own I/O without CsvFileWriter or ParquetFileWriter.

**This matters because:** Overwrite-mode jobs only care about the final date's output. Append-mode jobs accumulate across all dates. Both V1 and V2 must be run identically for comparison to be valid.

---

## Infrastructure Prerequisites

### 1. Task Queue Service (MockEtlFramework)

See `d1-postmortem-and-recommendations.md` for full design.

**Short version:** New `--service` mode in JobExecutor. Polls `control.task_queue` for `(job_name, effective_date)` pairs. Executes one at a time. Marks success/failure. Sleeps on empty queue.

### 2. Proofmark Batch Mode

See `d1-postmortem-and-recommendations.md` for full design.

**Short version:** New `proofmark batch --manifest <file>` command. Reads a CSV of `config|lhs|rhs|output` rows. Runs each comparison sequentially. Produces individual JSON reports + summary.

### 3. Queue Population Script

Generates `control.task_queue` entries for a given set of jobs across a date range:

```sql
-- Template: populate queue for V1 jobs
INSERT INTO control.task_queue (job_name, effective_date)
SELECT j.job_name, d.dt::date
FROM control.jobs j
CROSS JOIN generate_series('2024-10-01'::date, '2024-12-31'::date, '1 day') d(dt)
WHERE j.is_active = true
  AND j.job_name NOT LIKE '%V2'
ORDER BY d.dt, j.job_name;

-- Template: populate queue for V2 jobs
INSERT INTO control.task_queue (job_name, effective_date)
SELECT j.job_name, d.dt::date
FROM control.jobs j
CROSS JOIN generate_series('2024-10-01'::date, '2024-12-31'::date, '1 day') d(dt)
WHERE j.is_active = true
  AND j.job_name LIKE '%V2'
ORDER BY d.dt, j.job_name;
```

**Queue ordering:** `ORDER BY d.dt, j.job_name` means all jobs for 2024-10-01 run first, then all for 2024-10-02, etc. This matches real-world ETL scheduling (all jobs for a given business date run together). Alternative: `ORDER BY j.job_name, d.dt` runs each job through all dates before moving to the next — useful for debugging a single job but less realistic.

### 4. Proofmark Manifest Generator

Script that reads `POC3/proofmark_configs/*.yaml` and generates the batch manifest:

```bash
#!/bin/bash
# generate_proofmark_manifest.sh
# Reads each config YAML and determines LHS/RHS paths

MANIFEST="POC3/proofmark_batch.csv"
echo "config,lhs,rhs,output" > "$MANIFEST"

for config in POC3/proofmark_configs/*.yaml; do
    job=$(basename "$config" .yaml)
    reader=$(python3 -c "import yaml; print(yaml.safe_load(open('$config'))['reader'])")

    if [ "$reader" = "parquet" ]; then
        lhs="Output/curated/$job"
        rhs="Output/double_secret_curated/$job"
    else
        lhs="Output/curated/${job}.csv"
        rhs="Output/double_secret_curated/${job}.csv"
    fi

    echo "$config,$lhs,$rhs,POC3/logs/proofmark_reports/${job}.json" >> "$MANIFEST"
done
```

Note: The 7 External I/O jobs may have non-standard output paths. The manifest generator needs to check the V2 job config or FSD for the actual output path. This is a one-time fixup.

---

## Phase C.6: Populate V1 Baseline

**Status: ALREADY COMPLETE.** V1 baseline is locked read-only. 101 output items in `Output/curated/`. Each V1 job has 1 successful run record at `max_effective_date = 2024-12-31`. This does not need to be re-run.

**However:** If we're building the task queue service anyway, we could validate it by re-running C.6 through the queue and comparing output to the existing baseline. This is optional but would prove the service works before we rely on it for D.1.

### C.6 Execution Flow (if re-running with task queue)

1. **Activate V1 jobs, deactivate V2 jobs**
   ```sql
   UPDATE control.jobs SET is_active = true WHERE job_name NOT LIKE '%V2';
   UPDATE control.jobs SET is_active = false WHERE job_name LIKE '%V2';
   ```

2. **Clean V1 run history**
   ```sql
   DELETE FROM control.job_runs WHERE job_id IN (
     SELECT job_id FROM control.jobs WHERE job_name NOT LIKE '%V2'
   );
   ```

3. **Clean V1 output** — Can't do this because `Output/curated/` is locked read-only by root. To re-run C.6, Dan would need to unlock it from the host first. **Recommendation: skip C.6 re-run. V1 baseline is fine.**

4. **Populate queue**
   ```sql
   INSERT INTO control.task_queue (job_name, effective_date)
   SELECT j.job_name, d.dt::date
   FROM control.jobs j
   CROSS JOIN generate_series('2024-10-01'::date, '2024-12-31'::date, '1 day') d(dt)
   WHERE j.is_active = true AND j.job_name NOT LIKE '%V2'
   ORDER BY d.dt, j.job_name;
   -- Expected: 101 jobs × 92 dates = 9,292 tasks
   ```

5. **Start service**
   ```bash
   dotnet run --project JobExecutor -- --service
   ```

6. **Monitor progress**
   ```sql
   SELECT status, COUNT(*) FROM control.task_queue GROUP BY status;
   ```

7. **Service drains queue, goes idle.** Stop with Ctrl+C.

---

## Phase D.1: Run V2 Jobs

### Pre-requisites

1. Task queue service is built and tested
2. V1 baseline is intact and read-only in `Output/curated/`
3. V2 output directory is clean

### Step-by-step

1. **Activate V2 jobs, deactivate V1 jobs**
   ```sql
   UPDATE control.jobs SET is_active = false WHERE job_name NOT LIKE '%V2';
   UPDATE control.jobs SET is_active = true WHERE job_name LIKE '%V2';
   ```

2. **Clean V2 run history**
   ```sql
   DELETE FROM control.job_runs WHERE job_id IN (
     SELECT job_id FROM control.jobs WHERE job_name LIKE '%V2'
   );
   ```

3. **Clean V2 output**
   ```bash
   rm -rf Output/double_secret_curated/*
   ```

4. **Clean task queue**
   ```sql
   DELETE FROM control.task_queue;
   ```

5. **Populate V2 queue**
   ```sql
   INSERT INTO control.task_queue (job_name, effective_date)
   SELECT j.job_name, d.dt::date
   FROM control.jobs j
   CROSS JOIN generate_series('2024-10-01'::date, '2024-12-31'::date, '1 day') d(dt)
   WHERE j.is_active = true AND j.job_name LIKE '%V2'
   ORDER BY d.dt, j.job_name;
   -- Expected: 101 jobs × 92 dates = 9,292 tasks
   ```

6. **Start service**
   ```bash
   dotnet run --project JobExecutor -- --service
   # Or with controlled parallelism:
   dotnet run --project JobExecutor -- --service --workers 2
   ```

7. **Monitor progress** (from another terminal)
   ```sql
   -- Overall progress
   SELECT status, COUNT(*) FROM control.task_queue GROUP BY status;

   -- Failed tasks (investigate these)
   SELECT job_name, effective_date, error_message
   FROM control.task_queue WHERE status = 'Failed'
   ORDER BY job_name, effective_date LIMIT 20;

   -- Per-job summary
   SELECT job_name,
     SUM(CASE WHEN status='Succeeded' THEN 1 ELSE 0 END) as ok,
     SUM(CASE WHEN status='Failed' THEN 1 ELSE 0 END) as fail,
     SUM(CASE WHEN status='Pending' THEN 1 ELSE 0 END) as pending
   FROM control.task_queue
   GROUP BY job_name
   HAVING SUM(CASE WHEN status='Failed' THEN 1 ELSE 0 END) > 0
   ORDER BY job_name;
   ```

8. **Expected runtime:** 9,292 tasks × ~2-5 seconds each (rough estimate for single-threaded) = ~5-13 hours. With `--workers 2`: roughly half that. This is a background grind — start it and go do something else.

9. **Expected failures:**
   - Some jobs will fail on certain dates due to missing weekend/holiday data in the datalake (same pattern as V1 C.6). This is expected and should match the V1 failure pattern.
   - `RepeatOverdraftCustomersV2` and `SuspiciousWireFlagsV2` were failing on every date in the crashed D.1 run. These may have real code bugs that need investigation regardless.

10. **Service drains queue, goes idle.** Stop with Ctrl+C.

### What "Done" Looks Like

```sql
-- All tasks should be Succeeded or Failed (no Pending)
SELECT status, COUNT(*) FROM control.task_queue GROUP BY status;

-- Expected: ~9,000+ Succeeded, some Failed (weekend/missing data pattern)
-- Any job with ALL 92 dates Failed is a real problem
-- Any job with SOME dates Failed is probably the weekend pattern (compare to V1)
```

Verify output exists:
```bash
ls Output/double_secret_curated/ | wc -l
# Should be 101 items (mix of .csv files and directories)
```

---

## Phase D.2: Run Proofmark Comparisons

### Pre-requisites

1. Proofmark batch mode is built
2. D.1 is complete (all queue tasks Succeeded or accounted-for Failures)
3. V2 output exists in `Output/double_secret_curated/`

### Step-by-step

1. **Generate batch manifest**
   ```bash
   ./generate_proofmark_manifest.sh
   # Produces POC3/proofmark_batch.csv with 101 rows
   ```

2. **Clean prior proofmark reports**
   ```bash
   rm -f POC3/logs/proofmark_reports/*.json
   ```

3. **Run batch**
   ```bash
   cd /workspace/MockEtlFramework
   python3 -m proofmark batch \
     --manifest POC3/proofmark_batch.csv \
     --continue-on-error
   ```

4. **Review summary output**
   The batch command should print something like:
   ```
   101 comparisons complete
   PASS: 78
   FAIL: 23
   ERROR: 0
   ```

5. **Categorize failures**
   ```bash
   # Quick tally
   for f in POC3/logs/proofmark_reports/*.json; do
     result=$(python3 -c "import json; print(json.load(open('$f'))['summary']['result'])")
     echo "$result $(basename $f .json)"
   done | sort | uniq -c | sort -rn
   ```

### Expected Failure Categories

| Category | Expected Count | Description |
|----------|---------------|-------------|
| Saboteur mutations | 10-12 | Deliberately planted code-level mutations. These SHOULD fail. |
| Parquet type mismatches | ~33 (all Parquet jobs) | int32→int64, decimal→double. Systemic V2 code issue. |
| Legitimate logic errors | Unknown | Real bugs in V2 code. This is what Phase D resolution is for. |
| Stealth mutations | 0-2 | Saboteur mutations #4 and #10 were designed to NOT cause Proofmark failures. If they pass, that's correct. |

**Key insight:** The Parquet type mismatches will mask everything else for Parquet jobs. We need to decide: fix the type issue proactively (before resolution agents) or let resolution agents discover it (more honest for the POC narrative but wastes tokens on 33 identical diagnoses).

**Recommendation:** Fix the Parquet type mapping issue proactively. It's an infrastructure/framework interop problem, not a logic error. Resolution agents should spend their tokens on actual logic discrepancies, not on "your int is the wrong width." Document this as a known framework limitation with a pre-applied fix.

---

## Phase D.3: Triage Results

This is where the blind lead (BBC) takes over again. The orchestrator provides BBC with the 101 proofmark reports and BBC categorizes each job:

| Proofmark Result | Action |
|-----------------|--------|
| PASS | Mark as VALIDATED. No further work needed. |
| FAIL | Queue for resolution. BBC spawns resolution agents. |
| ERROR | Investigate. Likely a config problem or missing output file. |

### Triage Output

BBC produces a triage manifest:
```
VALIDATED: N jobs (list)
NEEDS_RESOLUTION: M jobs (list with failure summary)
ERROR: K jobs (list with error detail)
```

---

## Phase D.4: Resolution Loop (Per Failing Job)

For each FAIL job, a resolution agent runs the following cycle:

```
┌─────────────────────────────────────┐
│ 1. Read Proofmark report            │
│ 2. Read V2 code + V1 code           │
│ 3. Read FSD + BRD                   │
│ 4. Diagnose root cause              │
│    ├─ BRD error (saboteur)          │
│    ├─ V2 code bug                   │
│    ├─ Non-deterministic field       │
│    └─ Proofmark config error        │
│ 5. Fix (code, BRD, FSD, config)     │
│ 6. Update upstream docs             │
│ 7. Re-run single job (all dates)    │◄── Task queue: repopulate for this job
│ 8. Re-run Proofmark for this job    │
│ 9. PASS? → VALIDATED                │
│    FAIL? → Back to step 1           │
│    (max 6 attempts per job)         │
└─────────────────────────────────────┘
```

**Task queue integration for step 7:** When a resolution agent fixes a V2 job and needs to re-run it:
```sql
-- Clean this job's prior queue entries
DELETE FROM control.task_queue WHERE job_name = '{JobNameV2}';

-- Clean this job's run history
DELETE FROM control.job_runs WHERE job_id = (
  SELECT job_id FROM control.jobs WHERE job_name = '{JobNameV2}'
);

-- Clean this job's output
-- (rm the specific output file/directory)

-- Repopulate queue for just this job
INSERT INTO control.task_queue (job_name, effective_date)
SELECT '{JobNameV2}', d.dt::date
FROM generate_series('2024-10-01'::date, '2024-12-31'::date, '1 day') d(dt)
ORDER BY d.dt;
-- 92 tasks for this one job
```

Then either:
- Start the service if it's not running: `dotnet run --project JobExecutor -- --service`
- Or if service is already running, it'll pick up the new tasks automatically

Then re-run proofmark for just this job:
```bash
python3 -m proofmark compare \
  --config POC3/proofmark_configs/{job_name}.yaml \
  --left Output/curated/{v1_path} \
  --right Output/double_secret_curated/{v2_path} \
  --output POC3/logs/proofmark_reports/{job_name}.json
```

### Resolution Loop Token Budget

Each resolution agent reads 5-6 documents per attempt. With 12+ expected failures and up to 6 attempts each, worst case is ~72 heavy subagent invocations. This is why the fresh token cycle is important — D.4 is the most expensive phase.

---

## Phase D.5: Escalation

Jobs that fail 6 resolution attempts get escalated to Dan. The resolution agent writes a detailed "I tried everything" report. Dan decides: manual fix, accept the discrepancy, or punt to POC4.

---

## Phase D.6: Document Consistency Verification

After all resolutions are complete, read-only verification agents check each VALIDATED job's full doc chain: BRD ↔ FSD ↔ test plan ↔ Proofmark config ↔ V2 code. Any inconsistency sends the job back for one more fix cycle.

---

## Phase E: Governance Package

Final deliverable for CIO presentation. Aggregate results, scorecard, lessons learned.

---

## Execution Timeline Estimate

| Phase | Work | Estimated Duration | Token Cost |
|-------|------|--------------------|------------|
| Infrastructure | Build task queue service + Proofmark batch mode | 2-4 hours (us) | Moderate |
| D.1 re-run | 9,292 queue tasks, single-threaded | 5-13 hours (background grind) | Near zero (compute only) |
| D.2 | 101 Proofmark comparisons | 10-30 minutes | Near zero |
| D.3 | Triage | 30 minutes | Low |
| D.4 | Resolution loops (~12-20 jobs) | 2-4 hours of agent work | HIGH |
| D.5 | Escalation review | Dan's time | N/A |
| D.6 | Consistency verification | 1-2 hours of agent work | Moderate |
| E | Governance package | 1-2 hours | Moderate |

**CIO presentation: March 24.** We have ~3 weeks. This is tight but very doable if we build the infrastructure this week and let D.1 grind over a night or weekend.

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Parquet type mismatches obscure real failures | HIGH | MEDIUM | Fix proactively before D.2 |
| Task queue service has bugs | LOW | HIGH | Test with a small queue (5 jobs × 3 dates) before full run |
| D.1 re-run reveals new systemic issues | LOW | HIGH | Monitor first 100 tasks before walking away |
| Weekend/missing data causes unexpected failures | MEDIUM | LOW | Compare V2 failure pattern to V1 C.6 pattern — should match |
| Resolution agents burn tokens on type mismatch diagnosis | HIGH | MEDIUM | Fix type issues proactively; agents focus on logic |
| Hard power cycle corrupted something | LOW | HIGH | Run `fsck` results check, verify git repos are clean |
