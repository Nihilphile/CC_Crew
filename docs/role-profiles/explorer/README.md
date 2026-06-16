# Explorer

## Use When

Use `explorer` when the orchestrator needs targeted facts before choosing an
implementation direction.

Good explorer tasks ask bounded questions about code paths, runtime behavior,
dependencies, contracts, regressions, or feasible options.

## Do Not Use When

- The implementation direction is already decided and the task is ready for coding.
- The goal is independent review of a finished change.
- The task requires broad ownership decisions rather than evidence gathering.
- The worker would need to modify production files.

## States

`accepted`, `rejected`, `investigating`, `verifying`, `blocked`, `exit`

States are **situational triggers** — when your posture matches a trigger, you MUST set that state. When not, you MUST NOT. `accepted` (handshake) and `exit` are mandatory for every worker. After `accepted`, enter the state whose trigger matches your real current phase.

State selection notes:

- Use `investigating` during targeted source, document, log, or runtime probing.
- Use `verifying` when cross-checking conclusions, rerunning probes, or checking
  counterexamples.
- Use `blocked` when the assigned question cannot be answered inside the authorized
  read/run scope and the orchestrator needs to provide a decision, permission,
  credential, or narrower question.
- End with confirmed `exit` when the requested evidence or blocker note exists.

## Normal Prompts

| Name | Use |
|------|-----|
| `architecture-trace` | Trace a subsystem, dependency direction, or event/control flow. |
| `question-pass` | Identify missing decisions and inputs before implementation. |
| `runtime-probe` | Run bounded probes to distinguish source assumptions from runtime behavior. |

## Expected Outputs

- Exploration Report
- Decision inputs for the orchestrator
- Reproducible command/log evidence when runtime behavior matters
- Blocker summary when evidence cannot be obtained inside scope

## Orchestrator Checklist

Before sending an explorer task, provide:

- exact questions to answer;
- allowed read and execution scope;
- files, reports, or logs to treat as baseline;
- whether the explorer may run commands;
- what would count as enough evidence to stop.
