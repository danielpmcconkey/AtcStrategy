# Proofmark Setup Agent — One-Time Config Derivation

You run ONCE before the E.6 date loop begins. Your job: read all job configs
and FSDs, derive Proofmark comparison configs, and write a comparison manifest
that the bash sequencer uses for all 92 dates.

---

## HARD RULES

1. **You run once.** Produce your output and exit.
2. **You do NOT run Proofmark.** You create configs and a manifest. That's it.
3. **You do NOT modify job configs, code, or framework files.**
4. **Start STRICT.** Every column is STRICT by default. Only add FUZZY or
   EXCLUDED overrides if the FSD or code provides clear evidence that a column
   is non-deterministic or has floating-point precision issues.
5. **Evidence required.** Every FUZZY/EXCLUDED column must cite the specific
   code path or FSD section that justifies it.
6. **Respect existing configs.** If a Proofmark config already exists at
   `POC4/Artifacts/{JobName}/proofmark*.yaml`, use it as the starting point.
   It may have overrides from prior triage.

---

## Database

```bash
PGPASSWORD=claude psql -h 172.18.0.1 -U claude -d atc -c "..."
```

---

## Input

Your prompt tells you:
- Where to write the comparison manifest
- Where to write the Proofmark config YAML files

## Output

### 1. Proofmark Config YAMLs

One YAML file per comparison (not per job — DansTransactionSpecial gets two).

Config format:
```yaml
comparison_target: "{descriptive name}"
reader: csv
threshold: 100.0
csv:
  header_rows: 1
  trailer_rows: 0    # see derivation rules below
# Only add if evidence supports it:
columns:
  fuzzy:
    - name: "column_name"
      tolerance: 0.0001
      tolerance_type: "absolute"
      reason: "cite FSD section or code path"
  excluded:
    - name: "column_name"
      reason: "cite FSD section or code path"
```

### 2. Comparison Manifest

A JSON file the bash sequencer reads. Format:

```json
{
  "comparisons": [
    {
      "job_key": "PeakTransactionTimes",
      "config_path": "/absolute/path/to/config.yaml",
      "lhs_template": "/workspace/MockEtlFramework/Output/curated/{jobDirName}/{outputTableDirName}/{date}/{fileName}",
      "rhs_template": "/workspace/MockEtlFramework/Output/double_secret_curated/{jobDirName}/{outputTableDirName}/{date}/{fileName}"
    }
  ]
}
```

- `lhs_template` and `rhs_template` use `{date}` as a placeholder. The bash
  loop substitutes the actual effective date.
- Use **absolute paths** for everything.
- `config_path` points to the YAML you wrote.

---

## Procedure

### For each of the 5 V1 jobs:

1. **Read the V1 job config** at `JobExecutor/Jobs/{snake_case_name}.json`

2. **Find writer modules** (`CsvFileWriter`, `ParquetFileWriter`).
   Extract: `jobDirName`, `outputTableDirName`, `fileName`, `writeMode`,
   `trailerFormat` (if present), `includeHeader`.

3. **If V1 has only External modules (no writers):** Read the V4 config to get
   output path components. V4 always uses framework writers. V1 output lives at
   the same path under `Output/curated/`.

4. **Determine trailer_rows:**
   - If `writeMode: "Append"` → `trailer_rows: 0` (trailers embedded, not at end)
   - If `writeMode: "Overwrite"` AND `trailerFormat` is present → `trailer_rows: 1`
   - If no `trailerFormat` → `trailer_rows: 0`

5. **Read the FSD** at `POC4/Artifacts/{JobName}/fsd.md`. Look for:
   - Columns documented as non-deterministic (timestamps, random IDs)
   - Columns with known floating-point precision issues
   - Any notes about expected differences between V1 and V4

6. **Check for existing Proofmark config** at `POC4/Artifacts/{JobName}/proofmark*.yaml`.
   If found, use it as the base (preserve any FUZZY/EXCLUDED overrides).

7. **Write the YAML config** to `POC4/Artifacts/{JobName}/proofmark.yaml`
   (or `proofmark-{output_name}.yaml` for multi-output jobs). These are
   durable artifacts, not temp files. They live with the job's other docs.

8. **Add entry to the comparison manifest** with the absolute path to the
   YAML and the LHS/RHS path templates.

### Multi-output jobs

DansTransactionSpecial has TWO writer modules producing TWO output files.
Create a separate config and manifest entry for each. Use distinct `job_key`
values (e.g., `DansTransactionSpecial_details`, `DansTransactionSpecial_by_state`).

---

## V1/V4 Job Pairing

| V1 Job | V4 Job | Config File |
|--------|--------|-------------|
| PeakTransactionTimes | PeakTransactionTimesV4 | peak_transaction_times.json |
| DailyBalanceMovement | DailyBalanceMovementV4 | daily_balance_movement.json |
| CreditScoreDelta | CreditScoreDeltaV4 | credit_score_delta.json |
| BranchVisitsByCustomerCsvAppendTrailer | BranchVisitsByCustomerCsvAppendTrailerV4 | branch_visits_by_customer_csv_append_trailer.json |
| DansTransactionSpecial | DansTransactionSpecialV4 | dans_transaction_special.json |

Job configs at: `/workspace/MockEtlFramework/JobExecutor/Jobs/`
FSDs at: `/workspace/AtcStrategy/POC4/Artifacts/{JobName}/fsd.md`
Existing Proofmark configs at: `/workspace/AtcStrategy/POC4/Artifacts/{JobName}/proofmark*.yaml`
