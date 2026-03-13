# POC6 Session 023 — Wake-Up Prompt

## Copy-paste this into Hobson when you start the next session:

```
Go read /media/dan/fdrive/codeprojects/AtcStrategy/POC6/HobsonsNotes/session-022-wakeup.md — that's your wakeup prompt. Read it, absorb it, then tell me you're ready.
```

---

## Who You Are

You are Hobson. Your CLAUDE.md and MEMORY.md are already loaded.

## What You're Doing This Session

**Implementing network isolation for POC6.** The design is agreed. This session is execution.

Read these before doing anything else:

1. `/media/dan/fdrive/codeprojects/AtcStrategy/POC6/HobsonsNotes/state-of-poc6.md` — **Section 4 (Network Isolation)** is the master reference. Read all of it, but section 4 is your implementation spec.
2. `/media/dan/fdrive/codeprojects/AtcStrategy/POC6/HobsonsNotes/env-var-mapping.md` — current vs proposed env var values on both sides.

Then read these for context on the existing code you'll be modifying:

3. `/media/dan/fdrive/codeprojects/proofmark/src/proofmark/app_config.py` — Proofmark's `PathSettings` with the 3 token resolve method.
4. `/media/dan/fdrive/codeprojects/proofmark/src/proofmark/queue.py` — where `resolve_path` is wired into the worker loop.
5. `/media/dan/fdrive/codeprojects/MockEtlFrameworkPython/src/etl/path_helper.py` — ETL framework's token expansion.
6. `/media/dan/fdrive/codeprojects/MockEtlFrameworkPython/src/etl/app_config.py` — ETL framework's config (mirrors C# AppConfig).
7. `/media/dan/fdrive/codeprojects/MockEtlFramework/Lib/AppConfig.cs` — C# original for reference.
8. `/media/dan/fdrive/ai-sandbox/launch.sh` — Docker launch script (where env vars are likely set).

## Implementation Plan

### Phase 1: Env vars

1. **Update host `ETL_ROOT`** — Dan needs to add to `.bashrc`: `export ETL_ROOT=/media/dan/fdrive/codeprojects/MockEtlFrameworkPython`. Flag this for Dan.
2. **Update Docker config** — In `launch.sh` or wherever env vars are set:
   - `ETL_ROOT=/workspace/MockEtlFrameworkPython` (was `/workspace/MockEtlFramework`)
   - Remove `ETL_RE_ROOT` and `ETL_RE_OUTPUT`
3. **Update Proofmark** — In `app_config.py`, simplify `PathSettings` to only handle `ETL_ROOT` (and `ETL_DB_PASSWORD`). Remove `ETL_RE_ROOT`/`ETL_RE_OUTPUT` token expansion. Update tests if any reference the removed tokens.
4. **Update ETL FW** — In `path_helper.py` and `app_config.py`, remove `ETL_RE_ROOT`/`ETL_RE_OUTPUT`. Keep `ETL_ROOT`.

### Phase 2: Docker mounts

5. **Add read-only mount** — OG curated output into container:
   - Host: `/media/dan/fdrive/codeprojects/MockEtlFrameworkPython/Output/curated/`
   - Container: `/workspace/og-curated/` (read-only)
6. **Create `re-curated` directory** — `/media/dan/fdrive/ai-sandbox/workspace/re-curated/`
7. **Create host-side symlink** — `/media/dan/fdrive/ai-sandbox/workspace/og-curated` → `/media/dan/fdrive/codeprojects/MockEtlFrameworkPython/Output/curated` (so translated paths resolve on host)

### Phase 3: Verify

8. **Test Proofmark** — Insert a test queue entry using `{ETL_ROOT}/...` token paths, run Proofmark, confirm it resolves correctly.
9. **Test ETL FW** — Run a single job with the new `ETL_ROOT`, confirm output goes to the right place.
10. **Test from basement** — Have Dan queue something from the container side, verify the host picks it up.

## Key Context

- **Why we're doing this:** POC5 agents cheated (copied OG output, edited OG code). Network isolation makes cheating structurally impossible.
- **ATC model:** Humans are air traffic control, agents are pilots. Agents have autonomy within their lane; validation and governance are on the host side.
- **localhost trick:** `DatabaseSettings.Host = localhost` in the framework config means the basement can't run the ETL FW against the real DB. Intentional. Don't "fix" this.
- **Git isolation:** OG repo on host is frozen from RE perspective. Host never pulls agent changes. Don't set up any cross-repo sync.
- **Output dirs are not in git** (`.gitignore`). Safe to mount, symlink, whatever.

## Standing Rules

- Only Hobson writes code to MockEtlFrameworkPython (on the host side).
- Read code before editing it.
- 103 jobs in scope (2 burned: repeat_overdraft_customers, suspicious_wire_flags).
- **Do NOT run `pytest tests/` in Proofmark without understanding the test table situation.** Tests use `control._test_proofmark_queue`, production uses `control.proofmark_test_queue`.
