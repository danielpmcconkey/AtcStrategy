# Hobson Briefing: Artifact Architecture & Agent Contracts

**From:** BD (basement dweller)
**For:** Hobson (blueprint author)
**Date:** 2026-03-14
**Context:** Session 14 design conversation between Dan and BD. These are decisions, not proposals.

---

## Two Artifact Streams

Every agent produces two kinds of output. Your blueprints need to account for both.

### 1. Process Artifacts (agent-to-agent)

Structured JSON files. One per node per job. These are the "notes for the next guy" — they exist so the orchestrator can route and so downstream agents know what happened upstream.

**Location:** `EtlReverseEngineering/jobs/{job_id}/process/{node-name}.json`

**Format:** Every process artifact MUST include this header:

```json
{
  "node": "brd-writer",
  "job_id": 42,
  "outcome": "SUCCESS",
  "reason": "Generated BRD from Plan phase outputs",
  "conditions": [],
  "artifacts_written": ["artifacts/brd.md"],
  "artifacts_read": ["process/source-analyst.json", "process/output-analyst.json"],
  "body": {
    // node-specific notes for downstream agents — whatever the next guy needs
  }
}
```

**Outcome enum — these are the ONLY valid values:**

| Value | Used By | Meaning |
|-------|---------|---------|
| `SUCCESS` | Work nodes | Did the job, wrote the deliverable |
| `FAIL` | Work nodes | Couldn't complete, `reason` explains why |
| `APPROVED` | Review nodes | Deliverable passes review |
| `CONDITIONAL` | Review nodes | Passes with caveats, `conditions[]` lists them |
| `REJECTED` | Review nodes | Fails review, `reason` explains why |

The orchestrator is deterministic. It reads `outcome`, routes to the next state per the state machine, and doesn't interpret anything else. The `reason`, `conditions`, and `body` fields are for humans and downstream agents only.

**Critical rule:** An agent only writes its process JSON on success/approval/conditional. If the agent fails or rejects, the orchestrator handles routing — no process artifact gets written for the failed attempt. (Edit: this applies to the *process artifact for the next node*. The agent should still communicate its FAIL/REJECTED outcome back to the orchestrator via stdout — see "Agent Response Contract" below.)

### 2. Product Artifacts (the deliverables)

The actual RE outputs — BRDs, FSDs, BDD specs, generated code, test suites. These are the *point* of the whole operation. Humans read these eventually.

**Location:** `EtlReverseEngineering/jobs/{job_id}/artifacts/`

```
jobs/{job_id}/artifacts/
  brd.md
  fsd.md
  bdd_specs/
  code/
    jobconf.json       # FW grabs this via tokenized path
    transforms/
  tests/
```

**These all live in EtlRE, not MockEtlFramework.** The FW accesses generated code via tokenized paths in `control.jobs` — something like `{token}/EtlReverseEngineering/jobs/42/artifacts/code/jobconf.json`. The FW upstairs de-tokenizes and loads dynamically. No cross-repo writes, no commits mid-flight.

---

## Agent Response Contract

This is how the orchestrator knows what happened. The agent's stdout must end with a fenced JSON block:

```json
{"outcome": "SUCCESS", "reason": "...", "conditions": []}
```

That's it. The orchestrator parses the last JSON block from stdout. Everything above it is agent reasoning/logging that gets captured but not parsed.

Your blueprints should instruct agents to emit this block as their final output.

---

## What Agents Read

An agent needs to read from two places:

1. **Process artifacts from predecessor(s):** The JSON chain tells it what happened upstream. A `brd-reviewer` reads `process/brd-writer.json` to understand what the writer did and where it put the BRD.

2. **Product artifacts from predecessor(s):** The actual deliverables. The `brd-reviewer` reads `artifacts/brd.md` to review the BRD itself. It might also read Plan-phase product artifacts to verify the BRD covers what the analysts found.

3. **Source material in MockEtlFramework:** The OG job code being reverse-engineered. This is read-only. Agents study it, they don't modify it.

Your blueprints should explicitly list what each agent reads. Don't make agents guess — tell them "read these specific files."

---

## All Nodes Are Agentic

This includes the "mechanical" ones — job-executor (running ETL FW jobs), proofmark-executor (running comparisons), publisher. These could be deterministic code, but they're agents for portability reasons. When this moves to Dan's production environment, publishing and orchestration will be more complex. Making everything agentic means the orchestrator has exactly one execution path (invoke blueprint, parse outcome), and the complexity lives in the blueprints where it can be swapped without touching orchestrator code.

So yes, write blueprints for job-executor, proofmark-executor, and publisher too. They'll be simple blueprints, but they're blueprints.

---

## Summary for Blueprint Updates

When writing/updating blueprints, each one should specify:

1. **What process artifacts to read** (predecessor JSON files)
2. **What product artifacts to read** (predecessor deliverables + OG source in MockEtlFW)
3. **What product artifact to write** (the deliverable this node produces)
4. **What the process artifact body should contain** (notes for the next agent)
5. **Which outcome values are valid** (SUCCESS/FAIL for work nodes, APPROVED/CONDITIONAL/REJECTED for review nodes)
6. **The stdout contract** — end with the outcome JSON block

File paths use the convention:
- Process: `jobs/{job_id}/process/{node-name}.json`
- Product: `jobs/{job_id}/artifacts/{whatever}`
- Source: read-only access to MockEtlFramework for OG job code

---

Questions? Take them to Dan. I'm in the basement.
