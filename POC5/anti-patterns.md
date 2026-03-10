# Master Anti-Pattern List

**Source:** Consolidated from POC2 Phase 3 Anti-Pattern Analysis and POC3 Wrinkle Manifest
**Purpose:** Definitive list of code-quality anti-patterns that reverse engineering teams must identify and eliminate in rewrites. These are the things V1 code does badly that V2 code must do better.

---

## The List

### AP1 — Dead-End Sourcing
Config sources tables or data that are never referenced in processing logic. Wasted I/O, misleading configs, maintenance confusion.

*POC2 origin. Also absorbs POC2's "wrong-table lookups" and "redundant re-sourcing" — both were specific instances of sourcing data that serves no purpose.*

### AP2 — Duplicated Logic
Job re-derives data that another job already computes. Produces the same value through a separate code path instead of sourcing the existing output. Maintenance nightmare — change the business logic in one place, forget the other. Consistency risk across the portfolio.

*New in POC3.*

### AP3 — Unnecessary External Module
C# External module where a SQL Transformation + standard DataFrameWriter would suffice. Adds a source file, a class, a build dependency, and a maintenance surface for zero functional benefit.

*POC2 origin. In POC2, agents actually worsened this — adding External modules to jobs that were originally SQL-only.*

### AP4 — Unused Columns
Config sources columns that are never referenced in processing or output. Cousin of AP1 but at the column level. Obscures what the job actually needs.

*POC2 origin (was "silent column drops" — same concept, broader framing).*

### AP5 — Asymmetric Null/Default Handling
Inconsistent treatment of NULL/empty/default values across similar operations within the same job. E.g., null in one field becomes "Unknown", null in another becomes 0, null in a third stays null — with no documented rationale for the differences.

*POC2 origin.*

### AP6 — Row-by-Row Iteration
foreach loops processing records individually where a SQL set operation (GROUP BY, JOIN, WHERE) would be cleaner, faster, and more correct. Classic imperative-thinking-in-a-declarative-context problem. Performance killer at real data volumes.

*New in POC3. Most heavily planted anti-pattern — 19 of 70 jobs.*

### AP7 — Magic Values
Hardcoded business thresholds, date boundaries, string literals, and numeric constants with no parameterization, no documentation, and no indication of where they came from. E.g., `$500`, `"High"`, `'2024-10-01'`, `3.0` standard deviations.

*POC2 origin.*

### AP8 — Complex/Dead SQL
Unused CTEs, unnecessary window functions, redundant subqueries — SQL complexity that computes values never used in the final output. Cognitive overhead with no functional purpose.

*POC2 origin (was "unused CTEs/window functions" — broadened to cover all dead SQL complexity).*

### AP9 — Misleading Names
Job names, table names, or column names that contradict what the code actually produces. E.g., "MonthlyTransactionTrend" that outputs daily rows, "quarterly" KPIs computed daily.

*POC2 origin.*

### AP10 — Over-Sourcing Date Ranges
Jobs source broad date ranges (or entire tables) through DataSourcing config, then immediately filter down in the SQL transformation WHERE clause. Wastes I/O and memory. The date filtering should happen at the sourcing level.

*POC2 origin.*
