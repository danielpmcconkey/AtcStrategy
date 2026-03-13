# Adversarial Review #1 — Taxonomy vs Dan's Vision

## Reviewer: Background agent (adversarial)
## Date: 2026-03-10

---

## 1. Point 5 — Parallelism (8-12 fungible workers)

### Bottleneck: Final Build Review is a fan-out bomb

The "Final build review" node (Build L7) re-executes **six** reviewers and triggers re-reviews in Define and Design. That's potentially 9 agent invocations for a single job at a single pipeline stage. If 3 jobs hit Final Build Review simultaneously, you've just spawned 27 tasks and blown past your 12-worker cap. Worse, the re-review agents can fail and queue *more* work (review responses), which queue *more* re-reviews. This single node could monopolize the entire worker pool.

**Dan's response:** Disagree. The deterministic loop manages a pool of 12 workers across ALL jobs. It just queues 17 tasks. The loop processes them as capacity frees up. Non-trivial design problem for call/response simulation through the loop, but not a capacity bomb.

### Bottleneck: Validate stage serializes on external systems

"Execute job runs" and "Execute proofmark" both depend on the ETL Framework and Proofmark running on the host side (Hobson). If 8 jobs are all in Validate simultaneously, they're all hammering the same framework queue and Postgres.

**Dan's response:** (not directly addressed — revisit when discussing Validate stage design)

### Fungibility looks clean ✓

## 2. Point 6 — Agent Atomicity

### Too fat: "Build job artifacts"

This agent creates job conf files *and* external modules. Those are two different skills (JSON/YAML config generation vs. code generation). An agent that fails on the external module has to redo the conf file too. Split them.

**Dan's response:** They ARE split. Two separate rows in the taxonomy. BD misread the tree.

### Too fat: "Triage proofmark failures"

This one is asked to: review proofmark results, determine root cause analysis, fix code/conf/proofmark config, and re-queue. That's diagnosis *and* surgery in one agent.

**Dan's response:** RCA and fix are 2 separate agents, 2 separate rows. Reviewer misread the taxonomy.

### Too thin: "Publish"

"Register jobs in control.jobs table" is a single SQL INSERT. This doesn't need an LLM agent.

**Dan's response:** Possibly. Cross that bridge later. Need to think forward to production environment which will be more complicated.

### Too thin: "Locate OG source files"

This is a file lookup. If the OG source file locations follow any convention, this is a deterministic operation.

**Dan's response:** Same as Publish — cross that bridge later.

### Atomicity violation: Review Response agents

Every "Review response" is listed as a sub-bullet under the Write agents, not as its own leaf node. Unclear if it's a separate agent or part of the Write agent's behavior.

**Dan's response:** Agreed. Needs clarification in blueprint design or routing discussion.

## 3. Point 7 — Minimize Orchestration LLMs

### Problem: "Triage and re-execute any failures" in Execute job runs

Who decides what a failure means? This is a decision point that either requires LLM reasoning in the orchestrator or a dedicated triage agent.

**Dan's response:** (addressed implicitly — the deterministic loop doesn't make these decisions, agents do)

### Problem: "Any fail → route feedback to appropriate layer" in Final Build Review

This routing decision is non-trivial. The taxonomy says "route to appropriate layer" but doesn't define the routing table.

**Dan's response:** Routing is hand-wavy at this point. Probably the next thing to think through, even before blueprints.

### The rest is clean ✓

## 4. Point 1 — Network Isolation / Write Boundary

### Write boundary not implemented

**Dan's response:** (known issue, Hobson working on it — carried from POC5)

### Agent tooling model gives Bash access

`--allowedTools "Bash Read Grep"` gives agents shell access. They can write anywhere.

**Dan's response:** (not directly addressed — relates to blueprint design)

## 5. Point 2 — Horizontal, Not Vertical

### Shared resource: Postgres task queue

All jobs share the same task queue table. Claim mechanism must be airtight.

### Shared resource: File system

No per-job directory isolation defined.

### POC5 sequencing bug (race condition)

Build creates files, Publish registers in DB. If files aren't verified on disk, same race condition.

**Dan's response:** The deterministic loop won't fire validate steps until build steps are verified. The taxonomy already handles this. BD hasn't sufficiently articulated the deterministic loop design — needs discussion.

## 6. General

### Missing: Circuit breaker

Review loops can spin forever without a max-retry count.

**Dan's response:** Valid, but belongs in blueprint design, not taxonomy. Specifically in the triage layer. Check past runs — if this is the 5th triage, give up and report overall process as failed.

### Missing: Per-job cost tracking

A job hitting 10 review cycles burns $5+ silently.

**Dan's response:** Nice to have. To-do list.

### Redundant: Re-review agents vs. Final Build Review

Are these the same thing? Is Final Build Review the trigger, and the re-review agents are what gets triggered?

**Dan's response:** (not directly addressed — likely clarified in routing discussion)

---

## Summary — Dan's Disposition

| Finding | Severity | Disposition |
|---------|----------|-------------|
| No circuit breaker | Critical | Valid — blueprint concern, not taxonomy |
| Write boundary | Critical | Known — Hobson WIP |
| Final Build Review fan-out | High | Disagree — pool is shared, not per-job |
| Triage too fat | High | Disagree — already split in taxonomy |
| Routing hand-wavy | High | Agreed — next design step |
| POC5 race condition | High | Disagree — deterministic loop handles this |
| Review Response ambiguity | Medium | Agreed — blueprint/routing concern |
| Build artifacts too fat | Medium | Disagree — already split in taxonomy |
| Publish/Locate don't need LLMs | Medium | Defer |
| Per-job cost tracking | Medium | Nice to have, to-do |
