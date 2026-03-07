# BRD: DailyBalanceMovement

**Job ID:** 166
**Job Name:** DailyBalanceMovement
**Config:** `MockEtlFramework/JobExecutor/Jobs/daily_balance_movement.json`
**First Effective Date:** 2024-10-01

---

## 1. Overview

DailyBalanceMovement calculates daily debit totals, credit totals, and net movement per account. For each effective date, it aggregates all transactions by account, joins to the accounts table to get customer_id, and produces a per-account summary of financial movement for that day.

**Business Purpose:** Track daily cash flow direction and magnitude per account for balance monitoring and trend analysis.

---

## 2. Source Tables

### 2.1 datalake.transactions (resultName: "transactions")
- **Columns sourced:** transaction_id, account_id, txn_type, amount
- **Date filter:** ifw_effective_date = __etlEffectiveDate (single day)
- **Additional filters:** None
- **Evidence:** Job config modules[0]

### 2.2 datalake.accounts (resultName: "accounts")
- **Columns sourced:** account_id, customer_id
- **Date filter:** ifw_effective_date = __etlEffectiveDate (single day)
- **Additional filters:** None
- **Evidence:** Job config modules[1]

---

## 3. Business Rules

### BR1: Account-Level Aggregation
Transactions are grouped by `account_id`. For each account, debit and credit totals are computed separately based on `txn_type`.
- **Confidence:** HIGH
- **Evidence:** DailyBalanceMovementCalculator.cs lines 34-49 — foreach loop groups by account_id, checks txn_type == "Debit" or "Credit"

### BR2: Debit/Credit Classification
Only `txn_type == "Debit"` increments `debitTotal`. Only `txn_type == "Credit"` increments `creditTotal`. Any other txn_type value is silently ignored (neither debit nor credit total is affected).
- **Confidence:** HIGH
- **Evidence:** DailyBalanceMovementCalculator.cs lines 45-48 — explicit string comparison against "Debit" and "Credit" only

### BR3: Net Movement Calculation
`net_movement = creditTotal - debitTotal` (credits are positive movement, debits are negative).
- **Confidence:** HIGH
- **Evidence:** DailyBalanceMovementCalculator.cs line 59

### BR4: Double Arithmetic (Precision Issue)
All monetary calculations use `double` instead of `decimal`. This introduces floating-point epsilon errors that accumulate across many transactions.
- **Confidence:** HIGH
- **Evidence:** DailyBalanceMovementCalculator.cs line 34 — `Dictionary<int, (double debitTotal, double creditTotal, ...)>`, line 39 — `Convert.ToDouble(row["amount"])`

### BR5: Customer ID Lookup
The External module builds a lookup dictionary from accounts (account_id -> customer_id) and joins it to the transaction aggregates. If an account_id is not found in the lookup, customer_id defaults to 0.
- **Confidence:** HIGH
- **Evidence:** DailyBalanceMovementCalculator.cs lines 25-31 — accountToCustomer dictionary; line 56 — `GetValueOrDefault(accountId, 0)`

### BR6: Effective Date from First Transaction
The `ifw_effective_date` column in the output is taken from `row["ifw_effective_date"]` of the first transaction encountered for each account (stored as `asOf` in the tuple).
- **Confidence:** HIGH
- **Evidence:** DailyBalanceMovementCalculator.cs line 42 — `row["ifw_effective_date"]` captured on first encounter; line 66 — `["ifw_effective_date"] = asOf`

### BR7: Output Written via Framework CsvFileWriter
Unlike PeakTransactionTimes, this job sets `sharedState["output"]` to the DataFrame and uses the framework's CsvFileWriter module with writeMode "Overwrite".
- **Confidence:** HIGH
- **Evidence:** Job config modules[3] — CsvFileWriter with source "output", writeMode "Overwrite"; DailyBalanceMovementCalculator.cs line 72

### BR8: Empty Input Handling
If transactions or accounts are null or empty, returns an empty DataFrame.
- **Confidence:** HIGH
- **Evidence:** DailyBalanceMovementCalculator.cs lines 18-22

---

## 4. Output Schema

| Column | Type | Source | Transformation |
|--------|------|--------|----------------|
| account_id | int | datalake.transactions.account_id | Group key |
| customer_id | int | datalake.accounts.customer_id | Lookup via account_id; default 0 if not found |
| debit_total | double | datalake.transactions.amount | SUM where txn_type = "Debit" |
| credit_total | double | datalake.transactions.amount | SUM where txn_type = "Credit" |
| net_movement | double | Computed | credit_total - debit_total |
| ifw_effective_date | object | datalake.transactions.ifw_effective_date | First transaction's ifw_effective_date for the account |
| etl_effective_date | string | Framework injected | CsvFileWriter adds this automatically (yyyy-MM-dd) |

---

## 5. Anti-Patterns Identified

### AP3 — Unnecessary External Module
The entire aggregation logic could be expressed as a SQL Transformation:
```sql
SELECT t.account_id, a.customer_id,
       SUM(CASE WHEN t.txn_type = 'Debit' THEN t.amount ELSE 0 END) AS debit_total,
       SUM(CASE WHEN t.txn_type = 'Credit' THEN t.amount ELSE 0 END) AS credit_total,
       SUM(CASE WHEN t.txn_type = 'Credit' THEN t.amount ELSE 0 END) -
       SUM(CASE WHEN t.txn_type = 'Debit' THEN t.amount ELSE 0 END) AS net_movement
FROM transactions t
LEFT JOIN accounts a ON t.account_id = a.account_id
GROUP BY t.account_id, a.customer_id
```
No C# logic is needed that SQL cannot handle.
- **Evidence:** DailyBalanceMovementCalculator.cs — entire Execute method is a foreach aggregation with dictionary lookup

### AP4 — Unused Columns
`transaction_id` is sourced from datalake.transactions but never referenced in the External module. It is not in the output schema and serves no purpose.
- **Evidence:** Job config modules[0] lists "transaction_id"; DailyBalanceMovementCalculator.cs accesses only account_id, txn_type, amount, ifw_effective_date

### AP5 — Asymmetric Null/Default Handling
When an account_id from transactions is not found in the accounts lookup, customer_id defaults to 0 (an arbitrary magic value). There's no documented reason for choosing 0 vs NULL vs -1. Meanwhile, missing txn_type values result in the transaction being silently dropped from both debit and credit totals.
- **Evidence:** DailyBalanceMovementCalculator.cs line 56 — `GetValueOrDefault(accountId, 0)`; lines 45-48 — unmatched txn_type silently ignored

### AP6 — Row-by-Row Iteration
The External module iterates over every transaction row individually, maintaining a dictionary of running totals. This is a textbook GROUP BY operation.
- **Evidence:** DailyBalanceMovementCalculator.cs lines 34-49 — foreach loop with manual dictionary accumulation

### AP7 — Magic Values
The default customer_id of 0 for unmatched accounts is a hardcoded magic value with no documentation or parameterization.
- **Evidence:** DailyBalanceMovementCalculator.cs line 56

---

## 6. Edge Cases

1. **No transactions for a date:** Returns empty DataFrame; CsvFileWriter produces header-only CSV
2. **No accounts for a date:** Returns empty DataFrame (accounts null/empty check at line 18)
3. **Account with only non-Debit/non-Credit transactions:** Account still appears in output with debit_total=0, credit_total=0, net_movement=0 (because the account_id still gets added to the stats dictionary with initial values 0,0)
4. **Floating-point precision:** Using double arithmetic means sums like `142.5` are exact but complex sums may exhibit epsilon errors (e.g., observed output shows `357.5` which happens to be exact, but this is not guaranteed)
5. **Multiple transactions per account:** All are aggregated into single output row per account
6. **Unmatched account_id:** Gets customer_id = 0 in output

---

## 7. Traceability Matrix

| Business Rule | Source Code Reference | Config Reference | Output Evidence |
|---------------|----------------------|------------------|-----------------|
| BR1: Account Aggregation | DailyBalanceMovementCalculator.cs:34-49 | N/A (logic in C#) | One row per account_id in output |
| BR2: Debit/Credit Classification | DailyBalanceMovementCalculator.cs:45-48 | N/A | Separate debit_total and credit_total columns |
| BR3: Net Movement | DailyBalanceMovementCalculator.cs:59 | N/A | net_movement = credit_total - debit_total verified in output |
| BR4: Double Arithmetic | DailyBalanceMovementCalculator.cs:34,39 | N/A | Output values show double formatting (e.g., 357.5 not 357.50) |
| BR5: Customer ID Lookup | DailyBalanceMovementCalculator.cs:25-31,56 | N/A | customer_id column populated in output |
| BR6: Date from First Txn | DailyBalanceMovementCalculator.cs:42,66 | N/A | ifw_effective_date in output matches effective date |
| BR7: Framework Writer | DailyBalanceMovementCalculator.cs:72 | Config modules[3] | Files at Output/curated/daily_balance_movement/ with etl_effective_date |
| BR8: Empty Input | DailyBalanceMovementCalculator.cs:18-22 | N/A | Empty DataFrame returned |
