# BD Wake-Up — POC6 Session 14

## Paste this to start the session:

```
Read /workspace/AtcStrategy/POC6/BDsNotes/bd-wakeup-poc6-session14.md then tell me where we are.
```

---

## What Happened Last Session

1. **v0.2: COMPLETE** (session 13). All 4 phases (4-7) built and shipped in one session.
   - Phase 4: Postgres foundations (schema, pool, CRUD, concurrency proofs)
   - Phase 5: Queue write paths (enqueue_next, ingest_manifest)
   - Phase 6: Worker pool (N threads, configurable, claim-execute loop)
   - Phase 7: SM wiring (StepHandler, engine rewrite, test rewrite — run_job deleted)
   - 132 tests total, 16 requirements, all pushed to origin.

2. **v0.3 is next: Agent Integration.** Hobson is writing agent blueprints in the EtlRE repo.
   BD's job is the plumbing — waking up Claude CLI agents with "go read specific_blueprint.md on job 123."

## What Needs to Happen

### Recommended Order of Operations

**1. Housekeeping (quick, do first)**
- Update `ROADMAP.md` — mark phases 4-7 as complete, add v0.3 milestone
- Update `REQUIREMENTS.md` — mark TQ-01 through TS-03 as done, add AG-01/AG-02/AG-03
- Update `.planning/STATE.md` if it exists
- Optionally add VAL-01/VAL-02 (transition table static validation, path coverage) if Dan wants them in v0.3

**2. Recon: Check Hobson's blueprint work**
- `ls /workspace/EtlReverseEngineering/` for any new blueprint directories/files
- `git log --oneline -20` to see what Hobson has committed
- Understand the blueprint format: what does a blueprint.md look like? What info does it contain?
- This determines the interface between the orchestrator and agent invocations

**3. Design the agent invocation layer (v0.3 Phase 8)**
- Replace `StubWorkNode.execute()` / `StubReviewNode.execute()` with real Claude CLI calls
- Each node maps to a blueprint file — the blueprint IS the system prompt
- Invocation pattern: `claude --system-prompt "$(cat blueprint.md)" --input "job_id=123, ..."`
- Need to figure out: how does the agent get its context? (job manifest entry, current state, prior artifacts)
- Need to figure out: how does the agent return structured outcomes? (SUCCESS/FAILURE/APPROVE/CONDITIONAL/FAIL + reason)
- Need to figure out: cost caps per invocation (AG-03)

**4. Build the invocation plumbing (v0.3 Phase 8 execution)**
- Create `AgentNode` class that replaces stubs
- AgentNode.execute(): shell out to Claude CLI with blueprint as system prompt
- Parse structured response back to Outcome enum
- Wire into StepHandler (it already uses the node registry — just swap the implementations)
- Keep stubs available for testing (feature flag or separate registry)

**5. Integration testing (v0.3 Phase 9)**
- Run a single job through the real pipeline with real agents
- Validate that agent outputs parse to valid Outcomes
- Validate that the queue lifecycle works end-to-end with real agent latency
- Cost tracking / reporting

### Key Decisions Needed From Dan

- **Blueprint location convention:** Where in the repo do blueprints live? What's the naming pattern?
- **Agent context:** What gets passed to each agent beyond the blueprint? Job manifest entry? Prior node outputs? Current job state?
- **Output format:** How should agents structure their response so StepHandler can parse it to an Outcome?
- **Cost caps:** Hard kill after $X per invocation? Per job? Global budget?
- **Which nodes to de-stub first?** All at once or incremental (e.g., Plan nodes first, then Define, etc.)?

### Key Files

- `/workspace/AtcStrategy/POC6/BDsNotes/state-of-poc6.md` — current project state
- `/workspace/EtlReverseEngineering/.planning/PROJECT.md` — project context
- `/workspace/EtlReverseEngineering/.planning/REQUIREMENTS.md` — requirements (needs v0.3 additions)
- `/workspace/EtlReverseEngineering/.planning/ROADMAP.md` — roadmap (needs v0.3 additions)
- `/workspace/EtlReverseEngineering/src/workflow_engine/step_handler.py` — where agent results get processed
- `/workspace/EtlReverseEngineering/src/workflow_engine/nodes.py` — stubs to be replaced with AgentNode
- `/workspace/AtcStrategy/POC6/HobsonsNotes/job-scope-manifest.json` — 103 jobs

### The v0.2 Stack (for reference)

```
manifest.json → ingest_manifest() → re_task_queue (Postgres)
                                          ↓
WorkerPool (N threads) → claim_task() → StepHandler.__call__()
                                          ↓
                              load_job_state() → node.execute(job) → _resolve_outcome()
                                          ↓
                              save_job_state() → complete_task() → enqueue_task(next_node)
```

The `node.execute(job)` call is where stubs become real agents.

---

## RAM WARNING — READ THIS

Dan's host has 15GB RAM + 16GB swap. This container shares the host's swap.
**Subagent spawning is dangerous.** GSD executor subagents have OOM'd the host twice.

**Standing order:**
- Do NOT use `/gsd:execute-phase`. It will spawn subagents and OOM.
- Execute TDD cycles directly — read the plan, write the code.
- Before heavy work, run `free -h` to confirm available memory.
