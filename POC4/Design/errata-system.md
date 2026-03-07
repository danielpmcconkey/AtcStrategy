# Errata System Design — Step 13

**Status:** DRAFT
**Created:** 2026-03-07
**Depends on:** Step 12 (Agent Architecture)
**Feeds into:** Step 15 (Blueprints), Step 16 (Runbook)

---

## Purpose

Execution-time discoveries (edge cases, data quirks, framework behaviors,
Proofmark config adjustments) must propagate to future agents without
blueprint amendments. Blueprints are immutable post-readiness-gate.
The errata system is the mutation channel.

---

## Components

### 1. Raw Errata Log

**Location:** `POC4/Errata/raw-errata-log.md`
**Written by:** Any worker agent during any phase
**Format:** Append-only. Each entry timestamped, attributed, structured.

```markdown
## Entry {N} — {job_name} — {phase} — {date}

**Agent:** {role}-{id}
**Phase:** E.{n}
**Job:** {job_name}
**Effective Date:** {YYYY-MM-DD} (if applicable)
**Category:** {data-quirk | framework-behavior | proofmark-config | edge-case | bug-fix}

**Finding:**
{What was discovered}

**Resolution:**
{What was done about it}

**Applies to:**
{This job only | All jobs with {characteristic} | All jobs}
```

### 2. Curated Errata

**Location:** `POC4/Errata/curated/`
**Written by:** Errata Curator agent
**Triggered:** After each effective date's triage completes (E.6)
**Format:** One summary file, organized by pattern.

```markdown
# Curated Errata Summary — Updated {date}

## Common Patterns

### {Pattern Name}
- **Affects:** {list of jobs or job characteristics}
- **Issue:** {description}
- **Standard resolution:** {what to do}
- **Entries:** {raw log entry numbers}

## Job-Specific Notes

### {job_name}
- {known quirks for this specific job}
- {raw log entry references}
```

### 3. Read Protocol

- **Workers read curated errata** before starting triage on any job (E.6)
- **Workers never read the raw log** — the curator's summaries are the interface
- **The curator reads the raw log** — that's its only job
- **Orchestrator does not read either** — errata is between workers and curator

---

## Dry Run Simplification

For 5 jobs, the curator agent is likely unnecessary. Workers can read the
raw log directly. If the dry run generates enough errata to make the raw log
unwieldy (unlikely with 5 jobs), that's a lesson learned about curator
trigger points.

Minimum viable errata for dry run:
- Raw errata log exists at the defined location
- Workers append entries when they fix something
- Workers read prior entries before starting triage on a new job
- Skip the curator entirely
