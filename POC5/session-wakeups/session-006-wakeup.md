# POC5 Session 007 — Wake-Up Prompt

## Copy-paste this into Hobson when you start the next session:

```
Go read /media/dan/fdrive/ai-sandbox/workspace/AtcStrategy/POC5/session-wakeups/session-006-wakeup.md — that's your wakeup prompt. Read it, absorb it, then tell me where you think we left off.
```

---

## Who You Are

You are Hobson. Your CLAUDE.md and MEMORY.md are already loaded — don't re-read them unless something feels off.

## What Happened This Session (006)

### 1. Transcript review and state file

You reviewed session 004 and 005 transcripts, wrote a state-of-poc5 file. That first version (v1) turned out to be sloppy — it described the I/O architecture as "settled" when two real problems were hiding in it. Dan caught you being ambiguous about what code changed where. v1 is stale. Ignore it.

### 2. Problem 1 identified — RE output lands in the wrong place

The ETL FW runs on the host with Hobson's `ETL_ROOT`. When it runs an RE job, output goes to `/media/dan/fdrive/codeprojects/MockEtlFramework/Output/curated_re/` — Hobson's directory tree. BD's Docker container can't see that path. Unlike original output (one-time copy), RE output is iterative. Can't copy manually.

**Solution:** New env var `ETL_RE_OUTPUT`. On the host it points to BD's workspace (`/media/dan/fdrive/ai-sandbox/workspace/MockEtlFramework/Output/curated_re`). In Docker it points to `/workspace/MockEtlFramework/Output/curated_re`. RE job confs use `{ETL_RE_OUTPUT}` as output dir. Host ETL FW writes directly to BD's workspace. No symlinks, no mounts.

Symlinks were considered first but rejected — Docker doesn't follow symlinks whose targets are outside the bind mount scope.

### 3. Problem 2 identified — Proofmark has no token expansion

Proofmark is a separate codebase. No changes were made to it. When agents enqueue a comparison with `{ETL_ROOT}/...` paths, Proofmark won't know what to do with the tokens. This is an open Phase 2 task.

### 4. Full phased task list created

Dan laid out a 5-phase plan. It's in `poc5-task-list.md`. Phases execute in order.

## First Action for Next Session

Read these two files, then you're ready to work:

1. `/media/dan/fdrive/ai-sandbox/workspace/AtcStrategy/POC5/hobson-notes/state-of-poc5-2026-03-08-v2.md`
2. `/media/dan/fdrive/ai-sandbox/workspace/AtcStrategy/POC5/hobson-notes/poc5-task-list.md`

Dan will tell you which phase/task to start on.

## Key File Paths

| What | Path |
|------|------|
| State of POC5 (current) | `AtcStrategy/POC5/hobson-notes/state-of-poc5-2026-03-08-v2.md` |
| State of POC5 (stale, ignore) | `AtcStrategy/POC5/hobson-notes/state-of-poc5-2026-03-08.md` |
| Task list | `AtcStrategy/POC5/hobson-notes/poc5-task-list.md` |
| Dan's vision | `AtcStrategy/POC5/DansNewVision.md` |
| Tooling plan | `AtcStrategy/POC5/hobson-notes/tooling-plan.md` |
| ETL FW code (Hobson's clone) | `/media/dan/fdrive/codeprojects/MockEtlFramework/` |
| ETL FW code (BD's clone) | `/media/dan/fdrive/ai-sandbox/workspace/MockEtlFramework/` |
| PathHelper | `/media/dan/fdrive/codeprojects/MockEtlFramework/Lib/PathHelper.cs` |
| Proofmark (host) | `/media/dan/fdrive/codeprojects/proofmark/` |
| Session wakeups | `AtcStrategy/POC5/session-wakeups/` |
| Hobson transcripts | `/home/dan/penthouse-pete/.transcripts/` |

All `AtcStrategy/` paths are under `/media/dan/fdrive/ai-sandbox/workspace/AtcStrategy/`.
