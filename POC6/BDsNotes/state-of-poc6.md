# State of POC6

## What Exists

### Network Isolation (done — Hobson)
- BD writes code/confs to `/workspace/MockEtlFrameworkPython/`
- Inserts tokenized paths into `control.jobs` table (Postgres at 172.18.0.1)
- Host-side framework picks up jobs and runs them
- OG output (answer key): `/workspace/og-curated/` (read-only)
- RE output: `/workspace/re-curated/` (read-only, framework writes here)
- Only upward channel: structured data in queue tables

### Architecture (done — BD + Dan)
- Dumb Python orchestrator, no LLM in the control loop
- Deterministic state machine drives workflow
- Atomic agents: claim task, do one thing, queue next step, die
- Fresh Claude CLI context per invocation (no rot)
- Postgres task queue with `SELECT ... FOR UPDATE SKIP LOCKED`
- Per-agent blueprints as system prompts
- 105 independent job pipelines, zero cross-contamination
- See: `poc6-architecture.md`

### Agent Taxonomy (done — BD + Dan)
- Full waterfall: Plan → Define → Design → Build → Validate
- ~30 leaf nodes, each one an atomic agent
- See: `agent-taxonomy.md`

### State Machine Transition Table (done — BD + Dan)
- 27 happy path nodes (Plan through FinalSignOff)
- FinalBuildReview exploded into 6 serial gates (FBR_BrdCheck through FBR_UnitTestCheck)
- Three-outcome review model: Approve / Conditional / Fail
  - Conditional: targeted fix via response node, no downstream invalidation, 3 per review node max
  - Fail: rewind to write node, replay full pipeline forward from there
  - 4th conditional auto-promotes to Fail
- No errata accumulation. Writer gets only the most recent rejection reason. Fresh context always.
- Proofmark triage: 7-step diagnostic sub-pipeline (T1-T7)
  - T1-T2: context gathering (data profiling, OG flow analysis)
  - T3-T6: layer checks (BRD, FSD, code, proofmark config), each returns clean/fault
  - T7: pure orchestrator logic, routes to earliest fault or DEAD_LETTER
  - Each triage pass is fresh — no carryover from prior triage runs
- Retry exhaustion at any node → DEAD_LETTER → human escalation
- See: `state-machine-transitions.md`

## What's Next

Build the state machine / workflow engine in Python with stubbed nodes.
- Each node is a stub with a comment describing what the real agent will do
- Review nodes use RNG to return Approve / Conditional / Fail
- Non-review nodes use RNG to return Success / Failure
- Basic logging: job ID, node name, outcome, retry counts, transitions
- Run a handful of jobs through it to validate the workflow honors the
  transition table (rewinds, conditionals, FBR gauntlet restarts, triage
  routing, DEAD_LETTER on retry exhaustion)
- No Postgres, no Claude CLI, no real agents. Pure workflow validation.

## Design Principles (standing)

- No errata accumulation. Retry counter is the only memory between attempts.
- Keep agents dumb. Let the state machine's structure handle complexity.
- Parallelism is at the job level (105 jobs), not within a single job's pipeline.
- Fresh context every agent invocation. No state carried between invocations.

## Stale Artifacts

The GSD planning in `/workspace/EtlReverseEngineering/.planning/` was built for a C#/.NET 8 stack that no longer applies. Left in place for now but not current.
