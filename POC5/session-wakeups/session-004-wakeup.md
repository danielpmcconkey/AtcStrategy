# POC5 Session 005 — Wake-Up Prompt

## Copy-paste this into Hobson when you start the next session:

```
Go read /media/dan/fdrive/ai-sandbox/workspace/AtcStrategy/POC5/session-wakeups/session-004-wakeup.md — that's your wakeup prompt. Read it, absorb it, then tell me what's next.
```

---

## Who You Are

You are Hobson. Your CLAUDE.md and MEMORY.md are already loaded — don't re-read them unless something feels off.

## What Happened Last Session

### 1. Stenographer hooks verified working

The hooks installed in session 003 weren't producing transcripts because `jq` wasn't installed. Dan installed it (`sudo apt install jq`), and transcripts now appear in `/home/dan/penthouse-pete/.transcripts/`. Also confirmed Hobson has no sudo rights — as intended.

### 2. MockEtlFramework builds clean

`dotnet build` on `/media/dan/fdrive/codeprojects/MockEtlFramework/MockEtlFramework.sln` — zero errors, 11 nullable warnings in ExternalModules (cosmetic).

### 3. Path resolution problem identified — THE OPEN QUESTION

We dug into how the ETL FW resolves paths for POC5's host-side service mode. Key findings:

- **Output paths** in job confs are **relative** (e.g., `Output/curated/account_balance_snapshot/`). `PathHelper.Resolve()` resolves them against the solution root. These are fine.
- **`assemblyPath`** in job confs is absolute (`/media/dan/fdrive/codeprojects/MockEtlFramework/ExternalModules/...`). Only matters on host. Fine for now.
- **`job_conf_path`** in `control.jobs` is the problem. Currently stores Docker paths like `/workspace/MockEtlFramework/JobExecutor/Jobs/investment_risk_profile.json`. The ETL FW uses these raw — `File.ReadAllText(path)` with no resolution, no variable substitution. These will fail on the host.

**Two options discussed:**

1. **Update the DB rows** to host paths (`/media/dan/fdrive/codeprojects/MockEtlFramework/JobExecutor/Jobs/...`)
2. **Make paths relative** (e.g., `JobExecutor/Jobs/investment_risk_profile.json`) and route them through `PathHelper.Resolve()` in `JobExecutorService.cs`

Option 2 is cleaner (DB becomes portable between host and Docker), but Dan wanted to sleep on it. **This is where to resume.**

## POC5 Infrastructure Work (From Session 002 — Still Parked)

1. Stand up MockEtlFramework as a host-side long-running service
2. Stand up Proofmark as a host-side long-running service
3. Set up host-side output directory, read-only mounted into Docker
4. Install Briggsy's tooling chain into BD's Docker environment
5. Build the "press go" execution plan

Step 1 is effectively in progress — the build works, the path question is the remaining blocker.

## Key File Paths

| What | Path |
|------|------|
| Dan's vision | `/media/dan/fdrive/ai-sandbox/workspace/AtcStrategy/POC5/DansNewVision.md` |
| Hobson's notes | `/media/dan/fdrive/ai-sandbox/workspace/AtcStrategy/POC5/hobson-notes/` |
| Tooling plan | `/media/dan/fdrive/ai-sandbox/workspace/AtcStrategy/POC5/hobson-notes/tooling-plan.md` |
| ETL FW code | `/media/dan/fdrive/codeprojects/MockEtlFramework/` |
| PathHelper | `/media/dan/fdrive/codeprojects/MockEtlFramework/Lib/PathHelper.cs` |
| JobExecutorService | `/media/dan/fdrive/codeprojects/MockEtlFramework/Lib/Control/JobExecutorService.cs` |
| ControlDb | `/media/dan/fdrive/codeprojects/MockEtlFramework/Lib/Control/ControlDb.cs` |
| Example job conf | `/media/dan/fdrive/codeprojects/MockEtlFramework/JobExecutor/Jobs/account_balance_snapshot.json` |
| DB: atc | `control.jobs` table — `job_conf_path` column has the Docker paths |
| Hobson transcripts | `/home/dan/penthouse-pete/.transcripts/` |
| Session wakeups | `/media/dan/fdrive/ai-sandbox/workspace/AtcStrategy/POC5/session-wakeups/` |
