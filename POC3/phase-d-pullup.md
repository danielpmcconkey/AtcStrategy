# Phase D Pull-Up Plan

**Purpose:** Opportunistic early start on Phase D if C.6 finishes with token budget and clock time remaining before the billing cycle resets.

**Decision point:** When C.6 completes, evaluate:
1. How much time remains until the token meter resets?
2. How much of the meter is left?

If the answer to both is "enough to be useful," execute this plan. If it's close enough to the reset that we'd burn tokens for marginal gain, skip it — Phase D launches fresh on the new cycle anyway.

---

## Prerequisites

### Step 0: Lock V1 Output (Dan — from host as root)

After C.6 is confirmed complete, Dan runs this on the host:

```bash
chmod -R a-w /media/dan/fdrive/ai-sandbox/workspace/MockEtlFramework/Output/curated/
```

This makes the V1 baseline physically read-only to everything in the container. BBC and BD run as `sandbox` with no `sudo` — we cannot undo this. Proofmark can still read the files for comparison, but any attempt to write, delete, or overwrite will hard-fail with `Permission denied`. This is the only enforcement mechanism that BBC cannot circumvent.

### Step 1: Job Activation Swap

BBC deactivated V2 jobs during C.6 so the V1 baseline run wouldn't accidentally execute them. Before D.1 can run, the job activation state needs to flip.

**Current state (during C.6):**
- 101 V1 jobs: `is_active = true`
- 101 V2 jobs: `is_active = false`

**Required state for Phase D:**
- 101 V1 jobs: `is_active = false` (V1 baseline is FROZEN — these never run again)
- 101 V2 jobs: `is_active = true`

```sql
-- Deactivate V1 jobs (baseline is frozen after C.6)
UPDATE control.jobs SET is_active = false
WHERE job_name NOT LIKE '%V2' AND job_name NOT LIKE '%_v2';

-- Activate V2 jobs
UPDATE control.jobs SET is_active = true
WHERE job_name LIKE '%V2' OR job_name LIKE '%_v2';
```

**Why deactivate V1?** Defense in depth. The BLUEPRINT already says "never re-run V1" and "run V2 jobs individually." But if BBC ever falls back to a bare `dotnet run` (the auto-advance trap), deactivated V1 jobs won't execute. Belt and suspenders.

Verify after swap:
```sql
SELECT
  CASE WHEN job_name LIKE '%V2' THEN 'V2' ELSE 'V1' END as version,
  is_active,
  count(*)
FROM control.jobs
GROUP BY 1, 2
ORDER BY 1, 2;
```

Expected: V1 false 101, V2 true 101.

---

## What's Cheap (Pull Forward)

### D.1: Run V2 Jobs

Token cost: **Near zero.** It's just bash commands and dotnet compute on Dan's PC.

The blind lead already knows the explicit date loop pattern from C.6. This is the same kind of work — sequential dotnet runs, no subagents, no document reads. Pure compute grind.

Run each V2 job individually through the explicit date loop. Do NOT use the bare all-jobs command — even with V1 deactivated, individual runs give clearer error attribution if something fails.

```bash
# Repeat for each V2 job (101 jobs)
for d in $(seq 0 91); do
  dt=$(date -d "2024-10-01 + $d days" +%Y-%m-%d)
  dotnet run --project JobExecutor -- "$dt" {JobName}V2
done
```

The blind lead should query `control.jobs` for all active V2 job names and loop through them. Each job gets its own 92-day date loop.

### D.2: Run Proofmark Comparisons

Token cost: **Minimal.** Python CLI commands. The blind lead reads the Proofmark config YAMLs and runs comparisons. Results land as JSON files.

Can run these as V2 jobs complete, or batch them all after D.1 finishes. Either way, no subagents needed — just sequential Proofmark CLI calls.

```bash
python3 -m proofmark compare \
  --config POC3/proofmark_configs/{job_name}.yaml \
  --left Output/curated/{v1_output_path} \
  --right Output/double_secret_curated/{v2_output_path} \
  --output POC3/logs/proofmark_reports/{job_name}.json
```

**Output:** 101 JSON reports, each with exit code 0 (PASS), 1 (FAIL), or 2 (ERROR).

---

## What's Expensive (DO NOT Pull Forward)

### D.4: Resolution Agents

Token cost: **High.** Each resolution agent reads the full doc chain (BRD + FSD + test plan + V1 code + V2 code + Proofmark report). With 12+ expected failures, that's 12+ heavy subagent spawns.

**This is what the fresh token cycle is for.** Do not start resolution work during the pull-up window.

### D.6: Document Consistency Verification

Token cost: **Moderate.** Read-only subagents but they read 5 docs per job across all 101 jobs.

**Save for fresh cycle.**

---

## Execution Sequence

If Dan greenlights the pull-up:

1. **Confirm C.6 is fully done.** Verify V1 baseline output exists for all 101 jobs in `Output/curated/`.
2. **Execute job activation swap.** Deactivate V1, activate V2. Verify counts.
3. **Start D.1.** Run V2 jobs individually with explicit date loop. Sequential, no subagents.
4. **As D.1 runs, monitor progress.** This is compute-bound, not token-bound. Let it grind.
5. **If D.1 finishes with time left, start D.2.** Run all 101 Proofmark comparisons. Collect PASS/FAIL/ERROR results.
6. **STOP.** Do not proceed to D.3/D.4 resolution work. Write results to `POC3/logs/validation_state.md` and update `POC3/logs/session_state.md` with current state.
7. **Meter resets.** Fresh cycle begins. Resolution agents launch with a complete picture: all 101 comparison results already in hand, full token budget available for the expensive work.

---

## What This Buys Us

If the pull-up completes D.1 + D.2:
- **Zero exploration cost in the fresh cycle.** No time spent on "what jobs need to run" or "let me figure out the date loop" — it's all done.
- **Immediate triage.** The fresh cycle opens with 101 PASS/FAIL results. We know exactly which jobs need resolution agents and which are clean.
- **Saboteur early read.** We'll already know which of the 12 sabotaged jobs triggered Proofmark failures — before spending a single resolution token.
- **Faster Phase D completion.** The fresh cycle jumps straight to D.3/D.4 resolution work instead of burning the first chunk on compute.

---

## Abort Criteria

Stop the pull-up and save remaining budget if:
- Token meter drops below 10% remaining (need buffer for session state writes)
- Clock is within 15 minutes of reset (not worth starting a new D.1/D.2 batch)
- Any unexpected errors in D.1 that need investigation (don't debug on a dying meter)
- Build failures during V2 runs (saboteur mutations shouldn't cause build failures — if they do, something else is wrong)
