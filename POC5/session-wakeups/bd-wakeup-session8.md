# BD Wake-Up — POC5 Session 8

## Paste this to start the session:

```
Read /workspace/AtcStrategy/POC5/session-wakeups/bd-wakeup-session8.md then tell me where we are.
```

---

## What Happened in Session 7

1. **Phase 2 executed and complete.** 4 parallel agents, 10 Tier 2 jobs, 920/920 Proofmark PASS. Verification passed 7/7.
2. **Post-execution audit ran.** Two background agents independently verified:
   - Anti-pattern remediation: 9/10 jobs had real APs, all substantively remediated. One minor residual: PreferenceChangeCount still sources `preference_id` after RANK() removal (unused column, AP4). Assessment doc claims it was removed — it wasn't.
   - Data profiling: 100/100 spot-checks clean. All output matches V1.
3. **Race condition identified.** Agents queued framework tasks and Proofmark comparisons before config files were written to disk. Cost ~860 wasted turns, ~70M wasted cache read tokens, ~$4-5 burned, ~35 min wall clock. Details in `/workspace/AtcStrategy/POC5/phase-2-sequencing-bug.md`.
4. **Phase 2 post-mortem written.** Full assessment at `/workspace/AtcStrategy/POC5/phase-2-post-mortem.md`.

## Open Item: Sequencing Bug Fix

Dan wants this fixed before Phase 3 execution. The fix is adding an ordering constraint to `re-blueprint.md` (the RE Workflow section, between steps 7 and 8) that says "verify config files exist on disk before queuing tasks."

Read `/workspace/AtcStrategy/POC5/phase-2-sequencing-bug.md` for the full diagnosis, cost breakdown, and exactly where to apply the fix. It's a two-sentence edit to re-blueprint.md. Do it before planning Phase 3.

Dan's position: he wants GSD (or BD, the line is blurry) to fix it. BD's position from last session: this isn't a GSD workflow task, it's a 30-second edit to a POC5 artifact that GSD planners read. Don't overthink it — just add the constraint and move on.

## IMPORTANT: GSD Working Directory

**GSD runs in `/workspace/EtlReverseEngineering/`, NOT `/workspace/`.** The `.planning/` directory, all GSD state, and the git repo live there. You MUST `cd /workspace/EtlReverseEngineering` before running any GSD commands.

## Read These

1. `/workspace/EtlReverseEngineering/.planning/STATE.md` — current project state
2. `/workspace/EtlReverseEngineering/.planning/ROADMAP.md` — Phase 2 complete, Phase 3 next
3. `/workspace/AtcStrategy/POC5/phase-2-sequencing-bug.md` — the fix to apply
4. `/workspace/AtcStrategy/POC5/re-blueprint.md` — where the fix goes (RE Workflow section)

## What's Next

1. Apply the sequencing fix to `re-blueprint.md`
2. `/clear`
3. `/gsd:plan-phase 3` — Tier 3 Append Mode

## GSD Context Warning

Each GSD slash command injects a massive workflow definition into context. Budget accordingly:
- `/clear` between GSD steps
- Plan for one major GSD command per session, maybe two if the first is light

## Blockers

None. Phase 2 done, Phase 3 ready to plan after the sequencing fix.
