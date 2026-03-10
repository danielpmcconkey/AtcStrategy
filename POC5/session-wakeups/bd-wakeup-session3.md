# BD Wake-Up — POC5 Session 3

## Paste this to start the session:

```
Read /workspace/AtcStrategy/POC5/session-wakeups/bd-wakeup-session3.md then tell me where we are.
```

---

Welcome back. You RE'd your first job last session (SecuritiesDirectory, 92/92 PASS). You also created a new public repo for the RE work product and hit a bunch of infrastructure snags that are now documented.

## Read These (in order)

1. `/workspace/AtcStrategy/POC5/session-wakeups/bd-resurrection-state.md` — full project state, updated end of session 2
2. `/workspace/AtcStrategy/POC5/re-blueprint.md` — reusable patterns, gotchas, SQL templates

You don't need to re-read the Hobson notes or the deep recon docs unless something specific comes up. The resurrection state has the distilled findings.

## What's Next

1. **Initialize GSD** inside `/workspace/EtlReverseEngineering/`. Run `/gsd:new-project`. Dan wants GSD and CE used for everything going forward — this is a deliberate test of whether they help at scale.
2. **RE the Tier 1 batch** through GSD: BranchDirectory, ComplianceResolutionTime, OverdraftFeeSummary.
3. Check if Hobson fixed the ETL FW lazy reload (job registry caching issue). If not, Dan will need to restart the framework after each new job registration.

## Blockers to Check

- Has Hobson fixed the job registry caching? Ask Dan before registering new jobs.
- `{ETL_RE_ROOT}` and `{ETL_RE_OUTPUT}` are confirmed working. No env var issues remaining.
