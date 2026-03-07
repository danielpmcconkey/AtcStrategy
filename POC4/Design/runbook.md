# POC4 Runbook — Step 16

**Status:** DRAFT
**Created:** 2026-03-07
**Purpose:** Dan's process checklist. Evidence trail that the POC followed its own rules.

---

## Prerequisites

- [ ] `dotnet build` succeeds in `/workspace/MockEtlFramework/`
- [ ] `dotnet test` passes
- [ ] PostgreSQL accessible, datalake populated
- [ ] All V1 jobs registered and active in `control.jobs`
- [ ] Smoke test: at least 1 V1 job runs and produces output
- [ ] Job scope manifest sealed at `Governance/ScopeManifest/job-scope-manifest.json`
- [ ] Anti-pattern list finalized at `Governance/anti-patterns.md`
- [ ] Definition of success finalized at `Governance/definition-of-success.md`
- [ ] All blueprints reviewed and approved (Step 15)
- [ ] Artifact directory structure created: `POC4/Artifacts/`, `POC4/Errata/`, `POC4/Sabotage/`
- [ ] Session state file initialized: `POC4/session-state.md`
- [ ] FMEA / Jim sign-off recorded (Step 17)
- [ ] Tooling readiness gate passed (Step 18)

---

## Phase Boundary Ritual

Every phase transition follows this sequence. No exceptions.

1. Orchestrator stops and reports completion to BD
2. BD validates existence of all required outputs (checklist per phase below)
3. Dan manually reviews and approves
4. Dan checks token usage
5. Dan recycles BD (fresh session, clean context)

---

## Execution Sequence

### E.1 — Infer Business Requirements

**Dan instructs BD to:** Launch Orchestrator with `orchestrator-e1.md` blueprint

**BD validates existence of:**
- [ ] BRD for every job in scope manifest
- [ ] Output manifest for every job
- [ ] Review report for every BRD

**Dan reviews:** Spot-check 2-3 BRDs for quality. Check evidence citations.

**Phase boundary ritual.** Recycle BD.

---

### E.2 — Functional Specs and Test Strategy

**Dan instructs BD to:** Launch Orchestrator with `orchestrator-e2.md` blueprint

**BD validates existence of:**
- [ ] FSD for every job in scope manifest
- [ ] Test strategy for every job
- [ ] Review reports for all FSDs and test documents

**Dan reviews:** Spot-check 2-3 FSDs. Verify anti-pattern avoidance specs.

**Phase boundary ritual.** Recycle BD.

---

### E.3 — Sabotage Round 1

**Dan instructs BD to:** Launch Saboteur with `saboteur.md` blueprint (E.3 variant)

**BD validates existence of:**
- [ ] Sabotage ledger at `POC4/Sabotage/ledger-e3.md`
- [ ] 10 jobs sabotaged with documented mutations

**Dan reviews:** Assess each planted error for plausibility. Not trivially obvious, not impossibly subtle. This is a judgment call.

**Phase boundary ritual.** Recycle BD.

---

### E.4 — Build

**Dan instructs BD to:** Launch Orchestrator with `orchestrator-e4.md` blueprint

**BD validates existence of:**
- [ ] V4 job config for every job in scope manifest
- [ ] External modules where needed
- [ ] Unit tests
- [ ] All reviews approved
- [ ] `dotnet build` clean
- [ ] `dotnet test` passing
- [ ] Smoke test residue cleaned up

**Dan reviews:** Spot-check V4 code. Check External module justifications.

**Post-approval (Dan instructs BD):**
- [ ] Clean up data output and control table residue
- [ ] Tag MockEtlFramework: `poc4_e4_complete`
- [ ] pg_dump control schema to `POC4/Backups/`

**Phase boundary ritual.** Recycle BD.

---

### E.5 — Sabotage Round 2

**Dan instructs BD to:** Launch Saboteur with `saboteur.md` blueprint (E.5 variant)

**BD validates existence of:**
- [ ] Sabotage ledger at `POC4/Sabotage/ledger-e5.md`
- [ ] 10 jobs sabotaged with documented mutations

**Dan reviews:** Assess plausibility. Same judgment as E.3.

**Phase boundary ritual.** Recycle BD.

---

### E.6 — Validate

**Dan instructs BD to:** Launch Orchestrator with `orchestrator-e6.md` blueprint

**BD validates existence of:**
- [ ] Proofmark results for all jobs × all effective dates
- [ ] Errata log populated
- [ ] Non-STRICT column audit complete
- [ ] Any flagged failures documented

**Post-Orchestrator:**
- [ ] BD launches Pat to audit all evidence from E.1-E.6
- [ ] If flagged failures exist, Dan and BD investigate
- [ ] After Pat returns, Dan and BD discuss findings
- [ ] Dan determines success/failure

**Phase boundary ritual.** Recycle BD.

---

### E.7 — Close-Out

**Dan instructs BD to:** Launch Orchestrator with `orchestrator-e7.md` blueprint

**BD validates existence of:**
- [ ] Evidence rollup (success case) or lessons learned (failure case)
- [ ] Executive summary (success case)

**Dan reviews and signs off.**

---

## Sabotage Reconciliation

After E.6 completes, Dan reconciles:
- Compare `POC4/Sabotage/ledger-e3.md` and `ledger-e5.md` against Proofmark results
- Sabotaged job that fails Proofmark → error was caught (good)
- Sabotaged job that passes Proofmark → chain failed to detect planted error (bad)
- Agents never know which errors are sabotage vs. organic

---

## CLUTCH

At any time, Dan can create `POC4/CLUTCH` to pause Orchestrator at the next batch boundary. Orchestrator finishes in-progress work, writes session state, and stops. Dan decides what happens next.

---

## Pull-the-Plug Triggers

Dan is the only one who pulls the plug. BD recommends when:
- 3+ agents stuck simultaneously
- Single job hits 5 failed fix attempts
- Overall fix rate trending badly
- Build failures won't resolve
- V1 baseline corruption
