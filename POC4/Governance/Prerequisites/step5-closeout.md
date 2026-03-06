# Step 5 Close-Out: Tooling & Framework Changes

**Completed:** 2026-03-06
**Signed off by:** Dan

## Framework Changes

Writer restructure for date-partitioned curated zone output. Four write mode variants (CSV Overwrite, CSV Append, Parquet Overwrite, Parquet Append) implemented and validated. Key additions: `DataFrame.FromParquet()`, DataSourcing multi-date support (`lookbackDays`, `mostRecentPrior`), `DatePartitionHelper` extraction, trailer stripping for append mode, `DataFrame.FromCsvLines()` overload. 111 tests passing at session end (no regression from Step 4's 92).

## Proofmark Validation

Dan designed and personally validated 23 manual tests (14 CSV, 9 Parquet) against synthetic credit card transaction data. Tests covered: order independence, schema validation (missing/extra columns), floating point strict vs fuzzy tolerance, trailer row handling, whitespace detection, CSV quoting, line break detection, multi-part Parquet, and column type mismatches. 21/23 matched expected results. Two known gaps documented and accepted:

1. **CSV quoting dialect (test 013)** — Proofmark parses CSV before comparing, which strips quoting. Format-different but data-equivalent files are not detected. Rated HIGH risk for production. Documented in FSD §12 with two-layer architecture recommendation for vendor build. Root cause: CSV files are delivered via MFT to downstream systems with unknown parser brittleness. Byte-level formatting (quoting, escaping, delimiters, date/number format) must be identical, but the parsed comparison cannot verify this.

2. **Mixed line breaks (test 005)** — File-level detection only. A single rogue LF in an otherwise CRLF file is not caught. Rated LOW risk. Documented at FSD-6.10 with vendor build note.

## Proofmark Scale Readiness

PostgreSQL-backed queue runner implemented (`proofmark serve`). 5 parallel workers using `FOR UPDATE SKIP LOCKED` for race-condition-free task claiming. Validated by running all 23 manual test fixtures through the queue — 23/23 completed in under 2 seconds. Results match manual test log exactly (same two known gaps, same pass/fail on all others). The queue eliminates Python startup overhead (~140ms per invocation × 18,400 comparisons = 43 minutes of pure startup tax during POC4 execution).

## Cross-Validation

Proofmark cross-validated CSV vs Parquet output parity during Step 4 implementation — 10/10 runs passed STRICT comparison across all dates (Oct 1-10). This validated both the framework's write modes and Proofmark's comparison engine against real (non-synthetic) ETL output.

**Evidence:**
- `AtcStrategy/POC3/proofmark-manual-test-log.md` — 23 manual tests, Dan-validated
- `proofmark/Documentation/Design/FSD-v1.md` §12 — CSV format comparison gap, two-layer vendor build architecture
- `proofmark/Documentation/Design/FSD-v1.md` §11 — Queue runner specification
- `proofmark/sql/queue_schema.sql` — Queue table DDL
- `proofmark/tests/test_queue.py` — 12 integration tests against live PostgreSQL
- `Governance/Amendments/001-proofmark-status.md` — Doctrine amendment: "Accuracy Validated Within Tested Scope, Untested at Scale"
- Transcript summary: `2026-03-05_c972a808.md` — Parquet cross-validation, 10/10 PASS
- Queue runner smoke test: 23 tasks, 5 workers, all Succeeded, results consistent with manual log
