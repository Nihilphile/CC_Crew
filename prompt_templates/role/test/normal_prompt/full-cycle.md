# Full Lifecycle Probe

Selected normal marker: `V2_TEST_NORMAL_FULL_C6E2`

Exercise the complete positive lifecycle without modifying the runtime under test:

1. Call `--accepted` with summary `full-cycle accepted`, then wait at least three
   seconds.
2. Call `--coding` with summary `creating seeded artifact`, then wait at least three
   seconds. Create the task's temporary JSON artifact with `actual` deliberately set
   to a value different from `expected`.
3. Call `--debugging` with summary `repairing seeded defect`, then wait at least three
   seconds. Parse the artifact, prove the mismatch exists, and change `actual` to
   equal `expected`.
4. Call `--reviewing` with summary `validating corrected artifact`, then wait at least
   three seconds. Re-open the artifact from disk, validate its JSON shape and equality,
   and add the observed system, header, normal, and task markers to its evidence.
5. Call `--exit` without confirmation. Verify that this only prints the role's exit
   checklist and does not replace the current `reviewing` state.
6. Call `--exit -Confirm -SummaryMessage` with a summary containing
   `V2_TEST_EXIT_SUMMARY_OK`.

Do not write `result.md`. Do not call deprecated completion helpers. Do not create an
`.exit` file.

