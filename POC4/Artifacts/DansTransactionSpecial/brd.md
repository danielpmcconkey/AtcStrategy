# BRD: DansTransactionSpecial

**Job ID:** 373
**Job Name:** DansTransactionSpecial
**Config:** `MockEtlFramework/JobExecutor/Jobs/dans_transaction_special.json`
**First Effective Date:** 2024-10-01

---

## 1. Overview

DansTransactionSpecial produces two outputs from the same pipeline:
1. **Transaction Details** — A denormalized view of transactions enriched with customer name, account metadata, and address information (Overwrite mode)
2. **Transactions by State/Province** — An aggregated summary counting transactions and summing amounts by effective date and state/province (Append mode, cumulative)

**Business Purpose:** Provide a comprehensive transaction-level detail view with geographic enrichment, plus a geographic aggregation for regional transaction volume analysis.

---

## 2. Source Tables

### 2.1 datalake.transactions (resultName: "transactions")
- **Columns sourced:** transaction_id, account_id, txn_timestamp, txn_type, amount, description, ifw_effective_date
- **Date filter:** ifw_effective_date = __etlEffectiveDate (single day)
- **Additional filters:** None
- **Evidence:** Job config modules[0]

### 2.2 datalake.accounts (resultName: "accounts")
- **Columns sourced:** account_id, customer_id, account_type, account_status, current_balance
- **Date filter:** `mostRecent: true` — MAX(ifw_effective_date) on or before __etlEffectiveDate
- **Additional filters:** None
- **Evidence:** Job config modules[1]

### 2.3 datalake.customers (resultName: "customers")
- **Columns sourced:** id, first_name, last_name, sort_name
- **Date filter:** `mostRecent: true` — MAX(ifw_effective_date) on or before __etlEffectiveDate
- **Additional filters:** None
- **Evidence:** Job config modules[2]

### 2.4 datalake.addresses (resultName: "addresses")
- **Columns sourced:** customer_id, city, state_province, postal_code, start_date
- **Date filter:** `mostRecent: true` — MAX(ifw_effective_date) on or before __etlEffectiveDate
- **Additional filters:** None
- **Evidence:** Job config modules[3]

---

## 3. Business Rules

### BR1: Address Deduplication
Addresses are deduplicated per customer using a CTE with `ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY start_date DESC)`, keeping only the most recent address (rn = 1) per customer.
- **Confidence:** HIGH
- **Evidence:** Job config modules[4] SQL — `WITH deduped_addresses AS (SELECT ..., ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY start_date DESC) AS rn FROM addresses)` and `da.rn = 1` in JOIN

### BR2: Multi-Table Denormalization
Transactions are enriched via three LEFT JOINs:
- transactions -> accounts (on account_id)
- accounts -> customers (on customer_id = id)
- accounts -> deduped_addresses (on customer_id, rn = 1)
- **Confidence:** HIGH
- **Evidence:** Job config modules[4] SQL JOIN chain

### BR3: Transaction Details Output (Overwrite)
The first output produces a fully denormalized transaction record with account, customer, and address data. Written via CsvFileWriter with writeMode "Overwrite".
- **Confidence:** HIGH
- **Evidence:** Job config modules[5] — CsvFileWriter with source "transaction_details", writeMode "Overwrite"

### BR4: State/Province Aggregation
The second transformation aggregates the transaction_details DataFrame by `ifw_effective_date` and `state_province`, computing `COUNT(*)` as transaction_count and `SUM(amount)` as total_amount.
- **Confidence:** HIGH
- **Evidence:** Job config modules[6] SQL — `SELECT ifw_effective_date, state_province, COUNT(*) AS transaction_count, SUM(amount) AS total_amount FROM transaction_details GROUP BY ifw_effective_date, state_province ORDER BY ifw_effective_date, state_province`

### BR5: State/Province Output (Append, Cumulative)
The state/province aggregation is written with writeMode "Append", meaning each run's output includes all accumulated prior data plus the current day's aggregates.
- **Confidence:** HIGH
- **Evidence:** Job config modules[7] — CsvFileWriter with writeMode "Append"

### BR6: Output Ordering
- Transaction details: ordered by transaction_id ASC
- State/province summary: ordered by ifw_effective_date ASC, then state_province ASC
- **Confidence:** HIGH
- **Evidence:** Job config modules[4] SQL — `ORDER BY t.transaction_id`; modules[6] SQL — `ORDER BY ifw_effective_date, state_province`

### BR7: All Left Joins — Nullable Enrichment
All three enrichment joins are LEFT JOINs, meaning:
- Transactions without matching accounts: customer_id, account_type, account_status, current_balance are NULL
- Accounts without matching customers: sort_name is NULL
- Customers without matching addresses: city, state_province, postal_code are NULL
- **Confidence:** HIGH
- **Evidence:** Job config modules[4] SQL — all three JOINs use LEFT JOIN

---

## 4. Output Schema

### Output 1: Transaction Details

| Column | Type | Source | Transformation |
|--------|------|--------|----------------|
| transaction_id | int | datalake.transactions.transaction_id | Direct |
| account_id | int | datalake.transactions.account_id | Direct |
| customer_id | int | datalake.accounts.customer_id | LEFT JOIN on account_id |
| sort_name | string | datalake.customers.sort_name | LEFT JOIN on customer_id = id |
| txn_timestamp | datetime/string | datalake.transactions.txn_timestamp | Direct (ISO format) |
| txn_type | string | datalake.transactions.txn_type | Direct |
| amount | decimal | datalake.transactions.amount | Direct |
| description | string | datalake.transactions.description | Direct |
| account_type | string | datalake.accounts.account_type | LEFT JOIN on account_id |
| account_status | string | datalake.accounts.account_status | LEFT JOIN on account_id |
| current_balance | decimal | datalake.accounts.current_balance | LEFT JOIN on account_id |
| city | string | datalake.addresses.city | LEFT JOIN via deduped_addresses (most recent by start_date) |
| state_province | string | datalake.addresses.state_province | LEFT JOIN via deduped_addresses |
| postal_code | string | datalake.addresses.postal_code | LEFT JOIN via deduped_addresses |
| ifw_effective_date | datetime/string | datalake.transactions.ifw_effective_date | Direct (from transactions source) |
| etl_effective_date | string (yyyy-MM-dd) | Framework injected | CsvFileWriter adds automatically |

### Output 2: Transactions by State/Province

| Column | Type | Source | Transformation |
|--------|------|--------|----------------|
| ifw_effective_date | datetime/string | transaction_details.ifw_effective_date | GROUP BY key |
| state_province | string | transaction_details.state_province (from addresses) | GROUP BY key |
| transaction_count | int | Computed | COUNT(*) per group |
| total_amount | decimal | transaction_details.amount | SUM(amount) per group |
| etl_effective_date | string (yyyy-MM-dd) | Framework injected | Current run's date for ALL rows (including accumulated) |

---

## 5. Anti-Patterns Identified

### AP4 — Unused Columns
From `customers`: `first_name` and `last_name` are sourced but never referenced in any SQL transformation or output. Only `id` and `sort_name` are used.
- **Evidence:** Job config modules[2] sources first_name, last_name; modules[4] SQL only uses `c.sort_name` and `c.id`

### AP8 — Complex/Dead SQL (Minor)
The `deduped_addresses` CTE uses ROW_NUMBER to pick the most recent address, but the `addresses` DataSourcing already uses `mostRecent: true` which fetches only the latest snapshot. If the datalake snapshot already contains only one address per customer for the most recent date, the CTE dedup is redundant. However, if a single snapshot date can have multiple addresses per customer, the dedup is necessary.
- **Evidence:** Job config modules[3] — `mostRecent: true`; modules[4] SQL — CTE dedup logic

### AP7 — Magic Values (Minor)
The `ifw_effective_date` column is explicitly included in the transactions sourcing (modules[0]) rather than relying on the framework's automatic injection. This is unusual compared to other jobs and could cause confusion about which ifw_effective_date is in play.
- **Evidence:** Job config modules[0] columns includes "ifw_effective_date" explicitly

---

## 6. Edge Cases

1. **No transactions for a date:** Empty transaction_details, empty state_province summary. State/province append file still contains prior accumulated data.
2. **Transaction with no matching account:** customer_id and all account fields are NULL in transaction_details. State/province aggregation would group these under NULL state_province.
3. **Customer with no address:** city, state_province, postal_code are NULL. These transactions aggregate under NULL state_province in the summary.
4. **Multiple addresses per customer within snapshot:** The CTE dedup picks the one with the most recent start_date. If start_dates are tied, ROW_NUMBER is non-deterministic (no tiebreaker column).
5. **Append etl_effective_date overwrite:** In the state/province append file, all accumulated rows get the current run's etl_effective_date, losing the original effective dates. The `ifw_effective_date` column preserves the original transaction date.
6. **State/province summary includes ifw_effective_date as GROUP BY key:** Since transactions all share the same ifw_effective_date per run, the GROUP BY effectively groups by state_province only within a single day. In the accumulated file, each day's data maintains separate rows per state_province per date.
7. **Re-run with pre-existing output:** The `FindLatestPartition` method finds the LATEST date-named directory regardless of the current effective date. If output directories already exist from a prior run, re-running Oct 1 will read the latest partition's accumulated file (even Oct 7's) as "prior data", causing data duplication. Clean output directories are required for correct append behavior. This was observed during V1 output generation -- the append file's prior partitions had been populated by an earlier run, contaminating the re-run's output with doubled data.

---

## 7. Traceability Matrix

| Business Rule | Source Code Reference | Config Reference | Output Evidence |
|---------------|----------------------|------------------|-----------------|
| BR1: Address Dedup | Transformation.cs (SQL) | Config modules[4] SQL CTE | One address per customer in output |
| BR2: Denormalization | Transformation.cs (SQL) | Config modules[4] SQL JOINs | 16 columns in transaction_details output |
| BR3: Details Overwrite | CsvFileWriter.cs | Config modules[5] writeMode="Overwrite" | Single day per date partition |
| BR4: State Aggregation | Transformation.cs (SQL) | Config modules[6] SQL | transaction_count, total_amount columns |
| BR5: State Append | CsvFileWriter.cs:54-71 | Config modules[7] writeMode="Append" | Growing file across partitions |
| BR6: Ordering | Transformation.cs (SQL) | Config modules[4,6] SQL ORDER BY | Sorted output in CSVs |
| BR7: Left Joins | Transformation.cs (SQL) | Config modules[4] SQL | Nullable enrichment fields |
