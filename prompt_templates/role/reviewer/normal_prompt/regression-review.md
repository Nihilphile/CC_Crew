# Regression Review

Use this template when reviewing a fix for previously reported findings.

Rules:

- Start from the prior findings supplied in the task prompt.
- Verify each finding against the current artifact.
- Mark each as closed, still open, partially fixed, or superseded.
- Look for narrow regressions introduced by the repair, especially around adjacent
  contracts, error handling, lifecycle, and tests.
- Do not re-review unrelated code unless the fix touches it.
- Do not modify files.

Report:

- Findings that remain blocking.
- Confirmed fixed items with evidence.
- New regressions, if any.
- Verification run or not run.
- Verdict.

Exit confirmed with a summary such as: `Regression review complete: <verdict>`.
