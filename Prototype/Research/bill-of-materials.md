# Prototype Bill of Materials: CE-Style RE Workflow in Pi

**Date:** 2026-04-15
**Author:** BD (Claude Code agent), with Dan McConkey
**Status:** Draft

---

## Design Philosophy

Compound Engineering's power comes from a simple loop: **brainstorm → plan → work → review → compound**. The "compound" step is the product — every solved problem becomes searchable institutional knowledge that auto-injects into future work. Later jobs get smarter because earlier jobs left breadcrumbs.

We can't use CE directly (it's a Claude Code plugin, and Claude Code isn't available in the lab). So we're building the same workflow in Pi using the portable Agent Skills standard (SKILL.md). The phases map to CE. The knowledge loop maps to CE. The experience maps to CE. The internals are purpose-built for ETL reverse engineering.

---

## The Compound Loop

This is the spine of the entire system. Everything else exists to serve it.

```
                    ┌─────────────────────────────────────────┐
                    │          docs/solutions/                │
                    │  ┌─────────────────────────────────┐    │
                    │  │ re-pivot-tables.md               │    │
                    │  │ re-cumulative-append.md          │    │
                    │  │ re-framework-best-practices.md   │    │
                    │  │ re-date-filter-injection.md      │    │
                    │  │ ...                              │    │
                    │  └─────────────────────────────────┘    │
                    └──────┬──────────────────────▲───────────┘
                           │                      │
                      /re:recall               /re:compound
                    (auto-inject)            (capture learnings)
                           │                      │
                           ▼                      │
        ┌──────────────────────────────────────────────────┐
        │                                                  │
        │   brainstorm ──→ plan ──→ work ──→ review ───────┤
        │  /re:discover  /re:spec  /re:build /re:validate  │
        │                                                  │
        └──────────────────────────────────────────────────┘
                         ▲            │
                         │            ▼
                    /re:deploy (gate, then done)
```

### How Compounding Works

**After every completed job**, `/re:compound` distills what was learned into a structured markdown file:

```yaml
---
title: "Cumulative append jobs require snapshot-then-diff strategy"
tags: [append-mode, cumulative, proofmark, validation]
category: build-pattern
job_ids: [job-012, job-017]
transform_types: [cumulative-append]
data_sources: [inventory_daily, transaction_log]
date: 2026-05-15
---

## Problem
Cumulative append jobs write all historical data on every run. Naive RE
produces correct final output but fails Proofmark on intermediate dates
because row ordering shifts when the full dataset is re-sorted.

## Solution
Snapshot the prior day's output, compute only the delta, append in
original insertion order. Proofmark config needs `row_order: preserve`
instead of the default `row_order: ignore`.

## Why This Works
The OG job's append behavior is accidentally order-dependent...
```

**Before every phase**, `/re:recall` searches `docs/solutions/` by tags matching the current job's characteristics — data source types, transform patterns, framework behaviors encountered during discovery. Relevant learnings get injected into the skill's context automatically.

**The result:** Job 1 runs blind. Job 5 has four jobs' worth of edge cases and solutions pre-loaded. Job 50 has a near-complete playbook for every pattern the team has seen.

### Knowledge Taxonomy

| Category | What Gets Captured | Searched By |
|----------|-------------------|-------------|
| `build-pattern` | Reusable implementation approaches for specific transform types | `tags`, `data_sources` |
| `best-practice` | Correct way to use a framework feature — the pattern to follow, not the mistake to avoid | `tags`, `transform_types` |
| `proofmark-gotcha` | Validation edge cases — things that look wrong but aren't, or vice versa | `tags`, `category` |
| `synth-data-recipe` | How to generate realistic synthetic data for a specific source type | `data_sources`, `tags` |
| `triage-playbook` | Root cause + fix for a specific failure mode | `tags`, `category` |
| `framework-quirk` | Target framework behaviors that affect config generation | `tags`, `category` |

---

## Workflow Phases

The outer phases map directly to CE. The inner activities are RE-specific.

### Phase 1: Brainstorm → `/re:discover`

**CE equivalent:** `/ce:brainstorm` — interactive exploration of what we're dealing with

| Activity | What Happens |
|----------|-------------|
| Locate OG source files | Find all code files that comprise this job — main script, external modules, configs |
| Inventory outputs | Catalog every output file: path, format, partitioning scheme, write mode (overwrite vs append) |
| Inventory data sources | Catalog every upstream dependency: tables, files, APIs. Schema, row counts, date ranges |
| Note dependencies | Map cross-job dependencies, shared modules, execution order constraints |
| **Artifact produced** | **Job Manifest** (JSON) — complete inventory of everything the job touches |

### Phase 2: Plan → `/re:spec`

**CE equivalent:** `/ce:plan` — creating the specification (not "planning" in the project-management sense)

We use "spec" instead of "plan" to avoid confusion. CE's "plan" phase produces the spec that the work phase implements. That's exactly what this phase does — it documents the observable behaviors of the OG job and produces the BDD specs and FSD that the build phase consumes.

| Activity | What Happens |
|----------|-------------|
| Document behaviors | Analyze the OG code and document what it does — observable inputs, transforms, and outputs. Behavior documentation, not business requirements. The "what," not the "why" or "how" |
| Review behaviors | Adversarial self-review against checklist. In Walk/Run mode, a separate review persona |
| Write BDD specs | Behavior-Driven Design: Given/When/Then gherkins for every observed behavior, written to framework best practices |
| Review BDD | Verify BDD covers all behaviors documented, no gaps, gherkins follow framework conventions |
| Write FSD | Functional Specification Document: transformation logic expressed in framework-correct patterns |
| Review FSD | Verify FSD is traceable to behavior docs, BDD specs are implementable from FSD |
| **Artifacts produced** | **Behavior documentation, BDD gherkins, FSD** |

### Phase 3: Work → `/re:build`

**CE equivalent:** `/ce:work` — implement the spec

| Activity | What Happens |
|----------|-------------|
| Build job config | Generate framework-ready JSON configuration from FSD, following framework best practices |
| Build external modules | Write Python code for transforms that can't be expressed in config alone |
| Build Proofmark config | Configure byte-level comparison: file mappings, row ordering rules, tolerance settings |
| Review artifacts | Verify config + modules implement the FSD faithfully using correct framework patterns |
| Build unit tests | Write tests derived from BDD gherkins |
| Execute unit tests | Run tests, iterate on failures |
| Publish | Deploy job to the framework's job registry |
| **Artifacts produced** | **Job config, external modules, Proofmark config, unit tests, published job** |

### Phase 4: Review → `/re:validate`

**CE equivalent:** `/ce:review` — adversarial verification

| Activity | What Happens |
|----------|-------------|
| Execute job runs | Run the RE job across all date partitions in the synthetic prod environment |
| Execute Proofmark | Byte-level comparison of OG output vs RE output |
| Evidence audit (Pat) | Adversarial final review: assumes every prior phase cut corners. Inspects traceability across all artifacts. This is the "bullshit detector" |
| PatFix (if needed) | Auto-remediate documentation/test drift found by Pat |
| **Artifacts produced** | **Proofmark results, evidence audit report, sign-off** |

### Phase 5: Compound → `/re:compound`

**CE equivalent:** `/ce:compound` — capture what was learned

| Activity | What Happens |
|----------|-------------|
| Distill learnings | Extract reusable knowledge from the completed job |
| Tag and categorize | Apply taxonomy tags so future `/re:recall` can find it |
| Write to `docs/solutions/` | Structured markdown with YAML frontmatter |
| **Artifact produced** | **Knowledge file(s) in docs/solutions/** |

### Phase 6 (Outside Loop): `/re:deploy`

**No CE equivalent** — this is RE-specific

| Activity | What Happens |
|----------|-------------|
| Deploy to lightweight prod | Push validated RE job to the prod-like lab environment |
| Run against synthetic data | Execute with realistic data volumes and patterns |
| Evaluate results | Final acceptance against synthetic prod baseline |

---

## Mapping: CE Phases → RE Skills → Prior Pipeline Nodes

For those familiar with the prior weekend and evenings work (Ogre pipeline), here's how the 29 autonomous nodes collapse into the 6 human-gated CE phases:

| CE Phase | RE Skill | Prior Pipeline Nodes |
|----------|----------|---------------------|
| **Brainstorm** | `/re:discover` | LocateOgSourceFiles, InventoryOutputs, InventoryDataSources, NoteDependencies |
| **Plan** | `/re:spec` | WriteBrd, ReviewBrd, WriteBddTestArch, ReviewBdd, WriteFsd, ReviewFsd |
| **Work** | `/re:build` | BuildJobArtifacts, ReviewJobArtifacts, BuildProofmarkConfig, ReviewProofmarkConfig, BuildUnitTests, ReviewUnitTests, ExecuteUnitTests, Publish |
| **Review** | `/re:validate` | ExecuteJobRuns, ExecuteProofmark, FBR_EvidenceAudit, PatFix |
| **Compound** | `/re:compound` | *(new — prior work didn't have this)* |
| *(gate)* | `/re:deploy` | *(new — prior work stopped at validation)* |

---

## Full Component Inventory

### Skills (SKILL.md files)

| # | Skill | Layer | Purpose | Crawl | Walk | Run |
|---|-------|-------|---------|-------|------|-----|
| 1 | `/re:discover` | Core | Brainstorm phase — inventory and recon | Manual | Auto-chain to spec | Auto |
| 2 | `/re:spec` | Core | Plan phase — behavior docs, BDD gherkins, FSD | Manual | **Human gate** | Auto w/ review loop |
| 3 | `/re:build` | Core | Work phase — config, modules, tests, publish | Manual | Auto-chain to validate | Auto |
| 4 | `/re:validate` | Core | Review phase — Proofmark, evidence audit, Pat | Manual | Auto-chain from build | Auto w/ triage |
| 5 | `/re:compound` | Core | Compound phase — capture learnings | Manual | Manual | Auto |
| 6 | `/re:deploy` | Core | Deploy to synthetic prod, evaluate | Manual | **Human gate** | Auto |
| 7 | `/re:recall` | Knowledge | Search docs/solutions/, inject relevant learnings | Manual | Auto (hook) | Auto (hook) |
| 8 | `/re:init` | Support | Initialize job workspace, create directory structure, register in tracker | Manual | Manual | Auto |
| 9 | `/re:status` | Support | Show state of all jobs across phases | Manual | Dashboard | Dashboard |
| 10 | `/re:review` | Support | Standalone adversarial review — invoke against any artifact | Manual | On-demand | Auto (gate) |
| 11 | `/re:triage` | Support | RCA → Fix → Reset when validation fails | Manual RCA | Semi-auto | Auto |
| 12 | `/re:synth-data` | Support | Generate synthetic test data from behavior doc source inventory | Manual | Manual | Semi-auto |

### Pi Extensions (TypeScript, ~/.pi/agent/extensions/)

| # | Extension | Purpose | Crawl | Walk | Run |
|---|-----------|---------|-------|------|-----|
| 13 | `auto-recall` | Before any `/re:*` skill, auto-invoke `/re:recall` to inject knowledge | Not needed | **Required** | **Required** |
| 14 | `job-tracker` | After any `/re:*` skill completes, update job state with phase, timestamp, outcome | Not needed | **Required** | **Required** |
| 15 | `phase-chain` | Auto-invoke next phase after mechanical phases complete (discover→spec, build→validate). Decision phases (spec→build, validate→deploy) still require human invocation | Not needed | **Required** | Replaced by orchestrator |
| 16 | `artifact-guard` | Before a phase starts, verify required input artifacts from prior phase exist and pass sanity checks | Not needed | Nice-to-have | **Required** |

### CLI Tools (with README files — Pi's MCP alternative)

| # | Tool | Purpose | Crawl | Walk | Run |
|---|------|---------|-------|------|-----|
| 17 | `proofmark` | Byte-level OG vs RE output comparison. Port from prior work, adapt for synthetic data paths | Port | Same | Same |
| 18 | `re-framework-cli` | CLI wrapper for target ETL framework — execute jobs, check status, retrieve output | Build or wrap | Same | Same |
| 19 | `job-tracker-cli` | Read/write job tracker state. JSON file in Crawl/Walk, Postgres in Run | JSON file | JSON file | Postgres |

### Orchestrator (Run Mode Only)

| # | Component | Purpose | Crawl | Walk | Run |
|---|-----------|---------|-------|------|-----|
| 20 | `re-engine` | Deterministic state machine + Postgres job queue. Pulls next job+phase, invokes Pi via RPC, routes outcome | Not needed | Not needed | **Required** |
| 21 | `worker-pool` | N concurrent Pi RPC processes in isolated working directories (git worktrees) | Not needed | Not needed | **Required** |
| 22 | `token-budget` | API token consumption monitor. Clutch pattern: throttle at 90%, drain in-flight jobs | Not needed | Not needed | **Required** |

**Run mode alternative:** Skip Pi RPC entirely. Use the raw Anthropic API with built-in `bash` and `text_editor` tools. ~500 lines of Python. More control, no CLI dependency.

### Project Context Files

| # | File | Purpose |
|---|------|---------|
| 23 | `CLAUDE.md` | Project instructions. Pi reads natively. Repo structure, coding standards, framework conventions, phase descriptions |
| 24 | `docs/best-practices.md` | Framework best practices — the correct patterns for using the target ETL framework. Referenced by `/re:spec` and `/re:build` |
| 25 | `docs/templates/behavior-doc.md` | Behavior documentation template with required sections |
| 26 | `docs/templates/fsd.md` | FSD template with required sections |
| 27 | `docs/templates/bdd.md` | BDD gherkin template — follows framework best practices |
| 28 | `docs/templates/evidence-audit.md` | Pat's evidence audit checklist |
| 29 | `docs/solutions/` | Knowledge base directory (starts empty, grows with every completed job) |

---

## Crawl → Walk → Run: What Gets Built When

### Crawl (Weeks 1-3) — Prove the Workflow

**Goal:** 5 jobs RE'd with correct output against synthetic data. Knowledge base has its first entries.

**Build:**
- 6 core skills (#1-6)
- Knowledge recall skill (#7)
- `/re:init` and `/re:status` (#8-9)
- Project context files + templates (#23-28)
- Knowledge base directory (#29)
- Port Proofmark (#17)
- Framework CLI wrapper (#18)

**Components:** 16 of 29
**Estimated effort:** 3-4 weeks
**How it works:** One human, one job at a time. Invoke `/re:discover`, read the output, invoke `/re:spec`, read the output, and so on. The human IS the state machine. After each job, manually run `/re:compound` to capture learnings. Before the next job, manually run `/re:recall` to see what prior jobs taught you.

### Walk (Weeks 4-6) — Automate the Glue

**Goal:** 20+ jobs RE'd. Knowledge loop is demonstrably making later jobs faster and higher quality.

**Build (incremental):**
- Pi extensions: auto-recall, job-tracker, phase-chain, artifact-guard (#13-16)
- `/re:review` standalone adversarial review (#10)
- `/re:triage` semi-automated (#11)
- `/re:synth-data` (#12)
- Job tracker CLI (#19)

**New components:** 8 (total: 24 of 29)
**Estimated effort:** 2 weeks
**How it works:** Multiple team members, multiple jobs in parallel. Knowledge injection is automatic. Mechanical phases chain automatically. Humans only gate at the two decision points: spec→build ("is this spec right?") and validate→deploy ("is this ready for prod?").

### Run (Weeks 7-10) — Full Autonomy

**Goal:** 100 jobs RE'd. Operator queues jobs and checks results.

**Build (incremental):**
- Orchestrator engine (#20)
- Worker pool (#21)
- Token budget monitor (#22)
- Upgrade job tracker to Postgres

**New components:** 3 + upgrades (total: 29 of 29)
**Estimated effort:** 3-4 weeks
**How it works:** Queue jobs into Postgres. Start the worker pool. Go to sleep. Check results in the morning. Handle dead letters when you get to work. This is Ogre, rebuilt.

---

## Total Bill of Materials

| Layer | Components | Crawl | Walk | Run |
|-------|-----------|-------|------|-----|
| Core Skills | 6 SKILL.md files | All 6 | Same | Same |
| Knowledge Loop | 1 skill + directory | Both | Same (auto) | Same (auto) |
| Support Skills | 5 SKILL.md files | 2 of 5 | All 5 | All 5 |
| Pi Extensions | 4 TypeScript files | 0 of 4 | All 4 | 3 of 4 |
| CLI Tools | 3 tools | 2 of 3 | All 3 | All 3 (upgraded) |
| Orchestrator | 3 components | 0 of 3 | 0 of 3 | All 3 |
| Project Context | 7 files | All 7 | Same | Same |
| **Totals** | **29 components** | **16** | **24** | **29** |

---

## What You're NOT Building

- **A custom state machine** (until Run mode) — the human IS the state machine in Crawl and Walk
- **MCP servers** — Pi's CLI-with-README pattern is more token-efficient and simpler
- **A web UI / dashboard** — `/re:status` reads a JSON file; pipe it through `jq` if you want it pretty
- **Model fine-tuning** — off-the-shelf Claude with well-crafted prompts, same as prior work
- **Data pipeline infrastructure** — the lightweight prod environment is a given; you're deploying RE jobs into it

---

## Open Questions

1. **Which ETL framework is the target?** The framework CLI wrapper (#18) and job config format depend on this.
2. **How is synthetic data generated today?** Is there an existing tool, or is `/re:synth-data` net-new?
3. **Lab environment access model** — VDI with WSL? Direct Linux VMs? This affects Pi installation and extension paths.
4. **API key management** — How will Claude API keys be provisioned in the lab? Per-user? Shared team key with rate limiting?
5. **Git workflow** — One repo per job? Monorepo with branches? This affects isolation for Walk/Run modes.
