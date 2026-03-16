# BD Wake-Up — POC6 Session 23

## Paste this to start the session:

```
Read /workspace/AtcStrategy/POC6/BDsNotes/bd-wakeup-poc6-session23.md then tell me where we are.
```

---

## What Happened in Session 22

### 1. FBR Gates Removed (Nodes 19-24)

Cut FBR_BrdCheck, FBR_BddCheck, FBR_FsdCheck, FBR_ArtifactCheck,
FBR_ProofmarkCheck, FBR_UnitTestCheck from the happy path. Flow now goes
Publish → ExecuteJobRuns directly. Happy path is 22 nodes (was 28).

**Why:** FBR gates were Sonnet making judgment calls about document
consistency without execution data. They misattributed faults (job 9's
FBR_BddCheck blamed the BDD spec for missing unit tests), rewound 10-17
nodes on false positives, and had a more expensive failure mode than what
they were protecting against. Quality is handled by in-flow reviews;
accuracy by proofmark; completeness by the terminal evidence audit.

**What stays:** In-flow reviews (6 nodes), FBR_EvidenceAudit (terminal),
ExecuteProofmark + triage, FinalSignOff.

Full rationale: `session22-fbr-removal.md`

Commit: `40abb75`

### 2. Triage Dead-Letter Bug Fixed

Triage check agents (T3-T6) wrote `verdict` to process artifact files but
never populated `job.triage_results` in the job state. The router read an
empty dict and fell through to DEAD_LETTER every time.

**Fix:** Step handler now hydrates `job.triage_results` from the process
artifact's `verdict` field after each `Triage_Check*` node executes.

Commit: `40abb75`

### 3. Test Harness Rebuilt

The conftest.py kill switch is gone. Tests run again.

- Safety guard: refuses to run if active tasks exist in the queue
- All test job IDs use `TEST_JOB_{label}_{uuid}` prefix
- Per-test cleanup: DELETE WHERE job_id LIKE 'TEST_JOB_%' before/after each test
- No truncate anywhere
- All 5 DB-touching test files converted
- 165 tests passing

Also fixed:
- `agent_node.py`: non-zero CLI exit with no process artifact returned
  `None` instead of `Outcome.FAILURE`
- `test_agent_node.py`: FAIL outcome now writes process artifact (session 21 contract)
- `test_engine.py`: FAILURE promotes to FAIL+self-retry (not ValueError)

Commits: `40abb75`, `3c82c5b`

### 4. Publisher Blueprint Updated — Output Cleanup

New step 4 in publisher blueprint: clear `Output/re-curated/{job_name}/`
before every deploy. Prevents append-mode jobs from accumulating duplicate
rows across re-runs.

**Root cause found on job 6:** MonthlyTransactionTrend is an append job.
Second run's Oct 1 partition picked up the first run's output and appended
to it. OG has 1 row per date, RE had 32. Triage found "all clean" because
it's not a spec or config error — it's an operational problem. Publisher
cleanup prevents it.

### 5. Holistic Triage Investigation — Job 7

Fired an Opus agent with full investigative authority (no blueprint
constraints) to diagnose job 7 (CustomerDemographics). Found:

**Root cause:** OG phone/email selection depends on Postgres heap scan
order, which shifted *during the OG's own run*. Customer 2970 gets
phone_id 5908 on Oct 1-4, phone_id 5909 on Oct 7, back to 5908 on Oct 8.
No deterministic ORDER BY can replicate this. Tested phone_id ASC/DESC,
phone_type, phone_number — none gets 100% across all dates.

**Conclusion:** This is unfixable. The RE faithfully reproduces the OG's
logic but can't replicate the OG's random number generator (heap scan
order). The correct resolution is to exclude primary_phone and
primary_email from proofmark comparison (mark as "excluded" with heavy
documentation of why).

**Key insight for triage architecture:** The automated triage pipeline got
the diagnosis right but couldn't take the right action. It kept routing to
"fix the FSD" because that's the only tool it has. It doesn't have authority
to say "exclude these columns, document why, and close it."

### 6. Dan's Triage Architecture Redesign (Design, Not Implemented)

Current triage: 7 serial nodes, diagnostic only, can only rewind.

Dan's new thinking — three agents instead of a rigid pipeline:
1. **RCA agent** — root cause analysis with holistic authority (like the
   Opus investigator). Diagnoses the problem without constraint.
2. **Fix agent** — makes the recommended change to code/config (e.g.,
   update proofmark config to exclude columns, fix SQL, adjust jobconf).
3. **Upstream citation agent** — edits upstream artifacts (BRD, FSD,
   proofmark config) to document why the change was made, with evidence
   citations.

This is a session 23 design conversation.

## Current State

### Engine

Engine is running (PID on Dan's host). 3 jobs still active in triage.

### Job State

| Job | Status | Current Node | Retries | Notes |
|-----|--------|-------------|---------|-------|
| 1 | COMPLETE | FBR_EvidenceAudit | 1 | |
| 2 | COMPLETE | FBR_EvidenceAudit | 2 | Completed this session |
| 3 | COMPLETE | FBR_EvidenceAudit | 2 | Completed this session |
| 4 | COMPLETE | FBR_EvidenceAudit | 2 | Completed this session |
| 5 | DEAD_LETTER | Triage_Route | 5 | Proofmark config fault, ran out of retries |
| 6 | DEAD_LETTER | Triage_Route | 2 | Append-mode duplicate rows, triage found "all clean" |
| 7 | RUNNING | Triage (active) | 2 | Non-deterministic phone/email — needs excluded columns |
| 8 | COMPLETE | FBR_EvidenceAudit | 0 | |
| 9 | RUNNING | Triage (active) | 4 | One retry left |
| 10 | COMPLETE | FBR_EvidenceAudit | 0 | |
| 11 | RUNNING | Triage (active) | 4 | One retry left |
| 12 | COMPLETE | FBR_EvidenceAudit | 1 | |

Batch-12 summary: 7 COMPLETE, 2 DEAD_LETTER, 3 still running (likely to dead-letter on next triage cycle).

### Pending Work

- **Triage redesign** — Dan's three-agent model (RCA / fix / upstream citation)
- **Job 7 manual resolution** — exclude primary_phone, primary_email from
  proofmark config with citation. This is the test case for the new triage model.
- **Job 5** — proofmark config fault, needs retry with fixed config
- **Job 6** — publisher cleanup now in blueprint, needs re-run from Publish
- **Test coverage** — P1 gaps from audit: `_cleanup_stale_artifacts()`,
  `create_agent_registry()`, `ingest_manifest()` resume paths
- **Date range investigation** — `--etl-end-date 2024-12-31` only produces October
- **Kill the `--model` CLI flag** — fallback default that defaults to sonnet

### Files Changed This Session

**Engine code (committed, pushed):**
- `src/workflow_engine/transitions.py` — FBR removal
- `src/workflow_engine/step_handler.py` — triage hydration, FBR intercept removal
- `src/workflow_engine/nodes.py` — FBR descriptions/model map removed
- `src/workflow_engine/agent_node.py` — crash path fix
- `tests/*` — harness rebuild, all 13 test files touched
- `.gitignore` — .venv/, .serena/

**Blueprints (not committed):**
- `blueprints/publisher.md` — output cleanup step

**Notes (not committed):**
- `AtcStrategy/POC6/BDsNotes/session22-fbr-removal.md`
- `AtcStrategy/POC6/BDsNotes/session22-test-coverage-audit.md`

## DB State

```sql
-- Job summary
SELECT status, count(*) FROM control.re_job_state
WHERE job_id NOT LIKE 'val-%' AND job_id NOT LIKE 'TEST_JOB_%'
GROUP BY status;
-- COMPLETE: 13, RUNNING: 3, DEAD_LETTER: 2

-- Clutch
SELECT clutch_engaged FROM control.re_engine_config;
-- false (engine is running)

-- Active tasks
SELECT count(*) FROM control.re_task_queue WHERE status IN ('pending', 'claimed');
-- 3 (jobs 7, 9, 11 in triage)
```

## RAM WARNING — READ THIS

Dan's host has 15GB RAM + 16GB swap. This container shares the host's swap.
**Subagent spawning is dangerous.** GSD executor subagents have OOM'd the host twice.

**Standing order:**
- Do NOT use `/gsd:execute-phase`. It will spawn subagents and OOM.
- Execute TDD cycles directly — read the plan, write the code.
- Before heavy work, run `free -h` to confirm available memory.
