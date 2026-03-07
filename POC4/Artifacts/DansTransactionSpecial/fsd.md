# FSD: DansTransactionSpecial

**Job ID:** 373
**Job Name:** DansTransactionSpecial
**BRD Reference:** `POC4/Artifacts/DansTransactionSpecial/brd.md`
**Config Reference:** `MockEtlFramework/JobExecutor/Jobs/dans_transaction_special.json`

---

## 1. Functional Requirements

### FR1: Address Deduplication
**Traces to:** BRD BR1
Addresses are deduplicated per customer using `ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY start_date DESC)`, keeping only the most recent address (rn = 1) per customer. This is implemented as a CTE (`deduped_addresses`) within the SQL Transformation.

**V4 Design Note:** The `addresses` DataSourcing uses `mostRecent: true`, which fetches the latest snapshot of addresses. If a single snapshot can contain multiple addresses per customer, the CTE dedup is necessary. If the snapshot already guarantees one address per customer, the CTE is redundant but harmless. For fidelity, V4 preserves the CTE.

### FR2: Multi-Table Denormalization
**Traces to:** BRD BR2
Transactions are enriched via three LEFT JOINs:
- `transactions t LEFT JOIN accounts a ON t.account_id = a.account_id`
- `accounts a LEFT JOIN customers c ON a.customer_id = c.id`
- `accounts a LEFT JOIN deduped_addresses da ON a.customer_id = da.customer_id AND da.rn = 1`

### FR3: Transaction Details Output (Overwrite)
**Traces to:** BRD BR3
The first output produces a fully denormalized transaction record. Written via CsvFileWriter with `writeMode: "Overwrite"`. Each effective date produces an independent file.

### FR4: State/Province Aggregation
**Traces to:** BRD BR4
The second transformation aggregates the `transaction_details` DataFrame by `ifw_effective_date` and `state_province`:
- `transaction_count = COUNT(*)`
- `total_amount = SUM(amount)`

### FR5: State/Province Output (Append, Cumulative)
**Traces to:** BRD BR5
The state/province summary is written with `writeMode: "Append"`. Each run's output includes all accumulated prior data plus current day's aggregates. The framework handles accumulation via `FindLatestPartition`, prior data read, trailer strip (if configured — this output has no trailer), `etl_effective_date` drop/re-add, and union.

### FR6: Output Ordering
**Traces to:** BRD BR6
- Transaction details: `ORDER BY t.transaction_id ASC`
- State/province summary: `ORDER BY ifw_effective_date ASC, state_province ASC`

### FR7: All Left Joins — Nullable Enrichment
**Traces to:** BRD BR7
All three enrichment joins are LEFT JOINs:
- Transactions without matching accounts: customer_id, account_type, account_status, current_balance are NULL
- Accounts without matching customers: sort_name is NULL
- Customers without matching addresses: city, state_province, postal_code are NULL

### FR8: Empty Day Handling
**Traces to:** BRD Edge Case 1
When no transactions exist for the effective date, transaction_details is empty (Overwrite: header-only CSV). State/province append file still contains prior accumulated data with updated etl_effective_date.

### FR9: Non-Deterministic Address Dedup Tiebreaker
**Traces to:** BRD Edge Case 4
If multiple addresses for the same customer have the same `start_date`, `ROW_NUMBER()` with no tiebreaker column produces non-deterministic results. This is a known V1 behavior that V4 preserves. If it causes Proofmark comparison failures, it must be documented as a non-deterministic element and the affected column(s) excluded from STRICT comparison.

### FR10: ifw_effective_date Explicit Sourcing
**Traces to:** BRD AP7 (Minor)
V1 explicitly includes `ifw_effective_date` in the transactions DataSourcing columns. This is unusual — most jobs let the framework inject it automatically. For fidelity, V4 preserves this explicit sourcing.

---

## 2. Anti-Pattern Analysis

### AP4 — Unused Columns (V1)
**Identified in BRD:** `first_name` and `last_name` sourced from customers but never used in any SQL.
**V4 Avoidance:** Remove `first_name` and `last_name` from the customers DataSourcing columns list. Source only `id` and `sort_name`.
**Fidelity Impact:** None — these columns are never referenced in any transformation or output.

### AP8 — Complex/Dead SQL, Minor (V1)
**Identified in BRD:** The `deduped_addresses` CTE may be redundant if the `mostRecent: true` snapshot already contains one address per customer.
**V4 Decision:** Preserve the CTE. The dedup is defensive — it guarantees one address per customer regardless of snapshot contents. Removing it would be a functional change (potentially introducing duplicate rows from address joins). The overhead is minimal (ROW_NUMBER on a small table).

### AP7 — Magic Values, Minor (V1)
**Identified in BRD:** `ifw_effective_date` explicitly sourced in transactions DataSourcing.
**V4 Decision:** Preserve. This is the source of the `ifw_effective_date` column in the output, which is needed for the state/province aggregation GROUP BY. Removing it would break the second output.

---

## 3. Output DataFrames

### Output 1: dans_transaction_details.csv

| Column | Type | Source | Transformation | BRD Reference |
|--------|------|--------|----------------|---------------|
| transaction_id | int | transactions.transaction_id | Direct | BR2 |
| account_id | int | transactions.account_id | Direct | BR2 |
| customer_id | int/null | accounts.customer_id | LEFT JOIN on account_id | BR2, BR7 |
| sort_name | string/null | customers.sort_name | LEFT JOIN on customer_id = id | BR2, BR7 |
| txn_timestamp | string (ISO 8601) | transactions.txn_timestamp | Direct | BR2 |
| txn_type | string | transactions.txn_type | Direct | BR2 |
| amount | decimal | transactions.amount | Direct | BR2 |
| description | string | transactions.description | Direct | BR2 |
| account_type | string/null | accounts.account_type | LEFT JOIN | BR2, BR7 |
| account_status | string/null | accounts.account_status | LEFT JOIN | BR2, BR7 |
| current_balance | decimal/null | accounts.current_balance | LEFT JOIN | BR2, BR7 |
| city | string/null | addresses.city | LEFT JOIN via deduped_addresses | BR1, BR7 |
| state_province | string/null | addresses.state_province | LEFT JOIN via deduped_addresses | BR1, BR7 |
| postal_code | string/null | addresses.postal_code | LEFT JOIN via deduped_addresses | BR1, BR7 |
| ifw_effective_date | string (ISO 8601) | transactions.ifw_effective_date | Direct (explicitly sourced) | BR2 |
| etl_effective_date | string (yyyy-MM-dd) | Framework injected | CsvFileWriter auto-injection | N/A |

### Output 2: dans_transactions_by_state_province.csv

| Column | Type | Source | Transformation | BRD Reference |
|--------|------|--------|----------------|---------------|
| ifw_effective_date | string (ISO 8601) | transaction_details.ifw_effective_date | GROUP BY key | BR4 |
| state_province | string/null | transaction_details.state_province | GROUP BY key | BR4 |
| transaction_count | int | Computed | COUNT(*) | BR4 |
| total_amount | decimal | transaction_details.amount | SUM(amount) | BR4 |
| etl_effective_date | string (yyyy-MM-dd) | Framework injected | Current run's date for ALL rows | BR5 |

---

## 4. Module Chain Design

### Preferred: DataSourcing(x4) -> Transformation -> CsvFileWriter -> Transformation -> CsvFileWriter

This is the EXISTING V1 module chain. DansTransactionSpecial already uses the preferred pattern (SQL Transformations + CsvFileWriters, no External module). V4 changes are config-level anti-pattern fixes only.

1. **DataSourcing** — Source `transactions`. Columns: `transaction_id`, `account_id`, `txn_timestamp`, `txn_type`, `amount`, `description`, `ifw_effective_date`. Single-day filter.
2. **DataSourcing** — Source `accounts`. Columns: `account_id`, `customer_id`, `account_type`, `account_status`, `current_balance`. `mostRecent: true`.
3. **DataSourcing** — Source `customers`. Columns: `id`, `sort_name`. `mostRecent: true`. **V4 change:** Remove `first_name`, `last_name` from columns.
4. **DataSourcing** — Source `addresses`. Columns: `customer_id`, `city`, `state_province`, `postal_code`, `start_date`. `mostRecent: true`.
5. **Transformation** — SQL (unchanged from V1):
   ```sql
   WITH deduped_addresses AS (
     SELECT customer_id, city, state_province, postal_code,
            ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY start_date DESC) AS rn
     FROM addresses
   )
   SELECT t.transaction_id, t.account_id, a.customer_id, c.sort_name,
          t.txn_timestamp, t.txn_type, t.amount, t.description,
          a.account_type, a.account_status, a.current_balance,
          da.city, da.state_province, da.postal_code, t.ifw_effective_date
   FROM transactions t
   LEFT JOIN accounts a ON t.account_id = a.account_id
   LEFT JOIN customers c ON a.customer_id = c.id
   LEFT JOIN deduped_addresses da ON a.customer_id = da.customer_id AND da.rn = 1
   ORDER BY t.transaction_id
   ```
   Result name: `transaction_details`
6. **CsvFileWriter** — Write `transaction_details` with writeMode "Overwrite".
7. **Transformation** — SQL (unchanged from V1):
   ```sql
   SELECT ifw_effective_date, state_province,
          COUNT(*) AS transaction_count, SUM(amount) AS total_amount
   FROM transaction_details
   GROUP BY ifw_effective_date, state_province
   ORDER BY ifw_effective_date, state_province
   ```
   Result name: `transactions_by_state_province`
8. **CsvFileWriter** — Write `transactions_by_state_province` with writeMode "Append".

**No External Module.** V1 already uses the correct pattern. V4 preserves it.

---

## 5. Open Questions

1. **Address dedup non-determinism:** If multiple addresses share the same start_date for a customer, ROW_NUMBER picks one arbitrarily. This could cause different results between V1 and V4 runs, or between different SQLite versions. If Proofmark shows mismatches in city/state_province/postal_code columns, investigate whether address dedup tiebreaking is the cause.

2. **ifw_effective_date format in state/province output:** The output manifest notes that Oct 1 partition shows `2024-10-02T00:00:00` for ifw_effective_date. This appears to be a data issue — if transactions for 2024-10-01 have ifw_effective_date stored as 2024-10-02 in the datalake, that's what appears. V4 must reproduce whatever V1 produces, regardless of apparent incorrectness.

3. **Append re-run safety:** Same concern as BranchVisitsByCustomerCsvAppendTrailer — clean output directories required for correct append behavior. This is an operational requirement, not a V4 code issue.

4. **total_amount precision in state/province output:** SUM(amount) in SQLite uses IEEE 754 doubles. V1 also uses SQLite for the same aggregation (Transformation module). So both V1 and V4 should produce identical results. Verify with Proofmark.
