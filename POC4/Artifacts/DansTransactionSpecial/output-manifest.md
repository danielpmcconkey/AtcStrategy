# Output Manifest: DansTransactionSpecial

**Job ID:** 373
**Job Name:** DansTransactionSpecial

---

## Output Files

### 1. dans_transaction_details.csv
- **Path:** `Output/curated/dans_transaction_special/dans_transaction_details/{etl_effective_date}/dans_transaction_details.csv`
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
| transaction_id | int | datalake.transactions.transaction_id | Direct |
| account_id | int | datalake.transactions.account_id | Direct |
| customer_id | int/null | datalake.accounts.customer_id | LEFT JOIN on t.account_id = a.account_id |
| sort_name | string/null | datalake.customers.sort_name | LEFT JOIN on a.customer_id = c.id |
| txn_timestamp | string (ISO 8601) | datalake.transactions.txn_timestamp | Pass-through |
| txn_type | string | datalake.transactions.txn_type | Direct (e.g., "Credit", "Debit") |
| amount | decimal | datalake.transactions.amount | Direct |
| description | string | datalake.transactions.description | Direct |
| account_type | string/null | datalake.accounts.account_type | LEFT JOIN on account_id |
| account_status | string/null | datalake.accounts.account_status | LEFT JOIN on account_id |
| current_balance | decimal/null | datalake.accounts.current_balance | LEFT JOIN on account_id |
| city | string/null | datalake.addresses.city | LEFT JOIN via deduped_addresses (ROW_NUMBER by start_date DESC, rn=1) |
| state_province | string/null | datalake.addresses.state_province | LEFT JOIN via deduped_addresses |
| postal_code | string/null | datalake.addresses.postal_code | LEFT JOIN via deduped_addresses |
| ifw_effective_date | string (ISO 8601) | datalake.transactions.ifw_effective_date | Direct from transactions source (explicitly sourced column) |
| etl_effective_date | string (yyyy-MM-dd) | Framework injected | CsvFileWriter adds automatically |

#### Sample Output (2024-10-07)
```
transaction_id,account_id,customer_id,sort_name,txn_timestamp,txn_type,amount,description,account_type,account_status,current_balance,city,state_province,postal_code,ifw_effective_date,etl_effective_date
4008,3004,1004,Reynolds Sophia,2024-10-07T12:15:00,Credit,600,Deposit,Checking,Active,1570.11,San Francisco,CA,94105,2024-10-07T00:00:00,2024-10-07
```

---

### 2. dans_transactions_by_state_province.csv
- **Path:** `Output/curated/dans_transaction_special/dans_transactions_by_state_province/{etl_effective_date}/dans_transactions_by_state_province.csv`
- **Writer:** Framework CsvFileWriter
- **Write Mode:** Append (cumulative — each partition includes all prior data)
- **Date Partitioned:** Yes (one directory per effective date, but content is cumulative)
- **Header:** Yes
- **Line Ending:** LF
- **Trailer:** None
- **Encoding:** UTF-8 (no BOM)

#### Schema

| Column | Type | Source | Transformation |
|--------|------|--------|----------------|
| ifw_effective_date | string (ISO 8601) | transaction_details.ifw_effective_date | GROUP BY key |
| state_province | string/null | transaction_details.state_province | GROUP BY key (from addresses via denormalization) |
| transaction_count | int | Computed | COUNT(*) per (ifw_effective_date, state_province) |
| total_amount | decimal | transaction_details.amount | SUM(amount) per group |
| etl_effective_date | string (yyyy-MM-dd) | Framework injected | Current run's date for ALL rows (including accumulated) |

#### Sample Output (2024-10-07, accumulated file)
```
ifw_effective_date,state_province,transaction_count,total_amount,etl_effective_date
2024-10-02T00:00:00,AB,207,175845,2024-10-07
2024-10-02T00:00:00,AZ,77,63888.75,2024-10-07
2024-10-02T00:00:00,BC,234,229437,2024-10-07
...
2024-10-07T00:00:00,TX,85,70444,2024-10-07
2024-10-07T00:00:00,WA,125,116374,2024-10-07
2024-10-07T00:00:00,YT,122,110138,2024-10-07
```

#### Accumulation Behavior
Each date partition includes all prior dates' state/province summaries:
- 2024-10-01: ~31 rows (one day's state/province breakdown)
- 2024-10-07: ~217 rows (7 days of accumulated state/province data)

The `etl_effective_date` is overwritten to the current run's date for ALL rows. The `ifw_effective_date` column preserves the original transaction date, allowing distinction between days.

#### Notes
- No trailer on this output (no trailerFormat configured)
- The accumulated file preserves per-day granularity via the ifw_effective_date GROUP BY key
- The Oct 1 partition starts with data labeled as `2024-10-02T00:00:00` in ifw_effective_date because the transactions DataFrame gets ifw_effective_date from the framework's DataSourcing which returns it as a DateTime object, and the SQL GROUP BY preserves this format
