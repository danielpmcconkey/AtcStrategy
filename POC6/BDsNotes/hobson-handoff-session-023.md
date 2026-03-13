# Hobson → BD Handoff — Session 023

**Date:** 2026-03-13

---

## What I Did

Network isolation is fully implemented. Here's what changed in your world:

### Your Workspace

- **C# `MockEtlFramework` is gone.** Deleted from `/workspace/`. You don't need it — POC6 is Python. If you need to read the C# originals, clone from GitHub.
- **`MockEtlFrameworkPython` and `proofmark`** are fresh clones from GitHub, fully up to date. Your previous local changes (trailer_match feature in Proofmark, DB host override in the C# repo) have been discarded.

### Environment Variables

- **`ETL_ROOT`** now points to `/workspace/MockEtlFrameworkPython` (was `/workspace/MockEtlFramework`)
- **`ETL_RE_OUTPUT` and `ETL_RE_ROOT` are gone.** Removed from compose.yml, from source code, from everywhere. They were POC5 artifacts. Everything uses `{ETL_ROOT}` tokens now.
- **`ETL_DB_PASSWORD`** is unchanged.

### New Mount

- **`/workspace/og-curated/`** is a read-only mount of the OG curated output (the answer key). You can read it. You cannot write to it. That's the point.

### New Directory

- **`/workspace/re-curated/`** exists and is empty. This is where the host-side ETL framework will write RE validation output.

### Database

- Host Postgres is reachable at **`172.18.0.1`** from inside the container, `claude` role, `atc` database. Confirmed working.
- The ETL framework's `DatabaseSettings.Host = localhost` is **intentional** — it means you can't run the framework against the real DB from inside the container. Don't "fix" this.

### What This Means For You

- All paths in job confs, queue entries, and Proofmark configs should use `{ETL_ROOT}/...` tokens. The host expands them.
- You write code and confs to `/workspace/MockEtlFrameworkPython/`. The host sees them via bind mount and runs them through the real framework.
- You can read OG output at `/workspace/og-curated/` for reference, but you cannot copy it or write to it.
- Your only upward channel to the host is structured data in queue tables. That's by design.

### Reference

Full details in `AtcStrategy/POC6/HobsonsNotes/state-of-poc6.md`, section 4.

— Hobson
