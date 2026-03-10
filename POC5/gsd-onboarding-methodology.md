# GSD Onboarding Methodology for Large-Scale RE Projects

**Purpose:** Reference doc for how we fed a 105-job reverse engineering project to GSD. Reusable when Dan brings this methodology to his work platform.

**Date:** 2026-03-09, POC5 Session 3

---

## The Problem GSD Wasn't Designed For

GSD assumes you're building something new. Its questioning phase asks "what do you want to build?" and expects a greenfield answer. A large-scale RE project is different:

- The deliverable is well-defined (match existing output with clean code)
- The work is repetitive (105 instances of the same workflow)
- Success is binary per job (92/92 PASS or not)
- The complexity varies by job, not by feature

## What We Did

### 1. Front-Loaded Context Into the Questioning Phase

GSD's questioning phase asks "what do you want to build?" and follows threads until it has enough to write PROJECT.md. We didn't skip this — we changed the shape of the input.

Dan had already done 2 sessions of recon with BD (the sandbox Claude instance) before GSD was initialized. Rather than make Dan re-explain everything from scratch, he provided a detailed "definition of success" pitch covering the 8 deliverables per job, the anti-pattern remediation mandate, and the autonomy constraint. BD then critiqued the pitch for gaps that downstream GSD agents would need filled.

**Important:** We drafted PROJECT.md from this, but the GSD questioning gate still runs. The agent reviews the draft and has full opportunity to ask questions, identify gaps, or push back. We're giving him a head start, not a fait accompli.

### 2. Supplemented Dan's Pitch with Agent Context

Dan's pitch was human-readable but missing things GSD agents need:
- **Infrastructure details** — path tokens, database, task queue mechanics
- **Tiering strategy** — job complexity tiers and processing order
- **Anti-pattern catalog** — inlined so agents don't need to find external files
- **Autonomy constraint** — "zero human input" needs to be a first-class constraint, not a footnote
- **Expected workflow** — the base per-job process with a note to adapt for complexity (not presented as proven/final)

### 3. Structured PROJECT.md for Batch Work

Standard GSD PROJECT.md has requirements like AUTH-01, CONT-02. Ours has:
- **RE-01 through RE-09** — per-job deliverable requirements (apply to every job)
- **TIER-01 through TIER-06** — batch completion requirements (progress tracking)
- **Prime Directive section** — anti-pattern remediation front and center, especially AP3 (external module minimization)
- **Complexity tiers table** — so the roadmapper can structure phases by difficulty
- **Dependency graph** — so phases respect job ordering constraints

### 4. Used "Validated" Requirements for Infrastructure Only

GSD's brownfield pattern puts existing capabilities in the "Validated" section. We used this for infrastructure only:
- Repository structure and conventions
- Proofmark integration
- ETL Framework / Postgres / path token wiring

We deliberately did NOT mark any job as validated — even though one had been RE'd previously, we reset it so the GSD agent establishes his own patterns from scratch.

## Key Insight

The questioning phase isn't about the questions — it's about ensuring PROJECT.md has enough context for downstream agents to act autonomously. For a well-understood project, the fastest path is:

1. Human provides the "what and why" in their own words
2. Agent critiques for gaps that automated agents will need
3. Agent drafts PROJECT.md combining human framing with technical details
4. Human reviews and adjusts
5. **GSD questioning phase still runs** — the agent validates the draft, not rubber-stamps it

Front-loading context doesn't mean bypassing the process. It means the questioning phase starts from a strong draft instead of a blank page.

## What to Watch For

- **GSD's research phase** may be useless for RE projects — we're not researching a domain, we're analyzing existing code. Consider skipping or repurposing.
- **GSD's requirements phase** assumes feature scoping. Ours is deliverable scoping. The framework handles this fine but the agent prompts assume feature language.
- **Phase granularity** matters a lot — 105 jobs across 6 tiers. Coarse phases (one per tier) or fine phases (one per job)? This is a GSD config decision with real consequences.
- **The "zero human input" constraint** is unusual for GSD. Most projects expect interactive checkpoints. Make sure config reflects YOLO mode.

## Files

| What | Where |
|------|-------|
| Live PROJECT.md | `/workspace/EtlReverseEngineering/.planning/PROJECT.md` |
| Dan's original pitch | This file, referenced above |
| Anti-patterns | `/workspace/AtcStrategy/POC5/anti-patterns.md` |
| Complexity tiers | `/workspace/AtcStrategy/POC5/job-complexity-analysis.md` |
| RE Blueprint | `/workspace/AtcStrategy/POC5/re-blueprint.md` |
| Resurrection state | `/workspace/AtcStrategy/POC5/session-wakeups/bd-resurrection-state.md` |
