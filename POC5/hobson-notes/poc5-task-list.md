# POC5 Task List

Created 2026-03-08. Phases execute in order. Tasks within a phase may be reordered.

---

## Phase 1 — Host ETL FW Ready

- [x] Set `ETL_ROOT` env var on the host
- [x] Set `ETL_RE_OUTPUT` env var on the host
- [x] Set `ETL_ROOT` env var in Docker (`compose.yml`)
- [x] Set `ETL_RE_OUTPUT` env var in Docker (`compose.yml`)
- [x] Change MockEtlFramework sleep timer from 15 minutes to 8 hours (see [Note 1](#note-1))
- [x] Confirm that the path changes to MockEtlFramework are correct
- [x] Tokenise the 10 inconsistent DB rows in control.jobs (missing {ETL_ROOT} prefix)
- [x] Change MockEtlFramework's parallelism approach (see [Note 1](#note-1))
- [x] Confirm that MockEtlFramework Documentation directory is correct
- [ ] Start running MockEtlFramework as a long-running "service"

## Phase 2 — Host Proofmark Ready

- [ ] Change Proofmark code to also run for 8 hours
- [ ] Change Proofmark to handle dynamic pathing (`{TOKEN}` expansion)
- [ ] Change Proofmark's DB connection to use `ETL_DB_PASSWORD` env var (see [Note 2](#note-2))
- [ ] Make sure Proofmark's documentation is updated
- [ ] Start running Proofmark as a long-running "service"

## Phase 3 — Original Job Baseline

- [ ] Delete any remnants from the POC4 output
- [ ] Update all original job confs to use dynamic output paths
- [ ] Run all original jobs across the full 92-day range 2024-10-01 – 2024-12-31

## Phase 4 — Basement Prep

- [ ] Make sure all host code is committed and pushed
- [ ] Update all code repos on the basement side
- [ ] Confirm network boundary supports Dan's "who can read and write what" strategy
- [ ] Install Briggsy's tooling chain into BD's Docker
- [ ] Build the "press go" execution plan with the new toolchain in mind (significant effort)

## Phase 5 — RE Execution

- [ ] Execute RE operations on 1 ETL job
- [ ] Execute RE operations on 5 ETL jobs
- [ ] Execute RE operations on all remaining jobs

---

## Notes

### Note 1

**TaskQueueService redesign — parallelism and idle timeout (session 007)**

The current `TaskQueueService` has 4 parallel threads + 1 serial thread, with an
idle timeout of 15 minutes (30 cycles × 30s). Both the parallelism model and the
timeout need to change, and they're coupled enough to do together.

**New parallelism model:** Drop the serial/parallel distinction. Just N threads
(likely 5). Each thread wakes up, finds the first unclaimed job ID in the queue,
claims *all* rows for that job ID, and runs them sequentially. This way:

- Oct 1 Job A and Oct 2 Job B can run in parallel (different threads).
- Oct 1 Job A and Oct 2 Job A never run in parallel (same thread owns all of Job A's dates).
- Append-mode writes and CDC ordering are safe without any special config per job.

**Idle timeout:** Change from 15 minutes to 8 hours. Will be externalized to app
config along with thread count when the redesign happens.

**Current constants in `TaskQueueService.cs`** (all hardcoded, all need externalizing):
- `ParallelThreadCount = 4`
- `PollIntervalMs = 5000`
- `IdleCheckIntervalMs = 30000`
- `MaxIdleCycles = 30`

### Note 2

**Proofmark DB password — session 007**

MockEtlFramework now reads its DB password from the `ETL_DB_PASSWORD` env var
(no secrets in the repo). Proofmark's connection string likely still has a
hardcoded password. When we get to Phase 2, update Proofmark to use the same
env var so both apps share one secret source.
