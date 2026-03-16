# Analysis: Stdout JSON Parsing Failures

**Date:** 2026-03-15 (Session 21)
**Affected jobs:** 2 (Publish/Haiku), 8 (FBR_EvidenceAudit/Opus), 10 (ExecuteProofmark/Haiku)

## Symptom

Agents complete their work correctly — process artifacts are written to disk
with valid outcomes — but the engine's `_parse_outcome` returns
`Outcome.FAILURE` anyway. The engine never sees the agent's success, routes
the job into retry/triage/dead-letter, and burns retries on work that's
already done.

## The Parsing Pipeline

```
Claude CLI (--output-format json)
  → subprocess.run captures stdout
  → json.loads(stdout) → cli_response
  → cli_response["result"] → agent's conversational text
  → _extract_outcome_json(text) → hunt for last {"outcome": "..."} block
  → _OUTCOME_MAP lookup → Outcome enum
```

Four failure points, any of which returns `Outcome.FAILURE`:
1. **Non-zero exit code** — CLI crashed, never reach parsing
2. **CLI JSON parse failure** — stdout isn't valid JSON
3. **No outcome JSON found** — `_extract_outcome_json` returns None
4. **Unknown outcome string** — not in `_OUTCOME_MAP`

## Root Cause Hypothesis: #3 is the dominant failure mode

The `_extract_outcome_json` parser is structurally fragile. It splits the
agent's full text output on `{`, then for each fragment tries to build a
valid JSON object by scanning forward through `}` characters. It's looking
for the last flat JSON object containing an `"outcome"` key.

The problem: **the agent's text output is not just the outcome JSON.** The
`result` field from `--output-format json` contains the agent's entire
conversational response — all the narration around tool calls, file reads,
code blocks, reasoning, etc. In a typical agent run, this text might contain:

- Dozens of `{` characters from JSON files the agent read or wrote
- Nested JSON structures (jobconf.json, proofmark configs, test results)
- Markdown code blocks containing JSON examples
- The agent's own stdout contract JSON somewhere in the middle or end

The parser's strategy of splitting on `{` and trying candidates creates a
combinatorial mess. Specifically:

1. **Early `{` characters consume the search.** The parser builds candidates
   starting from each `{`. If an early candidate produces valid JSON that
   happens to contain an `"outcome"` key from a quoted/nested context, it
   stops there (the `break` on line 231 exits the inner loop on first valid
   parse, even if it's not the outcome block).

2. **Flat-only parsing.** The parser walks forward through `}` to find the
   first valid close. This means it can only find flat JSON objects — if the
   outcome JSON is inside a code block or preceded by other braces, the
   parser builds a candidate that starts mid-object and fails.

3. **Agent verbosity scales the problem.** Opus agents produce longer, more
   detailed responses than Sonnet. More text = more `{` characters = more
   candidates that can confuse the parser. This explains why Opus
   (FBR_EvidenceAudit, job 8) isn't immune despite being smarter.

4. **The "last match wins" design is correct in principle** but relies on
   the parser actually finding all matches. If an earlier candidate parses
   as valid JSON with an `"outcome"` key (from a quoted snippet the agent
   was discussing), the inner `break` moves to the next split without
   checking if it's the *right* outcome block.

## Why the process artifact exists but the engine doesn't see it

The agents write process artifacts to disk themselves using bash/file tools
during execution. This is independent of the engine's parsing — the agent
uses `write_text()` or bash `cat` to save its results to
`{job_dir}/process/{NodeName}.json`.

The engine's `_parse_outcome` *also* writes process artifacts (line 186-189),
but only when it successfully parses the outcome. When parsing fails, the
engine returns FAILURE and never writes — but the agent's self-written file
is already on disk from the execution phase. This creates the confusing
state where the artifact says SUCCESS but the engine saw FAILURE.

## Evidence

- **Job 2 (Publish, Haiku):** 5 consecutive Publish failures. Deployment
  actually succeeded (files on disk, control.jobs registered). Haiku is
  more likely to fumble structured output, but 5/5 is suspicious — suggests
  a systematic parsing issue, not random flakiness.

- **Job 8 (FBR_EvidenceAudit, Opus):** Process artifact shows Pat approved
  with flying colors. Opus produced a detailed, multi-field JSON response.
  The length and complexity of Opus's response likely means more `{`
  characters in the conversational text, increasing parser confusion.

- **Job 10 (ExecuteProofmark, Haiku):** 31/31 strict pass. Triage agent
  itself noted "triage triggered by process failure, not data failure."

## Not Haiku-specific

Session 20's wakeup doc blamed Haiku for Publish and ExecuteProofmark. Job 8
proves it affects Opus too. The common factor isn't model quality — it's the
fragility of extracting structured data from unstructured conversational
output.

## Proposed Fixes (priority order)

### 1. Process artifact fallback (quick win)
If `_extract_outcome_json` returns None, check whether the agent already
wrote a process artifact to disk. If `{process_dir}/{node_name}.json`
exists and contains a valid outcome, use that instead of failing. The agent
already did the work — honor it.

### 2. Focused retry on parse failure (backlog item)
When parsing fails but the agent exited cleanly (returncode 0), re-invoke
with a short, focused prompt: "Your previous run completed but the outcome
JSON was not found in stdout. Read your process artifact at {path} and
return ONLY the outcome JSON block." One retry, Haiku, cheap.

### 3. Structured output via tool use
Instead of hunting for JSON in conversational text, define a Claude tool
(function) that the agent must call to report its outcome. Tool call
parameters are always structured JSON — no parsing ambiguity. This is the
right long-term fix but requires changes to the CLI invocation pattern.

### 4. Delimiter-based extraction
Have blueprints instruct agents to wrap their outcome in a unique delimiter
(e.g., `<<<OUTCOME>>>...<<<OUTCOME>>>`). Parse between delimiters instead
of splitting on `{`. Simpler than tool use, more reliable than current
approach, but relies on agent compliance.

## Impact

3 out of 13 batch-12 jobs (23%) hit this bug. All three had correct work
products on disk. Zero actual quality problems — purely a reporting/parsing
failure. The engine is killing jobs that succeeded.
