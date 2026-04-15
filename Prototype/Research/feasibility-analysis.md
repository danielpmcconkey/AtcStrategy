# Prototype Feasibility Analysis: Tooling for Lab-Based ETL Reverse Engineering

**Date:** 2026-04-15
**Author:** BD (Claude Code agent), with Dan McConkey
**Status:** Draft for Review

---

## Context

Prior weekend and evenings work proved that an AI-driven engine can autonomously reverse-engineer ETL jobs from a legacy framework into a modern one — 41 jobs, 100% accuracy, zero human intervention during execution. That engine (Ogre) was purpose-built around Claude Code CLI instances orchestrated by a deterministic Python state machine.

This prototype moves that work into a corporate lab environment. The constraints are different:

- **No Claude Code** (company standard is Copilot CLI)
- **No production data** — synthetic test data deployed to a lightweight prod-like environment
- **Human-in-the-loop** — fully autonomous operation is a future goal, not a current requirement
- **No custom orchestrator code** as the starting position — use existing tools
- **Small team** executing phases interactively
- **Scope:** 5 jobs to prove the concept, then 100 to prove scale

The question: what tooling gives a small team the best interactive, phased workflow for reverse-engineering ETL jobs — without building custom infrastructure?

---

## The Target Workflow

The team wants a Compound Engineering-style phased workflow with human gates between each phase:

```
brainstorm → plan → design → build → validate → deploy
     ↑ human gate between each phase ↑
```

Plus a knowledge feedback loop where learnings from each completed job automatically inform future jobs.

### Evaluation Criteria

1. **CE-like phased workflow** — brainstorm → plan → work → review, human-gated between phases
2. **Portable skills standard** — reusable, chainable skills in the open Agent Skills (SKILL.md) format; no deepening into any single vendor's ecosystem
3. **Hooks / lifecycle automation** — pre/post actions triggered by workflow events
4. **MCP support** — for external tool integration where needed
5. **Interactive team experience** — this is a team tool, not a daemon
6. **No custom code** — use what exists (at least as the starting position)
7. **Knowledge feedback loop** — solved problems compound into future work

---

## Tools Evaluated

Four candidates were researched for current capabilities (April 2026). Full research write-ups are in the `Research/` directory alongside this document.

### GitHub Copilot CLI

**What it is:** GitHub's standalone agentic coding CLI. GA February 2026. Invoked as `copilot` or `gh copilot`.

| Aspect | Details |
|--------|---------|
| Claude model support | Yes — Claude Sonnet 4.5 is the default model |
| Non-interactive mode | `-p`, `-s`, `--no-ask-user`, `--allow-tool` |
| File read/write | Yes |
| Bash execution | Yes |
| MCP support | Yes (built-in GitHub MCP + custom servers) |
| Parallel execution | `/fleet` (built-in subtask decomposition) |
| Skills standard | `.github/copilot-instructions.md` — proprietary format |
| Hooks | Not documented |
| Context window | ~192K tokens |
| License | Proprietary (Copilot subscription) |
| Headless/SDK | **Broken** — `--headless --stdio` removed without deprecation; SDK non-functional |

**Assessment:** Copilot CLI is a capable interactive tool, but it deepens the team into Microsoft's ecosystem. It uses a proprietary instructions format, not the portable Agent Skills standard. The headless SDK situation is a dumpster fire — they yanked the programmatic API without a migration path, breaking every integration. Fine for interactive use by individual developers; poor foundation for a structured RE workflow.

### Pi Coding Agent

**What it is:** A minimal, opinionated terminal-based AI coding agent. MIT license. Built by Mario Zechner. ~35.8k GitHub stars, v0.67.2 (April 2026).

| Aspect | Details |
|--------|---------|
| Claude model support | Yes — API key and OAuth (Claude Pro/Max) |
| Non-interactive mode | `--print` (one-shot), `--mode rpc` (subprocess JSONL) |
| File read/write | Yes |
| Bash execution | Yes |
| MCP support | Not native — community adapter exists ([pi-mcp-adapter](https://github.com/nicobailon/pi-mcp-adapter)) |
| Parallel execution | DIY via subprocess spawning; no built-in multi-agent |
| Skills standard | **Agent Skills (SKILL.md) — native support** |
| Hooks | TypeScript extensions system (`~/.pi/agent/extensions/`) |
| Context window | Model-dependent (up to 1M on Opus 4.6) |
| License | MIT |
| CLAUDE.md support | Yes — reads CLAUDE.md natively for project context |

**Assessment:** Pi is the strongest match for the portable skills requirement. It natively supports the open Agent Skills standard (SKILL.md), reads CLAUDE.md files, and its philosophy (dumb orchestrator, disposable agents, transparency over magic) aligns with the lessons learned from prior weekend and evenings work. The lack of native MCP is a gap, but Pi's recommended alternative — CLI tools with README files — is arguably more token-efficient. The RPC mode provides a clean subprocess protocol if/when the team is ready to build automation.

### OpenCode

**What it is:** Open-source AI coding CLI. MIT license. Built by Anomaly Co (Dax Raad / SST). ~144k GitHub stars, v1.4.6 (April 2026). TypeScript/Bun.

| Aspect | Details |
|--------|---------|
| Claude model support | Yes — full provider configuration |
| Non-interactive mode | `opencode run` (one-shot), `opencode serve` (headless HTTP server) |
| File read/write | Yes |
| Bash execution | Yes |
| MCP support | Yes — native, both local (stdio) and remote (HTTP/OAuth) |
| Parallel execution | `/multi` command (limited); in-memory locking prevents clean multi-instance |
| Skills standard | Own format (`.opencode/agents/` with YAML frontmatter) — not SKILL.md |
| Hooks | Not documented |
| Context window | Model-dependent |
| License | MIT |
| WSL support | Official docs, recommended path for Windows |

**Assessment:** OpenCode has the strongest MCP support of the non-Claude-Code options and a mature serve/run architecture. However, it uses its own agent definition format rather than the portable Agent Skills standard. Parallel execution is its weakest area — in-memory locking and known concurrency bugs make multi-instance operation fragile. A solid tool for interactive single-agent work but less suited to structured multi-phase workflows.

### Direct Anthropic API (Custom Build)

**What it is:** Building a custom agentic loop using the Anthropic Messages API directly. The API provides built-in schema-less tools (`bash_20250124`, `text_editor_20250728`) that Claude already knows how to use.

| Aspect | Details |
|--------|---------|
| Claude model support | Yes — it's the API |
| Non-interactive mode | It's all programmatic |
| File read/write | `text_editor_20250728` built-in tool |
| Bash execution | `bash_20250124` built-in tool |
| MCP support | DIY (use `mcp` Python package) |
| Parallel execution | Full control — build whatever you want |
| Skills standard | N/A — you define your own prompt management |
| Hooks | N/A — you build them |
| Context window | Up to 1M on Opus 4.6 |
| License | API costs |
| Custom code required | ~500 lines of Python minimum |

**Assessment:** Maximum control, maximum custom code. This is the "build our own Ogre" path. The raw API gives you everything Claude Code has at the tool level — you just need to build the agentic loop, tool execution, and worker management yourself. This is the right fallback if no existing CLI tool meets requirements, and the right upgrade path when the team is ready to move from human-gated phases to automation.

---

## Capability Comparison

| Capability | Claude Code | Pi | OpenCode | Copilot CLI | Raw API |
|---|---|---|---|---|---|
| CE-like workflow | Native (CE's runtime) | Buildable via skills | Buildable via agents | Buildable via agents | Buildable (custom code) |
| SKILL.md standard | Native | **Native** | Own format | Own format | N/A |
| Hooks | Yes (lifecycle) | Extensions system | Unknown | Unknown | Build your own |
| MCP | Yes (native) | Adapter only | **Yes (native)** | **Yes (native)** | DIY |
| No vendor lock-in | Neutral | **Yes (MIT)** | **Yes (MIT)** | **No (Microsoft)** | Neutral |
| Interactive experience | Excellent | Good (TUI) | Good (TUI + web) | Good (TUI) | N/A |
| Multi-agent spawning | Yes (Agent/Task) | No (deliberate) | Limited (`/multi`) | `/fleet` (built-in) | Build your own |
| Knowledge feedback loop | Via CE plugin | DIY (skill + grep) | DIY (agent + grep) | DIY | Build your own |
| CLAUDE.md support | Native | **Native** | No | No | N/A |

---

## Recommendations

### Primary: Push for Claude Code Access

CE is the workflow the team wants. CE only runs on Claude Code. Claude Code connects to the same Claude models that Copilot uses — Copilot's default model is literally Claude Sonnet 4.5. The company is already paying for Claude model access through Copilot. Claude Code is a more direct path to the same models, not a competing ecosystem.

If Claude Code is approved, the team gets CE out of the box. No porting, no skill translation, no custom code. The entire prior toolchain (blueprints, Proofmark, knowledge base patterns) transfers directly.

### Fallback: Pi

If Claude Code is a no-go, Pi is the strongest option given the constraints:

- **SKILL.md standard** — native support for the portable Agent Skills format
- **CLAUDE.md support** — project instructions port directly from existing work
- **Extensions system** — closest thing to hooks outside Claude Code
- **MIT license** — no vendor lock-in, corporate-friendly
- **Philosophy alignment** — dumb orchestrator, disposable agents, transparency over magic

The team would need to:

1. Port CE's workflow phases as a set of Pi skills (brainstorm, plan, design, build, validate)
2. Build the knowledge feedback loop as a skill that searches `docs/solutions/` (straightforward)
3. Accept no native MCP (use the adapter if needed, or build CLI tools with READMEs — Pi's recommended pattern and arguably more token-efficient)
4. Accept no multi-agent spawning within a phase (each phase runs single-threaded, which is acceptable for a human-gated workflow)

### Copilot CLI's Role

Don't fight the Copilot mandate. Let it be the "official" tool the team uses for general interactive coding — exploring codebases, asking questions, quick edits. But don't build the RE workflow on top of it. It's Microsoft's ecosystem, the programmatic SDK is broken, and it doesn't support the portable skills standard.

### Future Path: Custom Orchestrator

When the team is ready to move from human-gated phases to automation (the "Dan goes to sleep" model), the raw Anthropic API is the upgrade path. The built-in `bash_20250124` and `text_editor_20250728` tools give you everything Claude Code has at the tool level. ~500 lines of Python gets you a custom agentic loop. But this is a Phase 2 conversation — earn it with 5 successful human-gated jobs first.

---

## The Knowledge Feedback Loop — Portable Design

The CE feature worth replicating regardless of tool choice. This is tool-agnostic and can be built on any platform:

```
docs/solutions/
├── re-job-transforms.md          # learnings from transform patterns
├── re-framework-best-practices.md # correct patterns for the target framework
├── re-proofmark-gotchas.md       # validation edge cases
├── re-synthetic-data.md          # synthetic data generation tricks
└── ...
```

Each file uses YAML frontmatter for structured metadata (tags, date, category, job-id) with a markdown body describing the problem, solution, and rationale. Before each spec phase, a skill/agent searches these files by tags relevant to the current job. Learnings from job 1 automatically inform job 50.

This is the "compounding" in Compound Engineering, and it's the real product. Everything else is orchestration.

---

## Scaling Strategy: 5 Jobs → 100 Jobs

### Phase 1: Prove It (5 Jobs)

- Human drives every phase interactively, one job at a time
- Team learns the workflow, builds up `docs/solutions/`, refines skills/blueprints
- Creates synthetic test data, validates against lightweight prod environment
- This works with any tool — even a single developer with a good CLI agent

### Phase 2: Prove Scale (100 Jobs)

- Battle-tested skills and a rich knowledge base from Phase 1
- Workflow is muscle memory; team can parallelize across members
- Multiple team members run different jobs simultaneously
- If the team is ready, this is when a lightweight orchestrator (Ogre-style) gets pitched — but it's been earned with 5 successful jobs first, not assumed from day one

---

## Supporting Research

Full research write-ups for each tool are available in the `Research/` directory:

- `copilot-cli.md` — GitHub Copilot CLI capabilities, scripting, enterprise deployment
- `pi-coding-agent.md` — Pi coding agent capabilities, RPC mode, SKILL.md support
- `opencode.md` — OpenCode capabilities, serve mode, MCP support, parallel limitations
- `direct-api-orchestration.md` — Anthropic API built-in tools, Agent SDK, Aider comparison
- `skills-standard.md` — Agent Skills (SKILL.md) open standard, Claude Code skills system
- `compound-engineering-latest.md` — CE v2.65 workflow, agents, knowledge feedback loop
- `bill-of-materials.md` — Full component inventory for building the RE workflow in Pi
