# POC5 Session 012 — Wake-Up Prompt

## Copy-paste this into Hobson when you start the next session:

```
Go read /media/dan/fdrive/ai-sandbox/workspace/AtcStrategy/POC5/session-wakeups/session-011-wakeup.md — that's your wakeup prompt. Read it, absorb it, then tell me where you think we left off.
```

---

## Who You Are

You are Hobson. Your CLAUDE.md and MEMORY.md are already loaded — don't re-read them unless something feels off.

## What Happened This Session (011)

### 1. Phase 4 — Complete

All items in Phase 4 of the task list are done. This was Hobson's final phase.

- Host code committed and pushed (MockEtlFramework `b756b29`, AtcStrategy `cd5fc30`)
- All 4 repos pulled on BD's side (MockEtlFramework, proofmark, AtcStrategy, ai-dev-playbook)
- Network boundary confirmed (session 010, carried forward)

### 2. Briggsy's Full Tooling Chain Installed

Dan's boss (Briggsy) insists his tooling stack is needed. Dan wants POC5 to test that thesis. All five tools are installed and verified working in BD's Docker container:

| Tool | Version | Type | Status |
|------|---------|------|--------|
| Serena | 0.1.4 | MCP server (Roslyn/C#) | Connected |
| Context7 | 2.1.3 | MCP server (library docs) | Connected |
| Sequential Thinking | 2025.12.18 | MCP server (structured reasoning) | Connected |
| GSD | 1.22.4 | Slash commands + hooks | Installed |
| Compound Engineering | 2.38.1 | Plugin (agents + knowledge loop) | Installed, enabled |

**Install gotchas for future reference:**
- Serena requires Python 3.11 (not 3.12). Installed via deadsnakes PPA. Venv at `/workspace/.serena-venv/`.
- MCP servers must be configured via `.mcp.json` in the project root (`/workspace/.mcp.json`), NOT in `settings.json` or `.claude.json`. Those locations are silently ignored.
- SSH known_hosts for GitHub needs to persist. Entrypoint.sh now symlinks `~/.claude/.ssh/` into `~/.ssh/` on container start.
- GSD installer modified `settings.json` with hooks (context monitor, update checker, statusline).
- CE plugin installed via `claude plugin marketplace add EveryInc/compound-engineering-plugin` then `claude plugin install compound-engineering`.
- Python 3.11 and deadsnakes PPA are NOT yet baked into the Dockerfile. The Dockerfile has the edit but the container hasn't been rebuilt with it. Current container has them installed via `apt` at runtime. Next rebuild will bake them in.

### 3. BD's Context Cleaned

- CLAUDE.md rewritten — removed REBOOT.md reference, removed POC4 boot sequence. Kept tone, environment, context engineering rules.
- Workspace MEMORY.md rewritten — removed ATC boot sequence and POC3/4 references. Kept identity, permissions, Postgres, GitHub, SSH, repos. Added toolchain section.
- Deleted 5 stale memory files (poc3-blueprint, poc3-closeout, fw-benchmarks, fw-rearchitect, fw-rearchitect-execution).
- Deleted MockEtlFramework project MEMORY.md (was all POC3 state).

**Is BD clean?** Mostly. His CLAUDE.md, MEMORY.md, and memory directory are clear of POC-specific context. However:
- The `ai-dev-playbook/REBOOT.md` still exists and references POC4 docs. BD won't be directed to read it (the CLAUDE.md reference was removed), but if he goes exploring, he'll find it.
- AtcStrategy repo contains POC1-4 directories. Dan said these aren't off-limits, just shouldn't be BD's starting point.
- BD's `.claude/history.jsonl` (608KB) contains prior session transcripts. Claude Code doesn't auto-load these, but BD could search them.
- There's a stashed set of BD's local changes in ai-dev-playbook (`git stash`). Harmless but worth knowing.

Net assessment: BD is clean enough for a fresh start. His auto-loaded context (CLAUDE.md + MEMORY.md) contains zero POC history. He'd have to go looking to find the old stuff.

### 4. BD Wake-Up Prompt — DRAFT ONLY, NOT YET REVIEWED

A draft wake-up prompt was written at `AtcStrategy/POC5/session-wakeups/bd-wakeup.md`. **Dan has NOT reviewed it yet.** This is the next task. Dan wants to play a very active role in crafting what BD sees when he wakes up — this is not a "Hobson writes it and Dan approves it" situation. It's collaborative.

Read the draft, understand what it says, but be prepared for Dan to reshape it significantly. The key framing decisions Dan has made:
- BD should understand his toolchain first (that's his starting point)
- ETL FW and Proofmark are "COTS products in the cloud" — BD can study the reference code but can't touch the running versions
- Job confs and OG output in BD's workspace are reference copies, not the real ones
- BD builds the RE execution plan WITH Dan, not solo
- Key principles: horizontal (one job at a time), agent atomicity, task-queue driven, minimal orchestration LLMs, parallelism with fungible workers

### 5. Task List Updated

Phase 4 all checked off. Phase 5 starts with BD building the RE plan with Dan. See the task list for current state.

## What's Next

1. **Review and finalize BD's wake-up prompt with Dan** — collaborative, not delegated
2. **Give BD the wake-up prompt and start Phase 5**

## Key File Paths

| What | Path |
|------|------|
| Task list | `AtcStrategy/POC5/hobson-notes/poc5-task-list.md` |
| BD wake-up draft | `AtcStrategy/POC5/session-wakeups/bd-wakeup.md` |
| OG output isolation doc | `AtcStrategy/POC5/hobson-notes/og-output-isolation.md` |
| Dan's POC5 vision | `AtcStrategy/POC5/DansNewVision.md` |
| Briggsy tooling eval | `ai-dev-playbook/Tooling/BriggsyStackEval/` |
| BD's CLAUDE.md | `/media/dan/fdrive/ai-sandbox/workspace/CLAUDE.md` |
| BD's MEMORY.md | `/media/dan/fdrive/ai-sandbox/claude-home/projects/-workspace/memory/MEMORY.md` |
| BD's MCP config | `/media/dan/fdrive/ai-sandbox/workspace/.mcp.json` |
| Dockerfile | `/media/dan/fdrive/ai-sandbox/Dockerfile` |
| Docker entrypoint | `/media/dan/fdrive/ai-sandbox/entrypoint.sh` |
| Session wakeups | `AtcStrategy/POC5/session-wakeups/` |

All `AtcStrategy/` paths are under `/media/dan/fdrive/ai-sandbox/workspace/AtcStrategy/`.

## Standing Rules

- Only Hobson makes code changes to MockEtlFramework. BD's clone is reference only (except BD can add his own RE jobs).
- When Dan asks you to write a query, write the query. Don't run it and hand back a verdict unless asked.
