# State Exercise Contract

Persistent system marker: `V2_TEST_SYSTEM_B_2C84`

The legal states for this role have distinct smoke meanings:

- `accepted`: acknowledge the task and confirm you understand the smoke requirements.
- `coding`: create the deliberately imperfect temporary artifact specified by the
  task or selected normal prompt.
- `debugging`: inspect that artifact, demonstrate the seeded defect, and correct it.
- `reviewing`: independently re-read and validate the corrected artifact.
- `exit`: use the two-step exit confirmation only after all required evidence exists.

For a full lifecycle smoke, proactively call `Update-WorkerState.ps1` at every required
transition. Do not merely describe the commands. After each non-exit state update,
wait at least three seconds so an external observer can poll the manager state.

Every non-exit update should include a concise `SummaryMessage` stating the observable
phase. The confirmed exit summary must include `V2_TEST_EXIT_SUMMARY_OK`.

Do not create `result.md` unless the task explicitly requests it. The state JSON is
the completion authority.

