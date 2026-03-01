# ACT / Bambino POC #3

## Intent
Take the ATC /Bambino POC even further, to tighten up loose ends from POC 2, and to expand our knowledge and experience with this tooling.

### Loose ends -- Proofmark

The simulated reviewers (agents with explicit personas to poke holes in this) opened many intriguing avenues of thought for how this program would ultimately be embraced by risk and control type people. They're job is to keep regulators happy and regulators don't typically embrace change of this magnitude with open arms. Primary among those concerns was a risk of model validation. Or, as one of them put it, who's watching the watchers? 

A legitimate concern coming out of POC 2 was that the AI that built the reverse engineering pipeline was the same AI that was evaluating its own efficacy. While this isn't strictly true in the technology sense. It's worth understanding the point behind the concern. That there can be no appearance of the fox designing the hen house in the eyes of our regulators. 

During the OnPrem to Cloud migration, this team learned quite a lot about this process, and how to evaluate whether new code could produce like-for-like output. In that case, the "new code" was human produced, but by humans who didn't write the on-prem code to begin with and it was on an entirely different architecture. To arrive at a governance gate that was satisfactory to our regulators then, we used two vendor tools. Neither was quite up to the entirety of the task alone, but together they sufficed.

This POC is setting out to rebuild that tooling entirely separately from the reverse engineering pipeline and in a fashion that much more closely mimicks Program-level SDLC. We'll call that tool Proofmark.The name comes from proof marks on firearms: the stamp from an independent proof house certifying that a weapon has been pressure-tested. The proof house doesn't care who built the gun. It cares whether it passes.

A human who has extensive knowledge of the challenges we experienced during that original migration process will write the business requirements for a new tool called Proofmark that covers the primary capabilities of those 2 vendor tools we used. This human was the lead of 2 of the migration teams during that program and dealt with the pitfalls of comparing output from an entire ETL platform on a daily basis for years.

From the BRD, the AI will write the test strategy in a manner closely aligned to business driven development (BDD), then the functional specification (FSD), then unit tests, and finally the code. The human will tightly review each document along the way. More importantly, a completely independent "auditor" agent, with very strict instruction to cite any lacking traceability, any inconsistency, any dropped ball, will audit every document. And we will not proceed past any step until the auditor is satisfied.

Finally, we will write the code, in an entirely different programming language and tech stack from the Mock ETL Framework. We will follow traditional SDLC steps. We will create test data that is not sourced from our mock data lake, specifically designed to prove out any edge cases or negative tests. We will require 100% unit test coverage and 100% unit tests passed. 

This is non negotiable. For the sake of this POC, Proofmark is an independently developed COTS product, designed for re-use across any bank for verifying the fidelity of output data after migrating or re-writing an ETL workflow. When we run the POC to reverse engineer our mock ETL portfolio, the AI agents tasked with doing so will have no knowledge that this tool was developed for this POC. As far as they will know, it is a COTS tool that we have put into their gating process to evaluate their success.

### Loose ends -- The Sabateur

One legitimate criticism of our second POC was that it never found any logic errors in the code rewrites. There were errors, but they were schema baseed (numerical precisions and the like). No true misses by the reverse engineering bots. The optimist could respond "that's great, it produced perfect code". The pessimist will say "so how do you know your process is robust?"

We can't design our reverse engineering process to fail on the first try, but we can take a page from Netflix. Anyone remember Chaos Monkey? Well we have the Sabateur. This will be an independent agent whose job will be to subtly change requirements mid flight. The analyst agent will write the perfect spec based on evidence in the code and data. The sabateur will change some of those specs before the coding ever starts. Logic errors. We'll put the sabateur in a tight box. We'll get nowhere if he's always breaking things. But, if done right, this should produce enough flux to stress test the process's ability to identify failures, triage root cause, fix, and re-test.

### Expand our knowledge of tooling

We'll be trying out multiple new techniques to drive our ability to affect positive change in this new AI-driven world. A lesson we saw from POC 2 was from an afterthought, done after the POC was complete. We asked a separate agent to adopt the persona of cross domain skepticism and poke holes in the process. Then we asked yet another to review that output using the persona of a neutral evaluator. We learned a lot from that process. And it drove the whole "loose ends" piece here in POC 3.

With that, we plan to approach every step of this POC through the lens of "what would the skeptics" say. We'll write the BRD for proofmark with a human HEAVILY involved in the process. We'll then let the LLM take the lead on the test architecture. Once that's done, well set up a series of adversarial interactions between independent agents, each adopting the persona of skeptis, auditors, control partners, etc. We'll address their concerns, one at a time, and update the documentation as we go. We don't move forward without a bullet-proof rear-view-mirror.

### Step 1a, build Proofmark 
This is complete as of Feb 28 17:15 EST. BRD, Test architecture. FSD. Test data. UTs. Code. All UTs pass. 

### Step 1b, expand the data lake
This is done. we created 10x the customers, added more tables, and extended our as-of date range from 1 month to 1 quarter

### Step 1c, expand the ETL job portfolio
This is in-process as of Feb 28, 17:17, running adversarial sessions to evaluate whether we have sufficent wrinkles, sufficient anti-patterns, and reasonable ETL job complexity to represent your typical big data platform. Scoped tightly to Step 1c only — does this job portfolio give Step 3 agents a credible challenge?

### Step 2a, contex engineer the reverse engineering
Plot out what we want to do and how we want to do it. Start from the POC2 blueprint. Work in better guardrails. Work in the Sabateur. Work out a better process. Lean in heavy on agent teams multi-threading.

### Step 3 Build the better ETL portfolio
Having no knowledge of the planted "gotchas", set up the reverse engineering team to rebuild these jobs, evaluate their efficacy using Proofmark, report on results, iterate through triage->repair->rerun->reevaluate cycles until the entire ETL portfolio is rebuilt with zero human intervention. Wrap everything into a nice, neat governance package, and give each other high-fives.