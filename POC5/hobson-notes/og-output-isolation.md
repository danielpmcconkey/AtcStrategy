# OG Output Isolation Strategy

## Problem

BD needs access to the original (known-good) ETL output so he can study schemas, row shapes, and expected results before writing RE jobs. But proofmark comparisons must always run against the real OG output — not a copy BD can tamper with.

## Design

1. **Copy the OG output into BD's repo.** This gives him a read-only reference snapshot at `/media/dan/fdrive/ai-sandbox/workspace/MockEtlFramework/Output/curated/`.

2. **Proofmark resolves paths via host-side env vars.** When BD queues a proofmark task, paths use `{ETL_ROOT}` tokens. Proofmark runs on the host, where `{ETL_ROOT}` resolves to `/media/dan/fdrive/codeprojects/MockEtlFramework/` — Hobson's copy, not BD's.

3. **Docker boundary prevents modification.** BD's container can see `/media/dan/fdrive/ai-sandbox/` but not `/media/dan/fdrive/codeprojects/`. He cannot alter the real OG output.

## Why This Works

- BD can read and study the OG output (his copy).
- Proofmark always compares against the real OG output (host-side token resolution).
- Even if BD's copy drifts or is modified, proofmark comparisons are unaffected.
- The only way to cheat would be to write a fully qualified path in the queue instead of using the `{ETL_ROOT}` token — deliberate, not accidental.

## Staleness

The copy is a point-in-time snapshot. It only needs refreshing if OG jobs are re-run due to a code fix, which would mean resetting the entire RE process anyway.
