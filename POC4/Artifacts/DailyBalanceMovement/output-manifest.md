# Output Manifest: DailyBalanceMovement

**Job ID:** 166
**Job Name:** DailyBalanceMovement

---

## Output Files

### 1. daily_balance_movement.csv
- **Path:** `Output/curated/daily_balance_movement/daily_balance_movement/{etl_effective_date}/daily_balance_movement.csv`
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
| account_id | int | datalake.transactions.account_id | Group key from External module aggregation |
| customer_id | int | datalake.accounts.customer_id | Joined via account_id lookup; default 0 if unmatched |
| debit_total | double | datalake.transactions.amount | SUM of amount WHERE txn_type = "Debit" |
| credit_total | double | datalake.transactions.amount | SUM of amount WHERE txn_type = "Credit" |
| net_movement | double | Computed | credit_total - debit_total |
| ifw_effective_date | object | datalake.transactions.ifw_effective_date | From first transaction for each account |
| etl_effective_date | string (yyyy-MM-dd) | Framework injected | CsvFileWriter.cs line 75 — `df.WithColumn("etl_effective_date", _ => dateStr)` |

#### Sample Output (2024-10-01)
```
account_id,customer_id,debit_total,credit_total,net_movement,ifw_effective_date,etl_effective_date
3001,1001,142.5,500,357.5,10/01/2024,2024-10-01
3003,1003,220,0,-220,10/01/2024,2024-10-01
3006,1006,25.5,0,-25.5,10/01/2024,2024-10-01
3010,1010,90.25,1850,1759.75,10/01/2024,2024-10-01
```

#### Notes
- `ifw_effective_date` is formatted as `MM/DD/YYYY` (not ISO format) because it comes from the DateOnly serialization through the External module, which stores it as an object (DateOnly.ToString() default format). This differs from the `etl_effective_date` column which uses ISO format.
- Double arithmetic means monetary values may have precision artifacts at high volumes.
