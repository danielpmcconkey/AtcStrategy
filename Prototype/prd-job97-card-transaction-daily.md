# PRD — CardTransactionDaily

**Version:** 1.0
**Date:** 2026-04-29
**Job ID:** 97
**Status:** Draft

---

## 1. Purpose

CardTransactionDaily produces a daily summary of card transactions aggregated
by card type. For each run date, the output contains one row per card type
showing the count of transactions, total amount, and average amount. On the
last day of each calendar month, an additional summary row is appended.

The output is a single CSV file per run date. No downstream ETL consumers are
known — this is a terminal artifact. The job has no upstream ETL dependencies
and can run independently once the source tables are populated.

---

## 2. Data Flow

```
cards              (no date filter) ──┐
card_transactions  (no date filter) ──┤──► [join + aggregate by card type] ──► card_transaction_daily.csv
accounts           (unused)         ──┘
customers          (unused)
```

---

## 3. Data Sources

### REQ-001 — Source: `datalake.card_transactions`

| Property     | Value                          |
|--------------|--------------------------------|
| Schema/Table | `datalake.card_transactions`   |
| Date mode    | No filter — entire table       |
| Date column  | N/A                            |
| Filters      | None                           |

**Columns consumed:** `card_id`, `amount`, `ifw_effective_date`

**Role in pipeline:** Fact table. Each row is a card transaction. Aggregated by
card type to produce the output.

---

### REQ-002 — Source: `datalake.cards`

| Property     | Value                          |
|--------------|--------------------------------|
| Schema/Table | `datalake.cards`               |
| Date mode    | No filter — entire table       |
| Date column  | N/A                            |
| Filters      | None                           |

**Columns consumed:** `card_id`, `card_type`

**Role in pipeline:** Reference table for resolving each transaction's card
type via `card_id`.

---

### REQ-003 — Source: `datalake.accounts` (DEAD SOURCE)

This source exists in the legacy job but has no effect on output. The build
team should NOT include it.

---

### REQ-004 — Source: `datalake.customers` (DEAD SOURCE)

This source exists in the legacy job but has no effect on output. The build
team should NOT include it.

---

## 4. Transformation Rules

### REQ-005 — Card Type Resolution

Resolve each transaction's card type by matching `card_id` from
`card_transactions` against `card_id` in `cards`.

- Transactions with no matching card record default to card type `"Unknown"`.
- If duplicate `card_id` values exist in `cards`, the last encountered value
  wins (last-write-wins semantics on the lookup).

---

### REQ-006 — Transaction Aggregation by Card Type

Group all transactions by their resolved card type. For each group, compute:

| Output field       | Computation                                      |
|--------------------|--------------------------------------------------|
| `card_type`        | Group key (e.g., `"Credit"`, `"Debit"`)          |
| `txn_count`        | Count of transactions in the group               |
| `total_amount`     | Sum of `amount` values, using decimal arithmetic |
| `avg_amount`       | `total_amount / txn_count`, rounded to 2 decimal places |
| `ifw_effective_date` | See REQ-007                                    |

**Decimal precision:** All amount calculations use decimal (not floating point)
arithmetic. Source amounts are converted to decimal before summing.

**Division by zero:** If a group somehow has zero transactions, `avg_amount`
is `0`. (Guard condition — empty groups should not be created.)

**Row ordering:** Output row order across card types is non-deterministic.

---

### REQ-007 — Effective Date Derivation

The `ifw_effective_date` value for all output rows (including the monthly
summary row) is taken from the first row of the `card_transactions` data. It
is a single value applied uniformly — not per-group.

---

### REQ-008 — Monthly Summary Row

On the last day of the calendar month (determined by comparing the run date's
day to the number of days in that month), append one additional row after all
card-type rows:

| Field              | Value                                             |
|--------------------|---------------------------------------------------|
| `card_type`        | Literal string `"MONTHLY_TOTAL"`                  |
| `txn_count`        | Sum of all groups' transaction counts              |
| `total_amount`     | Sum of all groups' total amounts                   |
| `avg_amount`       | `total_amount / txn_count`, rounded to 2 decimal places |
| `ifw_effective_date` | Same value as all other rows (REQ-007)           |

The `MONTHLY_TOTAL` row summarizes only the single run date's transactions —
it is NOT a cumulative monthly total despite the name.

---

### REQ-009 — Empty Input Handling

If either `card_transactions` or `cards` is empty (no rows), produce an empty
output with the correct column schema and skip all transformation logic.

---

## 5. Output Specification

### REQ-010 — Output: `card_transaction_daily.csv`

| Property        | Value                                    |
|-----------------|------------------------------------------|
| Format          | CSV                                      |
| Write mode      | Overwrite                                |
| Partitioning    | Date-partitioned by run date             |
| Path pattern    | `Output/curated/card_transaction_daily/card_transaction_daily/{YYYY-MM-DD}/card_transaction_daily.csv` |

**Schema (6 columns, in order):**

| # | Column               | Type           | Description                              |
|---|----------------------|----------------|------------------------------------------|
| 1 | `card_type`          | string         | Card type group key, or `"MONTHLY_TOTAL"` on month-end |
| 2 | `txn_count`          | integer        | Transaction count per group              |
| 3 | `total_amount`       | decimal (2dp)  | Sum of transaction amounts               |
| 4 | `avg_amount`         | decimal (2dp)  | Average transaction amount               |
| 5 | `ifw_effective_date` | string         | Format: `M/D/YYYY` (no leading zeros, e.g., `10/1/2024`) |
| 6 | `etl_effective_date` | string         | Run date in `YYYY-MM-DD` format, injected at write time |

**Formatting rules:**

| Rule           | Value                                                |
|----------------|------------------------------------------------------|
| Encoding       | UTF-8                                                |
| Line ending    | `LF` (`\n`)                                          |
| Header row     | Yes                                                  |
| Quoting        | RFC 4180 — fields with commas/quotes are double-quoted |
| Decimal format | Always 2 decimal places for `total_amount` and `avg_amount` |

**Trailer line:** `TRAILER|{row_count}|{YYYY-MM-DD}` where `row_count` is the
number of data rows (excludes header and trailer) and the date is
`etl_effective_date`.

**Row ordering:** Non-deterministic for card-type rows. On month-end days,
`MONTHLY_TOTAL` is always the last data row.

**Row counts:**

| Scenario       | Data rows | Notes                                    |
|----------------|-----------|------------------------------------------|
| Empty day      | 0         | Empty input guard (REQ-009) triggered    |
| Regular day    | 2         | Credit + Debit                           |
| End-of-month   | 3         | Credit + Debit + MONTHLY_TOTAL           |

---

## 6. Correctness Flags

### CF-001 — No Date Filtering on Source Data

**Observed behavior:** The legacy job loads the entire `card_transactions`
table (all dates, all rows) on every run. The aggregation operates on the full
table, not just the run date's transactions.

**Concern:** It is unclear whether the intent is to aggregate all-time
transactions or only the run date's transactions. If the table grows, every
run re-aggregates the entire history. The output for a given day would change
if historical rows were added or modified.

**Resolution (required before lock):**
- [x] **Reproduce** — build matches legacy behavior as-is
- [ ] **Remediate** — build deviates from legacy, with justification:

---

### CF-002 — Misleading MONTHLY_TOTAL Name

**Observed behavior:** The `MONTHLY_TOTAL` row aggregates only the single run
date's transactions on the last day of the month — not a cumulative total
across the entire month.

**Concern:** Downstream consumers may interpret `MONTHLY_TOTAL` as a
month-wide aggregation. The actual behavior is "daily total, on a day that
happens to be month-end."

**Resolution (required before lock):**
- [x] **Reproduce** — build matches legacy behavior as-is
- [ ] **Remediate** — build deviates from legacy, with justification:

---

### CF-003 — Effective Date from Arbitrary Row

**Observed behavior:** The `ifw_effective_date` output value comes from the
first physical row of the transaction data. If the data contained multiple
dates, only one would be represented. No validation ensures all rows share the
same date.

**Concern:** The value depends on data ordering, which is not guaranteed. In
practice, current data is single-date per run, making this cosmetic — but the
behavior is fragile.

**Resolution (required before lock):**
- [x] **Reproduce** — build matches legacy behavior as-is
- [ ] **Remediate** — build deviates from legacy, with justification:

---

### CF-004 — Silent Default on Missing Card Lookup

**Observed behavior:** Transactions referencing a `card_id` not present in
`cards` are silently assigned card type `"Unknown"`. No logging or alerting
occurs.

**Concern:** Orphaned transactions could mask data quality issues (missing
card records, referential integrity failures). The `"Unknown"` value would
appear in output without explanation.

**Resolution (required before lock):**
- [x] **Reproduce** — build matches legacy behavior as-is
- [ ] **Remediate** — build deviates from legacy, with justification:

---

## 7. Assumptions

| # | Assumption | Basis |
|---|------------|-------|
| A-01 | The `datalake` schema is immutable per-date — rows are never updated or deleted after initial load | Source system behavior |
| A-02 | No date filtering is intentional — the job aggregates ALL rows in `card_transactions` regardless of run date | Legacy behavior confirmed; see CF-001 |
| A-03 | Only two card types (`Credit`, `Debit`) exist in current data; the `"Unknown"` fallback has not been triggered in observed runs | Observed from output samples |
| A-04 | `ifw_effective_date` in `card_transactions` consistently uses `M/D/YYYY` format (no leading zeros) | Observed across all sample dates |
| A-05 | The `MONTHLY_TOTAL` row summarizes only the run date's data, not the full month | Legacy behavior confirmed; see CF-002 |

---

## 8. Requirements Traceability Matrix

| Req ID  | Description                                                         | Rebuild Anchor | Test Case | Status |
|---------|---------------------------------------------------------------------|----------------|-----------|--------|
| REQ-001 | Source `datalake.card_transactions` — no date filter                |                |           |        |
| REQ-002 | Source `datalake.cards` — no date filter                            |                |           |        |
| REQ-003 | Dead source `datalake.accounts` — exclude from build                |                |           |        |
| REQ-004 | Dead source `datalake.customers` — exclude from build               |                |           |        |
| REQ-005 | Resolve card type via card_id lookup; default `"Unknown"` on miss   |                |           |        |
| REQ-006 | Aggregate by card type: count, sum, avg (decimal, 2dp)              |                |           |        |
| REQ-007 | Effective date from first transaction row, applied to all output     |                |           |        |
| REQ-008 | MONTHLY_TOTAL summary row on last day of calendar month             |                |           |        |
| REQ-009 | Empty input returns zero-row DataFrame with correct schema          |                |           |        |
| REQ-010 | Output CSV: 6 columns, Overwrite, LF, UTF-8, RFC 4180, trailer     |                |           |        |
| CF-001  | No date filtering on source — reproduce                             |                |           |        |
| CF-002  | MONTHLY_TOTAL name misleading — reproduce                           |                |           |        |
| CF-003  | Effective date from arbitrary row — reproduce                       |                |           |        |
| CF-004  | Silent Unknown default on missing card — reproduce                  |                |           |        |
