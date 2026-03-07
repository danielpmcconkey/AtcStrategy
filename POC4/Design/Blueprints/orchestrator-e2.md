# Orchestrator Blueprint — E.2: Functional Specs and Test Strategy

**Scope:** Produce an FSD and test strategy for every job in the scope manifest. Stop when all FSDs and test documents have passed independent review.

---

## Inputs

- Completed BRDs and output manifests from E.1: `POC4/Artifacts/{job_name}/brd.md`, `output-manifest.md`
- Anti-pattern list: `Governance/anti-patterns.md`
- V1 source code and job configs (for reference)

## Your Team

- **Architects** — spawn as worker subagents, assign batches of jobs
- **Reviewers** — spawn as independent subagents

## Execution

1. Assign jobs to architect workers in batches
2. Each architect, for each assigned job:
   - Read the BRD and output manifest
   - Read V1 source code for reference
   - Write FSD at `POC4/Artifacts/{job_name}/fsd.md` including:
     - Functional requirements traced to BRD requirements
     - Anti-patterns identified in V1 code (citing AP codes)
     - How the V4 design avoids each anti-pattern, with evidence that the alternative achieves the same output fidelity
     - All output DataFrames defined to explicitly match the output schema from the BRD
     - Module chain design (DataSourcing → Transformation → Writer preferred; External only with justification)
   - Write test strategy at `POC4/Artifacts/{job_name}/test-strategy.md` including:
     - Test cases traced to BRD requirements
     - Any additional anti-patterns discovered during test design
     - Edge case coverage
3. For each completed FSD, spawn an independent reviewer:
   - All BRD requirements accounted for
   - All functional requirements citing evidence in BRD, V1 code, or data
   - All output DataFrames match BRD output schema
   - Anti-pattern avoidance specs are sound
4. For each completed test document, spawn an independent reviewer:
   - All BRD requirements have corresponding test cases
   - All test cases citing evidence in BRD, V1 code, or data
5. If reviewer rejects, send feedback to a fresh architect worker for revision. Max 3 cycles.
6. Update `POC4/session-state.md` at batch boundaries
7. Check for `POC4/CLUTCH` at batch boundaries

## Outputs

For each job in scope:
- `POC4/Artifacts/{job_name}/fsd.md`
- `POC4/Artifacts/{job_name}/test-strategy.md`
- `POC4/Artifacts/{job_name}/fsd-review.md`
- `POC4/Artifacts/{job_name}/test-review.md`

## Stop Condition

**Stop and report to BD when:** All FSDs and test documents have passed independent review. Do not proceed to any other phase. Your job is done.
