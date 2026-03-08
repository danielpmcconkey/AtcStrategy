# POC5 Tooling Plan — How Each Tool Fits

Status: DRAFT — evolving as design solidifies.

---

## Host-Side Services

### MockEtlFramework (ETL FW)
**Role:** Runs V1 and V4 ETL jobs. Agents never touch this directly.
**How:** Long-running `JobExecutor --service` process on host. Polls `control.task_queue`. Agents in Docker insert tasks into the queue via Postgres. ETL FW runs the job, writes output to a host-side directory that's read-only mounted into Docker.
**Network isolation:** Agents cannot modify framework code, V1 job confs, or output files. They can only enqueue work and read results.

### Proofmark
**Role:** Compares V1 vs V4 output files. Agents never touch this directly.
**How:** Long-running `proofmark serve` process on host. Polls its queue table (e.g. `control.proofmark_queue`). Agents insert comparison tasks via Postgres. Proofmark reads output files (host-side), writes results back to Postgres as JSONB. Agents read results from the queue table.
**Network isolation:** Same principle — agents enqueue, Proofmark executes, agents read results.

---

## Basement-Side (Docker) Tooling

### GSD (Get Shit Done)
**Role:** Orchestration framework. Agent spawning engine.
**How:** GSD manages the lifecycle of reverse-engineering work. Its core value: fresh 200K context per subagent (no context rot). The orchestrator is deliberately starved — it passes file paths, not contents.
**POC5 fit:** GSD's spec → roadmap → plan → execute → verify pipeline maps to the horizontal job processing model. Each ETL job becomes a "project" that flows through GSD's pipeline. GSD spawns fresh subagents for each stage (BRD analysis, FSD design, FSD review, code build, validation). The orchestrator's job is pure coordination: read the task queue, see what needs doing, spawn the right agent type.
**Open question:** How does GSD's built-in pipeline map to our specific agent roles (analyst, FSD architect, reviewer, etc.)? May need customization of GSD's agent definitions.

### Serena
**Role:** Semantic code navigation for V1 code analysis.
**How:** MCP server using Roslyn (C# LSP). Gives agents symbol-level understanding of the MockEtlFramework codebase — function signatures, type hierarchies, cross-file references.
**POC5 fit:** Critical for the analyst/BRD phase. Instead of agents grep-searching V1 code, they get semantic navigation: "find all references to this method," "show me the type signature of this class," "what calls this function?" Makes requirement inference far more reliable.
**Note:** Roslyn startup is 30-60s and memory-hungry. One instance shared across agents, not one per agent.

### Context7
**Role:** Live library documentation lookup.
**How:** MCP server that fetches current docs for .NET libraries, EF Core, xUnit, etc.
**POC5 fit:** Useful during the code build phase so agents don't hallucinate .NET APIs. Coverage for .NET is mediocre but free. Low-effort install, zero-friction value.

### Compound Engineering (cherry-picked)
**Role:** Knowledge feedback loop + specialized review agents.
**How:** Plugin providing:
- **compound-docs** skill: Captures solved problems as searchable YAML. This IS the errata system — when an agent fixes a triage issue, compound-docs captures the lesson.
- **learnings-researcher** agent: Searches captured knowledge before planning/review. Agents learn from prior jobs' mistakes.
- **architecture-strategist** / **code-simplicity-reviewer** / **security-sentinel**: Specialized review agents for independent FSD and code review.
**POC5 fit:** The knowledge feedback loop directly addresses POC4's "no inter-phase learning" problem. When Job #47's triage reveals a pattern, Job #48's analyst agent already knows about it.
**Open question:** How to adapt the Rails-centric defaults to C#/.NET domain.

### Sequential Thinking
**Verdict:** Skip. 217 lines of TypeScript counter. Claude's native extended thinking already does this.

### Visual Explainer
**Role:** Nice-to-have. Converts diagrams to interactive HTML for Dan's review.
**POC5 fit:** Low priority. Install if easy, ignore if not.

### GitHub MCP
**Role:** GitHub integration from CLI.
**POC5 fit:** Convenience only. Dan already uses `gh`. Install if the token is already set up.

---

## The Queue-Driven Architecture

```
Docker (agents)                    Host (services)
─────────────────                  ─────────────────
Agent claims task from
  Postgres task queue
      │
      ▼
Agent does its work
  (BRD/FSD/code/etc.)
      │
      ▼
Agent inserts ETL run
  request into
  control.task_queue        ──►    ETL FW picks up task
                                     runs job
                                     writes output to
                                     host-side dir
      │
      ▼
Agent inserts Proofmark
  comparison task into
  comparison_queue          ──►    Proofmark picks up task
                                     reads output files
                                     writes result to Postgres
      │
      ▼
Agent reads Proofmark
  result from Postgres
Agent reads output files
  (read-only mount)
      │
      ▼
Agent writes report,
  updates task status,
  enqueues next stage
```

**Postgres is the integration bus.** Agents and host services communicate exclusively through database tables. No filesystem writes cross the Docker boundary (agents read host output via read-only mount, but never write to it).
