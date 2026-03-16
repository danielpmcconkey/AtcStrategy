# Session 22: Remove FBR Gates (19-24)

## Decision

Cut FBR_BrdCheck, FBR_BddCheck, FBR_FsdCheck, FBR_ArtifactCheck, FBR_ProofmarkCheck,
FBR_UnitTestCheck from the happy path. Flow goes Publish -> ExecuteJobRuns.

## Reasoning

The FBR gates were conflating four concerns:

- **Quality** (does it meet standards?) — already handled by in-flow reviews (nodes 6, 8, 10, 12, 14, 16). Rewind is cheap there (one node back).
- **Accuracy** (are the things it says correct?) — proven empirically by proofmark. No amount of document squinting replaces execution data.
- **Completeness** (all use cases captured, sufficient evidence/traceability?) — proven by proofmark coverage and the terminal evidence audit (FBR_EvidenceAudit, node 28).
- **Assuredness** (safe to proceed?) — can't be controlled by gates. Comes from watching the system run uninterrupted.

FBR gates were Sonnet making judgment calls about document consistency without execution data. When they fired (often on false positives or misattributed faults), they rewound 10-17 nodes, destroyed all downstream artifacts, and burned hours of rework. Job 9 went through 3 full laps because FBR_BddCheck kept blaming the BDD spec for missing unit tests — wrong artifact, wrong diagnosis.

The original motivation was anti-cheating (earlier POCs had agents gaming the system). Network isolation and narrow agent scope solved that architecturally. The belt works; the suspenders are strangling us.

## What Stays

- In-flow reviews (6 review nodes) — quality gate, cheap rewind
- FBR_EvidenceAudit (node 28) — terminal gate, completeness/traceability
- ExecuteProofmark + triage pipeline — accuracy gate, empirical
- FinalSignOff — assuredness checkpoint

## Implementation

Remove nodes 19-24 from HAPPY_PATH and FBR_ROUTING in transitions.py.
Remove associated FBR blueprints from agent dispatch (or leave them — they just won't be called).
