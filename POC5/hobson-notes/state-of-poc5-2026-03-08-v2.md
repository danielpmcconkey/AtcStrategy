# State of POC5 — 2026-03-08 (v2)

Written by Hobson at end of session 006 after correcting errors in v1.
v1 is stale — ignore it.

---

## The Architecture

### What runs where

- **MockEtlFramework** runs on the **host** as a long-running service. Agents in Docker never run it directly.
- **Proofmark** runs on the **host** as a long-running service. Same principle.
- **Agents** run in **Docker** (BD's sandbox). They communicate with host services exclusively through **Postgres** (`atc` database). They enqueue work, services execute, agents read results.

### Environment variables

| Var | Host (Hobson) | Docker (BD) |
|-----|---------------|-------------|
| `ETL_ROOT` | `/media/dan/fdrive/codeprojects/MockEtlFramework` | `/workspace/MockEtlFramework` |
| `ETL_RE_OUTPUT` | `/media/dan/fdrive/ai-sandbox/workspace/MockEtlFramework/Output/curated_re` | `/workspace/MockEtlFramework/Output/curated_re` |

**Why two vars:** The ETL FW runs on the host. When it runs an RE job, the output needs to land somewhere BD can see. `ETL_ROOT` on the host points to Hobson's clone — outside Docker's mount scope. `ETL_RE_OUTPUT` points directly into BD's workspace, so the host ETL FW writes RE output where Docker can see it natively. No symlinks, no extra bind mounts.

### Output directories

- Original job output: `{ETL_ROOT}/Output/curated/`
- Reverse-engineered job output: `{ETL_RE_OUTPUT}/` (resolves into BD's workspace on the host)

### How original output gets to BD

One-time copy. Run all originals on the host, then copy `{ETL_ROOT}/Output/curated/` into BD's workspace. No git (Output/ is gitignored), no Docker mounts.

### Token expansion

`PathHelper.Resolve()` in MockEtlFramework expands `{TOKEN}` patterns via env vars. Any `{VAR_NAME}` in a path is replaced with the corresponding environment variable's value before the path is used.

Proofmark does **not** have token expansion yet. That's an open task in Phase 2.

---

## Code Changes Completed (Sessions 005–006)

All in **Hobson's clone only** (`/media/dan/fdrive/codeprojects/MockEtlFramework/`). Uncommitted, not pushed. BD's clone has none of these.

| File | Change |
|------|--------|
| `Lib/PathHelper.cs` | New. `GetSolutionRoot()` prefers `ETL_ROOT` env var, falls back to `.sln` walk. `Resolve()` expands `{TOKEN}` patterns via env vars. |
| `Lib/JobRunner.cs:14` | `jobConfPath` routed through `PathHelper.Resolve()` |
| `Lib/Control/JobExecutorService.cs:171` | Same |
| `Lib/Modules/External.cs:25-28` | `_assemblyPath` routed through `PathHelper.Resolve()` |
| 71 job conf JSONs | `assemblyPath` → `{ETL_ROOT}/ExternalModules/bin/Debug/net8.0/ExternalModules.dll` |

### DB changes completed

110 rows in `control.jobs` table (`atc` database, localhost Postgres). `job_conf_path` changed from `/workspace/MockEtlFramework/...` to `{ETL_ROOT}/JobExecutor/Jobs/...`.

**The DB is shared** — both Hobson and BD connect to the same Postgres instance. BD already sees the tokenised paths but doesn't have the PathHelper code to resolve them yet. The push in Phase 4 is load-bearing.

---

## What's Not Done

See `poc5-task-list.md` for the full phased list. High-level:

- **Phase 1:** Host ETL FW not yet running as a service. Env vars not persisted. Parallelism changes TBD. Sleep timer needs changing. Docs need review.
- **Phase 2:** Proofmark has no token expansion, no 8-hour runtime, not running as a service.
- **Phase 3:** Original jobs haven't been run. POC4 artifacts need cleanup. Job confs need dynamic output paths.
- **Phase 4:** Nothing committed or pushed. BD's clone is stale. Briggsy's tooling not installed. Execution plan not built.
- **Phase 5:** Not started.

---

## Key Decisions Log

| Decision | Rationale |
|----------|-----------|
| `ETL_ROOT` env var with `{TOKEN}` syntax | Portable paths — same DB rows and job confs work on host and in Docker |
| `ETL_RE_OUTPUT` as second env var | RE output must land in BD's workspace; symlinks don't cross Docker mount boundaries |
| `curated/` and `curated_re/` naming | Clean break from POC3/4 "double_secret_curated" naming |
| One-time copy for original output | Original output is stable. Run once, copy once. No mount needed. |
| Proofmark output to DB | JSON report queue. Both sides read via Postgres. Acknowledged as suboptimal but fine for POC. |
| No structural enforcement of BD's FW access | POSIX can't separate delete-without-write. Convention only. Proofmark LHS enforcement is the real check. |
| `claude` role on `atc` has full write access | Not SELECT-only. That restriction is `householdbudget` only. |
