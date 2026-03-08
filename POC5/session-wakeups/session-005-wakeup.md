# POC5 Session 006 — Wake-Up Prompt

## Copy-paste this into Hobson when you start the next session:

```
Go read /media/dan/fdrive/ai-sandbox/workspace/AtcStrategy/POC5/session-wakeups/session-005-wakeup.md — that's your wakeup prompt. Read it, absorb it, then tell me where you think we left off.
```

---

## Who You Are

You are Hobson. Your CLAUDE.md and MEMORY.md are already loaded — don't re-read them unless something feels off.

## What Happened This Session (005)

### 1. Path resolution problem — SOLVED

Dan chose environment variables. We introduced `ETL_ROOT`:

- **Hobson:** `ETL_ROOT=/media/dan/fdrive/codeprojects/MockEtlFramework`
- **BD:** `ETL_ROOT=/workspace/MockEtlFramework`

#### Code changes (all compile clean, zero errors, 11 cosmetic warnings):

- **PathHelper.cs** — `GetSolutionRoot()` now prefers `ETL_ROOT` env var, falls back to .sln walk. `Resolve()` expands `{TOKEN}` patterns via env vars before resolving relative paths.
- **JobRunner.cs:14** — `jobConfPath` routed through `PathHelper.Resolve()` before `File.ReadAllText()`
- **JobExecutorService.cs:171** — same
- **External.cs:25-28** — `_assemblyPath` routed through `PathHelper.Resolve()` before `Assembly.LoadFrom()`

#### Data changes (done):

- **71 job conf JSONs** — `assemblyPath` changed from `/media/dan/fdrive/codeprojects/MockEtlFramework/ExternalModules/...` to `{ETL_ROOT}/ExternalModules/bin/Debug/net8.0/ExternalModules.dll`
- **110 DB rows** in `control.jobs` — `job_conf_path` changed from `/workspace/MockEtlFramework/...` to `{ETL_ROOT}/JobExecutor/Jobs/...`

### 2. Output directory naming decided

- Original job output: `Output/curated/`
- Reverse-engineered job output: `Output/curated_re/`
- (Replaces old POC3/4 naming of "double_secret_curated")

### 3. I/O architecture decided — no Docker mounts needed

Dan's plan: run all original jobs once, then one-time copy `Output/curated/` from the host into BD's workspace. No new Docker bind mounts. Git stays out of it (`Output/` is gitignored for good reason).

| I/O type | Host | Docker (BD) |
|---|---|---|
| Original job configs | `{ETL_ROOT}/JobExecutor/Jobs/` | `{ETL_ROOT}/JobExecutor/Jobs/` (repo clone) |
| Original job run outputs | `{ETL_ROOT}/Output/curated/` | `{ETL_ROOT}/Output/curated/` (one-time copy from host) |
| RE job confs | visible via repo sync | `{ETL_ROOT}/JobExecutor/Jobs/` (BD creates new files) |
| RE job run outputs | visible at `/media/dan/fdrive/ai-sandbox/workspace/MockEtlFramework/Output/curated_re/` | `{ETL_ROOT}/Output/curated_re/` |
| Proofmark config yamls | visible at `/media/dan/fdrive/ai-sandbox/workspace/proofmark/...` | `/workspace/proofmark/...` (BD creates) |
| Proofmark output | DB (JSON report queue) | DB (JSON report queue) |

### 4. Proofmark output goes to DB, not filesystem

Proofmark writes comparison results as JSON to the DB report queue. Both sides read via DB access. No filesystem output path to worry about. (Dan noted this was "a dumb thing to implement that way" but fine for the POC as long as no one deletes reports off the queue.)

### 5. BD can't be structurally prevented from running the FW

Dan asked about chmod tricks to give BD delete-without-write on `curated_re/`. Answer: POSIX can't separate them — both require write permission on the directory. It's a convention/trust boundary. Proofmark comparison using Hobson's `curated/` as LHS is the real enforcement.

### 6. DB role clarification

`claude` role on the `atc` database has full write access (CREATE TABLE, TRUNCATE, INSERT, UPDATE). Not SELECT-only. That restriction only applies to the `householdbudget` database (PersonalFinance project).

## Still TODO — Infrastructure Work

1. ~~Stand up MockEtlFramework as a host-side long-running service~~ Path resolution done. **Env var setup still needed.**
2. Stand up Proofmark as a host-side long-running service
3. ~~Set up host-side output directory, read-only mounted into Docker~~ **Replaced by one-time copy approach.**
4. Install Briggsy's tooling chain into BD's Docker environment
5. Build the "press go" execution plan
6. Push MockEtlFramework changes and sync BD's clone (**load-bearing — BD's next DB read will get tokenised paths**)

## First Action for Next Session

Dan wants next-Hobson to review the transcripts from this session, verify nothing was missed, and write a "state of POC5 as of 2026-03-08" file.

Transcripts are in `/home/dan/penthouse-pete/.transcripts/`. Look for files dated 2026-03-07 and 2026-03-08.

## Key File Paths

| What | Path |
|------|------|
| Dan's vision | `/media/dan/fdrive/ai-sandbox/workspace/AtcStrategy/POC5/DansNewVision.md` |
| Hobson's notes | `/media/dan/fdrive/ai-sandbox/workspace/AtcStrategy/POC5/hobson-notes/` |
| Tooling plan | `/media/dan/fdrive/ai-sandbox/workspace/AtcStrategy/POC5/hobson-notes/tooling-plan.md` |
| ETL FW code | `/media/dan/fdrive/codeprojects/MockEtlFramework/` |
| PathHelper | `/media/dan/fdrive/codeprojects/MockEtlFramework/Lib/PathHelper.cs` |
| JobExecutorService | `/media/dan/fdrive/codeprojects/MockEtlFramework/Lib/Control/JobExecutorService.cs` |
| JobRunner | `/media/dan/fdrive/codeprojects/MockEtlFramework/Lib/JobRunner.cs` |
| External module | `/media/dan/fdrive/codeprojects/MockEtlFramework/Lib/Modules/External.cs` |
| Example job conf | `/media/dan/fdrive/codeprojects/MockEtlFramework/JobExecutor/Jobs/account_balance_snapshot.json` |
| DB: atc | `control.jobs` — `job_conf_path` column now uses `{ETL_ROOT}` tokens |
| Hobson transcripts | `/home/dan/penthouse-pete/.transcripts/` |
| Session wakeups | `/media/dan/fdrive/ai-sandbox/workspace/AtcStrategy/POC5/session-wakeups/` |
