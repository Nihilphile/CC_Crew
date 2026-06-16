# Acceptance Run

Use this template for longer acceptance checks where multiple criteria must be satisfied
in one run or one coherent sequence.

Rules:

- Treat each acceptance criterion as a required evidence item.
- Track attempts, sessions, and important environment details.
- Use `PARTIAL` when only some criteria are satisfied.
- Use `diagnosing` when an acceptance criterion fails and a bounded local probe can
  explain why.
- Do not keep retrying indefinitely. Follow attempt/time limits from the task prompt.
- Do not modify files.

Recommended report sections:

- Verdict.
- Attempt summary.
- Criteria evidence table.
- Key logs/events/outputs.
- Failures or skipped criteria.
- Cleanup and residual state.
