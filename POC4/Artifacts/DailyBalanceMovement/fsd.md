# FSD: DailyBalanceMovement

**Job ID:** 166
**Job Name:** DailyBalanceMovement
**BRD Reference:** `POC4/Artifacts/DailyBalanceMovement/brd.md`
**Config Reference:** `MockEtlFramework/JobExecutor/Jobs/daily_balance_movement.json`

---

## 1. Functional Requirements

### FR1: Account-Level Aggregation
**Traces to:** BRD BR1
Group all transactions by `account_id`. For each account, compute separate debit and credit totals based on `txn_type`.

### FR2: Debit/Credit Classification
**Traces to:** BRD BR2
- `txn_type == "Debit"` -> add amount to debit_total
- `txn_type == "Credit"` -> add amount to credit_total
- Any other txn_type value is silently ignored (does not contribute to either total)

The string comparison is case-sensitive and exact-match only.

### FR3: Net Movement Calculation
**Traces to:** BRD BR3
`net_movement = credit_total - debit_total` (credits are positive movement).

### FR4: Double Arithmetic Preservation
**Traces to:** BRD BR4
V1 uses `double` arithmetic (IEEE 754 floating point). V4 must produce identical numeric output. In the SQL Transformation, SQLite uses 64-bit IEEE 754 floats for REAL values, which is functionally equivalent to C# `double`. The SQL aggregation `SUM(amount)` and arithmetic operations should produce identical results.

**Fidelity Risk:** If accumulation order differs between V1 foreach (dictionary insertion order) and SQL GROUP BY (implementation-defined), floating-point accumulation artifacts could theoretically differ. In practice, the amounts in the test data are exact binary fractions (e.g., 142.5, 357.5) so this risk is minimal. Proofmark comparison will detect any actual divergence.

### FR5: Customer ID Lookup
**Traces to:** BRD BR5
Join accounts to get `customer_id` for each `account_id`. When no matching account exists, `customer_id` defaults to 0.

**V4 Design:** SQL LEFT JOIN with `COALESCE(a.customer_id, 0)` replicates the V1 `GetValueOrDefault(accountId, 0)` behavior.

### FR6: Effective Date from First Transaction
**Traces to:** BRD BR6
V1 captures `ifw_effective_date` from the first transaction encountered for each account. Since all transactions for a given effective date have the same `ifw_effective_date`, this is equivalent to any arbitrary `ifw_effective_date` from the group. SQL can use `MIN(ifw_effective_date)` or `MAX(ifw_effective_date)` — both produce the same result when all values are identical within the group.

**Format Note:** The V1 code stores the raw `DateOnly` object from `row["ifw_effective_date"]`. The observed output format is `MM/DD/YYYY` (e.g., `10/01/2024`), which is the default `DateOnly.ToString()` format. The V4 SQL must reproduce this format exactly.

### FR7: Framework CsvFileWriter Output
**Traces to:** BRD BR7
V4 uses the framework's CsvFileWriter with `writeMode: "Overwrite"`, producing date-partitioned output at `Output/double_secret_curated/daily_balance_movement/daily_balance_movement/{etl_effective_date}/daily_balance_movement.csv`. The framework automatically injects the `etl_effective_date` column.

### FR8: Empty Input Handling
**Traces to:** BRD BR8
When transactions or accounts are null/empty, return an empty DataFrame. CsvFileWriter produces a header-only CSV.

---

## 2. Anti-Pattern Analysis

### AP3 — Unnecessary External Module (V1)
**Identified in BRD:** Entire aggregation is a GROUP BY with a JOIN.
**V4 Avoidance:** Replace External module with SQL Transformation:
```sql
SELECT t.account_id,
       COALESCE(a.customer_id, 0) AS customer_id,
       SUM(CASE WHEN t.txn_type = 'Debit' THEN t.amount ELSE 0 END) AS debit_total,
       SUM(CASE WHEN t.txn_type = 'Credit' THEN t.amount ELSE 0 END) AS credit_total,
       SUM(CASE WHEN t.txn_type = 'Credit' THEN t.amount ELSE 0 END) -
       SUM(CASE WHEN t.txn_type = 'Debit' THEN t.amount ELSE 0 END) AS net_movement,
       MIN(t.ifw_effective_date) AS ifw_effective_date
FROM transactions t
LEFT JOIN accounts a ON t.account_id = a.account_id
GROUP BY t.account_id, a.customer_id
```
**Evidence of alternative achieving same output:** The SQL produces identical account-level aggregation with the same debit/credit classification logic. COALESCE replicates the default-0 behavior.

### AP4 — Unused Columns (V1)
**Identified in BRD:** `transaction_id` sourced but never used.
**V4 Avoidance:** Remove `transaction_id` from the DataSourcing columns list.
**Fidelity Impact:** None.

### AP5 — Asymmetric Null/Default Handling (V1)
**Identified in BRD:** Unmatched account_id gets customer_id = 0; unmatched txn_type is silently dropped.
**V4 Avoidance:** The V4 SQL explicitly documents both behaviors:
- `COALESCE(a.customer_id, 0)` -- documented default for unmatched accounts
- CASE expression only matches 'Debit' and 'Credit' -- unmatched types contribute 0 to both totals (equivalent to V1 silent drop since the account still appears with 0/0)

Note: This is fidelity-preserving. The V1 behavior IS the business rule. V4 documents it explicitly rather than hiding it in implicit dictionary behavior.

### AP6 — Row-by-Row Iteration (V1)
**Identified in BRD:** foreach loop with dictionary accumulation.
**V4 Avoidance:** SQL GROUP BY. Set-based operation, no loops.

### AP7 — Magic Values (V1)
**Identified in BRD:** Default customer_id = 0 for unmatched accounts.
**V4 Avoidance:** The value 0 is preserved (fidelity requirement) but documented explicitly in the SQL via COALESCE and in this FSD.

---

## 3. Output DataFrames

### Output 1: daily_balance_movement.csv

| Column | Type | Source | Transformation | BRD Reference |
|--------|------|--------|----------------|---------------|
| account_id | int | transactions.account_id | GROUP BY key | BR1 |
| customer_id | int | accounts.customer_id | LEFT JOIN, COALESCE to 0 | BR5 |
| debit_total | double | transactions.amount | SUM WHERE txn_type = 'Debit' | BR1, BR2 |
| credit_total | double | transactions.amount | SUM WHERE txn_type = 'Credit' | BR1, BR2 |
| net_movement | double | Computed | credit_total - debit_total | BR3 |
| ifw_effective_date | object | transactions.ifw_effective_date | MIN() from group (all same value) | BR6 |
| etl_effective_date | string (yyyy-MM-dd) | Framework injected | CsvFileWriter auto-injection | BR7 |

---

## 4. Module Chain Design

### Preferred: DataSourcing -> DataSourcing -> Transformation -> CsvFileWriter

1. **DataSourcing** — Source `transactions` table with columns `account_id`, `txn_type`, `amount`. Single-day filter on `ifw_effective_date`. (Note: `ifw_effective_date` is auto-included by framework.)
2. **DataSourcing** — Source `accounts` table with columns `account_id`, `customer_id`. Single-day filter on `ifw_effective_date`.
3. **Transformation** — SQL aggregation with JOIN:
   ```sql
   SELECT t.account_id,
          COALESCE(a.customer_id, 0) AS customer_id,
          SUM(CASE WHEN t.txn_type = 'Debit' THEN CAST(t.amount AS REAL) ELSE 0 END) AS debit_total,
          SUM(CASE WHEN t.txn_type = 'Credit' THEN CAST(t.amount AS REAL) ELSE 0 END) AS credit_total,
          SUM(CASE WHEN t.txn_type = 'Credit' THEN CAST(t.amount AS REAL) ELSE 0 END) -
          SUM(CASE WHEN t.txn_type = 'Debit' THEN CAST(t.amount AS REAL) ELSE 0 END) AS net_movement,
          MIN(t.ifw_effective_date) AS ifw_effective_date
   FROM transactions t
   LEFT JOIN accounts a ON t.account_id = a.account_id
   GROUP BY t.account_id, a.customer_id
   ```
   Result name: `daily_balance_movement`
4. **CsvFileWriter** — Write `daily_balance_movement` with writeMode "Overwrite", date-partitioned output.

**No External Module.** The entire job is expressible as DataSourcing + SQL Transformation + CsvFileWriter. No trailer, no custom logic needed.

### ifw_effective_date Format Concern
V1 output shows `ifw_effective_date` as `10/01/2024` (MM/DD/YYYY format from DateOnly.ToString() default). The framework's DataSourcing returns `ifw_effective_date` as a DateOnly object. When passed through SQLite MIN() and back to DataFrame, the format depends on how the framework serializes the value. If the framework preserves the DateOnly object through SQLite round-trip, the CSV output format should match V1. This must be verified during testing; if format differs, the SQL may need explicit formatting via `strftime()`.

---

## 5. Open Questions

1. **Double vs REAL precision:** V1 uses C# `double`; SQLite uses IEEE 754 REAL (also 64-bit double). Functionally identical, but accumulation order may differ. Proofmark comparison is the definitive test.

2. **ifw_effective_date format:** V1 outputs `MM/DD/YYYY`. V4 SQL needs to produce the same format. Depends on how the framework handles DateOnly through SQLite registration. May need `strftime('%m/%d/%Y', ifw_effective_date)` in the SQL.

3. **Row ordering:** V1 iterates over a Dictionary<int,...> which has no guaranteed order. V4 SQL has no ORDER BY, so output row order is undefined. V1 output order depends on dictionary insertion order. Proofmark comparison should account for order-independence or we should add an explicit ORDER BY matching V1's observed output order.
