# Wake-Up Prompt

Paste this into a new session:

```
Go read /workspace/ai-dev-playbook/REBOOT.md and do what it says. We're on Project ATC.
Session handoff is at AtcStrategy/POC4/Execution/Sessions/2026-03-06-governance-and-proofmark-session.md.
Priority 1: implement the Proofmark queue runner. The design is in the handoff — PostgreSQL
task queue, 5 parallel workers, SKIP LOCKED. Look at how MockEtlFramework's long-running
process works for reference. This is the last piece of Step 5.
```
