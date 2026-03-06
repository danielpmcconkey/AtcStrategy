# Session Handoff: Write Mode Variants — All Four Validated

**Written:** 2026-03-05 (session 2 of the day)
**Previous handoff:** CreditScoreDelta CSV Overwrite done, CSV Append next.
**Dan says hi.**

---

## What We Accomplished

All four write mode variants are now validated. This may complete POC4 Step 3 — Dan thinks so, but future-you needs to read the roadmap (`memory/poc4-roadmap.md`) and confirm with Dan.

### Jobs built and validated this session

1. **CreditScoreDeltaCsvAppend** — `JobExecutor/Jobs/credit_score_delta_csv_append.json`
   - Same sources/SQL as CSV Overwrite, `writeMode: "Append"`
   - Output columns updated to match Dan's reference query: added `ifw_effective_date`, `past_ifw_effective_date`, renamed `prior_score` → `past_score`
   - Ran Oct 1-10: 8/10 succeeded (Oct 5-6 have no credit_scores data in datalake — weekends)
   - Output at `Output/poc4/credit_score_delta_csv_append/`

2. **BranchVisitsByCustomer** — `JobExecutor/Jobs/branch_visits_by_customer.json`
   - CSV Append + trailing record (`TRAILER|{row_count}|{date}`)
   - Branch visits (7-day data) LEFT JOIN customers (weekday only, `mostRecent`)
   - Tests the "main table has today's data, enrichment doesn't" scenario — weekends use Friday's customer snapshot
   - `additionalFilter: "customer_id < 1500"` to keep output manageable
   - Ran Oct 1-10: 10/10 succeeded (branch_visits has weekend data)
   - Output at `Output/poc4/branch_visits_by_customer/`

3. **BranchVisitsByCustomerParquetAppend** — `JobExecutor/Jobs/branch_visits_by_customer_parquet_append.json`
   - Same sources/SQL as above, Parquet Append writer
   - Ran Oct 1-10: 10/10 succeeded
   - Output at `Output/poc4/branch_visits_by_customer_parquet_append/`

### Proofmark validation

Converted all 10 Parquet partitions to CSV (with matching trailing records) and ran proofmark STRICT mode against the CSV Append output. **10/10 PASS, zero mismatches.** This proves CSV and Parquet writers produce identical data through the append pipeline.

### Framework changes this session

1. **Append mode trailer stripping** — CsvFileWriter now strips the trailing record from the prior partition's CSV before parsing. When `trailerFormat` is set and `writeMode` is Append, it reads the file as lines, drops the last line (`lines[..^1]`), then parses via `FromCsvLines`. Without this fix, the prior trailer would be carried forward as a garbage data row.

2. **`DataFrame.FromCsvLines(string[] lines)`** — new static factory method. Shared parse logic used by both `FromCsv(filePath)` and the trailer-stripping path. Keeps trailer responsibility in CsvFileWriter, not DataFrame.

### Test count: 111 (was 106 at session start)

New tests: `FromCsvLines` parsing (3), CsvFileWriter append+trailer strips prior trailer (1), append-without-trailer doesn't strip last row (1).

### Architecture docs updated

Background agent updated `Documentation/Architecture.md` covering all framework changes from both sessions: date resolution modes, empty DataFrames, trailer stripping, `FromCsvLines`, corrected CsvFileWriter property names.

## Open Issues

### Default date resolution crash (T-0/T-N with no data)
When there's no datalake data for the effective date, default DataSourcing returns nothing and the table never gets registered → Transformation throws `no such table`. This is how CreditScoreDelta failed on Oct 5-6.

**Dan's rules (agreed this session, not yet implemented):**
1. **Default (T-0/T-N):** no data = no output. This is the primary source. If it's not there, the job has nothing to do. Should be a graceful no-op, not a crash.
2. **`mostRecent`:** no data = empty DataFrame with schema. *(Already works.)*
3. **`mostRecentPrior`:** no data = empty DataFrame with schema. *(Already works.)*

### Parking lot (carried forward)
- CustomerAccountSummary — check V1 code (vestigial from POC2 or real gap?)
- SQL seed scripts still reference `as_of` — low priority

## What To Do Next

1. **Read the POC4 roadmap** (`memory/poc4-roadmap.md`) and confirm with Dan that this completes Step 3.
2. **Governance sign-off** — Dan wants to do this next session.
3. **Fix the T-0/T-N no-data crash** — implement Dan's rules above. This is probably Step 4 or a prerequisite for Step 5.
4. **CreditScoreDelta Parquet variants** (Overwrite + Append) — the two remaining CreditScoreDelta flavors. Low priority since the write modes are proven via BranchVisits, but they exist for completeness.

## What NOT To Read

- AAR log, governance reviews, POC3 orchestrator docs — not relevant
- `rename-review-report.md` — historical

## What To Read

1. **This file**
2. **POC4 roadmap:** `memory/poc4-roadmap.md`
3. **Program doctrine:** `AtcStrategy/POC4/ProgramDoctrine/program-doctrine.md` (for governance gates)
4. **Job configs:** `JobExecutor/Jobs/` — all four new jobs
5. **CsvFileWriter.cs** — trailer stripping logic
