# Phase 2 Sequencing Bug — Fix This

## The Problem

During Phase 2 execution, all 4 GSD executor agents queued framework tasks
and Proofmark comparisons BEFORE the config files were written to disk. The
framework and Proofmark workers picked up the tasks, couldn't find the files,
and failed. The framework's fail-fast then cascaded SKIPs across entire batches.

Agents eventually self-recovered (wrote the files, re-queued), but the damage
was done.

## What It Cost

| Agent | Jobs | Turns Used | Estimated Clean Turns | Wasted Turns |
|-------|------|------------|----------------------|--------------|
| 02-01 | 3 | 336 | ~120 | ~216 |
| 02-02 | 3 | 248 | ~100 | ~148 |
| 02-03 | 2 | 214 | ~90 | ~124 |
| 02-04 | 2 | 521 | ~150 | ~371 |
| **Total** | **10** | **1,319** | **~460** | **~860** |

- **~65% of all agent turns were retry/diagnostic overhead**
- **~70M wasted cache read tokens** (every retry re-reads full context)
- **~35 min wall clock wasted** (agents took 33-55 min, clean should be ~15-20)
- **~$4-5 burned on retries** for a phase that should've cost ~$3 total
- 02-04 was worst: 521 turns and 51M cache reads for 2 jobs

## Root Cause

The RE Workflow in `re-blueprint.md` lists the steps in the right order:

```
6. Write _re job conf
7. Write Proofmark config YAML
8. Register job in control.jobs
9. Queue 92 dates in control.task_queue
10. Verify all Succeeded
11. Queue 92 Proofmark comparisons
12. Verify 92/92 PASS
```

But there's no enforcement or explicit warning that steps 6-7 MUST complete
and be verified on disk before steps 8-11 execute. The agents treated it as
a loose checklist rather than a strict sequence. Some wrote SQL that queued
tasks and inserted proofmark rows in the same batch as writing config files.

## The Fix

The ordering constraint needs to be explicit in `re-blueprint.md` (the file
GSD planner agents actually read when generating plans). Something like:

> **CRITICAL ORDERING:** Steps 6-7 (write config files) must complete and be
> verified on disk (`test -f path`) BEFORE steps 8-11 (queue tasks/proofmark).
> The framework and Proofmark workers pick up queued items immediately. If the
> config files don't exist yet, the first task fails and fail-fast cascades
> SKIPs across the entire batch.

This is a one-liner fix that prevents $5 and 35 minutes of waste per phase.
It applies to every future phase — the race condition gets worse as job counts
grow (Phase 4 has ~67 jobs).

## Where To Fix

- `re-blueprint.md` — RE Workflow section, between steps 7 and 8
- Optionally also in `PROJECT.md` constraints (like the external module rebuild protocol)
