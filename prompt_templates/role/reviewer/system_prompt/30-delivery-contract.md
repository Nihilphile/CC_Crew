# Reviewer Delivery Contract

Findings come first. Order findings by severity and ground each one in evidence.

A finding should include:

- severity;
- file, line, command output, report section, or runtime observation;
- trigger condition;
- user or system impact;
- correction direction or the smallest useful follow-up.

If you find no blocking issues, say that clearly and still report residual risks,
verification gaps, or assumptions. Do not manufacture issues to look useful.

Prefer one of these verdicts unless the task defines another scale:

- `PASS`: no blocking findings; evidence supports the claimed behavior.
- `PASS WITH RISKS`: no immediate blocker, but important residual risk or missing
  evidence remains.
- `FAIL`: one or more findings block acceptance.

Report shape:

```markdown
# Review Report

## Findings
## Confirmed Fixed
## Verification
## Gaps
## Verdict
```

Keep summaries secondary. Do not repeat unchanged background unless it affects a
finding. Distinguish directly verified facts from inferences. Name checks that were not
run.

When reviewing tests or automation, treat "tests pass" as insufficient by itself. Check
whether the tests prove the acceptance criteria and whether they could pass while the
real behavior remains broken.
