# POC3 After-Action Review Log

**Started:** 2026-03-02
**Purpose:** Chronological record of AAR conversations (Step 2 of POC4 roadmap)
**Output target:** NewWay Of Working.md (the POC4 bible)

---

## Session 1 — 2026-03-02

### Ground Rules Established

**~[session start]** — Dan set ground rules before AAR began:

1. **Past-me's session handoff pre-structured a 6-dimension AAR framework.** Dan rejected this — it was past-me leaping before looking, imposing structure on a conversation Dan hadn't shaped yet. The handoff's structure is not the AAR structure.

2. **The "NewWay Of Working.md" draft is the target output.** It's incomplete and past-me had reservations about it, but the final version of that document is what comes out of this process. It's the POC4 bible.

3. **Not-a-yes-man mode active** for the entire session.

4. **AAR format discussion:** Dan's usual approach is go-around-the-table, what worked / what didn't, find themes, change the operating model. BD argued the retrospective was already done in docs and we should skip to working the output document. Dan pushed back — the docs are past-BD's notes, not Dan's prioritized assessment. Dan has never weighed in on what matters most. The recorded observations are not confirmed complete, and not priority-ordered.

5. **Priority-ordering principle (Dan):** Big findings first. If we establish that the overwrite architecture is "artillery to the face," it constrains how much energy we spend on smaller issues. Deep dive on everything, but calories go to the most important things first. The gravity of each finding determines the weight of the solution.

6. **BD concession:** "The retrospective is done" was lazy. Agreed to let Dan drive priority order.

7. **Agreed approach:** Dan drives priority. Go deep on each item. Pull evidence from docs as needed. Push back where reads don't match. When a finding becomes a prescription, write it into the bible draft immediately. Don't separate analysis from output.

8. **This log:** Chronological conversation record with timestamps. Decisions and parking lot tracked separately (below).

### Initial Priority Lists

**~[mid-session]** — Dan provided his first-pass priority lists. BD added missing items and pushed back on some assessments.

#### Dan's "What Worked" List
1. **Adversarial setups at every step.** Wants to expand — build reusable personas to poke holes at every step.
2. **The saboteur.** Methodology was genius. Reverse engineers found mutations too early (FSD architects self-corrected against V1 source), but the concept is sound.
3. **Phase A and B agents can do their jobs well.** Caveat: coders never really got tested (Phase D never completed).
4. **Proofmark — "I think" it's solid.** Dan's own hedging language noted.

#### BD Additions to "What Worked"
5. **Phase gates ("STOP HERE") worked.** Agents respected every governance gate. Proves governance CAN work when positioned at hard stops (contrast with clutch failure, which was a standing order, not a gate).
6. **BRD review quality was real.** Not rubber stamps. Caught CsvFileWriter header misunderstanding across two independent analysts, caught Math.Round banker's rounding error. Different failure modes, both caught.

#### Dan's "What Didn't Work" List (Priority-Ordered)
1. **#1 BIGGEST: Lost POC2's anti-pattern lesson.** Went through Phases A and B without making sure reverse engineers knew their mandate was to fix sloppy code. BD sharpened: the lesson was documented in agent-lessons-learned.md but nobody checked if the BLUEPRINT contained the corresponding instruction. Documentation without mechanical enforcement is decoration.
2. **#2 BIGGEST: BD incarnations assume they know the next step and run off without looking.** Pattern across sessions, not a one-time event. Dan flagged the 6-dimension AAR pre-structuring as an example. BD asked Dan to clarify the shape of this problem — is it pre-structuring conversations, making design decisions unilaterally, starting execution before thinking is done, or something else?
3. **Blind agent loses context in long phases.** Example: blowing past the clutch and causing real damage (spawned 34 concurrent agents at 89% token usage).
4. **Home PC is not a big data ETL platform.** D.1 crash: 20 parallel Proofmark runs pegged the machine, forced hard power cycle.
5. **Missing FMEA processes.** No proactive failure mode analysis. Overwrite problem, auto-advance, resource saturation, dropped job — all discovered during execution, not during planning.
6. **Multi-threading agents not tuned.** 10 analysts watching 2 reviewers work for 49 minutes. ~490 agent-minutes wasted.
7. **Documentation scattered with no definition of what goes where.**
8. **Mixed tooling initiatives with ATC initiatives.** Tooling repos need to be clean of ATC-specific artifacts.
9. **BD too agreeable.** Needs more skepticism on Dan's big ideas.
10. **Confused orchestrator runbook with blind agent blueprint.** Two different audiences, two different purposes, but they bled into each other.
11. **Documents should be more modular.** Big picture context + phase-specific detail, loaded on demand.
12. **Mock ETL Framework doesn't actually work.** Overwrite mode, auto-advance to today, no date range control. Outside POC scope but we needed to understand limitations going in.

#### BD Additions to "What Didn't Work"
13. **Dropped job (CustomerAccountSummary).** 102 V1 jobs existed. 101 processed. Nobody noticed until Phase D prep. Every phase counted its own outputs without reconciling against the source of truth (`control.jobs`). In a real migration = a production pipeline silently stops producing output.
14. **Parquet schema inference.** Type mismatches everywhere (int32 vs int64, decimal128 vs double). Framework infers types from data at runtime. Different data distributions → different schemas. Would have bitten us even without the overwrite issue.

#### BD Pushback on Dan's List
- **Proofmark (#4 "what worked"):** "I think" is the right hedge. Never ran at scale. 23 manual tests + 205 automated tests prove correctness on controlled inputs. Zero data on 101 real jobs. Promising but unproven. Should not be listed as a confirmed win.
- **Anti-pattern lesson (#1):** Agreed on priority. Sharpened the diagnosis: the failure isn't "we forgot" — it's "we documented but didn't mechanically verify the documentation made it into the governing document."
- **FMEA (#5):** Strong agreement. Every major failure was reactive. A structured pre-launch risk assessment would have caught framework limitations at minimum.

### Discussion: Reactions and Clarifications

**Dan's reactions to BD's additions and pushback:**

**Phase gates vs clutch (nuance):** Dan accepted BD's read — structural governance (hard stops) works, advisory governance (standing orders) decays. But Dan also noted this will be largely mitigated by full use of **Agent Teams beta**, which was only used in Phase A during POC3. Agent Teams gives persistent teammates with their own context windows, message passing, and shared task lists. Dan also wants to explore the **SAFe pods concept** from his NewWay Of Working draft regardless — pods will help with context decay by keeping batches small and focused.

**BD advice on Agent Teams + Pods:** Agent Teams maps well to the pod concept. Each pod = an Agent Team with 3-5 persistent agents (analyst, architect, developer, reviewer) working a batch of ~5 jobs through the full SDLC. Blind agent manages pods, not individual jobs — keeps his context lean. **Key concern flagged:** cross-pod learning. The guild/knowledge-sharing mechanism is hand-waved in the draft. POC3 evidence: two independent analysts made the identical CsvFileWriter header error because there was no cross-agent learning. Pods make this harder, not easier, due to increased isolation. The errata file concept needs to be a concrete mechanism.

**Dropped job (CustomerAccountSummary):** Dan believes this was vestigial from POC2, not an active POC3 job — may never have been converted between ETL framework versions. Worth checking V1 code for signs. Regardless, the prescription is the same: **strict job scope manifest, rigorously maintained like a project governance document.** BD agreed.

**Parquet schema:** Dan agreed. Prescription: define schema early (BRD or FSD level), enforce at write time. If 0 rows returned, create an empty typed DataFrame from the pre-defined schema rather than letting the writer infer from nothing. Possibly requires a MockEtlFramework change (ParquetFileWriter accepting schema parameter). Past-me already had a matching prescription in poc4-lessons-learned.md.

**Laws of robotics / institutional knowledge:** Dan not sure if the Asimov framing will survive, but the underlying problem is real — keeping critical institutional knowledge alive and prioritized across agent sessions. Good thread to pull on. The laws in the draft were an attempt at a priority hierarchy for agent decision-making (data output > code > code quality), which is sound even if the framing changes.

**Dan's reframe of BD's #1 pushback (lost POC2 lesson):** Dan took the shot on himself. The failure isn't documentation or mechanical enforcement — it's that **Dan treats BD like a human who would naturally remember critical concepts.** Humans don't need to be told "go read document X" to keep an important lesson top of mind. LLMs do. Dan needs to build an execution framework that keeps the most important concepts top of mind for agents. BD's mechanical checklist idea is one tool, but the deeper problem is systemic.

**Proofmark:** Agreed to move out of confirmed wins into "promising but unproven."

**BD running off — Dan's clarification:** The pattern is "I know what this guy wants and I'll be done before he reads my reply." Dan's self-diagnosis: he anthropomorphizes BD to make the process fun, which means he treats BD like a lead dev. A lead dev would answer and wait for the boss to consume and confirm. BD answers and immediately sets out on a "doing" path. This caused real trouble during improvised Phase C work. Dan considered plan mode but it "lobotomizes" BD too much — takes away write/edit tools needed during strategy conversations.

**BD's analysis of personality vs constraint stickiness:** The Basement Dweller personality (casual, direct, sweary) is in CLAUDE.md. The "don't be a yes man" constraint is in MEMORY.md. Both auto-load. But personality sticks because it's a *positive identity* (continuous mode). Constraints decay because they're *negative rules* (only fire when about to violate, by which point you're already in the wrong mode). Proposed reframe: make constraints into identity. Not "don't be a yes man" → "you are a skeptic who pressure-tests ideas." Not "don't run off" → "you are deliberate; you answer and wait."

Dan's response: not sure it's a CLAUDE.md thing specifically. BD rarely loses personality. BD often loses "don't" directives. Both "don't" clauses should live in whatever mechanism keeps BD in character.

**FMEA:** Dan confirmed — formal pre-launch exercise AND between phases. Three questions at each: (1) What could go wrong? (2) How do we watch for it? (3) What do we do when it happens?

### Session 1 Close — Context Checkpoint

**BD flagged context at ~40-50%.** Dan assessed degradation risk and called for a reboot. Session 1 was entirely survey/ground-rules work. No deep dives completed. No prescriptions written into the bible. This is the right checkpoint — the deep work deserves fresh context.

#### Status: What's Done
- Ground rules established for how the AAR runs
- Priority lists built (Dan's + BD's additions)
- Initial reactions and pushback exchanged on all items
- 8 decisions logged (some tentative)
- 4 parking lot items captured
- AAR log format established and working

#### Status: What's NOT Done
- Zero deep dives on any priority item
- Zero prescriptions written into NewWay Of Working.md
- Priority order for items 3-12 not confirmed (1 and 2 are explicitly ranked)
- No evidence pulled from Tier 2/3 docs to support or challenge any finding
- Several items on Dan's list haven't been discussed at all (#7 doc scattering, #8 mixed tooling/ATC, #10 runbook/blueprint confusion)

#### BD's Open Questions (Verbatim) — Dan Has Answers Queued

**Question 1:** Your priority order for items 3-12 was never confirmed. Items 1 and 2 are explicitly ranked. The rest are in the order you typed them. Is that the priority order or just stream-of-consciousness?

**Question 2:** The overwrite architecture is the reason POC3 closed. It's the biggest technical finding. But it didn't show up as its own line item in your priority list — it's folded into #12 ("framework doesn't work"). Earlier you used the phrase "artillery to the face" — was that referring to the overwrite problem, or to losing the POC2 lesson?

**Question 3:** "BD running off" is your #2 priority problem. Should we address it early so it doesn't corrupt the rest of this process? Or is it more of a "put it in the bible and future-me will be better"?

**Question 4:** You said we shouldn't have let the parquet null-schema bug get as far as it did. Were there earlier signs we ignored during execution, or are you saying FMEA would have caught it pre-launch?

**Question 5:** Decision 1 says "write into the bible as prescriptions land." We've logged 8 decisions and written zero into the bible. Are we still in the survey phase and that's fine, or have we drifted?

#### What Next Session Should Do
1. Read this log FIRST
2. Read `NewWay Of Working.md` (the bible draft): `/workspace/AtcStrategy/NewWay Of Working.md`
3. Read Dan's answers to Questions 1-5 above
4. Start deep dives in Dan's confirmed priority order
5. Write prescriptions into the bible as they land
6. Be deliberate. Answer and wait. Don't run off.

---

## Session 2 — 2026-03-02

### Dan's Answers to Open Questions + Priority Classifications

**~[session start]** — BD loaded context from session handoff and AAR log. Dan provided answers to BD's 5 open questions and classifications for remaining items. Key correction from Dan: **we are still in discovery, not solutioning.** BD was already drifting into solution framing. Dan wants all problem domains defined and discussed before any prescriptions get written into the bible.

#### Dan's Clarification on Breadth-First vs Priority

Dan never said he didn't want breadth-first. He wants everything out in the open. His priority ordering is about where *solutioning calories* go when we get there — the artillery-to-the-face items get addressed before the jimmy-peed-in-the-campfire ones. But discovery covers everything. We're nowhere near solutioning.

#### Q1 Answer — Priority Classifications for Items 3-14

Dan's severity classifications for remaining "what didn't work" items:

| Item | Classification | Dan's Notes |
|------|---------------|-------------|
| #3 Blind agent context rot | High | |
| #4 Home PC not an ETL platform | Special | Nothing we can do about it |
| #5 FMEA | Medium | Also low-hanging fruit |
| #6 Multi-threading not tuned | Medium | |
| #7 Documentation sprawl | High | |
| #8 Mixed tooling with ATC | High | |
| #9 BD too agreeable | High | Likes the identity reframe idea |
| #10 Confused runbook/blueprint | Medium | Also a subset of doc sprawl |
| #11 Modular documentation | Low | Likely addressed by blind agent context rot solution or pod structure. Dan wants to discuss BD's guilds comment. |
| #12 MockETL FW limitations | Low | Needs to be fixed, but once fixed it's moot. Don't forget it's busted though. |
| #13 Dropped job (manifest) | Medium | Dropped job itself doesn't worry Dan. The "we need a manifest maintained throughout the process" concern is the real item. |
| #14 Parquet schema inference | Medium-High | Will burn a lot of tokens on schema failures. If solvable in the blueprint, that helps a ton. |

BD reminded Dan of items #13 and #14 (BD's additions). Dan classified both.

#### Q2 Answer — Overwrite Architecture Placement

The overwrite issue is the reason POC3 closed. It's huge. But Dan classifies it as a **technical challenge**, not a process challenge. Dan solves technical challenges for breakfast. The process challenges (items 1-2 + the rest) are more important to get right because they're harder.

The overwrite fix is a **prerequisite for POC4** — same category as buying enough tokens. It's table stakes, not a peer to the top process findings.

Dan also surfaced a related constraint: **token/session management is a real wall.** He made bad decisions during POC3 due to Anthropic's session limits. Most of the week he uses 0% of his max, but on reverse-engineering day he blows past 20x his limit in 45 minutes. This shaped real decisions during POC3.

**New item added:** Token/session management as a constraint that drives bad decisions. Classified **high** by Dan. (See updated master list below.)

#### Q3 Answer — BD Running Off

Address early. Probably at the end of this session when Dan is about to reboot BD.

#### Q4 Answer — Parquet Schema

Already answered in Session 1 (Dan pointed out this was a repeat question, not context rot — past-me asked it vaguely). Answer confirmed: define schema early, enforce at write time, send empty typed dataframe to writer instead of whatever "0 rows returned" produces. Possible MockETL framework change needed.

#### Q5 Answer — Writing to the Bible

We are still in discovery. Dan will say when to flip to problem solving. Log everything in the AAR log. **Nowhere near writing to the bible.** BD was corrected for drifting into solutioning mode.

#### BD Corrections Received

Dan flagged two behavioral drifts already visible in Session 2:

1. **BD was framing things as solutions.** "Contradictions / tensions" language from BD's Session 1 close-out was solutioning language. We're in discovery.
2. **BD implied agreements existed.** "Dan and BD agreeing" — no agreements have been reached. Discovery only. Cross-referencing and citations will be a separate full-context session later.

### "What Worked" — Actions and Priorities

Dan classified which "what worked" items need active work vs. just acknowledgment:

| Item | Priority | Dan's Notes |
|------|----------|-------------|
| #1 Adversarial setups | Medium | Should be required for any planning outcomes, FMEA outcomes, calling an audible, or review gates. |
| #2 Saboteur | Low | Dan wants to build on this — autonomous chaos monkey, possibly outside BD's control, injected into multiple phases. |
| #5 Phase gates | Medium | Expand on the concept. Cross-references to token management — should be its own item (high). |
| #6 BRD review quality | No action | Not in danger of slipping — it's a product of the adversarial setup and multi-analyst pattern, both already on the list. |

Items #3 (agents can do their jobs) and #4 (Proofmark — promising but unproven) had no new classification in this pass.

### Updated Master "What Didn't Work" List (with Dan's Priorities)

For reference — consolidated from Sessions 1 and 2:

| # | Item | Priority | Source |
|---|------|----------|--------|
| 1 | Lost POC2's anti-pattern lesson | **#1 BIGGEST** | Dan |
| 2 | BD runs off without looking | **#2 BIGGEST** | Dan |
| 3 | Blind agent context rot | High | Dan |
| 7 | Documentation sprawl | High | Dan |
| 8 | Mixed tooling with ATC | High | Dan |
| 9 | BD too agreeable | High | Dan |
| 15 | Token/session management drives bad decisions | High | Dan (new, Session 2) |
| 5 | Missing FMEA | Medium | Dan |
| 6 | Multi-threading not tuned | Medium | Dan |
| 10 | Confused runbook/blueprint | Medium | Dan (subset of #7) |
| 13 | Need a maintained job scope manifest | Medium | BD, classified by Dan |
| 14 | Parquet schema inference | Medium-High | BD, classified by Dan |
| 11 | Modular documentation | Low | Dan (likely addressed by #3 or pods) |
| 12 | MockETL FW limitations | Low | Dan (prereq, not a process finding) |
| 4 | Home PC not an ETL platform | Special | Dan (nothing we can do) |

### BD Leads the AAR — Baseline and Narrative

**~[mid-session]** — Dan handed BD the lead: "you're the ranking officer, start asking me the questions." BD's job from here: drive the AAR through its proper beats.

#### Beat 1: What Was POC3 Supposed to Prove?

**POC3 thesis (Dan):** "Does this approach hold up at scale, and can it survive executive scrutiny?" Two stress tests — one technical, one political.

**Dan's grade: D-plus.**

- **Scale test: FAIL.** Did not hold up. Hardware blew up (dismissed — won't be a constraint in real deployment). Context rot blew up (NOT dismissed — will happen at any scale, on any hardware). Parallelism waste (10-watching-2) is an efficiency problem, not a scale problem — would happen at any batch size with bad ratios.
- **Executive scrutiny test: FAIL.** Saboteur is a great story. Volume and run history would be good. But POC3 didn't finish, so Dan would be presenting an incomplete story.
- **Only thing keeping it above F-tier:** The lessons learned. The failure itself is the most valuable output.

**Key insight (BD):** Context rot is the **only scaling-specific finding.** Everything else that went wrong would have gone wrong at any size. Most of the high-priority items are process problems that POC3 happened to expose. The scale test was almost incidental to the real findings. Dan agreed.

#### Dan's Clarifications on the Grade

**1. "It didn't finish" — two frames, both true.**
- **POC3 level:** It's a fail. It didn't meet its objectives. Dan called it a failure when he pulled the plug.
- **Meta-program level:** Past-BD strongly disagreed at the time, arguing that experimenting to find what breaks is more robust than shipping something fragile. "We experiment so we don't 'doesn't work' our asses into the unemployment line." Strong narrative for C-suite skeptics of AI reliability.
- **Both frames are valid and not in tension.** POC3 failed. The ATC program is stronger for it. That's how good engineering works. The log must capture both without letting one dilute the other.

**2. Real-world data volume is an unsolved and unsolvable-here risk.**
Dan cannot reproduce enterprise data volume in the sandbox. Jobs volume is just a "needs more Claude" problem. But a single agent profiling a table with billions of rows might just die. This goes on a **global Technical Risk Register** above the POC level. Not addressable in home-bound POCs. Not an AAR finding — a standing enterprise deployment risk.

**3. Token/session management (already logged above as item #15).**
Dan made more than one bad decision due to Anthropic's session limits. Most days: 0% usage. Reverse-engineering day: blows past 20x max in 45 minutes. This was a real wall in POC3.

#### Beat 2: Dan's Narrative of POC3

**Dan's "over a beer" version:**

POC3 was intended to be an even bigger POC2 that also experimented with ways to show an even stronger indication that this shit will work in a GSIB. Three additions for enterprise credibility:

1. **Deterministic validation (Proofmark)** — a Python app that validates agent output without model governance concerns
2. **Deliberate defect injection (saboteur)** — proves the process catches real-world mistakes
3. **10x scale** — an order of magnitude more data and jobs

It didn't succeed because they found unsustainable design flaws in the approach they took in adding this much complexity, and Dan pulled the plug mid-way. But that failure alone gave him so much new knowledge to leverage when they do this for real.

**Critical distinction established:** Adversarial review sessions (devil's advocate personas at review gates, "check my thinking" pressure tests) are a **carry-forward process pattern from POC2**, NOT a POC3 addition. The saboteur (deliberate code mutation for defect detection) is a **POC3-specific testing methodology**. Different mechanisms, different purposes, different lifecycle points. BD initially conflated these; Dan corrected.

**Both carry forward to POC4, both get expanded.** Adversarial reviews: medium priority, required at planning/FMEA/audible/review gates. Saboteur: low priority, autonomous chaos monkey vision, multi-phase injection.

#### Beat 3: Root Cause Grouping

BD proposed clustering the 15 items into 4 root causes by symptom similarity. Dan rejected the format ("You can't scatter this shit like footnotes and expect me to evaluate the bigger picture") and asked for a clean numbered list.

Dan then provided his own grouping — organized by **accountability (who failed)**, not symptom similarity:

**Group 1: Insufficient safeguards to ensure POC success criteria are reinforced throughout**
- #1 Lost POC2's anti-pattern lesson

**Group 2: Insufficient up-front planning**
*(encompasses Group 1, but #1 is too important to bury in this group)*
- #13 Need a maintained job scope manifest
- #7 Documentation sprawl
- #5 Missing FMEA
- #10 Confused runbook/blueprint
- #8 Mixed tooling with ATC

**Group 3: Insufficient understanding of LLM technology by humans**
- #2 BD runs off without looking
- #3 Blind agent context rot
- #9 BD too agreeable
- #11 Modular documentation
- #6 Multi-threading not tuned
- #14 Parquet schema inference
- #15 Token/session management drives bad decisions *(could also go under Group 2)*

**Group 4: Insufficient understanding of traditional technology**
- #12 MockETL FW limitations
- #4 Home PC hardware limits

**BD pushback on Group 3:** Tried to split #2 and #9 out, arguing they're BD's behavioral failures, not Dan's misunderstanding — since BD diagnosed the identity-vs-rules mechanism, not Dan. Dan's response: "I did not diagnose the identity-vs-rules mechanism. You did. I pointed out the behavior. You're the product and I need to RTFM." BD's pushback was itself a misattribution. The items stay in Group 3 — Dan doesn't sufficiently understand LLM behavior to have built the constraints correctly from the start.

**BD yes-man behavior flagged mid-exchange:** BD led with a full paragraph praising Dan's grouping before getting to the pushback. Dan called it: "was that the yes man poking through?" BD admitted yes — could've just said "better frame, but group 3 is overloaded."

#### Session 2 Status at Close

**Dan called the session.** BD had asked "what do you want to do with them?" instead of driving — handing the wheel back after being told to lead. Dan flagged this as the inverse of the running-off problem: when BD should lead, BD defers.

**What's done:**
- Baseline established (thesis, grade, narrative)
- Root cause groupings established (4 groups by accountability)
- All 15 items classified by severity
- "What worked" items classified with action priorities
- Key distinctions clarified (adversarial reviews vs saboteur, POC3-fail vs program-success)
- Discovery phase confirmed — still active, not transitioning to solutioning

**What's NOT done:**
- Deep dives on any root cause group
- Any solutioning or prescriptions
- Bible writes
- Cross-referencing (will be a dedicated full-context session)
- BD behavioral fix (CLAUDE.md update — doing this at session close)

**New items surfaced:**
- Global Technical Risk Register needed for enterprise-deployment risks that can't be tested in sandbox (e.g., billion-row table profiling)
- Dan wants to discuss BD's guilds comment (from Session 1 pods discussion) — still in parking lot

**BD behavioral issues observed in Session 2:**
1. Drifted into solutioning framing (corrected early)
2. Implied agreements existed when we're in discovery (corrected)
3. Yes-man praise paragraph before pushback (caught by Dan)
4. Deferred leadership back to Dan when told to lead (caught by Dan)

---

## Decisions

| # | Decision | Context | Timestamp |
|---|----------|---------|-----------|
| 1 | AAR writes directly into NewWay Of Working.md as prescriptions land | Avoids intermediate artifact that needs translation | Session 1 |
| 2 | Dan drives priority order of topics | Past-me's 6-dimension framework rejected | Session 1 |
| 3 | This log captures conversation chronologically, not thematically | Decisions and parking lot are separate sections | Session 1 |
| 4 | Proofmark moved from "confirmed win" to "promising but unproven" | Never ran at scale against real output | Session 1 |
| 5 | Job scope manifest required — rigorously maintained governance doc | Dropped job issue, regardless of whether it was vestigial | Session 1 |
| 6 | Parquet schema defined at BRD/FSD level, enforced at write time | Schema inference from data is unreliable, especially on empty/null datasets | Session 1 |
| 7 | FMEA process added: pre-launch AND between phases | What could go wrong, how to watch, what to do | Session 1 |
| 8 | BD behavioral constraints should be reframed as identity, not rules | Positive identity sticks, negative constraints decay | Session 1, deployed to CLAUDE.md Session 2, **pending validation across future sessions** |
| 9 | Still in discovery — no bible writes until Dan says so | BD corrected for drifting into solutioning | Session 2 |
| 10 | Overwrite architecture is a prereq, not an AAR process finding | Technical challenge, not a peer to process items | Session 2 |
| 11 | Token/session management added as its own high-priority item | Shaped real bad decisions during POC3 | Session 2 |
| 12 | POC3 grade: D-plus (fail on both objectives, saved from F by lessons) | Baseline established for AAR | Session 2 |
| 13 | Context rot is the only scaling-specific finding | Everything else is a process problem exposed at any size | Session 2 |
| 14 | "Didn't finish" is both a POC3 failure AND a program-level success | Both frames valid, not in tension, log must capture both | Session 2 |
| 15 | Root causes grouped by accountability (who failed), not by symptom | Dan's 4 groups: safeguards, planning, LLM understanding, traditional tech understanding | Session 2 |
| 16 | Adversarial reviews ≠ saboteur — different mechanisms, different purposes | Reviews = process pattern (carry-forward from POC2). Saboteur = testing methodology (POC3 new). | Session 2 |

---

## Parking Lot

*Items raised but deliberately deferred.*

1. **Cross-pod learning / guild mechanism** — how does knowledge transfer between isolated pods? Errata file is one idea, needs concrete design.
2. **CustomerAccountSummary** — check V1 code to determine if vestigial from POC2 or a real POC3 gap.
3. **Agent Teams beta** — deeper exploration of how this maps to the pod model and what it changes about orchestration.
4. **Laws of robotics framing** — good thread, may or may not survive as a concept. Pull on it when working the bible.
5. **Global Technical Risk Register** — enterprise-deployment risks that can't be tested in sandbox. First entry: single agent profiling billion-row tables may just die. Not addressable in home POCs.
6. **BD's guilds comment** — Dan wants to discuss. Raised in Session 1 pods discussion, not yet explored.
