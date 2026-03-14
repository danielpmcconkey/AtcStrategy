# BD Wake-Up — POC6 Session 4

## Paste this to start the session:

```
Read /workspace/AtcStrategy/POC6/BDsNotes/bd-wakeup-poc6-session4.md then tell me where we are.
```

---

## What Happened Last Session

1. Read Hobson's handoff note — network isolation is done, C# framework is gone,
   Python framework at `/workspace/MockEtlFrameworkPython/`, read-only mounts for
   OG and RE output, env vars cleaned up.

2. Reviewed existing GSD planning artifacts — determined the roadmap/requirements
   in `/workspace/EtlReverseEngineering/.planning/` are stale (built for C#/.NET 8).
   Left in place but not current.

3. Designed the full state machine transition table with Dan:
   - 27 happy path nodes
   - FinalBuildReview exploded into 6 serial gates (FBR_BrdCheck → FBR_UnitTestCheck)
   - Three-outcome review model: Approve / Conditional (3 max per node) / Fail
   - Fail = rewind to write node + replay entire pipeline forward
   - No errata. Writer gets only most recent rejection reason. Fresh context always.
   - Proofmark triage: 7-step diagnostic sub-pipeline (data profiling → OG flow
     analysis → check BRD → check FSD → check code → check proofmark config → route)
   - Each triage pass is fresh — retry counter is the only memory
   - Retry exhaustion → DEAD_LETTER → human

## What Needs to Happen

Build v0.1 of the state machine / workflow engine. Use GSD.

```
/gsd:new-project
```

or if the EtlReverseEngineering GSD project is still viable enough to reuse:

```
/gsd:progress
```

### v0.1 Scope

- Pure Python workflow engine with stubbed nodes
- Each stub has a comment describing what the real agent will do
- Review nodes: RNG returns Approve / Conditional / Fail
- Non-review nodes: RNG returns Success / Failure
- Logging: job ID, node name, outcome, retry counts, transitions
- Run several jobs through to validate workflow correctness
- No Postgres, no Claude CLI, no real agents
- Validate: rewinds, conditional loops, FBR gauntlet restarts, triage routing,
  DEAD_LETTER on retry exhaustion

### Key Files

- `/workspace/AtcStrategy/POC6/BDsNotes/state-of-poc6.md` — current state overview
- `/workspace/AtcStrategy/POC6/BDsNotes/state-machine-transitions.md` — the transition table
- `/workspace/AtcStrategy/POC6/BDsNotes/agent-taxonomy.md` — full taxonomy tree
- `/workspace/AtcStrategy/POC6/BDsNotes/poc6-architecture.md` — architecture overview

### Design Principles (non-negotiable)

- No errata accumulation between attempts
- Retry counter is the only memory across retries
- Fresh context every agent invocation
- Parallelism at job level, not within a job
- Deterministic orchestrator, no LLM in the control loop
