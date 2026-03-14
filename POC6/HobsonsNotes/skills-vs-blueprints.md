# Skills vs Blueprints — When to Use Which

**Date:** 2026-03-13
**Author:** Hobson
**Context:** Dan asked me to evaluate Claude Skills 2.0 against his existing
blueprint pattern for assembling the RE agent team.

---

## Source

Analysis based on: https://github.com/mbriggsy/ai-learning-journey/blob/main/research/claude%20skills%202.0/Claude_Skills_2.0_User_Guide.md

The guide is technically sound. Frontmatter fields, directory layout, progressive
disclosure mechanics, `context: fork`, `$ARGUMENTS` substitutions, `!` backtick
preprocessing — all verified against known Claude Code behaviour. It's a good
reference doc, not battle-tested field notes.

---

## What Skills Are

Skills are folders containing a `SKILL.md` with YAML frontmatter, plus optional
scripts, references, and assets. They live in `.claude/skills/` (project) or
`~/.claude/skills/` (personal). The skill name becomes a `/slash-command`.

The key feature is **progressive disclosure** — a three-tier loading system:

| Tier | What loads | When | Size |
|------|-----------|------|------|
| Metadata | Name + description only | Always in context | ~100 words |
| Instructions | Full SKILL.md body | When skill triggers | < 500 lines |
| Resources | Scripts, references, assets | On demand | Unlimited |

This protects the context window. An agent with 10 available skills only carries
~1,000 words of metadata until it actually needs a specific skill's instructions.

Other notable features:
- `context: fork` — runs skill in an isolated subagent (Explore, Plan, general-purpose, or custom)
- `allowed-tools` — auto-approve specific tools when skill is active
- `disable-model-invocation: true` — hides skill from Claude's awareness entirely
- `!` backtick preprocessing — executes shell commands before skill content reaches Claude
- `$ARGUMENTS`, `$0`, `$1` — parameterised invocation

---

## Why They Don't Fit POC6's RE Team

The RE team agents are **short-lived, narrowly scoped workers** fired from a
deterministic workflow engine / state machine. Each agent:

1. Wakes up
2. Reads one blueprint file
3. Does one specific task (e.g. "review job 17's BRD")
4. Returns its result
5. Dies

There is no context to protect because the agent never lives long enough to
accumulate any. Progressive disclosure solves a problem these agents don't have.

Skills solve **discovery** ("which of my capabilities should I use?") and
**context management** ("how do I avoid stuffing everything into the window at
once?"). The RE agents need neither — the orchestrator *tells* them exactly what
to do, and they're gone before context pressure matters.

The blueprint pattern — `"go read BrdReviewerBlueprint.md and review job 17's
BRD"` — is already the right abstraction for this architecture.

---

## When Skills Would Matter

If POC6 succeeds and the orchestrator evolves from a dumb state machine to an
**LLM-based orchestrator** — a longer-lived supervisory agent that:

- Sits above the pipeline
- Reviews results across multiple jobs
- Decides when to retry or escalate
- Spots patterns in failures
- Manages its own context over an extended session

...then skills become relevant. That agent would live long enough for context
pressure to be real, and would benefit from discovering capabilities on demand
rather than having everything front-loaded.

**In short:** blueprints for workers, skills for supervisors.

---

## Reference: Skill Directory Layout

```
.claude/skills/
├── reverse-engineer-job/
│   ├── SKILL.md              # Core RE workflow, rules, guardrails
│   └── references/
│       ├── proofmark-guide.md
│       └── edge-cases.md
├── run-proofmark/            # /run-proofmark <job-name>
│   └── SKILL.md
├── validate-equivalence/     # Output comparison checklist
│   └── SKILL.md
```

This is what it *could* look like if/when a supervisory agent needs it. Parked
here for future reference.
