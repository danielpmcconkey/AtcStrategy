# Tooling Recon — Session 3

**Date:** 2026-03-09
**Purpose:** Evaluate MCP tools before committing to them for the full 105-job RE pipeline.

---

## Serena (Semantic Code Navigation)

**Status:** Working after config fix.
**Config issues found:**
1. `project.yml` had `languages:` (plural, list) — code expects `language:` (singular, string). Fixed.
2. `serena_config.docker.yml` had `projects: []` — MockEtlFramework was never registered. Fixed by adding path.

**What it does:** Symbol-level navigation of C# codebase via Roslyn LSP backend. Can query class structures, find symbol references, read specific method bodies without loading whole files.

**Test:** `find_symbol("CsvFileWriter", depth=1)` returned full class structure (9 fields, 3 methods) in one call. `get_symbols_overview("ExternalModules/CreditScoreProcessor.cs")` returned the class immediately.

**Where it helps:** Tier 4 jobs with external modules. Instead of grepping through C# files, we can navigate semantically — "show me what CoveredTransactionProcessor.Execute does" or "find everything that references IExternalStep". Less critical for Tier 1 (no external modules) but still useful for verifying framework behavior.

## Context7 (Library Documentation)

**Status:** Working.

**What it does:** Resolves library names to doc IDs, then queries up-to-date documentation and code examples.

**Test:** Resolved "Npgsql" to Context7 library IDs with descriptions and quality scores.

**Where it helps:** Marginal for POC5. We're RE'ing existing jobs, not learning new frameworks. Could be useful if we hit weird .NET behavior or need to verify Postgres driver semantics. Low cost to have available.

## Sequential Thinking (Structured Reasoning)

**Status:** Working.

**What it does:** Explicit step-by-step reasoning with branching, revision, and hypothesis verification.

**Test:** Fed it a real question about Tier 1 processing order. Accepted and processed cleanly.

**Where it helps:** Complex external module RE where multiple interpretations are possible. Forces disciplined reasoning instead of winging it. On simple jobs, probably overhead. On hard jobs (Tier 4, multi-step transformations), the branching/revision structure could prevent wrong turns.

## GSD (Get Shit Done)

**Status:** Not yet tested. `/gsd:new-project` is next.

**What it does:** Meta-prompting system with spec-driven development. Manages planning, execution, verification through structured phases. Slash commands for everything.

**Where it helps:** The entire pipeline orchestration. Planning the RE batch, tracking progress, ensuring nothing falls through the cracks across 105 jobs. This is the primary bet.

## Compound Engineering

**Status:** Not yet tested. Will be exercised through GSD workflows.

**What it does:** 29 specialized agents — code reviewers, researchers, architecture analysts, etc. Knowledge feedback loop.

**Where it helps:** Quality assurance on RE output. Can review job confs, catch anti-patterns, verify traceability between BRD/FSD/test artifacts.

---

## Verdict

Nothing here will actively harm the process. All tools are non-optional per Dan's decision — we use them and evaluate post hoc whether they helped. Serena is the most immediately useful (real semantic C# navigation). GSD/CE are the primary bet. Context7 and Sequential Thinking are low-cost additions.
