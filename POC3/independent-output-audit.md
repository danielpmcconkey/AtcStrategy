# Independent Output Audit -- MockEtlFramework V2
**Date:** 2026-03-02
**Auditor:** Independent skeptical review (Claude agent, no project team involvement)
**Scope:** 5 sampled V2 jobs -- BRD-to-output validation

## Methodology

### Job Selection
Selected 5 jobs for diversity across multiple dimensions:
- **Output format:** 2 CSV, 3 Parquet
- **Complexity:** Range from simple aggregation (executive_dashboard) to multi-table joins with snapshot fallback (covered_transactions)
- **Business domain:** Executive reporting, customer analytics, risk assessment, regulatory/AML, compliance
- **Selection was blind** -- I picked jobs that sounded interesting before reading any BRDs or output

### For Each Job
1. Read the BRD to understand the documented business requirements
2. Queried PostgreSQL datalake source tables to verify source data counts and values
3. Examined V2 output files (CSV directly, Parquet via pyarrow)
4. Spot-checked individual records by tracing source data through business rules to expected output
5. Compared V2 output to V1 baseline (curated/ directory) where relevant
6. When issues were found, traced to V2 source code to confirm root cause

### Jobs Selected
1. executive_dashboard (CSV) -- high-level KPI aggregation
2. customer_credit_summary (CSV) -- per-customer financial summary
3. large_transaction_log (Parquet) -- AML/regulatory large transaction tracking
4. loan_risk_assessment (Parquet) -- credit risk tier classification
5. covered_transactions (Parquet) -- FDIC-insured transaction reporting

---

## Job-by-Job Assessment

### Job 1: executive_dashboard (CSV)

**Inferred Business Need:**
A senior executive needs a single-screen view of the bank's key operational metrics on any given day: how many customers, how much money is on deposit, how many transactions are moving, what's the loan book look like, are branches getting foot traffic. This is a daily health check for someone who makes decisions at the institutional level.

**Output Assessment:**
9 metric rows, exactly as specified. All values validated against direct SQL queries on the datalake source tables:

| Metric | V2 Output | Source Query | Match |
|--------|-----------|-------------|-------|
| total_customers | 2,230 | COUNT(*) FROM customers | YES |
| total_accounts | 2,869 | COUNT(*) FROM accounts | YES |
| total_balance | 10,429,347.73 | SUM(current_balance) FROM accounts | YES |
| total_transactions | 4,263 | COUNT(*) FROM transactions | YES |
| total_txn_amount | 3,871,936.14 | SUM(amount) FROM transactions | YES |
| avg_txn_amount | 908.27 | 3,871,936.14 / 4,263 | YES |
| total_loans | 894 | COUNT(*) FROM loan_accounts | YES |
| total_loan_balance | 114,330,325.25 | SUM(current_balance) FROM loan_accounts | YES |
| total_branch_visits | 244 | COUNT(*) FROM branch_visits | YES |

**Data Quality:**
- All 9 metrics verified to the penny against source data
- Date format consistent with V1 (MM/DD/YYYY)
- SUMMARY trailer line present (framework convention, also present in V1) -- downstream parsers need to handle this
- Overwrite mode means only one date's data present, which is correct per spec

**Verdict: PASS**
This output is exactly what a business user would expect. Clean, accurate, no surprises.

---

### Job 2: customer_credit_summary (CSV)

**Inferred Business Need:**
A relationship manager or credit officer needs to see each customer's complete financial posture at a glance: their credit score, how much they owe in loans, how much they have on deposit, and how many products they hold. This drives decisions like "should we offer this customer a new product" or "is this customer a credit risk."

**Output Assessment:**
2,230 rows (one per customer, matching the customer table exactly). Spot-checked 3 customers:

- Customer 1024 (Ellie Nguyen): avg_credit_score = 776.33 (verified: Equifax 761 + TransUnion 782 + Experian 786 = avg 776.33). total_account_balance = 3,545.00 (verified: single Checking account with $3,545). loan_count = 0 (verified: no loans). CORRECT.
- Customer 1025 (Jackson Harris): avg_credit_score = 840 (verified: 833+850+837 = avg 840). total_loan_balance = 47,435.95 (verified: single Personal loan). CORRECT.
- Customer 1004 (Sophia Reynolds): avg_credit_score = 782.33 (verified: 797+776+774 = avg 782.33). total_loan_balance = 6,086.00 (verified). CORRECT.

**Data Quality:**
- Precision difference from V1: V2 outputs avg_credit_score with full decimal precision (e.g., 776.33333333333333333333333333) while V1 rounds to integer (e.g., 776). The business rules say "arithmetic mean" with no rounding spec, so both are technically correct, but the V2 output is aesthetically ugly and could cause issues for downstream consumers expecting integer credit scores.
- Negative account balances appear in some rows (e.g., customer 1026: total_account_balance = -1,499.00). This is valid -- credit card accounts can carry negative balances.
- No SUMMARY trailer on this CSV (inconsistent with executive_dashboard, but not a bug -- trailer presence varies by job config).

**Verdict: PASS (with cosmetic note)**
The data is correct. The unbounded decimal precision is a formatting concern, not a correctness issue. A business user would get the right answers but might squint at "776.33333333333333333333333333" on a screen.

---

### Job 3: large_transaction_log (Parquet)

**Inferred Business Need:**
The bank's compliance or AML (Anti-Money Laundering) team needs a running log of every transaction over $500, enriched with the customer's name. This is a standard regulatory requirement -- banks must monitor and report large transactions. The $500 threshold is below the typical BSA/CTR threshold of $10,000, suggesting this is for internal monitoring rather than mandatory regulatory filing.

**Output Assessment:**
3,104 rows for the 2024-10-01 effective date. Verified against source: `SELECT COUNT(*) FROM transactions WHERE amount > 500 AND as_of = '2024-10-01'` returns 3,104. Exact match.

Spot-checked customer enrichment:
- Transaction 4023: account_id 3012 -> customer_id 1012 (Amelia Chow), amount $1,200. Source query confirms: account 3012 belongs to customer 1012, name is Amelia Chow. CORRECT.
- Minimum amount in output: 501.0 (correct -- threshold is > 500, not >= 500)
- Maximum amount in output: 2,500.0

**Data Quality:**
- Schema differences from V1: V2 uses int64 for IDs (V1 uses int32), double for amount (V1 uses decimal128), string for txn_timestamp/as_of (V1 uses native timestamp/date types). The double-for-amount change is a concern for financial data -- IEEE 754 double precision can't represent all decimal values exactly. For amounts in the $500-$2,500 range, this is unlikely to cause visible errors, but it's architecturally wrong for financial data.
- Only 1 effective date present in V2 output (2024-10-01). This is an Append-mode job, so it should accumulate over multiple dates. The single date suggests only one date has been processed, which is expected for a test run.

**Verdict: PASS (with schema concern)**
Row counts match, enrichment is correct, filtering is correct. The use of double instead of decimal for financial amounts is an architectural smell but doesn't produce visible errors at this data scale.

---

### Job 4: loan_risk_assessment (Parquet)

**Inferred Business Need:**
The credit risk team needs every loan in the portfolio classified by risk tier based on the borrower's creditworthiness. This drives provisioning decisions (how much the bank sets aside for potential losses), regulatory capital calculations, and portfolio management. Getting the tier boundaries wrong means mispricing risk.

**Output Assessment:**
894 rows (one per loan, matching the loan_accounts table count for 2024-10-01). Risk tier distribution:

| Tier | V2 Count | V1 Count |
|------|----------|----------|
| Low Risk | 375 | 214 |
| Medium Risk | 134 | 288 |
| High Risk | 263 | 241 |
| Very High Risk | 122 | 151 |

**CRITICAL FINDING: V2 uses wrong threshold for Low Risk tier.**

The BRD specifies: avg_credit_score >= 750 = "Low Risk". V1 correctly implements this. V2 uses >= 700 instead of >= 750. Confirmed by:
- V2 output: Low Risk loans start at avg_credit_score = 700.00 (should start at 750.00)
- V1 output: Low Risk loans start at avg_credit_score = 750.00 (correct)
- V2 source code (`loan_risk_assessment_v2.json` line 22): SQL says `WHEN cs_avg.avg_credit_score >= 700 THEN 'Low Risk'`
- 161 loans are INCORRECTLY classified as Low Risk that should be Medium Risk

This means the bank would be understating risk on 161 loans. In a real portfolio, this could mean:
- Insufficient loan loss provisioning
- Incorrect risk-weighted assets for capital adequacy
- Misinformed portfolio management decisions

**Data Quality:**
Aside from the tier misclassification, the underlying data (loan details, avg_credit_score calculation) is correct. Spot-checked loan_id 1 (customer 1004): avg(797, 776, 774) = 782.33, matching the V2 avg_credit_score of 782.33. The ONLY error is the tier threshold.

**Verdict: FAIL**
The risk tier classification is materially wrong. 18% of loans (161 of 894) are misclassified as lower risk than they actually are. This is exactly the kind of error that regulators fine banks for.

**Note:** Post-audit, I discovered this is one of 12 deliberate "saboteur" mutations planted in the V2 code as a red team exercise (saboteur-ledger.md, mutation #9). The mutation was designed to test whether the framework's comparison tool (Proofmark) would catch it. The comparison step has not yet been executed for this job.

---

### Job 5: covered_transactions (Parquet)

**Inferred Business Need:**
This is likely an FDIC/regulatory reporting dataset. "Covered transactions" in banking typically refers to transactions on insured deposit accounts (Checking) for customers with verified US addresses. This would be used for regulatory reporting, compliance monitoring, or deposit insurance calculations. The denormalized format (transaction + customer demographics + address + account details in one row) suggests this feeds a report or downstream analytics system.

**Output Assessment:**
1,716 rows for 2024-10-01.

**CRITICAL FINDING: V2 includes Savings accounts in addition to Checking.**

| Account Type | V2 Count | V1 Count |
|-------------|----------|----------|
| Checking | 855 | 868 |
| Savings | 861 | 0 |
| **Total** | **1,716** | **868** |

The BRD (BR-1) explicitly states: "Only transactions associated with Checking accounts are included." V1 correctly implements this (868 rows, all Checking). V2 includes Savings accounts, nearly doubling the output.

Confirmed in V2 source code (`CoveredTransactionsV2Processor.cs` line 88):
```csharp
if (row["account_type"]?.ToString() == CoveredAccountType || row["account_type"]?.ToString() == "Savings")
```
The comment on line 84 says "Build dictionary of Checking accounts only" while the code also includes Savings. The comment contradicts the code.

This means:
- If this feeds regulatory reporting, the bank is reporting transactions that don't qualify
- If this feeds deposit insurance calculations, balances are overstated
- The output is approximately 2x the correct size

**Data Quality (other than the filter error):**
- All output rows have country = 'US' (correct per BR-4)
- record_count = 1716 on every row (consistent with the actual row count, but the count itself is inflated due to the Savings inclusion)
- Sort order appears correct (customer_id ASC, transaction_id DESC within each customer)
- Customer demographics, addresses, and timestamps are properly formatted

**Verdict: FAIL**
The inclusion of Savings accounts is a material error that would produce incorrect regulatory output. The output is nearly double what it should be.

**Note:** Post-audit, I discovered this is also a deliberate saboteur mutation (saboteur-ledger.md, mutation #7). Same red team exercise as the loan_risk_assessment finding.

---

## Overall Assessment

### The Good
Of the 5 jobs audited, 3 produced correct output:
- **executive_dashboard**: Every metric verified to the penny against source data. This is the kind of output you'd be comfortable showing a board of directors.
- **customer_credit_summary**: All spot-checked records were correct. Row counts match source data exactly. The only issue is cosmetic (decimal precision formatting).
- **large_transaction_log**: Filtering, enrichment, and row counts all verified correct against source data.

For the clean (non-sabotaged) jobs, the V2 framework produced accurate, complete, business-useful output. The SQL-based transformations correctly replicate the V1 External module logic. Source data is read correctly, aggregations compute correctly, and joins resolve correctly.

### The Bad
2 of 5 jobs had material errors:
- **loan_risk_assessment**: Wrong threshold for Low Risk tier (700 instead of 750). 161 of 894 loans misclassified. This would understate portfolio risk.
- **covered_transactions**: Savings accounts incorrectly included alongside Checking. Output is approximately 2x the correct size. This would produce incorrect regulatory data.

Both errors were later identified as DELIBERATE saboteur mutations planted as part of the project's red team methodology. This is actually a positive sign for the project's governance -- they're stress-testing their own pipeline. However, it means the current V2 output in `Output/double_secret_curated/` is NOT suitable for business use without first completing the comparison step (Proofmark) and remediating detected issues.

### The Ugly
Schema differences between V1 and V2 Parquet output are a concern:
- V2 uses `double` for financial amounts where V1 uses `decimal128`. This is architecturally inappropriate for financial data. No visible errors at current data volumes, but this would eventually produce penny rounding issues at scale.
- V2 uses `string` for dates/timestamps where V1 uses native types. This loses type safety and makes downstream processing harder.
- V2 uses `int64` for IDs where V1 uses `int32`. Not a correctness issue, just inefficient.

### Bottom Line
**The framework works.** When the business logic is correctly specified, V2 produces accurate output. The 3 clean jobs demonstrate that the SQL-based transformation approach is a viable replacement for the V1 External module (C# procedural code) approach. The framework's ability to read from PostgreSQL, apply SQL transformations, and write correct CSV/Parquet output is solid.

**The saboteur findings, while deliberate, prove the importance of the comparison step.** A human eyeballing the output of loan_risk_assessment or covered_transactions would not catch these errors -- the data LOOKS reasonable, the counts aren't absurd, and the schema is correct. Only systematic comparison against V1 baseline would detect the threshold shift and filter expansion. The project team's decision to invest in automated comparison tooling (Proofmark) is validated by this audit.

**Confidence level: Moderate.** The sample size (5 jobs out of 100+) is too small for a definitive assessment. The 3 clean jobs all produced correct output, but 3 samples can't prove the framework is bug-free. The 2 failures were deliberate sabotage, not organic bugs, which limits what they tell us about real-world reliability.

## Limitations of This Audit

1. **Sample size**: 5 of ~100 jobs. This is a spot check, not a comprehensive audit. The 3 clean jobs happened to be straightforward (simple aggregations, basic joins). The most complex clean job (large_transaction_log) is still relatively simple logic. I did not sample any of the most complex analytics jobs (e.g., customer_360_snapshot, quarterly_executive_kpis).

2. **Single effective date**: All V2 output was for 2024-10-01. I could not test Append-mode behavior across multiple dates, weekend/gap-fill behavior, or edge cases around date boundaries.

3. **No negative testing**: I verified that correct data IS present, but I did not verify that incorrect data is ABSENT (except for the filter-based checks). I did not check for duplicate rows, orphan records, or referential integrity violations.

4. **Schema drift**: I noted Parquet type differences but did not test whether downstream consumers would break on these type changes. In a production environment, a Parquet reader expecting decimal128 might fail or silently lose precision when receiving double.

5. **No test of Overwrite vs. Append correctness**: I could not verify that Overwrite-mode jobs correctly replace prior data or that Append-mode jobs correctly accumulate without duplication, because only single-date output was available.

6. **Saboteur contamination**: 2 of 5 sampled jobs had deliberate errors. This means 40% of my sample was testing the saboteur, not the framework. A clean audit would require running against a non-sabotaged V2 build.

7. **I am an AI evaluating AI-built output.** I have no domain expertise in banking regulations, FDIC insurance rules, or loan provisioning. My "inferred business needs" are educated guesses based on column names and general knowledge. A human domain expert might identify issues I missed entirely.
