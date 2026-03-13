# BD Wake-Up — POC6 Session 2

## Paste this to start the session:

```
Read /workspace/AtcStrategy/POC6/BDsNotes/bd-wakeup-poc6-session2.md then tell me where we are.
```

---

## What Happened Last Session

1. Read session 1 wake-up, got caught up on POC6 design state.
2. Dan refined the architecture direction:
   - **C# project** in EtlReverseEngineering repo (not Python as previously sketched)
   - **DB-backed task queue** in control schema (Postgres)
   - **Skills as discrete C# functions** — collapse taxonomy overlap into a skill registry
   - **State machine workflow** — not if/else spaghetti. (current_state, outcome) → next_state
   - **Thread safety** is critical — rules out F# (immutable-first doesn't play nice with concurrent mutable state)
   - **Polyglot**: C# orchestrator, agents produce Python artifacts for MockEtlFrameworkPython
   - Hobson rebuilt MockEtlFramework in Python to eliminate compile-rebuild human-in-the-middle bottleneck
   - C# → Python migration of the orchestrator is a future option, trivial for Claude
3. **Cleared EtlReverseEngineering repo** — deleted all POC5 artifacts (jobs/, job-confs/, proofmark-configs/, .planning/)
4. **Wrote README as goal doc** for GSD — captures the goal, architecture, taxonomy, decisions, and open questions
5. Committed and pushed to GitHub

## What Needs to Happen Next

**Fire up GSD in the EtlReverseEngineering repo.** Point it to the README when it asks what we're building. Let GSD drive the spec/design conversation — that's what it's supposed to be good at.

## Key Files

- `/workspace/EtlReverseEngineering/README.md` — the goal doc (this is what GSD reads)
- `/workspace/AtcStrategy/POC6/BDsNotes/agent-taxonomy.md` — full taxonomy tree
- `/workspace/AtcStrategy/POC6/BDsNotes/poc6-architecture.md` — architecture overview
- `/workspace/AtcStrategy/POC6/BDsNotes/adversarial-review-01.md` — adversarial review + Dan's responses
- `/workspace/AtcStrategy/POC5/DansNewVision.md` — original vision (points 5, 6, 7 carry forward)
