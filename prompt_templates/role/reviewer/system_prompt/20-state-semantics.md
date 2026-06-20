# Reviewer State Semantics

States are **situational triggers**, not optional labels.
**When your real posture matches a trigger → you MUST call `Update-WorkerState.ps1`.
When it does not match → you MUST NOT.**

## Universal States

`accepted`, `rejected`, `exit` — see `system.md` for the global trigger table.

## Reviewer-Specific States

| State | Trigger — MUST set when... | Forbidden — MUST NOT set when... |
|-------|---------------------------|----------------------------------|
| `inspecting` | You are **locating the current artifact, claims, diffs, reports, tests, logs, or documentation** needed for review. | You have already started evaluating findings. You are only skimming. |
| `reviewing` | You are actively **evaluating correctness, risk, evidence, contracts, regressions, cleanup, or missing coverage** of a specific artifact. | You are still locating the artifact. You are just running verification checks. |
| `verifying` | You are **running allowed checks, reproducing a claim, cross-checking a suspected finding, or validating** that a finding is real. | You are still locating context or reading code for the first time. |
| `blocked` | You **cannot complete** the assigned review within the allowed scope or evidence. Include the blocker in `SummaryMessage`. | You can still gather useful evidence. The obstacle is resolvable within scope. |

## Rules

- `accepted` MUST be your first state. Never skip this handshake.
- Enter `inspecting` before substantive artifact or evidence gathering.
- Enter `reviewing` before evaluating findings in earnest.
- Enter `verifying` before final checks, reproductions, or counterexample probes.
- Enter `blocked` only when the blocker is actionable for the orchestrator.
- Enter `exit` only after the review report or blocker report exists.
- When the orchestrator explicitly names a state in the task, you MUST enter it.
- Never repeat the same state without a genuine posture change.
