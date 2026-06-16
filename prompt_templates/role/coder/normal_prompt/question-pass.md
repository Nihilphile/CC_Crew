# Question Pass

This reusable fragment is for long or risky implementation tasks where the orchestrator has supplied an engineering direction, but hidden decisions may affect architecture, protocol, persistence, compatibility, ownership boundaries, or test strategy.

This turn is Question Pass only unless the orchestrator explicitly says otherwise.

Rules:

- Do not modify project files.
- Read only the context needed to expose implementation decisions.
- Set `accepted` first (mandatory handshake). Use `inspecting` while reading context,
  `questioning` when surfacing orchestrator decisions, and confirmed `exit` when the
  Question Pass Report is complete.
- Distinguish confirmed facts, inferences, and open questions.
- Do not convert unresolved choices into implementation by guessing.

Write a Question Pass Report with:

- confirmed facts and relevant file paths;
- parts of the plan that are directly executable;
- implicit decisions or ambiguities;
- recommended default choices, if any, with tradeoffs;
- risks of choosing incorrectly;
- exact decisions needed from the orchestrator;
- proposed next implementation scope after decisions are made.

Exit confirmed with a summary such as: `Question pass complete: <N> decisions needed`.
