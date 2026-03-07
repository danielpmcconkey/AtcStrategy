# Proofmark Specialist — Reference Document

This section is appended to the Date Coordinator's system prompt. It contains
all knowledge needed to derive Proofmark configs at runtime and interpret results.

---

## Proofmark Overview

Proofmark is a comparison tool that validates V4 output matches V1 output.
It compares two files (left=V1, right=V4) and reports match percentage.

**Location:** `/workspace/MockEtlFramework/Tools/proofmark/`
**Full guide:** `/workspace/MockEtlFramework/Tools/proofmark/CONFIG_GUIDE.md`

---

## Proofmark Queue Service

Proofmark runs as a queue service, just like the ETL framework. You do NOT
invoke Proofmark directly via CLI. You INSERT comparisons into the database
queue and poll for results.

**Queue table:** `control.proofmark_test_queue`

### Queue Population

```sql
INSERT INTO control.proofmark_test_queue (config_path, lhs_path, rhs_path, job_key, date_key)
VALUES (
  '{path to proofmark config YAML}',
  '{V1 output path}',
  '{V4 output path}',
  '{job name}',
  '{effective date}'
);
```

### Polling for Completion

```sql
SELECT job_key, date_key, status, result, result_json, error_message
FROM control.proofmark_test_queue
WHERE date_key = '{date}'
  AND status NOT IN ('Succeeded', 'Failed');
```

When this returns 0 rows, all comparisons for this date are done.

### Reading Results

```sql
SELECT job_key, date_key, status, result, result_json, error_message
FROM control.proofmark_test_queue
WHERE date_key = '{date}';
```

- `status = 'Succeeded'` and `result = 'PASS'` → comparison passed
- `status = 'Succeeded'` and `result = 'FAIL'` → comparison ran but found differences
- `status = 'Failed'` → Proofmark itself errored (bad config, missing files, etc.)
- `result_json` contains the full Proofmark report as JSONB

---

## Output Path Pattern

```
V1: Output/curated/{jobDirName}/{outputTableDirName}/{date}/{fileName}
V4: Output/double_secret_curated/{jobDirName}/{outputTableDirName}/{date}/{fileName}
```

These path components come from the CsvFileWriter or ParquetFileWriter module
in the job config JSON.

---

## Config Derivation Procedure

You must derive Proofmark configs from job configs and actual output. Do NOT
use hardcoded values. Follow this procedure for each V1/V4 comparison pair:

### Step 1: Identify Output Files

Read the V1 job config at `JobExecutor/Jobs/{snake_case_name}.json`.

Find all writer modules (`type: "CsvFileWriter"` or `type: "ParquetFileWriter"`).
Each writer module produces one output file. A job may have multiple writers
(e.g., DansTransactionSpecial produces 2 CSVs).

Extract from each writer module:
- `jobDirName` — directory name under Output/curated/
- `outputTableDirName` — subdirectory name
- `fileName` — the output file name
- `writeMode` — "Overwrite" or "Append"
- `trailerFormat` — present or absent (determines if trailers exist)
- `includeHeader` — true/false

**If V1 config has only External modules (no writers):**
The External module handles its own output. Read the V4 config instead to get
output path components (V4 always uses framework writers). The V1 output lives
at the same relative path but under `Output/curated/` instead of
`Output/double_secret_curated/`.

### Step 2: Construct Paths

For this effective date, construct:
```
v1_path = Output/curated/{jobDirName}/{outputTableDirName}/{date}/{fileName}
v4_path = Output/double_secret_curated/{jobDirName}/{outputTableDirName}/{date}/{fileName}
```

Verify both files exist before queuing the comparison. If V1 output is missing,
report as an error (V1 should have produced output from its run).

### Step 3: Detect Trailers

**Do not assume trailer presence from config alone.** Verify from actual output:

1. Read the last line of the V1 output file
2. If it starts with `TRAILER|` → trailer is present
3. Determine trailer_rows:
   - If `writeMode: "Overwrite"` AND trailer detected: `trailer_rows: 1`
   - If `writeMode: "Append"`: `trailer_rows: 0` (trailers are embedded
     throughout the file in Append mode, not just at the end)
   - If no trailer detected: `trailer_rows: 0`

### Step 4: Check for Existing Proofmark Config

Look for an existing config at `POC4/Artifacts/{JobName}/proofmark*.yaml`.
If one exists, **use it** — it may contain FUZZY or EXCLUDED column overrides
from prior triage sessions. Do not overwrite tuned configs.

If no existing config, create one.

### Step 5: Create Config YAML

```yaml
comparison_target: "{JobName}_{outputTableDirName}"
reader: csv           # or "parquet" for ParquetFileWriter
threshold: 100.0      # always start at 100% strict
csv:
  header_rows: 1      # 1 if includeHeader is true, 0 otherwise
  trailer_rows: {from step 3}
```

Write the config to the working directory (the date results dir), NOT to
POC4/Artifacts/ (that's for curated, reviewed configs).

### Step 6: Queue Comparisons

INSERT each comparison into `control.proofmark_test_queue` with:
- `config_path` — absolute path to the YAML config you wrote
- `lhs_path` — absolute path to V1 output file
- `rhs_path` — absolute path to V4 output file
- `job_key` — V1 job name (e.g., "PeakTransactionTimes")
- `date_key` — effective date

**Use absolute paths.** The Proofmark service resolves paths from its own
working directory, so relative paths will break.

Queue ALL comparisons for this date at once, then poll for all of them.

### Step 7: Poll and Interpret Results

Poll `control.proofmark_test_queue` until all rows for this date show
`Succeeded` or `Failed`.

- `result = 'PASS'` → Record job as passed.
- `result = 'FAIL'` → Read `result_json` for mismatch details. Record job
  as failed with a clear reason string that includes the key mismatch info.
- `status = 'Failed'` → Proofmark errored. Record as failed with the
  `error_message`. This usually means missing files, bad config, or
  encoding issues — not a data mismatch.

---

## V1/V4 Job Pairing

The V4 job name is always the V1 name with "V4" appended:

| V1 Job | V4 Job |
|--------|--------|
| PeakTransactionTimes | PeakTransactionTimesV4 |
| DailyBalanceMovement | DailyBalanceMovementV4 |
| CreditScoreDelta | CreditScoreDeltaV4 |
| BranchVisitsByCustomerCsvAppendTrailer | BranchVisitsByCustomerCsvAppendTrailerV4 |
| DansTransactionSpecial | DansTransactionSpecialV4 |

To derive V1 name from a V4 name: strip the trailing "V4".

---

## Multi-Output Jobs

DansTransactionSpecial produces TWO output files from TWO separate writer
modules. You must queue a Proofmark comparison for EACH output file pair.
Both must pass for the job to count as passed.

---

## Edge Cases

**Empty output (header-only CSV):** After the empty-result framework fix
(commit `1fca961`), jobs that find no data produce a header-only CSV and
succeed. If both V1 and V4 produce header-only output, Proofmark should
pass (identical files). This commonly happens with CreditScoreDelta on
weekends.

**Matched failures:** If both V1 and V4 fail on the same date (e.g., both
crash on a weekend), skip Proofmark for that pair. Record as "skip" in
date-result.json, not as a failure.
