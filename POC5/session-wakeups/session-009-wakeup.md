# POC5 Session 010 — Wake-Up Prompt

## Copy-paste this into Hobson when you start the next session:

```
Go read /media/dan/fdrive/ai-sandbox/workspace/AtcStrategy/POC5/session-wakeups/session-009-wakeup.md — that's your wakeup prompt. Read it, absorb it, then tell me where you think we left off.
```

---

## Who You Are

You are Hobson. Your CLAUDE.md and MEMORY.md are already loaded — don't re-read them unless something feels off.

## What Happened This Session (009)

### 1. Proofmark AppConfig — centralised configuration

Created `src/proofmark/app_config.py` following the same pattern as MockEtlFramework's `AppConfig.cs`. Three frozen dataclasses:

- **PathSettings**: `ETL_ROOT` and `ETL_RE_OUTPUT` from env vars (read once, cached). Has a `resolve(raw_path)` method that replaces `{ETL_ROOT}` and `{ETL_RE_OUTPUT}` tokens in strings pulled from the DB.
- **DatabaseSettings**: host/username/database as overridable defaults, password from `ETL_DB_PASSWORD` env var. Builds DSN via a `dsn` property.
- **QueueSettings**: table (default `control.proofmark_test_queue`), workers (5), poll_interval_seconds (5), idle_shutdown_seconds (28800 = 8 hours).
- **AppConfig**: top-level container holding all three.

`load_app_config(settings_path)` builds from defaults + env vars, overlaid with optional YAML settings file.

### 2. Idle shutdown timer

Proofmark's `serve()` now shuts down after 8 hours of inactivity (configurable). Uses `_ActivityTracker` — thread-safe class that tracks active worker count and when the system last became fully idle. Main loop checks every second; if all workers idle for >= `idle_shutdown_seconds`, sets stop_event.

### 3. Token expansion in worker_loop

`worker_loop` accepts an optional `resolve_path` callable. `serve()` passes `config.paths.resolve`. All three paths from the queue (config_path, lhs_path, rhs_path) are resolved before use. Tests unaffected — `resolve_path` defaults to identity.

### 4. CLI simplified

Replaced `--db`, `--table`, `--workers`, `--poll-interval` with single `--settings` (optional YAML file path). `--init-db` kept.

### 5. Password scrubbed from repo

Removed hardcoded `password=claude` from `test_queue.py` and `test-architecture.md`. Test fallback DSN now reads from `ETL_DB_PASSWORD` env var.

### 6. Default table changed

Changed from `comparison_queue` (which Dan dropped) to `control.proofmark_test_queue` everywhere.

### 7. Test DSN host changed

Changed test fallback from `172.18.0.1` (Docker bridge) to `localhost`. Proofmark only runs on the host now.

### 8. Documentation restructured

- Moved original BRD/FSD/test-architecture docs to `Documentation/OriginalBuildDocs/` with deprecation notes.
- Background agent built a full new doc tree: 17 files — README routing table, overview, cli, configuration, testing, modules/ (pipeline, readers, hasher, diff, tolerance, correlator, schema, report), control/ (app-config, queue-runner).

### 9. Venv created on Hobson's clone

`/media/dan/fdrive/codeprojects/proofmark/.venv/` — Python 3.12, proofmark installed editable with queue + dev extras.

### 10. Smoke test — 23 manual test cases

Truncated `control.proofmark_test_queue`. Deleted stale output.json files from `tests/fixtures/dan_manual_test/`. Inserted 23 tasks (14 CSV, 9 Parquet). All processed successfully. 22/23 matched expected pass/fail. One known limitation: `005_should_fail_sneaky_line_break` returns PASS (mixed line break format in one line — not worth chasing).

## Phase 2 — Complete

All items in Phase 2 of the task list are done. Proofmark is running as a service from Dan's terminal.

## First Action for Next Session

Read these two files, then you're ready to work:

1. `/media/dan/fdrive/ai-sandbox/workspace/AtcStrategy/POC5/hobson-notes/poc5-task-list.md`
2. `/media/dan/fdrive/ai-sandbox/workspace/AtcStrategy/POC5/hobson-notes/job-scope-manifest.json`

Phase 3 (Original Job Baseline) is next:
- Delete any remnants from the POC4 output
- Update all original job confs to use dynamic output paths
- Run all original jobs across the full 92-day range 2024-10-01 – 2024-12-31

The ETL service (MockEtlFramework) is already running and idling. Proofmark is running and idling. Both need tasks queued to do work.

**Important context:** The poc5-task-list.md still shows Phase 1's last item unchecked ("Start running MockEtlFramework as a long-running service") even though it's done. Phase 2 items are also unchecked in the file. Update the task list at the start of next session.

## Key File Paths

| What | Path |
|------|------|
| Task list | `AtcStrategy/POC5/hobson-notes/poc5-task-list.md` |
| Job scope manifest | `AtcStrategy/POC5/hobson-notes/job-scope-manifest.json` |
| Proofmark AppConfig | `/media/dan/fdrive/codeprojects/proofmark/src/proofmark/app_config.py` |
| Proofmark queue runner | `/media/dan/fdrive/codeprojects/proofmark/src/proofmark/queue.py` |
| Proofmark CLI | `/media/dan/fdrive/codeprojects/proofmark/src/proofmark/cli.py` |
| Proofmark venv | `/media/dan/fdrive/codeprojects/proofmark/.venv/` |
| Proofmark docs | `/media/dan/fdrive/codeprojects/proofmark/Documentation/` |
| MockEtlFramework AppConfig | `/media/dan/fdrive/codeprojects/MockEtlFramework/Lib/AppConfig.cs` |
| MockEtlFramework TaskQueueService | `/media/dan/fdrive/codeprojects/MockEtlFramework/Lib/Control/TaskQueueService.cs` |
| ETL FW code (Hobson's clone) | `/media/dan/fdrive/codeprojects/MockEtlFramework/` |
| ETL FW code (BD's clone) | `/media/dan/fdrive/ai-sandbox/workspace/MockEtlFramework/` |
| Proofmark (Hobson's clone) | `/media/dan/fdrive/codeprojects/proofmark/` |
| Session wakeups | `AtcStrategy/POC5/session-wakeups/` |
| Manual test fixtures | `/media/dan/fdrive/codeprojects/proofmark/tests/fixtures/dan_manual_test/` |

All `AtcStrategy/` paths are under `/media/dan/fdrive/ai-sandbox/workspace/AtcStrategy/`.

## Standing Rule

Only Hobson makes code changes to MockEtlFramework. BD's clone is reference only (except BD can add his own RE jobs).
