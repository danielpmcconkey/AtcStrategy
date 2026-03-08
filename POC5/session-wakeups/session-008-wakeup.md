# POC5 Session 009 — Wake-Up Prompt

## Copy-paste this into Hobson when you start the next session:

```
Go read /media/dan/fdrive/ai-sandbox/workspace/AtcStrategy/POC5/session-wakeups/session-008-wakeup.md — that's your wakeup prompt. Read it, absorb it, then tell me where you think we left off.
```

---

## Who You Are

You are Hobson. Your CLAUDE.md and MEMORY.md are already loaded — don't re-read them unless something feels off.

## What Happened This Session (008)

### 1. Parallelism redesign — claim-by-job model

Rewrote `TaskQueueService.cs`. The serial/parallel thread distinction is gone. Now N identical threads (default 5), each claims ALL pending tasks for a single job using PostgreSQL advisory locks (`pg_try_advisory_xact_lock(hashtext(job_name))`), then runs them sequentially in effective_date order. Different jobs run in parallel across threads. If a task fails, remaining tasks in the batch are marked Failed.

Renamed `ParallelThreadCount` → `ThreadCount` in `AppConfig.TaskQueueSettings`, `appsettings.json`, and tests. Default is 5 (matches old 4 parallel + 1 serial = 5 total).

### 2. Documentation restructured

Broke the monolithic `Architecture.md` into 15 focused reference docs in a tree under `Documentation/`. Added `README.md` as a routing table ("looking for X? go to Y"). Deleted `ProjectSummary.md` (vestigial). Architecture.md kept as-is with a deprecation note at the top. A background audit confirmed all content was carried over — 11 gaps found and patched.

New tree:
```
Documentation/
├── README.md, overview.md, cli.md, configuration.md, dataframes.md, testing.md
├── modules/ (overview, data-sourcing, transformation, data-frame-writer, csv-file-writer, parquet-file-writer, external)
└── control/ (overview, job-executor-service, task-queue-service)
```

### 3. AtcStrategy repos synced

Both clones (`/media/dan/fdrive/codeprojects/AtcStrategy/` and `/media/dan/fdrive/ai-sandbox/workspace/AtcStrategy/`) are now on the same commit. POC5/ directory committed and pushed. Two stray POC3 files committed.

### 4. POC5 job scope manifest

Extracted the 105-job manifest from POC4 commit `6e069d0` (before BD whittled it to 5 for the dry run). Saved to `POC5/hobson-notes/job-scope-manifest.json`. Structure is bare-bones: job_id, job_name, job_conf_path per entry.

### 5. Database cleaned to baseline

- Deleted the 5 V4 (RE) jobs and their 55 run records
- `control.jobs` now has exactly 105 rows, matching the manifest
- All 105 jobs set to `is_active = true`
- `control.task_queue` truncated
- `control.job_runs` truncated
- `control.comparison_queue` dropped (Dan did this manually — Proofmark references it, will be fixed later)
- Dan granted `TRUNCATE ON control.job_runs TO claude`

### 6. Job conf paths tokenised

5 remaining rows in `control.jobs` had bare relative `job_conf_path` values (the other 5 of the original 10 were the V4 jobs we deleted). Fixed with `UPDATE ... SET job_conf_path = '{ETL_ROOT}/' || job_conf_path`. All 105 now have `{ETL_ROOT}/` prefix.

### 7. Output path structure verified

All 97 jobs with file writers use `Output/curated/{jobDirName}/{outputTableDirName}/{etl_effective_date}/{fileName}`. All 8 jobs that use External modules for output follow the same structure manually via `Path.Combine`. No inconsistencies.

### 8. Release build running

`dotnet build -c Release` on `/media/dan/fdrive/codeprojects/MockEtlFramework/`. Dan launched the service from his own terminal (decoupled from Claude session): `JobExecutor/bin/Release/net8.0/JobExecutor --service`. Task queue is empty — service is idling, waiting for work.

### 9. Default browser changed

Changed Dan's default browser from Firefox to LibreWolf (Flatpak): `xdg-settings set default-web-browser io.gitlab.librewolf-community.desktop`.

## Phase 1 — Complete

All items in Phase 1 of the task list are done, including "Start running MockEtlFramework as a long-running service."

## First Action for Next Session

Read these two files, then you're ready to work:

1. `/media/dan/fdrive/ai-sandbox/workspace/AtcStrategy/POC5/hobson-notes/poc5-task-list.md`
2. `/media/dan/fdrive/ai-sandbox/workspace/AtcStrategy/POC5/hobson-notes/job-scope-manifest.json`

Phase 1 is done. Phase 2 (Proofmark) and Phase 3 (Original Job Baseline) are next. The service is already running — Dan will likely want to populate the task queue and start the baseline run (Phase 3) while Proofmark work happens in parallel. Ask Dan what's next.

**Important context:** `control.comparison_queue` was dropped. Proofmark references it. This needs fixing before Proofmark can run. Don't forget.

## Key File Paths

| What | Path |
|------|------|
| Task list | `AtcStrategy/POC5/hobson-notes/poc5-task-list.md` |
| Job scope manifest | `AtcStrategy/POC5/hobson-notes/job-scope-manifest.json` |
| Documentation index | `MockEtlFramework/Documentation/README.md` |
| AppConfig | `/media/dan/fdrive/codeprojects/MockEtlFramework/Lib/AppConfig.cs` |
| TaskQueueService | `/media/dan/fdrive/codeprojects/MockEtlFramework/Lib/Control/TaskQueueService.cs` |
| Program.cs | `/media/dan/fdrive/codeprojects/MockEtlFramework/JobExecutor/Program.cs` |
| appsettings.json | `/media/dan/fdrive/codeprojects/MockEtlFramework/JobExecutor/appsettings.json` |
| Unit tests | `/media/dan/fdrive/codeprojects/MockEtlFramework/Lib.Tests/AppConfigTests.cs` |
| ETL FW code (Hobson's clone) | `/media/dan/fdrive/codeprojects/MockEtlFramework/` |
| ETL FW code (BD's clone) | `/media/dan/fdrive/ai-sandbox/workspace/MockEtlFramework/` |
| Proofmark (host) | `/media/dan/fdrive/codeprojects/proofmark/` |
| Session wakeups | `AtcStrategy/POC5/session-wakeups/` |

All `AtcStrategy/` paths are under `/media/dan/fdrive/ai-sandbox/workspace/AtcStrategy/`.

## Standing Rule

Only Hobson makes code changes to MockEtlFramework. BD's clone is reference only (except BD can add his own RE jobs).
