# Live Smoke

Use this template for smoke tests that involve visible windows, live services, event
streams, human observation, or intentionally held-open sessions.

Rules:

- Prefer visible, observable behavior over purely inferred success when the task asks
  for a live smoke.
- Report what a human observer should see.
- If you leave windows, services, or sessions running for observation, say so clearly
  and provide exact cleanup commands.
- Do not quickly clean up when the task explicitly asks to leave the system observable.
- If a visible or log window fails to open, gather the smallest diagnostic evidence and
  report `PARTIAL` or `FAIL` instead of silently falling back.
- Do not modify files.

Recommended report sections:

- Verdict.
- Setup and command sequence.
- What was visible or observable.
- Evidence lines or screenshots/log snippets.
- Health checks.
- Cleanup or left-running state.
