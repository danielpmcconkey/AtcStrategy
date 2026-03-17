# Anti-Pattern Remediation — Holistic View

**Date:** 2026-03-17
**Scope:** 41 completed jobs with artifacts

## Summary

**175 total anti-patterns** cataloged across 41 jobs (avg 4.3 per job).
**60% remediation rate.** The remaining 40% are almost entirely deliberate — preserved because they're load-bearing for output equivalence or reproduced because Proofmark requires byte-identical results.

## Disposition Breakdown

| Status | Count | % |
|--------|-------|---|
| REMEDIATED | 100 | 57% |
| PARTIALLY REMEDIATED | 6 | 3% |
| PRESERVED (load-bearing, can't change without breaking output equivalence) | 42 | 24% |
| REPRODUCED (faithfully replicated from OG, no remediation attempted) | 20 | 11% |
| NOT REMEDIATED | 3 | 2% |
| REVERTED / SUPERSEDED / NOT AN ISSUE | 4 | 2% |

## Top 5 Anti-Pattern Categories

1. **Dead/vestigial data sources** (26 instances) — tables loaded but never consumed. 23 of 26 remediated. Almost always `branches` or `segments`.
2. **Unused/over-fetched columns** (24 instances) — columns selected that no transformation references. 24 of 24 remediated. 100% cleanup rate.
3. **Row-by-row iteration via `iterrows()`** (22 instances) — Python loops where SQL/vectorized ops work. 21 of 22 remediated.
4. **Unnecessary External modules** (15 instances) — using Python External modules for logic expressible in standard SQL Transformation modules. 9 remediated, 2 partially, 1 reverted (job 23 needed it for dtype preservation).
5. **No date filtering / full table scans** (10 instances) — 6 preserved as load-bearing, 2 turned out to not be anti-patterns at all (framework default handles it).

## Categories Almost Never Remediated

- **Append/cumulative mode issues** (9 instances, 0 remediated) — framework-level behavior, not fixable at job level.
- **Framework/structural issues** (8 instances, 1 remediated) — in-memory SQLite, inline SQL in JSON, misleading names.
- **Float/decimal arithmetic** (5 instances, 1 remediated) — preserving OG's IEEE 754 behavior is required for equivalence.

## Notable Jobs

- **Jobs 3, 5, 10, 11, 14, 16, 17, 26:** 100% remediation rate (all APs fixed).
- **Jobs 159, 369, 371, 373:** 0% remediation rate — all anti-patterns reproduced faithfully (framework-level or Proofmark-constrained).
- **Job 18:** 3 anti-patterns explicitly marked NOT_REMEDIATED (External module, iterrows, non-deterministic dedup) — the worst remediation outcome.
- **Job 21:** Highest AP count (7), still remediated 5.

## Where the Data Lives

- **BRD anti-pattern catalog:** `/workspace/EtlReverseEngineering/jobs/{id}/artifacts/brd.md` (section "Anti-Patterns Catalog", `AP-NNN` numbering)
- **FSD remediation plan:** `/workspace/EtlReverseEngineering/jobs/{id}/artifacts/fsd.md` (section "Anti-Pattern Remediation Plan")
- **Triage reports** (11 jobs): `/workspace/EtlReverseEngineering/jobs/{id}/artifacts/triage/`
- **Process JSON:** `/workspace/EtlReverseEngineering/jobs/{id}/process/WriteBrd.json` (`anti_pattern_count` field)

## Conclusion

The engine consistently identifies and catalogs anti-patterns during reverse engineering. The 60% remediation rate reflects pragmatic trade-offs — output equivalence (validated by Proofmark) takes priority over code purity. The unremediated patterns are overwhelmingly framework-level constraints, not missed opportunities.
