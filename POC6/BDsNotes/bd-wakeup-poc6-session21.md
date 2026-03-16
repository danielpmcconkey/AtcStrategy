# BD Wake-Up — POC6 Session 21

## Paste this to start the session:

```
Read /workspace/AtcStrategy/POC6/BDsNotes/bd-wakeup-poc6-session21.md then tell me where we are.
```

---

## What Happened Last Session (Session 20)

### Bug Fix: Work-Node FAIL Transitions

Discovered that WORK nodes had no FAIL edge in the transition table. When a
work node timed out, the engine called `fail_task()` then `raise ValueError`,
never saving job state. Result: zombie jobs (RUNNING status, no queue entry,
unreachable). Fixed in two places:
- `transitions.py`: Added self-retry FAIL edges for all 27 work nodes
- `step_handler.py`: Added `save_job_state()` before the ValueError raise

Commit: `141c33b`

### Per-Node Model Mapping

Added `MODEL_MAP` to `nodes.py`. Models assigned by node complexity:
- **Opus (16 nodes):** WriteBrd, ReviewBrd, WriteBddTestArch, ReviewBdd,
  WriteFsd, ReviewFsd, ReviewJobArtifacts, FBR_BrdCheck, FBR_FsdCheck,
  FBR_ArtifactCheck, FinalSignOff, FBR_EvidenceAudit, Triage_AnalyzeOgFlow,
  plus response nodes WriteBrdResponse, WriteBddResponse, WriteFsdResponse
- **Haiku (2 nodes):** Publish, ExecuteProofmark
- **Sonnet (23 nodes):** Everything else via CLI `--model` fallback

Verified working in batch-12 logs. `--model` CLI flag is now just the
fallback default (defaults to sonnet, so you don't need to specify it).

Commit: `c8c93f9`

### Blueprint Cleanup

Burned all C# references — OG codebase is Python now (Hobson ported it).
Killed stale tokens: `{OG_CS_ROOT}`, `{FW_DOCS}`, `{ORCH_ROOT}`, `{JOB_DIR}`.
All paths are now hardcoded container paths. `{ETL_ROOT}` remains as the only
token, used as a literal string in DB entries for host-side resolution.

Updated `_conventions.md` with external module interface docs (register/execute
pattern, assemblyPath vestigial note, discovery mechanism).

Updated og-flow-analyst Section 4 from "C# vs Python" to "OG vs RE" divergence
checklist (float accumulation, library rounding, pandas behavior).

Commit: `73797b0`

### Other Fixes
- Per-step timeout bumped from 600s to 1800s (30 min)
- Token-budget clutch tested and working
- Docs updated (README + 4 Documentation files)

Commit: `2889873` (docs)

### Job 163 — Dead-Lettered

TransactionAnomalyFlags. Exhausted 5/5 retries, dead-lettered at
FBR_ProofmarkCheck. History: Pat rejected it (session 18/19), FBR rewind
triggered FSD rewrite, BuildJobArtifacts timed out (the zombie bug), rebuilt
successfully after fix, but couldn't survive FBR gauntlet on remaining retries.

### Batch-12 Launched (13 jobs)

12 new jobs (IDs 1-12) plus job 163 (which dead-lettered during the run).
All 12 new jobs progressed to Build/Validate stage before the token-budget
clutch was engaged. Zero retries on all 12.

**Job status at clutch engagement:**

| Job | Node | Retries |
|-----|------|---------|
| 1   | ReviewProofmarkConfig | 0 |
| 2   | BuildProofmarkConfig | 0 |
| 3   | ReviewFsd | 0 |
| 4   | ReviewJobArtifacts | 0 |
| 5   | ReviewJobArtifacts | 0 |
| 6   | ExecuteUnitTests | 0 |
| 7   | BuildJobArtifacts | 0 |
| 8   | FBR_BddCheck | 0 |
| 9   | ExecuteUnitTests | 0 |
| 10  | BuildProofmarkConfig | 0 |
| 11  | ReviewProofmarkConfig | 0 |
| 12  | ReviewUnitTests | 0 |

## What's Queued for Session 21

### Disengage Clutch and Monitor Batch-12

The engine is still running with the clutch engaged. Workers are parked.

**To resume:**
```sql
UPDATE control.re_engine_config SET clutch_engaged = false, updated_at = NOW();
```

**To re-engage (token budget):**
```sql
UPDATE control.re_engine_config SET clutch_engaged = true, updated_at = NOW();
```

Monitor progress:
```sql
SELECT job_id, current_node, status, main_retry_count
FROM control.re_job_state
WHERE job_id NOT LIKE 'val-%'
  AND status = 'RUNNING'
ORDER BY job_id::int;
```

### Post-Batch Analysis

Once batch-12 completes, do the same due diligence as session 19:
- Proofmark results: all STRICT? Any fuzzy/non-strict cheating?
- Genuine remediation or copy-paste?
- Output coverage: all 31 October dates?
- Deployment paths correct?

### Job 163 Triage Decision

Dead-lettered at FBR_ProofmarkCheck. Options:
1. Reset retry count and re-run from FBR_ProofmarkCheck
2. Reset and re-run from BuildProofmarkConfig (proofmark config might be wrong)
3. Scrap it and move on — it's 1 of 103 jobs

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
  output on both sides that were never submitted to proofmark.
- **Kill the `--model` CLI flag** — It's now just a fallback default that
  defaults to sonnet. Either remove it or make it an override for MODEL_MAP.

## DB State at End of Session

```sql
-- Job summary
SELECT status, count(*) FROM control.re_job_state
WHERE job_id NOT LIKE 'val-%' GROUP BY status;
-- COMPLETE: 10, RUNNING: 12, DEAD_LETTER: 1

-- Clutch status
SELECT clutch_engaged FROM control.re_engine_config;
-- true (workers parked)
```

## RAM WARNING — READ THIS

Dan's host has 15GB RAM + 16GB swap. This container shares the host's swap.
**Subagent spawning is dangerous.** GSD executor subagents have OOM'd the host twice.

**Standing order:**
- Do NOT use `/gsd:execute-phase`. It will spawn subagents and OOM.
- Execute TDD cycles directly — read the plan, write the code.
- Before heavy work, run `free -h` to confirm available memory.
