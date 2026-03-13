# RCA: Proofmark Queue Runner Memory Leak — Pipeline Analysis

**Date:** 2026-03-12
**Author:** Hobson
**Status:** Analysis complete — awaiting implementation

## Symptoms

- Memory climbs from ~38% to ~66% over ~440 tasks with no plateau
- Mean completion time degrades from 0.04s to 11.75s (max 78.6s single task)
- `gc.collect()` after each task + persistent DB connections did not arrest the leak
- Degradation is progressive and correlates with task count, not task size

---

## Root Cause Candidates

### 1. PyArrow Memory Pool Fragmentation (CRITICAL — Parquet mode)

**File:** `proofmark/readers/parquet.py:30-52`

PyArrow maintains a **process-global memory pool** (jemalloc or system malloc) that
backs all Arrow buffers. The reader does the following per task:

```python
tables.append(pq.read_table(pf))          # allocates Arrow buffers
combined = pa.concat_tables(tables)        # more Arrow buffers
rows = combined.to_pylist()                # copies to Python objects
```

After `to_pylist()`, the Arrow `Table` and `RecordBatch` objects go out of scope
and *should* be freed. However:

- PyArrow's memory pool does **not return freed pages to the OS** by default. It
  holds them for reuse. `gc.collect()` reclaims the Python wrappers but the
  underlying Arrow pool retains the allocation. This is why RSS climbs while
  Python's `gc` reports nothing held.
- `pa.concat_tables()` creates a new table that references the originals, then
  the result and the originals share a moment of overlapping liveness. With many
  part-files per directory, this doubles peak allocation per task.
- The `tables` list accumulates all part-file tables before concatenation. If a
  comparison directory has 20 part-files at 50 MB each, that's 1 GB allocated in
  the Arrow pool *before* concatenation even starts, and 2 GB at peak.

**Severity:** CRITICAL if the workload is parquet. This is the most likely
primary cause of the RSS climb — the Arrow pool never shrinks.

**Fix:** After converting to `pylist`, explicitly release Arrow memory:

```python
del combined, tables
pa.default_memory_pool().release_unused()
```

Or use `pa.system_memory_pool()` as the allocator which returns pages to the OS
more aggressively.

---

### 2. Large Intermediate Data Structures in `pipeline.run()` (HIGH)

**File:** `proofmark/pipeline.py:69-176`

Every call to `run()` creates the following objects that are all live
simultaneously at line 166 (the `build_report` call):

| Object | Type | Held Until |
|---|---|---|
| `lhs_result.rows` | `list[dict]` | end of `run()` |
| `rhs_result.rows` | `list[dict]` | end of `run()` |
| `lhs_hashed` | `list[HashedRow]` | end of `run()` |
| `rhs_hashed` | `list[HashedRow]` | end of `run()` |
| `diff_result` | contains `hash_groups`, `all_unmatched_*` | end of `run()` |
| `correlation` | `CorrelationResult` | end of `run()` |
| `report` (returned dict) | deep nested dict | until `del report` in queue.py |

For a 100,000-row comparison, the raw rows alone are ~200K dicts. The hashed
rows duplicate all non-excluded column values into `row_data` AND
`unhashed_content` (a pipe-joined string of every value). That's roughly 3-4x
the input data living in memory simultaneously.

These *should* all be freed when `run()` returns and the caller does `del report;
gc.collect()`. But they won't be freed promptly if:

- CPython's cyclic GC doesn't collect generation-2 objects on every `gc.collect()`
  call (it does, but only if the threshold is met).
- Any reference cycle exists among these objects.

**The real problem** isn't that these aren't freed — it's that the **peak memory
footprint per task** is enormous, and with 5 workers running concurrently, the
combined peak is 5x that. If tasks overlap in the allocation phase, the process
can spike to multi-GB before any task completes.

**Severity:** HIGH. Not a leak per se, but the cause of the degradation
and the high watermark that never recedes (due to #1 or malloc fragmentation).

**Fix:** Break `run()` into phases and explicitly `del` intermediate
structures when no longer needed:

```python
# After hashing, rows are no longer needed
del lhs_result, rhs_result

# After diffing, hashed rows are no longer needed
del lhs_hashed, rhs_hashed
```

---

### 3. HashedRow Duplicates Row Data Three Ways (HIGH)

**File:** `proofmark/hasher.py:52-75`

Each `HashedRow` stores:

- `hash_key` — 32-char hex string
- `unhashed_content` — pipe-joined string of ALL non-excluded column values
- `fuzzy_values` — dict of fuzzy column name -> value
- `row_data` — dict of ALL non-excluded column name -> value

`unhashed_content` and `row_data` are **redundant representations of the same
data**. For a row with 30 columns, `row_data` is a 30-key dict and
`unhashed_content` is a ~500-char string that encodes the same information.

This means the hasher phase roughly **triples** the memory footprint of the
input data (original rows + hashed rows containing two copies each).

**Severity:** HIGH. This is a design-level amplification factor, not a leak, but
it directly multiplies the impact of every other issue.

**Fix:** Defer `row_data` construction — only build it for unmatched rows in
`diff.py`, where it's actually needed (for the correlator). Or compute
`unhashed_content` on the fly from `row_data` instead of storing both.

---

### 4. Correlator O(n^2) Heap with Retained Row Data (MEDIUM)

**File:** `proofmark/correlator.py:46-57`

```python
for i, lhs_row in enumerate(sorted_lhs):
    for j, rhs_row in enumerate(sorted_rhs):
        ...
        if score > 0.5:
            heapq.heappush(heap, (-score, i, j, differing))
```

The heap stores a `differing` list (column names) for every candidate pair above
0.5 similarity. With N unmatched LHS rows and M unmatched RHS rows, the heap can
hold up to N*M entries. For a badly mismatched comparison (say 1,000 unmatched on
each side), that's up to 1,000,000 heap entries, each containing a list of
column name strings.

The `sorted_lhs` and `sorted_rhs` lists also hold references to `UnmatchedRow`
objects which contain `row_data` dicts — so the entire unmatched row data is
pinned in memory for the duration of correlation.

In practice, most Proofmark runs have few mismatches, so this is unlikely to be
the *primary* leak. But for failing comparisons it could spike hard.

**Severity:** MEDIUM. Quadratic blowup only for high-mismatch comparisons.

**Fix:** Cap the heap size. Prune candidates below a tighter threshold or limit
unmatched rows sent to the correlator.

---

### 5. `json.dumps(report)` in `mark_succeeded` Creates a Large Transient String (MEDIUM)

**File:** `proofmark/queue.py:87`

```python
report_json = json.dumps(report)
```

This serializes the entire report dict (which includes all hash group details,
surplus rows, correlation pairs, etc.) into a single Python string. For a large
mismatch report, this string can be tens of megabytes. It's passed to psycopg2
which copies it again into a libpq buffer.

The `report_json` string is scoped to `mark_succeeded` and should be freed when
the function returns. However, Python's string allocator (pymalloc) may not
return small-block arenas to the OS if even one allocation in the arena is still
live. With 5 workers, each producing and discarding multi-MB strings,
fragmentation is inevitable.

**Severity:** MEDIUM. Contributes to RSS creep via malloc fragmentation rather
than a true reference leak.

**Fix:** Stream the JSON to the database using `psycopg2`'s `copy` protocol
or `io.StringIO`, avoiding the intermediate string. Or serialize with
`orjson.dumps()` which returns bytes and has better allocation behaviour.

---

### 6. CSV Reader Holds Entire File in Memory as Multiple Forms (LOW-MEDIUM)

**File:** `proofmark/readers/csv_reader.py:25-85`

The CSV reader simultaneously holds:

- `raw_bytes` — the entire file as bytes
- `text` — the entire file decoded to a string
- `lines` — the file split into a list of strings
- `data_lines` — a subset of `lines`
- `data_text` — `data_lines` re-joined into a single string (line 78)
- The `csv.reader` iterator over `data_text`
- `rows` — the parsed list of dicts

At peak (around line 80-85), the file content exists in at least 4 forms
simultaneously: `raw_bytes`, `text`, `lines`/`data_lines`, and `data_text`.
For a 50 MB CSV, that's ~200 MB just in the reader before a single row dict is
built.

These are all function-local and freed on return, but with 5 workers each
reading a file simultaneously, the combined spike is significant.

**Severity:** LOW-MEDIUM. Transient, but contributes to peak memory and
therefore to fragmentation.

**Fix:** Stream the CSV instead of slurping it. Read `raw_bytes`, detect line
endings, then immediately `del raw_bytes`. Parse `text` directly with
`csv.reader` rather than splitting into lines and re-joining.

---

### 7. `diff()` Closure Captures (LOW)

**File:** `proofmark/diff.py:106-111`

```python
def sort_key(row: HashedRow) -> tuple:
    fuzzy_part = tuple(
        _null_safe_sort_val(row.fuzzy_values.get(col.name))
        for col in fuzzy_columns
    )
    return (fuzzy_part, row.unhashed_content)
```

This closure is defined inside a `for key in sorted(all_keys):` loop. A new
`sort_key` function object is created on every iteration of the outer loop,
each capturing `fuzzy_columns` from the enclosing scope. The function objects
are short-lived (used only for `sorted()` and then discarded), but in a tight
loop with thousands of hash groups, this creates thousands of closure objects.

**Severity:** LOW. Closures are tiny and freed promptly. Negligible.

**Fix:** Move `sort_key` outside the loop (it doesn't depend on `key`).

---

### 8. `defaultdict` References in `diff()` (LOW)

**File:** `proofmark/diff.py:58-64`

```python
lhs_groups: dict[str, list[HashedRow]] = defaultdict(list)
rhs_groups: dict[str, list[HashedRow]] = defaultdict(list)
```

These group all hashed rows by hash key. They remain live for the entire
duration of `diff()`, meaning all `HashedRow` objects (with their `row_data`
dicts) are pinned until `diff()` returns. The `DiffResult` returned from `diff()`
references `UnmatchedRow` objects that were freshly created from `HashedRow` data —
so at the moment `diff()` returns, BOTH the grouped originals and the unmatched
copies exist simultaneously before the caller can free the originals.

**Severity:** LOW. Standard Python function scoping. Not a leak, but amplifies
peak memory.

**Fix:** None needed beyond the `del lhs_hashed, rhs_hashed` suggested in #2.

---

## Summary and Prioritized Recommendations

| Priority | Issue | Type | Fix Effort |
|---|---|---|---|
| 1 | PyArrow memory pool never releases to OS | True leak (pool-level) | Low — add `release_unused()` |
| 2 | Intermediate structures live too long in `run()` | Peak amplification | Low — add `del` statements |
| 3 | HashedRow stores redundant row representations | Design amplification | Medium — refactor hasher |
| 4 | `json.dumps` transient string fragmentation | Fragmentation | Low — use `orjson` or streaming |
| 5 | CSV reader multi-form file buffering | Peak amplification | Medium — streaming reader |
| 6 | Correlator O(n^2) heap | Conditional blowup | Low — cap heap size |
| 7 | `diff()` closure per hash group | Negligible | Trivial |

**If these are parquet comparisons**, fix #1 alone will likely arrest the RSS
climb. The Arrow pool is the only component that retains memory across `run()`
invocations at the C level, invisible to Python's `gc`.

**If these are CSV comparisons**, the leak is almost certainly CPython malloc
fragmentation caused by the combined effect of #2, #3, #5, and #6. Each task
allocates then frees hundreds of thousands of small Python objects (dicts,
strings, lists). pymalloc's arena allocator cannot return partially-occupied 256
KB arenas to the OS, so RSS ratchets upward even though Python considers the
memory "free." The fix there is to reduce peak per-task allocation (fixes #2,
#3) and consider running workers as subprocesses rather than threads, so the OS
reclaims all memory when the subprocess exits.

**The time degradation** (0.04s to 11.75s) is a secondary effect. As RSS climbs
past physical RAM, the kernel starts swapping or reclaiming page cache. File I/O
(reading CSVs/parquet from disk) that was previously served from page cache now
hits disk, and Python's allocator spends more time searching free lists in
fragmented arenas.

---

## Recommended Implementation Order

1. **Add `del` for intermediate structures in `pipeline.run()`** — zero risk,
   immediate reduction in peak memory per task.
2. **If parquet: add `pa.default_memory_pool().release_unused()`** in the
   parquet reader after `to_pylist()` and `del tables, combined`.
3. **Switch from threads to `ProcessPoolExecutor`** in `queue.py` — each
   comparison runs in a child process whose entire address space is reclaimed on
   exit. This is the nuclear option that eliminates *all* fragmentation-based
   leaks. The DB connection stays in the main process; only `run()` moves to the
   child.
4. **Refactor hasher to not duplicate row data** — medium effort, large payoff
   for ongoing memory efficiency.
