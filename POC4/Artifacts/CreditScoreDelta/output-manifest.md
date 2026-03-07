# Output Manifest: CreditScoreDelta

**Job ID:** 369
**Job Name:** CreditScoreDelta

---

## Output Files

### 1. credit_score_delta.csv
- **Path:** `Output/curated/credit_score_delta/credit_score_delta/{etl_effective_date}/credit_score_delta.csv`
- **Writer:** Framework CsvFileWriter
- **Write Mode:** Overwrite
- **Date Partitioned:** Yes (one directory per effective date)
- **Header:** Yes
- **Line Ending:** LF
- **Trailer:** None
- **Encoding:** UTF-8 (no BOM)

#### Schema

| Column | Type | Source | Transformation |
|--------|------|--------|----------------|
| customer_id | int | datalake.credit_scores.customer_id | From todays_scores; filtered to IN (2252, 2581, 2632) |
| sort_name | string | datalake.customers.sort_name | LEFT JOIN on customer_id = id via mostRecent snapshot |
| bureau | string | datalake.credit_scores.bureau | From todays_scores (e.g., "Equifax", "Experian", "TransUnion") |
| current_score | int/numeric | datalake.credit_scores.score | Today's score (aliased from t.score) |
| prior_score | int/numeric/null | datalake.credit_scores.score | Most recent prior date's score (aliased from p.score); NULL if no prior |
| etl_effective_date | string (yyyy-MM-dd) | Framework injected | CsvFileWriter adds automatically |

#### Sample Output (2024-10-01 — first run, no prior scores)
```
customer_id,sort_name,bureau,current_score,prior_score,etl_effective_date
2252,Reyes Gabriel,Equifax,623,,2024-10-01
2252,Reyes Gabriel,Experian,654,,2024-10-01
2252,Reyes Gabriel,TransUnion,655,,2024-10-01
2581,Wright Mason,Equifax,609,,2024-10-01
2581,Wright Mason,Experian,631,,2024-10-01
2581,Wright Mason,TransUnion,642,,2024-10-01
2632,Bailey Jack,Equifax,590,,2024-10-01
2632,Bailey Jack,Experian,596,,2024-10-01
2632,Bailey Jack,TransUnion,585,,2024-10-01
```

#### Sample Output (2024-10-02 — with prior scores)
```
customer_id,sort_name,bureau,current_score,prior_score,etl_effective_date
2252,Reyes Gabriel,Equifax,622,623,2024-10-02
2252,Reyes Gabriel,Experian,656,654,2024-10-02
2252,Reyes Gabriel,TransUnion,657,655,2024-10-02
2581,Wright Mason,Equifax,608,609,2024-10-02
...
```

#### Missing Date Partitions
- **2024-10-05:** No output (job failed — no credit_scores data for this date)
- **2024-10-06:** No output (job failed — no credit_scores data for this date)

#### Notes
- NULL prior_score renders as empty string in CSV (RFC 4180 standard via CsvFileWriter.FormatField)
- Job fails hard when no source data exists for the effective date rather than producing empty output
- Only 3 customers monitored — hardcoded filter
