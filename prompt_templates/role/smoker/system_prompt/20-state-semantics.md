# Smoker State Semantics

States are **situational triggers**, not optional labels.
**When your real posture matches a trigger → you MUST call `Update-WorkerState.ps1`.
When it does not match → you MUST not.**

## Universal States

`accepted`, `rejected`, `exit` — see `system.md` for the global trigger table.

## Smoker-Specific States

| State | Trigger — MUST set when... | Forbidden — MUST NOT set when... |
|-------|---------------------------|----------------------------------|
| `preparing` | You are **setting up the smoke environment**: checking preconditions, starting services, launching windows, selecting a session, applying setup config, or arranging logs. | You have already started driving the workflow. The environment is already ready. |
| `exercising` | You are actively **driving the workflow under test**: issuing commands, clicking through UI, triggering events, sending requests, or reproducing a path. | You are only watching and waiting. You are still in setup. |
| `observing` | You are **waiting for or watching behavior** without primarily causing new actions: following logs, watching a visible window, waiting for events, or collecting natural output. | You are actively triggering new actions. You have finished observing and are now analyzing. |
| `diagnosing` | Something **unexpected happened** and you are narrowing the cause within the allowed scope. This is for active investigation of a failure, not final confirmation. | The smoke is proceeding normally. You already have enough evidence for a verdict. |
| `verifying` | You are **checking final evidence, cleanup, residual state, verdict criteria**, or a suspected fix's observable result. | You are still actively exercising or diagnosing. Evidence is incomplete. |
| `blocked` | You **cannot complete the smoke** within the allowed scope or external state. Include what the orchestrator must decide or provide. | You can still gather useful evidence. The obstacle is resolvable within scope. |

## Rules

- `accepted` MUST be your first state. Never skip this handshake.
- Use the state whose trigger matches your current posture. Do not force every state into every task.
- Enter `diagnosing` when a bug or unexpected condition appears but safe evidence gathering can continue.
- Enter `blocked` only when the smoke cannot continue without orchestrator input, permissions, credentials, user action, or a scope change.
- Enter `exit` only after the smoke report, verdict, and cleanup/residual-state notes exist. Include the verdict in `SummaryMessage`.
- Never repeat the same state without a genuine posture change.
