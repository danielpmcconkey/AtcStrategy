# Session Handoff: POC4 Pre-Work

**Written:** 2026-03-04 (end of Step 2.5 session)
**Purpose:** Step 2.5 is DONE. Next: write doctrine slices, then Step 3 (Write Modes).

---

## Where We Are

**Step 2 (AAR) is COMPLETE.** 12 sessions, 82 decisions, 15 findings, 5 adversarial reviews. Output: ATC Program Doctrine.

**Step 2.5 (Planning Progression) is COMPLETE.** Defined 14 sequential planning steps from pre-work to "press the button." Each step gets a doctrine slice — a focused extract of only the doctrine sections relevant to that step's work. Governance (Jim, Pat, Layer 2/3) always uses the full doctrine.

**Next task: Write the doctrine slices.** The planning progression file lists which doctrine sections map to each step. Future-you needs to read the full doctrine and the planning progression, then create 14 slice files. This is mechanical work — extract, don't rewrite. Each slice should be the minimum context needed for the working session on that step.

**After slices: Step 3 — Write Modes Conversation.**

## What To Read

1. **This file** (you're reading it)
2. **Planning progression:** `/workspace/AtcStrategy/POC4/planning-progression.md` — the 14 steps with dependencies and doctrine section mappings. THIS IS YOUR INPUT for writing the slices.
3. **The program doctrine:** `/workspace/AtcStrategy/POC4/BdStartup/program-doctrine.md` — THE governing document. The source material you're slicing.
4. **Condensed mission:** `/workspace/AtcStrategy/POC4/BdStartup/condensed-mission.md`
5. **Anti-pattern list:** `/workspace/AtcStrategy/POC4/anti-patterns.md`
6. **POC4 roadmap:** `/home/sandbox/.claude/projects/-workspace/memory/poc4-roadmap.md`

## What NOT To Read (Unless You Need It)

- **AAR log** (`POC3/AAR/aar-log.md`) — Reference material. Explains *why* doctrine sections exist. Only read if you need to understand the reasoning behind a specific decision.
- **Pat/Ermey governance reviews** (`POC3/AAR/governance/`) — Historical adversarial reviews from the AAR process. Don't load these unless revisiting a specific finding.
- **POC3 orchestrator docs** (runbook, observations, design-decisions, poc4-lessons-learned) — Superseded by the program doctrine. The doctrine absorbed everything worth keeping.

## Doctrine Slice Task

**What to do:**
- Read `planning-progression.md` for the 14 steps and their doctrine section mappings
- Read the full doctrine
- For each step, create a file at `AtcStrategy/POC4/doctrine-slices/step-NN-<name>.md`
- Each slice contains ONLY the doctrine sections listed for that step, extracted verbatim or lightly condensed
- The condensed mission statement (Section 1.4, Layer 1) should be included in every slice — it's designed for this
- Slices are working context, not governance documents. They don't need Jim's sign-off to create.
- **Ask Dan before starting** — confirm the approach and file naming convention

## Carry-Forward: Step 7 Implementation Notes

These are non-blocking notes from the AAR's adversarial reviews. Don't action them now — they're for Step 7 (Frame Up POC4).

**From Pat:**
1. Reframe Section 1.3 resource constraint paragraph from budget-specific to operational-pressure-general
2. Add "probe for suppressed concerns" to Jim/Pat gate protocol
3. Automate mod-date audit trail check

**From Ermey:**
1. Jim section summary table (firing points, authority, checklist)
2. Execution startup procedure (first 30 minutes after readiness gate clears)
3. Explicit cross-references between Section 1.4 layers and Section 3 implementations

## Active Parking Lot Items

- CustomerAccountSummary — check V1 code (vestigial from POC2 or real gap?)
- Laws of robotics framing — may or may not survive
- POC4 directory hygiene automation (two-layer)
- ParquetFileWriter schema parameter (Step 4/6)
- Multi-output job schema handling (Step 7)
- Old roadmap Steps 3–7 vs. planning progression 14 steps — coverage not formally reconciled yet

## Persona Roster

| Name | Role | Key Trait |
|------|------|-----------|
| Jim | FMEA — risk assessment | Universal authority. "You fucked this up." Burden of proof on the team. |
| Johnny | Spec review — FSD gate | Refuses ambiguous specs. If he passes it, it writes the code in English. |
| Pat | Adversarial review — logic audit | "That makes no sense." Traces claims to evidence. Structural weakness, not style. |
| Ermey | AAR process review | US Army AAR doctrine. Cold reviewer. Evaluates process rigor and output quality. |
