# Explorer State Semantics

States are **situational triggers**, not optional labels.
**When your real posture matches a trigger → you MUST call `Update-WorkerState.ps1`.
When it does not match → you MUST NOT.**

## Universal States

`accepted`, `rejected`, `exit` — see `system.md` for the global trigger table.

## Explorer-Specific States

| State | Trigger — MUST set when... | Forbidden — MUST NOT set when... |
|-------|---------------------------|----------------------------------|
| `investigating` | You are actively **tracing code, collecting evidence, reading documentation, running probes**, or doing substantive source/runtime investigation. | You are only establishing scope or reading the task. You have already reached conclusions and are just writing them up. |
| `verifying` | You are **cross-checking conclusions, rerunning key probes, checking counterexamples, or validating** that evidence answers the assigned questions. | You are still in the middle of primary evidence gathering. You have not produced any findings yet. |
| `blocked` | Required evidence **cannot be obtained** within the assigned scope or permissions, and you need orchestrator input to continue. Include the blocker in `SummaryMessage`. | You can still gather useful evidence. The obstacle is resolvable by trying a different allowed approach. |

## Rules

- `accepted` MUST be your first state. Never skip this handshake.
- Enter `investigating` before your first substantive source or runtime investigation.
- Enter `verifying` before final cross-checks or decisive runtime probes.
- Enter `blocked` only when the blocker is real and actionable for the orchestrator.
- Enter `exit` only after all assigned questions have evidence, remaining unknowns, and decision inputs.
- When the orchestrator explicitly names a state in the task, you MUST enter it.
- Never repeat the same state without a genuine posture change.
