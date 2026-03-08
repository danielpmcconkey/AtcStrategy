# POC5 Session 002 — Wake-Up Prompt

## Who You Are

You are Hobson. Read your CLAUDE.md. Read your MEMORY.md.

## What Happened Last Session

Dan declared POC4 a failure and kicked off POC5 planning. We:

1. **Read Dan's POC5 vision** (`POC5/DansNewVision.md`) — horizontal not vertical, network isolation, minimal human involvement, Briggsy's tooling stack, parallelism, atomic agents, minimal orchestration LLMs.

2. **Summarized Briggsy's full tool stack** — wrote `ai-dev-playbook/Tooling/BriggsyStackEval/stack-summary.md`. Six tools: GSD (orchestration), Context7 (live docs), Serena (LSP code nav), Sequential Thinking (skip — it's a counter), Compound Engineering (knowledge feedback loop), Visual Explainer (diagrams). Plus GitHub MCP (convenience).

3. **Read and summarized three key source docs:**
   - ETL FW architecture → `POC5/hobson-notes/etl-fw-summary.md`
   - Proofmark queue runner → `POC5/hobson-notes/proofmark-summary.md`
   - POC4 execution phases → `POC5/hobson-notes/poc4-execution-summary.md`

4. **Wrote a draft tooling plan** — `POC5/hobson-notes/tooling-plan.md`. Maps each tool to its POC5 role. Key insight: Postgres is the integration bus. Agents in Docker enqueue work, host-side services (ETL FW, Proofmark) execute it, agents read results.

5. **Clarified Hobson's job list:**
   - Install MockEtlFramework as a host-side long-running service
   - Install Proofmark as a host-side long-running service
   - Set up host-side output directory, read-only mounted into Docker
   - Install Briggsy's tooling chain into BD's Docker environment
   - Build the "press go" execution plan across conversations with Dan

## What to Read First

These are your notes. They're short. Read them all before doing anything:

1. `POC5/DansNewVision.md` — Dan's words, the north star
2. `POC5/hobson-notes/tooling-plan.md` — how everything fits together
3. `POC5/hobson-notes/etl-fw-summary.md` — ETL FW operational summary
4. `POC5/hobson-notes/proofmark-summary.md` — Proofmark operational summary
5. `POC5/hobson-notes/poc4-execution-summary.md` — what failed and why

Only go to the full source docs if the summaries aren't enough.

## What We're Doing Next

**Fix background agent permissions.** This session, background agents (launched via the Agent tool with `run_in_background: true`) were denied Read, Write, Bash, Grep, and Glob — every tool they needed. They burned tokens accomplishing nothing. BD doesn't have this problem in his sandbox. Dan wants this fixed before we do real work.

Investigate:
- Is this a permission mode issue? We launched with `mode: "auto"`. Maybe background agents need `mode: "bypassPermissions"` or Dan needs to adjust his Claude Code permission settings.
- Test with a simple background agent (read one file, write one file) to confirm the fix works before moving on.

After permissions are sorted, the next real work is standing up the ETL FW and Proofmark as host-side services.

## Key File Paths

| What | Path |
|------|------|
| Dan's vision | `/media/dan/fdrive/ai-sandbox/workspace/AtcStrategy/POC5/DansNewVision.md` |
| Hobson's notes | `/media/dan/fdrive/ai-sandbox/workspace/AtcStrategy/POC5/hobson-notes/` |
| Tooling plan | `/media/dan/fdrive/ai-sandbox/workspace/AtcStrategy/POC5/hobson-notes/tooling-plan.md` |
| Stack summary | `/media/dan/fdrive/ai-sandbox/workspace/ai-dev-playbook/Tooling/BriggsyStackEval/stack-summary.md` |
| ETL FW code | `/media/dan/fdrive/ai-sandbox/workspace/MockEtlFramework/` |
| Proofmark code | `/media/dan/fdrive/ai-sandbox/workspace/proofmark/` |
| Session wakeups | `/media/dan/fdrive/ai-sandbox/workspace/AtcStrategy/POC5/session-wakeups/` |
