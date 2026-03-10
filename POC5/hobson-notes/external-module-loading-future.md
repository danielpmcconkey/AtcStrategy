# External Module Loading — Future Plans

Written 2026-03-09, session 009. Not a POC5 deliverable — this is forward-looking for POC6+.

---

## The Problem

BD's RE agents need to create External modules (custom C# classes implementing `IExternalStep`). The current pipeline has three friction points:

1. **Build required.** External modules compile into `ExternalModules.dll`. A `.cs` file on disk does nothing until `dotnet build` runs.
2. **Build can only happen on the host.** BD has a read-only copy of MockEtlFramework. The real codebase lives on Hobson's side. BD cannot run `dotnet build`.
3. **Assembly caching.** `Assembly.LoadFrom()` in `External.cs:30` caches by path. Once the DLL is loaded into the running process, a rebuilt DLL on disk is invisible until the service restarts.

### POC5 Workaround

BD stops and tells Dan to rebuild. Dan ctrl+C's the running service, runs `~/penthouse-pete/run-etl-service.sh` (git pull → dotnet build → restart). Manual, but acceptable for a POC where the human is nearby.

---

## Option A: AssemblyLoadContext (Stay in C#)

.NET's `AssemblyLoadContext` (ALC) is a first-class API designed for plugin architectures. Microsoft's own docs include a tutorial for this exact pattern ("Create a .NET application with plugins").

### How It Works

Replace `Assembly.LoadFrom()` in `External.cs` with:

```csharp
var alc = new AssemblyLoadContext("External_" + Guid.NewGuid(), isCollectible: true);
var assembly = alc.LoadFromAssemblyPath(resolvedPath);
var type = assembly.GetType(typeName);
var instance = Activator.CreateInstance(type) as IExternalStep;
var result = instance.Execute(sharedState);
alc.Unload();
```

### What It Solves

- **Friction point 3 (assembly caching):** Eliminated. Each invocation loads the DLL fresh into an isolated, unloadable context. No service restart needed.

### What It Doesn't Solve

- **Friction point 1 (build required):** Still need `dotnet build` after every new or changed `.cs` file.
- **Friction point 2 (build location):** BD still can't build. Someone on the host must pull and build. This requires either Dan in the loop, a file watcher script, or Hobson monitoring for changes.

### Trade-offs

- ~20 lines of code change. Surgical. No impact on existing modules, configs, or tests.
- Strong typing and compile-time checking fully preserved.
- The `IExternalStep` interface stays in `Lib` (shared assembly). External modules reference it. Clean separation.
- GC delay before unloaded assemblies are actually freed — irrelevant at POC scale.
- The compile-and-pull dance remains. ALC removes one step (restart) but leaves two (build + sync).

---

## Option B: Rewrite Framework in Python

Replace MockEtlFramework with a Python equivalent. External modules become `.py` files loaded via `importlib.util.spec_from_file_location()`.

### How It Works

```python
import importlib.util
spec = importlib.util.spec_from_file_location(module_name, file_path)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
step = getattr(mod, class_name)()
return step.execute(shared_state)
```

### What It Solves

- **All three friction points.** No compilation. No DLL. No caching. BD writes a `.py` file to a shared directory and the framework loads it on the next job invocation. The entire pipeline collapses to a single step.

### What It Costs

- Framework rewrite: ~5,400 LOC. Estimated 2-3 Claude sessions.
- 73 external modules rewritten: ~6,700 LOC. Formulaic, 2-3 Claude sessions.
- Validation against Proofmark: 2-3 sessions (compute time is the bottleneck, not Claude time).
- Total: roughly a week of sessions.
- Existing Proofmark-validated equivalence (POC3 Run 2: 32 jobs, 100%) must be re-established from zero.
- Test suite (~2,540 LOC) rewritten.

### Technical Feasibility (confirmed by research)

| Concern | Assessment |
|---------|------------|
| DataFrame | pandas. Maps 1:1 to the existing custom DataFrame API. |
| Parallelism / GIL | Not a problem. Workload is I/O-bound (Postgres, file writes). GIL released during I/O. N threading.Thread workers mirrors the C# model exactly. |
| Parquet | pyarrow. DateOnly → datetime.date. Native support. |
| CSV | stdlib csv module. RFC 4180, configurable line endings, trailer format — all covered. |
| PostgreSQL | psycopg3 (or psycopg2). Advisory locks, connection pooling, date types — all solved. |
| SQLite transforms | sqlite3 stdlib. Or pandasql for DataFrame-native SQL. |
| Hot-reload | importlib. Load from arbitrary path, fresh every time, no caching. |

### Trade-offs

- No compile-time type checking. Runtime errors instead of build errors. Mitigated by tests, but fundamentally different safety profile.
- Proofmark is already Python. Framework + validation tool in the same language simplifies the stack.
- Dan doesn't maintain the codebase directly — Hobson does. The "maintainer resents the language" concern doesn't apply.
- Agents are at least as fluent in Python as C#. Possibly more so for generating external modules on the fly.

---

## Comparison

| | Option A (ALC) | Option B (Python) |
|---|---|---|
| Friction points removed | 1 of 3 (restart) | 3 of 3 (compile, sync, restart) |
| Code change | ~20 lines | Full rewrite (~12K LOC + tests) |
| Effort | 1 session | ~1 week of sessions |
| Risk to existing validation | None | Must re-validate from zero |
| BD autonomy | Still needs host-side build | Fully autonomous |
| Type safety | Preserved | Lost (runtime errors) |
| Agent workflow | Write .cs → commit → host pulls → host builds → next invocation loads | Write .py → next invocation loads |

---

## Recommendation

For POC5: neither. The manual rebuild script is sufficient. BD is already running RE operations and the human-in-the-loop cost is manageable.

For POC6, where the goal involves interactivity between the basement and the host: the Python rewrite becomes significantly more attractive. The compile-and-sync dance is tolerable when a human is nearby; it's a serious bottleneck for autonomous overnight execution. If POC6 needs agents creating and iterating on external modules without human intervention, Option B is the cleaner path.

Option A (ALC) is the right answer if the framework stays in C# long-term and the build step can be automated reliably (e.g., a host-side file watcher that triggers `dotnet build` on changes). It's low-risk and surgical. But it doesn't eliminate the fundamental friction of a compiled language in an agent-driven workflow.

---

## POC6 — Two-Model Architecture

### The Constraint

In production, PCI-DSS and PII data cannot leave the company's approved infrastructure. Dan's company trusts Copilot / OpenAI in Azure for data-adjacent work. Claude (Anthropic API) is not approved for customer data. This isn't a preference — it's a regulatory boundary.

### The Architecture

Two LLMs, two roles, strict data separation:

| Role | Model | Location | Data Access |
|------|-------|----------|-------------|
| **RE agents** | Claude Sonnet / Opus | Basement (Docker sandbox) | V1 source code (read-only), Proofmark results, profiler responses. No customer data. |
| **Data profiler** | Haiku 4.5 (simulating Copilot/Azure OpenAI) | Host side | Production data. Can run queries, describe distributions, characterize edge cases, identify null patterns, report value ranges. |

### How It Works

- RE agents in the basement do the hard work: read V1 code, infer requirements, write specs, build V2 modules, run through Proofmark.
- When an agent needs to understand the data — "what's the cardinality of column X," "are there nulls," "what date range does this job actually process" — it posts a question to a shared queue (Postgres).
- The host-side profiler picks up the question, queries prod data, and posts back a statistical summary. No raw customer records cross the boundary — just profiles, distributions, and schema descriptions.
- The RE agent reads the answer and continues its work.

### Why This Demands the Python Rewrite

The RE agents are in a tight iteration loop:

1. Write module
2. Run it via ETL FW
3. Check Proofmark results
4. Ask the profiler about an unexpected data pattern
5. Adjust the module
6. Repeat

Every iteration that requires a compile step, a git sync, or a human restarting a service breaks the autonomous overnight execution goal. Python's hot-reload (`importlib`) eliminates all of that friction. The agent writes a `.py` file, the framework picks it up on the next run, no intermediary steps.

### What POC6 Proves

- That a two-model architecture can deliver autonomous RE at scale within real-world compliance constraints.
- That the data profiler provides sufficient fidelity for RE agents to build correct modules — without ever exposing customer data to the RE model.
- That the host/basement boundary works as a genuine security perimeter, not just a convention.

