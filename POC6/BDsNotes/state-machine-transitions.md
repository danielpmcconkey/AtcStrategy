# State Machine Transition Table

## Happy Path (all successes, linear)

| #  | State                    | Stage    | Blueprint        | On Success               |
|----|--------------------------|----------|------------------|--------------------------|
| 1  | LocateOgSourceFiles      | Plan     | og-locator       | InventoryOutputs         |
| 2  | InventoryOutputs         | Plan     | output-analyst   | InventoryDataSources     |
| 3  | InventoryDataSources     | Plan     | source-analyst   | NoteDependencies         |
| 4  | NoteDependencies         | Plan     | dependency-analyst| WriteBrd                |
| 5  | WriteBrd                 | Define   | brd-writer       | ReviewBrd                |
| 6  | ReviewBrd                | Define   | brd-reviewer     | WriteBddTestArch         |
| 7  | WriteBddTestArch         | Design   | bdd-writer       | ReviewBdd                |
| 8  | ReviewBdd                | Design   | bdd-reviewer     | WriteFsd                 |
| 9  | WriteFsd                 | Design   | fsd-writer       | ReviewFsd                |
| 10 | ReviewFsd                | Design   | fsd-reviewer     | BuildJobArtifacts        |
| 11 | BuildJobArtifacts        | Build    | builder          | ReviewJobArtifacts       |
| 12 | ReviewJobArtifacts       | Build    | artifact-reviewer| BuildProofmarkConfig     |
| 13 | BuildProofmarkConfig     | Build    | proofmark-builder| ReviewProofmarkConfig    |
| 14 | ReviewProofmarkConfig    | Build    | proofmark-reviewer| BuildUnitTests          |
| 15 | BuildUnitTests           | Build    | test-writer      | ReviewUnitTests          |
| 16 | ReviewUnitTests          | Build    | test-reviewer    | ExecuteUnitTests         |
| 17 | ExecuteUnitTests         | Build    | test-executor    | Publish                  |
| 18 | Publish                  | Build    | publisher          | FBR_BrdCheck           |
| 19 | FBR_BrdCheck             | Build    | brd-reviewer       | FBR_BddCheck           |
| 20 | FBR_BddCheck             | Build    | bdd-reviewer       | FBR_FsdCheck           |
| 21 | FBR_FsdCheck             | Build    | fsd-reviewer       | FBR_ArtifactCheck      |
| 22 | FBR_ArtifactCheck        | Build    | artifact-reviewer  | FBR_ProofmarkCheck     |
| 23 | FBR_ProofmarkCheck       | Build    | proofmark-reviewer | FBR_UnitTestCheck      |
| 24 | FBR_UnitTestCheck        | Build    | test-reviewer      | ExecuteJobRuns         |
| 25 | ExecuteJobRuns           | Validate | job-executor       | ExecuteProofmark       |
| 26 | ExecuteProofmark         | Validate | proofmark-executor | FinalSignOff           |
| 27 | FinalSignOff             | Validate | signoff            | COMPLETE               |

## Review Response Nodes (same blueprint as writer, different routing)

These only appear on failure paths. On the happy path they're never entered.

| State                       | Stage    | Blueprint          | On Success             |
|-----------------------------|----------|--------------------|------------------------|
| WriteBrdResponse            | Define   | brd-writer         | ReviewBrd              |
| WriteBddResponse            | Design   | bdd-writer         | ReviewBdd              |
| WriteFsdResponse            | Design   | fsd-writer         | ReviewFsd              |
| BuildJobArtifactsResponse   | Build    | builder            | ReviewJobArtifacts     |
| BuildProofmarkResponse      | Build    | proofmark-builder  | ReviewProofmarkConfig  |
| BuildUnitTestsResponse      | Build    | test-writer        | ReviewUnitTests        |
| TriageProofmarkFailures     | Validate | triage             | ExecuteProofmark       |

## FBR Failure Routing

Any FBR gate failure rewinds to the response node, goes through review, then restarts
the entire FBR gauntlet from the top. Depth cap on total FBR restarts prevents infinite loops.

| FBR Gate              | On Fail                    | Fix Path                                        |
|-----------------------|----------------------------|-------------------------------------------------|
| FBR_BrdCheck          | WriteBrdResponse           | → ReviewBrd → restart at FBR_BrdCheck           |
| FBR_BddCheck          | WriteBddResponse           | → ReviewBdd → restart at FBR_BrdCheck           |
| FBR_FsdCheck          | WriteFsdResponse           | → ReviewFsd → restart at FBR_BrdCheck           |
| FBR_ArtifactCheck     | BuildJobArtifactsResponse  | → ReviewJobArtifacts → restart at FBR_BrdCheck  |
| FBR_ProofmarkCheck    | BuildProofmarkResponse     | → ReviewProofmarkConfig → restart at FBR_BrdCheck|
| FBR_UnitTestCheck     | BuildUnitTestsResponse     | → ReviewUnitTests → restart at FBR_BrdCheck     |

Note: Restart is always from FBR_BrdCheck (top of gauntlet), because a downstream
fix could invalidate an upstream pass.

## In-Flow Review Failure Edges

### Three-Outcome Model

Every review node returns one of:
- **Approve** → next node in happy path
- **Conditional** → response node (targeted fixes) → same reviewer again
- **Fail** → back to original write node (full rewrite from that point forward)

Key distinction:
- **Conditional**: "fix these specific things." Writer gets reviewer's feedback.
  Job stays at this review boundary. No downstream invalidation.
- **Fail**: "this artifact is fundamentally wrong." Everything downstream is
  invalidated. Job rewinds to the write node and walks the full happy path
  forward from there, re-doing all subsequent artifacts.

### Agent Input on Failure

Writer receives ONLY the most recent rejection reason. No accumulated errata.
Keep agents dumb. Let retry limits handle persistent failures.

### Counters

- **Conditional limit**: 3 per review node. 4th conditional auto-promotes to Fail.
- **Retry limit**: TBD per review node. Exhaustion → DEAD_LETTER → human.

### Transition Table

| Review Node           | On Conditional                | On Fail (rewind to)  |
|-----------------------|-------------------------------|----------------------|
| ReviewBrd             | WriteBrdResponse → ReviewBrd  | WriteBrd (redo Define onward) |
| ReviewBdd             | WriteBddResponse → ReviewBdd  | WriteBddTestArch (redo Design onward) |
| ReviewFsd             | WriteFsdResponse → ReviewFsd  | WriteFsd (redo Design.FSD onward) |
| ReviewJobArtifacts    | BuildJobArtifactsResponse → ReviewJobArtifacts | BuildJobArtifacts (redo Build onward) |
| ReviewProofmarkConfig | BuildProofmarkResponse → ReviewProofmarkConfig | BuildProofmarkConfig (redo from here onward) |
| ReviewUnitTests       | BuildUnitTestsResponse → ReviewUnitTests | BuildUnitTests (redo from here onward) |

### FBR Gates

FBR gates use the same three-outcome model. The difference:
- **Conditional**: response node → review → approve → restart gauntlet from FBR_BrdCheck
- **Fail**: rewind to original write node, re-walk happy path forward, which
  naturally arrives back at FBR_BrdCheck after re-doing all intermediate steps

## Proofmark Failure Pipeline

When ExecuteProofmark fails, the job enters a triage sub-pipeline. This is a
serial diagnostic sequence. Steps 1-2 are context-gathering (produce artifacts
consumed by later steps). Steps 3-6 are diagnostic (each checks one layer).
Step 7 is the fallback.

### Triage Sub-Pipeline

| #  | State                    | Blueprint            | Output                          | On Success               |
|----|--------------------------|----------------------|---------------------------------|--------------------------|
| T1 | Triage_ProfileData       | data-profiler        | Data profile of failed rows     | Triage_AnalyzeOgFlow     |
| T2 | Triage_AnalyzeOgFlow     | og-flow-analyst      | OG data flow analysis + findings| Triage_CheckBrd          |
| T3 | Triage_CheckBrd          | triage-brd-checker   | (clean, "") or (fault, reason)  | Triage_CheckFsd          |
| T4 | Triage_CheckFsd          | triage-fsd-checker   | (clean, "") or (fault, reason)  | Triage_CheckCode         |
| T5 | Triage_CheckCode         | triage-code-checker  | (clean, "") or (fault, reason)  | Triage_CheckProofmark    |
| T6 | Triage_CheckProofmark    | triage-pm-checker    | (clean, "") or (fault, reason)  | Triage_Route             |
| T7 | Triage_Route             | (no agent — logic)   | Routing decision                | (see below)              |

### Agent Inputs

Each diagnostic agent (T3-T6) receives:
- The data profile from T1
- The OG flow analysis from T2
- The job's current artifact for the layer it's checking
- Its own blueprint (narrowly scoped to one layer)

T3 (BRD check): Does the BRD correctly describe the data flow identified in T2?
  If T2 found meaningful findings, check BRD against them.
  If T2 found nothing notable, use data profile to "step through" the BRD.

T4 (FSD check): Same approach — check FSD against T2 findings or data profile.

T5 (code check): Same approach — check conf/external modules against T2 findings
  or data profile.

T6 (proofmark config): Only meaningful if T3, T4, T5 all came back clean.
  If the pipeline correctly implements a correct spec, the comparison rules
  must be wrong. Uses data profile to evaluate match rules.

### Triage Routing (T7)

T7 is pure orchestrator logic, no agent. It reads the outputs of T3-T6 and routes:

| Condition                          | Route To                                    |
|------------------------------------|---------------------------------------------|
| T3 found fault (BRD)              | WriteBrd (redo Define onward)               |
| T4 found fault (FSD)              | WriteFsd (redo Design.FSD onward)           |
| T5 found fault (code)             | BuildJobArtifacts (redo Build onward)       |
| T6 found fault (proofmark config) | BuildProofmarkConfig (redo from here onward)|
| Multiple faults found             | Route to earliest (highest up the pipeline) |
| No faults found                   | DEAD_LETTER → human                         |

### Triage Counter

Triage has its own retry limit. Each complete pass through the triage sub-pipeline
(T1-T7 → fix → re-execute proofmark → fail again) increments the counter.
Exhaustion → DEAD_LETTER.

## Terminal Failures

Any node that exhausts its retry limit → DEAD_LETTER.
Job sits in DEAD_LETTER for manual inspection / human decision.
