# Session 22 Test Coverage Audit

**Date:** 2026-03-15
**Scope:** `src/workflow_engine/` (12 files) vs `tests/` (10 test files + conftest)

---

## 1. Covered: What Has Tests

### models.py — WELL COVERED
| Function/Class | Test File | Tests |
|---|---|---|
| `JobState` defaults & fields | test_models.py | `TestJobState` (3 tests), `TestJobStateFields` (4 tests) |
| `JobState` dataclass isolation | test_models.py | `test_no_state_bleed` |
| `EngineConfig` defaults | test_models.py | `TestEngineConfig` (1 test) |
| `Outcome` enum members | test_models.py | `TestOutcome` (1 test — confirms 6 members) |
| `NodeType` enum | test_models.py | `TestNodeType` (1 test) |
| `triage_results`, `triage_rewind_target`, `fbr_return_pending` fields | test_models.py | 3 dedicated tests |

### transitions.py — WELL COVERED
| Function/Class | Test File | Tests |
|---|---|---|
| `HAPPY_PATH` structure (22 nodes, order) | test_transitions.py | `TestTransitionTable` (8 tests) |
| FBR gate removal (session 22) | test_transitions.py | `TestFBRRemoved` (3 tests) |
| `REVIEW_ROUTING` (6 entries, exact mappings) | test_transitions.py | `TestReviewRouting` (11 tests) |
| CONDITIONAL/FAIL/response-SUCCESS edges | test_transitions.py | 3 tests in `TestReviewRouting` |
| Response node FAILURE edges | test_transitions.py | `test_response_node_failure_edges_in_transition_table` |
| Triage pipeline wiring (T1-T7) | test_transitions.py | `TestTriage` (5 tests) |
| `validate_transition_table()` | test_transitions.py | 1 test |
| `FBR_ROUTING` is empty | test_transitions.py | 1 test |
| Work-node self-retry edges | test_transitions.py | indirectly via `test_every_happy_path_node_has_outbound_edge` |

### nodes.py — WELL COVERED
| Function/Class | Test File | Tests |
|---|---|---|
| `Node` ABC | test_nodes.py | 1 test |
| `StubWorkNode` (deterministic + RNG) | test_nodes.py | 2 tests |
| `StubReviewNode` (deterministic + RNG) | test_nodes.py | 2 tests |
| `DiagnosticStubNode` (deterministic, RNG, verdict recording) | test_nodes.py | `TestTriageNodes` (4 tests) |
| `TriageRouterNode` (earliest fault, no faults, single fault) | test_nodes.py | 3 tests |
| `create_node_registry()` (descriptions, coverage, RNG, size=35) | test_nodes.py | 4 tests |
| Response nodes (exist, type, descriptions, deterministic, RNG) | test_nodes.py | 5 standalone tests |

### agent_node.py — WELL COVERED
| Function/Class | Test File | Tests |
|---|---|---|
| `_extract_outcome_json()` (8 cases) | test_agent_node.py | `TestExtractOutcomeJson` (9 tests) |
| `_OUTCOME_MAP` values | test_agent_node.py | `TestOutcomeMap` (2 tests) |
| `execute()` — success, fail, approved, conditional, rejected | test_agent_node.py | `TestAgentNodeExecute` (5 outcome tests) |
| `execute()` — non-zero CLI exit | test_agent_node.py | `test_cli_nonzero_exit_returns_failure` |
| `execute()` — timeout | test_agent_node.py | `test_timeout_returns_failure` |
| `execute()` — unparseable stdout | test_agent_node.py | 1 test |
| `execute()` — no outcome in agent text | test_agent_node.py | 1 test |
| `execute()` — unknown outcome value | test_agent_node.py | 1 test |
| Directory creation | test_agent_node.py | 1 test |
| CLI command structure | test_agent_node.py | 1 test |
| Rejection reason in prompt | test_agent_node.py | 1 test |
| Sub-agents CLI flag | test_agent_node.py | 2 tests |
| Process artifact writing (stdout fallback path) | test_agent_node.py | 3 tests verify file existence |

### db.py — WELL COVERED
| Function/Class | Test File | Tests |
|---|---|---|
| `get_pool()` | test_db.py | 1 test |
| `enqueue_task()` | test_db.py | 2 tests |
| `claim_task()` (oldest, empty, skip claimed) | test_db.py | 3 tests |
| `complete_task()` | test_db.py | 1 test |
| `fail_task()` | test_db.py | 1 test |
| FIFO ordering | test_db.py | 1 test |
| `is_clutch_engaged()` | test_db.py | 3 tests |
| `save_job_state()` / `load_job_state()` | test_db.py | 4 tests (including full round-trip) |
| SKIP LOCKED concurrency | test_db_concurrency.py | 2 tests |
| One-active-per-job constraint | test_db_concurrency.py | 3 tests |

### queue_ops.py — ADEQUATELY COVERED
| Function/Class | Test File | Tests |
|---|---|---|
| `ingest_manifest()` — new jobs | test_queue_ops.py | 4 tests |

### step_handler.py — PARTIALLY COVERED (see Gaps)
| Function/Class | Test File | Tests |
|---|---|---|
| `__call__()` — happy path traversal | test_engine.py | `TestHappyPathTraversal` (3 tests) |
| `__call__()` — DEAD_LETTER on max retries | test_engine.py | `TestCounterMechanics` (6 tests) |
| `__call__()` — TRIAGE_ROUTE handling | test_engine.py | `TestTriage` (6 tests) |
| `_resolve_outcome()` — FAILURE promotion, CONDITIONAL auto-promote, FAIL counter | test_engine.py | via `TestCounterMechanics` + `TestErrorHandling` |
| `_resolve_outcome()` — TERMINAL_FAIL_NODES | test_engine.py | `TestFBREvidenceAudit` (2 tests) |
| `_reset_downstream_conditionals()` | test_engine.py | `test_downstream_counters_reset_on_rewind` |
| Review branching (CONDITIONAL loop, FAIL rewind, rejection reason) | test_engine.py | `TestReviewBranching` (3 tests) |

### worker.py — WELL COVERED
| Function/Class | Test File | Tests |
|---|---|---|
| `WorkerPool` config (default, explicit, env var) | test_worker.py | 4 tests |
| Task processing | test_worker.py | 1 test |
| No double processing | test_worker.py | 1 test |
| Concurrent workers | test_worker.py | 1 test |
| Any-worker-any-job fungibility | test_worker.py | 1 test |
| Handler error resilience | test_worker.py | 1 test |
| `stop()` signals workers | test_worker.py | 1 test |
| Clutch integration | test_worker.py | 1 test |

### engine.py — PARTIALLY COVERED
| Function/Class | Test File | Tests |
|---|---|---|
| `Engine.__init__()` — transition validation | test_engine.py | indirectly (StepHandler instantiation) |
| `Engine.run()` — full multi-job via pool | test_engine.py | `test_multi_job_concurrent_via_pool` |

### log_config.py — COVERED
| Function/Class | Test File | Tests |
|---|---|---|
| `configure_logging()` | test_logging.py | 2 tests (JSON output, bound context) |

### __main__.py — NOT TESTED (see Gaps)

---

## 2. Gaps: What Has No Tests or Insufficient Tests

### CRITICAL: triage_results hydration in step_handler.py (NEW, ZERO tests)

**Lines 79-91 of step_handler.py** — the `Triage_Check*` process artifact hydration block added in session 22. This code:
1. Checks if `node_name.startswith("Triage_Check")` AND `self._config.use_agents` is True
2. Reads `{jobs_dir}/{job_id}/process/{node_name}.json`
3. Extracts `artifact.get("verdict", "clean")` and writes to `job.triage_results[node_name]`
4. Falls back to `"clean"` on JSON/OS errors

**Why this matters:** This is the bridge between AgentNode (writes files) and TriageRouterNode (reads `job.triage_results`). If this hydration fails silently, triage routing will always see "clean" and dead-letter every triage case. The stub path (DiagnosticStubNode) writes directly to `job.triage_results`, so all existing triage tests pass without exercising this code path.

**Untested scenarios:**
- Happy path: agent writes `{"outcome": "SUCCESS", "verdict": "fault"}`, hydration sets `triage_results["Triage_CheckBrd"] = "fault"`
- Missing verdict key: defaults to `"clean"`
- Malformed JSON in process artifact: falls back to `"clean"`
- Missing process file: no hydration (silent skip)
- `use_agents=False`: hydration block is skipped entirely (stub path handles it)

### CRITICAL: _read_outcome_from_file() primary path in agent_node.py

The execute() tests mock `subprocess.run` but the tests that verify SUCCESS outcomes go through the **stdout fallback path** (`_parse_outcome_from_stdout`), not the file-based primary path (`_read_outcome_from_file`). The stdout fallback writes the process artifact, so the test then asserts the file exists — but this tests the fallback, not the primary path.

**What's not tested:** Agent writes process artifact BEFORE subprocess returns, then `execute()` reads it via `_read_outcome_from_file()`. The only test that truly hits `_read_outcome_from_file()` is `test_cli_nonzero_exit_returns_failure`, which tests the error path (no artifact file → returns `None` → falls back to `Outcome.FAILURE`).

**Untested scenarios:**
- Process artifact exists on disk before stdout parsing: `_read_outcome_from_file` returns outcome, stdout fallback never runs
- Process artifact exists but has bad JSON: returns `None`, falls through to stdout
- Process artifact exists but missing `"outcome"` key: returns `None`
- Process artifact has unknown outcome string: returns `None`

### HIGH: _cleanup_stale_artifacts() in step_handler.py (ZERO tests)

**Lines 245-261 of step_handler.py** — removes process artifacts for downstream nodes on rewind when `use_agents=True`. Never tested because all integration tests use `use_agents=False` (stubs).

### HIGH: create_agent_registry() in nodes.py (ZERO tests)

No test instantiates `create_agent_registry()` or verifies:
- Blueprint path construction (`{blueprints_dir}/{bp_name}.md`)
- MODEL_MAP per-node model assignment
- Sub-agent wiring for `_AUTHOR_NODES`
- Triage_Route stays as TriageRouterNode (not AgentNode)
- `_blueprint_name()` extraction logic

### MEDIUM: ingest_manifest() resume path in queue_ops.py

`ingest_manifest()` has three branches:
1. New job → tested
2. Existing COMPLETE/DEAD_LETTER → **NOT TESTED** (skip logic)
3. Existing RUNNING → **NOT TESTED** (resume logic, enqueues `existing.current_node`)

### MEDIUM: __main__.py CLI entry point (ZERO tests)

`main()` argument parsing, `--stubs` flag behavior, config construction, and output formatting are untested. Low risk (thin wrapper) but `use_agents=not args.stubs` logic could silently break.

### MEDIUM: Engine.run() error paths

- `Engine.__init__()` raises `ValueError` on invalid transition table — not tested directly
- `Engine.run()` timeout path in `WorkerPool.run_until_drained` — not tested (what happens when deadline exceeded?)
- `close_pool()` is never called in `Engine.run()` — no test verifies connection cleanup

### LOW: Date-aware prompt logic in agent_node.py

`_DATE_AWARE_NODES` prompt injection (lines 84-94) is never tested. Tests don't verify that:
- ETL date range is included in prompt for `ExecuteJobRuns`, `ExecuteProofmark`, `FinalSignOff`, `FBR_EvidenceAudit`
- Warning message appears when dates are missing
- Non-date-aware nodes don't get the date block

### LOW: db.py edge cases

- `ensure_schema()` — not tested (always run implicitly)
- `close_pool()` — not tested
- `get_pool()` with custom `RE_DATABASE_URL` env var — not tested
- `enqueue_task` returning no row (defensive RuntimeError) — not tested

### LOW: WorkerPool.run_until_drained() timeout behavior

When deadline is exceeded, `run_until_drained()` just calls `stop()` and returns silently. No test verifies this doesn't leave tasks in a bad state.

---

## 3. Priority Gaps: Ranked by Production Bug Risk

### P0 — Will cause production bugs

1. **triage_results hydration (step_handler.py lines 79-91)**
   - **Risk:** This is the ONLY code path that bridges agent file output to triage routing in production (`use_agents=True`). If this breaks, every triage case dead-letters because TriageRouterNode sees all-clean results. Zero tests exercise this path.
   - **Fix:** Create tests with `use_agents=True`, mock `EngineConfig.jobs_dir`, write fake process artifact files with verdict data, and verify `job.triage_results` is populated correctly after `StepHandler.__call__()`.

2. **_read_outcome_from_file() primary path (agent_node.py)**
   - **Risk:** In production, agents write process artifacts to disk. The primary outcome path reads from file. All existing tests exercise the stdout fallback instead. If file reading breaks (path construction, JSON parsing, outcome mapping), every agent node fails.
   - **Fix:** Write process artifact files to `tmp_path` before calling `execute()`, verify the file-based path is used and stdout fallback is NOT reached.

### P1 — Likely to cause bugs on edge cases

3. **_cleanup_stale_artifacts() (step_handler.py lines 245-261)**
   - **Risk:** On rewind, stale process artifacts from a prior walk persist. If an agent reads a prior node's artifact and makes decisions based on it, the second walk produces wrong results. Untested.
   - **Fix:** Create agent-mode StepHandler test with `jobs_dir`, trigger a rewind, verify downstream `.json` files are deleted.

4. **create_agent_registry() (nodes.py)**
   - **Risk:** Blueprint path mismatches (`_blueprint_name()` returns wrong slug), MODEL_MAP not applied, sub-agents not wired — any of these silently breaks agent invocation in production.
   - **Fix:** Unit test that instantiates `create_agent_registry()` with a temp blueprints dir, verifies AgentNode attributes.

5. **ingest_manifest() resume/skip paths (queue_ops.py)**
   - **Risk:** Re-running the engine after a partial failure is a real production scenario. If resume enqueues the wrong node, or if skip doesn't filter COMPLETE jobs, you get duplicate work or data corruption.
   - **Fix:** Save a COMPLETE job, save a RUNNING job at node N, call `ingest_manifest()`, verify COMPLETE is skipped and RUNNING is enqueued at current_node.

### P2 — Should be tested but low immediate risk

6. **Date-aware prompt logic (agent_node.py)** — wrong date range = wrong ETL execution
7. **Engine.run() timeout / connection cleanup** — resource leak potential
8. **__main__.py CLI** — thin wrapper, low risk
9. **db.py edge cases** — defensive code, unlikely to fire

---

## 4. Session 22 Change Verification

### FBR gate removal (nodes 19-24): VERIFIED
- `test_no_fbr_gates_in_happy_path` confirms 6 FBR gates removed from HAPPY_PATH
- `test_fbr_routing_is_empty` confirms `FBR_ROUTING = {}`
- `test_fbr_evidence_audit_still_in_happy_path` confirms terminal gate stays
- `test_publish_leads_to_execute_job_runs` confirms Publish -> ExecuteJobRuns (direct)
- `test_happy_path_has_22_nodes` confirms node count
- Happy path traversal test completes successfully with 22 transition logs
- **Nothing missed in FBR removal.**

### agent_node.py line 140 fix (non-zero exit + no artifact = FAILURE): VERIFIED
- `test_cli_nonzero_exit_returns_failure` confirms `Outcome.FAILURE` (not `None`)
- Test creates no process artifact file, so `_read_outcome_from_file()` returns `None`, and the `or Outcome.FAILURE` fallback fires
- **Fix is tested.**

### Session 21 file-based outcome contract: PARTIALLY VERIFIED
- Agent tests verify process artifact files are written on SUCCESS, FAIL, CONDITIONAL
- But tests use the stdout fallback path (agent didn't write file, so `_parse_outcome_from_stdout` writes it)
- The *primary* path where agent writes file pre-return is not directly tested (see P0 #2)

---

## 5. Test Harness Health

The conftest.py harness is solid:
- `TEST_JOB_` prefix prevents production data collisions
- Per-test cleanup (before AND after) prevents stale task claiming
- Session-scoped safety guard blocks test runs during active engine execution
- Session-scoped cleanup catches anything per-test cleanup misses
- `make_test_job_id()` uses UUID suffix for uniqueness

**One minor concern:** `fresh_job_state` fixture uses hardcoded `job_id="test-job-001"` without the `TEST_JOB_` prefix. This fixture is only used in `test_models.py` for pure-logic tests (no DB writes), so it's safe today, but it violates the stated convention.
