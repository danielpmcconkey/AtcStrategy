# Path Architecture v2 — For BD

**Date:** 2026-03-14
**Author:** Hobson
**Status:** Dan-approved design. BD to update agent blueprints.

---

## The Problem We Solved

The RE team was using wrong paths — trying to run the ETL framework locally
inside the container (doesn't work, DB is localhost which resolves to nothing),
and referencing tokens that don't exist on the host side. We also had no way
for the host framework to load RE code (job confs and external modules)
without a rebuild.

## Design Principle

**One token: `{ETL_ROOT}`.** Everything the host framework and Proofmark need
to find must be expressible as `{ETL_ROOT}/...`. On the host, `ETL_ROOT`
resolves to `/media/dan/fdrive/codeprojects/MockEtlFrameworkPython`. In the
container, it resolves to `/workspace/MockEtlFrameworkPython`. It never changes.

---

## Host Directory Layout

```
{ETL_ROOT}/
├── JobExecutor/Jobs/              # OG job confs (existing)
├── src/etl/modules/externals/     # OG external modules (existing)
├── Output/
│   ├── curated/                   # OG output (existing)
│   └── re-curated/                # RE output (real dir, host-only writes)
├── RE/                            # gitignored
│   ├── Jobs/                      # symlink → workspace RE jobs
│   └── externals/                 # symlink → workspace RE externals
```

- `Output/` is already gitignored.
- `RE/` will be added to .gitignore.

## Symlinks (host side)

Two symlinks on the host bridge the OG repo to the workspace:

```
{ETL_ROOT}/RE/Jobs/
  → /media/dan/fdrive/ai-sandbox/workspace/MockEtlFrameworkPython/RE/Jobs/

{ETL_ROOT}/RE/externals/
  → /media/dan/fdrive/ai-sandbox/workspace/MockEtlFrameworkPython/RE/externals/
```

When the publisher writes to `/workspace/MockEtlFrameworkPython/RE/Jobs/foo/jobconf.json`
inside the container, the host framework sees it at
`{ETL_ROOT}/RE/Jobs/foo/jobconf.json` through the symlink.

This is a POC stand-in for what would be a proper CI/CD deployment pipeline
in production (Azure/Databricks). It's ugly but honest.

## Docker Mounts (3 total)

```yaml
volumes:
  - ./workspace:/workspace                                                                          # rw
  - /media/dan/fdrive/codeprojects/MockEtlFrameworkPython/Output/curated:/workspace/MockEtlFrameworkPython/Output/curated:ro
  - /media/dan/fdrive/codeprojects/MockEtlFrameworkPython/Output/re-curated:/workspace/MockEtlFrameworkPython/Output/re-curated:ro
```

| Mount | Container path | Mode | Purpose |
|-------|---------------|------|---------|
| workspace | `/workspace/` | rw | RE team writes code here |
| OG output | `{ETL_ROOT}/Output/curated/` | ro | RE team reads OG output for reference |
| RE output | `{ETL_ROOT}/Output/re-curated/` | ro | RE team reads their own validated output |

## Framework Code Change (DONE — Session 026)

`external.py` uses `_load_from_dir()` to scan both `src/etl/modules/externals/`
(OG) and `RE/externals/` (RE) at runtime via `importlib`. No hardcoded import
lists. Drop a `.py` file in either directory and the framework finds it next run.
Remove a file and nothing breaks.

## Three Task Queues

| Queue | Purpose | Who inserts | Who processes |
|-------|---------|------------|---------------|
| `control.task_queue` | ETL job execution | Basement agents | Host (`python cli.py --service`) |
| `control.proofmark_test_queue` | Output comparison | Basement agents | Host (`proofmark serve`) |
| `control.re_task_queue` | Workflow state machine | BD's orchestrator | BD's orchestrator (internal) |

The first two cross the network boundary. The third is entirely yours.

---

## The Full RE Pipeline — Step by Step

This is the exact flow for reverse-engineering a single job. Every path
is specific. Update the agent blueprints to match.

1. **Build engineering agent** writes the job conf to
   `/workspace/EtlReverseEngineering/jobs/{name of job}/jobconf.json`

2. **Build engineering agent** writes external module to
   `/workspace/EtlReverseEngineering/jobs/{name of job}/{name of module}.py`

3. **Build engineering agent** must set `outputDirectory` to `Output/re-curated`
   in the job conf (not `Output/curated`). This is the one intentional
   difference from OG — it routes RE output to the correct directory on
   the host.

4. **Publish agent** copies job conf from
   `/workspace/EtlReverseEngineering/jobs/{name of job}/jobconf.json` to
   `/workspace/MockEtlFrameworkPython/RE/Jobs/{name of job}/jobconf.json`

5. **Publish agent** copies external module from
   `/workspace/EtlReverseEngineering/jobs/{name of job}/{name of module}.py` to
   `/workspace/MockEtlFrameworkPython/RE/externals/{name of module}.py`

6. **Publish agent** adds a record to `control.jobs` with path of
   `{ETL_ROOT}/RE/Jobs/{name of job}/jobconf.json`

7. **ExecuteJobRuns agent** creates entries in `control.task_queue`.
   No paths needed — just `job_name` and `effective_date`.

8. **ExecuteJobRuns agent** monitors the `control.task_queue` table for results.
   Poll until all rows are `Succeeded` or `Failed`.

9. **ExecuteJobRuns agent** monitors `{ETL_ROOT}/Output/re-curated` for the
   RE output files.

10. **BuildProofmarkConfig agent** builds the proofmark-config.yaml in
    `/workspace/EtlReverseEngineering/jobs/{name of job}/proofmark-config.yaml`

11. **Proofmark execution agent** copies
    `/workspace/EtlReverseEngineering/jobs/{name of job}/proofmark-config.yaml` to
    `/workspace/MockEtlFrameworkPython/RE/Jobs/{name of job}/proofmark-config.yaml`

12. **Proofmark execution agent** adds records to `control.proofmark_test_queue`
    with `lhs_path` of `{ETL_ROOT}/Output/curated/{path/to/effectiveDate/output}`
    and `rhs_path` of `{ETL_ROOT}/Output/re-curated/{path/to/effectiveDate/output}`

---

## What BD Needs to Do

Update the agent blueprints to match the step-by-step flow above. Key changes:

- **builder.md**: `outputDirectory` must be `Output/re-curated`
- **publisher.md**: copy both job conf AND external module to `RE/` directories;
  register with `{ETL_ROOT}/RE/Jobs/...` path in `control.jobs`
- **job-executor.md**: INSERT into `control.task_queue`, poll for results.
  Do NOT run `python -m cli` locally.
- **proofmark-builder.md**: write config to EtlReverseEngineering jobs dir
- **proofmark-executor.md**: copy config to `RE/Jobs/`, INSERT into
  `control.proofmark_test_queue` with `{ETL_ROOT}` token paths
- **_conventions.md**: kill `{OG_CURATED}` token, document the `RE/` directory
  convention, document queue entry path rules

**Dan has cleanup to do before any of this goes live. Wait for his go.**
