# BRD Review: CreditScoreDelta

**Reviewer:** Independent Reviewer (not the analyst who wrote the BRD)
**Review Date:** 2026-03-07
**Verdict:** PASS

---

## Review Pass 1 — Output Accuracy

### Output File: credit_score_delta.csv

| Check | Result | Notes |
|-------|--------|-------|
| File path matches manifest | PASS | Manifest: `Output/curated/credit_score_delta/credit_score_delta/{date}/credit_score_delta.csv`; Actual paths match |
| Column headers match schema | PASS | Manifest: 6 columns; Actual: `customer_id,sort_name,bureau,current_score,prior_score,etl_effective_date` — exact match |
| Date partitioned | PASS | 5 date directories present (Oct 1-4, Oct 7). Oct 5-6 missing as documented (job failures). |
| Missing partitions documented | PASS | Manifest explicitly notes Oct 5-6 failures |
| Write mode = Overwrite | PASS | Each partition contains only that date's delta |
| No trailer | PASS | No trailerFormat in config |
| NULL rendering | PASS | prior_score shows as empty string for Oct 1 (first run, no prior). Matches RFC 4180 via CsvFileWriter.FormatField |

### Output Manifest Completeness
- All output files documented: PASS (single file per date partition)
- Schema complete: PASS (6 columns documented)
- Sample data provided for Oct 1 and Oct 2: PASS — matches actual files

### Data Accuracy Spot Check
- Oct 1: All prior_scores empty (NULL) — correct for first run (no prior date)
- Oct 2: `2252,Reyes Gabriel,Equifax,622,623` — score changed from 623 to 622 (decrease of 1) — correctly included
- Oct 2: All 9 rows (3 customers x 3 bureaus) present with changes — correct

---

## Review Pass 2 — Requirement Accuracy

| Rule | Evidence Valid? | Notes |
|------|----------------|-------|
| BR1: Customer Scope | PASS | `additionalFilter: "customer_id IN (2252, 2581, 2632)"` on both score sources. Output confirms only these 3 customers. |
| BR2: Today vs Prior | PASS | SQL uses `LEFT JOIN prior_scores p ON t.customer_id = p.customer_id AND t.bureau = p.bureau`. Oct 1 has NULL priors; Oct 2+ has actual priors. |
| BR3: Change Detection | PASS | `WHERE p.score IS NULL OR t.score <> p.score`. Oct 1 all NULL priors = all included. Oct 2 all changed = all included. |
| BR4: Name Enrichment | PASS | `LEFT JOIN customers c ON t.customer_id = c.id`. sort_name populated correctly (e.g., "Reyes Gabriel"). |
| BR5: Output Ordering | PASS | `ORDER BY t.customer_id, t.bureau`. Output sorted: 2252/Equifax, 2252/Experian, 2252/TransUnion, 2581/Equifax, etc. |
| BR6: Prior Date Resolution | PASS | DataSourcing.cs `mostRecentPrior` uses `MAX(ifw_effective_date) WHERE < @date`. Confirmed empty for Oct 1 (no prior data). |
| BR7: Missing Data Failure | PASS | Task queue confirms Failed status for Oct 5-6. Error message: `SQLite Error 1: 'no such table: todays_scores'`. BRD correctly traces this to Transformation.cs RegisterTable skipping empty DataFrames. |

### Anti-Pattern Review

| AP Code | Valid? | Notes |
|---------|--------|-------|
| AP1: Dead-End Sourcing (partial - customers) | PASS | customers sourced with `mostRecent: true` and NO additionalFilter. Loads all customers when only 3 IDs are needed. Valid finding. |
| AP7: Magic Values | PASS | Customer IDs 2252, 2581, 2632 hardcoded with no parameterization. Valid AP7. |
| AP10: Over-Sourcing (partial - customers) | PASS | `mostRecent: true` on full customers table to get 3 names. Valid AP10. |

### Observation on BR7
The BRD's analysis of WHY the job fails on missing data is technically sound but could benefit from one clarification: the DataSourcing module returns an empty DataFrame with columns when no data matches (not "no columns"). The issue is that Transformation.cs `RegisterTable` checks `if (!df.Columns.Any()) return` — but an empty DataFrame DOES have columns, so it DOES get registered as an empty SQLite table. The actual failure occurs because when the DataSourcing for `todays_scores` returns no rows BUT the `ifw_effective_date` has no data at all, `ResolveDateRange` returns `(effectiveDate, effectiveDate)` for the default mode (no mostRecent/mostRecentPrior flags). The query runs but returns 0 rows. The DataFrame has columns but no rows. It gets registered in SQLite. The SQL should still work with an empty table.

Wait — re-examining: the credit_scores sourcing for `todays_scores` (modules[0]) uses the DEFAULT date mode. If there are no credit_scores records for Oct 5, DataSourcing still constructs the query with `WHERE ifw_effective_date >= '2024-10-05' AND ifw_effective_date <= '2024-10-05'`. The query returns 0 rows. The DataFrame is constructed via `DataFrame(rows)` where rows is an empty list. The DataFrame's column list depends on `_columnNames` — but wait, the constructor `DataFrame(List<Dictionary<string, object?>> rows)` with empty rows produces a DataFrame with no columns (`Columns` is derived from rows).

This is the root cause: an empty `List<Dictionary<string, object?>>` produces a DataFrame with `Columns.Any() == false`, so `RegisterTable` skips it, and the SQL fails with "no such table".

**The BRD's analysis is correct.** The failure path is properly traced.

---

## Final Verdict: PASS

The BRD accurately captures all business logic, the output manifest matches actual V1 output, and anti-patterns are correctly identified. The failure mode for missing data (BR7) is a particularly valuable finding.
