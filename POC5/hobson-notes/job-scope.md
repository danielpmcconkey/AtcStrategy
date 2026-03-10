# Job Scope — What You're Reverse Engineering

## The Job Portfolio

105 active ETL jobs. Each one:
1. Reads from a data lake (Postgres tables in the `atc` database)
2. Applies transformations (filters, joins, aggregations, column mappings)
3. Writes output files (CSV or Parquet) to a date-partitioned directory

Jobs are defined by JSON configuration files. The configs specify source queries,
transformation rules, output format, and write mode. You have reference copies
of all 105 configs in `/workspace/MockEtlFramework/V4JobConfs/`.

## The Date Range

Every job runs once per day across 92 effective dates:
**2024-10-01 through 2024-12-31** (inclusive).

That's 105 jobs x 92 days = up to 9,660 job executions.

## Dependencies

Some jobs depend on other jobs. The dependency graph is in `control.job_dependencies`.
A dependency means Job B can't run for a given date until Job A has succeeded for
that date (SameDay) or has any successful run (Latest). When you RE a job that
has upstream dependencies, those upstream jobs need to have run first.

## What Success Looks Like

For each job, for each of the 92 dates, your RE output must match the original
output. "Match" is determined by Proofmark — it reads both sets of files and
compares them according to a per-job YAML config.

Most comparisons are strict (byte-perfect). Some columns may be classified as
FUZZY (tolerance-based) or EXCLUDED. The Proofmark config for each job defines
which.

**A job is fully RE'd when all 92 dates return PASS from Proofmark.**

## The Full Job List

All 105 jobs are listed in `AtcStrategy/POC5/hobson-notes/job-scope-manifest.json`
with their job IDs, names, and conf file paths.

## Scaling Ramp

Dan's expectation: get one job working end-to-end first. Then 5. Then 10.
Then all 105. Don't try to boil the ocean.
