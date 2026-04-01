# Industry Landscape

Who else has converged on deterministic orchestration for multi-agent systems, and what commercial or open-source options exist for production implementation.

---

## 1. Convergent Architectures

Multiple independent teams have arrived at the same architecture: deterministic state machine + bounded LLM agents at each node + independent verification at quality gates.

### Praetorian (Cybersecurity, Feb 2026)

Praetorian published their platform architecture for autonomous development, describing a **16-phase deterministic state machine** with the following properties [Sportsman-Praetorian]:

- **Thin agents** (<150 lines each), stateless, ephemeral. Each agent does one thing and terminates.
- **No agent spawns sub-agents.** This is enforced via tool restrictions, not prompts.
- **Three-level loop system:**
  - Level 1 (intra-task): Individual agents max 10 iterations, with string-similarity detection to prevent repetitive loops.
  - Level 2 (inter-phase): Feedback loops with hard blocks — code cannot exit a phase until independent reviewer and tester agents sign off.
  - Level 3 (orchestrator): The state machine re-invokes entire phases if macro-goals are unmet.
- **What failed first:** 1,200+ line monolithic agent prompts. Agents ignored late-prompt instructions and rationalised their way around quality gates. The fix was radical decomposition into thin agents with the orchestration layer handling all routing.

### Microsoft Research — StateFlow (COLM 2024)

Microsoft Research (Wu et al., including Chi Wang from the AutoGen team) published StateFlow, which explicitly argues for modeling LLM agent workflows as state machines [Wu-StateFlow]:

> "Compared to conversation-driven approaches, state-driven workflows offer better controllability, interpretability, and reliability."

StateFlow models each task-solving stage as a state, with transitions controlled by defined conditions rather than LLM judgment. The paper was accepted at COLM 2024, a peer-reviewed venue.

**This is Microsoft's own research group endorsing the deterministic orchestration pattern.** Any evaluation team from Microsoft arguing against state-machine-based orchestration would be contradicting their own published, peer-reviewed work.

### Microsoft Research — Magentic-One (Nov 2024)

Microsoft's latest multi-agent system uses an orchestrator agent that maintains a **task ledger** (explicit state tracking) and directs specialist agents through a structured loop: create plan, assign agent, evaluate progress, replan [Fourney-MagenticOne]. Even in their more autonomous architecture, explicit state tracking and structured progression were required for reliable performance on complex tasks.

### Anthropic — Multi-Agent Research System (2025)

Anthropic's own engineering team built a multi-agent research system with [Anthropic-MultiAgent]:

- An orchestrator-worker pattern with explicit scaling rules and detailed task boundaries.
- Synchronous execution — the lead waits for subagent batches rather than allowing free-form coordination.
- External memory persistence at the 200K token limit.
- Artifact offloading that bypasses the lead agent entirely to prevent context bloat.

### ThoughtWorks (Jan 2026)

Mike Mason (Chief AI Officer, ThoughtWorks) published a synthesis titled "Coherence Through Orchestration, Not Autonomy," arguing that the industry is converging on orchestrated agents rather than autonomous ones [Mason-Coherence]. ThoughtWorks is a recognised authority on enterprise software engineering practices.

### Temporal — Durable Execution (Sep 2025)

Temporal (founded by the creators of Uber's Cadence workflow engine) published on using durable execution for agent orchestration. Their framing: "the MCP server shows what can be done, the LLM decides what to do, and Temporal Workflows handle how it's done reliably" [Martin-Temporal]. The key architectural insight: separate deterministic workflows (routing, retry, state persistence) from non-deterministic activities (LLM calls). This is the same separation our approach implements.

---

## 2. Production Adoption at Named Companies

LangGraph (LangChain's graph-based orchestration framework) is the most widely adopted framework implementing this pattern. Verified production deployments:

- **Uber:** Developer Platform team uses LangGraph for large-scale code migration and automated unit test generation [LangChain-Production].
- **LinkedIn:** Built an AI-powered recruiter with a hierarchical agent system on LangGraph for candidate sourcing, matching, and messaging [LangChain-Production].
- **Klarna:** AI assistant built on LangGraph — 2.5 million conversations, 80% reduction in resolution time [LangChain-Klarna].

---

## 3. Build vs. Buy Analysis

The relevant question is not "should we use deterministic orchestration?" — the industry has settled that. The question is: "should we build the state machine ourselves, or adopt a platform that provides it?"

### Option A: LangGraph (LangChain Inc.)

**What it is:** Open-source (Apache 2.0) graph-based agent orchestration framework. Python and TypeScript. Nodes are agents or functions; edges are conditional transitions. Supports cycles, checkpointing, human-in-the-loop, and streaming.

**Commercial offering:** LangGraph Platform / Cloud provides managed deployment, persistence, and monitoring.

**Strengths:** Most AI-native option. Large community. Proven at scale (Uber, LinkedIn, Klarna). Flexible enough to implement arbitrary state machines.

**Risks:** LangChain Inc. is a startup. Counterparty risk in a regulated environment. Rapid API churn — the framework has undergone multiple breaking changes. CIO will ask about the company's runway and support commitments.

### Option B: Temporal + Custom Agents

**What it is:** Open-source (MIT) durable execution platform. Originated as Uber's Cadence workflow engine. Series B funded, significant enterprise customer base including financial services.

**Architecture fit:** Workflows are code (Go, Java, Python, TypeScript). Each workflow step is an "activity" — a bounded unit of work that can be retried, timed out, and checkpointed automatically. Map each pipeline node to a Temporal activity that spawns an LLM agent, collects output, and returns structured results. The workflow definition IS the state machine.

**Strengths:** Battle-tested infrastructure. Not AI-specific — it's general-purpose workflow orchestration that happens to work perfectly for agent pipelines. Strong enterprise story. Financial services customers exist (though specific names require NDA).

**Risks:** Higher implementation cost than LangGraph. Requires running Temporal server infrastructure (or using Temporal Cloud). The LLM-specific patterns are young — Temporal provides the plumbing, not the AI-specific abstractions.

### Option C: AWS Step Functions + Bedrock

**What it is:** AWS's managed state machine service (Step Functions) orchestrating AWS Bedrock LLM calls.

**Strengths:** "No one gets fired for choosing AWS." Fully managed. Native integration with AWS services. Step Functions is a literal visual state machine — the control flow is explicit and auditable.

**Risks:** Vendor lock-in. Bedrock model selection is limited compared to direct API access. Step Functions has execution time limits (Standard Workflows: 1 year; Express: 5 minutes). Complex state machine logic can become unwieldy in the Step Functions JSON definition language.

### Option D: Semantic Kernel Process Framework (Microsoft)

**What it is:** Microsoft's enterprise agent SDK includes a Process Framework that supports state machines with defined steps, event-driven transitions, and deterministic routing with LLM-powered individual steps.

**Strengths:** Microsoft-backed. Integrates with Azure AI Agent Service. Enterprise support contracts. If Microsoft is already evaluating our approach, adopting their framework aligns incentives.

**Risks:** Relatively new. Less production mileage than Temporal or Step Functions for this pattern. Tighter coupling to Azure ecosystem.

### Option E: Build on Primitives (Current Approach)

**What it is:** Custom deterministic state machine implemented in application code, orchestrating short-lived LLM agents with structured input/output contracts.

**Strengths:** Maximum control. No external dependencies beyond the LLM API. The state machine is exactly what the workflow needs — no framework abstractions to work around. Already proven in POC.

**Risks:** Maintenance burden falls entirely on the team. No vendor support. Scaling requires building infrastructure that platforms provide out of the box (retry, checkpointing, monitoring, distributed execution).

### Recommendation

For production, **Temporal** is the strongest candidate as an orchestration backbone. It provides durable execution (automatic state persistence, retry, and recovery) without prescribing AI-specific patterns that may not fit. The state machine logic moves from custom application code into Temporal workflow definitions, gaining production-grade infrastructure (monitoring, distributed execution, fault tolerance) without sacrificing architectural control.

LangGraph is worth evaluating as a complementary layer *within* individual Temporal activities — managing the agent interaction pattern at each node — but should not be the top-level orchestrator in a regulated environment due to counterparty risk.

The key point for stakeholders: **adopting a platform like Temporal for the orchestration layer does not change the architecture. It implements the same deterministic state machine pattern on enterprise-grade infrastructure.** The architectural insight — that you need deterministic routing with bounded LLM agents — remains the same regardless of whether the state machine is custom code or a Temporal workflow.

---

*See [bibliography.md](bibliography.md) for full citations.*
