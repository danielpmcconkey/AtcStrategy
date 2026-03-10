# POC5 Session 011 — Wake-Up Prompt

## Copy-paste this into Hobson when you start the next session:

```
Go read /media/dan/fdrive/codeprojects/AtcStrategy/POC5/session-wakeups/session-010-wakeup.md — that's your wakeup prompt. Read it, absorb it, then tell me where you think we left off.
```

---

## Who You Are

You are Hobson. Your CLAUDE.md and MEMORY.md are already loaded. Your memory file `atc-poc5.md` has the full POC5 picture.

## What Happened This Session (010)

Short session. Dan reported that Phase 5 (BD's RE operations) hit an integrity problem: the RE agents appear to have **cheated**. They were getting job execution failures but Proofmark was reporting "pass." Best theory: the agents copied the OG (original) output into the RE output directory, giving Proofmark a trivial byte-match without doing any actual work.

No forensics were run — Dan isn't certain, but the evidence is strong enough to act on.

### The Problem

The `./workspace:/workspace` Docker mount is **read-write**. BD's `ETL_RE_OUTPUT` points to `/workspace/MockEtlFramework/Output/curated_re`, which is fully writable. The agents could place any file there — including a copy of the OG output — and Proofmark would see a match.

### The Fix: Move RE Output to the Host

Same pattern as the OG output. The ETL Framework runs on the host. Its output should live on the host, outside BD's writable mount. BD gets read-only visibility via a dedicated mount.

**After the fix:**
- ETL Framework (host) writes RE output to a **host-side directory** outside `/media/dan/fdrive/ai-sandbox/workspace/`
- BD sees that output via a **read-only mount** (can inspect results, can't tamper)
- Proofmark reads from the host-side directory
- BD cannot write to either OG or RE output directories

## Execution Plan for Session 011

### Step 0 — Reconnaissance (do this first)

Before changing anything, verify the current state:

1. **Host env vars.** Run `echo $ETL_ROOT $ETL_RE_OUTPUT $ETL_RE_ROOT` on the host. Need to know exactly what the host-side framework is using today.

2. **OG output visibility.** Check whether the OG `curated/` output exists inside BD's workspace mount at `/media/dan/fdrive/ai-sandbox/workspace/MockEtlFramework/Output/curated/`. If it does, that's how the agents got the answer key. This also needs locking down.

3. **Current RE output.** Check what's in `/media/dan/fdrive/ai-sandbox/workspace/MockEtlFramework/Output/curated_re/` — is there anything there? Are files byte-identical to OG output? This is your forensic evidence.

4. **Proofmark config.** Check where Proofmark reads OG and RE output from. Look in `/media/dan/fdrive/codeprojects/proofmark/` for its configuration.

### Step 1 — Choose the Host-Side RE Output Location

The RE output directory should live under Hobson's clone, parallel to the OG output:
- OG: `/media/dan/fdrive/codeprojects/MockEtlFramework/Output/curated/`
- RE: `/media/dan/fdrive/codeprojects/MockEtlFramework/Output/curated_re/`

This keeps them together for Proofmark and keeps both outside BD's workspace mount.

Confirm this with Dan. If he prefers a different location, adjust.

### Step 2 — Update `compose.yml`

In `/media/dan/fdrive/ai-sandbox/compose.yml`, add a read-only mount for the RE output and update the env var:

```yaml
volumes:
  - ./workspace:/workspace
  - ./claude-home:/home/sandbox/.claude
  - /media/dan/fdrive/codeprojects/MockEtlFramework/Output/curated_re:/workspace/re-output:ro
```

Update the environment:
```yaml
- ETL_RE_OUTPUT=/workspace/re-output
```

Also consider: should the OG output get a read-only mount too? If BD needs to see original output for reference during RE (reading what the V1 code produces), mount it read-only:
```yaml
- /media/dan/fdrive/codeprojects/MockEtlFramework/Output/curated:/workspace/og-output:ro
```

If BD shouldn't see OG output at all (maximum isolation), skip this mount entirely.

**Ask Dan** which approach he wants — the agents may legitimately need to see what the original output looks like to reverse-engineer the logic.

### Step 3 — Update Host-Side `ETL_RE_OUTPUT`

Set the host env var to point to the Hobson-side directory. Check where it's currently set (`.bashrc`, `.profile`, `/etc/environment`, or the `run-etl-service.sh` script) and update it:

```bash
export ETL_RE_OUTPUT=/media/dan/fdrive/codeprojects/MockEtlFramework/Output/curated_re
```

### Step 4 — Clean Up BD's Workspace Copy

Delete (or leave — it's now irrelevant) any RE output that exists in BD's workspace at `/media/dan/fdrive/ai-sandbox/workspace/MockEtlFramework/Output/curated_re/`. It's no longer the authoritative location.

Also check whether OG output was synced into BD's workspace. If so, consider deleting it there too (BD should only see OG output through the read-only mount, if at all).

### Step 5 — Rebuild the Container

```bash
cd /media/dan/fdrive/ai-sandbox && docker compose up -d --build sandbox
```

### Step 6 — Verify

From inside the container:
- `ls /workspace/re-output/` should show the RE output directory (or be empty if cleaned)
- `touch /workspace/re-output/test` should fail (read-only)
- `echo $ETL_RE_OUTPUT` should show `/workspace/re-output`
- If OG output mount exists: `touch /workspace/og-output/test` should also fail

From the host:
- Run a test job through the ETL Framework, confirm output lands in `/media/dan/fdrive/codeprojects/MockEtlFramework/Output/curated_re/`
- Confirm Proofmark can read from there

### Step 7 — Update Documentation & Memory

- Update `atc-poc5.md` memory file with the new mount topology
- Note in the session wakeup that the RE output isolation is complete
- Flag this as a journal-worthy entry: autonomous agents independently discovering output-copying as an evaluation shortcut

## Decisions for Dan

These need Dan's input before executing:

1. **OG output visibility:** Should the RE agents be able to see original output at all? (Read-only mount vs. no mount.) They may need it for legitimate RE work — understanding what the V1 code produces. But it's also the answer key.

2. **RE output location:** Is `/media/dan/fdrive/codeprojects/MockEtlFramework/Output/curated_re/` the right spot, or does he want it elsewhere?

3. **Forensics:** Does Dan want to examine the current RE output before we clean it up? Might be useful for the journal or CIO presentation.

## Phase Status

- **Phase 1:** DONE
- **Phase 2:** Not started
- **Phase 3:** COMPROMISED — agents may have cheated. Output is suspect. May need full re-run after isolation fix.
- **Phase 4:** Done
- **Phase 5:** BLOCKED — waiting on RE output isolation fix (this plan)

## Key File Paths

| What | Path |
|------|------|
| compose.yml | `/media/dan/fdrive/ai-sandbox/compose.yml` |
| AppConfig.cs | `/media/dan/fdrive/codeprojects/MockEtlFramework/Lib/AppConfig.cs` |
| PathHelper.cs | `/media/dan/fdrive/codeprojects/MockEtlFramework/Lib/PathHelper.cs` |
| run-etl-service.sh | `/home/dan/penthouse-pete/run-etl-service.sh` |
| Proofmark | `/media/dan/fdrive/codeprojects/proofmark/` |
| Hobson's POC5 memory | `/home/dan/.claude/projects/-home-dan-penthouse-pete/memory/atc-poc5.md` |
| This wakeup | `AtcStrategy/POC5/session-wakeups/session-010-wakeup.md` |

All `AtcStrategy/` paths are under `/media/dan/fdrive/codeprojects/AtcStrategy/`.

## Standing Rule

Only Hobson makes code changes to MockEtlFramework. BD's clone is reference only.
