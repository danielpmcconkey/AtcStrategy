# Output Manifest: PeakTransactionTimes

**Job ID:** 165
**Job Name:** PeakTransactionTimes

---

## Output Files

### 1. peak_transaction_times.csv
- **Path:** `Output/curated/peak_transaction_times.csv`
- **Writer:** External module (PeakTransactionTimesWriter) — bypasses framework CsvFileWriter
- **Write Mode:** Overwrite (StreamWriter append:false)
- **Date Partitioned:** No (flat file, overwritten each run)
- **Header:** Yes
- **Line Ending:** LF (`\n`)
- **Trailer:** Yes — format: `TRAILER|{input_row_count}|{effective_date}`
- **Encoding:** UTF-8 (default StreamWriter)

#### Schema

| Column | Type | Source | Transformation |
|--------|------|--------|----------------|
| hour_of_day | int | datalake.transactions.txn_timestamp | Extract hour component (0-23) via DateTime.Hour |
| txn_count | int | Computed | COUNT of transactions per hour bucket |
| total_amount | decimal (2dp) | datalake.transactions.amount | SUM per hour bucket, Math.Round(x, 2) |
| ifw_effective_date | string (yyyy-MM-dd) | __etlEffectiveDate shared state | DateOnly.ToString("yyyy-MM-dd") |

#### Trailer Row
| Field | Position | Source |
|-------|----------|--------|
| Literal "TRAILER" | 1 | Hardcoded |
| Record count | 2 | INPUT transaction count (pre-aggregation), NOT output row count |
| Date | 3 | __etlEffectiveDate formatted as yyyy-MM-dd |

#### Notes
- The trailer count is deliberately (or erroneously) the INPUT row count, not the output row count. In observed output, TRAILER|4284 but only 19 data rows.
- No `etl_effective_date` column is injected because the framework CsvFileWriter is bypassed.
- Only the last run's data survives — file is overwritten, not date-partitioned.
