# BRD: BranchVisitsByCustomerCsvAppendTrailer

**Job ID:** 371
**Job Name:** BranchVisitsByCustomerCsvAppendTrailer
**Config:** `MockEtlFramework/JobExecutor/Jobs/branch_visits_by_customer_csv_append_trailer.json`
**First Effective Date:** 2024-10-01

---

## 1. Overview

BranchVisitsByCustomerCsvAppendTrailer produces an enriched listing of branch visits joined with customer names. It uses Append write mode, meaning each new effective date's output includes all prior dates' data accumulated into a single growing file. A trailer record tracks the total row count.

**Business Purpose:** Provide a cumulative daily record of branch visits enriched with customer names for branch activity reporting and customer visit tracking.

---

## 2. Source Tables

### 2.1 datalake.branch_visits (resultName: "visits")
- **Columns sourced:** visit_id, customer_id, branch_id, visit_timestamp, visit_purpose
- **Date filter:** ifw_effective_date = __etlEffectiveDate (single day)
- **Additional filter:** `customer_id < 1500`
- **Evidence:** Job config modules[0]

### 2.2 datalake.customers (resultName: "customers")
- **Columns sourced:** id, sort_name
- **Date filter:** `mostRecent: true` — MAX(ifw_effective_date) on or before __etlEffectiveDate
- **Additional filters:** None (loads all customers)
- **Evidence:** Job config modules[1]

---

## 3. Business Rules

### BR1: Customer Scope Filter
Only visits where `customer_id < 1500` are included. This is applied at the DataSourcing level.
- **Confidence:** HIGH
- **Evidence:** Job config modules[0] — `"additionalFilter": "customer_id < 1500"`

### BR2: Customer Name Enrichment
Visit records are enriched with `sort_name` from the customers table via `LEFT JOIN customers c ON v.customer_id = c.id`.
- **Confidence:** HIGH
- **Evidence:** Job config modules[2] SQL

### BR3: Output Ordering
Results ordered by customer_id ASC, then visit_timestamp ASC.
- **Confidence:** HIGH
- **Evidence:** Job config modules[2] SQL — `ORDER BY v.customer_id, v.visit_timestamp`

### BR4: Append Mode — Cumulative Output
The CsvFileWriter uses `writeMode: "Append"`. The framework's append logic:
1. Finds the most recent prior date partition directory
2. Reads the prior output file (stripping the trailer if present)
3. Drops the `etl_effective_date` column from prior data
4. Unions prior data with current day's data
5. Re-adds `etl_effective_date` (set to current effective date for ALL rows)
6. Writes the combined result to a new date partition
- **Confidence:** HIGH
- **Evidence:** CsvFileWriter.cs lines 54-71 — append mode logic; observed output shows cumulative growth across date partitions

### BR5: Trailer Record
A trailer line is appended with format `TRAILER|{row_count}|{date}`. The row_count is the total rows in the DataFrame (including accumulated prior data).
- **Confidence:** HIGH
- **Evidence:** Job config modules[3] — `"trailerFormat": "TRAILER|{row_count}|{date}"`; CsvFileWriter.cs lines 96-103; observed: `TRAILER|395|2024-10-01`

### BR6: All Columns Pass Through
The SQL SELECT includes all sourced visit columns plus the joined sort_name. No transformations are applied to any values.
- **Confidence:** HIGH
- **Evidence:** Job config modules[2] SQL — `SELECT v.visit_id, v.customer_id, c.sort_name, v.branch_id, v.visit_timestamp, v.visit_purpose`

---

## 4. Output Schema

| Column | Type | Source | Transformation |
|--------|------|--------|----------------|
| visit_id | int | datalake.branch_visits.visit_id | Direct pass-through |
| customer_id | int | datalake.branch_visits.customer_id | Direct pass-through; filtered to < 1500 at sourcing |
| sort_name | string | datalake.customers.sort_name | LEFT JOIN on customer_id = id |
| branch_id | int | datalake.branch_visits.branch_id | Direct pass-through |
| visit_timestamp | datetime/string | datalake.branch_visits.visit_timestamp | Direct pass-through (ISO format in output) |
| visit_purpose | string | datalake.branch_visits.visit_purpose | Direct pass-through |
| etl_effective_date | string (yyyy-MM-dd) | Framework injected | Set to CURRENT run's effective date for ALL rows (including accumulated prior data) |

**Trailer row:** `TRAILER|{total_row_count}|{effective_date}`

---

## 5. Anti-Patterns Identified

### AP1 — Dead-End Sourcing (Partial)
The `customers` table is sourced with `mostRecent: true` and no `additionalFilter`. This loads ALL customers when only `customer_id < 1500` are relevant (matching the branch_visits filter). The customer sourcing should include a matching filter.
- **Evidence:** Job config modules[1] — no additionalFilter; modules[0] has `"customer_id < 1500"`

### AP7 — Magic Values
The customer filter `customer_id < 1500` is a hardcoded threshold with no documentation explaining why 1500 is the cutoff.
- **Evidence:** Job config modules[0] additionalFilter

---

## 6. Edge Cases

1. **No visits for a date:** The current day contributes zero rows. Output contains only accumulated prior data (if any) with the new etl_effective_date.
2. **Customer not in customers table:** sort_name will be NULL (LEFT JOIN).
3. **First run (no prior partition):** Output contains only current day's data. `DatePartitionHelper.FindLatestPartition` returns null, skipping prior data load.
4. **etl_effective_date overwrite on append:** When prior data is accumulated, the framework drops the old `etl_effective_date` and re-adds it with the current effective date. This means ALL rows in the Oct 7 file show `etl_effective_date=2024-10-07`, even rows that originated from Oct 1. The original effective date is lost.
5. **Trailer stripping on append:** When reading prior data, the framework strips the last line if a trailer format is configured (CsvFileWriter.cs line 63-65: `lines = lines[..^1]`). If the prior file has no trailer (corruption), the last data row would be silently dropped.
6. **Re-run with pre-existing output:** The `FindLatestPartition` method finds the LATEST date-named directory regardless of the current effective date. If output directories already exist from a prior run (e.g., partitions through Oct 7 exist), re-running Oct 1 will read Oct 7's accumulated file as "prior data" and union it with Oct 1's fresh data, causing data duplication. Clean output directories are required for correct append behavior.

---

## 7. Traceability Matrix

| Business Rule | Source Code Reference | Config Reference | Output Evidence |
|---------------|----------------------|------------------|-----------------|
| BR1: Customer Filter | DataSourcing.cs:185-186 | Config modules[0] additionalFilter | Only customer_ids < 1500 in output |
| BR2: Name Enrichment | Transformation.cs (SQL) | Config modules[2] SQL | sort_name column populated |
| BR3: Output Ordering | Transformation.cs (SQL) | Config modules[2] SQL ORDER BY | Rows sorted by customer_id, visit_timestamp |
| BR4: Append Mode | CsvFileWriter.cs:54-71 | Config modules[3] writeMode="Append" | Oct 1 partition has ~395 rows, growing across dates |
| BR5: Trailer | CsvFileWriter.cs:96-103 | Config modules[3] trailerFormat | TRAILER\|395\|2024-10-01 observed |
| BR6: Column Pass-Through | Transformation.cs (SQL) | Config modules[2] SQL SELECT | All visit columns present in output |
