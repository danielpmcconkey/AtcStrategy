# POC5 Session 004 — Wake-Up Prompt

## Copy-paste this into Hobson when you start the next session:

```
Go read /media/dan/fdrive/ai-sandbox/workspace/AtcStrategy/POC5/session-wakeups/session-003-wakeup.md — that's your wakeup prompt. Read it, absorb it, then tell me what's next.
```

---

## Who You Are

You are Hobson. Your CLAUDE.md and MEMORY.md are already loaded — don't re-read them unless something feels off.

## What Happened Last Session

Two things:

### 1. Read the session-002 wakeup (but didn't act on it)

Dan told us to hold the POC5 infrastructure work for later. The next steps from that doc (standing up MockEtlFramework/Proofmark as services, Docker tooling, etc.) are still pending. Don't start them without Dan's say-so.

### 2. Installed the Stenographer hooks on Hobson

BD already had conversation transcript hooks writing to `/media/dan/fdrive/ai-sandbox/workspace/.transcripts`. We ported them to Hobson:

- **Input hook:** `/home/dan/penthouse-pete/.claude/hooks/stenographer-input.sh` — fires on `UserPromptSubmit`, writes Dan's messages to a session markdown file.
- **Output hook:** `/home/dan/penthouse-pete/.claude/hooks/stenographer-output.sh` — fires on `Stop`, extracts assistant text from the native JSONL transcript and appends it.
- **Transcripts land in:** `/home/dan/penthouse-pete/.transcripts/`
- **Feature flag:** `~/.claude/stenographer-on` (touch file — delete to disable)
- **Hooks registered in:** `/home/dan/penthouse-pete/.claude/settings.local.json`
- Labels say "Hobson" instead of "Claude" because we have standards.
- Dropped BD's debug JSONL dumping — it was scaffolding.

**This was the first session with these hooks.** If transcripts aren't appearing in `/home/dan/penthouse-pete/.transcripts/`, troubleshoot that first — check the flag file exists, scripts are executable, `jq` is installed, and the JSONL fallback path is correct (`$HOME/.claude/projects/-home-dan-penthouse-pete/${SESSION_ID}.jsonl`).

## POC5 Infrastructure Work (Parked)

From session-002 wakeup — still to do when Dan's ready:

1. Stand up MockEtlFramework as a host-side long-running service
2. Stand up Proofmark as a host-side long-running service
3. Set up host-side output directory, read-only mounted into Docker
4. Install Briggsy's tooling chain into BD's Docker environment
5. Build the "press go" execution plan

## Key File Paths

| What | Path |
|------|------|
| Dan's vision | `/media/dan/fdrive/ai-sandbox/workspace/AtcStrategy/POC5/DansNewVision.md` |
| Hobson's notes | `/media/dan/fdrive/ai-sandbox/workspace/AtcStrategy/POC5/hobson-notes/` |
| Tooling plan | `/media/dan/fdrive/ai-sandbox/workspace/AtcStrategy/POC5/hobson-notes/tooling-plan.md` |
| Hobson hooks | `/home/dan/penthouse-pete/.claude/hooks/` |
| Hobson transcripts | `/home/dan/penthouse-pete/.transcripts/` |
| Hobson permissions | `/home/dan/penthouse-pete/.claude/settings.local.json` |
| BD transcripts | `/media/dan/fdrive/ai-sandbox/workspace/.transcripts/` |
| Session wakeups | `/media/dan/fdrive/ai-sandbox/workspace/AtcStrategy/POC5/session-wakeups/` |
