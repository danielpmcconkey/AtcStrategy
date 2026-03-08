# POC 3 Step 1c — Adversarial Portfolio Audit

**Date:** 2026-02-28
**Status:** Step 1c declared complete by adversarial auditor.

## Auditor Scope

Evaluate whether the 70-job ETL portfolio is sufficient to challenge Step 3 reverse-engineering agents. Not evaluating the overall POC, Proofmark, the Saboteur, or scaling concerns.

## Verdicts

### 1. Variety — Sufficient

- Aggregation, filtering, joins, lookups, classification, time-window logic, composite scoring, O(n²) pattern matching
- Success on simple grouping jobs teaches nothing about boundary logic or transfer detection
- Patterns span SQL-only (23 jobs), simple External (20+), complex External (~20), direct file writers (8)

### 2. Anti-Pattern Coverage — Sufficient

- All 10 categories (AP1-AP10) distributed across 70 jobs
- Meaningful interaction effects (e.g., W4+W5 in OverdraftRecoveryRate: integer division → 0, then banker's rounding on 0)
- Agents cannot apply a single cleanup template across all jobs
- AP4 (unused columns) is uniform in detection method but realistic
- AP9 (misleading names) thin at 2 jobs — acknowledged, not disqualifying

### 3. Wrinkle Difficulty — Sufficient with caveats

**Genuine challenges (will cause Proofmark failures):**
- W3a/b/c boundary rows (weekly/monthly/quarterly aggregates appended on specific dates)
- W4+W5 combos (integer division + banker's rounding)
- W7 trailer inflation (input row count vs output row count)
- W12 header re-emit (header on every append)
- W6 epsilon drift (double vs decimal accumulation)

**Moderate:**
- W2 weekend fallback, W1 Sunday skip, W9 wrong writeMode

**Trivial:**
- W10 absurd numParts, W8 stale trailer date

**A naive SQL-first approach would fail Proofmark on ~30-40 of 70 jobs.**

### 4. Edge Cases — Sufficient

- Oct-Dec window: 13 Sundays, 3 month-ends, 1 quarter-end (Oct 31)
- Weekend handling inconsistent by design (3 skip, 10 fallback, others run normally)
- Empty data days produce empty files (header + trailer), not missing files
- Forces per-job analysis — no uniform weekend assumption works

### 5. Volume & Domain Spread — Sufficient

- 70 jobs, 7 domains, balanced format mix (25 Parquet, 23 CSV, 22 CSV+Trailer)
- 47 External module, 23 SQL-only, 8 direct file writers
- Cross-domain analytics (#51-60) forces multi-source reasoning
- Credible for CIO presentation

## Acknowledged Limitations (not blockers)

- W3c (quarterly boundary) on only 1 job — defensible, only 1 quarter-end in window
- AP9 (misleading names) only 2 instances
- No Parquet-specific output wrinkles — CSV carries format trap burden
- Source data clean by design — POC tests bad code reasoning, not bad data handling
- No timezone, encoding, or schema evolution wrinkles — out of scope for mock environment

## Manifest Bookkeeping (from first auditor)

- W5 count says 8 but lists 9 jobs — fix
- W9 count says 5 but lists 6 jobs — fix
- Date format inconsistency (DateOnly → M/d/yyyy vs yyyy-MM-dd) is unlabeled but real
