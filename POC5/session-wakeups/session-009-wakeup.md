# POC5 Session 010 — Wake-Up Prompt

## Copy-paste this into Hobson when you start the next session:

```
Go read /media/dan/fdrive/ai-sandbox/workspace/AtcStrategy/POC5/session-wakeups/session-009-wakeup.md — that's your wakeup prompt. Read it, absorb it, then tell me where you think we left off.
```

---

## Who You Are

You are Hobson. Your CLAUDE.md and MEMORY.md are already loaded — don't re-read them unless something feels off. Your memory file `atc-poc5.md` now exists and has the full POC5 picture.

## What Happened This Session (009)

This was a strategy/planning session. No code was written to MockEtlFramework or Proofmark. Two planning documents and one operational script were created.

### 1. Memory catch-up

Previous Hobson sessions had not written POC5 status to memory. Created `/home/dan/.claude/projects/-home-dan-penthouse-pete/memory/atc-poc5.md` with the full architecture, phase status, design principles, and key file paths. MEMORY.md updated to reference it.

### 2. External module rebuild problem — identified and solved (for POC5)

BD's RE agents will eventually need to create External module `.cs` files. These compile into `ExternalModules.dll`, which the ETL FW loads at runtime via `Assembly.LoadFrom()`. Three friction points:

1. **Build required.** A `.cs` file does nothing until `dotnet build` runs.
2. **BD can't build.** The ETL FW lives on the host. BD has a read-only copy.
3. **Assembly caching.** `Assembly.LoadFrom()` (in `Lib/Modules/External.cs:30`) caches by path. Once the DLL is loaded into the running process, a rebuilt DLL on disk is invisible until the process restarts.

**POC5 solution (KISS):** BD's agents stop and tell Dan to rebuild. Dan ctrl+C's the running service, hits up-arrow to re-run the script.

### 3. Rebuild-and-run script

Created `/home/dan/penthouse-pete/run-etl-service.sh`:

```bash
#!/bin/bash
cd /media/dan/fdrive/codeprojects/MockEtlFramework
git pull
dotnet build -c Release -v quiet
JobExecutor/bin/Release/net8.0/JobExecutor --service
```

### 4. Status line configured

Set up a context window status bar for Hobson's Claude Code instance. Script at `/home/dan/penthouse-pete/hobson-statusline.js`. Shows model, working directory, and a colour-coded context usage bar (green < 50%, yellow 50-65%, orange 65-80%, blinking skull 80%+). Adapted from BD's GSD statusline with GSD-specific features stripped out. Wired into `~/.claude/settings.json`.

### 5. Future planning: External module loading beyond POC5

Researched and documented two options for eliminating the build/restart friction:

**Option A — AssemblyLoadContext (C#):** ~20 lines in `External.cs`. Loads DLL into an isolated, collectible context that can be unloaded. Eliminates the restart problem but NOT the build problem. BD still can't run `dotnet build`. Microsoft-sanctioned API, strong typing preserved.

**Option B — Python rewrite:** Full framework rewrite. `importlib` hot-loads `.py` files from disk on every invocation. No build step, no restart, no compile toolchain. BD writes a file, framework picks it up next run.

Feasibility research confirmed Python rewrite is ~1 week of Claude sessions (framework 2-3 sessions, 73 external modules 2-3 sessions, validation 2-3 sessions). Everything maps cleanly: pandas for DataFrames, psycopg3 for Postgres, pyarrow for Parquet, threading for parallelism (GIL is irrelevant — workload is I/O-bound).

Key insight from the discussion: ALC removes 1 of 3 friction points (restart). Python removes all 3 (compile, sync, restart). For POC5 the manual script is fine. For POC6 where agents need to iterate autonomously overnight, Python is the cleaner path.

**Write-up:** `AtcStrategy/POC5/hobson-notes/external-module-loading-future.md`

### 6. POC6 two-model architecture

Dan laid out the production constraint: his company will not allow PCI/PII data through Anthropic APIs. Claude does the code-only RE work. A company-trusted model (Copilot/Azure OpenAI, simulated by Haiku 4.5 in the POC) handles data profiling on the host side.

Architecture:
- **RE agents** (Claude Sonnet/Opus) in the basement — read V1 code, infer requirements, write specs, build modules. No customer data access.
- **Data profiler** (Haiku 4.5, simulating Copilot) on the host — queries prod data, returns statistical summaries, distributions, schema descriptions. No raw records cross the boundary.
- Communication via Postgres queue. RE agents post questions, profiler posts answers.

This is the "interactivity between basement and host" that makes the Python rewrite more compelling — the RE agents are in a tight loop (write module → run → check Proofmark → ask profiler → adjust → repeat) and every compile/sync/restart cycle breaks overnight autonomy.

**Added to:** `AtcStrategy/POC5/hobson-notes/external-module-loading-future.md` (POC6 section)

### 7. Cloud deployment compliance research

Researched whether Claude can be deployed with equivalent data isolation to Copilot/Azure OpenAI:

| Platform | Data stays in-tenancy? | Processor |
|----------|----------------------|-----------|
| Azure Foundry | **No** — Anthropic is the processor, data may leave Azure | Anthropic |
| AWS Bedrock | **Yes** — runs on AWS infrastructure, Anthropic has no access | AWS |
| GCP Vertex AI | **Yes** — regional endpoints enforce residency, FedRAMP High | Google |

If Dan's company is Azure-only, the two-model architecture is necessary. If they're in AWS or GCP, Claude via Bedrock/Vertex could potentially get the same compliance approval, which would eliminate the need for a separate profiler model entirely.

**Write-up:** `AtcStrategy/POC5/hobson-notes/cloud-deployment-compliance.md`

### 8. BD is running RE operations

BD is downstairs using GSD, working through the RE process. He clears context between GSD phases. This is the first time the full POC5 pipeline is being exercised end-to-end.

## Phase Status (unchanged from session 008)

- **Phase 1:** DONE
- **Phase 2:** Not started (Proofmark needs token expansion, 8-hour runtime, service mode; `control.comparison_queue` was dropped and needs recreating)
- **Phase 3:** Not started
- **Phase 4:** Not started
- **Phase 5:** In progress — BD is actively running RE operations

## First Action for Next Session

Check in with Dan. Ask how BD's RE run is going, whether he's hit the External module rebuild wall, and whether the restart script is working. Then check the task list for what's next.

## Key File Paths

| What | Path |
|------|------|
| Rebuild script | `/home/dan/penthouse-pete/run-etl-service.sh` |
| Statusline script | `/home/dan/penthouse-pete/hobson-statusline.js` |
| External module loading write-up | `AtcStrategy/POC5/hobson-notes/external-module-loading-future.md` |
| Cloud compliance write-up | `AtcStrategy/POC5/hobson-notes/cloud-deployment-compliance.md` |
| Task list | `AtcStrategy/POC5/hobson-notes/poc5-task-list.md` |
| Job scope manifest | `AtcStrategy/POC5/hobson-notes/job-scope-manifest.json` |
| External.cs (assembly loading) | `/media/dan/fdrive/codeprojects/MockEtlFramework/Lib/Modules/External.cs` |
| AppConfig | `/media/dan/fdrive/codeprojects/MockEtlFramework/Lib/AppConfig.cs` |
| TaskQueueService | `/media/dan/fdrive/codeprojects/MockEtlFramework/Lib/Control/TaskQueueService.cs` |
| Documentation index | `MockEtlFramework/Documentation/README.md` |
| ETL FW code (Hobson's clone) | `/media/dan/fdrive/codeprojects/MockEtlFramework/` |
| ETL FW code (BD's clone) | `/media/dan/fdrive/ai-sandbox/workspace/MockEtlFramework/` |
| Proofmark (host) | `/media/dan/fdrive/codeprojects/proofmark/` |
| Session wakeups | `AtcStrategy/POC5/session-wakeups/` |
| Hobson's POC5 memory | `/home/dan/.claude/projects/-home-dan-penthouse-pete/memory/atc-poc5.md` |

All `AtcStrategy/` paths are under `/media/dan/fdrive/ai-sandbox/workspace/AtcStrategy/`.

## Standing Rule

Only Hobson makes code changes to MockEtlFramework. BD's clone is reference only (except BD can add his own RE jobs and External module `.cs` files).
