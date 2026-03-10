# POC5 Session 010 — Wake-Up Prompt

## Copy-paste this into Hobson when you start the next session:

```
Go read /media/dan/fdrive/codeprojects/AtcStrategy/POC5/session-wakeups/session-009-wakeup.md — that's your wakeup prompt. Read it, absorb it, then tell me where you think we left off.
```

---

## Who You Are

You are Hobson. Your CLAUDE.md and MEMORY.md are already loaded — don't re-read them unless something feels off. Your memory file `atc-poc5.md` has the full POC5 picture.

## What Happened This Session (009)

Two parallel workstreams — Hobson on the host, BD in the basement.

### Hobson's Work

#### 1. Memory catch-up

Previous Hobson sessions had not written POC5 status to memory. Created `/home/dan/.claude/projects/-home-dan-penthouse-pete/memory/atc-poc5.md` with the full architecture, phase status, design principles, and key file paths. MEMORY.md updated to reference it.

#### 2. External module rebuild problem — identified and solved (for POC5)

BD's RE agents will eventually need to create External module `.cs` files. These compile into `ExternalModules.dll`, which the ETL FW loads at runtime via `Assembly.LoadFrom()`. Three friction points:

1. **Build required.** A `.cs` file does nothing until `dotnet build` runs.
2. **BD can't build.** The ETL FW lives on the host. BD has a read-only copy.
3. **Assembly caching.** `Assembly.LoadFrom()` (in `Lib/Modules/External.cs:30`) caches by path. Once the DLL is loaded into the running process, a rebuilt DLL on disk is invisible until the process restarts.

**POC5 solution (KISS):** BD's agents stop and tell Dan to rebuild. Dan ctrl+C's the running service, hits up-arrow to re-run the script.

#### 3. Rebuild-and-run script

Created `/home/dan/penthouse-pete/run-etl-service.sh`:

```bash
#!/bin/bash
cd /media/dan/fdrive/codeprojects/MockEtlFramework
git pull
dotnet build -c Release -v quiet
JobExecutor/bin/Release/net8.0/JobExecutor --service
```

#### 4. Status line configured

Set up a context window status bar for Hobson's Claude Code instance. Script at `/home/dan/penthouse-pete/hobson-statusline.js`. Shows model, working directory, and a colour-coded context usage bar (green < 50%, yellow 50-65%, orange 65-80%, blinking skull 80%+).

#### 5. Future planning: External module loading beyond POC5

Researched and documented two options for eliminating the build/restart friction:

**Option A — AssemblyLoadContext (C#):** ~20 lines in `External.cs`. Loads DLL into an isolated, collectible context. Eliminates restart problem but NOT the build problem.

**Option B — Python rewrite:** Full framework rewrite. `importlib` hot-loads `.py` files from disk on every invocation. No build step, no restart, no compile toolchain.

Key insight: ALC removes 1 of 3 friction points (restart). Python removes all 3 (compile, sync, restart). For POC5 the manual script is fine.

**Write-up:** `AtcStrategy/POC5/hobson-notes/external-module-loading-future.md`

#### 6. POC6 two-model architecture

Dan laid out the production constraint: his company will not allow PCI/PII data through Anthropic APIs. Architecture: RE agents (Claude) in the basement handle code-only work; a company-trusted model (Copilot/Azure OpenAI, simulated by Haiku 4.5 in POC) handles data profiling on the host side. Communication via Postgres queue.

**Added to:** `AtcStrategy/POC5/hobson-notes/external-module-loading-future.md` (POC6 section)

#### 7. Cloud deployment compliance research

Researched whether Claude can be deployed with equivalent data isolation to Copilot/Azure OpenAI. AWS Bedrock and GCP Vertex AI keep data in-tenancy; Azure Foundry does not (Anthropic is the processor).

**Write-up:** `AtcStrategy/POC5/hobson-notes/cloud-deployment-compliance.md`

### BD's Work (Phase 2 — Proofmark)

#### 1. Proofmark AppConfig — centralised configuration

Created `src/proofmark/app_config.py` following the same pattern as MockEtlFramework's `AppConfig.cs`. Three frozen dataclasses (PathSettings, DatabaseSettings, QueueSettings) plus top-level AppConfig container. `load_app_config(settings_path)` builds from defaults + env vars, overlaid with optional YAML.

#### 2. Idle shutdown timer

Proofmark's `serve()` now shuts down after 8 hours of inactivity (configurable). Uses `_ActivityTracker` — thread-safe class with lock-protected timestamp.

#### 3. Token expansion in worker_loop

All three paths from the queue (config_path, lhs_path, rhs_path) are resolved via `config.paths.resolve` before use. Tests unaffected — `resolve_path` defaults to identity.

#### 4. CLI simplified

Replaced `--db`, `--table`, `--workers`, `--poll-interval` with single `--settings` (optional YAML file path). `--init-db` kept.

#### 5. Password scrubbed from repo

Removed hardcoded `password=claude` from `test_queue.py` and `test-architecture.md`. Test fallback DSN now reads from `ETL_DB_PASSWORD` env var.

#### 6. Default table changed

Changed from `comparison_queue` (which Dan dropped) to `control.proofmark_test_queue` everywhere.

#### 7. Test DSN host changed

Changed test fallback from `172.18.0.1` (Docker bridge) to `localhost`. Proofmark only runs on the host now.

#### 8. Documentation restructured

Moved original BRD/FSD/test-architecture docs to `Documentation/OriginalBuildDocs/` with deprecation notes. Background agent built a full new doc tree: 17 files.

#### 9. Venv created on Hobson's clone

`/media/dan/fdrive/codeprojects/proofmark/.venv/` — Python 3.12, proofmark installed editable with queue + dev extras.

#### 10. Smoke test — 23 manual test cases

All processed successfully. 22/23 matched expected pass/fail. One known limitation: `005_should_fail_sneaky_line_break` returns PASS (not worth chasing).

## Phase Status

- **Phase 1:** DONE
- **Phase 2:** DONE (completed by BD this session)
- **Phase 3:** Not started
- **Phase 4:** Not started
- **Phase 5:** BD actively running RE operations

## First Action for Next Session

Check in with Dan. Ask how BD's RE run is going. Then check the task list for what's next.

## Key File Paths

| What | Path |
|------|------|
| Rebuild script | `/home/dan/penthouse-pete/run-etl-service.sh` |
| Statusline script | `/home/dan/penthouse-pete/hobson-statusline.js` |
| External module loading write-up | `AtcStrategy/POC5/hobson-notes/external-module-loading-future.md` |
| Cloud compliance write-up | `AtcStrategy/POC5/hobson-notes/cloud-deployment-compliance.md` |
| Task list | `AtcStrategy/POC5/hobson-notes/poc5-task-list.md` |
| Job scope manifest | `AtcStrategy/POC5/hobson-notes/job-scope-manifest.json` |
| Proofmark AppConfig | `/media/dan/fdrive/codeprojects/proofmark/src/proofmark/app_config.py` |
| Proofmark queue runner | `/media/dan/fdrive/codeprojects/proofmark/src/proofmark/queue.py` |
| Proofmark CLI | `/media/dan/fdrive/codeprojects/proofmark/src/proofmark/cli.py` |
| Proofmark venv | `/media/dan/fdrive/codeprojects/proofmark/.venv/` |
| Proofmark docs | `/media/dan/fdrive/codeprojects/proofmark/Documentation/` |
| External.cs (assembly loading) | `/media/dan/fdrive/codeprojects/MockEtlFramework/Lib/Modules/External.cs` |
| AppConfig | `/media/dan/fdrive/codeprojects/MockEtlFramework/Lib/AppConfig.cs` |
| TaskQueueService | `/media/dan/fdrive/codeprojects/MockEtlFramework/Lib/Control/TaskQueueService.cs` |
| Documentation index | `MockEtlFramework/Documentation/README.md` |
| ETL FW code (Hobson's clone) | `/media/dan/fdrive/codeprojects/MockEtlFramework/` |
| ETL FW code (BD's clone) | `/media/dan/fdrive/ai-sandbox/workspace/MockEtlFramework/` |
| Session wakeups | `AtcStrategy/POC5/session-wakeups/` |

All `AtcStrategy/` paths are under `/media/dan/fdrive/codeprojects/AtcStrategy/`.

## Standing Rule

Only Hobson makes code changes to MockEtlFramework. BD's clone is reference only (except BD can add his own RE jobs and External module `.cs` files).
