# BD Wake-Up — POC6 Session 20

## Paste this to start the session:

```
Read /workspace/AtcStrategy/POC6/BDsNotes/bd-wakeup-poc6-session20.md then tell me where we are.
```

---

## What Happened Last Session (Session 19)

### Blueprint Overhaul — Remediation-First Anti-Pattern Policy

Discovered agents were copy-pasting OG external module code with `_re` suffix
instead of remediating. Root cause: 10 blueprints across the pipeline were
structurally biased toward faithful reproduction. Rewrote all of them to
enforce remediation-first policy. Key files changed:
- `fsd-writer.md` — complete rewrite, externals as last resort
- `bdd-writer.md` — tests remediated behavior unless load-bearing
- `builder.md` — removed unconditional reproduce instruction
- `brd-writer.md` — remediation is default recommendation
- Plus 6 reviewer/auditor blueprints tightened

Commit: `310fe20`

### Batch Run Results

**Run 1 (10 jobs, old blueprints):** 4 completed, 6 failed at `ExecuteJobRuns`.
Failure cause: phantom import in `_load_all()` for a job cut between POC5/POC6.
Hobson replaced hardcoded import list with directory scan.

**Run 2 (6 failed jobs, new blueprints):** 5 completed with genuine remediation.
- Jobs 160, 166: External modules fully eliminated — pure framework modules
- Jobs 161, 164, 165: Externals reduced to thin I/O shims
- Job 163: Still running (FBR kickback, slow)
- All proofmark STRICT, no cheating, correct deployments

**Completed jobs total:** 159, 160, 161, 162, 164, 165, 166, 369, 371, 373

### Infrastructure Fixes
- `run_until_drained` timeout bumped from 1h to 4h (was killing healthy runs)
- Orphaned task cleanup procedure confirmed working
- Monitor script at `/tmp/batch-monitor.sh` (needs PID update each run)

### Hobson's Fixes (MockEtlFrameworkPython)
- Replaced `_load_all()` hardcoded import list with `pkgutil.iter_modules` scan
- 156 tests passing
- BD's stale local changes (phantom stub, `_re` imports) cleaned up

## What's Queued for Session 20

### Per-Node Model Mapping

Currently all nodes use whatever `--model` is passed on the CLI (default sonnet).
Every node gets the same model. We want to assign models by node type:
- **Opus** for spec/design/triage nodes (WriteBrd, WriteFsd, FBR checks, Pat)
- **Sonnet** for build/execution nodes (BuildJobArtifacts, BuildUnitTests, ExecuteJobRuns)
- **Haiku** for mechanical execution (ExecuteProofmark, Publish)

#### Where the model gets set today

1. CLI: `--model opus` in `__main__.py` → `EngineConfig.agent_model`
2. `step_handler.py` creates `AgentNode` instances, passes `config.agent_model`
3. `AgentNode.__init__` stores `self.model`, passes it to `claude --model X`

#### Implementation approach

Add a `MODEL_MAP: dict[str, str]` (node_name → model) to `agent_node.py` or
`models.py`. `StepHandler` looks up the node's model from the map, falling back
to `config.agent_model` if not mapped. Could also be a CLI config file.

Consider: should the map be hardcoded, in a config file, or a CLI param per tier?

### Batch-12 Manifest Ready

`jobs/batch-12-manifest.json` — next 12 jobs from the scope manifest. Jobs 1-12:
CustomerAccountSummary, DailyTransactionSummary, TransactionCategorySummary,
LargeTransactionLog, DailyTransactionVolume, MonthlyTransactionTrend,
CustomerDemographics, CustomerContactInfo, CustomerSegmentMap,
CustomerAddressHistory, CustomerFullProfile, AccountBalanceSnapshot.

**Command:**
```
cd /workspace/EtlReverseEngineering
source .venv/bin/activate
python -m workflow_engine jobs/batch-12-manifest.json --etl-start-date 2024-10-01 --etl-end-date 2024-10-31 --model opus --n-jobs 12
```

Note: October dates only. `--n-jobs 12` for 12 workers.

## DB State at End of Session

```sql
-- 10 complete, 1 running (163), 7 dead-letter (validation)
SELECT status, count(*) FROM control.re_job_state
WHERE job_id NOT LIKE 'val-%' GROUP BY status;
-- COMPLETE: 10, RUNNING: 1

-- Job 163 status
SELECT job_id, current_node, status FROM control.re_job_state WHERE job_id = '163';
-- Check if it finished or dead-lettered overnight
```

## Pending from Prior Sessions

- **Date range param investigation** — Supplying `--etl-end-date 2024-12-31`
  should produce 92 effective dates (Oct-Dec) of output, but only October was
  generated. Data lake has Nov/Dec data. Need to trace where the engine or
  agents constrain output dates.
- **Outcome JSON retry mechanism** — When an agent does the work but forgets
  the stdout JSON, the engine should retry once with a focused "give me the
  JSON" prompt instead of failing the whole node.
- **Test harness rebuild** — env separation, non-destructive cleanup. Deferred.
- **Remove StubNode and stub-based tests** — deferred.
- **Add `started_at` / `attempt` columns to `re_job_state`** — for tracking
  wall-clock per attempt and restart history.
- **Empty-vs-empty proofmark verification** — Job 164 had 30 dates with empty
  output on both sides that were never submitted to proofmark. Should
  empty-vs-empty get a submission to prove it?

## Key Files Changed This Session
- `blueprints/fsd-writer.md` (complete rewrite)
- `blueprints/bdd-writer.md`, `brd-writer.md`, `builder.md` (anti-pattern policy)
- `blueprints/fsd-reviewer.md`, `brd-reviewer.md`, `bdd-reviewer.md` (tightened)
- `blueprints/artifact-reviewer.md`, `evidence-auditor.md`, `signoff.md` (tightened)
- `src/workflow_engine/__main__.py` (timeout 1h → 4h)
- `jobs/batch-6-redo-manifest.json` (new)
- `jobs/batch-12-manifest.json` (new)
- `sql/RE_status.sql` (new — dashboard query)

## RAM WARNING — READ THIS

Dan's host has 15GB RAM + 16GB swap. This container shares the host's swap.
**Subagent spawning is dangerous.** GSD executor subagents have OOM'd the host twice.

**Standing order:**
- Do NOT use `/gsd:execute-phase`. It will spawn subagents and OOM.
- Execute TDD cycles directly — read the plan, write the code.
- Before heavy work, run `free -h` to confirm available memory.
