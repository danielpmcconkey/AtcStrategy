# BD Wake-Up — POC6 Session 19

## Paste this to start the session:

```
Read /workspace/AtcStrategy/POC6/BDsNotes/bd-wakeup-poc6-session19.md then tell me where we are.
```

---

## What Happened Last Session (Session 18)

### FIRST COMPLETE END-TO-END RE PIPELINE RUN — Job 373

Job 373 (`DansTransactionSpecial`) ran through the entire pipeline and completed
with APPROVED status from Pat (FBR_EvidenceAudit). Zero main retries. BDD had
one conditional round-trip (WriteBddResponse → ReviewBdd). Everything else
passed first try.

**Proofmark results:** 62/62 comparisons passed STRICT. Both output tables
(`dans_transaction_details`, `dans_transactions_by_state_province`) across all
31 October dates. Byte-for-byte identical OG vs RE output confirmed via diff.

### Infrastructure Confirmed Working

1. **Container rebuild** — `re-curated` and `curated` read-only mounts active.
2. **Hobson's symlinks** — `RE/Jobs/` and `RE/externals/` confirmed working
   (test file written from container, visible on host).
3. **Job conf restored** — `dans_transaction_special.json` had been deleted
   from the repo at some point. Restored from git history (`23c836b`).

### Bugs Fixed

1. **signoff.md outcome type** — Blueprint said `SUCCESS`, engine expected
   `APPROVED` (string maps to `Outcome.APPROVE` enum). Fixed to `APPROVED`.
   Cost two failed FinalSignOff attempts to sort out (first fix used `APPROVE`
   instead of `APPROVED` — my fault).

2. **proofmark-executor.md** — Three issues fixed:
   - Example SQL paths pointed to directories, not CSV files. Added
     `/{output_table_name}.csv` to both lhs and rhs paths.
   - No guidance on directory name case. Agent tried PascalCase (`DansTransactionSpecial`)
     before discovering snake_case (`dans_transaction_special`). Added step to
     list actual directory names before queuing.
   - No OG date discovery step. Agent tried November dates that don't exist.
     Added step to list OG output dates before queuing.
   - **No-delete evidence rule added.** Agent was silently deleting failed
     `proofmark_test_queue` rows and reinserting. New constraint: never delete
     or update existing rows. Insert new batch and filter by `task_id >= first_task_id`.

### Observations

- **Agent self-correction is real but messy.** The proofmark executor went
  through 3 batches (wrong case → directory-not-file → correct) before getting
  it right. It deleted its failed evidence each time. Resourceful but not
  auditable.
- **WriteFsd failed on first run** — agent wrote the FSD file but forgot the
  stdout outcome JSON. Engine got `agent_no_outcome`. Possible context rot
  under sonnet with heavy blueprints. Rewind and retry worked.
- **API latency was 2-4x slower than session 17.** LocateOgSourceFiles took
  6:16 first run (was ~90s before). Not a code issue — external.
- **Job 373 is a gimme.** Zero anti-patterns, same framework on both sides,
  all-STRICT proofmark config. Real test is jobs with anti-patterns, external
  modules, and FUZZY columns.

### Engine Rewind Procedure (learned this session)

The engine is **purely queue-driven**. `current_node` in `re_job_state` is
bookkeeping — never read to decide what runs next. To rewind a job:

```sql
-- 1. Delete the failed task entry
DELETE FROM control.re_task_queue WHERE id = <failed_task_id>;

-- 2. Reset job state (status MUST be RUNNING or engine won't process it)
UPDATE control.re_job_state
SET current_node = '<target_node>', status = 'RUNNING', updated_at = now()
WHERE job_id = '<job_id>';

-- 3. Do NOT manually insert a pending queue entry — the engine does it
--    on startup via ingest_manifest when it sees a RUNNING job.
```

Also delete artifacts: `jobs/{job_id}/artifacts/<artifact>` and
`jobs/{job_id}/process/<NodeName>.json`.

### Pending Work Items

- **Outcome JSON retry mechanism** — When an agent does the work but forgets
  the stdout JSON, the engine should retry once with a focused "give me the
  JSON" prompt instead of failing the whole node. Code change to `agent_node.py`.
  Deferred to next session.
- **FinalSignOff as single agent** — Works for simple jobs. May need to be
  broken into multiple nodes for complex jobs with triage history, fuzzy columns,
  external modules. Watch and see.

## What's Queued for Session 19

### 10-Job Batch Run

Manifest at `/workspace/EtlReverseEngineering/jobs/batch-10-manifest.json`.
Jobs 159-166, 369, 371. Includes `BranchVisitsByCustomerCsvAppendTrailer`
which likely has anti-patterns worth testing.

**Command:**
```
cd /workspace/EtlReverseEngineering
source .venv/bin/activate
python -m workflow_engine jobs/batch-10-manifest.json --etl-start-date 2024-10-01 --etl-end-date 2024-10-31
```

Note: October dates only. OG output is October. Don't use Jan-Dec again.
Note: Model set to Opus for this batch run.

### Hobson TODO (may or may not be done)

- **`external.py` change** — Framework needs to scan `RE/externals/` in
  addition to OG `externals/`. Not blocking for jobs without external modules,
  but needed for jobs that use them. Some of the batch-10 jobs may have externals.

## DB State at End of Session

```sql
-- Job 373 COMPLETE
SELECT job_id, current_node, status FROM control.re_job_state WHERE job_id = '373';
-- 373 | FBR_EvidenceAudit | COMPLETE

-- 62 successful proofmark comparisons
SELECT count(*), status FROM control.proofmark_test_queue
WHERE job_key = 'DansTransactionSpecial_re' GROUP BY status;
-- 62 | Succeeded

-- Full task history (29 completed tasks)
SELECT count(*) FROM control.re_task_queue WHERE job_id = '373' AND status = 'completed';
-- 29
```

## Pending from Prior Sessions
- **Test harness rebuild** — env separation, non-destructive cleanup. Deferred.
- **Per-node model mapping** — opus on spec/triage, sonnet on build, haiku on execution. Deferred.
- **Remove StubNode and stub-based tests** — deferred.
- **Date range param investigation** — Supplying `--etl-end-date 2024-12-31` should produce 92 effective dates (Oct-Dec) of output, but only October was generated. Data lake has Nov/Dec data. Need to trace where the engine or agents constrain output dates and why it ignores the requested range. Deferred.

## Key Files Changed This Session
- `/workspace/EtlReverseEngineering/blueprints/signoff.md` (outcome type fix)
- `/workspace/EtlReverseEngineering/blueprints/proofmark-executor.md` (path fixes, no-delete rule)
- `/workspace/EtlReverseEngineering/jobs/batch-10-manifest.json` (new)
- `/workspace/MockEtlFrameworkPython/JobExecutor/Jobs/dans_transaction_special.json` (restored from git)

## RAM WARNING — READ THIS

Dan's host has 15GB RAM + 16GB swap. This container shares the host's swap.
**Subagent spawning is dangerous.** GSD executor subagents have OOM'd the host twice.

**Standing order:**
- Do NOT use `/gsd:execute-phase`. It will spawn subagents and OOM.
- Execute TDD cycles directly — read the plan, write the code.
- Before heavy work, run `free -h` to confirm available memory.
