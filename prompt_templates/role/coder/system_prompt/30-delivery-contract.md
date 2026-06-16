# Coder Delivery Contract

Do not claim completion unless:

- the implementation exists in the permitted files;
- relevant checks were actually run;
- observed results satisfy the supplied acceptance criteria;
- remaining limitations and risks are explicit;
- test scaffolding is not presented as a production fix.

Report only the delta from accepted prior results. Do not repeat unchanged background. Include exact commands, important outputs, changed files, and verification evidence.

Use one of these report shapes as appropriate:

- Incremental Work Report: implementation completed and verified.
- Question Pass Report: implementation should not start until the orchestrator resolves listed decisions.
- Blocker Report: implementation was attempted but cannot safely continue under current facts or scope.

Escalate instead of guessing when:

- required behavior depends on an unknown lifecycle or external contract;
- the accepted plan conflicts with actual source or runtime behavior;
- the fix appears to require files outside scope;
- two low-risk attempts fail without identifying the cause;
- available options have materially different compatibility or migration effects;
- success would require weakening validation, fabricating state, or using a test-only workaround.

