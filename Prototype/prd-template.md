# PRD Template — Reverse Engineering (Chapter 1)

This is a contract, not a form. Every section exists because downstream phases
(plans, code, tests, evidence) need it. If a section doesn't apply to your job,
say so and move on — don't fill it with boilerplate.

The PRD is a behavioral specification. It describes **what** the pipeline does,
never **how** the legacy code does it. No implementation details, no source code
references, no module names, no line numbers. The build team works clean room —
this document is the only input they see.

---

```markdown
# PRD — {Job Name}

**Version:** {semver}
**Date:** {YYYY-MM-DD}
**Job ID:** {ID}
**Status:** {Draft | Under Review | Locked}

---

## 1. Purpose

What does this pipeline produce and why does it exist? One to three paragraphs.
State the business function, not the technical mechanism. Include:

- What the output represents in business terms
- Who or what consumes the output (downstream systems, reports, humans, or "terminal — no known consumers")
- Upstream dependencies (other pipelines that must complete first, or "none — runs independently")
- Execution cadence if known (daily, monthly, event-driven)

---

## 2. Data Flow

A high-level diagram showing inputs, transformations, and outputs. Use a text
diagram (ASCII or Mermaid). Name the logical steps, not the legacy module types.

```
source_a ──┐
source_b ──┤──► [enrich / join / filter] ──► output_1
source_c ──┘                             ──► output_2
```

Keep it to one diagram. If the job has branching outputs, show the fork. If a
source is ingested but never used (dead source), include it with a "(unused)"
annotation — the build team should know it exists in the legacy job so they can
consciously exclude it.

---

## 3. Data Sources

One subsection per source. For each:

### REQ-{NNN} — Source: {schema.table}

| Property     | Value                          |
|--------------|--------------------------------|
| Schema/Table | `{schema}.{table}`             |
| Date mode    | {exact-date, most-recent snapshot, no filter, range} |
| Date column  | `{column}` or N/A              |
| Filters      | {any row-level filters, or "none"} |

**Columns consumed:**
List only the columns that affect the output. If the legacy job fetches columns
it never uses, do not list them here — they are not requirements.

**Role in pipeline:** One sentence on what this source contributes (e.g.,
"lookup table for resolving card_id to card_type," "fact table of daily
transactions").

For dead sources (fetched but never consumed by the legacy job):

### REQ-{NNN} — Source: {schema.table} (DEAD SOURCE)

State that this source exists in the legacy job but has no effect on output.
The build team should NOT include it.

---

## 4. Transformation Rules

One subsection per logical transformation. Describe the **behavior**, not the
implementation. Focus on:

- What data goes in
- What computation happens (joins, aggregations, filters, lookups, derivations)
- What data comes out
- Edge cases and boundary conditions

### REQ-{NNN} — {Descriptive Name}

Write the rule in plain language. Use tables for column mappings. Use formulae
or pseudocode only when plain language would be ambiguous (e.g., rounding rules,
tie-breaking logic). Never reference legacy code, variable names, or module
types.

**Good:** "Resolve each transaction's card type by matching card_id against the
cards reference data. Transactions with no matching card default to 'Unknown'."

**Bad:** "The External module builds a dict via iterrows() and does
card_type_lookup.get(card_id, 'Unknown')."

For boundary conditions, be explicit:

- What happens on empty input?
- What happens on null/missing join keys?
- What happens on duplicate keys in reference data?
- Date boundaries (end of month, year rollover, leap years)

---

## 5. Output Specification

One subsection per output file/table. For each:

### REQ-{NNN} — Output: {file or table name}

| Property        | Value                                    |
|-----------------|------------------------------------------|
| Format          | {CSV, Parquet, Delta, etc.}              |
| Write mode      | {Overwrite, Append, Merge}               |
| Partitioning    | {partition scheme, or "none"}            |
| Path pattern    | `{path with placeholders}`               |

**Schema:**

| # | Column             | Type           | Description / derivation         |
|---|--------------------|----------------|----------------------------------|
| 1 | `column_name`      | string/int/etc | Where it comes from, what it means |

**Formatting rules:** encoding, line endings, quoting, date formats, decimal
precision, header presence, trailer format — whatever the output contract
requires.

**Row ordering:** Specify if deterministic, or state "non-deterministic" if
order is not guaranteed.

**Row counts:** Expected row profile per run (e.g., "one row per card type per
day, plus a summary row on month-end").

---

## 6. Correctness Flags

Legacy behavior that is suspected to be wrong, misleading, or worth a conscious
decision. Each flag requires a resolution before the PRD locks.

### CF-{NNN} — {Short Description}

**Observed behavior:** What the legacy job does.

**Concern:** Why this might be wrong or misleading.

**Resolution (required before lock):**
- [ ] **Reproduce** — build matches legacy behavior as-is
- [ ] **Remediate** — build deviates from legacy, with justification: {state it}

Correctness flags are not anti-patterns. Anti-patterns describe *how* legacy
code is built (implementation concern — excluded from the PRD). Correctness
flags describe *what* the legacy job produces that might be wrong (behavioral
concern — included in the PRD because the build team needs to know).

---

## 7. Assumptions

| # | Assumption | Basis |
|---|------------|-------|
| A-{NN} | {What you're assuming} | {Why you believe it — observed data, documentation, SME input} |

Things worth calling out: data immutability, referential integrity, date
semantics, null handling conventions, expected value domains, cadence.

---

## 8. Requirements Traceability Matrix

Every requirement from sections 3-5 gets a row. Build-side columns
(`rebuild_anchor`, `test_case`, `status`) are populated during later phases —
leave them empty at PRD lock.

| Req ID   | Description                                    | Rebuild Anchor | Test Case | Status |
|----------|------------------------------------------------|----------------|-----------|--------|
| REQ-001  | {from section 3, 4, or 5}                      |                |           |        |
| REQ-002  | ...                                            |                |           |        |
| CF-001   | {correctness flag, with resolution}            |                |           |        |
```

---

## Contract Checklist (for human review before lock)

Before locking the PRD, the reviewer hunts for:

- [ ] **Holes.** Inputs without schemas. Outputs without consumers. Logic described
  as "transform the data" with no specifics.
- [ ] **Implicit assumptions.** Time zones, null handling, dedup rules,
  late-arriving data, schema evolution — if the PRD doesn't say it, the build
  agent will guess.
- [ ] **Unresolved correctness flags.** Every CF must have a checked resolution
  (reproduce or remediate) before lock.
- [ ] **Clean room violations.** Any mention of legacy code structure, module
  types, variable names, file paths, or line numbers. If you find one, the PRD
  is contaminated — fix it before locking.
- [ ] **RTM coverage.** Every behavioral requirement has a row.

The PRD locks when the reviewer has read it end to end and has nothing to kick
back.
