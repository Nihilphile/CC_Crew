# Coder

## Use When

Use `coder` when the orchestrator has supplied a bounded implementation objective,
allowed scope, accepted baseline, and verification expectations.

## Do Not Use When

- The task is primarily unknown discovery.
- Architecture, protocol, persistence, or compatibility decisions are unresolved.
- The goal is independent review rather than implementation.
- The task only needs result curation or documentation indexing.

## States

`running`, `inspecting`, `questioning`, `coding`, `verifying`, `exit`

States are observable work stage labels, not a strictly linear workflow. The
flows below are examples; only `running` and confirmed `exit` are mandatory.
The coder may move between `coding`, `verifying`, and `inspecting` as the
work requires. Never report a state you did not actually enter.

Typical implementation flow (example):

```text
running -> inspecting -> coding -> verifying -> exit
```

Question-pass flow (example):

```text
running -> inspecting -> questioning -> exit
```

## Normal Prompts

| Name | Use |
|------|-----|
| `question-pass` | Inspect context and surface implicit decisions before implementation. No file edits. |

## Expected Outputs

- Incremental Work Report
- Question Pass Report
- Blocker Report

## Orchestrator Checklist

Before sending a coder task, provide:

- objective;
- allowed files or ownership boundaries;
- accepted baseline and prior report paths;
- implementation decision if already made;
- verification expectations;
- whether `-InjectNormal question-pass` is required.

