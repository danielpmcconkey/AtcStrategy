# POC4 Look-Forward — What We're Doing Differently

Concrete process changes for POC4, derived from POC3 failures and the generic agent lessons learned (`ai-dev-playbook/Tooling/agent-lessons-learned.md`). Each item is a specific change to how POC4 will operate, not a restatement of the lesson — the generic doc has the "why," this doc has the "so what."

---

## Blueprint & Governance Structure

### Split the monolithic blueprint
**From lesson:** Monolithic Blueprint Tax, Standing Orders Decay Over Long Runs

POC3's BLUEPRINT.md was ~550 lines covering all 5 phases. Governance instructions at line 77 were dead letters by the time the agent reached line 211. POC4 blueprint structure:

- `BLUEPRINT.md` — mission, rules, protocols that apply to all phases (~100 lines max)
- `PHASE_A.md` through `PHASE_E.md` — per-phase instructions loaded on demand
- Governance checks duplicated at every decision point within each phase doc, not just at the top

### Governance checks at decision points, not document headers
**From lesson:** Standing Orders Decay, Context Degradation Not Recoverable

Every "spawn agents" or "start batch" step in every phase doc must have an inline pre-flight checklist:

```
[ ] CLUTCH file absent
[ ] Concurrency cap not exceeded (≤10 subagents)
[ ] Previous batch complete
[ ] Session health self-check
```

Don't reference "see standing orders in Section 1." Put the checklist right there.

### Dual-document update mandate
**From lesson:** Dual-Document Drift

The orchestrator runbook and the worker blueprint are a coupled pair. Any edit to one requires an explicit check: "Does the other document describe this same concern?" If yes, update both in the same commit. Blueprint update PRs must touch both files or include a note explaining why only one changed.

---

## Phase A — Analysis & BRD Production

### First-BRD gate before batch execution
**From lesson:** Batch Error Propagation, Inference Shortcutting

Every analyst submits their FIRST BRD and waits for review feedback before proceeding with their batch. This catches systematic misunderstandings (like the CsvFileWriter header-in-append fiasco) before they propagate across 10+ BRDs.

### Shared errata file
**From lesson:** No Cross-Agent Learning

Reviewers maintain `POC4/logs/errata.md`. When they catch a systematic error, they append a one-liner: "CsvFileWriter suppresses headers in Append mode — see CsvFileWriter.cs:47." All analysts check errata before submitting each BRD. Nearly free, prevents the same mistake from hitting multiple analysts.

### Pre-analysis framework deep-read
**From lesson:** Inference Shortcutting

All analysts read the actual module source code (not just Architecture.md) before starting domain work. Blueprint instruction: "Read the job config AND the module source code to verify actual behavior. Config describes what is configured, not how it behaves."

### Source-of-truth job inventory from day 1
**From lesson:** Silent Inventory Drift (POC3 Design Decision #26)

Before any agent touches any job, query `control.jobs` and write the canonical job list to a manifest file. This is a living checklist, not a one-time count:

| Job Name | BRD | Review | FSD | V2 Code | Registered | Baseline | V2 Run | Proofmark | Resolution |
|----------|-----|--------|-----|---------|------------|----------|--------|-----------|------------|

Any unchecked box at a phase gate is a hard stop. Agent-reported counts are convenient but untrustworthy. Name-level verification, not count comparison.

### Evidence citation spot-checks
**From lesson:** Evidence Fabrication / Hallucinated Citations

Reviewers verify 3-5 random citations per BRD. All citations must use `file:line` format so they're mechanically verifiable.

---

## Phase B — FSD & V2 Implementation

### Anti-pattern correction mandate from launch
**From lesson:** Agents Reproduce Anti-Patterns (POC3 Decision #20, also POC2 Run 1)

This was learned in POC2, forgotten in POC3, and re-learned after a failed run. Never again. The Phase B instructions must include before the first agent launches:

1. Explicit dual mandate: "output equivalence AND anti-pattern elimination"
2. Reference to `KNOWN_ANTI_PATTERNS.md` with standardized codes
3. Module hierarchy: Tier 1 (framework-only) → Tier 2 (scalpel External) → Tier 3 (full External, last resort)
4. Clean code requirement for all External modules regardless of tier

Pre-launch checklist item: "Does PHASE_B.md contain the anti-pattern correction mandate? If not, stop."

### Parquet schema specification as mandatory FSD artifact
**From lesson:** POC3 rearchitect (2026-03-02), proofmark spot-check failure on `card_status_snapshot`

The `ParquetFileWriter` infers column types from data at write time. When rows are partitioned, different parts can get different type inferences (int64 in part 0, string in part 3 because all nulls). POC3 fixed per-run consistency (infer once from all rows), but cross-run consistency still depends on data distribution.

**POC4 process change:** Every Parquet-output job's FSD must include a **Parquet Schema Specification**:

| Column | Parquet Type | Nullable | Source |
|--------|-------------|----------|--------|
| card_count | int64 | yes | V1 output inspection, datalake.cards DDL |

- Types are design decisions, not runtime observations
- V2 code passes the schema to the writer explicitly, no inference
- Phase B reviewers verify the spec against both BRD field definitions and actual V1 output samples
- Any V1 schema inconsistency (like the int64/string split) gets documented as a known V1 defect in the BRD

**Framework change required:** `ParquetFileWriter` should accept an optional schema override parameter. When provided, use specified types. When absent, fall back to inference (backward compat).

### Batched execution with forced context refresh
**From lesson:** Context Degradation, Standing Orders Decay (POC3 Decision #24)

Batches of ≤20 jobs. At each batch boundary, the agent must:

1. Check for CLUTCH file
2. Run `dotnet build`
3. Re-read governance sections of the phase doc
4. Update `session_state.md`
5. Verify concurrency cap (≤10 subagents)

### Serialized build verification
**From lesson:** Host Resource Saturation from Parallel Builds

Agents write code only during Phase B. Compilation verification happens at batch boundaries (one build, not N concurrent builds). No `dotnet build` inside parallel subagents.

### Standardized taxonomy from day 1
**From lesson:** Emergent Taxonomy Divergence

Provide `KNOWN_ANTI_PATTERNS.md` with standardized codes upfront. If agents discover new patterns, they register them in a shared taxonomy file before using them. Reviewers enforce taxonomy compliance.

---

## Phase C — Setup & Baseline

### Commands must encode their own constraints
**From lesson:** Blueprints Must Constrain Runtime Boundaries

POC3's C.6 said "run for date range 2024-10-01 through 2024-12-31" but the command was unconstrained `dotnet run --project JobExecutor` which auto-advanced to today. The command won; the prose lost.

POC4: every command in every phase doc must enforce its own boundaries. Use explicit date loops or the `--service` queue executor with a bounded queue population. No unconstrained auto-advance.

### Explicit V1/V2 activation management
**From lesson:** Blueprint Steps Have Implicit Dependencies

V2 jobs must be deactivated before V1 baseline runs. V1 jobs must be deactivated before V2 runs. This must be an explicit step in the phase doc, not something the agent figures out on its own.

### Use the queue executor
**From lesson:** POC3 framework rearchitect

`dotnet run --project JobExecutor -- --service` with a pre-populated `control.task_queue`. 17x speedup over individual invocations. Eliminates the per-date shell loop entirely. Populate the queue with the exact date range and job set needed, then fire once.

---

## Phase D — Comparison & Resolution

### Saboteur targets code, not BRDs
**From lesson:** FSD Architects Self-Correct Against Source Code (POC3 Decision #21)

BRD-level mutations were proven ineffective — architects independently validate against V1 source and correct discrepancies before they reach implementation. POC4 saboteur plants mutations in V2 code after Phase B, directly targeting Proofmark and the resolution loop.

### Resolution evidence requirement
**From lesson:** POC3 Decision #13

Every resolution must cite specific V1 ground-truth evidence. A fix that makes Proofmark pass without explaining WHY the mismatch existed is not accepted.

### Changes flow uphill
**From lesson:** POC3 Decision #14

Any resolution that modifies V2 code must update all upstream documents (FSD, BRD, test plan) to maintain consistency. Phase D.6 consistency verification checks this.

---

## Operational Model

### Prefer session restarts over session continuations
**From lesson:** Context Degradation Not Recoverable In-Session

Don't try to rehab a cooked agent. Kill it and start fresh with a resurrection file. A new session with clean governance context is always cheaper than arguing with a saturated agent. Build session_state.md writes into every batch boundary protocol.

### Dynamic agent rebalancing
**From lesson:** Reviewer Bottleneck

Don't hard-code analyst:reviewer ratios. Give the lead a total agent budget and let it redistribute based on observed throughput. When analysts finish their batch, idle agents become additional reviewers.

### Smoke test cleanup
**From lesson:** Smoke Test Artifacts Contaminate Evaluation

After pre-launch smoke testing, delete all V2 artifacts before launching agents. Or use a throwaway job name that doesn't collide with real jobs.

### Pre-launch checklist (mechanical, not memory-based)
**From lesson:** Anti-Pattern Correction (learned in POC2, forgotten in POC3)

A pre-launch checklist that verifies the blueprint contains every required instruction. Lessons learned that aren't mechanically enforced will be re-learned. The checklist is not "did you think about X?" — it's "does PHASE_B.md contain the string 'KNOWN_ANTI_PATTERNS.md'? grep it."

---

*This document is the POC4 action plan. The generic lessons with full context and examples live in `ai-dev-playbook/Tooling/agent-lessons-learned.md`. Read that for the "why." Read this for the "what we're actually doing about it."*
