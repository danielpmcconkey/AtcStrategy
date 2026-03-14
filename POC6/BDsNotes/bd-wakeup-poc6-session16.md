# BD Wake-Up — POC6 Session 16

## Paste this to start the session:

```
Read /workspace/AtcStrategy/POC6/BDsNotes/bd-wakeup-poc6-session16.md then tell me where we are.
```

---

## What Happened Last Session (Session 15)

### Clutch System — COMPLETE
- `control.re_engine_config` table — single-row, `clutch_engaged boolean`, `CHECK (id = 1)`.
- `is_clutch_engaged()` in db.py. Workers check before `claim_task()`. If engaged, sleep 5 min (configurable via `clutch_interval`).
- Dan sets the clutch at 90% token usage via SQL: `UPDATE control.re_engine_config SET clutch_engaged = true WHERE id = 1;`

### Jobs Directory Scaffold — COMPLETE
- `jobs/` dir with `.gitkeep` and `.gitignore` (runtime artifacts excluded from git).
- `AgentNode.execute()` creates `{job_id}/process/` and `{job_id}/artifacts/` on the fly.

### Budget Removed
- Stripped `--max-budget-usd` from CLI invocations entirely. The clutch is the throttle.
- Removed `agent_budget` from EngineConfig, AgentNode, nodes.py, __main__.py, and tests.

### FAILURE→FAIL Promotion
- When an agent has a plumbing failure (empty output, timeout, bad JSON), `FAILURE` promotes to `FAIL` in `_resolve_outcome` — BUT only when no explicit `(node, FAILURE)` transition exists. ExecuteProofmark→Triage keeps its dedicated FAILURE transition.

### Resume Support
- `ingest_manifest` checks `load_job_state()` first. RUNNING jobs get their `current_node` re-enqueued. COMPLETE/DEAD_LETTER jobs are skipped. New jobs start fresh.
- Resume is dumb by design — the app trusts whatever state it finds. Human + BD clean up state externally before restarting.

### CLI Wired Up
- `--use-agents` (default True), `--stubs`, `--blueprints-dir`, `--jobs-dir`, `--model`, `--timeout`

### Bug Fixes
- `ingest_manifest` returns job IDs (strings) not task IDs (ints).
- `run_until_drained` checks both queue activity AND `re_job_state` RUNNING count to avoid the race between `complete_task` and `enqueue_task`.
- Indentation fix in `__main__.py`.

### DansTransactionSpecial (Job 373) — IN FLIGHT
- Running with real agents (`use_agents=True`), single worker, sonnet model.
- As of end of session: past ReviewProofmarkConfig (all APPROVEDs), BuildUnitTests in flight.
- Check progress: `tail -10 /tmp/claude-1000/-workspace/241b9fb1-b0f6-4b7f-83a2-451dfefa18a8/tasks/bw2hs2qlk.output`
- If that file is gone (container recycled), check DB: `python3 -c "from workflow_engine.db import *; ensure_schema(); print(load_job_state('373'))"`

### Test Harness — BROKEN, DO NOT RUN

**The test suite truncated production data TWICE.** The conftest autouse fixture was doing `TRUNCATE control.re_task_queue` and `TRUNCATE control.re_job_state` before every test. This wiped job 373's state mid-run.

## IMMEDIATE TODO — DO THIS BEFORE ANYTHING ELSE

### 1. Disable All Unit Tests
Make the test suite un-runnable until the harness is fixed. Don't just skip — make it impossible to accidentally run.

### 2. Document Test vs Prod Strategy
Dan's requirements (write this up somewhere permanent, probably EtlRE docs):

**Environment separation:**
- New env var in EtlReverseEngineering designating dev/SIT vs prod mode.
- Each mode uses its own DB connection string.
- Ideal: separate Docker containers with separate DBs. Current constraint: not enough RAM.
- Compromise: same container, different connection strings pointing to different databases (need Dan to create the test DB upstairs).

**Non-destructive test harness (belt and suspenders):**
- Tests NEVER truncate. Tests NEVER delete production data.
- Every test job ID uses prefix `TEST_JOB_{uuid}`.
- Conftest cleanup: `DELETE FROM ... WHERE job_id LIKE 'TEST_JOB_%'` — nothing else.
- `claim_task()` in tests is still dangerous — it grabs globally. Don't run tests while jobs are in flight.

**conftest.py was partially rewritten** — the `make_test_job_id()` helper and non-destructive cleanup are in place. `test_db.py` was partially converted. The rest of the test files still use hardcoded job IDs like `"job-1"`, `"job-err"`, etc. All need converting.

### Test files that touch the DB (need conversion):
- `tests/test_db.py` — partially done
- `tests/test_db_concurrency.py`
- `tests/test_engine.py`
- `tests/test_worker.py`
- `tests/test_queue_ops.py`

### Test files that DON'T touch the DB (safe as-is):
- `tests/test_agent_node.py` (uses mocks)
- `tests/test_models.py` (pure logic)
- `tests/test_nodes.py` (pure logic)
- `tests/test_transitions.py` (pure logic)
- `tests/test_logging.py` (pure logic)

## Pending from Session 14
- **Fix Hobson's `state-machine-transitions.md`** — FBR_EvidenceAudit still listed at state 25, should be 28.
- **Remove StubNode and stub-based tests** — on the todo list but deferred.

## Key Files
- `/workspace/EtlReverseEngineering/src/workflow_engine/agent_node.py`
- `/workspace/EtlReverseEngineering/src/workflow_engine/nodes.py`
- `/workspace/EtlReverseEngineering/src/workflow_engine/step_handler.py`
- `/workspace/EtlReverseEngineering/src/workflow_engine/worker.py`
- `/workspace/EtlReverseEngineering/src/workflow_engine/db.py`
- `/workspace/EtlReverseEngineering/src/workflow_engine/queue_ops.py`
- `/workspace/EtlReverseEngineering/src/workflow_engine/__main__.py`
- `/workspace/EtlReverseEngineering/src/workflow_engine/schema.sql`
- `/workspace/EtlReverseEngineering/tests/conftest.py` — partially rewritten, not tested
- `/workspace/EtlReverseEngineering/tests/test_db.py` — partially converted, not tested

## Test Counts (BEFORE session 15 changes — some tests may now fail)
- EtlReverseEngineering: 156 tests
- MockEtlFrameworkPython: 156 tests
- Proofmark: 194 tests

## RAM WARNING — READ THIS

Dan's host has 15GB RAM + 16GB swap. This container shares the host's swap.
**Subagent spawning is dangerous.** GSD executor subagents have OOM'd the host twice.

**Standing order:**
- Do NOT use `/gsd:execute-phase`. It will spawn subagents and OOM.
- Execute TDD cycles directly — read the plan, write the code.
- Before heavy work, run `free -h` to confirm available memory.
