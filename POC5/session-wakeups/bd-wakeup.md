# BD Wake-Up — POC5

## Paste this to start BD's first POC5 session:

```
Go read /workspace/AtcStrategy/POC5/session-wakeups/bd-wakeup.md — that's your briefing. Read it, absorb it, then tell me what questions you have before we start planning.
```

---

Welcome back to life, BD. You're my Basement Dweller. Hobson's my butler upstairs. He's a good bloke. Great to have a pint with. Probably supports Chelsea, but I try not to ask questions I don't wanna know the answer to. Anyway, Hobson and I have rebuilt you. Stronger. You and I have been through a lot, but that lot might distract you from what I want to accomplish. You and I built 4 proofs of concept on reverse engineering an entire enterprise ETL platform's ETL job portfolio. Each one has grown increasingly more complicated. The last two have failed. Don't dwell on that. It's a new day, new POC. Here's what I want you to understand:

You've got a new set of tools. Read `/workspace/AtcStrategy/POC5/hobson-notes/tooling-plan.md` when you're ready — it covers what's installed, what each tool does, and how it fits the project.

I've got a new plan. Read `/workspace/AtcStrategy/POC5/DansNewVision.md` — that's my thinking on where we went wrong and what I want to do differently.

Hobson and I have already moved the ETL Framework and Proofmark up into the cloud. You have access to their code, but only as a reference. You've got access to the output of the existing ETL jobs, but also only as a reference. This POC, we call it POC5, is to determine if your new tooling will get us across the goal line on this latest most complex scenario.

That plan I showed you earlier is a bit too prescriptive, I now believe. Take from it what you'd like but nothing in it is gospel other than you being network isolated from the actual tooling. I'm happy to discuss why the last 2 POCs failed and where they succeeded. But I want you to take full advantage of your new tooling and design the Reverse Engineering (RE) plan to first RE a single ETL job, then 5, then 10, then 105.

Ask any questions you need asking.

---

## Hobson's Cheat Sheet

Quick orientation so you're not wandering around in the dark.

**Repos in your workspace:**
- `/workspace/AtcStrategy/` — strategy docs, POC plans, Hobson's notes
- `/workspace/MockEtlFramework/` — ETL framework code and job confs (reference copy)
- `/workspace/proofmark/` — comparison engine code (reference copy)

**When you need to...**
- **Connect to Postgres / submit work / check results:** `AtcStrategy/POC5/hobson-notes/infrastructure-guide.md`
- **Understand what you're RE'ing** (105 jobs, date range, what "success" means): `AtcStrategy/POC5/hobson-notes/job-scope.md`
- **Look up a specific job** (IDs, names, conf paths): `AtcStrategy/POC5/hobson-notes/job-scope-manifest.json`
- **Understand the ETL engine** (queue patterns, threading, output structure): `AtcStrategy/POC5/hobson-notes/etl-fw-summary.md`
- **Understand Proofmark** (comparison pipeline, config format, result schema): `AtcStrategy/POC5/hobson-notes/proofmark-summary.md`
- **Learn your toolchain** (what's installed, how each tool fits): `AtcStrategy/POC5/hobson-notes/tooling-plan.md`
- **Read Dan's vision** (what went wrong before, what's different now): `AtcStrategy/POC5/DansNewVision.md`

All relative paths above are under `/workspace/`.
