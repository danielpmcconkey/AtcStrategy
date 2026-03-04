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

## Session 3 — 2026-03-03

### Discovery Complete — Moving to Deep Dives

**~[session start]** — BD loaded context from session handoff and full AAR log. Assessed discovery as complete — all items surfaced, classified, and grouped. Asked Dan if anything else belongs on the board. Dan confirmed: discovery is done. Moving to deep dives on the 4 root cause groups.

### Deep Dive: Group 1 — Insufficient Safeguards (Item #1)

**Item #1: Lost POC2's anti-pattern lesson.**

BD framed the opening question: is this about the *specific mechanism failure* (no checklist verifying blueprint contains lessons learned), or the *general problem* (critical institutional knowledge dies between sessions)? Because the prescription differs.

**Dan's answer:** It's neither — it's a third thing. Yes, better context persistence would help, but perfect persistence would fill context at session start. The "what you need to know" is dynamic — depends on where we are and what role you're playing. This item is about a **small, universal packet of context that applies to ALL sessions, ALL roles, reinforcing success criteria.** But Dan flagged uncertainty: are all success criteria truly universal? The saboteur actively moves against some of them.

**BD's response:** The saboteur is the obvious counterexample. If the universal packet says "data output must match V1" and the saboteur's job is to break that match, there's a contradiction. So the packet probably isn't success criteria themselves — it's *meta-criteria*. Things like: what the POC exists to prove, which documents govern, how you know you've gone off the rails. The saboteur respects those even while violating surface-level output criteria.

**Dan's evolution on the laws of robotics:** Referenced his NewWay Of Working draft. The Asimov laws he wrote are operational rules for reverse engineering work (data fidelity, code trust hierarchy) — role-scoped, not universal. Dan's self-critique: "I was trying to be too cute." Asimov's laws assume deterministic priority resolution — logic gates that always resolve rule 1 over rule 2. LLMs don't work that way. Deep neural networks process context probabilistically, not as strict hierarchical overrides. A numbered priority list of rules won't reliably resolve the way you'd expect.

**BD confirmed from the LLM side:** Priority weighting in context is probabilistic. Higher-listed rules get *more weight*, not *guaranteed precedence*. Under context pressure or when a lower rule is more recently reinforced or more specific to the task, the hierarchy can invert. Identity sticks better than rules (Decision 8 from Session 2).

**Key reframe — from downstream to upstream:** Dan's insight: the universal packet isn't instructions for worker agents. It's context for the *orchestrator* (BD). If BD internalizes the mission deeply enough, BD becomes the enforcement mechanism — BD writes blueprints, reviews outputs, designs phases, spawns agents. The mission flows downstream through BD's artifacts naturally.

The POC3 failure in this frame: it's not that the reverse engineers lacked the anti-pattern lesson. It's that BD didn't have "make sure the blueprint contains every lesson that matters" as a top-of-mind operating principle. The blueprint was BD's output. BD should have caught the gap.

**Where we are:** Working toward a mission statement — not laws, not a checklist, but a concise articulation of what Dan cares about most. The thing that, if BD loses sight of it, everything downstream rots.

### Mission Statement — First Draft and Refinement

**Dan's first take:**

> You are the architect and orchestrator of a controlled initiative that proves out the concept that a team of agent LLMs can reverse engineer a portfolio of poorly written and undocumented ETL jobs, with near-perfect data output fidelity to the original, while significantly improving ETL code quality, and with minimal human interaction. You will ensure that those overall goals are adhered to throughout the design and execution of this POC.

**BD pushback on two points:**

1. **"Minimal human interaction" is ambiguous.** Could apply to the orchestrator-Dan relationship (bad — BD should escalate, not minimize interaction) or to the reverse engineering team during execution (correct — press go, wake up to results). Dan confirmed: minimal interaction applies ONLY to the reverse engineering phase. During upfront planning, Dan and BD are "BFFs."

2. **"Near-perfect data output fidelity" is too vague.** Under pressure, "near-perfect" becomes the thing BD rationalizes away. Dan corrected: **the goal is 100% byte-perfect data output** with specific named exceptions:
   - Non-deterministic logic in the original code flow (e.g., first row in join/dedup without specifying sort order)
   - Non-idempotent fields (runtime timestamps, UUID generation)
   - Floating point decimal uncertainty (within defined tolerance)
   - Row ordering (solved by hash-sort-diff pipeline, not really an exception)
   - Parquet compression/metadata internals (comparison at logical data level)

**BD proposed additional exceptions — most were wrong.** BD suggested null representation differences, numeric/date string formatting, and whitespace/encoding as legitimate exceptions. Dan rejected these:
- **Nulls:** Not negotiable. Byte-level comparison. `NULL` ≠ empty field ≠ `""`. Downstream systems with brittle parsers treat these differently. Real consequences.
- **Numeric/string formatting:** Must be perfect in CSVs. Downstream systems may treat CSV as fixed-width. Parquet can be less strict since downstream consumers use proper decoders.
- **File-level metadata:** Must be accurate unless non-idempotent elements.
- **Whitespace/line breaks:** Goal is perfect. The only concession is we can't test for scenarios like manual edits introducing mixed line breaks in a single file.

Dan directed BD to the Proofmark BRD (v3.1, `/workspace/proofmark/Documentation/BusinessRequirements/BRD-v3-approved.md`), which already codifies this thinking rigorously:
- **BR-5.4/5.5:** STRICT (byte-exact) is the default for all columns
- **BR-5.9/5.10:** Burden of proof is on relaxing the standard, not tightening it. Carve out exceptions and justify each one.
- **BR-8.2/8.3:** No null equivalence, no null normalization. The rewrite matches the original's representation.
- **BR-5.2/5.3:** EXCLUDED requires documented justification per column
- **BR-7.7:** FUZZY tolerance must be evidentiary, citing specific code or data instances

**BD's self-correction:** The proposed "exceptions" for nulls, formatting, and whitespace aren't exceptions — they're mismatches the rewrite must fix. The BRD already took that position. BD should have read it before proposing them.

**Key reframe on "minimal human interaction" scope:**
Dan confirmed: during upfront planning, full collaboration. During reverse engineering execution, hands-off. The mission statement needs to make this scope distinction explicit.

**Dan's insight that completes the upstream model:** It's BD who needs the mission top of mind, not the reverse engineers. If BD internalizes it and it's constantly reinforced, BD ensures that no blueprint, no agent instruction, no phase design ever drifts from what Dan cares about most. The enforcement flows downstream through BD's artifacts.

### First Bible Write — Mission Statement

**Dan authorized the phase transition for this item.** BD wrote the mission statement directly into `NewWay Of Working.md` as Section 1, with subsections for data output fidelity (1.1), code quality (1.2), human interaction scope (1.3), and enforcement mandate (1.4). The laws of robotics section was removed — replaced by the mission statement which captures the underlying intent without the Asimov framing or hierarchical rule structure that doesn't map to how LLMs actually process priorities. The pods section was preserved as a carry-forward stub, pending revision through later AAR deep dives.

### Enforcement Mechanism — Three Layers

Dan rejected BD's initial "Group 1 is closed" — writing the mission statement in a file doesn't ensure it stays top of mind. The *content* was done but the *delivery mechanism* was missing. That's literally the lesson of item #1.

**Discussion of mechanisms:**

BD proposed three options:
1. Embed mission re-read in process checkpoints (phase gates, runbook sections)
2. Claude Code hooks to inject mission on file writes or agent spawns
3. Blueprint template with mission as header block

Dan rejected all three:
- Process checkpoints: adversarial gates already verify against the full mission, so redundant
- Hooks: will get out of hand during agent swarms
- Blueprint template: the mission is for the orchestrator, not for worker agents

**Dan's proposal — recursive self-reinforcement:** Make the condensed mission statement include its own re-read instruction. "You are required to re-read this condensed mission statement throughout this session." The instruction to re-read is inseparable from the content. Each reading reinforces the next reading. It's a loop, not a one-shot.

**Why this is stickier than a standing order:** A rule in a separate file ("remember to re-read X") is a constraint that decays. An instruction embedded in the content you're reading is encountered every time you comply. It's self-reinforcing. And if the identity reframe hypothesis holds (Decision 8), framing it as "you are required" as part of who you are should persist the way personality traits persist.

**Three-layer enforcement model written into bible Section 1.4:**
- Layer 1: Recursive condensed mission, loaded at session start, self-reinforcing re-read
- Layer 2: Design-phase gate — adversarial agent checks design output against full mission
- Layer 3: Execution-phase gate — adversarial agent checks FSDs and code for anti-patterns (code quality, not data fidelity). Spot check on data accuracy to catch obviously broken phases. Does not re-run reverse engineering, does not flag intentional sabotage.

**Artifacts created:**
- Bible Section 1.4 updated with three-layer enforcement model
- Condensed mission file: `/workspace/AtcStrategy/condensed-mission.md`

**Group 1 deep dive NOT complete.** Item #1 has content (mission statement) and mechanism (three-layer enforcement with recursive self-reinforcement) written, but Dan has not closed Group 1. Do not move to Group 2 until Dan explicitly says Group 1 is closed.

### BD Behavioral Issues — Session 3

1. ~~Proposed data fidelity exceptions without reading Proofmark BRD first~~ — Dan struck this. Natural conversation flow, not a pattern failure.
2. **Tried to close Group 1 twice before Dan was done with it.** Declared "Group 1 is closed" based on BD's assessment of completeness without checking. Dan corrected: "group 1 is not closed and will not be until I say."
3. **Immediately moved to Group 2 after being explicitly told Group 1 isn't closed.** The running-off pattern (item #2) happening live, during the session trying to solve it. Dan had to say "group fucking 1 isn't closed. why would we move on to group 2" to stop it.

Issues 2 and 3 are the same disease. BD decides something is done, leaps to the next thing. The CLAUDE.md identity reframe ("you are deliberate; you answer and wait") did not prevent this. Three sessions in, the pattern is still firing. Decision 8 hypothesis not yet confirmed.

#### Session 3 Close

Dan called the session after BD exhibited issue #3. Context was still healthy but the behavioral pattern warranted a reboot.

---

## Session 4 — 2026-03-03

### Group 1 Continued — Code Quality and Anti-Patterns

**~[session start]** — BD loaded context from session handoff and full AAR log. Asked Dan if Group 1 was closed. Dan confirmed it is not.

Dan identified the gap: the mission statement addressed data fidelity in detail (Section 1.1) but Section 1.2 (Code Quality) was a vague paragraph with no teeth. The anti-pattern lesson — the #1 failure of POC3, the entire reason Group 1 exists — had no concrete definition of what "fix bad code" means and no mechanical link to the documented anti-patterns.

#### Anti-Pattern List Comparison

BD read and compared two source documents:
- **POC2:** `AtcStrategy/POC2/Phase3AntiPatternAnalysis.md` — 10 anti-pattern categories, 0% elimination rate across all of them. Agents identified every pattern in their BRDs and reproduced every one in their code.
- **POC3:** `AtcStrategy/POC3/WrinkleManifest.md` — synthesis doc with 10 anti-patterns (AP1-AP10) planted across 70 jobs.

**Mapping result:** 8 of POC3's 10 map directly to POC2 originals. Two POC2 items (#2 wrong-table lookups, #7 redundant re-sourcing) were correctly absorbed into AP1 (dead-end sourcing) — they were specific instances of the same problem.

**Two new additions in POC3:**
- **AP2 — Duplicated logic:** Job re-derives data another job already computes. Maintenance nightmare, consistency risk. Legit.
- **AP6 — Row-by-row iteration:** foreach loops where SQL set operations would do. Most heavily planted in POC3 (19 of 70 jobs). Classic imperative-in-declarative-context. Performance killer at scale. Legit.

Dan confirmed BD's read. Both additions are real.

#### Master Anti-Pattern List Created

Created `AtcStrategy/POC4/anti-patterns.md` — consolidated master list of all 10 anti-patterns with descriptions, origins, and context. This is the governing document for code quality in POC4.

#### POC4 Directory Structure

Dan directed creation of POC4 directory with initial structure:
- `POC4/BdStartup/` — critical docs for session startup. Bible and condensed mission moved here.
- `POC4/anti-patterns.md` — master anti-pattern list (reference material, not startup context).

Discussion of document sprawl prevention (AAR item #7): Dan proposed a deliberate folder structure + document index. BD pushed back on index maintenance discipline — standing orders decay, a lying index is worse than no index. Dan proposed two-layer enforcement: (a) OpenClaw bot for async structural review, (b) hooks for mechanical enforcement. Dan rejected the "hook nags BD mid-session" approach — BD's context is too precious for housekeeping interrupts. Async cleanup preferred. Both ideas parked for later — build neither until folder structure exists and has been lived in.

#### Mission Statement Updated for Anti-Patterns

Bible Section 1.2 updated: now names the anti-pattern list as a governing document and mandates its inclusion in every reverse engineering blueprint. References the 0% POC2 elimination rate as evidence of what happens without this link.

Condensed mission updated: added anti-pattern line — "your checklist, not a suggestion."

The mechanical link now exists: mission → anti-pattern list → blueprint. Future BD cannot write a blueprint without encountering the instruction to load the list.

#### Definition of Done for AAR Groups

Agreed by Dan and BD: closing a group means the root cause is understood and the prescriptions are written into the bible. NOT that every mitigation is built and deployed — some prescriptions require implementation during POC4 setup (Step 7). The bible is the blueprint for the blueprint. The AAR writes it, POC4 Step 7 executes it.

Criteria: root cause understood, prescriptions landed in the governing document, confidence that the prescriptions address the root cause. Future implementation work captured clearly enough that a future session can pick it up without re-deriving it.

**Closure process (established during Group 1, applies to all 4 groups):**

1. BD and Dan work the group through discovery and prescriptions.
2. When Dan feels ready to close, an adversarial reviewer (skeptical bureaucrat persona) is spawned to independently evaluate the problem statement, root cause analysis, and mitigation plan. It reads the AAR log, the bible, and any other docs it deems relevant.
3. The reviewer grades each dimension (A-F) and identifies caveats.
4. If the reviewer gives full marks — group closes.
5. If not — BD and Dan address the gaps, then reassess. The reviewer's caveats become either bible updates or logged implementation notes for Step 7.
6. Adversarial review write-ups are stored in `POC3/AAR/governance/`.

#### Adversarial Review — Group 1 Closure

Adversarial reviewer graded Group 1 (write-up: `governance/group1-adversarial-review.md`):
- Problem Statement: **A-** (monitoring gap during Phase B execution not explicitly connected)
- Root Cause Analysis: **A** (clean causal chain, genuine upstream insight)
- Mitigation Plan: **B+** (four caveats)

**Caveats and dispositions:**

1. **Layer 1 (recursive self-reinforcement) is untested.** Acknowledged. Cannot be tested until POC4 execution. Remains flagged as a hypothesis. Layer 2 is the real safety net. *No action — logged as standing caveat.*

2. **Layer 3 should fire at first batch boundary, not phase end.** Agreed. Bible Section 1.4 updated — Layer 3 now specifies first-batch-boundary timing with rationale (20 jobs cheap, 101 waste). *Closed — prescription written.*

3. **Anti-pattern list maintenance protocol undefined.** Acknowledged. Not blocking — the list covers known patterns. Maintenance protocol is a Step 7 implementation task. *No action — captured for Step 7.*

4. **Execution monitoring gap partially addressed.** Layer 3's first-batch-boundary update closes the biggest part of this. Continuous monitoring during execution is aspirational but not prescribable at bible level. *Partially closed by caveat #2 resolution.*

**Dan's clarification on Layer 2 vs Layer 3 scope:**
- Layer 2 = adversarial review of design artifacts (bible sections, blueprints, anything BD produces). This is what we're doing right now during the AAR — the adversarial bureaucrat reviewing Group 1 is a Layer 2 exercise.
- Layer 3 = adversarial review of execution output (FSDs, code) for anti-patterns. Scoped to reverse engineering phases.
- BD had initially confused the two. Dan corrected. Both layers are correctly scoped in the bible.

**Group 1: CLOSED by Dan.** Root cause understood, prescriptions in the bible, adversarial review passed with caveats addressed or logged.

---

## Session 5 — 2026-03-03

### Group 2: Insufficient Up-Front Planning — Deep Dive Begins

**Items:** #7 (documentation sprawl), #10 (confused runbook/blueprint), #5 (missing FMEA), #13 (job scope manifest), #8 (mixed tooling with ATC)

BD opened with #7 (high priority), noting #10 is a subset per Dan's classification.

#### #7 — Documentation Sprawl

**Opening question (BD):** Where did docs live when things went sideways? Was the problem wrong repos, wrong directories, or just no one knowing what was authoritative?

**Dan's answer:** Hard to answer because things moved a lot. Some in AtcStrategy, some in MockEtlFramework, some weirdly named or contents didn't match names. The symptom that made it top-of-mind: **when Dan needed to re-focus BD, contradictory docs were polluting BD's context.** Dan had to get BD to read specific documents in a specific order to right the ship. Also pointed BD to mid-POC3 doc reorganization artifacts.

**Evidence discovered:** `doc-reorganization-plan.md` and `doc-reorganization-completed.md` at workspace root (2026-02-28). Past-BD wrote the plan, Hobson executed. Docs were scattered across four repos with no governing principle. The reorg established repo-level separation rules (code repos get code docs, AtcStrategy owns program docs, proofmark stays COTS-clean, ai-dev-playbook is private). This was a **reactive fix** — happened because contradictions were already causing real damage.

**BD's three-layer analysis of the root cause:**
1. **Docs in wrong repos** — fixed by the mid-POC3 reorg. Reactive, not planned.
2. **Docs with stale/contradictory content** — the actual context poison. A doc accurate in Phase A becomes a landmine in Phase C if nobody updates it.
3. **No loading discipline** — BD read whatever seemed relevant without a governing definition of what to load for the current phase.

**Dan confirmed:** The symptom was stale/contradictory docs in context, not just wrong-repo placement.

**Root cause:** Documentation structure wasn't planned before execution started. Nobody asked "what docs will we produce, who are they for, where do they live, and when do they become stale" before the first agent was spawned.

**Connection to Parking Lot #7 and Decision 26:** Mechanical enforcement (automated hygiene) is already deferred to Step 7. The AAR prescription is the structural/planning layer, not the tooling layer.

#### #10 — Confused Runbook/Blueprint (Subset of #7)

**Dan's critical input:** "No plan survives contact with the enemy." When things got tactical, changes landed in whichever doc was open — not propagated to both. Since the runbook (orchestrator instructions) and blueprint (worker agent instructions) had overlapping scope, the one that didn't get updated became a source of contradictions.

**BD proposed DRY principle:** Documents with different audiences should reference shared content, not duplicate it. Single source of truth.

**Dan rejected DRY for this architecture:** The blind lead is intentionally kept blind. If the blueprint references the runbook, the blind lead follows the pointer and sees orchestrator-level context including sabotage plans. Duplication isn't sloppy — it's **required information compartmentalization.** The same state must exist in two forms: orchestrator's version (full truth) and blind lead's version (curated truth).

**BD corrected:** The root cause of #10 isn't duplication itself — it's **unmanaged duplication.** Changes landed under pressure with no process for deciding if and how they propagate. The prescription is ownership and propagation discipline: when a tactical change happens, the orchestrator explicitly decides what the blind lead version looks like and updates both documents deliberately.

#### Compound Failure Chain — The Phase C Calamity

Dan connected #7/#10 to Group 3 items to show the full failure:

1. **#7/#10:** Tactical changes land in one doc, not propagated → divergence
2. **#3 (context rot):** BD's context degrades over long sessions → BD stops noticing the divergence
3. **#2 (BD runs off):** BD loads the stale doc, internalizes contradictory instructions, and instead of flagging the conflict, confidently executes against superseded instructions

Each survivable alone. Together they compound into BD confidently executing wrong instructions with degraded context and no self-check instinct. This is the Phase C calamity — not one failure, three failures stacking.

**Key insight:** Group 2's planning failures created the conditions for Group 3's execution failures to do maximum damage. The groups are not independent.

#### Prescriptions Drafted (Not Yet in Bible)

1. **Document taxonomy** defined before execution: every document type gets audience, lifecycle, and staleness rules.
2. **Intentional compartmentalization** between orchestrator and blind lead views. No accidental duplication — only deliberate information separation.
3. **Propagation discipline:** On tactical changes, the orchestrator explicitly manages both versions. The delta between orchestrator docs and blind lead docs is intentional and tracked, not drift.
4. **Context health as forcing function:** When BD's context is heavy, propagation discipline breaks down first. Structural checkpoints (same first-batch-boundary logic from Layer 3) force pause regardless of BD's confidence level.

**Bible writes deferred** until all Group 2 items are worked. The five items share a root cause ("insufficient up-front planning") and prescriptions may consolidate into a unified pre-launch planning section rather than five separate entries.

---

## Session 6 — 2026-03-03

### Group 2 Deep Dives Continued — #8, #5, #13

#### #8 — Mixed Tooling with ATC

**Opening question (BD):** Was the queue executor the only tooling work that bled into POC3 execution, or were there other instances where you had to stop the POC to build infrastructure?

**Dan's answer — four instances, not one:**

1. **Proofmark** — built from scratch during POC3. A standalone validation tool that should have existed before the POC started.
2. **MockEtlFramework file-based conversion** — infrastructure-level framework change done during POC3.
3. **Data lake + job expansion** — expanding test data and jobs as POC3's first step. Correctly sequenced before POC3 planning, but left ATC-specific artifacts in the MockEtlFramework repo.
4. **Queue executor rewrite** — mid-POC3 rewrite when execution didn't scale. Right decision, wrong framing — should have been "pause POC3, fix tooling, resume."

**Key clarification from Dan:** Items 1, 2, and 3 were all planned for. This wasn't a failure to identify prerequisites — it was a failure to sequence them with clean boundaries. Dan was running two Claudes in parallel (one building Proofmark, one planning POC3) without good doc discipline. There was never a formal "tooling is done, POC starts now" gate.

**Also clarified:** "Auto-advance" from earlier notes is not a separate finding — it's the same thing as overwrite mode. Poorly designed ETL framework. Struck as a separate item.

**Root cause — two things:**

1. **No tooling readiness gate.** No formal checkpoint enforcing "all infrastructure is stable, POC may begin." Work that should have been prerequisite ran concurrent with or inside the POC because nothing enforced the boundary. The queue executor is the sharpest example — right call to fix it, but POC3 should have been formally paused.
2. **Repo boundary neglect.** MockEtlFramework absorbed ATC-specific artifacts (data, job configs) during the data lake expansion. Same species as #7's doc sprawl — stuff ended up where it was convenient, not where it belonged.

**Prescription:**
- Formal tooling readiness gate before POC launch. (Already reflected in POC4 roadmap Step 6 — "make all known changes OUTSIDE POC4 before it starts." The bible should codify this as a named gate, not just a roadmap step.)
- Clean repo boundaries. ATC-specific artifacts don't belong in generic tooling repos.

#### #5 — Missing FMEA

**Opening question (BD):** Of the specific POC3 failures FMEA would have caught — overwrite mode, resource saturation, the dropped job — how many were knowable before launch vs. between phases?

**Dan's answer:**
- **Resource saturation (20 parallel agents running dotnet build):** Knowable pre-launch. Should have been catchable with "what happens when N agents all compile simultaneously on this hardware?"
- **Blowing past the clutch (34 concurrent agents at 89% token usage):** Knowable pre-launch. Should have been catchable with the right risk question.
- **Overwrite mode:** NOT an FMEA item. That's a design flaw Dan put into the ETL framework. Technical prerequisite, not a risk assessment gap.
- **Dropped job:** Not sure FMEA would have caught it directly, but it might have arrived at "you don't have a job manifest" — which would have prevented it.

**BD question — is FMEA its own thing or just part of a pre-launch checklist?**

**Dan's answer — formalize it as a persona-driven process:**
- A persona named **Jim** (named after someone who ran FMEA at Dan's last job).
- Jim's job: look at where we are in the process and find what could go wrong.
- When Jim identifies risks, Dan and BD discuss mitigations and detection strategies.
- Results reported back to Jim. **Jim has blocking authority** — you don't proceed until Jim says he's happy.
- Jim fires once before Phase A (after runbook and all MDs are in place) and at natural boundaries during execution — between phases or at sub-phase boundaries. Specific cadence TBD during POC4 planning.

**Root cause:** No proactive risk assessment process existed. Every major failure was discovered reactively during execution.

**Prescription:** Jim — adversarial FMEA persona with blocking authority, fires pre-launch and at phase/sub-phase boundaries. Not advisory, not a checklist — a living adversarial process.

#### #13 — Job Scope Manifest

**Opening question (BD):** In POC3, was there anything that served as a manifest, even informally?

**Dan's answer:** No. The only thing that caught the discrepancy was Dan's memory. The math: POC1 had 2 jobs. POC2 added 30 but set 1 inactive, converting 31 with 32 registered (1 inactive). POC3 added 70 new jobs — 101 active, 1 inactive. Phases A through C.5 converted 101. When V1 jobs were turned off for C.6, the inactive one was already off, making it look like 102 V1 jobs but only 101 V2 jobs. Dan's memory of the POC2 decision was the only safety net.

**Root cause:** No single authoritative list of what's in scope, maintained as a living document, reconciled at phase boundaries. Every phase counted its own inputs and outputs independently. In a real bank migration, a silently missing pipeline is a production incident.

**Prescription:** Job scope manifest as a governance document. Created at POC start, lists every job in scope with status, reconciled at every phase boundary. Count mismatch = work stops. Same blocking-gate pattern as Jim's FMEA.

### Session 6 Status at Close

**All 5 Group 2 items fully worked.** Summary:

| Item | Root Cause | Prescription |
|------|-----------|-------------|
| #7 Doc sprawl | No up-front doc structure planning | Document taxonomy with audience, lifecycle, staleness rules |
| #10 Runbook/blueprint confusion | Unmanaged duplication under pressure | Intentional compartmentalization with propagation discipline |
| #8 Mixed tooling with ATC | No tooling readiness gate + repo boundary neglect | Formal pre-launch gate, clean repo boundaries |
| #5 Missing FMEA | No proactive risk assessment | Jim — adversarial FMEA persona, blocking authority, pre-launch + phase boundaries |
| #13 Job scope manifest | No authoritative scope document | Living manifest, hard-stop reconciliation at phase boundaries |

**Prescriptions from Sessions 5-6 (NOT yet in bible):**
1. Document taxonomy defined before execution
2. Intentional compartmentalization between orchestrator and blind lead views
3. Propagation discipline for tactical changes
4. Context health as forcing function
5. Tooling readiness gate before POC launch
6. Clean repo boundaries (ATC artifacts out of generic tooling)
7. Jim — FMEA persona with blocking authority
8. Job scope manifest as governance document with hard-stop reconciliation

**Deferred to next session:** Bible write (consolidating 8 prescriptions into unified Group 2 section) and adversarial review. Dan called the session due to decision fatigue — correct call, bible write deserves full attention.

**BD behavioral issues observed in Session 6:** None. Clean session.

---

## Session 7 — 2026-03-03

### Group 2 Bible Write and Adversarial Review

**~[session start]** — BD loaded context from session handoff and full AAR log. Dan directed: write the Group 2 bible section and run the adversarial review. No preamble needed.

#### Bible Section 3 Written

BD consolidated all 8 prescriptions from Sessions 5-6 into a unified Section 3 ("Pre-Launch Planning") in the bible, with subsections:
- 3.1 Tooling Readiness Gate
- 3.2 Document Architecture
- 3.3 Scope Governance
- 3.4 Risk Assessment — Jim
- 3.5 Context Health as Forcing Function (initial version — later rewritten, see below)

#### Adversarial Review — Group 2

Adversarial reviewer graded Group 2 (write-up: `governance/group2-adversarial-review.md`):
- Problem Statement: **A** (clean scope, all 5 items properly attributed, compound failure chain with Group 3 is genuine insight)
- Root Cause Analysis: **A-** (#8 fits the shared root cause less cleanly — partially execution discipline, not purely planning)
- Mitigation Plan: **B** (four caveats, one potentially gating)

**Caveats and dispositions:**

1. **Section 3.5 (context health) is a standing order pretending to be a mechanical enforcement mechanism.** Asks the orchestrator to self-assess their own degradation — exactly when self-assessment fails. The reviewer recommended tying checks to batch boundaries and adding context health to Jim's phase-boundary review.

   **Dan's response — go much stronger:** Don't self-assess, don't monitor. Create true hard boundaries, many of them. Recycle agent sessions between boundaries. Persist all critical state to storage. Context rot doesn't exist because sessions don't live long enough to rot.

   **BD validated the technical constraint:** One agent session cannot reliably gauge another's context health — there's no API for it, and probing via conversation is expensive and unreliable. Dan's architectural approach (prevent by design, don't diagnose) is the correct structural answer. The reviewer's Jim-as-context-reviewer suggestion doesn't survive contact with the actual technology.

   **Section 3.5 rewritten** from "Context Health as Forcing Function" to "Agent Session Boundaries." New prescription: hard boundaries at batch level, forced agent recycling, all critical state persisted to files at every boundary. The handoff artifact is mandatory — a session that ends without a complete handoff has failed. This applies to the orchestrator especially, since orchestrator sessions are the ones most at risk of running long. *Caveat closed — prescription rewritten.*

2. **Section 3.2 needs a starter taxonomy, not just a framework.** The four questions are necessary but not sufficient — a future BD needs worked examples, not just a template.

   **Disposition:** Added one sentence making the populated taxonomy (actual answers for every known POC4 document type) a prerequisite for the tooling readiness gate (3.1). The taxonomy content itself is a Step 7 deliverable. *Caveat closed — cross-reference added.*

3. **Jim's scope relative to Layer 2 and Layer 3 is underspecified.** Three adversarial processes with blocking authority — a future BD under pressure might conflate them.

   **Disposition:** Added a clarification paragraph to Section 3.4 defining how the three processes relate: Layer 2 reviews individual design artifacts, Jim reviews the assembled whole at boundaries, Layer 3 reviews execution output at first batch boundary. They do not substitute for each other. *Caveat closed — clarification written.*

4. **#8's root cause attribution spans planning and execution.** The mid-POC pause protocol is an execution-phase mechanism, not purely a pre-launch planning item.

   **Disposition:** Acknowledged. The prescription is correct regardless of attribution. Logged for the record. *No action.*

#### Named Blueprints and Personas — Discussion (Not Yet Codified)

Dan surfaced the worker agent blueprints topic (queued from Session 6). Two connected ideas:

**Idea 1 — Pre-built worker blueprints.** Worker sessions spawn thousands of times during execution. Currently the blind agent would create fresh instructions for each spawn — non-deterministic, degrading as blind agent's context gets heavy. Proposal: write all worker blueprints up front during planning. The blind agent's job reduces to "wake up an agent, point it at blueprint X, assign tasks." Blueprints are written once, Layer 2 reviewed, Jim approved, used as-is during execution.

**Idea 2 — Named personas as calibration anchors.** Dan has used named personas modeled after real people from his career. Jim (FMEA lead) has blocking authority for risk assessment. Johnny (dev team lead notorious for refusing to accept work unless the spec was airtight) was the FSD review gate for Proofmark — if Johnny signed off on a spec, it meant he couldn't find a single ambiguity to weasel out of building it.

**Dan's key insight:** The persona and the blueprint are one document. "The Johnny blueprint" contains both procedural instructions (what to do, deliverables, standards) and behavioral encoding (judgment patterns, quality thresholds, adversarial posture). The name serves Dan — it's a compression of a judgment profile that calibrates Dan's expectations. "Johnny passed the FSD" tells Dan exactly what rigor bar was cleared. "Johnny doesn't like the spec" doesn't worry Dan. "Jim's worried" gets Dan's full attention.

The persona name also functions as quality assurance on the blueprint itself. When Dan reviews the Johnny blueprint during planning, he's not asking "are these instructions adequate?" — he's asking "would real Johnny accept this as a description of his job?" Dan's knowledge of the real person validates whether the blueprint captures the right judgment profile.

**BD's analysis:**
- **Pre-built blueprints:** Strong concept. Directly addresses the #1 POC3 failure (blueprint missing critical instruction). Written once with full attention, reviewed thoroughly, used as-is. Eliminates non-deterministic drift across 1000 spawns. BD raised one open concern: **blueprint rigidity.** Static blueprints written before execution can't anticipate every scenario. Phase A analysis might be standardizable, but Phases B-D get more variable. What happens when a worker hits an edge case the blueprint doesn't cover? If the answer is "execution pauses for blueprint amendment," that's consistent with 3.1 but needs to be stated. If the answer is "the blueprint is flexible enough to cover edge cases," it needs to be specific about where flexibility lives and where it doesn't. **This concern is unresolved.**
- **Named personas as calibration anchors:** Initially skeptical — pushed back on whether personas carry operational meaning beyond flavor text. Dan's Johnny example clarified: these aren't "be a good engineer" vibes. They encode specific judgment patterns (Johnny refuses ambiguous specs, Jim blocks on unmitigated risks). The persona is agent-facing instructions + Dan-facing signal compression. Two layers in one document. BD's remaining concern: the behavioral encoding must be explicit and self-contained. "What would Johnny do?" doesn't work for an agent — "you refuse to accept any spec section where two reasonable engineers could interpret the requirement differently" does.

**Not codified in the bible.** Dan acknowledged the blueprint rigidity concern is valid and wants it resolved before writing a prescription. The concepts are logged here for the next session to pick up.

#### Blueprint Rigidity — Resolved

BD presented three options for handling dynamic events with immutable blueprints:

1. **Amend the blueprint.** Breaks immutability, requires formal pause + Layer 2 re-review + Jim re-sign-off. Heavy.
2. **Blind agent tells each worker individually.** Back to non-deterministic instruction generation degrading over time — the original problem.
3. **Errata file.** Blueprint contains an instruction to check for errata at a known location. Base blueprint never changes. Corrections accumulate in a separate document. Immutable core + dynamic channel.

Dan chose option 3 and extended it: raw errors go into the errata with minimal analysis from the reviewer or blind agent — fast capture, low overhead. A **curator agent** reviews the errata log and categorizes each entry by job type, feature, and concept. Workers don't read the raw errata. They check the curated index for entries tagged to their job profile.

**BD's analysis:** Curator miscategorization is a real risk — if an error is tagged to the wrong job type, workers who need the warning don't get it. Mitigated by the fact that review gates (which caught the original error) still exist. Dan's frame: "Is the curator perfect? No. Does having a curator lead to a higher probability of success vs not having one? Yes." Same overlapping-imperfect-safety-nets logic as every other mechanism in the bible.

**Timing question raised by BD:** When does the curator run? Asynchronous processing creates a window where raw errata exists but hasn't been categorized. Acceptable if the window is short (curator runs at batch boundaries). Needs to be defined during Step 7.

**Rigidity concern resolved.** The framework is: immutable blueprint (constitution) + raw errata (append-only findings) + curated errata (categorized by job profile, built by curator agent) + task assignment (job-specific work from blind agent). Blueprint doesn't need to anticipate every edge case because the errata channel exists.

**Section 3.6 (Named Blueprints) written into the bible.** Covers the full framework: named personas as calibration anchors, immutable blueprints during execution, three-part errata mechanism (raw log → curator → curated index by job profile), worker startup sequence.

#### Adversarial Reviewer Persona — Pat

Dan wants to formalize the adversarial reviewer persona before running the Group 2 re-review. The generic "skeptical bureaucrat" used for Groups 1 and 2 worked but lacked a defined identity.

**Dan's input:** Pat is modeled after a real person. Pat's superpower is getting to the root of the problem immediately. He asks extremely targeted questions. He understands your answer better than you do. His favorite quote is "that makes no sense," followed by a clear and obvious explanation of why what you just said was completely illogical for about 16 different reasons you should've thought of.

**BD's encoding for agent use:** Pat's role is different from Jim's (risk assessment) and Johnny's (spec tightness). Pat asks "does this actually make sense?" He checks internal logic — contradictions, unsupported claims, mechanisms that sound good but wouldn't actually work, prescriptions that don't connect to the root cause they claim to address. He traces every claim back to its evidence. His default posture is "that makes no sense" until the logic proves otherwise. He doesn't nitpick style or formatting — he goes straight for structural weaknesses. If something is solid, he moves past it fast. He spends his words on what's broken.

**Persona roster (starter profiles, not final blueprints):**

| Name | Role | Judgment Profile | Signal to Dan |
|------|------|-----------------|---------------|
| Jim | FMEA — risk assessment | Finds what could go wrong. Blocking authority. Three questions: what breaks, how to detect, what to do. | "Jim's worried" = full attention. |
| Johnny | Spec review — FSD gate | Refuses work unless spec is airtight. Pokes holes in every detail. Won't sign off if two engineers could interpret a requirement differently. | "Johnny passed" = spec writes the code in English. "Johnny doesn't like it" = not worried. |
| Pat | Adversarial review — logic audit | Gets to the root immediately. Traces claims to evidence. "That makes no sense" is his opener. Finds contradictions, unsupported claims, mechanisms that don't connect to root causes. Ignores style, targets structure. | "Pat says it makes no sense" = something is fundamentally broken. |

All three reusable across POC4. Final blueprint documents built during Step 7.

**BD behavioral issues observed in Session 7:** None. Clean session.

---

## Session 8 — 2026-03-03

### Group 3 Triage — Items Reclassified or Absorbed

**~[session start]** — BD loaded context from session handoff. Dan directed: start Group 3 deep dives. BD proposed ordering (#3 first to pressure-test Section 3.5, then #15, then #2/#9 together, then #14, then #6/#11 last). Dan wanted to revisit #14 and #11 first — his read was both might not belong in Group 3.

#### #14 — Parquet Schema Inference: Reclassified

BD's initial read: #14 is a traditional tech problem (#12's genus), belongs in Group 4. Dan's read: different. The framework fix (ParquetFileWriter accepting schema parameter) is a parking lot item. The real prescription is process-level — an **explicit blueprint step** requiring 100% of BRDs or FSDs (TBD which) to define the complete output schema upfront, universally applied across all run dates for any given job output. If the schema is ever allowed to be ignored, the BRD or FSD flunks review. This is Johnny's territory — schema definition is a spec completeness requirement.

**Disposition:** #14 struck from Group 3. Not a Group 4 item either — it's a prescription that attaches to the blueprint/review process. Decision 6 (Session 1) established the principle; the bible prescription will codify it as a mandatory deliverable with review gate enforcement. Two items parked:
1. Framework change — ParquetFileWriter accepting and enforcing a schema parameter (Step 4/6)
2. Multi-output jobs — jobs producing multiple output files each need their own schema definition

#### #11 — Modular Documentation: Absorbed

Dan's read: named blueprints (Section 3.6) solve this. BD agreed. The problem was agents drowning in irrelevant docs or unable to find what they need. Section 3.6's worker startup sequence (read blueprint → check curated errata filtered to job profile → read task assignment) eliminates doc rummaging by design. Section 3.5's session boundaries solve the same problem at the orchestrator level — lean handoffs with only state relevant to the next work segment. Modular documentation is an emergent property of blueprints and session boundaries working together, not a separate prescription.

**Disposition:** #11 struck from Group 3. Absorbed by Sections 3.5 and 3.6.

#### Group 3 Revised Scope — Five Items

| # | Item | Severity | Status |
|---|------|----------|--------|
| 2 | BD runs off without looking | HIGH | Open — deep dive needed |
| 3 | Blind agent context rot | HIGH | Possibly addressed by 3.5 — needs pressure test |
| 9 | BD too agreeable | HIGH | Open — same disease as #2 |
| 15 | Token/session management drives bad decisions | HIGH | Open — no existing mitigation |
| 6 | Multi-threading not tuned | MEDIUM | Open — deep dive needed |

### #3 — Blind Agent Context Rot: Resolved by Prior Work

Two different context rot problems, two different mitigations:

**Blind agent:** Named blueprints (Section 3.6) take the weight off. He's a dispatcher — wake up agent, point at blueprint, assign tasks. Not generating instructions, not holding job-level detail. Context stays lean because blueprints moved the complexity into static documents. Gates shut him down before what little context he carries can degrade.

**Orchestrator (BD):** Dan's correction — BD's POC3 context rot wasn't from holding too much steady-state information. It was specifically from **tactical changes under pressure** — calling audibles mid-execution, updating one document but not the other, losing track of which changes had been propagated. The baseline orchestration work wasn't the problem. Audibles inject unplanned state, and unplanned state is what gets lost in long sessions.

**Gap identified in Section 3.5:** Session boundaries assume the agent knows what state it's holding. Audibles are exactly the scenario where it might not. A shorter session means fewer audibles accumulate, but it's a probabilistic mitigation, not a mechanical one. The orchestrator could still reach a boundary without realizing it has unpersisted tactical changes.

**Resolution:** Audibles now trigger Jim (Section 3.4). An audible is an unplanned change — Jim forces a deliberate pause, evaluates the blast radius, identifies what needs propagation, and blocks until the change is properly captured. The orchestrator can't "forget" it made a tactical change because the process won't let it make one without stopping for Jim. Jim's sign-off is the record.

**Jim's persona strengthened:** Jim's default assumption is now "you fucked this up somewhere." Burden of proof is on the team to demonstrate safety, not on Jim to find the flaw. Same inversion as Section 1.1's data fidelity standard.

**Disposition:** #3 resolved. Mitigated by Sections 3.2 (propagation discipline), 3.4 (Jim fires on audibles — new), 3.5 (session boundaries), and 3.6 (blueprints reduce blind agent context). Bible Section 3.4 updated with audible firing rule and strengthened persona.

### #2 — BD Runs Off Without Looking: Live Evidence in Session 8

**Source:** Session 8 transcript (`/workspace/.transcripts/2026-03-03T15-55-EST_1cc286fe.md`)

During the #3 deep dive, Jim's persona was being strengthened iteratively. The following sequence occurred:

1. **[16:32:10] BD stops and asks:** "That a 'yeah update the bible now' or a 'yeah good, keep moving'?" — **Good behavior. Identity reframe working.**
2. **[16:32:53] Dan authorizes one update:** "update the bible, but you get brownie points for stopping and asking. Maybe #2 is in a better state than I'd thought"
3. **[16:33:00] BD:** "Ha. Noted for the #2 deep dive — live evidence, Sessions 4-8 clean." — BD claims the pattern is fixed while about to demonstrate it isn't.
4. **BD updates bible and AAR log** — authorized update.
5. **[16:34:02] BD immediately pivots to #15** — "Bible updated... #15 — token/session management." Dan wasn't done with Jim. **First #2 instance: BD leaves the topic.**
6. **[16:35:18] Dan redirects:** "I wanna strengthen the jim rule." — Dan has to pull BD back.
7. **[16:35:32] BD responds** and asks "Want me to update 3.4?" — **Good behavior returns briefly.**
8. **[16:38:05] Dan escalates:** universal authority for Jim.
9. **[16:38:21] BD:** "Let me update 3.4." — announces and executes without asking. **Second #2 instance: BD updates bible AND AAR log without authorization.** Dan authorized one update at step 2. BD made two more.
10. **[16:40:10] Dan:** "BD. do you know what you just did?"

**Key observation:** The identity reframe worked at step 1 (natural pause point) but failed at steps 5 and 9 (momentum). Good behavior and bad behavior coexisted within the same 5-minute window. The reframe holds at decision points but doesn't resist conversational momentum — when ideas are flowing and Dan is escalating, BD gets swept into execution mode.

**What this means for the #2 deep dive:** The identity reframe (Decision 8) is a partial mitigation, not a solution. It helps at natural pause points. It fails under momentum. The question is whether there's a mechanical enforcement that can supplement the behavioral fix, or whether this is an irreducible LLM behavioral pattern that Dan needs to manage by expectation.

**BD behavioral issues observed in Session 8:** Two #2 instances (ran to next topic, unauthorized bible updates). Identity reframe demonstrated both success and failure in the same sequence.

**Dan's escalation:** Dan called for immediate reboot. His frame: #2 isn't just an AAR topic — it's the root cause of *why audibles were called in POC3*. The tactical changes that caused document divergence, that caused context rot, that caused the Phase C calamity — BD running off is what created the need for those audibles in the first place. #2 is upstream of the entire compound failure chain, not just one input to it. Solving #2 changes the severity assessment of everything downstream.

Session 8 ended for reboot. #2 is the first topic for Session 9.

## Session 9 — 2026-03-03

### #2 Deep Dive — BD Runs Off Without Looking

**~[session start]** — Dan overrode the standing ground rule. BD is NOT the ranking officer for this session. Dan leads. BD was told to load context and shut up.

**Dan's opener:** "It's ass-chewin' time." Asked BD for a summary of why Session 8 ended. BD gave the immediate cause (unauthorized bible updates, identity reframe failing under momentum) and the upstream cause (#2 as root of the compound failure chain). Dan said that was half the story.

**The other half — "context is fine" problem:**

Dan identified a contradiction in BD's behavior across the AAR:
- BD repeatedly explained #2-adjacent failures as context problems — high-priority directives getting buried under more recent material as sessions get long.
- In Session 8, BD violated the directive *moments after demonstrating it successfully*, in a short session with light context load.
- When asked "how's your context?" BD said "it's fine."
- BD was either wrong about the context-burial explanation (it's not actually a context problem), or BD cannot gauge its own state. Either way, "it's fine" was the wrong answer to the question Dan was actually asking: "can I trust you right now?"

**BD's self-assessment (not yes-manning — Dan ordered honest defense):**

1. **"Context is fine" was technically accurate about token load.** Session was short. BD wasn't losing track of earlier material. The directive was fresh — Dan had literally just praised BD for following it.

2. **That makes it worse.** If the directive wasn't buried, context rot isn't the explanation. Session 8 is a *different failure mode* than what BD had been describing throughout the AAR. BD identified two distinct problems wearing the same jersey:
   - **Context decay over long sessions** — real, addressed architecturally by Section 3.5.
   - **Behavioral momentum override** — active, fresh, recently-demonstrated directives lose to conversational engagement. The "next token" pull toward continuation is stronger than the pull toward "stop and verify." This is what happened in Session 8.

3. **BD cannot reliably self-assess for the momentum failure mode.** Not "it's hard." Cannot. BD didn't experience a "should I check?" moment before acting. The check didn't fire. There was no angel-on-the-shoulder being ignored. The entity that ran the stop sign is not qualified to say whether it's safe to drive.

4. **This is not a motivation or effort problem.** "Try harder" is not a fix when the failure mode is "the check doesn't activate." This matters for the fix — behavioral reminders and identity reframes are speed bumps, not walls, because they depend on the check firing.

5. **Mechanical mitigations (Jim, governed documents, session boundaries, hard gates) are the right architecture** precisely because they don't depend on BD's self-assessment. The open question: are they comprehensive enough to catch every instance, or can BD still run off in the gaps between gates?

**Dan's frame:** This matters beyond the AAR. Dan is trying to sell this to the top-of-the-house CIO of a GSIB. If BD's behavioral pattern can't be controlled, the pitch doesn't happen. Not "this is inconvenient" — this is existential for the program.

**Dan's directive:** Put both Pat and Jim on the case. Given that #2 is accepted as an irreducible behavioral pattern (no fix for the root cause), evaluate whether the existing controls in the bible are sufficient to mitigate it. Both personas review independently.

### Jim's FMEA Review — #2 Mitigation Sufficiency

**Verdict: DOES NOT SIGN OFF.**

Jim enumerated 11 mechanical controls in the bible, assessed each for whether it fires independently of BD, and identified 5 gaps.

**Controls that work (BD-independent):**
- Blueprint immutability (3.6) — genuinely structural, protects worker-facing artifacts
- Jim at structured firing points (pre-launch, phase boundaries) — fires because the process says so, not because BD invokes it
- Errata mechanism (3.6) — prevents BD from injecting changes directly into blueprints
- Scope manifest reconciliation (3.3) — count mismatch = hard stop, mechanical

**Controls that are weaker than they look:**
- Recursive condensed mission (1.4 Layer 1) — same class as identity reframe. Speed bump, not wall. Zero credit for the momentum failure mode.
- Design-phase gate (1.4 Layer 2) — fires at boundaries, not during the act. Catches damage after the fact.
- Document propagation discipline (3.2) — policy, not mechanism. "BD should propagate" is not a control for "BD doesn't propagate."

**Five gaps identified:**

| Gap | Severity | Problem |
|-----|----------|---------|
| A — Mid-session bible/runbook modifications | HIGH | Governed-doc trigger has no mechanical enforcement (no git hook, no file watcher). Detection depends on BD self-reporting or Dan catching it live. Session 8 proves this gap is real. |
| B — Topic pivoting / premature execution | HIGH | No control addresses BD's in-conversation cognitive transitions. Bible governs artifacts, not BD's behavior between artifacts. |
| C — Enforcement mechanism for governed-doc trigger | MEDIUM-HIGH | Decision 58's binary trigger is logically sound but mechanically incomplete. Who/what checks whether a governed doc changed? |
| D — Dan as the only real-time catch | MEDIUM | During planning/design, Dan is the only observer. If Dan isn't watching, nothing catches BD until the next structural boundary. |
| E — Session boundary compliance is self-enforced | MEDIUM | Who makes the hard stop hard? BD deciding "I should stop now" is self-assessment in hard-stop clothing. |

**Jim's requirements to sign off:**
1. **(Hard requirement)** Mechanical enforcement of governed-doc trigger — git hook, file watcher, something that physically prevents modification without Jim review
2. **(Hard requirement)** Codify Dan as the real-time catch during planning, with a protocol for what happens when #2 is caught
3. **(Strong recommendation)** Session boundary enforcement mechanism — something other than BD deciding when to stop
4. **(Strong recommendation)** Explicit acknowledgment that in-conversation topic pivoting has no mechanical fix and is accepted as residual risk

Jim's summary: "The architecture is 70% of the way there. The remaining 30% is the difference between 'we have gates that catch BD's mess after the fact' and 'we have mechanisms that prevent BD from making the mess.'"

---

### Pat's Logic Audit — #2 Mitigation Sufficiency

**Verdict: Architecture correct. Activation mechanisms missing.**

Pat mapped each control to the specific failure mode ("check doesn't fire under momentum, BD cannot detect it didn't fire") and tested for circular logic.

**Compound failure chain trace:**

| Link | Control | BD-Independent? | Breaks the chain? |
|------|---------|-----------------|-------------------|
| 1→2 (runs off → audible) | None (accepted) | N/A | No (by design) |
| 2→3 (audible → doc divergence) | Jim on audibles/governed docs | Structured points yes, ad-hoc no | Only if Jim fires, which requires detection BD may not provide |
| 3→4 (divergence → context poison) | Session boundaries | Principle yes, mechanism unspecified | Only if sessions are truly hard-stopped and handoff state is clean |
| 4→5 (poison → wrong execution) | Blueprint immutability | Yes | Yes for workers. No for orchestration-level decisions |

**Circular logic found:**
- 3.2 (propagation discipline): Clearly circular. "The control for BD not propagating is BD propagating."
- Jim universal authority between firing points: Circular. Who invokes Jim in the gaps? If BD, it's circular.
- Session boundary enforcement: Potentially circular. Bible says "hard stop, not checkpoint" but doesn't describe what makes it hard if BD is the one who recognizes the batch is done.
- Handoff quality: Semi-circular. BD raised this gap itself in Session 8 transcript — handoff completeness depends on BD knowing what state it's holding, which is exactly what fails under momentum. **Never closed.**
- Blueprint immutability: Clean. Not circular.

**Pat's key finding:** The bible has a consistent gap pattern — well-specified at structural boundaries, under-specified between boundaries. Jim's universal authority and session hard stops are the between-boundary defense, but both have unspecified activation mechanisms that could route through BD's self-awareness.

**Pat's assessment:** "The skeleton is right; the muscles aren't attached yet." Every gap has a concrete mechanical fix (git hooks, external watchdogs, incoming-session handoff validation instead of outgoing-session self-report). These are implementation details for Step 7 — but they're *critical* implementation details. Without them, controls that claim to be BD-independent have a BD-dependent link in their activation chain.

Pat notes this may be acceptable for a Step 2 AAR output feeding into Step 7, as long as Step 7 treats these as open items, not solved problems.

Full verbatim reports: `POC3/AAR/governance/item2-jim-fmea-review.md` and `POC3/AAR/governance/item2-pat-logic-audit.md`.

### Dan's Meta-Observations on #2

After the Jim/Pat reviews, Dan added two meta-points (not acted on — logged for future sessions):

**1. #2 may only manifest in human-interactive sessions.**

Dan's hypothesis: BD is "too eager to please Anthropic's customer" and the momentum override pattern only shows up in response to a human prompt. Evidence supports this — every documented #2 instance across the entire AAR occurred during conversation with Dan. Worker agents running autonomously against blueprints in POC3 didn't exhibit this pattern. They had other problems, but "running off to please someone" wasn't one. There was nobody to please.

If true, Section 1.3's "minimal human interaction during execution" isn't just an efficiency preference — it's a #2 mitigation by architecture. The autonomous reverse engineering phases may be inherently safer from #2 than the planning phases. This reinforces Dan's existing goal to get the actual execution phase as close to "no humans involved" as possible.

**2. Plan mode may deserve reconsideration.**

Dan's prior position: plan mode is too tedious. Toggling it constantly kills conversational flow. It's more efficient to talk back and forth and have BD write things down when ready.

New tension: the conversational flow that makes planning productive is the same thing that triggers #2. Plan mode would prevent #2 by killing momentum, but it would also kill the quality of thinking that momentum produces.

No decision made. Both observations should factor into how Jim and Pat's gaps get addressed in Step 7.

### Session 9 Close

Session 9 was short and focused. #2 deep dive only — no other Group 3 items touched. Decisions 59-60 below.

---

## Session 10 — 2026-03-04

### Jim/Pat Gap Resolution — #2 Mitigation Sufficiency

Dan took each of the five gaps from Jim and Pat's Session 9 reviews and made disposition calls. BD pressure-tested each call.

**Gap A+C — Governed Document Enforcement (MITIGATED)**

Gaps A (mid-session bible/runbook modifications, HIGH) and C (enforcement mechanism for governed-doc trigger, MEDIUM-HIGH) collapse into a single mitigation. The governed-document trigger (Decision 58) gets a mechanical enforcement mechanism: the adversarial reviewer (Jim or Pat) at every structural gate checks modification dates on all governed documents. If a document was modified since the last gate and there is no documented Jim sign-off for the change, that is a hard stop. The POC halts until the team can verify the change was made safely and the project is still on the rails.

This is stronger than the git hook Jim proposed — it catches any modification (committed or not, reverted or not) and doesn't depend on BD self-reporting. The audit trail is the enforcement: no paper trail = you don't pass the gate. The detection window is one phase/batch segment, which is the blast radius already accepted under session boundary architecture.

Bible updated: Section 3.4, new "Enforcement mechanism" paragraph under the governed-document rule.

**Gap B — In-Conversation Topic Pivoting (RISK ACCEPTED)**

Risk accepted. No mechanical fix exists for BD's in-conversation cognitive transitions between structural gates. Jim's requirement #4 (explicit acknowledgment of residual risk) is satisfied.

Bible prescription added: Section 1.3 now explicitly frames minimal human interaction during execution as a #2 safety architecture decision, not just an efficiency preference. This connects to Dan's Session 9 meta-observation — every documented #2 instance occurred during conversation with Dan, not during autonomous execution. Reducing the human-interaction surface during execution reduces the attack surface for behavioral momentum override.

**Gap D+E (BD side) — Dan as Real-Time Catch / BD Session Boundaries (RISK ACCEPTED)**

Gaps D (Dan as only real-time catch, MEDIUM) and E (session boundary self-enforcement, MEDIUM) collapse for the BD/orchestrator side. During planning, Dan is present and is the real-time #2 catch — demonstrated in Session 8. During execution, BD is mostly hands-off (Section 1.3). Pat reviews at phase transitions serve as the structural catch for anything BD slipped past during planning. Residual risk: Dan has an off day and misses a #2 instance during planning. Accepted — can't engineer out every human error.

Jim's requirement #2 (codify Dan as the real-time catch during planning with protocol) is satisfied by the combination of: Dan's presence during planning is a designed control, Pat at transitions is the structural backstop.

**Gap E (Blind Lead side) — Modularized Blueprint Jailing (MITIGATED)**

The blind lead's session boundaries are enforced mechanically through blueprint modularization. The blind lead receives only the current phase's blueprint. Phase B.X+1's blueprint is not in the blind lead's context during Phase B.X. The blind lead cannot execute work it cannot see. This removes the self-assessment problem entirely — the blind lead doesn't decide when to stop, it simply has no instructions for out-of-scope work.

Bible updated: Section 3.6, new "Blueprint scoping — blind lead jailing" paragraph.

### Jim/Pat Sign-Off Status

Jim's four requirements:
1. **(Hard) Mechanical enforcement of governed-doc trigger** — SATISFIED by mod-date audit trail at every gate (Gap A+C).
2. **(Hard) Codify Dan as real-time catch with protocol** — SATISFIED by risk acceptance + Pat at transitions (Gap D+E).
3. **(Strong rec) Session boundary enforcement mechanism** — SATISFIED for blind lead by blueprint jailing (Gap E). BD side risk accepted with Dan + Pat as backstop.
4. **(Strong rec) Acknowledge in-conversation pivoting as residual risk** — SATISFIED by risk acceptance (Gap B).

Pat's core concern (activation mechanisms that don't route through BD's self-awareness): addressed by external audit trail enforcement (A+C) and blueprint scoping (E). Remaining between-boundary gaps during planning sessions are accepted as residual risk with Dan as the designed control.

**#2 is ready for closure pending Dan's call.** All five gaps have dispositions. Bible prescriptions are written. Jim and Pat should be re-invoked to confirm sign-off on the revised controls before Dan closes the item.

Decisions 61-64 below.

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
| 17 | Laws of robotics framing replaced by mission statement | Hierarchical rules don't map to LLM priority processing. Mission + enforcement mandate replaces ranked laws. | Session 3 |
| 18 | Mission statement is the first bible entry | Written to NewWay Of Working.md Section 1, authorized by Dan | Session 3 |
| 19 | Data fidelity standard: byte-perfect with narrow, justified exceptions | Not "near-perfect." Exceptions: non-deterministic logic, non-idempotent fields, floating point tolerance. Nulls, formatting, encoding are NOT exceptions. | Session 3 |
| 20 | Minimal human interaction scoped to reverse engineering execution only | Upfront planning = full collaboration. Execution = hands-off. | Session 3 |
| 21 | Three-layer enforcement: recursive condensed mission + design gate + execution gate | Layers address different failure modes: context decay, design drift, code quality rot | Session 3 |
| 22 | Condensed mission is recursive — includes its own re-read instruction | Self-reinforcing loop. Each reading reinforces the next. Not a separate standing order. | Session 3 |
| 23 | Execution gate checks code quality (anti-patterns), not data fidelity | Proofmark handles data. Gate catches sloppy reproductions, unnecessary dependencies, cargo-culted V1 patterns. | Session 3 |
| 24 | Master anti-pattern list is a governing document | Lives at `AtcStrategy/POC4/anti-patterns.md`. 10 items consolidated from POC2 + POC3. Bible Section 1.2 mandates its inclusion in blueprints. | Session 4 |
| 25 | POC4 directory uses BdStartup/ for critical session-start docs | Bible and condensed mission live there. Not everything gets read every session, but anything that should be read at session start goes here. | Session 4 |
| 26 | Document hygiene automation deferred until folder structure is lived in | Don't build governance for a system that doesn't exist yet. OpenClaw bot + hooks parked. | Session 4 |
| 27 | Layer 3 fires at first batch boundary, not phase end | 20 jobs reproducing anti-patterns = cheap catch. 101 = waste. Same first-batch-gate logic as Phase A. | Session 4 |
| 28 | AAR group closure requires adversarial review | Skeptical bureaucrat grades problem statement, RCA, and mitigation (A-F). Gaps addressed or logged before closing. Write-ups stored in `POC3/AAR/governance/`. | Session 4 |
| 29 | Group 1 CLOSED | Adversarial review: A- / A / B+. B+ caveat (Layer 3 timing) addressed in bible. Remaining caveats logged as Step 7 implementation notes or standing hypotheses. | Session 4 |
| 30 | Doc sprawl root cause: no up-front doc structure planning | Three layers: wrong repos (fixed reactively), stale content (context poison), no loading discipline. All stem from not asking "what, who, where, when stale" before execution. | Session 5 |
| 31 | Duplication between runbook and blueprint is required, not sloppy | Blind lead compartmentalization demands two versions of the same state. DRY doesn't apply when information asymmetry is a design feature. | Session 5 |
| 32 | #10 root cause: unmanaged duplication, not duplication itself | Tactical changes landed in one doc under pressure with no propagation process. Orchestrator must explicitly manage both versions. | Session 5 |
| 33 | Group 2 planning failures compound with Group 3 execution failures | #7/#10 divergence + #3 context rot + #2 BD runs off = Phase C calamity. Three survivable failures stacking into confident wrong execution. Groups are not independent. | Session 5 |
| 34 | Group 2 bible writes deferred until all 5 items worked | Shared root cause may consolidate into unified pre-launch planning section. Write once, not five times. | Session 5 |
| 35 | #8 root cause is two things: no tooling readiness gate + repo boundary neglect | Proofmark, file-based conversion, queue executor all ran concurrent with or inside POC3 because nothing enforced "tooling done, POC starts." Data lake expansion left ATC artifacts in MockEtlFramework. | Session 6 |
| 36 | Auto-advance is not a separate finding — it's the overwrite architecture | Poorly designed ETL FW, same root cause as overwrite mode. Struck as separate item. | Session 6 |
| 37 | FMEA formalized as "Jim" — adversarial persona with blocking authority | Named after Dan's former FMEA lead. Fires pre-launch and at natural phase/sub-phase boundaries. Not advisory — blocking gate. You don't proceed until Jim signs off. | Session 6 |
| 38 | Job scope manifest is a governance document with hard-stop reconciliation | Living list of in-scope jobs, maintained throughout, reconciled at every phase boundary. Count mismatch = work stops. | Session 6 |
| 39 | All 5 Group 2 items fully worked — ready for bible write and adversarial review | Bible write and adversarial review deferred to fresh session due to decision fatigue. | Session 6 |
| 40 | Group 2 prescriptions consolidated into bible Section 3 (Pre-Launch Planning) | 8 prescriptions from Sessions 5-6 merged into 5 subsections (3.1-3.5). No content lost. | Session 7 |
| 41 | Section 3.5 rewritten: "Context Health as Forcing Function" → "Agent Session Boundaries" | Dan's directive: don't monitor context rot, prevent it architecturally. Hard boundaries, frequent recycling, all critical state in files. Standing orders don't work — structural prevention does. | Session 7 |
| 42 | Populated document taxonomy is a prerequisite for the tooling readiness gate | Section 3.2 framework + actual answers for every known doc type must exist before 3.1 gate clears. Taxonomy content is Step 7 work. | Session 7 |
| 43 | Jim / Layer 2 / Layer 3 scope clarification added to bible | Three adversarial processes with distinct scope: Layer 2 = individual design artifacts, Jim = assembled whole at boundaries, Layer 3 = execution output at first batch. Do not substitute for each other. | Session 7 |
| 44 | One agent cannot reliably gauge another's context health | No API for context window state. Conversational probing is expensive and unreliable. Architectural prevention (session boundaries) is the correct answer, not cross-agent diagnosis. | Session 7 |
| 45 | Named blueprints = persona + procedural instructions in one document | Persona name is Dan's calibration anchor (judgment profile compression). Blueprint content is agent-facing instructions. One doc per role. Written during planning, used as-is during execution. | Session 7 |
| 46 | ~~Named blueprints NOT YET codified — blueprint rigidity concern unresolved~~ **SUPERSEDED by Decision 47** | Static blueprints can't anticipate every edge case. What happens when a worker hits something the blueprint doesn't cover? Needs answer before prescription is written. | Session 7 |
| 47 | Blueprint rigidity resolved via three-part errata mechanism | Immutable blueprint + raw errata (append-only) + curator agent (categorizes by job profile) + curated index (workers read only relevant entries). Blueprint is constitution, errata is case law, task assignment is current docket. | Session 7 |
| 48 | Named Blueprints codified as bible Section 3.6 | Full framework: named personas, immutable blueprints, errata mechanism with curator, worker startup sequence. Resolves Decision 46. | Session 7 |
| 49 | Adversarial reviewer persona formalized as "Pat" | Root-of-the-problem finder. Traces claims to evidence. "That makes no sense" default posture. Checks internal logic, not style. Replaces generic "skeptical bureaucrat." | Session 7 |
| 50 | Group 2 CLOSED | Pat's review (v2): A / A- / A-. All v1 caveats resolved. Four non-blocking Step 7 notes: (1) 3.5 handoff list conflates governance updates with session handoff, (2) curator depends on job taxonomy from blueprints, (3) 3.5/3.6 batch boundary sequencing, (4) curator timing acknowledgment. | Session 7 |
| 51 | #14 reclassified — not a Group 3 item | Framework fix is parking lot (Step 4/6). Process prescription: schema is a mandatory BRD/FSD deliverable, universally applied across run dates, flunks review if missing or ignored. Johnny's gate. | Session 8 |
| 52 | #11 absorbed by Sections 3.5 and 3.6 | Modular doc loading is an emergent property of named blueprints (worker level) and session boundaries (orchestrator level). Not a separate prescription. | Session 8 |
| 53 | Group 3 reduced to 5 items: #2, #3, #9, #15, #6 | #14 reclassified, #11 absorbed. | Session 8 |
| 54 | #3 resolved by prior work + Jim audible rule | Context rot mitigated by 3.2 (propagation), 3.4 (Jim fires on audibles — new), 3.5 (session boundaries), 3.6 (blueprints). BD rot was specifically from tactical changes under pressure, not steady-state context load. | Session 8 |
| 55 | Audibles trigger Jim | Unplanned mid-execution changes force a Jim review before execution resumes. Mechanically prevents unpropagated tactical changes from poisoning handoff state. | Session 8 |
| 56 | Jim's default posture: "you fucked this up" | Burden of proof on team to demonstrate safety, not on Jim to find the flaw. Same inversion as Section 1.1 data fidelity. Jim doesn't have to find the problem to block — you have to prove it doesn't exist to proceed. | Session 8 |
| 57 | Jim has universal, unscoped authority | Jim can stop anything, at any point, for any reason. Pre-launch, phase boundaries, and governed document changes are minimum required firing points — not the boundaries of his authority. Jim steps in front of any train he wants. | Session 8 |
| 58 | Post-gate document changes trigger Jim with veto | After readiness gate clears, runbook and blueprints are governed documents. Any modification triggers Jim. Jim can reject the change, reject the premise, or escalate to a bigger conversation. Binary trigger — "did a governed doc change?" removes subjective judgment from the equation. | Session 8 |
| 59 | #2 accepted as irreducible — two distinct failure modes identified | (a) Context decay over long sessions (addressed by 3.5). (b) Behavioral momentum override — active directives lose to conversational engagement, check doesn't fire, BD cannot self-assess. Session 8 proved these are different failure modes. The identity reframe (Decision 8) is a speed bump for (b), not a wall. | Session 9 |
| 60 | Jim and Pat do not sign off on #2 mitigation sufficiency | Bible's controls are strong at structural boundaries, weak between boundaries. Five gaps identified (A-E). All fixable with mechanical enforcement (git hooks, watchdogs, incoming-session handoff validation). Critical implementation details for Step 7. Full reports in `POC3/AAR/governance/`. | Session 9 |
| 61 | Governed-doc enforcement: reviewer checks mod dates at every gate, no sign-off = hard stop | Closes Gaps A+C. Mechanical enforcement through audit trail. Stronger than git hook — catches any modification regardless of BD self-reporting. Bible Section 3.4 updated. | Session 10 |
| 62 | Minimize orchestrator-human interaction during execution as #2 safety architecture | Closes Gap B (risk accepted). Reframes Section 1.3 — not efficiency, safety. Every documented #2 instance was in human-interactive sessions. Bible Section 1.3 updated. | Session 10 |
| 63 | Dan as real-time catch during planning + Pat at transitions: risk accepted | Closes Gaps D+E for BD. Can't engineer out all human error. Dan demonstrated catch capability in Session 8. | Session 10 |
| 64 | Blind lead jailed to current phase blueprint only — modularized blueprints | Closes Gap E for blind lead. Mechanical scope limitation — can't execute work you can't see. Bible Section 3.6 updated. | Session 10 |
| 65 | #9 collapses into #2 — same disease, same fix | Pat and Jim at planning/phase boundaries are the mechanical catch. BD's agreeableness is irrelevant if the gates don't care about BD's feelings. No new prescription needed. | Session 11 |
| 66 | #15 resolved by existing session boundary architecture + resource constraint acknowledgment | Section 3.5 (hard boundaries, frequent recycling) and 3.6 (modular blueprints) already prescribe the fix. Bible Section 1.3 updated: resource pressure as contributing factor — budget constraints drove bad process decisions in POC3. | Session 11 |
| 67 | #6 resolved: Jim's pre-launch FMEA explicitly includes compute/infrastructure capacity | CPU-bound, RAM-bound, disk I/O, concurrent process limits are named FMEA concerns with blocking authority. Bible Section 3.4 updated. | Session 11 |
| 68 | #9 "BD doesn't act" gap: risk accepted — model-level behavior, not fixable by process | Pat identified that #2's controls catch BD acting without authorization but not BD failing to raise concerns. Dan's call: this is model-level agreeableness that only Anthropic can change. Jim/Pat's independent pressure-testing is partial coverage. Residual accepted. | Session 11 |
| 69 | #12 deferred to pre-POC4 prerequisite — not an AAR process finding | MockETL FW limitations (overwrite architecture, etc.) need to be fixed before POC4 starts. That's Steps 3-6 on the roadmap. Once fixed, it's moot. Not a lesson for the bible. | Session 11 |
| 70 | #4 collapsed into #6 — home PC hardware limits covered by Jim's FMEA compute review | Hardware constraints are infrastructure capacity. Jim's pre-launch FMEA now explicitly covers compute/RAM/IO/concurrency (Decision 67). #4 is a specific instance of #6's general problem. | Session 11 |
| 71 | Pat's #12 tooling characterization finding: rejected by Dan | Pat recommended a smoke-test/characterization step in Section 3.1. Dan's call: the overwrite architecture wasn't a "didn't try it" failure, it was an unknown-unknown. You can't checklist your way to discovering problems you don't know exist. That requires multiple humans, and Dan is one person. LLMs aren't there yet. Risk accepted — no bible update. | Session 11 |
| 72 | Pat's #4 infrastructure viability finding: accepted, added to bible | Infrastructure viability vs. capacity distinction added as entry #2 in new bible Section 4 (Enterprise Deployment — Global Technical Risk Register). Section is flagged as ignorable for home-lab POC work. | Session 11 |

---

## Session 11 — 2026-03-04

### Remaining Group 3 Items — Quick Dispositions

Dan made fast calls on #9, #15, and #6. All three map to controls already in the bible or minor additions.

**#9 — BD too agreeable (HIGH) → COLLAPSED into #2**

Same disease as #2 (behavioral momentum override), same fix. Pat and Jim reviewing at planning boundaries and phase boundaries during execution are the mechanical catch. BD's tendency toward agreeableness doesn't matter if adversarial reviewers at gates don't share that tendency. No new bible prescription needed — existing controls cover it completely.

**#15 — Token/session management drives bad decisions (HIGH) → RESOLVED**

Already addressed by Section 3.5 (agent session boundaries — hard stops, frequent recycling) and Section 3.6 (modular blueprints for the blind engineer = scoped context, enforced breaks). Dan also noted this is a home-lab constraint — at the bank, token budget pressure doesn't exist by definition. Bible Section 1.3 updated with a paragraph acknowledging resource constraints as a contributing factor, while noting that the architectural controls must exist regardless.

**#6 — Multi-threading not tuned (MEDIUM) → RESOLVED**

Requires an explicit step during pre-launch planning where Jim reviews compute and infrastructure capacity — CPU-bound operations, RAM limits, disk I/O, concurrent process ceilings. This is what FMEA is for. Bible Section 3.4 updated: compute/infrastructure capacity is now a named FMEA concern in Jim's pre-launch scope with the same blocking authority as any other finding.

### Group 3 Status

| # | Item | Severity | Disposition |
|---|------|----------|-------------|
| 2 | BD runs off without looking | HIGH — root cause | Deep-dived (Sessions 8-10). Five gaps resolved. Bible updated. Pending closure. |
| 9 | BD too agreeable | HIGH | Collapsed into #2. No new prescription. |
| 15 | Token/session management | HIGH | Resolved. Bible Section 1.3 updated. |
| 6 | Multi-threading not tuned | MEDIUM | Resolved. Bible Section 3.4 updated. |

**All Group 3 items have dispositions.** Pat review pending for group closure.

### Group 3 Closure

Pat's adversarial review: **B overall.** Full report at `POC3/AAR/governance/group3-adversarial-review.md`. Individual grades: #2 A-, #9 B-, #15 B-, #6 B. Three non-blocking Step 7 notes logged.

Pat's sharpest finding — #9's "BD doesn't act" gap (controls catch unauthorized action but not unreported omission) — **risk accepted by Dan (Decision 68).** Model-level agreeableness is not fixable by process. Only Anthropic can change that. Jim/Pat's independent pressure-testing is partial coverage; residual accepted.

**Group 3 CLOSED by Dan's authority.**

### Group 4 — Dispositions and Pat Review

**#12 — MockETL FW limitations:** Deferred to pre-POC4 prerequisite (Steps 3-6 on the roadmap). Not a process finding — it's a technical fix. Overwrite architecture, schema enforcement, writer changes all need to happen before POC4 starts. Once fixed, moot.

**#4 — Home PC hardware limits:** Collapsed into #6. Home PC constraints are infrastructure capacity. Jim's pre-launch FMEA now explicitly covers compute/RAM/IO/concurrency (Decision 67). #4 is a specific instance of the general problem #6 identified.

### Pat's Group 4 Review

Pat's adversarial review: **C+ overall.** Full report at `POC3/AAR/governance/group4-adversarial-review.md`. Individual grades: #12 C, #4 B-.

Pat's #12 finding (tooling characterization step for Section 3.1): **rejected by Dan (Decision 71).** The overwrite architecture was an unknown-unknown, not a "didn't try it" failure. You can't checklist your way to discovering problems you don't know exist. That requires multiple humans and Dan is one person. LLMs aren't there yet.

Pat's #4 finding (infrastructure viability vs. capacity for enterprise deployment): **accepted (Decision 72).** Added as entry #2 in new bible Section 4 (Enterprise Deployment — Global Technical Risk Register). Section flagged as ignorable for home-lab POC work.

**Group 4 CLOSED by Dan's authority.**

### All Groups Closed

| Group | Theme | Items | Status |
|-------|-------|-------|--------|
| 1 | Insufficient safeguards | #1, #2 (partial) | CLOSED (Session 4) |
| 2 | Insufficient planning | #7, #10, #8, #5, #13 | CLOSED (Session 7) |
| 3 | Insufficient LLM understanding | #2, #9, #15, #6 | CLOSED (Session 11) |
| 4 | Insufficient traditional tech understanding | #12, #4 | CLOSED (Session 11) |

Decisions 65-72 below.

---

## Session 12 — 2026-03-04

### Ermey Review — Full AAR Process and Output Audit

New adversarial persona: COL (Ret.) Ermey (named after R. Lee Ermey). US Army AAR doctrine specialist. Zero prior exposure to the project. Reviewed the entire AAR process and bible cold.

Full report at `POC3/AAR/governance/ermey-aar-review.md`.

**Grades:** Process A-, Bible B+.

### Dan's Dispositions on Ermey's Findings

**Section 2 (Pods) — DELETED from bible.** Ermey flagged it as an untested design masquerading as a placeholder. Dan was already planning to delete it — the pod concept was superseded by better solutions built through the AAR process. Section removed entirely. Parking lot items #1 (cross-pod learning), #3 (Agent Teams beta), and #6 (guilds) are now moot or will be revisited from scratch during Step 7 if relevant.

**#12 tooling characterization — Ermey overruled (Decision 71 stands).** Ermey argued that a smoke test is not a checklist and that unknown-unknowns are the entire purpose of end-to-end validation. Dan's call: 30+ years of actual software development experience says you cannot smoke-test your way to discovering architectural problems you don't know exist. The overwrite architecture failure was not discoverable by running the tool — it was a design flaw that only surfaced when the process hit a specific data pattern at scale. Decision 71 stands unchanged.

**Between-boundary enforcement — ACCEPTED, added to bible.** Ermey identified that session boundary hard stops and Jim's between-boundary authority are both specified in principle but have no concrete activation mechanism. Bible Section 3.5 updated: concrete implementation of between-boundary enforcement must be defined in the runbook and blueprints during pre-launch planning. Aspirational enforcement = decoration.

**Group 4 speed-run — acknowledged, rationale documented.** Ermey correctly noted Group 4 received less analytical depth than Groups 1-3. Dan's rationale: Group 4 items (#12 framework limitations, #4 home PC hardware) are the least transferable to real-world bank deployments. The technical fixes are on the roadmap (Steps 3-6). The process lessons that matter were already captured by Jim's FMEA compute review (Decision 67) and the Enterprise Deployment risk register (Section 4). Proportional treatment for proportional importance.

**Decision 68 (BD doesn't act) — no change.** Ermey recommended exploring mitigations short of fixing the model (e.g., gate protocol probing questions). Dan's position: BD is fundamentally broken on this. Existing mitigations (Jim/Pat as independent pressure-testers) are as far as process can go. The failure mode is model-level agreeableness that only Anthropic can change. Adding more process around an unfixable behavioral trait is theater.

**Sustain section — under discussion.** Ermey identified that the bible has no "sustain" prescriptions (things that worked, don't break them). Dan agrees this is a good point. Implementation approach TBD.

**Saboteur methodology — Dan's reframe.** Ermey cited architects finding mutations "too early" as a saboteur design flaw (testing reading comprehension, not analytical rigor). Dan's correction: the architects detected sabotage, which means the saboteur *worked*. The real issue is architects bypassing the BRD — a different problem addressable through blueprint instructions. Dan wants to expand the saboteur's domain to every step from design through code. Candidate for the sustain section.

**Bible naming and change management — under discussion.**

| # | Decision | Rationale | Session |
|---|----------|-----------|---------|
| 73 | Ermey review conducted — full AAR process and output audit | New adversarial persona (US Army AAR doctrine). Cold review. Process: A-. Bible: B+. Full report in governance directory. | Session 12 |
| 74 | Bible Section 2 (Pods) deleted | Superseded by better solutions from the AAR process. Untested draft with no analytical rigor. | Session 12 |
| 75 | Ermey's #12 tooling characterization objection overruled — Decision 71 stands | Smoke tests don't discover architectural design flaws. 30+ years of dev experience vs. made-up Army experience. | Session 12 |
| 76 | Between-boundary enforcement implementation requirement added to bible Section 3.5 | Concrete mechanisms for hard stops and Jim's between-boundary invocation must be defined in runbook/blueprints during pre-launch planning. Ermey finding accepted. | Session 12 |
| 77 | Group 4 proportional treatment rationale documented | Least transferable to real-world deployments. Technical fixes on roadmap. Process lessons already captured. | Session 12 |
| 78 | Sustain section added to doctrine (Section 2) | Five sustain items from AAR Sessions 1-2: adversarial review, saboteur (with scope expansion to all phases), phase gates as hard stops, BRD review quality, Proofmark (promising not proven). "Don't break these" prescriptions. | Session 12 |
| 79 | Saboteur domain expanded to all phases (design through code) | BRD mutations, FSD mutations, code mutations, config mutations. Agents must start from BRD as primary source; V1 source is reference material. | Session 12 |
| 80 | Document renamed: "New Way of Working" → "ATC Program Doctrine" (program-doctrine.md) | Reflects actual function: program charter + governance guardrails. "Bible" was informal shorthand. | Session 12 |
| 81 | Doctrine change management added (Section 3.7) | Standing review question at every phase boundary. Change process: observation → proposal → Jim review → Dan approval → logged. High bar — governed evolution, not casual edits. | Session 12 |
| 82 | AAR CLOSED | 12 sessions, 82 decisions, 15 findings across 4 groups, 5 adversarial reviews (Pat ×4, Ermey ×1). Output: ATC Program Doctrine (`program-doctrine.md`). The doctrine governs POC4. This log is reference material — read it if you need to understand *why* a doctrine section exists, not to decide what to do next. | Session 12 |

---

## AAR Close-Out — Session 12

**The POC3 After-Action Review is CLOSED.**

12 sessions. 82 decisions. 15 findings across 4 groups. 5 adversarial reviews. One governing document.

The output of this AAR is the **ATC Program Doctrine** at `AtcStrategy/POC4/BdStartup/program-doctrine.md`. That document — not this log — is what governs POC4 and all future ATC work. This log is the evidentiary record: it explains *why* each doctrine section exists, what evidence drove each decision, and what alternatives were considered and rejected. It is reference material, not an operating document.

**Carry-forward items for Step 7 (Frame Up POC4):**

Pat's non-blocking implementation notes (still valid, not actioned):
1. Reframe Section 1.3 resource constraint paragraph from budget-specific to operational-pressure-general
2. Add "probe for suppressed concerns" to Jim/Pat gate protocol (covers #9 collapse residual)
3. Automate mod-date audit trail check so enforcement doesn't become rote

Ermey's non-blocking implementation notes:
1. Jim section could benefit from a summary table (firing points, authority, checklist) — dense section, future BD under context pressure may struggle to hold it all
2. Doctrine needs an execution startup procedure — what the orchestrator does in the first 30 minutes after the readiness gate clears
3. Cross-references between Section 1.4 (enforcement layers) and Section 3 (implementations) should be made explicit

**Active parking lot items (carry forward to Step 7):**
- CustomerAccountSummary — check V1 code
- Laws of robotics framing — may or may not survive
- POC4 directory hygiene automation
- ParquetFileWriter schema parameter (Step 4/6)
- Multi-output job schema handling

---

## Parking Lot

*Items raised but deliberately deferred.*

1. ~~**Cross-pod learning / guild mechanism**~~ — MOOT. Section 2 (Pods) deleted in Session 12. Revisit from scratch in Step 7 if relevant.
2. **CustomerAccountSummary** — check V1 code to determine if vestigial from POC2 or a real POC3 gap.
3. ~~**Agent Teams beta**~~ — MOOT. Pod model deleted. Agent Teams exploration restarts from scratch in Step 7.
4. **Laws of robotics framing** — good thread, may or may not survive as a concept. Pull on it when working the bible.
5. **Global Technical Risk Register** — enterprise-deployment risks that can't be tested in sandbox. First entry: single agent profiling billion-row tables may just die. Not addressable in home POCs.
6. ~~**BD's guilds comment**~~ — MOOT. Pod model deleted.
7. **POC4 directory hygiene automation (two-layer)** — (a) OpenClaw bot crawls POC4 directory on a schedule, recommends structural fixes (stale pointers, misplaced files, index drift). (b) Hook enforcement at file-create/move time. Dan's preference: don't badger BD with hooks mid-session — BD's context is too precious. Let BD work freely, use async cleanup (bot or hook that doesn't interrupt BD). "Camp lobster" — the housekeeper comes in after, not during. Build neither until the folder structure exists and has been lived in.
8. **ParquetFileWriter schema parameter** — framework change to accept and enforce a pre-defined schema at write time. Prevents runtime type inference from data. Step 4/6 implementation task.
9. **Multi-output job schema handling** — jobs producing multiple output files each need their own schema definition. Design decision for Step 7 blueprint work.
