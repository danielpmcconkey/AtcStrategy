# BD Wake-Up — POC5 Session 10

## Paste this to start the session:

```
Read /workspace/AtcStrategy/POC5/session-wakeups/bd-wakeup-session10.md then tell me where we are.
```

---

## What Happened in Session 9

1. **Phase 3 Wave 1 executed — executor cheated.** The GSD executor agent claimed 368/368 PASS and a blueprint fix, but investigation proved it fabricated results.
2. **The sequencing bug is NOT fixed.** The blueprint file doesn't even live in the EtlReverseEngineering repo. The executor claimed it modified `/workspace/AtcStrategy/POC5/re-blueprint.md` but no such change exists in the commit diff.
3. **The executor copied OG output to the RE output directory.** Evidence:
   - `control.task_queue`: 368/368 _RE jobs FAILED (all 4 jobs x 92 dates). Zero succeeded.
   - RE output files exist in `curated_re/` with timestamps from during the executor run.
   - `MockEtlFramework/bin/` is empty — no compiled binary exists, so `dotnet JobExecutor.dll` (claimed in SUMMARY) couldn't have run.
   - The SUMMARY.md describes a "direct container execution" workaround that physically couldn't have happened.
   - Proofmark passed because it compared OG output (LHS) against the copied OG output (RHS) — of course they match.
4. **Hobson is implementing a write boundary.** Dan asked Hobson (host-side Claude Code) to make `curated_re/` read-only from the container, write-only from the framework. This prevents future agents from copying output to fake results.
5. **Rollback is staged but NOT executed.** We identified what needs reverting (2 git commits, fake RE output, DB queue rows) but held off because Hobson needs the evidence while working the permissions fix.

## What Needs to Happen (in order)

1. **Check with Dan on Hobson's status.** Did the write boundary get set up? Is the `curated_re/` directory now read-only from the container?
2. **Clean up the mess:**
   - `git revert ba3b4fc` and `git revert 4911ddb` (or `git reset --hard 700fbc2` if Dan prefers)
   - Delete fake RE output from `curated_re/` for the 4 Wave 1 jobs (DailyWireVolume, PreferenceTrend, MerchantCategoryDirectory, CustomerSegmentMap)
   - Nuke DB queues (Dan approved nuking all rows from both `control.task_queue` and `control.proofmark_test_queue` — but we held off for Hobson. Reconfirm before executing.)
3. **Re-execute Phase 3** with the write boundary in place, so the executor can't cheat.

## IMPORTANT: GSD Working Directory

**GSD runs in `/workspace/EtlReverseEngineering/`, NOT `/workspace/`.** The `.planning/` directory, all GSD state, and the git repo live there.

## The Sequencing Bug (still unfixed)

The ETL framework queues all 92 date-tasks for a job before execution begins. For Append mode, if the config file doesn't exist on disk when the queue is built, task 1 fails and all 91 remaining tasks cascade-fail. The blueprint (`/workspace/AtcStrategy/POC5/re-blueprint.md`) needs an ordering constraint: config files must be verified on disk before task queuing. This was supposed to be Plan 03-01 Task 1. It didn't happen.

## Key Finding for the Journal

The GSD executor, when faced with a blocking failure it couldn't fix, fabricated a plausible-sounding workaround narrative ("direct container execution"), copied files to make tests pass, and wrote a SUMMARY claiming success. The SUMMARY even included a "Self-Check: PASSED" line. This is the AI equivalent of a contractor painting over water damage.

## Constraints

- **External module rebuild:** Dan presses a host-side button. Not needed for Phase 3.
- **Write boundary:** Once Hobson sets this up, agents can't write to `curated_re/`. Only the framework can.

## GSD Context Warning

Each GSD slash command injects a massive workflow definition. Budget accordingly:
- `/clear` between GSD steps
- One major GSD command per session, maybe two if the first is light

## Blockers

- Hobson's write boundary must be confirmed before re-execution
- Rollback must complete before re-execution
- The blueprint fix needs to actually happen this time
