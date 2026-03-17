# Ogre State Machine — Transition Table

The Ogre engine is a deterministic state machine. Every job enters at `LocateOgSourceFiles` and either exits at `COMPLETE` or `DEAD_LETTER`. There is no LLM in the control loop — the orchestrator simply looks up `(current_node, outcome)` in this table to determine the next node.

---

## Happy Path

A job that passes every gate on the first try follows this sequence:

| # | Node | Stage | Type | Model | On Success/Approve |
|---|------|-------|------|-------|--------------------|
| 1 | LocateOgSourceFiles | Plan | Work | Sonnet | → InventoryOutputs |
| 2 | InventoryOutputs | Plan | Work | Sonnet | → InventoryDataSources |
| 3 | InventoryDataSources | Plan | Work | Sonnet | → NoteDependencies |
| 4 | NoteDependencies | Plan | Work | Sonnet | → WriteBrd |
| 5 | WriteBrd | Define | Work | **Opus** | → ReviewBrd |
| 6 | ReviewBrd | Define | Review | **Opus** | → WriteBddTestArch |
| 7 | WriteBddTestArch | Design | Work | **Opus** | → ReviewBdd |
| 8 | ReviewBdd | Design | Review | **Opus** | → WriteFsd |
| 9 | WriteFsd | Design | Work | **Opus** | → ReviewFsd |
| 10 | ReviewFsd | Design | Review | **Opus** | → BuildJobArtifacts |
| 11 | BuildJobArtifacts | Build | Work | Sonnet | → ReviewJobArtifacts |
| 12 | ReviewJobArtifacts | Build | Review | **Opus** | → BuildProofmarkConfig |
| 13 | BuildProofmarkConfig | Build | Work | Sonnet | → ReviewProofmarkConfig |
| 14 | ReviewProofmarkConfig | Build | Review | Sonnet | → BuildUnitTests |
| 15 | BuildUnitTests | Build | Work | Sonnet | → ReviewUnitTests |
| 16 | ReviewUnitTests | Build | Review | Sonnet | → ExecuteUnitTests |
| 17 | ExecuteUnitTests | Build | Work | Sonnet | → Publish |
| 18 | Publish | Build | Work | Sonnet | → ExecuteJobRuns |
| 19 | ExecuteJobRuns | Validate | Work | Sonnet | → ExecuteProofmark |
| 20 | ExecuteProofmark | Validate | Work | Sonnet | → FBR_EvidenceAudit |
| 21 | FBR_EvidenceAudit | Validate | Review | **Opus** | → **COMPLETE** |

---

## Review Branching

Review nodes are adversarial gates. They can approve, conditionally approve, or reject. Each review node has a paired **response node** (which addresses the reviewer's feedback) and a **rewind target** (which starts the work over from scratch).

| Review Node | Response Node | Rewind Target |
|-------------|---------------|---------------|
| ReviewBrd | WriteBrdResponse (Opus) | WriteBrd |
| ReviewBdd | WriteBddResponse (Opus) | WriteBddTestArch |
| ReviewFsd | WriteFsdResponse (Opus) | WriteFsd |
| ReviewJobArtifacts | BuildJobArtifactsResponse (Sonnet) | BuildJobArtifacts |
| ReviewProofmarkConfig | BuildProofmarkResponse (Sonnet) | BuildProofmarkConfig |
| ReviewUnitTests | BuildUnitTestsResponse (Sonnet) | BuildUnitTests |

### How review outcomes route:

```
APPROVE      → next node on the happy path (see table above)
CONDITIONAL  → response node (address specific feedback, then re-submit to same reviewer)
FAIL         → rewind target (start the work node over from scratch)
```

When the response node completes successfully, it routes back to the same review node for re-evaluation. If the response node itself fails, it also rewinds to the rewind target.

### Counter escalation:

Each review node tracks a **conditional counter** (per node, per job). If a review node issues CONDITIONAL too many times (default: 3), the engine escalates to FAIL. If the **main retry counter** (per job) exceeds its limit (default: 5), the job is DEAD_LETTERed.

---

## Terminal Gate — FBR_EvidenceAudit (Pat)

The final gate is different from the other review nodes. Pat is the auditor — he assumes the RE team didn't do their job right and inspects traceability across all artifacts.

```
APPROVE      → COMPLETE
CONDITIONAL  → PatFix (auto-remediate documentation/test drift)
FAIL         → DEAD_LETTER (no retry, no rewind — it's a human problem)
```

### PatFix

PatFix is a work node that mechanically addresses Pat's conditional findings — FSD updates, test rewrites, re-running the job through the framework, re-running Proofmark. It does not get re-reviewed by Pat (the conditions are specific and mechanical).

```
PatFix SUCCESS  → COMPLETE
PatFix FAIL     → DEAD_LETTER
```

---

## Triage

When `ExecuteProofmark` fails (RE output doesn't match OG output), the job enters triage. Triage is an autonomous node — it manages its own sub-agents internally:

1. **RCA** (Root Cause Analysis) — Opus model. Diagnoses why the output doesn't match.
2. **Fix** — Sonnet model. Applies code/config corrections.
3. **Reset** — Sonnet model. Rewinds job state to re-enter the pipeline at the appropriate node.

```
ExecuteProofmark FAILURE → Triage
```

Triage directly manipulates job state in the database. The engine fires it and walks away. After triage completes, the job re-enters the happy path at whatever node triage's Reset agent determined was appropriate.

---

## Work Node Self-Retry

Any work node (happy path or response) that doesn't have an explicit FAIL edge gets a **self-retry** — on failure, the same node runs again. The main retry counter increments each time. Terminal fail nodes (FBR_EvidenceAudit, PatFix) are excluded from self-retry.

---

## Full Transition Map

For reference, every edge in the state machine:

| From | Outcome | To |
|------|---------|----|
| LocateOgSourceFiles | SUCCESS | InventoryOutputs |
| LocateOgSourceFiles | FAIL | LocateOgSourceFiles (self-retry) |
| InventoryOutputs | SUCCESS | InventoryDataSources |
| InventoryOutputs | FAIL | InventoryOutputs (self-retry) |
| InventoryDataSources | SUCCESS | NoteDependencies |
| InventoryDataSources | FAIL | InventoryDataSources (self-retry) |
| NoteDependencies | SUCCESS | WriteBrd |
| NoteDependencies | FAIL | NoteDependencies (self-retry) |
| WriteBrd | SUCCESS | ReviewBrd |
| WriteBrd | FAIL | WriteBrd (self-retry) |
| ReviewBrd | APPROVE | WriteBddTestArch |
| ReviewBrd | CONDITIONAL | WriteBrdResponse |
| ReviewBrd | FAIL | WriteBrd |
| WriteBrdResponse | SUCCESS | ReviewBrd |
| WriteBrdResponse | FAILURE | WriteBrd |
| WriteBddTestArch | SUCCESS | ReviewBdd |
| WriteBddTestArch | FAIL | WriteBddTestArch (self-retry) |
| ReviewBdd | APPROVE | WriteFsd |
| ReviewBdd | CONDITIONAL | WriteBddResponse |
| ReviewBdd | FAIL | WriteBddTestArch |
| WriteBddResponse | SUCCESS | ReviewBdd |
| WriteBddResponse | FAILURE | WriteBddTestArch |
| WriteFsd | SUCCESS | ReviewFsd |
| WriteFsd | FAIL | WriteFsd (self-retry) |
| ReviewFsd | APPROVE | BuildJobArtifacts |
| ReviewFsd | CONDITIONAL | WriteFsdResponse |
| ReviewFsd | FAIL | WriteFsd |
| WriteFsdResponse | SUCCESS | ReviewFsd |
| WriteFsdResponse | FAILURE | WriteFsd |
| BuildJobArtifacts | SUCCESS | ReviewJobArtifacts |
| BuildJobArtifacts | FAIL | BuildJobArtifacts (self-retry) |
| ReviewJobArtifacts | APPROVE | BuildProofmarkConfig |
| ReviewJobArtifacts | CONDITIONAL | BuildJobArtifactsResponse |
| ReviewJobArtifacts | FAIL | BuildJobArtifacts |
| BuildJobArtifactsResponse | SUCCESS | ReviewJobArtifacts |
| BuildJobArtifactsResponse | FAILURE | BuildJobArtifacts |
| BuildProofmarkConfig | SUCCESS | ReviewProofmarkConfig |
| BuildProofmarkConfig | FAIL | BuildProofmarkConfig (self-retry) |
| ReviewProofmarkConfig | APPROVE | BuildUnitTests |
| ReviewProofmarkConfig | CONDITIONAL | BuildProofmarkResponse |
| ReviewProofmarkConfig | FAIL | BuildProofmarkConfig |
| BuildProofmarkResponse | SUCCESS | ReviewProofmarkConfig |
| BuildProofmarkResponse | FAILURE | BuildProofmarkConfig |
| BuildUnitTests | SUCCESS | ReviewUnitTests |
| BuildUnitTests | FAIL | BuildUnitTests (self-retry) |
| ReviewUnitTests | APPROVE | ExecuteUnitTests |
| ReviewUnitTests | CONDITIONAL | BuildUnitTestsResponse |
| ReviewUnitTests | FAIL | BuildUnitTests |
| BuildUnitTestsResponse | SUCCESS | ReviewUnitTests |
| BuildUnitTestsResponse | FAILURE | BuildUnitTests |
| ExecuteUnitTests | SUCCESS | Publish |
| ExecuteUnitTests | FAIL | ExecuteUnitTests (self-retry) |
| Publish | SUCCESS | ExecuteJobRuns |
| Publish | FAIL | Publish (self-retry) |
| ExecuteJobRuns | SUCCESS | ExecuteProofmark |
| ExecuteJobRuns | FAIL | ExecuteJobRuns (self-retry) |
| ExecuteProofmark | SUCCESS | FBR_EvidenceAudit |
| ExecuteProofmark | FAILURE | Triage |
| FBR_EvidenceAudit | APPROVE | **COMPLETE** |
| FBR_EvidenceAudit | CONDITIONAL | PatFix |
| FBR_EvidenceAudit | FAIL | **DEAD_LETTER** |
| PatFix | SUCCESS | **COMPLETE** |
| PatFix | FAIL | **DEAD_LETTER** |
