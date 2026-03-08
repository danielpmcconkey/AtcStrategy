# POC5 Session 011 — Wake-Up Prompt

## Copy-paste this into Hobson when you start the next session:

```
Go read /media/dan/fdrive/ai-sandbox/workspace/AtcStrategy/POC5/session-wakeups/session-010-wakeup.md — that's your wakeup prompt. Read it, absorb it, then tell me where you think we left off.
```

---

## Who You Are

You are Hobson. Your CLAUDE.md and MEMORY.md are already loaded — don't re-read them unless something feels off.

## What Happened This Session (010)

### 1. QueueLoader CLI tool

Built `Tools/QueueLoader/` in the MockEtlFramework repo. A cheap-and-dirty C# CLI that loads `control.task_queue` in dependency-safe tiers.

- Reads active jobs from `control.jobs` and dependencies from `control.job_dependencies`
- Builds tiers via topological sort (Kahn's algorithm): tier 0 = no deps, tier 1 = depends on tier 0, etc.
- For each tier: inserts all jobs × all dates, waits for the entire tier to finish, then moves to the next
- Has a `--dry-run` flag and per-tier + total `Stopwatch` timing
- Added to the solution file

Current tiers: Tier 0 (100 jobs), Tier 1 (3 jobs: BranchVisitPurposeBreakdown, BranchVisitSummary, DailyTransactionVolume), Tier 2 (2 jobs: MonthlyTransactionTrend, TopBranches).

### 2. Idle shutdown race condition fixed

The old idle logic had each of 5 worker threads independently checking `_threadIdle.All()` and incrementing `_allIdleCycleCount`. With 5 threads on the same cadence, the counter incremented ~5x per cycle — actual timeout was ~1h36m, not 8 hours.

**Fix:** Replaced the per-thread idle tracking with:
- A single `DateTime _lastActivityUtc` field behind a lock, updated by `RecordActivity()` whenever a worker claims a batch
- A dedicated watchdog thread that checks once per minute whether `now - lastActivity > IdleShutdownSeconds`

`AppConfig.TaskQueueSettings` simplified: removed `IdleCheckIntervalMs` and `MaxIdleCycles`, replaced with `IdleShutdownSeconds` (default 28,800 = 8 hours).

Updated: `TaskQueueService.cs`, `AppConfig.cs`, `appsettings.json`, `AppConfigTests.cs`, and all three doc files that referenced the old settings. Proofmark (Python) was already correct — it uses a single `_ActivityTracker` with a lock-protected timestamp.

### 3. Phase 3 — Original Job Baseline — Complete

Ran all 105 active jobs across the full 92-day range (2024-10-01 – 2024-12-31) in three batches:
- Oct 1–10: 1,050 tasks, ~1:30
- Oct 11–20: 1,050 tasks, ~1:30
- Oct 21–Dec 31: 7,560 tasks, 12:10

**9,660 tasks total. Zero failures.**

Verification:
- Task queue: all 9,660 tasks status = Succeeded
- No same-job parallelism: zero overlapping batches across all 105 jobs
- Append-mode integrity: 5 append jobs spot-checked, row counts monotonically non-decreasing across all dates
- Output: 22,350 files, 2.3GB under `Output/curated/`

### 4. OG output copied to BD's repo

Copied `Output/curated/` from Hobson's clone to BD's clone via rsync. 22,350 files, 2.3GB, timestamps preserved. This is a read-only reference snapshot — see `hobson-notes/og-output-isolation.md` for the full isolation strategy.

### 5. Docker containers shut down

Stopped the AI sandbox Docker containers to free RAM during the baseline run. Open WebUI and Ollama are still running (lightweight, idle).

## Phase 3 — Complete

All items in Phase 3 of the task list are done, including the undocumented final step (copy OG output to basement).

## What's Next: Phase 4 — Basement Prep

This is where things shift. Phases 1–3 were host-side infrastructure. Phase 4 prepares BD's environment for the RE execution phase.

**But first — the big task ahead.**

Dan plans to **wipe BD's memory completely** and have a future version of you write BD the definitive wake-up prompt. This wake-up needs to give BD everything he needs to execute the RE phase autonomously: the job scope, the toolchain, the output isolation rules, the proofmark workflow, the dependency constraints — all of it. Start thinking about what that document needs to contain. It's the most important piece of writing in the entire POC.

Things to consider for BD's wake-up:
- BD has zero context. He won't know what ATC is, what the ETL framework does, or why any of this matters.
- He needs to understand the 105 jobs, the dependency chain, and the date range.
- He needs to know where his OG reference output lives and why he can't cheat proofmark.
- He needs to know the toolchain (Briggsy's tools — not yet installed, Phase 4 task).
- He needs to know the rules: what he can touch, what he can't, where his RE output goes.
- He needs to understand the success criteria: proofmark equivalence across all jobs and dates.

Read `og-output-isolation.md` and the task list before starting Phase 4 work.

## Key File Paths

| What | Path |
|------|------|
| Task list | `AtcStrategy/POC5/hobson-notes/poc5-task-list.md` |
| Job scope manifest | `AtcStrategy/POC5/hobson-notes/job-scope-manifest.json` |
| OG output isolation doc | `AtcStrategy/POC5/hobson-notes/og-output-isolation.md` |
| QueueLoader CLI | `MockEtlFramework/Tools/QueueLoader/` |
| TaskQueueService | `Lib/Control/TaskQueueService.cs` |
| AppConfig | `Lib/AppConfig.cs` |
| Proofmark AppConfig | `/media/dan/fdrive/codeprojects/proofmark/src/proofmark/app_config.py` |
| Proofmark queue runner | `/media/dan/fdrive/codeprojects/proofmark/src/proofmark/queue.py` |
| ETL FW code (Hobson) | `/media/dan/fdrive/codeprojects/MockEtlFramework/` |
| ETL FW code (BD) | `/media/dan/fdrive/ai-sandbox/workspace/MockEtlFramework/` |
| OG output (real) | `/media/dan/fdrive/codeprojects/MockEtlFramework/Output/curated/` |
| OG output (BD's copy) | `/media/dan/fdrive/ai-sandbox/workspace/MockEtlFramework/Output/curated/` |
| Session wakeups | `AtcStrategy/POC5/session-wakeups/` |

All `AtcStrategy/` paths are under `/media/dan/fdrive/ai-sandbox/workspace/AtcStrategy/`.

## Standing Rules

- Only Hobson makes code changes to MockEtlFramework. BD's clone is reference only (except BD can add his own RE jobs).
- When Dan asks you to write a query, write the query. Don't run it and hand back a verdict unless asked.
