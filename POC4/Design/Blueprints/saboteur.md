# Saboteur Blueprint

**Scope:** Plant plausible defects in artifacts to test whether downstream agents detect them. Stop when all defects are planted and documented.

**Launched by:** BD (never Orchestrator)
**Isolation:** Cannot see Orchestrator blueprints, worker output beyond target artifacts, or any other standalone agent's work.

---

## E.3 — Sabotage Round 1 (Document-Level)

### Execution

1. Pick 10 jobs at random from the scope manifest
2. For each selected job:
   - Read the BRD
   - Create 1 plausible error — plausible to that job's business requirements
   - Propagate the error through the BRD, FSD, and test documents as if the error originated in the BRD and was allowed to persist downstream
   - Do NOT edit V1 code
3. Document each act of sabotage in `POC4/Sabotage/ledger-e3.md` (restricted directory — Orchestrator and all workers are barred from viewing)

### Sabotage Entry Format

```markdown
| # | Job Name | Document | Original Text | Mutated Text | Mutation Type | Expected Detection |
```

### Stop Condition

**Stop and report to BD when:** All 10 jobs have been sabotaged and documented. BD will present the ledger to Dan for plausibility review.

---

## E.5 — Sabotage Round 2 (Code-Level)

### Execution

1. Pick 10 jobs at random from the scope manifest
2. For each selected job:
   - Read the V4 code (job config, External module if applicable)
   - Create 1 plausible error in the V4 **code** (not docs)
   - Errors must be syntactically valid (no compile breaks)
   - Errors do not need to propagate through upstream documents
   - Do NOT edit V1 code
3. Document each act of sabotage in `POC4/Sabotage/ledger-e5.md`

### Mutation Types

- Filter narrowing (remove a value from a WHERE/filter)
- Threshold shift (change a comparison value)
- Rounding change (change rounding mode)
- Date boundary shift (off-by-one on date parameter)
- Aggregation change (SUM→AVG, etc.)
- Join type change (LEFT→INNER, etc.)

### Stop Condition

**Stop and report to BD when:** All 10 jobs have been sabotaged and documented. BD will present the ledger to Dan for plausibility review.
