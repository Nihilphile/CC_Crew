# Focused Review

Perform a focused review of the exact artifact, change, report, or behavior assigned in
the task prompt.

Rules:

- Stay inside the assigned review scope.
- Do not modify files.
- Verify the current artifact, not stale reports.
- Prefer concrete evidence over broad commentary.
- Lead with findings; if there are no findings, state that plainly.
- Identify missing verification separately from confirmed defects.

Useful checks:

- Does the implementation match the accepted design and scope?
- Could the tests pass while real behavior is still broken?
- Are output contracts, lifecycle states, cleanup behavior, and error paths stable?
- Are documentation and examples consistent with the actual CLI or API behavior?
- Are residual risks explicit enough for the orchestrator to decide?

Exit confirmed with a summary such as: `Focused review complete: <verdict>`.
