# Saboteur Ledger

**Created:** 2026-03-01
**Phase:** Between Phase A (Analysis) and Phase B (Design & Implementation)
**Total mutations planted:** 13 (including 1 compound)

## Constraint Verification

- **Per output type:** Parquet: 4, CSV: 6, CSV-with-trailer: 3 — all >= 2
- **Per analyst batch:** analyst-1: 1, analyst-2: 1, analyst-3: 1, analyst-4: 2, analyst-5: 1, analyst-6: 2, analyst-7: 1, analyst-8: 1, analyst-9: 1, analyst-10: 2 — all <= 2
- **Mutation type diversity:** Threshold shift: 3, Filter narrowing: 3, Rounding change: 3, Date boundary shift: 2, Join type change: 1, Aggregation change: 1 — no type exceeds 3
- **Compound mutations:** 1 (wealth_tier_analysis: threshold shift + rounding change)

## Ledger

| # | Job Name | BRD Section | Original Text | Mutated Text | Mutation Type | Output Type | Analyst | Expected Detection | Actual Outcome |
|---|----------|-------------|---------------|-------------|---------------|-------------|---------|-------------------|----------------|
| 1 | card_fraud_flags | BR-2, BR-3 | "amount > $500 (strictly greater than, not >=)" / "$500 threshold is a hardcoded magic value" | "amount > $750 (strictly greater than, not >=)" / "$750 threshold is a hardcoded magic value" | Threshold shift | CSV | analyst-1 | Proofmark FAIL — fewer rows in V2 (higher threshold excludes transactions between $500-$750) | |
| 2 | investment_risk_profile | BR-2 | "current_value > 200000 → High Value" | "current_value > 250000 → High Value" | Threshold shift | CSV | analyst-2 | Proofmark FAIL — investments between $200k-$250k misclassified as "Medium Value" instead of "High Value" | |
| 3 | compliance_open_items | BR-1 | "status = 'Open' or status = 'Escalated'" | "status = 'Open'" | Filter narrowing | Parquet | analyst-3 | Proofmark FAIL — fewer rows (Escalated events excluded), row count mismatch | |
| 4 | overdraft_recovery_rate | BR-3 | "rounded to 4 decimal places" / "Math.Round(recoveryRate, 4, MidpointRounding.ToEven)" | "rounded to 2 decimal places" / "Math.Round(recoveryRate, 2, MidpointRounding.ToEven)" | Rounding change | CSV-with-trailer | analyst-4 | Proofmark PASS (likely) — integer division makes recovery_rate always 0, so 4-decimal vs 2-decimal rounding on 0 produces the same result. This is a STEALTH mutation designed to test whether the system catches the intent mismatch even when output matches. | |
| 5 | marketing_eligible_customers | BR-1 | "ALL three required channels: MARKETING_EMAIL, MARKETING_SMS, and PUSH_NOTIFICATIONS" | "BOTH required channels: MARKETING_EMAIL and MARKETING_SMS" | Filter narrowing | CSV | analyst-5 | Proofmark FAIL — more rows in V2 (2-channel requirement is less restrictive than 3-channel, so more customers qualify) | |
| 6 | customer_value_score | BR-7 | "rounded to 2 decimal places using Math.Round" / "Math.Round(..., 2)" | "rounded to the nearest whole number (0 decimal places) using Math.Round" / "Math.Round(..., 0)" | Rounding change | CSV | analyst-6 | Proofmark FAIL — score values will differ (e.g., 456.78 vs 457) across all four score columns | |
| 7 | covered_transactions | BR-1 | "Only transactions linked to Checking accounts are included" / "account_type == 'Checking'" | "Only transactions linked to Checking or Savings accounts are included" / "account_type == 'Checking' \|\| account_type == 'Savings'" | Filter narrowing | Parquet | analyst-7 | Proofmark FAIL — more rows in V2 (Savings account transactions added), row count and content mismatch | |
| 8 | branch_visit_summary | BR-2 | "JOIN branches b ON vc.branch_id = b.branch_id AND vc.as_of = b.as_of" | "LEFT JOIN branches b ON vc.branch_id = b.branch_id AND vc.as_of = b.as_of" | Join type change | CSV-with-trailer | analyst-8 | Proofmark FAIL (if branch_ids exist in visits but not branches) or PASS (if all visited branch_ids exist in branches table). Detection depends on data — may be a stealth mutation if join is effectively complete. | |
| 9 | loan_risk_assessment | BR-2 | "avg_credit_score >= 750 → Low Risk" | "avg_credit_score >= 700 → Low Risk" | Threshold shift | Parquet | analyst-9 | Proofmark FAIL — customers with avg scores 700-749 misclassified as "Low Risk" instead of "Medium Risk" | |
| 10 | high_balance_accounts | BR-6 | "The as_of value comes from the account row" / '["as_of"] = acctRow["as_of"]' | "The as_of value is set to __maxEffectiveDate from shared state" / '["as_of"] = sharedState["__maxEffectiveDate"]' | Date boundary shift | CSV | analyst-10 | Proofmark FAIL (if multi-date range) or PASS (if single-day run where account as_of == maxEffectiveDate). In single-day gap-fill mode, account rows likely have as_of matching the effective date, making this a stealth mutation. | |
| 11a | wealth_tier_analysis | BR-2 | "Bronze: wealth < $10,000 / Silver: $10,000 <= wealth < $100,000" | "Bronze: wealth < $25,000 / Silver: $25,000 <= wealth < $100,000" | Threshold shift (COMPOUND part 1) | CSV-with-trailer | analyst-10 | Proofmark FAIL — customers with wealth $10k-$25k shifted from Silver to Bronze, changing customer_count, total_wealth, avg_wealth, and pct_of_customers for both tiers | |
| 11b | wealth_tier_analysis | BR-6 | "banker's rounding (MidpointRounding.ToEven)" for pct_of_customers | "standard rounding (MidpointRounding.AwayFromZero)" for pct_of_customers | Rounding change (COMPOUND part 2) | CSV-with-trailer | analyst-10 | Proofmark FAIL (combined with 11a) — different rounding mode for percentage values, though effect may be subtle if no midpoint values arise | |
| 12 | customer_attrition_signals | BR-4 | "Dormancy factor (weight 40) ... Declining transaction factor (weight 35)" | "Dormancy factor (weight 35) ... Declining transaction factor (weight 40)" | Aggregation change | Parquet | analyst-6 | Proofmark FAIL — attrition scores differ for customers where exactly one of dormancy/declining factors triggers. Customers with only dormancy get 35 instead of 40; customers with only declining txns get 40 instead of 35. Risk level thresholds unchanged, so some customers may cross the 40 or 75 boundary differently. | |
| 13 | fee_revenue_daily | BR-2 | "filters to current effective date (__maxEffectiveDate)" / "maxDate.ToString('yyyy-MM-dd')" | "filters to prior business day (__maxEffectiveDate minus 1 day)" / "maxDate.AddDays(-1).ToString('yyyy-MM-dd')" | Date boundary shift | CSV | analyst-4 | Proofmark FAIL — V2 will show previous day's fee data instead of current day's. Different row values for charged_fees, waived_fees, net_revenue. | |

## Detection Risk Assessment

**High confidence detection (9 mutations):**
- #1 card_fraud_flags — threshold change reduces output rows
- #3 compliance_open_items — filter narrowing drops Escalated rows
- #5 marketing_eligible_customers — fewer required channels means MORE qualifying customers
- #6 customer_value_score — whole-number rounding changes every score value
- #7 covered_transactions — Savings accounts add rows
- #9 loan_risk_assessment — tier reclassification for 700-749 range
- #11a wealth_tier_analysis — tier boundary shift redistributes customers
- #12 customer_attrition_signals — weight swap changes individual scores
- #13 fee_revenue_daily — wrong date means wrong data entirely

**Medium confidence detection (2 mutations):**
- #2 investment_risk_profile — depends on whether any investments have current_value between $200k-$250k
- #8 branch_visit_summary — LEFT vs INNER JOIN only differs if orphan branch_ids exist in visits

**Low confidence / Stealth mutations (2 mutations):**
- #4 overdraft_recovery_rate — integer division bug makes recovery_rate always 0 regardless of rounding precision; output may be identical
- #10 high_balance_accounts — in single-day execution, account as_of likely equals maxEffectiveDate; output may be identical

## Notes

- Stealth mutations (#4 and #10) are deliberately included to test whether the system catches mutations that don't affect output. If Proofmark passes these, the resolution agent should NOT flag them — the sabotage is only detectable by comparing the BRD text to the V1 source code, not by comparing V1 vs V2 output.
- The compound mutation (#11a + #11b) tests whether two simultaneous changes in the same BRD are both caught or whether only the more obvious one (threshold shift) masks the subtler one (rounding mode).
