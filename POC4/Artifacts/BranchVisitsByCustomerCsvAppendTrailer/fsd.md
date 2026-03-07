# FSD: BranchVisitsByCustomerCsvAppendTrailer

**Job ID:** 371
**Job Name:** BranchVisitsByCustomerCsvAppendTrailer
**BRD Reference:** `POC4/Artifacts/BranchVisitsByCustomerCsvAppendTrailer/brd.md`
**Config Reference:** `MockEtlFramework/JobExecutor/Jobs/branch_visits_by_customer_csv_append_trailer.json`

---

## 1. Functional Requirements

### FR1: Customer Scope Filter
**Traces to:** BRD BR1
Only branch visits where `customer_id < 1500` are included. This is enforced at the DataSourcing level via `additionalFilter`.

### FR2: Customer Name Enrichment
**Traces to:** BRD BR2
Visit records are enriched with `sort_name` from the customers table via `LEFT JOIN customers c ON v.customer_id = c.id`. When no matching customer exists, sort_name is NULL.

### FR3: Output Ordering
**Traces to:** BRD BR3
Results ordered by `customer_id ASC`, then `visit_timestamp ASC`.

### FR4: Append Mode — Cumulative Output
**Traces to:** BRD BR4
The CsvFileWriter uses `writeMode: "Append"`. The framework's append logic:
1. Finds the most recent prior date partition directory via `DatePartitionHelper.FindLatestPartition`
2. Reads the prior output CSV file, stripping the trailer line if `trailerFormat` is configured
3. Drops the `etl_effective_date` column from prior data (it will be re-injected)
4. Unions prior data rows with current day's new data rows
5. Re-adds `etl_effective_date` set to the CURRENT effective date for ALL rows
6. Writes the combined result to a new date partition directory

This means each date partition is a superset of all prior partitions. The `etl_effective_date` column reflects the current run date, not the original transaction date.

### FR5: Trailer Record
**Traces to:** BRD BR5
A trailer line is appended: `TRAILER|{row_count}|{date}` where:
- `row_count` = total rows in the DataFrame (including accumulated prior data), NOT just new rows
- `date` = current effective date in `yyyy-MM-dd` format

The framework's CsvFileWriter handles trailer generation via the `trailerFormat` config. `{row_count}` maps to `DataFrame.Count` and `{date}` maps to the effective date.

### FR6: All Columns Pass Through
**Traces to:** BRD BR6
The SQL SELECT includes all sourced visit columns plus joined sort_name. No transformations are applied to values — all are direct pass-through.

### FR7: Empty Day — Prior Data Only
**Traces to:** BRD Edge Case 1
When no visits exist for the effective date, the current day contributes zero new rows. Output contains only accumulated prior data (if any) with the updated `etl_effective_date`. If this is the first day AND no visits exist, output is header-only with TRAILER|0|{date}.

### FR8: First Run — No Prior Partition
**Traces to:** BRD Edge Case 3
On the first effective date, `FindLatestPartition` returns null. No prior data is loaded. Output contains only current day's data.

### FR9: Trailer Stripping on Prior Data Load
**Traces to:** BRD Edge Case 5
When reading prior data for append, the framework strips the last line if a trailer format is configured. If the prior file has no trailer (corruption), the last data row would be silently dropped. This is existing framework behavior that V4 inherits.

---

## 2. Anti-Pattern Analysis

### AP1 — Dead-End Sourcing, Partial (V1)
**Identified in BRD:** Customers table sourced with no `additionalFilter`, loading ALL customers when only `customer_id < 1500` are relevant.
**V4 Avoidance:** Add `"additionalFilter": "id < 1500"` to the customers DataSourcing module to match the visits filter scope.
**Fidelity Impact:** None — the LEFT JOIN only matches customer_ids present in the filtered visits. Sourcing fewer customers does not change the output.

### AP7 — Magic Values (V1)
**Identified in BRD:** `customer_id < 1500` is a hardcoded threshold.
**V4 Avoidance:** This is the business rule as defined. V4 preserves the filter but documents it explicitly in the FSD and config. Parameterization would require framework-level variable support, out of scope for POC4.

---

## 3. Output DataFrames

### Output 1: branch_visits_by_customer.csv

| Column | Type | Source | Transformation | BRD Reference |
|--------|------|--------|----------------|---------------|
| visit_id | int | branch_visits.visit_id | Direct pass-through | BR6 |
| customer_id | int | branch_visits.customer_id | Direct; filtered to < 1500 | BR1, BR6 |
| sort_name | string | customers.sort_name | LEFT JOIN on customer_id = id | BR2 |
| branch_id | int | branch_visits.branch_id | Direct pass-through | BR6 |
| visit_timestamp | string (ISO 8601) | branch_visits.visit_timestamp | Direct pass-through | BR6 |
| visit_purpose | string | branch_visits.visit_purpose | Direct pass-through | BR6 |
| etl_effective_date | string (yyyy-MM-dd) | Framework injected | Current run's date for ALL rows | BR4 |

**Trailer:** `TRAILER|{total_row_count}|{effective_date}` (BR5)

---

## 4. Module Chain Design

### Preferred: DataSourcing -> DataSourcing -> Transformation -> CsvFileWriter

This is the EXISTING V1 module chain. BranchVisitsByCustomerCsvAppendTrailer already uses the preferred pattern. V4 changes are config-level anti-pattern fixes only.

1. **DataSourcing** — Source `branch_visits` as `visits`. Columns: `visit_id`, `customer_id`, `branch_id`, `visit_timestamp`, `visit_purpose`. Single-day filter. additionalFilter: `customer_id < 1500`.
2. **DataSourcing** — Source `customers` as `customers`. Columns: `id`, `sort_name`. `mostRecent: true`. **V4 addition:** `additionalFilter: "id < 1500"`.
3. **Transformation** — SQL (unchanged from V1):
   ```sql
   SELECT v.visit_id, v.customer_id, c.sort_name, v.branch_id, v.visit_timestamp, v.visit_purpose
   FROM visits v
   LEFT JOIN customers c ON v.customer_id = c.id
   ORDER BY v.customer_id, v.visit_timestamp
   ```
   Result name: `branch_visits_by_customer`
4. **CsvFileWriter** — Write `branch_visits_by_customer` with:
   - writeMode: "Append"
   - trailerFormat: "TRAILER|{row_count}|{date}"
   - Date-partitioned output

**No External Module.** V1 already uses the correct pattern. V4 preserves it.

---

## 5. Open Questions

1. **Append re-run safety:** If output directories from a prior run exist, `FindLatestPartition` finds the latest partition regardless of the current effective date. Re-running Oct 1 when Oct 7 output exists would read Oct 7's accumulated file as "prior data", causing data duplication. V4 inherits this framework behavior. Clean output directories are a prerequisite for correct append runs.

2. **visit_timestamp format:** V1 SQL passes through visit_timestamp as-is. The framework's DataSourcing returns it as a DateTime object, and the CsvFileWriter serializes it. Observed V1 output shows ISO 8601 format (`2024-10-01T10:42:29`). V4 should produce the same format. Verify during testing.

3. **etl_effective_date overwrite semantics:** The framework drops the old etl_effective_date during append and re-adds with the current date. This means Oct 7's file shows etl_effective_date=2024-10-07 for ALL rows, including rows from Oct 1. This is existing behavior, not a bug. V4 preserves it.
