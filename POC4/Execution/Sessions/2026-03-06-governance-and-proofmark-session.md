# Session Handoff: Governance Close-Outs & Proofmark Scale Design

**Written:** 2026-03-06
**Previous handoff:** `2026-03-06-doc-tree-session.md` (Doc Tree & Canonical Steps)

---

## What We Accomplished

### 1. Canonical Steps — APPROVED
Dan reviewed and approved the canonical steps draft. Status changed from DRAFT to APPROVED.
Added living-document note: steps may be modified as we proceed. Fixed stale TODOs that
Pat caught. Resolved all three open questions:
- Q1: Step 6 starts from DB inventory, no pre-scoping needed
- Q2: Close-out packets written for Steps 1-4
- Q3: Doctrine amendment for Proofmark status

### 2. Governance Close-Out Packets — Steps 1-4
Written at `Governance/Prerequisites/step[1-4]-closeout.md`. Format: one paragraph,
timestamp, evidence pointers. Jim and Pat reviewed. Jim blocked Step 3 initially
(canonical steps was still DRAFT) — resolved by Dan approving canonical steps. Jim's
conditional items on Steps 1 and 4 addressed (POC3 artifact disposition, test count,
curated output deletion confirmation).

### 3. Doctrine Amendment 001 — APPLIED
§2.5 header changed from "Promising, Not Proven" to "Accuracy Validated Within Tested
Scope, Untested at Scale." Jim's conditions met: header acknowledges test 013 CSV quoting
gap (HIGH risk for production), severity preserved, residual accuracy risk noted in final
guidance sentence. Dan approved. Amendment logged at `Governance/Amendments/001-proofmark-status.md`.

### 4. Step 5 Scope Clarified
Dan corrected the Step 5 label from "Framework Changes" to "Tooling & Framework Changes."
Step 5 covers ALL tooling updates, not just MockEtlFramework. This includes Proofmark
changes needed for scale. **Step 5 is NOT done** — framework side is complete but
Proofmark queue runner is designed but not implemented.

### 5. Proofmark Queue Runner — DESIGNED, NOT IMPLEMENTED
Full design conversation happened. Here's what was decided:

**Problem:** 18,400 Proofmark comparisons during POC4 execution (92 dates × ~100 jobs × ~2
comparisons each). Python startup overhead is ~140ms per invocation = 43 minutes of pure
startup tax. Current architecture: one CLI invocation per comparison.

**Solution: PostgreSQL-backed task queue with parallel workers.**

Architecture:
- **Queue table** in PostgreSQL (same infrastructure as MockEtlFramework)
- **Parent thread** spawns at the start of the comparison phase
- **5 parallel worker threads** under the parent
- Each worker polls the queue every N seconds
- Worker claims a task using `SELECT ... FOR UPDATE SKIP LOCKED` (race-condition-free)
- Worker runs the comparison using the existing `pipeline.run()` function (already stateless)
- Worker writes result back to the queue table, then checks for next task
- Workers loop until killed

**Task submission:** Agents write comparison tasks to the queue table (config path, LHS path,
RHS path). Agents poll for results by task ID or job/date key.

**Lifecycle:**
- Dan starts the parent thread before the comparison phase
- Dan shuts it down when he's satisfied the phase is complete
- Same governance pattern as MockEtlFramework's long-running process
- Runbook (Step 16) will include start/stop steps for both processes
- The queue runner does NOT self-terminate. Dan says when it's done.

**Why not file-based queue:** Race conditions with parallel workers. Two workers see the
same file, both pick it up. You'd need file locking or atomic renames, which is reinventing
a shitty database. PostgreSQL `SKIP LOCKED` solves this for free.

**Why not batch mode:** Coordination problem. Somebody has to decide when to fire a batch,
and that somebody needs workflow context Proofmark shouldn't have. Queue inverts this — each
job just says "compare this" and walks away. Also handles trickle-in naturally (comparisons
arrive as jobs finish, don't need to wait for a batch to fill).

**Why not a daemon/service:** It IS a long-running process, but it's not a service in the
REST API sense. It's the same model as MockEtlFramework: start it, it processes work, Dan
kills it when done.

---

## What To Do Next

### Priority 1: Implement Proofmark queue runner
This is the remaining Step 5 work. Build:
1. Queue table schema (tasks table in PostgreSQL)
2. `proofmark serve` command (or similar) — parent thread + 5 workers
3. Task claiming with `SKIP LOCKED`
4. Result writing back to queue table
5. Agent-facing interface: how to submit tasks and poll results
6. Tests

### Priority 2: Write Step 5 close-out
Once the queue runner is implemented and tested, write `step5-closeout.md` covering
both the framework changes (already done) and the Proofmark queue runner.

### Priority 3: Burn deprecated docs
Dan approved canonical steps. The two source docs are deprecated:
- `planning-progression.md` (at POC4 root)
- `memory/poc4-roadmap.md`
Delete them and update references.

### Priority 4: Continue through canonical steps
Step 6 (Job Config Triage) is next after Step 5 closes. Starts from DB inventory of V1 jobs.

---

## What To Read
1. **This file**
2. **Canonical steps:** `Governance/canonical-steps.md` (now APPROVED)
3. **Doctrine §2.5:** Updated with Amendment 001
4. **Proofmark codebase:** `/workspace/proofmark/` — especially `src/proofmark/pipeline.py`
   (the `run()` function is the stateless comparison entry point)
5. **MockEtlFramework queue pattern:** Reference for how the existing long-running process works

## What NOT To Read
- Jim and Pat's full review transcripts (findings are already incorporated)
- AAR log
- POC3 governance reviews
