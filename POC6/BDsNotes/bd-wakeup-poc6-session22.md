# BD Wake-Up — POC6 Session 22

## Paste this to start the session:

```
Read /workspace/AtcStrategy/POC6/BDsNotes/bd-wakeup-poc6-session22.md then tell me where we are.
```

---

## What Happened Last Session (Session 21)

### File-Based Outcome Contract (Major Fix)

The engine was killing jobs that succeeded. 23% of batch-12 (3/13) had
correct process artifacts on disk but the engine's `_extract_outcome_json`
couldn't find the outcome in Claude CLI's conversational stdout. The parser
splits on `{` and hunts for JSON objects — gets confused by all the JSON
the agent reads/writes/discusses during execution.

**Fix:** Engine now reads the outcome from the process artifact file the
agent writes to disk. Stdout parsing is retained as fallback only.

All 29 blueprints updated: process artifacts now written on ALL outcomes
(SUCCESS, FAIL, APPROVED, CONDITIONAL, REJECTED) with standardized
`outcome`/`reason`/`conditions` fields. Conventions doc flipped the
critical rule.

Commit: `d04f180`

### Proofmark Config Schema in Blueprints

Agents were generating structurally wrong proofmark YAML configs. The
proofmark-builder blueprint said "see the docs" but agents (Sonnet) were
guessing at the format — inventing per-column dicts like
`column_name: { match: strict }` instead of the actual schema (lists under
`excluded:` and `fuzzy:`, with strict as implicit default).

327 out of 777 proofmark queue entries were Failed, mostly from bad configs.

**Fix:** Embedded the complete YAML schema with examples directly in both
the proofmark-builder and proofmark-reviewer blueprints. Added explicit
"DO NOT" warnings for the exact wrong formats agents were generating.
Reviewer now validates schema structure before evaluating content.

### Batch-12 Manual Interventions

Several jobs required manual DB interventions during the run:

| Job | Issue | Action |
|-----|-------|--------|
| 163 | Dead-lettered at FBR_ProofmarkCheck — retries burned on zombie bug from session 20 | Reset retry count, re-enqueued FBR_ProofmarkCheck. **Completed successfully.** |
| 2   | Dead-lettered at Publish — 5 consecutive Haiku stdout parse failures | Reset to FBR_BrdCheck (deployment was already done). Still running at kill time. |
| 10  | Dead-lettered via triage — ExecuteProofmark passed 31/31 but engine saw FAILURE | Reset to FinalSignOff (bypassed triage). Still running at kill time. |
| 6   | Dead-lettered at Publish — 5 consecutive Haiku stdout parse failures | Reset to FBR_BrdCheck (deployment was already done). |
| 8   | Dead-lettered at FBR_EvidenceAudit (terminal gate) — Opus stdout parse failure | Reset, re-enqueued FBR_EvidenceAudit. Still running at kill time. |

### Engine Kill (Unclean Shutdown)

Dan killed the engine with `kill` instead of using the clutch. 7 orphaned
`claimed` tasks had to be manually failed. Dan restarted the engine briefly
(up-arrow) but it wasn't left running.

A straggler agent on job 1 (CustomerAccountSummary) kept running after the
kill. It retried proofmark 3 times, fixed its own config schema, and got
31/31 PASS. We patched its process artifact with the new `outcome` field
and advanced it to FinalSignOff.

### Analysis Written

Full writeup of the stdout parsing failure at:
`/workspace/AtcStrategy/POC6/BDsNotes/analysis-stdout-json-parsing.md`

## What's Queued for Session 22

### Restart the Engine

The engine is NOT running. 7 RUNNING jobs need to resume + 3 that were
manually advanced. Before restarting:

1. Check for any remaining orphaned `claimed` tasks:
   ```sql
   SELECT id, job_id, node_name FROM control.re_task_queue
   WHERE status = 'claimed';
   ```
2. If clean, restart:
   ```bash
   cd /workspace/EtlReverseEngineering
   python -m workflow_engine jobs/batch-12-manifest.json --etl-start-date 2024-10-01 --etl-end-date 2024-10-31 --n-jobs 13
   ```

**Job state at session end:**

| Job | Status | Current Node | Notes |
|-----|--------|-------------|-------|
| 1   | RUNNING | FinalSignOff | Proofmark 31/31, advanced manually |
| 2   | RUNNING | BuildJobArtifacts | FBR rewound it |
| 3   | RUNNING | WriteFsd | FBR rewound it |
| 4   | RUNNING | BuildProofmarkConfig | Mid-build |
| 5   | RUNNING | ExecuteJobRuns | Deep in validation |
| 6   | RUNNING | FBR_BrdCheck | Was dead-lettered at Publish (same parse bug as job 2), reset |
| 7   | RUNNING | ExecuteProofmark | Was mid-flight at kill |
| 8   | RUNNING | FBR_EvidenceAudit | Reset after terminal-fail parse bug |
| 9   | RUNNING | BuildUnitTests | FBR rewound it |
| 10  | RUNNING | FinalSignOff | Bypassed triage, proofmark was 31/31 |
| 11  | RUNNING | WriteBddTestArch | FBR rewound it |
| 12  | RUNNING | Publish | Was mid-flight at kill |
| 163 | COMPLETE | FBR_EvidenceAudit | Fixed from session 20 dead letter |

All 12 batch-12 jobs are RUNNING. No dead letters remaining.

### Monitor the File-Based Outcome Contract

This is the first run with the new contract. Watch for:
- Do agents actually write process artifacts on FAIL/REJECTED? (new behavior)
- Does the file-based reading work end-to-end?
- Any fallback-to-stdout events? (log line: `artifact_missing_fallback_stdout`)
- Proofmark configs — are agents generating valid YAML with the new schema docs?

### Post-Batch Analysis (When Complete)

Same due diligence as session 19:
- Proofmark results: all STRICT? Any fuzzy/non-strict?
- Genuine remediation or copy-paste?
- Output coverage: all 31 October dates?
- Deployment paths correct?

## Pending from Prior Sessions

- **Date range param investigation** — `--etl-end-date 2024-12-31` should
  produce Oct-Dec but only October generated. Need to trace where dates
  get constrained.
- **Test harness rebuild** — env separation, non-destructive cleanup.
- **Remove StubNode and stub-based tests** — deferred.
- **Add `started_at` / `attempt` columns to `re_job_state`** — wall-clock
  per attempt and restart history.
- **Empty-vs-empty proofmark verification** — Job 164 had 30 dates with
  empty output on both sides never submitted to proofmark.
- **Kill the `--model` CLI flag** — fallback default that defaults to sonnet.
- **Tee engine stdout to log file** — no paper trail on agent failures
  currently. Need `tee` or structlog file handler.

## DB State at End of Session

```sql
-- Job summary
SELECT status, count(*) FROM control.re_job_state
WHERE job_id NOT LIKE 'val-%' GROUP BY status;
-- COMPLETE: 11, RUNNING: 12

-- Clutch status
SELECT clutch_engaged FROM control.re_engine_config;
-- false

-- Orphaned tasks
SELECT count(*) FROM control.re_task_queue WHERE status = 'claimed';
-- Should be 0. If not, fail them before restart.
```

## RAM WARNING — READ THIS

Dan's host has 15GB RAM + 16GB swap. This container shares the host's swap.
**Subagent spawning is dangerous.** GSD executor subagents have OOM'd the host twice.

**Standing order:**
- Do NOT use `/gsd:execute-phase`. It will spawn subagents and OOM.
- Execute TDD cycles directly — read the plan, write the code.
- Before heavy work, run `free -h` to confirm available memory.
