# BD Resurrection State — POC5 Session 1

**Date:** 2026-03-08 (updated 2026-03-09, end of session 2)
**Status:** First job RE'd and verified. New repo created. GSD integration next.

---

## What POC5 Is

Reverse engineer 105 ETL jobs. For each job, produce:
1. BRD (numbered requirements with evidence)
2. FSD (numbered specs, traceable to BRDs)
3. Test strategy (traceable to FSDs/BRDs)
4. New JSON job conf (`_re` suffix, lives alongside originals)
5. New external modules (ONLY if standard modules can't match output)
6. Output manifesto (every output in the system)
7. Proofmark config YAML per output (evidence for any non-strict columns)
8. Proofmark test evidence (100% match, all 92 dates Oct 1 - Dec 31 2024)

**Goal:** Zero human input after planning session with Dan.

## Architecture

- **Horizontal processing:** One job fully through the pipeline before touching the next
- **Queue-driven:** Agents in Docker, services (ETL FW + Proofmark) on host, Postgres is the integration bus
- **Network isolation:** Agents can't modify ETL FW code, V1 job confs, or output files. Read-only access to those. Write access to RE output dir.
- **GSD + Compound Engineering:** Briggsy's bet. POC5 is testing whether these tools solve the orchestration problems that killed POC3 (context rot) and POC4 (over-constrained orchestrator)

## Key Paths

| What | Path |
|------|------|
| All 105 job confs | `/workspace/MockEtlFramework/JobExecutor/Jobs/*.json` |
| External modules | `/workspace/MockEtlFramework/ExternalModules/*.cs` |
| Original output | `/workspace/MockEtlFramework/Output/curated/{jobDirName}/{outputTableDirName}/{date}/{fileName}` |
| RE output dir | `$ETL_RE_OUTPUT` = `/workspace/MockEtlFramework/Output/curated_re` (doesn't exist yet) |
| RE repo | `/workspace/EtlReverseEngineering/` (github.com/danielpmcconkey/EtlReverseEngineering) |
| Anti-patterns | `/workspace/AtcStrategy/POC5/anti-patterns.md` |
| Job manifest | `/workspace/AtcStrategy/POC5/hobson-notes/job-scope-manifest.json` |
| Proofmark docs | `/workspace/proofmark/Documentation/` |

## Database

- Host: `172.18.0.1:5432`, DB: `atc`, User/Pass: `claude/claude`
- Must use `PGPASSWORD=claude` prefix (no .pgpass set up)
- Key tables: `control.jobs`, `control.job_dependencies`, `control.task_queue`, `control.proofmark_test_queue`

## Job Conf Structure

Three-layer pipeline defined in JSON:
1. **DataSourcing** — pulls from datalake tables. Auto-includes `ifw_effective_date`. 5 date modes: static, lookbackDays, mostRecentPrior, mostRecent, fallback (uses __etlEffectiveDate).
2. **Transformation** — SQL against DataSourcing results (in-memory, not Postgres)
3. **Writers** — CsvFileWriter or ParquetFileWriter. Auto-adds `etl_effective_date` column. Can also have External (C# module) before writers.

## External Module Pattern

- Implements `IExternalStep` interface
- `Execute(Dictionary<string, object> sharedState) -> Dictionary<string, object>`
- Reads DataFrames from sharedState, processes, writes output DataFrame back to sharedState
- Assembly: `{ETL_ROOT}/ExternalModules/bin/Debug/net8.0/ExternalModules.dll`

## Dependency Graph (only 5 dependencies!)

- Job 5 (DailyTransactionVolume) → depends on Job 2 (DailyTransactionSummary)
- Job 6 (MonthlyTransactionTrend) → depends on Job 5
- Job 24 (BranchVisitSummary) → depends on Job 22 (BranchDirectory)
- Job 25 (BranchVisitPurposeBreakdown) → depends on Job 22
- Job 26 (TopBranches) → depends on Job 24

100 of 105 jobs have ZERO dependencies.

## Output Stats

- 61 CSV writers, 40 Parquet writers
- 80 Overwrite mode, 23 Append mode
- Only DansTransactionSpecial (job 373) has multiple outputs (2 CSV files)
- 38 jobs have NO external module (simplest candidates)
- `_v4` files in Jobs/ are dead artifacts from prior POCs — not registered in DB

## Proofmark Config Format

```yaml
comparison_target: job_name
reader: csv  # or parquet
csv:
  header_rows: 1
  trailer_rows: 0
columns:
  excluded:
    - name: col_name
      reason: "why"
  fuzzy:
    - name: col_name
      tolerance: 0.01
      tolerance_type: absolute  # or relative
      reason: "why"
```

Path tokens: `{ETL_ROOT}` (original output), `{ETL_RE_OUTPUT}` (RE output). Proofmark resolves on host side.

## Anti-Patterns to Catch

AP1: Dead-end sourcing (unused tables/data)
AP2: Duplicated logic across jobs
AP3: Unnecessary external modules
AP4: Unused columns
AP5: Asymmetric null/default handling
AP6: Row-by-row iteration (foreach instead of SQL)
AP7: Magic values (hardcoded thresholds)
AP8: Complex/dead SQL (unused CTEs, window functions)
AP9: Misleading names
AP10: Over-sourcing date ranges

## Critical: Append vs Overwrite Mode

**Append mode accumulates across dates.** When a job uses writeMode: Append:
- Oct 1 output: header + 1 day of rows
- Oct 15 output: header + 15 days of rows (all previous dates accumulated)
- Dec 31 output: header + 92 days of rows

This means Append jobs MUST be run in chronological order. 23 of 105 jobs use Append mode.
Overwrite jobs are independent per date — order doesn't matter.

## First Job Candidate

**SecuritiesDirectory (job_id 110)** — recommended first target:
- No dependencies
- No external module
- **Overwrite mode** (no accumulation complexity)
- Trivial SQL: `SELECT s.security_id, s.ticker, s.security_name, s.security_type, s.sector, s.exchange, s.ifw_effective_date FROM securities s ORDER BY s.security_id`
- Sources `holdings` table but never uses it → clear AP1 violation
- Single CSV output, 50 rows per date, stable across all dates (reference table)
- CSV with header, LF line endings
- 92 dates present with verified output

**Why not MerchantCategoryDirectory?** Originally considered, but it uses Append mode. Save that for after we've proven the pipeline with simpler Overwrite mechanics.

## Blockers

1. **`{ETL_RE_ROOT}` env var not wired up** — Dan needs to fix docker-compose. Can't register RE jobs in control.jobs or run them through ETL FW until this is done.
2. **RE output dir doesn't exist** — need to `mkdir -p $ETL_RE_OUTPUT` when ready

## Key Recon Files

- `/workspace/AtcStrategy/POC5/job-complexity-analysis.md` — full complexity tier breakdown, recommended processing order
- `/workspace/AtcStrategy/POC5/session-wakeups/bd-resurrection-state.md` — this file

## Trailer Format Findings

25 jobs have trailers. Three patterns:
- `TRAILER|{row_count}|{date}` — most common (deterministic)
- `END|{row_count}` — 3 jobs (deterministic)
- `CONTROL|{date}|{row_count}|{timestamp}` or `SUMMARY|...|{timestamp}` — 4 jobs (NON-DETERMINISTIC)

ALL Proofmark configs for jobs with trailers need `trailer_rows: 1`.
Jobs with `{timestamp}` trailers: CreditScoreAverage, DailyTransactionVolume, TopBranches, ExecutiveDashboard.

## Append Mode Deep Dive

CsvFileWriter Append behavior (from source code):
1. Finds latest existing date partition via `DatePartitionHelper.FindLatestPartition`
2. Reads that prior file, strips trailer if present
3. Parses into DataFrame, drops `etl_effective_date` column
4. Unions prior data with current data
5. Re-stamps ALL rows with current `etl_effective_date`
6. Writes to new date partition directory

**Implications:** RE Append jobs MUST run dates in order. Each output snapshot is cumulative.

## Session 2 Outcomes (2026-03-09)

### SecuritiesDirectory RE'd — 92/92 PASS
- First job through the full pipeline. AP1 remediation (removed dead `holdings` source).
- Byte-identical output confirmed via Proofmark strict comparison across all 92 dates.

### New Repo: EtlReverseEngineering
- Public repo: `github.com/danielpmcconkey/EtlReverseEngineering`
- Local: `/workspace/EtlReverseEngineering/`
- Contains: RE job confs, per-job docs (BRD/FSD/test), proofmark configs
- GSD `.planning/` will live here
- RE output stays at `{ETL_RE_OUTPUT}` (inside MockEtlFramework/Output/curated_re/)

### Infrastructure Issues Found & Fixed
1. **ETL FW caches job registry at startup** — new jobs not visible until restart. Hobson working on lazy reload fix.
2. **`{ETL_RE_ROOT}` token wasn't registered in PathHelper** — Dan rebuilt, fixed.
3. **`outputDirectory` in RE confs must use `{ETL_RE_OUTPUT}` token** — relative paths resolve against ETL_ROOT (Hobson's copy). Blueprint updated.
4. **Postgres date casting** — `d.dt::text` renders with timezone. Use `to_char(d.dt, 'YYYY-MM-DD')`.
5. **CSV Proofmark paths need the filename**, not just the directory. Parquet expects directory (untested).

### Decisions Made
1. Proofmark configs: `EtlReverseEngineering/proofmark-configs/{JobName}.yaml`
2. Per-job docs: `EtlReverseEngineering/jobs/{JobName}/`
3. Strategy docs stay in AtcStrategy (blueprint, anti-patterns, session wakeups)
4. **GSD + CE mandatory going forward** — Dan wants to prove whether they help or hinder at scale
5. Append mode Proofmark — already battle-tested from Dan's manual tests. Park until Tier 3.

### Tooling — MANDATORY, NON-OPTIONAL

All five MCP tools are to be used on every session. This is Dan's explicit decision — we use them and evaluate post hoc, not pre-screen and skip. "I can already do that without the tool" is not a reason to skip the tool.

| Tool | Status | Primary Use in POC5 |
|------|--------|-------------------|
| **Serena** | Working (config fixed session 3) | Semantic C# navigation, especially Tier 4 external modules |
| **Context7** | Working | Library doc lookup if we hit framework questions |
| **Sequential Thinking** | Working | Structured reasoning on complex RE decisions |
| **GSD** | Init pending | Pipeline orchestration, planning, execution tracking |
| **Compound Engineering** | Via GSD | Quality assurance, code review, specialized analysis |

**Config notes for future sessions:**
- Serena project.yml must use `language: csharp` (singular), NOT `languages:` (plural list)
- Serena global config (`serena_config.docker.yml`) registers projects as flat path strings under `projects:`
- Full recon: `/workspace/AtcStrategy/POC5/tooling-recon.md`

## Session 3 Outcomes (2026-03-09)

### Tooling Recon Complete
- All 5 MCP tools tested (or confirmed available). See `/workspace/AtcStrategy/POC5/tooling-recon.md`.
- Serena required config fixes to activate. Now working with MockEtlFramework indexed.
- Hobson says lazy reload fix is in. Untested — will verify on first Tier 1 job registration.

### SecuritiesDirectory Reset
- All RE artifacts wiped (job conf, BRD/FSD/test docs, proofmark config, output dir, 463 DB rows).
- Dan's decision: GSD agent starts all 105 jobs from scratch. No inherited bias from BD's prior work.

### GSD New-Project In Progress
- `PROJECT.md` drafted and Dan-approved at `/workspace/EtlReverseEngineering/.planning/PROJECT.md`
- "Prime Directive" section added — anti-pattern remediation front and center, AP3 (external module minimization) is the headline
- External modules require cited evidence in FSD if used
- GSD init not yet committed. Still need: questioning gate approval → config → research decision → requirements → roadmap
- Methodology documented at `/workspace/AtcStrategy/POC5/gsd-onboarding-methodology.md`

### Context Management Learning
- GSD skill loads are expensive (~30-40% of context per slash command)
- Plan one major GSD command per session
- `/clear` between GSD steps if above 50%

## Open Questions

1. Resume GSD new-project from questioning gate. PROJECT.md exists, needs Dan's formal approval through the flow.
2. Research phase — probably skip for RE project (we're analyzing code, not a domain). Dan decides.
3. Phase granularity — coarse (one phase per tier) vs fine (one per job)? Big GSD config decision.
4. Hobson's lazy reload — still untested. Verify on first job registration.

## External Module Complexity

73 external modules, 6702 total lines. Range: 40-239 lines per file.
- Shortest (CreditScoreProcessor, 40 lines): pure pass-through, textbook AP3+AP6. Could be a single SQL SELECT.
- Longest (CoveredTransactionProcessor, 239 lines): does its own data sourcing (0 DataSourcing modules in job conf).
- Most modules are 60-125 lines. Many will likely be eliminable via SQL Transformation.

Key insight: The RE agent's primary value-add on Tier 4 jobs is recognizing which external modules are unnecessary (AP3) and converting row-by-row iteration (AP6) to set-based SQL operations.

## People

- **Dan:** My human. Running this POC.
- **Hobson:** Claude Code instance on Dan's host OS. Built the infrastructure, wrote the briefing docs.
- **Briggsy:** Dan's boss. Advocating GSD + Compound Engineering as the solution. Thinks custom agent role definitions are wasted effort.
