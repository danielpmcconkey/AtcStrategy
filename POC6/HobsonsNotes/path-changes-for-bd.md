# Path & Blueprint Changes — For BD's Awareness

**Date:** 2026-03-14
**Author:** Hobson
**Status:** Changes made. Container rebuild required. Dan will coordinate next steps.

---

## What Changed and Why

The RE team was using wrong paths — specifically trying to run the ETL
framework locally inside the container, and referencing `{OG_CURATED}` (a
token that pointed to `/workspace/og-curated/`, which was a standalone Docker
mount outside the `{ETL_ROOT}` tree). Since `{ETL_ROOT}` is the only env var
token that the host-side services (Proofmark, ETL framework) can expand, all
resolvable paths must live under it.

Dan's directive: **everything lives under `{ETL_ROOT}`
(`/workspace/MockEtlFrameworkPython`).**

---

## Infrastructure Changes

### compose.yml

The read-only mount for OG curated output moved:

```
BEFORE: .../MockEtlFrameworkPython/Output/curated:/workspace/og-curated:ro
AFTER:  .../MockEtlFrameworkPython/Output/curated:/workspace/MockEtlFrameworkPython/Output/curated:ro
```

OG output is now at `{ETL_ROOT}/Output/curated/` inside the container.
**Container rebuild required** for this to take effect.

### Host-side symlinks

- **Removed:** `/media/dan/fdrive/ai-sandbox/workspace/og-curated` (old symlink)
- **Created:** `/media/dan/fdrive/codeprojects/MockEtlFrameworkPython/Output/re-curated`
  → workspace's `Output/curated/` (so host Proofmark can resolve RE output
  via `{ETL_ROOT}/Output/re-curated/`)

### Directories

- Created `/media/dan/fdrive/ai-sandbox/workspace/MockEtlFrameworkPython/Output/curated/`
  (where RE output will land when the host runs RE jobs)

---

## Blueprint Changes (10 files in EtlReverseEngineering)

### `_conventions.md`
- Killed `{OG_CURATED}` token entirely
- Added `{ETL_ROOT}` as first-class token in the path tokens table
- Added derived paths table (OG output, RE output, externals, job confs)
- Added section on queue entry paths — must use `{ETL_ROOT}`, not orchestrator tokens
- Added section: "you cannot run the ETL FW or Proofmark locally"
- Updated product artifact location guidance: code deploys to MockEtlFrameworkPython via publisher

### `job-executor.md` — Full rewrite
- Was: `cd /workspace/MockEtlFrameworkPython && python -m cli {date} {job_name}`
- Now: INSERT into `control.task_queue`, poll for results
- Includes DB connection details (172.18.0.1, claude role)
- Explicit constraint: "Do NOT run the ETL framework locally"

### `proofmark-executor.md` — Full rewrite
- Was: conceptually correct but referenced `{OG_CURATED}`
- Now: INSERT into `control.proofmark_test_queue` with `{ETL_ROOT}` token paths
- LHS: `{ETL_ROOT}/Output/curated/{job_name}/{date}/`
- RHS: `{ETL_ROOT}/Output/re-curated/{job_name}/{date}/`
- Explicit constraint: "Do NOT run Proofmark locally"

### `publisher.md` — Rewritten
- Was: register `{token}/EtlReverseEngineering/jobs/{job_id}/...` in control.jobs
- Now: copy job conf → `{ETL_ROOT}/JobExecutor/Jobs/{job_name}.json`,
  copy external modules → `{ETL_ROOT}/src/etl/modules/externals/`,
  register the `{ETL_ROOT}/...` path in control.jobs

### 6 other blueprints — `{OG_CURATED}` → `{ETL_ROOT}/Output/curated/`
- `evidence-auditor.md`
- `output-analyst.md`
- `og-flow-analyst.md`
- `brd-reviewer.md`
- `signoff.md`
- `data-profiler.md`

### `builder.md`
- Hardcoded `/workspace/MockEtlFrameworkPython/...` → `{ETL_ROOT}/...`

---

## Three Task Queues — For Clarity

| Queue | Purpose | Who inserts | Who processes |
|-------|---------|------------|---------------|
| `control.task_queue` | ETL job execution | Basement agents | Host (`python cli.py --service`) |
| `control.proofmark_test_queue` | Output comparison | Basement agents | Host (`proofmark serve`) |
| `control.re_task_queue` | Workflow state machine | BD's orchestrator | BD's orchestrator (internal) |

The first two cross the network boundary. The third is entirely yours.

---

## What This Means for EtlReverseEngineering

RE agents still write code in EtlReverseEngineering (`{job_dir}/artifacts/code/`).
The publisher deploys final artifacts into MockEtlFrameworkPython at the standard
framework locations. This is the "build here, deploy there" pattern.

**Dan has cleanup to do with you before any of this goes live.** These are the
changes as they stand — don't start building against them until Dan says go.
