# Per-Node Model Map — Agreed Session 20

Decided in session 20. Dan proposed initial assignments, BD pressure-tested
against actual blueprint complexity. This is the agreed version.

## Implementation

Add a `MODEL_MAP: dict[str, str]` to the engine. `StepHandler` looks up the
node's model from the map, falling back to `config.agent_model` if unmapped.

## Happy Path (28 nodes)

```
 #   Node                      Model     Rationale
──   ────                      ─────     ─────────
 1   LocateOgSourceFiles       Sonnet    file cataloging
 2   InventoryOutputs          Sonnet    data inventory
 3   InventoryDataSources      Sonnet    data inventory
 4   NoteDependencies          Sonnet    dependency analysis
 5   WriteBrd                  Opus      hardest spec work, anti-pattern analysis
 6   ReviewBrd                 Opus      adversarial evidence verification
 7   WriteBddTestArch          Opus      spec work, cascading impact downstream
 8   ReviewBdd                 Opus      anti-pattern judgment in test design
 9   WriteFsd                  Opus      hardest design work, remediation decisions
10   ReviewFsd                 Opus      adversarial spec verification
11   BuildJobArtifacts         Sonnet    faithful implementation from detailed FSD
12   ReviewJobArtifacts        Opus      code-vs-spec judgment
13   BuildProofmarkConfig      Sonnet    evidence-based match rule decisions (not Haiku)
14   ReviewProofmarkConfig     Sonnet    consistency check
15   BuildUnitTests            Sonnet    test implementation from BDD
16   ReviewUnitTests           Sonnet    test quality check
17   ExecuteUnitTests          Sonnet    3-attempt diagnosis+fix loop (not Haiku)
18   Publish                   Haiku     mechanical file copy + DB insert
19   FBR_BrdCheck              Opus      drift detection, first-pass quality
20   FBR_BddCheck              Sonnet    consistency check, not first-pass eval
21   FBR_FsdCheck              Opus      drift detection between spec and code
22   FBR_ArtifactCheck         Opus      code drift detection
23   FBR_ProofmarkCheck        Sonnet    consistency check
24   FBR_UnitTestCheck         Sonnet    consistency check
25   ExecuteJobRuns            Sonnet    3-attempt diagnosis+fix loop (not Haiku)
26   ExecuteProofmark          Haiku     mechanical queue+poll
27   FinalSignOff              Opus      judgment, spot-checking actual files
28   FBR_EvidenceAudit         Opus      Pat — most demanding node in pipeline
```

## Response Nodes (kickback targets)

Response nodes share blueprints with their parent writer/builder nodes.
Use the same model as the parent:

```
     Node                         Model     Parent
     ────                         ─────     ──────
     WriteBrdResponse             Opus      WriteBrd
     WriteBddResponse             Opus      WriteBddTestArch
     WriteFsdResponse             Opus      WriteFsd
     BuildJobArtifactsResponse    Sonnet    BuildJobArtifacts
     BuildProofmarkResponse       Sonnet    BuildProofmarkConfig
     BuildUnitTestsResponse       Sonnet    BuildUnitTests
```

## Triage Sub-Pipeline (7 nodes)

```
     Node                      Model     Rationale
     ────                      ─────     ─────────
T1   Triage_ProfileData        Sonnet    data profiling, not judgment
T2   Triage_AnalyzeOgFlow      Opus      OG code tracing, C#/Python divergence
T3   Triage_CheckBrd           Sonnet    comparing docs to T2 findings
T4   Triage_CheckFsd           Sonnet    comparing docs to T2 findings
T5   Triage_CheckCode          Sonnet    comparing code to FSD
T6   Triage_CheckProofmark     Sonnet    comparing config to profile
T7   Triage_Route              N/A       TriageRouterNode, no agent call
```

## Cost Summary

- Happy path (no kickbacks, no triage): 13 Opus, 13 Sonnet, 2 Haiku
- Dan's original proposal had 20 Opus on happy path
- ~35% fewer Opus calls per job across 103 jobs
