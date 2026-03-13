# BD Wake-Up — POC6 Session 1

## Paste this to start the session:

```
Read /workspace/AtcStrategy/POC6/BDsNotes/bd-wakeup-poc6-session1.md then tell me where we are.
```

---

## What Happened This Session

1. **POC5 is dead.** Committed and pushed all remaining artifacts in AtcStrategy and EtlReverseEngineering. Both repos are clean.
2. **Created MockEtlFrameworkPython repo** (public) on GitHub. Hobson is rebuilding the ETL framework in Python there.
3. **Designed the POC6 agent taxonomy** with Dan. Full per-job waterfall pipeline: Plan → Define → Design → Build → Validate. Each leaf node is an atomic agent.
4. **Ran an adversarial review** of the taxonomy against Dan's POC5 vision doc (points 5, 6, 7 especially). Dan responded to all findings. Key takeaways:
   - Circuit breakers: valid, but a blueprint concern not taxonomy
   - Routing is hand-wavy: **this is the next thing to solve**
   - The deterministic processing loop is the key architectural innovation — it manages a pool of 12 workers across ALL jobs, enforces the dependency graph, and prevents the sequencing bugs from POC5
   - The adversarial agent misread the taxonomy in 2 places (Build artifacts and Triage were already split). BD parroted it without checking. Don't do that again.

## What Needs to Happen Next

**Design the routing table.** Before blueprints, we need the full deterministic routing map:
- Every task type
- What it outputs (pass/fail/artifact)
- Exactly what gets queued next for every outcome
- This is what makes the orchestrator truly dumb — a lookup table, not a decision-maker

## Key Files

- `/workspace/AtcStrategy/POC6/BDsNotes/poc6-architecture.md` — architecture overview, CLI invocation pattern
- `/workspace/AtcStrategy/POC6/BDsNotes/agent-taxonomy.md` — the full taxonomy tree
- `/workspace/AtcStrategy/POC6/BDsNotes/adversarial-review-01.md` — adversarial review + Dan's responses
- `/workspace/AtcStrategy/POC5/DansNewVision.md` — the original vision (points 5, 6, 7 carry forward)

## Dan's Design Decisions (from this session)

- **105 waterfalls, not 1.** Each job gets its own full lifecycle pipeline. No cross-job contamination.
- **Dumb orchestrator.** Pure Python deterministic loop. No LLM. Polls queue, claims tasks, shells out to `claude -p`, parses response, queues next step.
- **12-worker pool** shared across all jobs. The loop manages capacity. A fan-out of 17 tasks from one job just means they queue up — not a capacity bomb.
- **Circuit breaker** belongs in the triage agent's blueprint: if this is the 5th triage, give up and report failure. Don't retry forever.
- **Review Response** agents need to be explicitly separate from Write agents (atomicity). Clarify during routing or blueprint design.
- **Publish and Locate OG** might not need LLM agents — defer that decision.

## Open Design Questions

- How does call/response work through the deterministic loop? (Dan flagged this as non-trivial)
- Per-job directory isolation?
- How do Validate-stage agents interact with external systems without wasting worker slots?
- Write boundary implementation (Hobson, still pending)

## Constraints

- Hobson is mid-refactor on MockEtlFrameworkPython — don't bother him
- Write boundary for curated_re/ still not implemented
- GSD is NOT being used for POC6 (at least not yet)
