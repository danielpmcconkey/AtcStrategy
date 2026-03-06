# Decision: Curated Zone Write Modes

**Date:** 2026-03-05
**Status:** Decided
**Participants:** Dan, BD
**Scope:** MockEtlFramework curated output architecture

---

## Context

POC3 revealed that V1's overwrite mode destroys point-in-time history. The datalake has daily as_of snapshots but the curated zone had a single file per job, overwritten on every run. This made it impossible to see what a job produced on any prior date.

## Decision

### Curated Zone Structure

The curated zone mirrors the datalake's date-partitioned model. Each job run writes output into a partition keyed by the run's as_of date. Prior partitions are preserved. You can always query the curated zone to see what a job produced on any given run date.

### Write Modes

**Overwrite mode:** Write today's output to today's partition. No dependency on prior state. The partition contains only what the job produced from today's datalake data.

**Append mode:** Build a cumulative snapshot:

1. Find the most recent existing partition for this job in the curated zone (max as_of date).
2. Read that partition's data. Drop the as_of column.
3. Union it with today's new data from the pipeline.
4. Stamp every row with today's as_of date.
5. Write the complete result to today's partition.

If no prior partition exists (first run), skip the union — just write today's data.

### as_of Column

as_of is metadata injected by the writer, not by job logic. In both modes, every row in a partition carries the same as_of value — the run date. Jobs do not produce or manipulate as_of.

In append mode, this means prior rows get re-stamped with today's date. The partition represents "the cumulative state of this data as of this date," not "when each row first appeared."

### Deduplication

None. The union is naive. If the same entity appears in both the prior partition and today's new data, both rows exist in the output. This is a mock ETL platform proving process, not building production SCD2 logic.

### Storage

Every append-mode partition is a full cumulative snapshot, so storage grows with each run. Acceptable for this scale. Monitor if it becomes a problem.

## Comparison Strategy

All existing V1 and V2 curated output is deleted. Fresh start.

1. Modify the ETL framework to implement the new write mode architecture.
2. Re-examine existing jobs and tune as needed for the new architecture.
3. Run all jobs to produce fresh V1 output under the new architecture.
4. Run all jobs to produce fresh V2 output under the new architecture.
5. Compare V1 vs V2 using Proofmark — partition-to-partition, same structure on both sides.

Both sides use the same framework, same write modes, same partitioning. The only variable is the job implementation (V1 vs V2). No special Proofmark config needed for as_of exclusion or row ordering — both sides produce identically shaped output.

## Cascade Impacts

- **Framework (Step 4):** Writers need partition-aware output paths. Append mode needs "read prior partition" logic. as_of injection moves into the writer. CsvFileWriter and ParquetFileWriter both affected.
- **Job configs (Step 5):** Re-evaluate all jobs under new write modes. Some V1 configs may need adjustment.
- **Proofmark (Step 5):** Comparison configs point at matching partitions. Simpler than POC3.
- **Directory structure:** Not yet defined. Deferred to POC4 doc structure step.
