# Output Manifest: BranchVisitsByCustomerCsvAppendTrailer

**Job ID:** 371
**Job Name:** BranchVisitsByCustomerCsvAppendTrailer

---

## Output Files

### 1. branch_visits_by_customer.csv
- **Path:** `Output/curated/branch_visits_by_customer/branch_visits_by_customer/{etl_effective_date}/branch_visits_by_customer.csv`
- **Writer:** Framework CsvFileWriter
- **Write Mode:** Append (cumulative — each partition includes all prior data)
- **Date Partitioned:** Yes (one directory per effective date, but content is cumulative)
- **Header:** Yes
- **Line Ending:** LF
- **Trailer:** Yes — format: `TRAILER|{row_count}|{date}`
- **Encoding:** UTF-8 (no BOM)

#### Schema

| Column | Type | Source | Transformation |
|--------|------|--------|----------------|
| visit_id | int | datalake.branch_visits.visit_id | Direct pass-through |
| customer_id | int | datalake.branch_visits.customer_id | Filtered to < 1500 at DataSourcing |
| sort_name | string | datalake.customers.sort_name | LEFT JOIN on v.customer_id = c.id |
| branch_id | int | datalake.branch_visits.branch_id | Direct pass-through |
| visit_timestamp | string (ISO 8601) | datalake.branch_visits.visit_timestamp | Pass-through, formatted as yyyy-MM-ddTHH:mm:ss |
| visit_purpose | string | datalake.branch_visits.visit_purpose | Direct pass-through |
| etl_effective_date | string (yyyy-MM-dd) | Framework injected | Current run's effective date for ALL rows |

#### Trailer Row
| Field | Position | Source |
|-------|----------|--------|
| Literal "TRAILER" | 1 | Hardcoded in trailerFormat |
| Row count | 2 | Total DataFrame row count (including accumulated prior data) |
| Date | 3 | etl_effective_date (yyyy-MM-dd) |

#### Sample Output (2024-10-01, first partition)
```
visit_id,customer_id,sort_name,branch_id,visit_timestamp,visit_purpose,etl_effective_date
1,1006,Garcia Ava,6,2024-10-01T10:42:29,Withdrawal,2024-10-01
2,1030,Hall Ava,7,2024-10-01T11:46:27,Deposit,2024-10-01
...
TRAILER|395|2024-10-01
```

#### Accumulation Behavior
Each date partition is a superset of all prior partitions:
- 2024-10-01: ~395 rows (day 1 visits only)
- 2024-10-02: ~395 rows (day 1 + day 2 visits)
- ...
- 2024-10-07: cumulative total of all 7 days

Note: The `etl_effective_date` column is overwritten to the CURRENT effective date for ALL rows during accumulation (prior data's original effective date is lost).

#### Notes
- Trailer row_count reflects total accumulated rows, not just new rows for the day
- Cumulative append means the Oct 7 file is the authoritative "full history" file
- sort_name may be NULL for customers not in the customers table (LEFT JOIN)
