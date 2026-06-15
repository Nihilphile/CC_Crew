# Smoker

## Use When

Use `smoker` when the orchestrator needs a bounded runtime smoke, live verification,
regression check, or acceptance run. This role is for exercising behavior and collecting
evidence, not implementing fixes.

Good uses include CLI smoke tests, visible-window checks, event/log pipeline checks,
process lifecycle verification, short acceptance scenarios, and regression re-tests.

## Do Not Use When

- The task is primarily source investigation before choosing an approach.
- The worker should modify files to implement or repair behavior.
- The goal is independent code review rather than runtime exercising.
- The task requires broad exploratory debugging without a bounded smoke target.

## States

`running`, `preparing`, `exercising`, `observing`, `diagnosing`, `verifying`, `blocked`, `exit`

States are posture labels, not a fixed sequence.

Common live smoke flow:

```text
running -> preparing -> exercising -> observing -> verifying -> exit
```

Bug during smoke:

```text
running -> preparing -> exercising -> diagnosing -> verifying -> exit
```

Blocked smoke:

```text
running -> preparing -> diagnosing -> blocked -> exit
```

## Normal Prompts

| Name | Use |
|------|-----|
| `live-smoke` | Visible windows, live event streams, human observation, held-open sessions. |
| `regression-smoke` | Re-test a specific prior failure or bug fix. |
| `acceptance-run` | Longer acceptance checks with multiple criteria and attempts. |

## Expected Outputs

- Smoke Report
- Regression Smoke Report
- Acceptance Run Report
- Blocker Report when no useful verdict is possible inside scope

## Orchestrator Checklist

Before sending a smoker task, provide:

- exact workflow or behavior to exercise;
- allowed commands and runtime scope;
- session names, ports, or process ownership boundaries;
- whether windows/services should be cleaned up or left running;
- PASS/PARTIAL/FAIL criteria;
- attempt/time limits;
- required evidence such as logs, event lines, screenshots, status JSON, or cleanup
  output;
- whether to use `-InjectNormal live-smoke`, `regression-smoke`, or `acceptance-run`.

