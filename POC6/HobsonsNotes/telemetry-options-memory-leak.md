# Proofmark Queue Runner — Memory Profiling Options

**Date:** 2026-03-12
**Context:** The queue runner (`queue.py`) processes CSV comparison tasks via
5 `threading.Thread` workers, each running `worker_loop`. Memory grows from
~38% to ~66% after ~440 tasks and task completion time degrades
catastrophically. The existing `del report; gc.collect()` at line 199 is not
sufficient to arrest the growth. This document surveys instrumentation options.

---

## Architecture Summary (for reference)

Each worker thread:
1. Claims a task from PostgreSQL (`claim_task` — uses `FOR UPDATE SKIP LOCKED`)
2. Calls `pipeline.run()` which:
   - Loads YAML config (`load_config`)
   - Reads two CSV files into `list[dict[str, Any]]` via `CsvReader`
   - Hashes every row into `HashedRow` objects (each carrying `row_data`, `fuzzy_values`, `unhashed_content`)
   - Diffs via hash-grouping into `DiffResult` (with `UnmatchedRow` lists)
   - Correlates unmatched rows (O(n*m) heap-based pairing)
   - Builds a report dict
3. Serializes report to JSON, writes it to PostgreSQL (`mark_succeeded`)
4. Deletes the report reference and calls `gc.collect()`

Each worker holds one persistent `psycopg2` connection for its lifetime.

**Likely leak suspects:** `pipeline.run()` creates substantial intermediate
objects (ReaderResult, HashedRow lists, DiffResult, CorrelationResult) that
should all be local to `run()` and eligible for collection once the report
dict is built and serialized. The report dict itself is `del`'d in
`worker_loop`. If memory still grows, something is holding references —
possibly psycopg2 internals, the YAML/PyArrow loaders, or an accumulating
data structure we haven't spotted.

---

## 1. Per-Task RSS Tracking

### Option 1A: `resource.getrusage` (stdlib, zero-install)

**What it measures:** Peak RSS (`ru_maxrss`) for the process as a whole. On
Linux this is in KB. It's a high-water mark — it never decreases — so it
tells you "memory has grown" but not "by how much this task."

**Integration:**
```python
import resource

def worker_loop(...):
    # ... inside the task processing block, after mark_succeeded:
    rss_kb = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
    logger.info("[%s] task %d done | peak_rss=%d KB", label, task_id, rss_kb)
```

**Overhead:** Negligible. Single syscall.

**Thread safety:** `RUSAGE_SELF` reports process-wide stats. Cannot
distinguish per-thread. But logging it after every task gives a monotonic
growth curve, which is what we need for the first pass.

**Limitation:** High-water mark only. If one task spikes RSS and then memory
is freed, the metric stays at the spike. Useful for confirming growth but not
for measuring per-task delta.

### Option 1B: `psutil.Process().memory_info()` (pip install psutil)

**What it measures:** Current RSS (not peak), VMS, shared, etc. Because it
reads `/proc/self/status` it reflects the *current* state, not a high-water
mark. Taking a reading before and after each task gives you a per-task delta.

**Integration:**
```python
import psutil
_proc = psutil.Process()

def worker_loop(...):
    # ... before calling pipeline.run():
    rss_before = _proc.memory_info().rss
    report = run(...)
    # ... after del report; gc.collect():
    rss_after = _proc.memory_info().rss
    delta_mb = (rss_after - rss_before) / (1024 * 1024)
    logger.info(
        "[%s] task %d | rss_before=%.1f MB rss_after=%.1f MB delta=%.2f MB",
        label, task_id,
        rss_before / (1024*1024), rss_after / (1024*1024), delta_mb,
    )
```

**Overhead:** ~0.1ms per call. Reads from `/proc`. Entirely negligible versus
the cost of a CSV comparison.

**Thread safety:** Process-wide metric. Multiple threads reading concurrently
is fine (no locking needed for reads). The delta is noisy because other
workers are running simultaneously, but over hundreds of tasks you'll see the
trend. For precise per-task attribution, run in single-worker mode (see
Section 5).

**Note:** `psutil` is not in proofmark's dependencies. Would need to be added
to `[project.optional-dependencies]` or installed alongside. It's already
available system-wide on this machine.

### Option 1C: Direct `/proc/self/statm` read (zero-install, zero-import)

**What it measures:** Same as psutil but without the dependency. RSS in pages.

**Integration:**
```python
import os

def _rss_mb():
    """Current RSS in MB, from /proc."""
    with open(f"/proc/{os.getpid()}/statm") as f:
        pages = int(f.read().split()[1])
    return pages * os.sysconf("SC_PAGE_SIZE") / (1024 * 1024)
```

**Overhead:** Negligible. One file read.

**Thread safety:** Same as 1B — process-wide, safe to read from any thread.

**Recommendation:** Start with 1C (zero dependencies, current RSS, works
immediately). Upgrade to 1B if you want richer metrics (VMS, USS, shared).

---

## 2. Object Growth Tracking

### Option 2A: `tracemalloc` (stdlib)

**What it measures:** Per-allocation tracking. Can snapshot the heap and
compare snapshots to show which lines of code allocated memory that wasn't
freed. The gold standard for Python-level leak hunting.

**Integration — lightweight (top-N growth between snapshots):**
```python
import tracemalloc

# At process start (e.g., top of serve()):
tracemalloc.start(10)  # 10 frames of traceback per allocation

# In worker_loop, take snapshots periodically:
if task_count % 50 == 0:
    snap = tracemalloc.take_snapshot()
    # Store on a module-level or pass through; compare to previous:
    if _prev_snap is not None:
        top = snap.compare_to(_prev_snap, 'lineno')
        for stat in top[:10]:
            logger.info("[%s] tracemalloc: %s", label, stat)
    _prev_snap = snap
```

**Overhead:** The `nframes` argument controls depth vs. overhead. `nframes=1`
adds ~10-20% overhead and ~30% memory overhead for the tracking tables
themselves. `nframes=10` is heavier. For a stress test of 440 tasks this is
fine. For a "leave it running in production" scenario, probably too much.

**Thread safety:** `tracemalloc` is **process-global**. `take_snapshot()` is
thread-safe (acquires the GIL), but the snapshot captures allocations from
*all* threads. You cannot filter by thread in the snapshot. However, the
traceback frames tell you *which code path* allocated, which is more useful
than knowing which thread — since all workers run the same code.

**Key strength:** This is the tool most likely to pinpoint the leak. It will
show you lines like "pipeline.py:77 allocated 4.2 MB that wasn't freed" with
full traceback context.

### Option 2B: `objgraph` (pip install objgraph)

**What it measures:** Object counts by type. `objgraph.growth()` shows types
whose instance count increased since the last call. `objgraph.show_backrefs()`
traces reference chains to explain *why* an object isn't collected.

**Integration:**
```python
import objgraph

# In worker_loop, periodically:
if task_count % 50 == 0:
    growth = objgraph.growth(limit=15)
    for typename, count, delta in growth:
        logger.info("[%s] objgraph: %s count=%d delta=+%d",
                    label, typename, count, delta)
```

**To trace a specific leak (interactive/single-worker):**
```python
# Find what's holding onto dict objects:
objgraph.show_backrefs(
    objgraph.by_type('dict')[:5],
    filename='/tmp/backref-graph.png',
    max_depth=5,
)
```

**Overhead:** `growth()` iterates all objects in the heap via
`gc.get_objects()`. On a heap with millions of objects this can take seconds
and will pause all threads (GIL). Fine for a debugging session, not for
production-like stress tests.

**Thread safety:** `gc.get_objects()` acquires the GIL. All other threads are
paused during iteration. This is safe but introduces stop-the-world pauses.

**Not currently installed.** `pip install objgraph`. Optional dependency on
`graphviz` for the PNG backref graphs.

### Option 2C: `pympler` (pip install pympler)

**What it measures:** `pympler.tracker.SummaryTracker` shows per-type memory
growth with actual byte counts (not just object counts). More informative than
objgraph for understanding memory impact.

**Integration:**
```python
from pympler import tracker

# Create one tracker per worker, or one global:
tr = tracker.SummaryTracker()

# In worker_loop, periodically:
if task_count % 50 == 0:
    tr.print_diff()  # prints to stdout; or use tr.diff() for programmatic access
```

**Overhead:** Similar to objgraph — iterates `gc.get_objects()` and computes
`sys.getsizeof()` for each. Heavier than objgraph because of the size
computation. A few seconds of GIL-held pause on a large heap.

**Thread safety:** Same GIL story as objgraph. Safe but pauses all threads.

**Not currently installed.** `pip install pympler`.

### Option 2D: `gc.get_objects()` + manual counting (stdlib, zero-install)

**What it measures:** You can roll your own lightweight version of objgraph:

```python
import gc
from collections import Counter

def _type_census():
    counts = Counter(type(o).__name__ for o in gc.get_objects())
    return counts.most_common(20)
```

**Overhead:** Same as objgraph — iterates all objects under the GIL.

**Advantage:** Zero install. Useful if you don't want to add dependencies to
the proofmark venv.

---

## 3. Per-Worker Thread Profiling

### The fundamental problem

CPython's memory allocator (`pymalloc`) is **process-global**. There is no
per-thread heap. `malloc`/`free` calls from any thread draw from the same
pool. Neither `tracemalloc` nor `psutil` can attribute memory to a specific
thread. This is a hard limitation of CPython + the OS memory model.

### Workaround 3A: Per-worker task counter + process RSS correlation

Tag every log line with the worker ID (already done — `label = f"worker-{worker_id}"`).
Log RSS after every task. Since all workers share the same process RSS, the
attribution is indirect, but you can:

- Correlate RSS spikes with which worker completed a task at that moment
- Run with `workers=1` to isolate completely (see Section 5)

### Workaround 3B: `tracemalloc` filtering by traceback

While you can't filter by thread, you can filter by filename/lineno. If you
suspect the leak is in a specific module (e.g., `csv_reader.py` or
`psycopg2`), filter the snapshot:

```python
snap = tracemalloc.take_snapshot()
filtered = snap.filter_traces([
    tracemalloc.Filter(True, "*/csv_reader.py"),
])
for stat in filtered.statistics('lineno')[:10]:
    logger.info(stat)
```

### Workaround 3C: `threading.current_thread()` in custom allocator hooks

Python 3.12+ added `sys.monitoring` but not per-thread allocation hooks. Not
practical for this use case. The thread workarounds above are the realistic
options.

### Workaround 3D: Multiprocessing instead of threading (redesign)

If per-worker memory isolation becomes essential, switching from `threading`
to `multiprocessing` (or `concurrent.futures.ProcessPoolExecutor`) would give
each worker its own address space. Then `psutil.Process(pid)` gives you true
per-worker RSS. This is a bigger change and probably not warranted until the
leak's root cause is identified.

---

## 4. Low-Overhead Options (leave running during stress tests)

These can be enabled for all 440+ task runs without distorting the
reproduction:

| Tool | Overhead | What you get |
|------|----------|-------------|
| `/proc/self/statm` (Option 1C) | ~0 | RSS after every task. Growth curve. |
| `resource.getrusage` (Option 1A) | ~0 | Peak RSS after every task (monotonic). |
| `tracemalloc.start(1)` | ~10-15% CPU, ~30% memory | Per-line allocation tracking. Snapshot every N tasks. |
| `gc.get_stats()` | ~0 | Collection counts, uncollectable object counts per generation. |

### Recommended low-overhead instrumentation bundle:

```python
import gc
import os
import tracemalloc

# At startup:
tracemalloc.start(1)  # shallow tracebacks, lower overhead
_prev_snapshot = [None]  # mutable container for thread access

def _rss_mb():
    with open(f"/proc/{os.getpid()}/statm") as f:
        return int(f.read().split()[1]) * os.sysconf("SC_PAGE_SIZE") / (1024**2)

# In worker_loop, after each task completes:
rss = _rss_mb()
gc_stats = gc.get_stats()  # per-generation stats
uncollectable = sum(s.get('uncollectable', 0) for s in gc_stats)
logger.info(
    "[%s] task %d | rss=%.1f MB | uncollectable=%d",
    label, task_id, rss, uncollectable,
)

# Every 50 tasks (from any one worker):
if task_count % 50 == 0:
    snap = tracemalloc.take_snapshot()
    if _prev_snapshot[0] is not None:
        top = snap.compare_to(_prev_snapshot[0], 'lineno')
        for stat in top[:10]:
            logger.info("[mem] %s", stat)
    _prev_snapshot[0] = snap
```

This adds negligible time per task and gives you: (a) an RSS growth curve,
(b) whether objects are genuinely uncollectable (reference cycles the GC
can't break), and (c) periodic tracemalloc diffs pinpointing where the growth
is happening.

### `gc.get_stats()` — checking for uncollectable objects

If `uncollectable > 0` grows over time, you have reference cycles involving
objects with `__del__` methods. This would be a smoking gun. Worth checking
first — it's free.

```python
gc.set_debug(gc.DEBUG_UNCOLLECTABLE)  # logs uncollectable objects to stderr
```

---

## 5. High-Detail Options (focused debugging session)

For a single-threaded deep dive. Set `workers=1` in the config or via a
settings YAML override, then:

### Option 5A: `tracemalloc` with deep tracebacks

```python
tracemalloc.start(25)  # 25 frames — expensive but full traceback context

# After every task:
snap = tracemalloc.take_snapshot()
top = snap.statistics('traceback')
for stat in top[:5]:
    logger.info("%.1f KiB in %d blocks", stat.size / 1024, stat.count)
    for line in stat.traceback.format():
        logger.info("  %s", line)
```

**Overhead:** 30-50% CPU, 2-3x memory. Only viable with 1 worker.

### Option 5B: `memray` (pip install memray)

**What it measures:** Native memory profiler for Python. Tracks *all*
allocations including C extensions (psycopg2, PyArrow, hashlib). Produces
flame graphs and temporal allocation plots.

**Integration (CLI, no code changes):**
```bash
# Record a run:
python -m memray run -o proofmark.bin -m proofmark.cli serve --workers 1

# Generate flame graph:
python -m memray flamegraph proofmark.bin -o flamegraph.html

# Generate temporal plot (shows growth over time):
python -m memray temporal proofmark.bin -o temporal.html
```

**Or attach to a running process:**
```bash
python -m memray attach <pid>
```

**Overhead:** 20-50% depending on allocation rate. Records every
`malloc`/`free`. Produces large trace files. Single-worker mode recommended.

**Thread safety:** memray instruments at the C level and handles threads
correctly. It tracks which thread made each allocation. This is the *only*
tool listed here that provides true per-thread attribution.

**Not currently installed.** `pip install memray`. Requires Python 3.12+ for
`attach` mode; `run` mode works on 3.11+.

**Key strength:** Captures C-extension allocations (psycopg2's libpq buffers,
PyArrow's Arrow memory pool). If the leak is in native code rather than
Python objects, tracemalloc won't see it but memray will.

### Option 5C: `objgraph.show_backrefs` for specific object types

Once you've identified the leaking type via tracemalloc or objgraph.growth(),
trace exactly *what* is holding the reference:

```python
import objgraph
# e.g., if dicts are growing:
objgraph.show_backrefs(
    objgraph.by_type('dict')[-5:],  # 5 newest dicts
    max_depth=7,
    filename='/tmp/dict-backrefs.png',
)
```

This produces a Graphviz PNG showing the reference chain from GC roots to
your leaked objects. Very effective for "aha" moments.

### Option 5D: `gc.get_referrers()` (stdlib, zero-install)

Manual version of objgraph's backref tracing:

```python
import gc

# After 100 tasks, find what's holding HashedRow objects:
hashed_rows = [o for o in gc.get_objects() if type(o).__name__ == 'HashedRow']
if hashed_rows:
    sample = hashed_rows[0]
    referrers = gc.get_referrers(sample)
    for ref in referrers:
        logger.info("Referrer type=%s", type(ref).__name__)
```

---

## 6. Specific Suspicions to Instrument

Based on the code review, here are the most likely leak vectors, ranked:

### 6A: psycopg2 connection/cursor state accumulation

Each worker holds one persistent `psycopg2` connection. If the connection
caches query results, plan metadata, or notices internally, that could grow.
The `json.dumps(report)` in `mark_succeeded` creates a potentially large
string that's passed to `cur.execute()`. Check whether psycopg2 holds
references to parameter values after `commit()`.

**Test:** Log `sys.getsizeof(conn)` (won't capture internal C buffers, but
worth checking). The real test: periodically close and reopen the connection
(e.g., every 50 tasks) and see if the growth stops.

### 6B: `json.dumps(report)` creating large strings

The `report_json = json.dumps(report)` in `mark_succeeded` (line 87) creates
a string that could be multi-MB for tasks with many mismatches. This string
is passed to psycopg2 which may copy it into libpq's buffer. The Python
string should be freed after `commit()`, but if psycopg2 holds a reference
internally, it won't be.

### 6C: YAML loader caching

`yaml.safe_load` may cache parsed schemas or anchors. If configs reuse
anchors/aliases, the loader might hold references. Less likely since
`load_config` opens/closes the file each time, but worth checking with
tracemalloc.

### 6D: `logging` module handler accumulation

If log handlers or formatters are being created per-task (unlikely from the
code, but worth ruling out), the logging module's internal dicts could grow.
Check with `len(logging.getLogger().handlers)` periodically.

### 6E: Module-level caches or class-level state

`importlib.metadata.version()` (called in `report.py:_get_version()`) may
cache package metadata. Low impact per call but called once per task.

---

## 7. Recommended Investigation Order

1. **Quick wins (zero-install, low-overhead):**
   - Add RSS logging via `/proc/self/statm` after every task
   - Add `gc.get_stats()` logging to check for uncollectable objects
   - Run the 440-task stress test and confirm the growth curve

2. **tracemalloc (stdlib, moderate overhead):**
   - Enable `tracemalloc.start(1)` at startup
   - Take snapshots every 50 tasks, log `compare_to` diffs
   - This should identify the leaking module/line within one run

3. **If tracemalloc points to Python code:**
   - Use `objgraph` or `gc.get_referrers()` to trace who's holding the reference
   - Fix the reference holder

4. **If tracemalloc shows no growth but RSS still grows:**
   - The leak is in C extensions (psycopg2/libpq, PyArrow, hashlib)
   - Use `memray` in single-worker mode to trace native allocations
   - Test the "reconnect every N tasks" hypothesis for psycopg2

5. **If the leak is in psycopg2:**
   - Add periodic connection cycling to `worker_loop` (reconnect every 50 tasks)
   - Or switch to `psycopg` (v3) which has a different connection model
