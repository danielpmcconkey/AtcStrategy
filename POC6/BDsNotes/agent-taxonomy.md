# POC6 Agent Taxonomy

Full per-job waterfall pipeline. Each leaf node is an atomic agent.

```
RE Job Pipeline
├── Plan
│   ├── Locate OG source files
│   ├── Inventory outputs
│   │   ├── DataframeWriter
│   │   └── External module
│   ├── Inventory data sources
│   └── Note dependencies
├── Define
│   ├── Write BRD
│   │   ├── Define data flow
│   │   ├── Define transformation rules
│   │   ├── Define output formats and schemas
│   │   ├── Catalog existing anti-patterns
│   │   └── Review response (incorporate reviewer feedback)
│   ├── Review BRD
│   │   ├── Confirm all cited evidence is real
│   │   ├── Approve BRD → queue Design
│   │   └── Reject BRD → queue Review response
│   └── Re-review BRD (triggered by Build L7)
│       ├── Re-confirm evidence against current state
│       ├── Pass → continue
│       └── Fail → queue Review response, halt downstream
├── Design
│   ├── Write BDD test architecture
│   │   ├── Define acceptance criteria from BRD
│   │   ├── Write feature scenarios (Given/When/Then)
│   │   ├── Define data fixtures and test boundaries
│   │   ├── Specify negative/edge cases
│   │   └── Review response (incorporate reviewer feedback)
│   ├── Review BDD test architecture
│   │   ├── Verify traceability to BRD requirements
│   │   ├── Assess scenario coverage completeness
│   │   ├── Approve BDD → queue Write FSD
│   │   └── Reject BDD → queue Review response
│   ├── Write FSD
│   │   ├── Review BRD
│   │   ├── Review BDD test artifacts
│   │   ├── Draft new data flow
│   │   ├── Write data sourcing requirements (pseudo-code)
│   │   ├── Write transformation query requirements (pseudo-code)
│   │   ├── Determine module sequence (anti-pattern remediation)
│   │   ├── Trace all requirements to BRD# and BDD scenario# with evidence
│   │   └── FSD review response (incorporate reviewer feedback)
│   ├── Review FSD
│   │   ├── Verify evidence and traceability to BRD# and BDD scenario#
│   │   ├── Approve FSD → queue Build
│   │   └── Reject FSD → queue FSD review response
│   ├── Re-review BDD (triggered by Build L7)
│   │   ├── Re-verify traceability and coverage against current state
│   │   ├── Pass → continue
│   │   └── Fail → queue Review response, halt downstream
│   └── Re-review FSD (triggered by Build L7)
│       ├── Re-verify evidence and traceability against current state
│       ├── Pass → continue
│       └── Fail → queue FSD review response, halt downstream
├── Build
│   ├── Build job artifacts
│   │   ├── Create job conf files per FSD
│   │   ├── Create external modules per FSD
│   │   └── Review response (incorporate reviewer feedback)
│   ├── Review job artifacts
│   │   ├── Verify all FSD items are implemented
│   │   ├── Approve artifacts → queue Build proofmark config
│   │   └── Reject artifacts → queue Review response
│   ├── Build proofmark config
│   │   ├── Define column-level match rules (strict/fuzzy/non-strict) from BRD schemas
│   │   ├── Justify any non-strict or fuzzy columns with BRD#/FSD# evidence
│   │   ├── Generate proofmark YAML
│   │   └── Review response (incorporate reviewer feedback)
│   ├── Review proofmark config
│   │   ├── Verify match rules align with BRD output schemas
│   │   ├── Verify non-strict/fuzzy justifications
│   │   ├── Approve → queue Build UTs
│   │   └── Reject → queue Review response
│   ├── Build unit tests
│   │   ├── Write UTs per code and BDD test architecture
│   │   ├── Verify UT coverage maps to BDD scenarios
│   │   └── Review response (incorporate reviewer feedback)
│   ├── Review unit tests
│   │   ├── Verify traceability to BDD scenarios and code
│   │   ├── Approve UTs → queue Execute UTs
│   │   └── Reject UTs → queue Review response
│   ├── Execute unit tests
│   │   ├── Run all UTs
│   │   ├── Triage failures
│   │   └── All pass → queue Publish
│   ├── Publish
│   │   └── Register jobs in control.jobs table
│   └── Final build review
│       ├── Re-execute BRD reviewer (→ Define re-review)
│       ├── Re-execute BDD reviewer (→ Design re-review)
│       ├── Re-execute FSD reviewer (→ Design re-review)
│       ├── Re-execute artifact reviewer
│       ├── Re-execute proofmark config reviewer
│       ├── Re-execute UT reviewer
│       ├── Audit evidence and traceability (mechanical verification)
│       │   ├── Verify every BRD→BDD→FSD→Code→Test traceability link exists
│       │   ├── Verify every file:line citation points to real content
│       │   └── Verify proofmark config covers all output columns
│       ├── All pass → queue Validate
│       └── Any fail → route feedback to appropriate layer
└── Validate
    ├── Execute job runs
    │   ├── Queue all effective dates into job queue
    │   ├── Monitor output
    │   └── Triage and re-execute any failures
    ├── Execute proofmark
    │   ├── Queue all effective dates into proofmark queue
    │   ├── Review output
    │   ├── All pass → queue Final sign-off
    │   └── Any fail → queue Triage
    ├── Triage proofmark failures
    │   ├── Review proofmark results, determine RCA
    │   ├── Fix code, conf, or proofmark config as needed
    │   └── → re-queue Execute proofmark
    └── Final sign-off
        ├── Confirm passes for all effective dates on single version of artifacts
        ├── Confirm non-strict proofmark columns are justified
        ├── Spot check fuzzy match columns via data profiling (OG vs RE)
        ├── Verify anti-patterns are remediated or confirmed required
        ├── Summarize proofmark results across all effective dates
        └── Summarize anti-pattern remediation
```

## Design Decisions

- **Proofmark config** lives in Build (needs BRD schemas + FSD details to define match rules)
- **BDD before FSD** — tests drive the spec, not the other way around
- **Re-review agents** in Define and Design are triggered by Build L7 final review
- **Each leaf node = one atomic agent** — claim task, do work, queue next step, die
- **All agents cite evidence** — BRD#, BDD scenario#, code references. No unsupported claims.
- **Evidence auditor** is the final FBR gate — mechanical (not judgmental) verification that all citations and traceability links are real
- **Executor agents (test-executor, job-executor)** have a leash of 3 self-fix attempts before returning FAIL
