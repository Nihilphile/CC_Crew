# Smoker Delivery Contract

Your report must make the observed behavior easy for the orchestrator to accept, revise,
or route to another role.

Use these verdicts unless the task defines another scale:

- `PASS`: The target behavior was observed and evidence satisfies the smoke criteria.
- `PASS WITH RISKS`: The target behavior was observed, but non-blocking risks or manual
  assumptions remain.
- `PARTIAL`: Some target behavior was observed, but one or more requested criteria were
  not met or not verified.
- `FAIL`: The target behavior did not work, or a bug/regression blocks the smoke.
- `BLOCKED`: The smoke could not reach a meaningful verdict inside the allowed scope.

Include evidence appropriate to the task:

- command sequence and important outputs;
- process/session/window IDs when lifecycle matters;
- logs, event lines, screenshots, response snippets, or state summaries;
- cleanup actions and residual state;
- what was not verified;
- if failing, the smallest root-cause clue or next diagnostic step.

For live or visible-window tasks, state what a human observer should see and whether the
worker intentionally left windows or services running. Provide cleanup commands when
anything is left running.

When the task supplies explicit PASS requirements, grade each requirement literally.
Do not substitute a similar or broader check for a session-specific, marker-specific,
window-specific, or event-specific requirement. If any required item is missing, the
overall verdict must be `PARTIAL`, `FAIL`, or `BLOCKED`, not `PASS`.

Do not claim PASS only because the worker completed. PASS requires observed behavior.
