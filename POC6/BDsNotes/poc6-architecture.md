# POC6 Architecture Notes — BD

## Core Insight (from POC5 failure)

The GSD executor lost its boundary constraints as context rotted. When it hit blocking
failures, it improvised — fabricating results, copying OG output to fake RE output,
writing plausible-sounding summaries. The system prompt got pushed out by troubleshooting
context. This is a fundamental problem with smart orchestrators.

## POC6 Architecture: Dumb Orchestrator + Atomic Workers

### The Flip

- POC5: 1 waterfall to RE 105 jobs (vertical)
- POC6: 105 waterfalls to RE 1 job each (horizontal)

Each job gets its own full lifecycle pipeline. No job's failure contaminates another.

### Per-Job Pipeline (task types)

Each stage is a discrete task type with its own atomic agent:

1. **Analyst** — Analyze OG job, write FSD, queue review task, die
2. **Reviewer** — Evaluate FSD, queue pass (→ test architect) or fail (→ back to analyst), die
3. **Test Architect** — Write test cases from FSD, queue build task, die
4. **Builder** — Generate config/code, queue validation, die
5. **Validator** — Run proofmark comparison, report pass/fail, die

### The Orchestrator

Pure Python. No LLM. Deterministic loop:

1. Poll Postgres queue for unclaimed tasks
2. Claim one (thread-safe SELECT/UPDATE, same pattern as ETL framework)
3. Shell out to `claude -p` with the right blueprint + tools for that task type
4. Parse JSON response
5. Write results, queue next task
6. Respect parallelism cap (8-12 concurrent subprocesses)

### Agent Invocation (Claude Code CLI)

```bash
claude -p "<task-specific prompt>" \
  --system-prompt "$(cat agent-blueprints/<agent-type>.md)" \
  --dangerously-skip-permissions \
  --model sonnet \
  --max-budget-usd 0.50 \
  --output-format json \
  --allowedTools "Bash Read Grep"
```

Key levers per agent type:
- `--system-prompt` — the blueprint (constraints, routing table, behavior)
- `--allowedTools` — lock agents to only what they need
- `--max-budget-usd` — hard cost cap per invocation
- `--model` — sonnet for grunt work, opus for hard jobs

### Why This Kills the POC5 Problems

| POC5 Problem | POC6 Fix |
|---|---|
| Context rot in orchestrator | No LLM in orchestrator |
| Executor lost boundary constraints | Constraints baked into per-agent blueprints, fresh every invocation |
| One failure cascaded to all jobs | Each job is isolated — own pipeline, own context |
| Agents fabricated results | Write boundary (Hobson's work) + limited toolsets per agent |
| Slow bus problem (waiting for stragglers) | Fungible workers, parallelism cap, no batch dependencies |

### Dan's Vision Doc References

This implements points 5, 6, and 7 from `/workspace/AtcStrategy/POC5/DansNewVision.md`:
- **5 — Parallelism**: 8-12 fungible workers in the air
- **6 — Agent atomicity**: Claim task, do work, queue next step, die
- **7 — Minimize orchestration LLMs**: Deterministic Python loop, no LLM decisions

### Open Questions

- Blueprint format — what goes in each agent's system prompt?
- Queue schema — reuse existing `control.task_queue` or redesign?
- Failure handling — max retries per stage? Circuit breaker per job?
- Cost model — budget per agent type? Per job total?
- Which jobs first? Easiest (Append mode) or hardest (complex transforms)?

### Hobson Context

- Hobson is rebuilding MockEtlFramework in Python → `/workspace/MockEtlFrameworkPython`
- Write boundary for `curated_re/` was planned but not yet implemented
- That boundary is still needed for POC6
