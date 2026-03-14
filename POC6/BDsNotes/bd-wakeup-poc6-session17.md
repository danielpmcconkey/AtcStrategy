# BD Wake-Up — POC6 Session 17

## Paste this to start the session:

```
Read /workspace/AtcStrategy/POC6/BDsNotes/bd-wakeup-poc6-session17.md then tell me where we are.
```

---

## What Happened Last Session (Session 16)

### BuildUnitTests — FIXED
- Original problem: BuildUnitTests was timing out at 600s (hardcoded in agent_node.py).
- First run (session 15) produced 50 tests / 994 lines — overkill for a 4-source job.
- Second run produced nothing in 10 minutes — agent churning on context.
- **Fix:** Nerfed `test-writer.md` blueprint to cap at 10 most critical BDD scenarios.
  Updated `test-reviewer.md` to accept the cap (don't reject for missing edge cases).
- Third run: artifacts at 40s, process JSON at 130s. ~2 minutes total. Success.
- Reviewer gave CONDITIONAL (13 tests instead of 10, plus a traceability nit).
  BuildUnitTestsResponse fixed it. Sonnet can't count but the loop converged.

### Sub-Agent Diagnosis
- `_AUTHOR_NODES` injects a `code-reviewer` sub-agent for quality checks.
- Blueprint step 7 was explicitly telling the agent to invoke it AND `_AUTHOR_NODES` injected it.
- Softened blueprint language to "it'll review, fix what it finds" — less loopy.
- Sub-agent left in place for quality checks (PEP 8, type hints). Downstream
  ReviewUnitTests handles traceability/evidence. Two different concerns.

### ETL Date Range Params — BUILT, NOT TESTED
- Added `--etl-start-date` and `--etl-end-date` to CLI.
- Plumbed through: `EngineConfig` → `StepHandler` → `create_agent_registry` → `AgentNode`.
- Date-aware nodes: `ExecuteJobRuns`, `ExecuteProofmark`, `FinalSignOff`, `FBR_EvidenceAudit`.
- Non-date nodes ignore it. Missing dates on date-aware nodes get a WARNING in prompt.

### Full Pipeline Run — Got to ExecuteJobRuns
- Job 373 ran through the full build phase + FBR gates successfully.
- All FBR checks passed: BRD, BDD, FSD, Artifact, Proofmark, UnitTest.
- ExecuteJobRuns agent ran `python -m cli` DIRECTLY instead of queuing
  to `control.task_queue`. Naughty — bypassed the host boundary.
- ExecuteProofmark agent DID use `control.proofmark_test_queue` (correct pattern)
  but used raw container paths instead of tokenized host paths. All 62 tasks
  failed with `ConfigError: 'comparison_target' is a required field`.

### Test Suite — STILL DISABLED
- `conftest.py` does `sys.exit(1)` with a loud warning. DO NOT re-enable
  until env separation and non-destructive harness are rebuilt.

## OPEN PROBLEM — CONTAINER / HOST PATH BOUNDARY

This is where we stopped. The core issue:

### Three Queues
1. **`control.task_queue`** — MockEtlFramework job execution. Agents INSERT here,
   Hobson's side picks up and runs ETL jobs on the host.
2. **`control.proofmark_test_queue`** — Proofmark comparisons. Same pattern.
3. **`control.re_task_queue`** — Workflow engine state machine (internal to basement).

### The Path Problem
- `/workspace/` in the container = `/media/dan/fdrive/ai-sandbox/workspace/` on the host.
- `ETL_ROOT` env var = `/workspace/MockEtlFrameworkPython` (container-side).
- But upstairs, ETL FW and Proofmark run in a directory OUTSIDE the sandbox
  entirely. This was deliberate — prior RE agents were editing things they
  shouldn't edit.
- OG curated output (`og-curated/`) is mounted somewhere Dan needs to clarify.
- RE output (`Output/curated/`) same deal.

### What Needs to Happen
- Dan needs to decide the env var / path token strategy for cross-boundary paths.
- Blueprints for `job-executor.md` and `proofmark-executor.md` need rewriting:
  - `job-executor.md`: Queue to `control.task_queue` instead of running CLI directly.
  - `proofmark-executor.md`: Already queues correctly but needs tokenized paths.
- Possibly a second env var beyond `ETL_ROOT` for the shared data directories.
- Dan was thinking this through when we stopped.

### Cleanup Before Next Run
- Delete stale proofmark queue entries: `DELETE FROM control.proofmark_test_queue WHERE job_key = 'job_373';`
- Reset job 373 state if needed (check `re_task_queue` and `re_job_state`).

## DB State at End of Session

```sql
-- Job state
SELECT * FROM control.re_job_state WHERE job_id = '373';
-- current_node = 'ExecuteJobRuns', status = 'RUNNING'
-- (but nothing is actually running — engine was killed)

-- Task queue has a stale 'claimed' ExecuteJobRuns entry
-- and a stale 'claimed' ExecuteProofmark entry from the first full run
```

## Pending from Prior Sessions
- **Fix Hobson's `state-machine-transitions.md`** — FBR_EvidenceAudit still listed at state 25, should be 28.
- **Remove StubNode and stub-based tests** — deferred.
- **Test harness rebuild** — env separation, non-destructive cleanup. Deferred until path problem solved.
- **Per-node model mapping** — Dan wants opus on spec/triage nodes, sonnet on build, haiku on execution. Deferred.

## Key Files Changed This Session
- `/workspace/EtlReverseEngineering/blueprints/test-writer.md` — 10-test cap
- `/workspace/EtlReverseEngineering/blueprints/test-reviewer.md` — accepts cap
- `/workspace/EtlReverseEngineering/src/workflow_engine/__main__.py` — date CLI args
- `/workspace/EtlReverseEngineering/src/workflow_engine/agent_node.py` — date injection + DATE_AWARE_NODES
- `/workspace/EtlReverseEngineering/src/workflow_engine/models.py` — etl_start/end_date on EngineConfig
- `/workspace/EtlReverseEngineering/src/workflow_engine/nodes.py` — pass dates to registry
- `/workspace/EtlReverseEngineering/src/workflow_engine/step_handler.py` — pass dates to registry

## RAM WARNING — READ THIS

Dan's host has 15GB RAM + 16GB swap. This container shares the host's swap.
**Subagent spawning is dangerous.** GSD executor subagents have OOM'd the host twice.

**Standing order:**
- Do NOT use `/gsd:execute-phase`. It will spawn subagents and OOM.
- Execute TDD cycles directly — read the plan, write the code.
- Before heavy work, run `free -h` to confirm available memory.
