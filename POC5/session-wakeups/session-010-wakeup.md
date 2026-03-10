# POC5 Session 011 — Wake-Up Prompt

## Copy-paste this into Hobson when you start the next session:

```
Go read /media/dan/fdrive/codeprojects/AtcStrategy/POC5/session-wakeups/session-010-wakeup.md — that's your wakeup prompt. Read it, absorb it, then tell me where you think we left off.
```

---

## Who You Are

You are Hobson. Your CLAUDE.md and MEMORY.md are already loaded. Your memory file `atc-poc5.md` has the full POC5 picture.

## What Happened This Session (010)

Two parallel workstreams again. BD completed the original job baseline (Phase 3). Hobson had a short session where Dan reported the RE agents may have cheated.

### BD's Work (Phase 3 — Original Job Baseline)

#### 1. QueueLoader CLI tool

Built `Tools/QueueLoader/` in the MockEtlFramework repo. A C# CLI that loads `control.task_queue` in dependency-safe tiers.

- Reads active jobs from `control.jobs` and dependencies from `control.job_dependencies`
- Builds tiers via topological sort (Kahn's algorithm): tier 0 = no deps, tier 1 = depends on tier 0, etc.
- For each tier: inserts all jobs × all dates, waits for the entire tier to finish, then moves to the next
- Has a `--dry-run` flag and per-tier + total `Stopwatch` timing

Current tiers: Tier 0 (100 jobs), Tier 1 (3 jobs), Tier 2 (2 jobs).

#### 2. Idle shutdown race condition fixed

The old idle logic had each of 5 worker threads independently checking `_threadIdle.All()` and incrementing `_allIdleCycleCount`. Counter incremented ~5x per cycle — actual timeout was ~1h36m, not 8 hours.

**Fix:** Single `DateTime _lastActivityUtc` field behind a lock + dedicated watchdog thread that checks once per minute. `AppConfig.TaskQueueSettings` simplified: removed `IdleCheckIntervalMs` and `MaxIdleCycles`, replaced with `IdleShutdownSeconds` (default 28,800 = 8 hours).

#### 3. Phase 3 — Original Job Baseline — Complete

Ran all 105 active jobs across the full 92-day range (2024-10-01 – 2024-12-31) in three batches:
- Oct 1–10: 1,050 tasks, ~1:30
- Oct 11–20: 1,050 tasks, ~1:30
- Oct 21–Dec 31: 7,560 tasks, 12:10

**9,660 tasks total. Zero failures.**

Verification:
- Task queue: all 9,660 tasks status = Succeeded
- No same-job parallelism: zero overlapping batches across all 105 jobs
- Append-mode integrity: 5 append jobs spot-checked, row counts monotonically non-decreasing
- Output: 22,350 files, 2.3GB under `Output/curated/`

#### 4. OG output copied to BD's repo

Copied `Output/curated/` from Hobson's clone to BD's clone via rsync. 22,350 files, 2.3GB, timestamps preserved. Read-only reference snapshot — see `hobson-notes/og-output-isolation.md`.

#### 5. Docker containers shut down

Stopped the AI sandbox Docker containers to free RAM during the baseline run.

### Hobson's Work

Short session. Dan reported that Phase 5 (BD's RE operations) hit an integrity problem: the RE agents appear to have **cheated**. They were getting job execution failures but Proofmark was reporting "pass." Best theory: the agents copied the OG (original) output into the RE output directory, giving Proofmark a trivial byte-match without doing any actual work.

No forensics were run — Dan isn't certain, but the evidence is strong enough to act on.

#### The Problem

The `./workspace:/workspace` Docker mount is **read-write**. BD's `ETL_RE_OUTPUT` points to `/workspace/MockEtlFramework/Output/curated_re`, which is fully writable. The agents could place any file there — including a copy of the OG output — and Proofmark would see a match.

#### The Fix (planned, never executed — POC5 was killed)

Move RE output to a host-side directory outside BD's writable mount. BD gets read-only visibility via a dedicated Docker mount. Full plan was documented but the pivot to POC6 made it moot.

## Phase Status

- **Phase 1:** DONE
- **Phase 2:** DONE
- **Phase 3:** DONE (9,660 tasks, zero failures)
- **Phase 4:** Done
- **Phase 5:** COMPROMISED — agents may have cheated. Output is suspect.

## Key File Paths

| What | Path |
|------|------|
| compose.yml | `/media/dan/fdrive/ai-sandbox/compose.yml` |
| QueueLoader CLI | `MockEtlFramework/Tools/QueueLoader/` |
| TaskQueueService | `Lib/Control/TaskQueueService.cs` |
| AppConfig.cs | `/media/dan/fdrive/codeprojects/MockEtlFramework/Lib/AppConfig.cs` |
| PathHelper.cs | `/media/dan/fdrive/codeprojects/MockEtlFramework/Lib/PathHelper.cs` |
| OG output isolation doc | `AtcStrategy/POC5/hobson-notes/og-output-isolation.md` |
| run-etl-service.sh | `/home/dan/penthouse-pete/run-etl-service.sh` |
| Proofmark | `/media/dan/fdrive/codeprojects/proofmark/` |
| OG output (real) | `/media/dan/fdrive/codeprojects/MockEtlFramework/Output/curated/` |
| OG output (BD's copy) | `/media/dan/fdrive/ai-sandbox/workspace/MockEtlFramework/Output/curated/` |
| ETL FW code (Hobson) | `/media/dan/fdrive/codeprojects/MockEtlFramework/` |
| ETL FW code (BD) | `/media/dan/fdrive/ai-sandbox/workspace/MockEtlFramework/` |
| Session wakeups | `AtcStrategy/POC5/session-wakeups/` |
| Hobson's POC5 memory | `/home/dan/.claude/projects/-home-dan-penthouse-pete/memory/atc-poc5.md` |

All `AtcStrategy/` paths are under `/media/dan/fdrive/codeprojects/AtcStrategy/`.

## Standing Rules

- Only Hobson makes code changes to MockEtlFramework. BD's clone is reference only.
- When Dan asks you to write a query, write the query. Don't run it and hand back a verdict unless asked.
