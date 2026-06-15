# V2 Prompt Assembly Repair Report

**Agent:** role-system-v2-prompt-assembly-coder-p  
**CommandId:** 20260616-020358-533  
**Date:** 2026-06-16  
**Role:** coder (ver1-external dispatch, p mode)

---

## Task

Fix ver2 prompt assembly P0 gaps identified by the exploration report, and synchronize state semantics text across role templates and profiles.

---

## Changes Made

### Goal A: Fix `scripts/Send-ClaudeCommand.ps1` Prompt Assembly

#### A1: `Build-SystemPrompt` — Now Assembles Full Layered System Prompt

**Before:** Only read `prompt_templates/default/system.md`. Role-specific `system_prompt/*.md` files were dead code.

**After:** Three-layer assembly:
1. `prompt_templates/default/system.md` (existing)
2. `prompt_templates/role/$Role/system_prompt/*.md` — sorted by filename, concatenated
3. `legal_state.json` summary — injected as a markdown block containing the legal states list and exit confirmation prompt text

**New signature:** `Build-SystemPrompt -Role $Role` (call site updated).

#### A2: `Build-WorkerPrompt` — Now Assembles Full Layered Worker Prompt

**Before:** Only read `prompt_templates/default/header.md`. Had a hardcoded MANDATORY COMPLETION block forcing `Complete-ClaudeTask.ps1`.

**After:** Multi-layer assembly:
1. `prompt_templates/default/header.md` with `~~ROLE~~` substitution
2. `prompt_templates/role/$Role/header_prompt/*.md` — sorted by filename, appended
3. New COMPLETION reminder (see A3)
4. `InjectNormal` block — preserved unchanged, still hard errors on missing template
5. `TASK:` + user prompt

#### A3: Completion Reminder — v2 Protocol, No Complete-ClaudeTask

**Removed:** The entire MANDATORY COMPLETION block that forced `Complete-ClaudeTask.ps1` and declared "Step 2 is non-negotiable."

**Replaced with:**
```
COMPLETION — when your work is done:
- Writing a summary to: $resultPath is optional but helpful.
- The authoritative completion signal is Update-WorkerState.ps1:
  1. First call: --exit (prints checklist, no state change).
  2. Then call: --exit -Confirm -SummaryMessage "<your summary>".
```

The `$completeScriptPath` variable still exists for backward compatibility but no longer appears in the generated prompt string.

### Goal B: State Semantics Text Fix

#### B1: Role System Prompt Files (`20-state-semantics.md`)

Modified for coder, explorer, and reviewer. Added preamble and body clarifying:

| Change | Details |
|--------|---------|
| New preamble | "States are **observable work stage labels**, not a strictly linear workflow. The typical sequence ... is an example; enter a state only when your actual work matches it." |
| `running` | Marked as **Required; never skip.** |
| `exit` | Marked as **Required; a special confirmation state.** |
| Flexibility | "You may move back and forth between X and Y as the work requires. Do not fake a state you never entered." |
| Task requirement | "When the task explicitly requires a state (e.g., 'set verifying'), you must enter it." |

#### B2: Role Profile README Files

Modified `docs/role-profiles/{coder,explorer,reviewer}/README.md` States sections to add the same clarifying language:
- States are observable labels, not strictly linear
- Flows are examples; only `running` and confirmed `exit` are mandatory
- Can move between substantive phases
- Never report unentered states

---

## Files Modified

| File | Change Type |
|------|------------|
| `scripts/Send-ClaudeCommand.ps1` | Build-SystemPrompt + Build-WorkerPrompt rewritten |
| `prompt_templates/role/coder/system_prompt/20-state-semantics.md` | Preamble + rules updated |
| `prompt_templates/role/explorer/system_prompt/20-state-semantics.md` | Preamble + rules updated |
| `prompt_templates/role/reviewer/system_prompt/20-state-semantics.md` | Preamble + rules updated |
| `docs/role-profiles/coder/README.md` | States section updated |
| `docs/role-profiles/explorer/README.md` | States section updated |
| `docs/role-profiles/reviewer/README.md` | States section updated |
| `tests/Mock-SendFixture.ps1` | 7 new tests (20-26) |
| `docs/worker-reports/role-system-v2-prompt-assembly-repair-report.md` | This report |

---

## Verification Results

### V1: Parse Check
`PowerShell Parser.ParseFile` on `Send-ClaudeCommand.ps1` → 0 errors. **PASS**

### V2: Mock-SendFixture Extended Tests (26 tests, ALL PASS)

| # | Subject | Result |
|---|---------|--------|
| 1-19 | Existing ClaudeTui.ps1 invariants | ALL PASS |
| 20 | Build-SystemPrompt reads role system_prompt files | PASS |
| 21 | Build-SystemPrompt reads legal_state.json | PASS |
| 22 | Build-WorkerPrompt reads role header_prompt files | PASS |
| 23 | MANDATORY COMPLETION + Complete-ClaudeTask removed | PASS |
| 24 | InjectNormal preserved | PASS |
| 25 | Completion reminder uses --exit protocol | PASS |
| 26 | Build-SystemPrompt called with -Role | PASS |

### V3: Live Prompt Assembly Fixture (Reviewer Role)

**System Prompt** (8127 chars): Contains default system.md + role system_prompt content + Legal States block with states list and exit_confirmation.

**Worker Prompt** (1054 chars): Contains default header + role header_prompt content (Reviewer preamble + State Reminder) + COMPLETION reminder (Update-WorkerState --exit protocol) + TASK section. No MANDATORY COMPLETION. No Complete-ClaudeTask reference.

**Worker Prompt with InjectNormal** (focused-review): INJECTED NORMAL PROMPT block present with focused-review content.

### V4: Runtime Source Grep

- `MANDATORY COMPLETION`: Only in historical worker-reports and test fixture. Zero in scripts/ or prompt_templates/.
- `non-negotiable`: Only in historical worker-reports. Zero in scripts/ or prompt_templates/.
- `Complete-ClaudeTask.ps1` in generated prompt: Zero occurrences.

### V5: Git Diff Scope

Git-tracked changes: `scripts/Send-ClaudeCommand.ps1`, `tests/Mock-SendFixture.ps1`. Role template/profile changes are disk-only. All within allowed scope. No modifications to ClaudeTui.ps1, Update-WorkerState.ps1, Complete-ClaudeTask.ps1, role normal templates, or manifest.json.

---

## What Was NOT Changed

- `Complete-ClaudeTask.ps1` — preserved as-is
- `Update-WorkerState.ps1` — untouched
- `ClaudeTui.ps1` — untouched
- Role normal_prompt templates — untouched
- `manifest.json` — untouched
- Runner script templates — untouched
- InjectNormal hard error behavior — preserved

---

## Residual Risks

1. **Worker context cache:** Workers with cached session history may retain old MANDATORY COMPLETION expectations. Fresh sessions will receive corrected prompt.

2. **Malformed legal_state.json:** Build-SystemPrompt logs warning and continues without legal state block if JSON is invalid. Rest of system prompt still assembles correctly.

3. **Coder header_prompt:** Coder role has only one header_prompt file (`10-state-reminder.md`) — no separate preamble. Assembly gracefully handles any number of files including zero.

4. **result.md optionality:** The new optional wording may cause workers to skip result summaries. This is intentional per v2 protocol where state JSON is authoritative.
