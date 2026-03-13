# POC6 Environment Variable Mapping — Host vs Basement

**Date:** 2026-03-13
**Author:** Hobson
**Status:** Implemented and verified (session 023).

---

## Path Variables

| Env Var | Host Value | Basement Value | Purpose |
|---------|-----------|---------------|---------|
| `ETL_ROOT` | `/media/dan/fdrive/codeprojects/MockEtlFrameworkPython` | `/workspace/MockEtlFrameworkPython` | Framework root. Set in `.bashrc` (host) and `compose.yml` (basement). |

`ETL_RE_OUTPUT` and `ETL_RE_ROOT` were POC5 artifacts. Removed from `.bashrc`, `compose.yml`, Proofmark source, and ETL FW source in session 023.

## Database

| Env Var | Host Value | Basement Value | Purpose |
|---------|-----------|---------------|---------|
| `ETL_DB_PASSWORD` | *(set, not echoed)* | *(same value)* | Password for the `claude` Postgres role. |

## Implicit Config (not env vars)

| Setting | Host Value | Basement Value | Effect |
|---------|-----------|---------------|--------|
| `DatabaseSettings.Host` | `localhost` (default in AppConfig) | `localhost` (same default) | **Deliberately left as localhost.** Postgres runs on the host, not in the container. This means the basement cannot run the ETL framework or Proofmark against the real DB — `localhost` inside the container resolves to nothing. |

## Basement DB Access (separate from ETL framework)

The RE agents access Postgres through a **different connection** (not the framework's AppConfig):
- Host: Docker bridge gateway `172.18.0.1` (confirmed session 023)
- Role: `claude`
- Permissions: READ on `control.*`, WRITE on queue tables only

This connection is used by the agents' own scripts, not by the framework. The framework's DB config intentionally doesn't work in the container.

---

## Docker Mounts

| Host path | Container path | Mode |
|-----------|---------------|------|
| `/media/dan/fdrive/ai-sandbox/workspace/` | `/workspace/` | rw |
| `/media/dan/fdrive/codeprojects/MockEtlFrameworkPython/Output/curated/` | `/workspace/og-curated/` | ro |

## Host-Side Symlinks and Directories

| Path | Type | Points to |
|------|------|-----------|
| `/media/dan/fdrive/ai-sandbox/workspace/og-curated` | symlink | `/media/dan/fdrive/codeprojects/MockEtlFrameworkPython/Output/curated` |
| `/media/dan/fdrive/ai-sandbox/workspace/re-curated/` | directory | *(RE output lands here)* |
