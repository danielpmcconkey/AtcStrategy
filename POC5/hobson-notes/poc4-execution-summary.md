# POC4 Execution Phases — Summary for POC5

## The Vertical Model (What Failed)

POC4 processed the entire portfolio through each phase before moving to the next:

1. **E.1 — Infer Business Requirements:** Run all V1 jobs for Oct 1-7. Review all V1 code. Write all BRDs with output manifests. Independent review of all BRDs.
2. **E.2 — Functional Specs & Test Strategy:** Write all FSDs from all BRDs. Write all test strategies. Independent review of all FSDs and test docs.
3. **E.3 — Sabotage Round 1:** Plant errors in 10 random BRDs, propagate through downstream docs.
4. **E.4 — Build:** Build all V4 code per FSDs. Write all unit tests. Smoke test all jobs for Oct 1-7. Independent reviews.
5. **E.5 — Sabotage Round 2:** Plant errors in 10 random V4 codebases.
6. **E.6 — Validate:** Run V1+V4 for each effective date (Oct 1 → Dec 31). Proofmark all output. Triage failures. Fix and re-run ALL dates from start on any change.
7. **E.7 — Close-Out:** Final evidence package or lessons learned.

## Key Problems for POC5 to Solve

- **Vertical = all-or-nothing.** Every job had to pass every phase before any job could move to the next. One slow job blocked everything.
- **E.6 was catastrophic.** Processing all jobs per date, then all dates sequentially, with mandatory full re-run on any fix. The orchestrators had "high-speed come-apart incidents" and never got out of the 5-job dry run.
- **Orchestrator context rot.** Managing 100+ jobs across phases was too much state for an LLM to track.
- **Agents edited things they shouldn't.** Orchestrator modified V1 code and framework code despite instructions not to.

## POC5 Horizontal Alternative

One job at a time. Infer its requirements → write its spec → build its code → validate across ALL effective dates → done. Move to next job. Each stage is an atomic agent that claims a task, does its work, writes its output, and dies.

## Agent Roles (from POC4, applicable to POC5)

- **Analyst** — reads V1 code, infers business requirements, writes BRD
- **FSD Architect** — writes functional spec from BRD
- **FSD Reviewer** — independent review of FSD
- **Test Architect** — writes test cases from BRD/FSD
- **Code Builder** — writes V4 job config + external modules + unit tests
- **Validator** — runs V1+V4, runs Proofmark, triages results
- **Errata Curator** — summarizes common issues from triage

## Phase Boundaries

POC4 had hard phase boundaries with BD recycling between each. POC5 should have agent atomicity instead — each agent is a fresh context that claims one task, does one thing, and dies.
