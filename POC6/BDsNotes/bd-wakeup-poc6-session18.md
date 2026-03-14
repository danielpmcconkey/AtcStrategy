# BD Wake-Up — POC6 Session 18

## Paste this to start the session:

```
Read /workspace/AtcStrategy/POC6/BDsNotes/bd-wakeup-poc6-session18.md then tell me where we are.
```

---

## What Happened Last Session (Session 17)

### Path Architecture v2 — IMPLEMENTED

The big problem from session 16 was container/host path boundaries. Agents
were running the ETL framework locally (doesn't work — DB is localhost),
using raw container paths in queue entries, and referencing tokens the host
couldn't resolve.

Hobson designed v2 of the path architecture. Key decisions:

1. **One literal token: `{ETL_ROOT}`** — never resolved by the orchestrator,
   always written as a literal string. Host services expand it from their own
   env var at runtime. Container path differs from host path.

2. **`RE/` directory convention** — RE artifacts deploy to:
   - `{ETL_ROOT}/RE/Jobs/{job_name}/jobconf.json` (job confs)
   - `{ETL_ROOT}/RE/externals/{module_name}_re.py` (external modules)
   - `{ETL_ROOT}/RE/Jobs/{job_name}/proofmark-config.yaml` (proofmark configs)

   These dirs are symlinked from the host codeprojects copy back to the
   container workspace. Publisher writes here, host framework reads via symlink.

3. **`_re` suffix on everything** — `jobName`, `typeName`, module filenames,
   `control.jobs` registration. Prevents collisions with OG entries.

4. **`Output/re-curated/`** — RE output goes here (not `Output/curated/`).
   Mounted read-only in the container.

5. **`Output/curated/`** — OG output, read-only mount at
   `{ETL_ROOT}/Output/curated/` inside the container.

### Blueprint Updates (7 files in EtlReverseEngineering)

- **_conventions.md** — Split path tokens into orchestrator-resolved vs literal.
  Added `RE/` directory convention, OG vs RE job identity section, queue entry
  path rules with correct example SQL.
- **builder.md** — `outputDirectory` = `Output/re-curated`, `_re` naming for
  jobName/typeName/filenames, external modules in `{job_dir}/artifacts/code/`
  (killed `transforms/` subfolder).
- **publisher.md** — Full rewrite. Deploys to `RE/Jobs/` and `RE/externals/`.
  Registers as `{job_name}_re` in `control.jobs` with OG description copy.
  Uses `{ETL_ROOT}/RE/Jobs/...` as literal token path.
- **job-executor.md** — Uses `{job_name}_re` in task_queue inserts, verifies
  output in `re-curated/`.
- **proofmark-executor.md** — Full rewrite. Copies config to `RE/Jobs/`,
  queue entries use `{ETL_ROOT}` literal paths. lhs=curated (OG),
  rhs=re-curated (RE).
- **artifact-reviewer.md** — Added RE naming convention section so it won't
  flag `_re` suffixes as FSD mismatches.
- **evidence-auditor.md** — Same `_re` convention awareness for Pat.

### DB Cleanup

- Deleted 62 stale `proofmark_test_queue` entries for job_373
- Deleted 28 `re_task_queue` entries for job_373
- Deleted `re_job_state` entry for job_373
- Fixed `control.jobs` entry for OG job 373 — publisher had overwritten
  `job_conf_path` with an EtlRE artifacts path. Restored to
  `{ETL_ROOT}/JobExecutor/Jobs/dans_transaction_special.json`.

### Rogue Output Cleanup

- Dan deleted `/workspace/Output/` — rogue output from agent running ETL
  framework locally with wrong cwd.
- OG output at `{ETL_ROOT}/Output/curated/dans_transaction_special/` confirmed
  legitimate (host-side ETL run, predates our RE work).

### Transition Doc

- Removed ghost `TriageProofmarkFailures` row from state machine transition
  table. Was never implemented — replaced by T1-T7 triage sub-pipeline.

### Directory Setup

- Created `/workspace/MockEtlFrameworkPython/RE/Jobs/` and
  `/workspace/MockEtlFrameworkPython/RE/externals/`.

## What Needs to Happen Before Running

1. **Container rebuild** — `re-curated` read-only mount not yet active.
   Docker inspect showed only `curated` mounted. Need compose change + rebuild.

2. **Hobson's symlinks** — `RE/Jobs/` and `RE/externals/` on the host pointing
   back to workspace. He was working on these when session ended.

3. **Hobson's `external.py` change** — Framework needs to scan `RE/externals/`
   in addition to OG `externals/`. NOT blocking for job 373 (no external
   modules), but needed for jobs that use them.

4. **Job 373 re-seed** — `re_job_state` row was deleted. Engine needs a fresh
   entry to start the pipeline. Either engine creates on launch or manual insert.

## Goal

Re-run the full RE pipeline on job 373 (`dans_transaction_special`) from the
beginning. All artifacts were wiped. Clean slate.

## DB State at End of Session

```sql
-- Job 373 OG registration restored
SELECT job_id, job_name, job_conf_path FROM control.jobs WHERE job_id = 373;
-- job_id=373, job_name='DansTransactionSpecial',
-- job_conf_path='{ETL_ROOT}/JobExecutor/Jobs/dans_transaction_special.json'

-- No RE job state
SELECT * FROM control.re_job_state WHERE job_id = '373';
-- (0 rows)

-- No stale queue entries
SELECT count(*) FROM control.proofmark_test_queue WHERE job_key = 'job_373';
-- 0
SELECT count(*) FROM control.re_task_queue WHERE job_id = '373';
-- 0
```

## Pending from Prior Sessions
- **Test harness rebuild** — env separation, non-destructive cleanup. Deferred.
- **Per-node model mapping** — opus on spec/triage, sonnet on build, haiku on execution. Deferred.
- **Remove StubNode and stub-based tests** — deferred.

## Key Files Changed This Session
- `/workspace/EtlReverseEngineering/blueprints/_conventions.md`
- `/workspace/EtlReverseEngineering/blueprints/artifact-reviewer.md`
- `/workspace/EtlReverseEngineering/blueprints/builder.md`
- `/workspace/EtlReverseEngineering/blueprints/evidence-auditor.md`
- `/workspace/EtlReverseEngineering/blueprints/job-executor.md`
- `/workspace/EtlReverseEngineering/blueprints/proofmark-executor.md`
- `/workspace/EtlReverseEngineering/blueprints/publisher.md`
- `/workspace/AtcStrategy/POC6/BDsNotes/state-machine-transitions.md`

## RAM WARNING — READ THIS

Dan's host has 15GB RAM + 16GB swap. This container shares the host's swap.
**Subagent spawning is dangerous.** GSD executor subagents have OOM'd the host twice.

**Standing order:**
- Do NOT use `/gsd:execute-phase`. It will spawn subagents and OOM.
- Execute TDD cycles directly — read the plan, write the code.
- Before heavy work, run `free -h` to confirm available memory.
