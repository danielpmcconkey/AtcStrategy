# State of POC5 — 2026-03-08

Written by Hobson after reviewing session transcripts 004 and 005
(2026-03-07 14:45 through 2026-03-08 08:17).

---

## Sessions Covered

| Session | Date | Duration | Summary |
|---------|------|----------|---------|
| 004 | 2026-03-07 14:45 | ~10 min | Verified Stenographer hooks working (jq install). Identified `job_conf_path` resolution problem — DB stores Docker-absolute paths that fail on host. Two options surfaced: brute-force DB update vs token-based resolution. Dan chose to sleep on it. |
| 005 | 2026-03-07 15:41 – 2026-03-08 08:17 | ~2.5 hrs (split by 11-hour sleep) | Implemented `ETL_ROOT` env var and `{TOKEN}` expansion in PathHelper. Updated 71 job confs, 110 DB rows. Settled output directory naming, I/O architecture, and proofmark output strategy. |

---

## Decisions Made

### 1. Path resolution: environment variable tokens
- Introduced `ETL_ROOT` env var with `{ETL_ROOT}` token syntax in paths.
- `PathHelper.Resolve()` expands `{TOKEN}` patterns via env vars, then resolves relative paths against the solution root.
- `GetSolutionRoot()` prefers `ETL_ROOT` env var, falls back to `.sln` walk.
- Values: Hobson = `/media/dan/fdrive/codeprojects/MockEtlFramework`, BD = `/workspace/MockEtlFramework`.

### 2. Output directory naming
- Original job output: `Output/curated/`
- Reverse-engineered job output: `Output/curated_re/`
- Replaces the old "double_secret_curated" naming from POC3/4.

### 3. I/O architecture — no Docker mounts needed
- Dan's plan: run all original jobs once on the host, then one-time copy `Output/curated/` into BD's workspace.
- No new Docker bind mounts. `Output/` stays gitignored.
- Git is the distribution mechanism for job confs and code. Filesystem copy for output.

### 4. Proofmark output goes to DB
- Proofmark writes comparison results as JSON to the DB report queue.
- Both sides read via DB access. No filesystem output path needed.
- Acknowledged as "dumb" but fine for the POC as long as no one deletes reports off the queue.

### 5. No structural enforcement of BD's FW access
- POSIX can't separate delete-without-write on directories — both require the write bit.
- BD's restriction from running his own copy of the ETL FW is convention/trust, not enforcement.
- Real enforcement: Proofmark LHS always uses Hobson's `curated/` output, never BD's copy.

### 6. `claude` DB role on `atc` has full write access
- CREATE TABLE, TRUNCATE, INSERT, UPDATE, etc.
- The SELECT-only restriction applies only to the `householdbudget` database (PersonalFinance project).

---

## Code Changes Completed (Session 005)

All compile clean. Zero errors, 11 cosmetic nullable warnings.

| File | Change |
|------|--------|
| `Lib/PathHelper.cs` | New file. `GetSolutionRoot()` prefers `ETL_ROOT` env var. `Resolve()` expands `{TOKEN}` patterns. |
| `Lib/JobRunner.cs:14` | `jobConfPath` routed through `PathHelper.Resolve()` |
| `Lib/Control/JobExecutorService.cs:171` | Same — path routed through `PathHelper.Resolve()` |
| `Lib/Modules/External.cs:25-28` | `_assemblyPath` routed through `PathHelper.Resolve()` |

### Data changes completed:
- **71 job conf JSONs** — `assemblyPath` changed from hardcoded `/media/dan/fdrive/...` to `{ETL_ROOT}/ExternalModules/bin/Debug/net8.0/ExternalModules.dll`
- **110 DB rows** in `control.jobs` — `job_conf_path` changed from `/workspace/MockEtlFramework/...` to `{ETL_ROOT}/JobExecutor/Jobs/...`

### Git status:
- All changes are **uncommitted** (modified, not staged) in Hobson's clone at `/media/dan/fdrive/codeprojects/MockEtlFramework/`.
- **Push + sync to BD's clone is load-bearing** — BD's next DB read will get tokenised paths, so his code must have the PathHelper changes to resolve them.

---

## I/O Path Table (Settled)

| I/O type | Host (Hobson) | Docker (BD) |
|---|---|---|
| Original job configs | `{ETL_ROOT}/JobExecutor/Jobs/` | `{ETL_ROOT}/JobExecutor/Jobs/` (repo clone) |
| Original job run outputs | `{ETL_ROOT}/Output/curated/` | `{ETL_ROOT}/Output/curated/` (one-time copy from host) |
| RE job confs | visible via repo sync | `{ETL_ROOT}/JobExecutor/Jobs/` (BD creates new files) |
| RE job run outputs | visible at host path | `{ETL_ROOT}/Output/curated_re/` |
| Proofmark config yamls | visible at host path | `/workspace/proofmark/...` (BD creates) |
| Proofmark output | DB (JSON report queue) | DB (JSON report queue) |

---

## Infrastructure TODO (Remaining)

From the original 5-step plan, with updates:

| # | Item | Status |
|---|------|--------|
| 1 | Stand up MockEtlFramework as host-side service | Path resolution done. **`ETL_ROOT` env var not yet persisted** in shell profile or systemd. |
| 2 | Stand up Proofmark as host-side service | Not started. |
| 3 | ~~Host-side output dir, read-only mounted into Docker~~ | **Replaced** by one-time copy approach. No mount needed. |
| 4 | Install Briggsy's tooling chain into BD's Docker | Not started. |
| 5 | Build the "press go" execution plan | Not started. |
| 6 | **Push MockEtlFramework changes and sync BD's clone** | Not started. Load-bearing — must happen before BD touches DB or runs jobs. |

---

## Observations from Transcript Review

1. **Nothing missed.** The wakeup prompt from session 005 is accurate and complete. All decisions and code changes match what I see in the filesystem and DB.

2. **Minor note:** The DB contains at least one row with a bare relative path (`JobExecutor/Jobs/daily_balance_movement_v4.json` — no `{ETL_ROOT}` prefix). This is likely an RE artifact from a prior POC. `PathHelper.Resolve()` handles relative paths fine, so it's not a problem.

3. **Env var persistence is the next blocker.** The code expects `ETL_ROOT` but it's not set anywhere permanent yet. Until it's in Dan's shell profile (for manual runs) or a systemd unit (for service mode), the ETL FW will fall back to the `.sln` walk — which works on the host but won't help BD.
