# Group 2 Adversarial Review v2 — "Insufficient Up-Front Planning"

**Reviewer:** Pat (logic audit persona)
**Date:** 2026-03-03
**Scope:** Re-review of bible Section 3 (3.1-3.6) after Section 3.5 rewrite, Section 3.6 addition, and caveats from v1 review
**Documents reviewed:** NewWay Of Working.md (full bible), AAR log (all 7 sessions + decisions), condensed-mission.md, anti-patterns.md, group2-adversarial-review.md (v1), doc-reorganization-plan.md provenance (referenced in AAR log), POC3 artifacts for evidence verification

---

## Summary Grades

| Category | Grade | One-Line Verdict |
|----------|-------|------------------|
| Problem Statement | **A** | Unchanged from v1. Tight scope, correct shared root cause, compound failure chain with Group 3 is the most analytically honest paragraph in the entire bible. |
| Root Cause Analysis | **A-** | Unchanged from v1. #8 still straddles planning and execution. Not worth reopening — the causal chain holds. |
| Mitigation Plan | **A-** | The 3.5 rewrite closes the biggest gap from v1. Section 3.6 is well-constructed with one structural concern. One cross-section interaction problem remains. |

---

## 1. Problem Statement — Grade: A

Nothing to add. The v1 reviewer gave this an A and was right. The scope is correctly drawn. All five items are properly attributed to "insufficient up-front planning." The compound failure chain paragraph connecting Group 2 to Group 3 is specific, evidenced, and structurally necessary — it explains why planning failures that look minor in isolation produced a catastrophic execution failure.

Moving on.

---

## 2. Root Cause Analysis — Grade: A-

The v1 reviewer's analysis holds. Four of five items map cleanly to the shared root cause. #8 is the weaker fit because the mid-POC pause protocol is an execution-phase mechanism, not a planning artifact. The bible handles this reasonably by treating the readiness gate (planning) and the pause protocol (execution discipline) as companion prescriptions in the same section. The attribution is slightly loose but the prescription is correct either way.

The v1 reviewer also flagged that #10's root cause analysis doesn't probe whether the runbook and blueprint had clearly defined scopes from the start. That's still true, but it doesn't change the grade — the evidence from Session 5 ("they bled into each other") supports the planning-failure attribution even if the trail could be tighter.

Moving on.

---

## 3. Mitigation Plan — Grade: A-

This is where the v1 review identified the real problems, and this is where the changes happened. Let me trace each v1 caveat to its resolution, then evaluate the new material.

### V1 Caveat Dispositions

**V1 Caveat 1 (Section 3.2 needs a populated taxonomy, not just a framework):** Closed. Section 3.2 now includes: "The populated taxonomy — not just the framework, but the actual answers for every known POC4 document type — is a prerequisite for the tooling readiness gate (Section 3.1). The gate does not clear until the taxonomy exists with real entries." This is the right fix. A future BD can't wave through the gate with just the four questions — they need real answers. The actual taxonomy content is a Step 7 deliverable, which is the correct placement. The bible establishes the requirement; Step 7 produces the artifact.

**V1 Caveat 2 (Jim's scope relative to Layer 2 and Layer 3):** Closed. Section 3.4 now has a full paragraph defining how the three adversarial processes relate. Layer 2 reviews individual design artifacts as they're produced. Jim reviews the assembled whole at defined boundaries. Layer 3 reviews execution output at first batch boundary. "They do not substitute for each other" and "a future orchestrator under context pressure must not conflate these or assume one covers for another." That last sentence is the one that matters — it's aimed directly at the failure mode the v1 reviewer identified. Good.

**V1 Caveat 3 (Section 3.5 was a standing order pretending to be a forcing function):** Closed via full rewrite. This was the gating caveat. The old 3.5 asked the orchestrator to self-assess context health at "natural pause points" — which is asking the patient to diagnose themselves, using the mechanism (standing orders) that the AAR already proved doesn't work. The new 3.5 replaces self-assessment with architectural prevention. Detailed evaluation below.

**V1 Caveat 4 (#8 attribution spans planning and execution):** Acknowledged in v1 as non-blocking. Correct. No action needed.

### The New Section 3.5 — Agent Session Boundaries

The v1 reviewer's #1 complaint was that the old 3.5 had no mechanical enforcement. The new 3.5 is a fundamentally different prescription. Let me trace the logic.

**The principle is correct.** Don't monitor context rot; prevent it by making sessions short enough that rot can't accumulate. This follows directly from Decision 44 (one agent cannot reliably gauge another's context health) and from the Phase C calamity evidence (BD's self-assessment was the first thing to fail). If you can't measure degradation, prevent the conditions that cause it. Sound reasoning.

**Hard boundaries instead of checkpoints.** "You are done. Persist your state. The next session will pick up." Not "assess whether you should continue." This directly addresses the v1 reviewer's complaint. No self-assessment. No standing order. A structural stop that fires regardless of the agent's confidence level. The contrast with the old 3.5 is night and day.

**Batch-level granularity.** The default unit of work between boundaries is a batch, not a phase. Err on the side of too many boundaries. "Twenty clean reboots beat one long session that goes sideways at minute 45." This is the mechanical cadence the v1 reviewer asked for.

**Mandatory handoff artifact.** A session that ends without a complete handoff has failed, even if its actual work was correct. The next session must start cold from the handoff and persistent governance documents alone. This is the enforcement mechanism — it creates a definition of session success that includes the handoff, not just the work product. A session that does great work and writes a garbage handoff is a failed session.

**Applies to the orchestrator.** The bible explicitly calls out that BD is the session most at risk and gets the same boundaries. This addresses the POC3 evidence directly — the compound failure happened at the orchestrator level, not the worker level.

**What concerns me about 3.5:**

One thing. The handoff artifact specification lists five categories of state to persist:

1. Job scope manifest with current status
2. Tactical changes with propagation status
3. Decisions and rationale
4. Current state of in-progress work
5. Anomalies, open questions, flags

That makes no sense as a flat list. Items 1 and 2 have different persistence mechanics than items 3-5. The job scope manifest (item 1) is a living governance document (Section 3.3) — it doesn't get written from scratch at every boundary. It gets *updated* at the boundary and persists across all sessions. Same for propagation status (item 2) — the document taxonomy (Section 3.2) tracks which documents have been updated and which need the blind-lead version. These are updates to existing documents, not new handoff content.

Items 3-5 are genuinely session-specific — they capture what happened during this segment and what the next session needs to know. These are the handoff artifact proper.

The bible treats all five as equivalent items in a bulleted list. A future BD reading this could interpret it as "at every boundary, write a handoff file containing all five things." That's wrong for items 1 and 2 — those are updates to persistent governance documents, not entries in a session handoff file. A BD who writes the manifest status into the handoff file instead of updating the actual manifest has satisfied the letter of the prescription while defeating the mechanism of Section 3.3.

This isn't a prescription failure. It's a specificity gap. The fix is straightforward: distinguish between "update these persistent governance documents" (items 1-2) and "create session-specific handoff content" (items 3-5). Two sentences, maybe three. Not blocking closure, but it should be tightened.

### The New Section 3.6 — Named Blueprints

The concept is solid. Let me trace the logic and then identify the concern.

**Immutable blueprints:** Written during planning with full attention, reviewed by Layer 2, approved by Jim, used as-is during execution. Eliminates non-deterministic instruction drift across thousands of spawns. This directly addresses the Group 1 failure (anti-pattern lesson didn't make it into the blueprint) by ensuring the blueprint is the single, carefully authored source of truth for agent behavior. If the blueprint is reviewed and approved before execution starts, the POC2 lesson is either in there or Jim catches it.

**Named personas as calibration anchors:** The name is Dan-facing signal compression; the content is agent-facing instructions. "Johnny passed the spec" compresses a judgment profile into four words. This is practically useful — it gives Dan a vocabulary for quality assessments that doesn't require re-explaining the standard every time. The name also serves as blueprint validation: "would real Johnny accept this as his job description?" is a better review heuristic than "are these instructions adequate?" because it invokes Dan's years of calibration with the real person. Fine.

**The errata mechanism — where I want to push.**

The three-part structure: raw errata log (fast capture, minimal analysis) -> curator agent (categorizes by job type, feature, concept) -> curated errata by job profile (workers read only relevant entries).

The bible acknowledges that the curator is imperfect: miscategorization means a relevant warning doesn't reach the right worker. It argues that the review gates still exist as a safety net and that an imperfect curator beats no curator. I'll grant both points. But there's a failure mode the bible doesn't address.

**The curator's categorization scheme depends on understanding the job taxonomy, which doesn't exist yet.** The curator categorizes entries "by job type, feature, and concept." What job types exist? How many? What features define them? What concepts cut across types? None of this is defined. The job taxonomy is a Step 7 output — it emerges from the actual POC4 job portfolio. The curator can't categorize by job type until job types are defined.

This isn't a fatal problem because the curator is also a Step 7 implementation detail. Nobody is building the curator today. But the bible prescribes a specific three-part mechanism where one part (the curator) depends on an input (job taxonomy) that another part (the blueprint) should define. The dependency chain is: job taxonomy -> curator categorization scheme -> curated errata -> worker startup sequence. The bible specifies the chain but doesn't acknowledge that the first link doesn't exist at bible-writing time. A Step 7 BD could miss this dependency and build the curator without first establishing the job taxonomy, producing a categorization scheme based on vibes rather than defined types.

The fix is one sentence in Section 3.6 stating that the curator's categorization scheme must be derived from the job taxonomy established during blueprint authoring, not invented by the curator. The blueprints define the job types; the curator uses those types as tags. This closes the loop.

**Second concern with errata: the curator's timing.**

The AAR log (Session 7) records that BD raised the timing question: "When does the curator run? Asynchronous processing creates a window where raw errata exists but hasn't been categorized." The response was "acceptable if the window is short (curator runs at batch boundaries). Needs to be defined during Step 7."

The bible's Section 3.6 doesn't mention timing at all. A worker spawned during the window between raw errata capture and curator processing would miss the relevant warning. The bible says "the review gates that caught the original error still exist and will catch recurrences" — fine, but if the whole point of errata is to *reduce* repeat failures, a timing gap that allows the exact same failure to repeat on the very next batch defeats the purpose.

This is a known deferral to Step 7 and I won't hold it against the grade, but the bible should at least acknowledge the timing dependency. Right now it reads as if the curated errata is always available when a worker starts, which isn't true if the curator runs asynchronously.

### Cross-Section Interactions

The v1 reviewer flagged Jim vs. Layer 2 vs. Layer 3 temporal proximity as a concern. Section 3.4's new clarification paragraph addresses this for those three processes. But the new 3.5 and 3.6 introduce additional interaction surfaces.

**3.5 (session boundaries) + 3.6 (errata mechanism): Who triggers errata processing?**

Section 3.5 says sessions end at batch boundaries and the next session starts cold from persistent state. Section 3.6 says discoveries go into the raw errata log and the curator categorizes them. If a reviewer discovers an error during batch N and writes it to the raw errata log, the curator needs to process it before batch N+1 workers spawn. But Section 3.5's session boundary means the reviewer's session ends at the batch boundary. Does the curator run as a separate session between batches? Is it part of the orchestrator's inter-batch work? Does it run in parallel with the next batch?

The bible doesn't specify this. The interaction between session boundaries and errata processing has a sequencing dependency that neither section addresses. A future BD would need to figure out: does the batch boundary sequence look like (batch ends -> all sessions recycle -> curator processes errata -> next batch spawns workers who read curated errata)? Or is it (batch ends -> next batch starts -> curator runs in parallel -> some workers in the new batch miss the update)?

The first option is correct but means the curator is on the critical path between batches. The second option has the timing gap I already flagged. This is a Step 7 design decision, but the bible should signal that the interaction exists. Right now, 3.5 and 3.6 read as independent prescriptions. They aren't.

**3.3 (scope governance) + 3.5 (session boundaries): Redundant state persistence.**

Section 3.3 says the job scope manifest is reconciled at every phase boundary. Section 3.5 says the manifest is persisted at every batch boundary (it's item 1 in the handoff state list). Batch boundaries are more frequent than phase boundaries. So the manifest gets persisted at every batch boundary but only *reconciled* (count verified against phase inputs/outputs) at phase boundaries.

This is actually fine — frequent persistence is good, and reconciliation at phase boundaries is the right frequency for a count check. But a future BD could read Section 3.3's "reconciled at every phase boundary" and Section 3.5's "persist manifest at every boundary" and conclude they need to do a full reconciliation at every batch boundary. That's wasteful and would slow execution. The distinction between "persist current state" and "reconcile against phase inputs" should be explicit.

Not a real gap. Just potential confusion from a BD reading two sections that reference the same artifact with different verbs.

---

## Overall Verdict: Is Group 2 Ready to Close?

**Yes.** The three changes since v1 — the 3.5 rewrite, the 3.6 addition, and the caveat fixes to 3.2 and 3.4 — close all four caveats from the first review. The new material is structurally sound. The mitigation plan now has mechanical enforcement across all six subsections.

The grade improvement from B to A- reflects that the 3.5 rewrite is a qualitatively different prescription. The old 3.5 was a standing order that would have failed the same way POC3's standing orders failed. The new 3.5 is an architectural prevention mechanism with defined boundaries, mandatory handoff artifacts, and explicit orchestrator coverage. That's the difference between a prescription that describes what should happen and one that makes the wrong thing structurally difficult.

### Remaining Notes (Not Blocking)

These are specificity gaps, not structural weaknesses. None of them change the root cause, challenge a causal chain, or undermine a prescription's connection to its evidence. They're tightening opportunities for Step 7.

1. **Section 3.5's handoff state list conflates governance document updates with session-specific handoff content.** Items 1-2 (manifest, propagation status) are updates to persistent documents. Items 3-5 (decisions, in-progress state, anomalies) are session-specific handoff content. The bible should distinguish these so a future BD doesn't write manifest status into a handoff file instead of updating the actual manifest. Two sentences.

2. **Section 3.6's curator depends on a job taxonomy that the blueprints define.** The curator categorizes "by job type, feature, and concept" but those categories come from the blueprint authoring process, not from the curator's invention. One sentence stating the dependency closes the loop.

3. **Sections 3.5 and 3.6 have a sequencing dependency at batch boundaries.** The curator must process errata between batches for the curated index to be current when the next batch's workers read it. Neither section acknowledges this. The interaction should be flagged so Step 7 designs the batch boundary sequence correctly.

4. **Section 3.6 doesn't mention curator timing.** The AAR log shows this was discussed and deferred to Step 7, but the bible reads as if curated errata is always available at worker startup. An acknowledgment of the asynchronous processing window would set correct expectations.

### Disposition

Close Group 2. The four notes above are implementation refinements for Step 7 — the kind of specificity that gets resolved when someone actually builds the system. The prescriptions are structurally sound. The causal chains are evidenced. The mitigations address their root causes through mechanisms that match the failure modes they're designed to prevent. Pat has nothing else to break.
