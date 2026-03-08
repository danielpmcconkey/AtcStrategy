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
- [x] Start running MockEtlFramework as a long-running "service"

## Phase 2 — Host Proofmark Ready

- [x] Change Proofmark code to also run for 8 hours
- [x] Change Proofmark to handle dynamic pathing (`{TOKEN}` expansion)
- [x] Change Proofmark's DB connection to use `ETL_DB_PASSWORD` env var (see [Note 2](#note-2))
- [x] Make sure Proofmark's documentation is updated
- [x] Start running Proofmark as a long-running "service"

## Phase 3 — Original Job Baseline

- [x] Delete any remnants from the POC4 output
- [x] Update all original job confs to use dynamic output paths
- [x] Run all original jobs across the full 92-day range 2024-10-01 – 2024-12-31
- [x] Copy OG output to BD's repo for reference

## Phase 4 — Basement Prep (Hobson's final phase)

- [ ] Make sure all host code is committed and pushed
- [ ] Update all code repos on the basement side
- [x] Confirm network boundary supports Dan's "who can read and write what" strategy
- [ ] Install Briggsy's tooling chain into BD's Docker
- [ ] Clean BD's resurrection file, memory, and CLAUDE.md of distracting context
- [ ] Write BD's wake-up prompt (see [Note 3](#note-3))

## Phase 5 — RE Planning & Execution (BD-led, with Dan)

- [ ] BD builds the RE execution plan with Dan
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

### Note 3

**BD's wake-up prompt — scope and framing**

BD wakes up with a clean slate. The wake-up prompt should give him:

- **His toolchain:** Briggsy's tools — what they are, what they do, how to use them.
- **The ETL framework as a black box:** A "COTS product in the cloud." BD has a
  reference copy of the code in his workspace. He can read it, study it, understand
  how jobs work — but it's a snapshot, not the running version. The real framework
  runs on the host and he can't touch it. He queues jobs; output appears.
- **Proofmark as a black box:** Same model. Reference copy in his workspace. The real
  proofmark runs on the host. He queues comparison tasks; it tells him pass/fail.
- **Reference output:** OG output lives in his workspace under `Output/curated/`.
  It's a read-only reference snapshot. The real OG output lives on the host and
  proofmark compares against that, not BD's copy.
- **The goal:** Reverse-engineer 105 ETL jobs so his RE output matches the OG output
  to proofmark's satisfaction. Build the RE execution plan *with Dan*.
- **What he doesn't need:** Programme history, POC lineage, architectural rationale.
  POC 1–4 docs aren't off-limits if he stumbles into them, but they're not his
  starting point. His starting point is the toolchain.
