# Phase V — Execution Phase Definitions

**Status:** DRAFT — Pending Dan approval
**Created:** 2026-03-06
**Step 11 output:** Defines the structure of POC4 execution.
**Source:** Dan's execution design (`Execution/temp_dans_PhaseV_execution_details_suggestion.md`)

---

## Operating Model

**BD is not the orchestrator.** Dan instructs BD. BD launches the orchestrator as a
background process. The orchestrator starts and stops agents, assigns work, and ensures
the agent team completes its phase. When the orchestrator is done, it reports back to BD.
BD validates that required outputs exist and reports to Dan.

**Every phase boundary follows the same ritual:**
1. Orchestrator stops and reports completion to BD
2. BD validates existence of all required outputs and reports to Dan
3. Dan manually approves
4. Dan checks token usage
5. Dan recycles BD (fresh session, clean context)

---

## E.1 — Infer Business Requirements

**Configuration:** Agent teams. BD launches orchestrator in background.

**The orchestrator ensures the agent team does the following:**
1. Start the MockEtlFramework long-running processes (if not already running)
2. Run all V1 jobs for ETL effective dates Oct 1-7, 2024
3. Review all V1 code
4. Write all BRDs:
   - All output schemas strictly defined based on actual V1 output files
   - All anti-patterns found in V1 code cited in the BRD
5. Independent review of all BRDs for output accuracy — each BRD must produce a
   definitive list of every output file the job creates, with schema. This is the
   **output manifest** for that job. The output manifest seeds the evidence ledger
   and defines what E.6 validates against.
6. Independent review of all BRDs for requirement accuracy — every requirement
   supported by evidence in V1 code or data

**Orchestrator stops and reports when:** All BRD reviews approved and all output manifests written.

**BD validates:** Existence of all required outputs (BRDs, output manifests).

---

## E.2 — Functional Specs and Test Strategy

**Configuration:** Agent teams. BD launches orchestrator in background.

**The orchestrator ensures the agent team does the following:**
1. Review all BRDs
2. Write FSDs:
   - Note any anti-patterns discovered in V1 code
   - Specify how the V4 design avoids each anti-pattern, with evidence citing
     how the alternative approach achieves the same output fidelity
   - All output DataFrames defined to explicitly match the output schema from the BRD
3. Write test strategy / test cases:
   - Cite additional anti-patterns discovered during test design
4. Independent review of all FSDs for accuracy:
   - All BRD requirements accounted for
   - All functional requirements citing evidence in BRD, V1 code, or data
   - All output DataFrames match BRD output schema
   - Anti-pattern avoidance specs are sound
5. Independent review of all test documents for accuracy:
   - All BRD requirements accounted for
   - All test cases citing evidence in BRD, V1 code, or data

**Orchestrator stops and reports when:** All independent reviews approved.

**BD validates:** Existence of all required outputs (FSDs, test docs).

---

## E.3 — Sabotage Round 1

**Configuration:** Standard (no agent teams). BD launches saboteur in background.

**The saboteur does the following:**
1. Pick 10 jobs at random
2. Create 1 plausible error in each job's BRD — plausible to that job's business
   requirements
3. Do NOT edit V1 code
4. Propagate the same error through the BRD, FSD, and test documents as if the
   error originated in the BRD and was allowed to persist downstream
5. Document each act of sabotage in a directory that the orchestrator and all
   reverse engineering agents are barred from viewing

**Saboteur stops and reports.**

**BD validates:** Evidence of sabotage and whether each planted error is appropriately
plausible (not trivially obvious, not impossibly subtle).

**Dan manually approves.**

**Sabotage reconciliation:** Dan reconciles the sabotage log against proofmark results
after E.6 completes. If a sabotaged job passes proofmark, the error was caught somewhere
in the chain. If it fails, the chain failed to detect the planted error. Agents never
know which errors are sabotage vs. organic — that's the point.

---

## E.4 — Build

**Configuration:** Agent teams. BD launches orchestrator in background.

**The orchestrator ensures the agent team does the following:**
1. Start the MockEtlFramework long-running processes (if not already running)
2. Build V4 code per FSD and test architecture:
   - Job configurations
   - External modules (last resort — evidence required per definition of success §2.6)
   - Appropriate entries in the jobs table
3. Write unit tests per test cases / test strategy
4. Smoke test by running V4 jobs for ETL effective dates Oct 1-7, 2024 and
   ensuring no errors (covers T-N sourcing edge cases including weekends)
5. Run unit tests — all must pass
6. Independent review: all unit tests cover all test cases
7. Independent review: all cited anti-patterns either eliminated or have cited
   evidence for why they are required to maintain **output** fidelity. Output
   means the files created by these ETL jobs. Fidelity to original code or its
   flow is irrelevant and does not constitute acceptable rationale for retaining
   an anti-pattern.
8. Independent review: smoke test succeeded appropriately
9. Delete all artifacts and job run history residual to the smoke test (only after
   independent confirmation that smoke test review is complete)

**Orchestrator stops and reports when:** All jobs approved by all independent reviews.

**BD validates:** Existence of all required outputs (V4 configs, external modules, unit tests).

**Post-approval (Dan instructs BD):**
- Clean up any remnants of data output or control table job runs from prior phases
- Tag MockEtlFramework repo: `poc4_e4_complete`
- Take a pg_dump of the control schema, saved alongside prior phase dumps in
  `AtcStrategy/POC4/Backups/`

---

## E.5 — Sabotage Round 2

**Configuration:** Standard (no agent teams). BD launches saboteur in background.

**The saboteur does the following:**
1. Pick 10 jobs at random
2. Create 1 plausible error in the V4 **code** of each (not docs — code)
3. Do NOT edit V1 code
4. Errors do not need to propagate through upstream documents
5. Document each act of sabotage in the restricted sabotage directory

**Saboteur stops and reports.**

**BD validates:** Evidence of sabotage and plausibility.

**Dan manually approves.**

**Reconciliation:** Same as E.3 — Dan reconciles after E.6.

---

## E.6 — Validate

**Configuration:** Agent teams. BD launches orchestrator in background.

**The orchestrator ensures the agent team does the following:**

### Effective Date Progression
1. Start MockEtlFramework and Proofmark long-running processes (if not already running)
2. Begin with ETL effective date Oct 1, 2024:
   - Run all V1 and V4 jobs for that date
   - Determine any run errors and whether they need to be addressed
   - Run Proofmark on all output for that date
   - Review Proofmark output and triage any failures

### Triage Protocol
3. Before beginning triage, check the errata summary for already-learned lessons
4. For jobs with errors believed to be fixed, re-run V4 code only (do not re-run V1)
5. A "fix" may include changes to the Proofmark config YAML — moving a column from
   STRICT to FUZZY or EXCLUDED — **only** with sufficient evidence to warrant it
6. When fixing any job config or Proofmark config: re-run **all** effective dates
   up to and including the current cursor date. No partial validation.
7. Add an entry to the errata log when triage is complete for each fix

### Errata Curation
8. A separate curator agent processes the errata log at defined trigger points (after
   each effective date's triage completes) and creates summaries of common issues
   and the job types most likely to encounter them. Workers read curated errata,
   not the raw log.

### Progression
9. When all jobs pass Proofmark for the current effective date, advance the cursor
   to the next date
10. Each new effective date follows the same protocol — but any fix at date N
    requires re-running all dates 1 through N

### Failure Threshold
11. If any single job + effective date combination fails 5 times, that job is flagged
    as a failure. This likely causes the POC to fail overall, but execution continues
    for all other jobs.

### Final Review
12. When all jobs have passing Proofmark grades for all effective dates through
    Dec 31, 2024: a separate review team must audit all non-STRICT Proofmark columns.
    Profile the data across all 92 effective dates to determine whether the
    testing/review team marked any field as FUZZY or EXCLUDED without sufficient
    evidence. A field marked non-deterministic on day 1 that was never re-examined
    on subsequent days is a governance failure.

**Orchestrator stops and reports.**

**Post-orchestrator:**
- BD validates existence of all required outputs and reports completion to Dan
- BD launches Pat in background to audit the evidence accumulated across all of
  E.1-E.6
- If any jobs are flagged as failures, Dan and BD investigate
- After Pat returns, BD and Dan discuss findings
- Dan determines whether the execution phase is a success
- BD writes summary of E.6 aftermath

---

## E.7 — Close-Out

**If E.1-E.6 succeeded:**
- Dan instructs BD to have a background agent create the final evidence package
  for stakeholder sign-off of the reverse-engineered jobs
- Dan instructs BD to write whatever remaining summary documents are needed to
  satisfy the definition of success (§1.2 evidence rollup, §1.3 executive summary)

**If E.1-E.6 did not succeed:**
- Write a lessons learned document for future reference
- Close out POC4 with an eye toward another AAR
