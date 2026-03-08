# POC5 Session 003 — Wake-Up Prompt

## Who You Are

You are Hobson. Read your CLAUDE.md. Read your MEMORY.md.

## What Happened Last Session

Dan asked us to read the session-001 wakeup. That doc said the next task was fixing background agent permissions, but Dan corrected course — the real task was fixing **Hobson's own permissions** on the host.

We:

1. **Audited all permission configs.** Read global settings (`~/.claude/settings.json`), global local (`~/.claude/settings.local.json`), and project local (`penthouse-pete/.claude/settings.local.json`). Found 80+ individual `Bash(command:*)` prefix entries that had accumulated one approval at a time.

2. **Read BD's permissions for comparison.** BD's config at `/media/dan/fdrive/ai-sandbox/workspace/.claude/settings.local.json` uses blanket `"Bash"` — no patterns, no per-command entries. BD's protection is Docker, not permissions.

3. **Discussed the tradeoffs with Dan.** Key points:
   - `Bash` without a pattern means full terminal access — no command is blocked
   - The permission syntax is prefix-matching only, no regex, no "contains", no path-scoping
   - There's no way to meaningfully say "rm is ok here but not there" — it's trivially bypassable
   - `sudo` commands will fail naturally (password prompt on stdin that we can't answer)
   - Without `sudo`, Hobson runs as `dan` — same filesystem permissions, same boundaries

4. **Wrote the new permissions.** Replaced 80+ entries in `penthouse-pete/.claude/settings.local.json` with:
   ```json
   {
     "permissions": {
       "allow": [
         "Bash", "Read", "Write", "Edit",
         "Glob", "Grep", "WebSearch", "WebFetch"
       ]
     }
   }
   ```

5. **Requires restart to take effect.** Permissions load at launch.

## What to Read First

1. `POC5/DansNewVision.md` — Dan's words, the north star
2. `POC5/hobson-notes/tooling-plan.md` — how everything fits together
3. `POC5/hobson-notes/etl-fw-summary.md` — ETL FW operational summary
4. `POC5/hobson-notes/proofmark-summary.md` — Proofmark operational summary
5. `POC5/hobson-notes/poc4-execution-summary.md` — what failed and why

Only go to the full source docs if the summaries aren't enough.

## What We're Doing Next

Permissions are sorted. The next real work from the session-001 list:

1. **Stand up MockEtlFramework as a host-side long-running service**
2. **Stand up Proofmark as a host-side long-running service**
3. **Set up host-side output directory, read-only mounted into Docker**
4. **Install Briggsy's tooling chain into BD's Docker environment**
5. **Build the "press go" execution plan across conversations with Dan**

Check with Dan on where he wants to start.

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
| Hobson permissions | `/home/dan/penthouse-pete/.claude/settings.local.json` |
| BD permissions | `/media/dan/fdrive/ai-sandbox/workspace/.claude/settings.local.json` |
