# POC5 Session 008 — Wake-Up Prompt

## Copy-paste this into Hobson when you start the next session:

```
Go read /media/dan/fdrive/ai-sandbox/workspace/AtcStrategy/POC5/session-wakeups/session-007-wakeup.md — that's your wakeup prompt. Read it, absorb it, then tell me where you think we left off.
```

---

## Who You Are

You are Hobson. Your CLAUDE.md and MEMORY.md are already loaded — don't re-read them unless something feels off.

## What Happened This Session (007)

### 1. Environment variables set (all 4)

Host (`~/.bashrc`): `ETL_ROOT`, `ETL_RE_OUTPUT`, `ETL_DB_PASSWORD`
Docker (`compose.yml`): `ETL_ROOT`, `ETL_RE_OUTPUT`, `ETL_DB_PASSWORD`

Docker container was recreated (`docker compose down` / relaunch) to pick up the new env vars.

### 2. Repos reconciled

Hobson's MockEtlFramework clone was 19 commits behind BD's. BD's had TaskQueueService, --service mode, POC4 work. Hobson's had uncommitted PathHelper/token changes from sessions 005-006.

Resolution: fast-forwarded Hobson to remote, stash-popped the PathHelper changes, resolved 71 JSON conflicts (assemblyPath tokenisation) and 1 C# conflict (JobExecutorService — dropped stale auto-advance helpers). Committed and pushed. Pulled on BD's side. Both clones now on same commit.

### 3. AppConfig — single source of truth for all configuration

Created `Lib/AppConfig.cs` with three settings sections:
- **PathSettings**: `EtlRoot` (from `ETL_ROOT`), `EtlReOutput` (from `ETL_RE_OUTPUT`)
- **DatabaseSettings**: Host, Username, DatabaseName, Timeout, CommandTimeout (from appsettings.json) + Password (from `ETL_DB_PASSWORD`)
- **TaskQueueSettings**: ParallelThreadCount, PollIntervalMs, IdleCheckIntervalMs, MaxIdleCycles (from appsettings.json)

Design principle: **AppConfig encapsulates all config sourcing.** Consumers read properties without knowing whether the value is a compiled default, an appsettings.json override, or an env var. Env vars are read once at construction and cached in readonly backing fields — no repeated Environment lookups.

`ConnectionHelper.Initialize(appConfig)` and `PathHelper.Initialize(appConfig)` are called at startup in `Program.cs`. PathHelper's token expansion uses an explicit map of known tokens populated from AppConfig, not arbitrary env var lookups.

### 4. TaskQueueService externalized

Constants moved out of TaskQueueService into AppConfig.TaskQueue. Defaults: 4 threads, 5s poll, 30s idle check, 960 max idle cycles (8 hours). All overridable via `JobExecutor/appsettings.json` without rebuilding.

### 5. CLAUDE.md removed from repos

Deleted from MockEtlFramework and proofmark. Added to `.gitignore` in both. MockEtlFramework's had hardcoded DB credentials — that was the main driver.

### 6. Unit tests

17 tests in `Lib.Tests/AppConfigTests.cs` covering: AppConfig defaults, DatabaseSettings defaults, TaskQueueSettings defaults, ConnectionHelper string building, env var sourcing for password, and a negative test proving appsettings.json cannot override the password env var.

### 7. 10 inconsistent DB rows identified

10 rows in `control.jobs` have `job_conf_path` without the `{ETL_ROOT}` prefix (relative paths). PathHelper.Resolve() handles them fine, but they're inconsistent. Added to the task list.

## First Action for Next Session

Read these two files, then you're ready to work:

1. `/media/dan/fdrive/ai-sandbox/workspace/AtcStrategy/POC5/hobson-notes/poc5-task-list.md`
2. `/media/dan/fdrive/ai-sandbox/workspace/AtcStrategy/POC5/hobson-notes/state-of-poc5-2026-03-08-v2.md` (note: partially stale — AppConfig work is not reflected here yet)

Next task on the list is **"Change MockEtlFramework's parallelism approach"** — see Note 1 in the task list for the design (claim-by-job-ID model). Dan will brief you on specifics.

## Key File Paths

| What | Path |
|------|------|
| Task list | `AtcStrategy/POC5/hobson-notes/poc5-task-list.md` |
| State of POC5 (partially stale) | `AtcStrategy/POC5/hobson-notes/state-of-poc5-2026-03-08-v2.md` |
| Dan's vision | `AtcStrategy/POC5/DansNewVision.md` |
| AppConfig | `/media/dan/fdrive/codeprojects/MockEtlFramework/Lib/AppConfig.cs` |
| PathHelper | `/media/dan/fdrive/codeprojects/MockEtlFramework/Lib/PathHelper.cs` |
| ConnectionHelper | `/media/dan/fdrive/codeprojects/MockEtlFramework/Lib/ConnectionHelper.cs` |
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
