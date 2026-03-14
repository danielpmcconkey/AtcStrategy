# BD Wake-Up — POC6 Session 15

## Paste this to start the session:

```
Read /workspace/AtcStrategy/POC6/BDsNotes/bd-wakeup-poc6-session15.md then tell me where we are.
```

---

## What Happened Last Session (Session 14)

### v0.3 Phase 8: Agent Invocation Layer — COMPLETE

1. **AgentNode class** — shells out to `claude -p` with blueprint as `--append-system-prompt`, parses structured JSON outcome from stdout, writes process artifacts on success. Controlled by `EngineConfig.use_agents` flag (default off).

2. **FBR_EvidenceAudit** — 28th node, FINAL node in happy path (after FinalSignOff). Terminal gate: APPROVED → COMPLETE, REJECTED → DEAD_LETTER with no retry. Pat persona — adversarial evidence auditor who assumes the RE squad cheated until proven otherwise.

3. **Sub-agent support** — `AgentNode` accepts optional `sub_agents` dict, passes as `--agents` to Claude CLI. Author nodes (builder, test-writer, proofmark-builder + their response variants) get a `code-reviewer` sub-agent for internal quality gate before returning SUCCESS.

4. **Artifact cleanup on rewinds** — stale process artifacts deleted when orchestrator rewinds to an earlier state.

5. **Code review cleanup across all 3 repos:**
   - EtlRE: fixed broken __main__.py, assert→RuntimeError, renamed logging.py→log_config.py, extracted triage descriptions, rewrote JSON parser, deleted dead enqueue_next, centralized test fixtures, tightened type hints
   - MockEtlFW: fixed bool/int type check bug, added SQL injection comment, standardized pathlib, moved WriteMode enum, removed sys.path hack
   - Proofmark: typed queue.py, list→tuple in frozen dataclasses, fixed bare except, removed dead code, added memory management comments

6. **Documentation** — 6 reference docs in EtlRE/Documentation/ (state machine overview, transition logic, FBR gauntlet, triage pipeline, agent integration)

7. **Planning docs updated** — ROADMAP, REQUIREMENTS, STATE all reflect v0.2 complete, v0.3 phase 8 complete.

8. **Hobson briefing** — wrote `hobson-briefing-artifact-architecture.md` in AtcStrategy defining the two-artifact-stream architecture, outcome enum contract, file layout conventions.

### Test Counts
- EtlReverseEngineering: 152 tests
- MockEtlFrameworkPython: 156 tests
- Proofmark: 194 tests

### Key Design Decisions Made This Session

- **All nodes agentic** (including executors) for portability to production
- **File-based artifact chaining** — no IPC between agents. Process JSON + product artifacts in EtlRE under `jobs/{job_id}/`
- **FW accesses generated code via tokenized paths** — no cross-repo writes
- **FBR_EvidenceAudit is terminal** — REJECTED = DEAD_LETTER, no rewind, no retry
- **Executor agents** (test-executor, job-executor) have 3-attempt internal leash — orchestrator doesn't retry them
- **FM-16 is documentation only** — existing FBR routing unchanged, the note describes the natural behavior
- **Author nodes get code-reviewer sub-agent** via `--agents` CLI flag — catches slop before downstream reviewers

## What Needs to Happen Next

### Immediate: Phase 9 — Integration Testing

1. **Wait for Hobson's blueprint updates** — he's rewriting all 28 to absorb the artifact architecture briefing. Check EtlRE for new commits.

2. **Scaffold the `jobs/` directory** — create the convention directories so agents have somewhere to write.

3. **Build a dry-run mode** — invoke a single agent on a single job with verbose logging. Validate:
   - Blueprint loads correctly as system prompt
   - Agent can read files (OG source, prior artifacts)
   - Agent writes product artifacts to the right place
   - Agent writes process JSON with valid outcome
   - Orchestrator parses outcome correctly
   - Sub-agent (code-reviewer) invokes within author nodes

4. **Cost estimation** — run the first few nodes of one job to get real cost-per-node data. Extrapolate to 103 jobs × 28 nodes.

### Pending: Update AtcStrategy Transition Table

Hobson's `state-machine-transitions.md` has FBR_EvidenceAudit at state 25 (in the FBR gauntlet). We moved it to state 28 (after FinalSignOff, before COMPLETE). That doc needs correcting.

### Deferred

- **Session 15 wakeup for Hobson** — if Dan wants Hobson to know about sub-agents and Pat's overhaul
- **VAL-01/VAL-02** — transition table static validation and path coverage reporting (future milestone)

## Key Files

- `/workspace/EtlReverseEngineering/src/workflow_engine/agent_node.py` — AgentNode class
- `/workspace/EtlReverseEngineering/src/workflow_engine/nodes.py` — node registry, sub-agent definitions, _AUTHOR_NODES
- `/workspace/EtlReverseEngineering/src/workflow_engine/step_handler.py` — orchestrator logic
- `/workspace/EtlReverseEngineering/src/workflow_engine/transitions.py` — transition table, TERMINAL_FAIL_NODES
- `/workspace/EtlReverseEngineering/blueprints/` — all 28 agent blueprints (+ _conventions.md)
- `/workspace/EtlReverseEngineering/blueprints/evidence-auditor.md` — Pat's blueprint
- `/workspace/EtlReverseEngineering/Documentation/` — 6 reference docs
- `/workspace/EtlReverseEngineering/.planning/STATE.md` — current project state
- `/workspace/AtcStrategy/POC6/BDsNotes/hobson-briefing-artifact-architecture.md` — Hobson's contract doc
- `/workspace/AtcStrategy/POC6/HobsonsNotes/job-scope-manifest.json` — 103 jobs

## The v0.2→v0.3 Stack

```
manifest.json → ingest_manifest() → re_task_queue (Postgres)
                                          ↓
WorkerPool (N threads) → claim_task() → StepHandler.__call__()
                                          ↓
                              load_job_state() → node.execute(job) → _resolve_outcome()
                                          ↓
                              save_job_state() → complete_task() → enqueue_task(next_node)
```

In v0.3, `node.execute(job)` is either:
- **StubNode** (use_agents=False) — deterministic, for testing
- **AgentNode** (use_agents=True) — `claude -p` with blueprint, parses outcome JSON
  - Author nodes also pass `--agents` with code-reviewer sub-agent

---

## RAM WARNING — READ THIS

Dan's host has 15GB RAM + 16GB swap. This container shares the host's swap.
**Subagent spawning is dangerous.** GSD executor subagents have OOM'd the host twice.

**Standing order:**
- Do NOT use `/gsd:execute-phase`. It will spawn subagents and OOM.
- Execute TDD cycles directly — read the plan, write the code.
- Before heavy work, run `free -h` to confirm available memory.
