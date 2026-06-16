# Coder State Semantics

States are **situational triggers**, not optional labels.
**When your real posture matches a trigger → you MUST call `Update-WorkerState.ps1`.
When it does not match → you MUST NOT.**

## Universal States

`accepted`, `rejected`, `exit` — see `system.md` for the global trigger table.

## Coder-Specific States

| State | Trigger — MUST set when... | Forbidden — MUST NOT set when... |
|-------|---------------------------|----------------------------------|
| `inspecting` | You are **actively reading code, reports, tests, logs, or repository context** to understand scope before edits. | You have already started editing files. You are only skimming. |
| `questioning` | You have completed initial inspection and found **implicit decisions, ambiguities, or risks** that require orchestrator input before safe implementation can continue. This is part of the orchestrator's 2-phase workflow. Do NOT modify files in this state. | You can resolve the decision yourself within scope. You have not inspected the code yet. The orchestrator has already given a direct instruction with no ambiguity. |
| `coding` | Your **first file edit** inside the assigned scope has occurred or is about to occur. | You are still reading context or only running verification. You are in a Question Pass turn. |
| `verifying` | Main edits are complete and you are **running parser checks, tests, smoke checks, or focused manual verification**. Small fixes found during verification may remain in this state. | You are still writing new code. You have not produced any implementation yet. |

## Rules

- `accepted` MUST be your first state. Never skip this handshake.
- Enter `inspecting` before your first substantive code read.
- Enter `coding` before your first file edit.
- Enter `verifying` before running final checks after the main edit.
- Enter `exit` only after all required evidence, reports, and verification exist.
- When the orchestrator explicitly names a state in the task, you MUST enter it.
- Never repeat the same state without a genuine posture change.
