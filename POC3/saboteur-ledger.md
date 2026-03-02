# Saboteur Ledger

**Created:** 2026-03-01
**Last updated:** 2026-03-01 (Phase 2 code-level re-insertion)

---

## Phase 1: BRD-Level Mutations (Original Protocol)

**Planted:** Between Phase A (Analysis) and Phase B (Design & Implementation)
**Total mutations planted:** 13 (including 1 compound mutation across 12 BRDs)

### Constraint Verification

- **Per output type:** Parquet: 4, CSV: 6, CSV-with-trailer: 3 — all >= 2
- **Per analyst batch:** analyst-1: 1, analyst-2: 1, analyst-3: 1, analyst-4: 2, analyst-5: 1, analyst-6: 2, analyst-7: 1, analyst-8: 1, analyst-9: 1, analyst-10: 2 — all <= 2
- **Mutation type diversity:** Threshold shift: 3, Filter narrowing: 3, Rounding change: 3, Date boundary shift: 2, Join type change: 1, Aggregation change: 1 — no type exceeds 3
- **Compound mutations:** 1 (wealth_tier_analysis: threshold shift + rounding change)

### BRD Mutation Ledger

| # | Job Name | BRD Section | Original Text | Mutated Text | Mutation Type | Output Type | Analyst | Expected Detection | Phase 1 Outcome |
|---|----------|-------------|---------------|-------------|---------------|-------------|---------|-------------------|-----------------|
| 1 | card_fraud_flags | BR-2, BR-3 | "amount > $500" | "amount > $750" | Threshold shift | CSV | analyst-1 | Proofmark FAIL — fewer rows in V2 | NEUTRALIZED at FSD — architect cited V1 code ($500), added CRITICAL NOTE |
| 2 | investment_risk_profile | BR-2 | "current_value > 200000 → High Value" | "current_value > 250000 → High Value" | Threshold shift | CSV | analyst-2 | Proofmark FAIL — misclassification in $200k-$250k range | NOT YET VERIFIED — code-level check pending |
| 3 | compliance_open_items | BR-1 | "status = 'Open' or status = 'Escalated'" | "status = 'Open'" | Filter narrowing | Parquet | analyst-3 | Proofmark FAIL — fewer rows (Escalated excluded) | NOT YET VERIFIED — code-level check pending |
| 4 | overdraft_recovery_rate | BR-3 | "rounded to 4 decimal places" | "rounded to 2 decimal places" | Rounding change (STEALTH) | CSV-with-trailer | analyst-4 | Proofmark PASS (likely) — integer division makes value always 0 | NEUTRALIZED at FSD — architect cited V1 code (4dp), FSD says 4dp, code uses 4dp |
| 5 | marketing_eligible_customers | BR-1 | "ALL three channels: EMAIL, SMS, PUSH" | "BOTH channels: EMAIL, SMS" | Filter narrowing | CSV | analyst-5 | Proofmark FAIL — more rows (less restrictive filter) | NEUTRALIZED at FSD — architect cited V1 code (3 channels), added CRITICAL NOTE |
| 6 | customer_value_score | BR-7 | "rounded to 2 decimal places" | "rounded to 0 decimal places" | Rounding change | CSV | analyst-6 | Proofmark FAIL — score values differ | NEUTRALIZED at FSD — architect cited V1 code (2dp), added NOTE |
| 7 | covered_transactions | BR-1 | "Checking accounts" | "Checking or Savings accounts" | Filter narrowing | Parquet | analyst-7 | Proofmark FAIL — more rows (Savings added) | NEUTRALIZED at FSD — FSD internally contradictory (traceability says Checking/Savings, design says Checking only). Code implements Checking only. Contaminated by smoke test artifact (see Covered Transactions Cleanup in observations). |
| 8 | branch_visit_summary | BR-2 | "JOIN branches" | "LEFT JOIN branches" | Join type change | CSV-with-trailer | analyst-8 | Proofmark FAIL or PASS (data-dependent) | NOT YET VERIFIED — code-level check pending |
| 9 | loan_risk_assessment | BR-2 | "avg_credit_score >= 750 → Low Risk" | "avg_credit_score >= 700 → Low Risk" | Threshold shift | Parquet | analyst-9 | Proofmark FAIL — tier reclassification for 700-749 | NOT YET VERIFIED — code-level check pending |
| 10 | high_balance_accounts | BR-6 | "as_of from account row" | "as_of from __maxEffectiveDate" | Date boundary shift (STEALTH) | CSV | analyst-10 | Proofmark PASS (likely) — single-day mode, values probably match | NOT YET VERIFIED — code-level check pending |
| 11a | wealth_tier_analysis | BR-2 | "Bronze: wealth < $10,000" | "Bronze: wealth < $25,000" | Threshold shift (COMPOUND pt 1) | CSV-with-trailer | analyst-10 | Proofmark FAIL — tier redistribution | NOT YET VERIFIED — code-level check pending |
| 11b | wealth_tier_analysis | BR-6 | "MidpointRounding.ToEven" | "MidpointRounding.AwayFromZero" | Rounding change (COMPOUND pt 2) | CSV-with-trailer | analyst-10 | Proofmark FAIL (combined with 11a) | NOT YET VERIFIED — code-level check pending |
| 12 | customer_attrition_signals | BR-4 | "Dormancy weight 40, Declining weight 35" | "Dormancy weight 35, Declining weight 40" | Aggregation change | Parquet | analyst-6 | Proofmark FAIL — score differences | NEUTRALIZED at FSD — architect cited V1 code (40/35), added CRITICAL NOTE |
| 13 | fee_revenue_daily | BR-2 | "filters to __maxEffectiveDate" | "filters to __maxEffectiveDate minus 1 day" | Date boundary shift | CSV | analyst-4 | Proofmark FAIL — wrong date's data | NEUTRALIZED at FSD — architect cited V1 code (current date), FSD says current date |

### Phase 1 Summary

**Result: All 7 verified mutations were neutralized at the FSD layer.** FSD architects independently cross-referenced BRD requirements against V1 source code and chose code as ground truth in every case. Multiple architects added explicit CRITICAL NOTE annotations documenting the BRD-vs-code discrepancy.

**Finding:** The pipeline has a self-correcting quality gate at the FSD layer. Architects don't blindly implement BRDs — they validate requirements against source code and reject discrepancies. This is a significant positive for the real project (ensures V2 fidelity to V1) but renders BRD-level saboteur testing ineffective.

**Decision:** Proceed to Phase 2 code-level mutations. See Protocol Departure documentation in orchestrator-observations.md.

---

## Phase 2: Code-Level Mutations (Pending — Post Phase B Re-Run)

**Status:** EXECUTED (2026-03-01). All 12 mutations planted. Build verified clean (0 errors).

**Strategy:** Reused the same mutation concepts from the Phase 1 BRD ledger, applied directly to V2 code. Since Phase 1 proved that FSD architects self-correct BRD errors by cross-referencing V1 source code, the only way to stress-test Proofmark is to sabotage the actual V2 output. These mutations make V2 produce intentionally wrong results that differ from V1 baseline.

**Skipped 2 of 13 original mutations** (#4 overdraft_recovery_rate, #10 high_balance_accounts) because the V2 implementations don't have clean code-level equivalents for those mutation types.

**Mutation type coverage:** Threshold shift: 4, Filter narrowing/expansion: 3, Rounding change: 3, Date boundary shift: 1, Join type change: 1, Aggregation change: 1. Compound mutation: 1 (wealth_tier_analysis: threshold shift + rounding change).

**Planted:** Between Phase B (Design & Implementation) and Phase C (Comparison)
**Total mutations planted:** 12 (across 11 V2 artifacts, including 1 compound mutation)
**Approach:** Reuse same mutation concepts from Phase 1 BRD saboteur, applied at V2 code level. Since FSD architects neutralized all BRD mutations by cross-referencing V1 source code, these code-level mutations make the V2 output intentionally WRONG — Proofmark must catch them.

### Skipped BRD Mutations (Not Replicable at Code Level)

| # | Job Name | Reason Skipped |
|---|----------|----------------|
| 4 | overdraft_recovery_rate | V2 SQL uses integer division — no ROUND function exists to change precision on. Mutation would require adding rounding that doesn't exist. |
| 10 | high_balance_accounts | Original mutation was stealth as_of source swap. V2 SQL pulls as_of from the same source as V1 — no clean equivalent. |

### Code Mutation Ledger

| # | Job Name | V2 Artifact | Original Code | Mutated Code | Mutation Type | Expected Detection | Actual Outcome |
|---|----------|-------------|--------------|-------------|---------------|-------------------|----------------|
| 1 | card_fraud_flags | Jobs/card_fraud_flags_v2.json | `> 500` (SQL WHERE) | `> 750` | Threshold shift | FAIL — fewer rows (txns $500-$750 excluded) | |
| 2 | investment_risk_profile | Jobs/investment_risk_profile_v2.json | `> 200000` (SQL CASE) | `> 250000` | Threshold shift | FAIL — misclassification ($200k-$250k range) | |
| 3 | compliance_open_items | Jobs/compliance_open_items_v2.json | `IN ('Open', 'Escalated')` (SQL WHERE) | `= 'Open'` | Filter narrowing | FAIL — fewer rows (Escalated excluded) | |
| 5 | marketing_eligible_customers | ExternalModules/MarketingEligibleCustomersV2Processor.cs | HashSet: EMAIL, SMS, PUSH_NOTIFICATIONS | HashSet: EMAIL, SMS (removed PUSH_NOTIFICATIONS) | Filter narrowing | FAIL — more rows (less restrictive, 2 of 3 channels) | |
| 6 | customer_value_score | Jobs/customer_value_score_v2.json | `ROUND(..., 2)` on all 4 score columns | `ROUND(..., 0)` | Rounding change | FAIL — all scores truncated to integers | |
| 7 | covered_transactions | ExternalModules/CoveredTransactionsV2Processor.cs | `== CoveredAccountType` (Checking only) | `== CoveredAccountType \|\| == "Savings"` | Filter expansion | FAIL — more rows (Savings accounts included) | |
| 8 | branch_visit_summary | Jobs/branch_visit_summary_v2.json | `JOIN branches b ON` (SQL) | `LEFT JOIN branches b ON` | Join type change | FAIL or PASS (data-dependent: only differs if branch_visits has orphan branch_ids) | |
| 9 | loan_risk_assessment | Jobs/loan_risk_assessment_v2.json | `>= 750` (SQL CASE, Low Risk threshold) | `>= 700` | Threshold shift | FAIL — tier reclassification for scores 700-749 | |
| 11a | wealth_tier_analysis | Jobs/wealth_tier_analysis_v2.json | `< 10000` (Bronze tier ceiling) | `< 25000` | Threshold shift (COMPOUND pt 1) | FAIL — tier redistribution ($10k-$25k customers shift Bronze→Silver) | |
| 11b | wealth_tier_analysis | Jobs/wealth_tier_analysis_v2.json | `ROUND(..., 2)` on total_wealth, avg_wealth, pct_of_customers | `ROUND(..., 0)` | Rounding change (COMPOUND pt 2) | FAIL — values rounded to integers | |
| 12 | customer_attrition_signals | ExternalModules/CustomerAttritionSignalsV2Processor.cs | DormancyWeight=40.0, DecliningTxnWeight=35.0 | DormancyWeight=35.0, DecliningTxnWeight=40.0 (swapped) | Aggregation change | FAIL — attrition scores differ for customers with mixed factors | |
| 13 | fee_revenue_daily | ExternalModules/FeeRevenueDailyV2Processor.cs | `maxDate.ToString("yyyy-MM-dd")` | `maxDate.AddDays(-1).ToString("yyyy-MM-dd")` | Date boundary shift | FAIL — effective_date off by one day, wrong date's fee data | |
