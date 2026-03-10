# BD Wake-Up — POC5 Session 7

## Paste this to start the session:

```
Read /workspace/AtcStrategy/POC5/session-wakeups/bd-wakeup-session7.md then tell me where we are.
```

---

## What Happened in Session 6

1. **External module rebuild protocol added to PROJECT.md.** When an agent needs to create or update an external module in MockEtlFramework:
   - Write the `.cs` file to `MockEtlFramework/ExternalModules/`
   - Stop submitting new work to `control.task_queue`
   - Wait for all claimed/running tasks to drain (worker threads claim entire batches — killing mid-batch orphans them)
   - Signal Dan (through BD) to rebuild MockEtlFramework and restart the framework
   - Block until Dan confirms rebuild is complete
   - Resume
   This is a mechanical limitation (compiled assemblies), not a break in autonomy. It applies to all phases going forward.
2. **Phase 2 fully planned** — 4 plans, 1 wave, all parallel. Research + planning + verification all passed clean.
3. **Key research findings for Phase 2:**
   - No external modules needed for any Tier 2 job (rebuild protocol won't trigger this phase)
   - Parquet output is new — 4 of 10 jobs write Parquet (Phase 1 was CSV-only)
   - TopBranches dependency on BranchVisitSummary is fake — reads datalake directly. All 10 jobs can run in parallel.
   - FeeWaiverAnalysis has a suspicious LEFT JOIN (same pattern as Phase 1's cartesian join — needs runtime verification)
   - Two jobs have trailers (CardAuthorizationSummary deterministic, TopBranches non-deterministic)

## IMPORTANT: GSD Working Directory

**GSD runs in `/workspace/EtlReverseEngineering/`, NOT `/workspace/`.** The `.planning/` directory, all GSD state, and the git repo live there. You MUST `cd /workspace/EtlReverseEngineering` before running any GSD commands or they'll fail with "phase not found."

## External Module Rebuild Protocol

This doesn't apply to Phase 2 (no external modules), but it will matter starting Phase 4 (Tier 4 — External Module Conversion, ~67 jobs). The constraint lives in `/workspace/EtlReverseEngineering/.planning/PROJECT.md` under Constraints. Read it before planning any phase that involves external modules.

## Read These

1. `/workspace/EtlReverseEngineering/.planning/STATE.md` — current project state
2. `/workspace/EtlReverseEngineering/.planning/ROADMAP.md` — 6 phases, Phase 1 complete, Phase 2 planned
3. `/workspace/EtlReverseEngineering/.planning/PROJECT.md` — includes the external module rebuild protocol
4. `/workspace/EtlReverseEngineering/.planning/phases/02-tier-2-simple-multi-source/02-RESEARCH.md` — Phase 2 research
5. `/workspace/AtcStrategy/POC5/re-blueprint.md` — SQL templates, gotchas, infrastructure patterns

## What's Next

1. **`/clear` first** — fresh context window
2. **`/gsd:execute-phase 2`** — Execute all 4 plans (1 wave, parallel)

| Plan | Jobs | Key Challenge |
|------|------|---------------|
| 02-01 | CustomerAccountSummary, SecuritiesDirectory, TransactionSizeBuckets | Clean CSV |
| 02-02 | CardAuthorizationSummary, FeeWaiverAnalysis, TopBranches | Trailers, suspicious JOIN |
| 02-03 | CardStatusSnapshot, TopHoldingsByValue | First Parquet validation |
| 02-04 | AccountOverdraftHistory, PreferenceChangeCount | Final Parquet + 920/920 gate |

## GSD Context Warning

Each GSD slash command injects a massive workflow definition into context. Budget accordingly:
- `/clear` between GSD steps
- Plan for one major GSD command per session, maybe two if the first is light

## Blockers

None. Phase 2 planned and verified, ready to execute.
