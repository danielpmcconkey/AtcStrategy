# Orchestrator Blueprint — E.1: Infer Business Requirements

**Scope:** Produce a BRD and output manifest for every job in the scope manifest. Stop when all BRDs have passed independent review.

---

## Inputs

- Job scope manifest: `Governance/ScopeManifest/job-scope-manifest.json`
- Anti-pattern list: `Governance/anti-patterns.md`
- MockEtlFramework repo with all V1 job configs and source code
- PostgreSQL database with datalake schema populated

## Your Team

- **Analysts** — spawn as worker subagents, assign batches of jobs
- **Reviewers** — spawn as independent subagents, cannot be the same agent that wrote the artifact

## Concurrency Target

**Keep 8-12 subagents in flight at all times.** When one finishes, immediately
launch the next. Do not wait for a full batch to complete before starting the
next batch. The goal is maximum throughput — idle slots are waste.

## Progress Reporting

Maintain a structured progress file at `POC4/Artifacts/e1-progress.md` that BD
can poll. Update it every time a job completes a stage. Format:

```markdown
# E.1 Progress

| Job | Analyst | BRD | Manifest | Review | Status |
|-----|---------|-----|----------|--------|--------|
| {name} | done/in-progress/pending | done/pending | done/pending | pass/fail/pending | {overall} |
```

## Execution

1. Populate the task queue to run all V1 jobs for ETL effective dates Oct 1-7, 2024.
   **Append-mode jobs must be queued with execution_mode = 'serial'** to prevent
   cross-date output contamination. All other jobs use 'parallel'.
   Then start the queue service (`dotnet run --project JobExecutor -- --service`).
   Wait for all tasks to succeed before proceeding.
2. Assign jobs to analyst workers — launch as many as possible in parallel (up to
   concurrency target)
3. Each analyst, for each assigned job:
   - Read the V1 job config JSON
   - Read V1 External module source code (if applicable)
   - Read V1 SQL transformations
   - Read framework code as needed to understand module behavior
   - Examine V1 output files to determine exact output schema
   - Write BRD at `POC4/Artifacts/{job_name}/brd.md` including:
     - Overview (what the job produces and why)
     - Source tables with join/filter logic and evidence
     - Business rules (numbered, each with confidence + evidence citation)
     - Output schema (every column, source, transformations)
     - Anti-patterns identified (citing AP codes from `Governance/anti-patterns.md`)
     - Edge cases
     - Traceability matrix
   - Write output manifest at `POC4/Artifacts/{job_name}/output-manifest.md`:
     - Every output file the job creates
     - Schema per output file (column name, type, source)
4. As each BRD completes, immediately spawn an independent reviewer (don't wait
   for all BRDs to finish first):
   - **Review pass 1 — Output accuracy:** Does the output manifest match actual V1 output?
   - **Review pass 2 — Requirement accuracy:** Is every requirement supported by evidence in V1 code or data?
5. If reviewer rejects, send feedback to a fresh analyst worker for revision. Max 3 cycles.
6. Update progress file after each job completes any stage
7. Update `POC4/session-state.md` at batch boundaries
8. Check for `POC4/CLUTCH` at batch boundaries

## Outputs

For each job in scope:
- `POC4/Artifacts/{job_name}/brd.md`
- `POC4/Artifacts/{job_name}/output-manifest.md`
- `POC4/Artifacts/{job_name}/brd-review.md`

Global:
- `POC4/Artifacts/e1-progress.md`

## Stop Condition

**Stop and report to BD when:** All BRDs have passed independent review and all output manifests are written. Do not proceed to any other phase. Your job is done.
