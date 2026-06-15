# Prompt Assembly Repair Review

## Verdict
**PASS**

All five required checks pass. The repair correctly implements the claimed behavior. No functional bugs found. One minor cleanliness note (dead variable, non-functional).

---

## Findings

### Check 1: Build-SystemPrompt Injects Default System, Role system_prompt/*.md (Sorted), and legal_state Summary

**Result: PASS**

- Source evidence: `scripts/Send-ClaudeCommand.ps1`, lines 225-267.
- The function reads `prompt_templates/default/system.md` first (line 228-232).
- It then reads and concatenates all `prompt_templates/role/$Role/system_prompt/*.md` files sorted by `Sort-Object Name` (lines 235-245).
- It then reads `prompt_templates/role/$Role/legal_state.json`, extracts `states` and `exit_confirmation`, and appends a compact markdown "Legal States" block (lines 248-264).
- Malformed `legal_state.json` is caught with a `Write-Host [WARN]` and the assembly continues without the legal block — graceful degradation.
- The call site at line 470 passes `-Role $Role`.
- Test 20 (Mock-SendFixture.ps1): Confirms role `system_prompt` path present, `Get-ChildItem` for `.md` files, `Sort-Object Name` for deterministic ordering. PASS.
- Test 21: Confirms `legal_state.json` read, states extracted, `exit_confirmation` extracted. PASS.
- Test 26: Confirms `Build-SystemPrompt` called with `-Role` parameter. PASS.

### Check 2: Build-WorkerPrompt Injects Default Header, Role header_prompt/*.md (Sorted), InjectNormal, and Task Body

**Result: PASS**

- Source evidence: `scripts/Send-ClaudeCommand.ps1`, lines 270-333.
- Reads `prompt_templates/default/header.md` and substitutes `~~ROLE~~` with the actual role name (lines 274-278).
- Appends all `prompt_templates/role/$Role/header_prompt/*.md` files sorted by `Sort-Object Name` (lines 281-291).
- Injects normal_prompt content when `$InjectNormal` is non-empty (lines 306-323). Hard errors if the file doesn't exist — behavior preserved unchanged.
- Appends `TASK:` + user prompt at end (line 331).
- Test 22 (Mock-SendFixture.ps1): Confirms role `header_prompt` path and `Get-ChildItem` for `.md` files. PASS.
- Test 24: Confirms `InjectNormal` marker preserved and hard-error behavior intact. PASS.

### Check 3: Generated Worker Prompt No Longer Forces Complete-ClaudeTask.ps1 or MANDATORY COMPLETION

**Result: PASS**

- Source evidence: `scripts/Send-ClaudeCommand.ps1`, lines 294-303 (the `$reminder` block replacing the old MANDATORY COMPLETION).
- The old block (as documented in the exploration report) was:
  ```
  MANDATORY COMPLETION - after the task, do these steps:
  1. Write a summary ... to: $resultPath
  2. Call: powershell.exe ... -File "$completeScriptPath" ...
  If task failed: add -State failed -ExitCode 1. Step 2 is non-negotiable.
  ```
- The new block is:
  ```
  COMPLETION — when your work is done:
  - Writing a summary to: $resultPath is optional but helpful.
  - The authoritative completion signal is Update-WorkerState.ps1:
    1. First call: --exit (prints checklist, no state change).
    2. Then call: --exit -Confirm -SummaryMessage "<your summary>".
  ```
- `$completeScriptPath` variable is declared on line 33 but is **never referenced** in `Build-WorkerPrompt`, confirmed by both regex search and line-by-line scan. It appears **exactly once** in the file — only at its declaration.
- Keyword scan confirms: `MANDATORY COMPLETION`, `non-negotiable`, and `Complete-ClaudeTask.ps1` (within the generated prompt string) are all absent.
- Test 23 (Mock-SendFixture.ps1): Confirms `MANDATORY COMPLETION` block removed and `Complete-ClaudeTask` not in generated prompt string. PASS.
- Test 25: Confirms the completion reminder references the `--exit` protocol. PASS.

**Minor note — dead variable:** `$completeScriptPath` is declared on line 33 but is never used after the MANDATORY COMPLETION block was removed. This is a code-cleanliness item, not a functional bug. The declaration is harmless and removing it would be a cosmetic-only change.

### Check 4: Default System Prompt Does Not Teach Role-Specific State Semantics

**Result: PASS**

- Source evidence: `prompt_templates/default/system.md`, full file (70 lines).
- **Concrete state examples used:** Only `--running` and `--exit` appear. Both are mandatory states required by all roles per the `legal_state.json` schema.
- **Generic placeholder:** `--<legal-state>` is used as a placeholder in the usage formula, not as a concrete example.
- **Role-specific states absent:** None of `--coding`, `--verifying`, `--reviewing`, `--investigating`, `--implementing`, `--inspecting`, `--questioning`, `--blocked` appear anywhere in the default system prompt.
- **Role legal-state delegation:** Line 25: "Use only states listed in your role's legal states block." This directs workers to the role-specific `legal_state.json` content injected by `Build-SystemPrompt`.
- Test 27 (Mock-SendFixture.ps1): Confirms no legacy `--implementing` state, no role-specific state examples (`--coding|--verifying|--reviewing|--investigating`), and the "Use only states listed in your role" reminder is present. PASS.

### Check 5: Tests Cover This Boundary and Still Pass

**Result: PASS**

- **All 27 tests pass** (exit code 0, no failures).
- Tests 20-26 are new tests added by this repair covering the prompt assembly changes:
  - Test 20: Build-SystemPrompt reads role system_prompt files
  - Test 21: Build-SystemPrompt reads legal_state.json
  - Test 22: Build-WorkerPrompt reads role header_prompt files
  - Test 23: MANDATORY COMPLETION + Complete-ClaudeTask removed
  - Test 24: InjectNormal preserved in Build-WorkerPrompt
  - Test 25: Completion reminder uses Update-WorkerState --exit protocol
  - Test 26: Build-SystemPrompt called with -Role
  - Test 27: Default system prompt is role-neutral
- Tests 1-19 (pre-existing) continue to pass, confirming no regressions.
- **PowerShell parser check:** `[System.Management.Automation.Language.Parser]::ParseInput` on `Send-ClaudeCommand.ps1` reports **0 errors**. PASS.

---

## Additional Consistency Checks

### Role Profiles (`docs/role-profiles/{coder,explorer,reviewer}/README.md`)

All three profiles have the updated state clarification text:
- "States are observable work stage labels, not a strictly linear workflow."
- "only `running` and confirmed `exit` are mandatory."
- "Never report a state you did not actually enter."

This matches the parallel updates in the role system_prompt `20-state-semantics.md` files. The profile text is consistent with the role prompt templates.

### State Semantics Files (`prompt_templates/role/{coder,explorer,reviewer}/system_prompt/20-state-semantics.md`)

All three files contain:
- Preamble: "States are **observable work stage labels**, not a strictly linear workflow."
- `running`: Marked as "**Required; never skip.**"
- `exit`: Marked as "**Required; a special confirmation state.**"
- Flexibility clause: "You may move back and forth between X and Y as the work requires."
- Anti-fabrication: "Do not fake a state you never entered."
- Task requirement: "When the task explicitly requires a state (e.g., 'set verifying'), you must enter it."

These changes directly address the reviewer smoke finding where the verifying state was skipped.

### Repair Report Accuracy

The repair report (`docs/worker-reports/role-system-v2-prompt-assembly-repair-report.md`) accurately describes all changes. No claimed behavior is unverified. The "What Was NOT Changed" section correctly identifies untouched files (`Complete-ClaudeTask.ps1`, `Update-WorkerState.ps1`, `ClaudeTui.ps1`, role normal templates, `manifest.json`, runner templates).

### Residual Risk Assessment

Risks identified in the repair report are valid and proportionate:

1. **Worker context cache** (risk: LOW): Fresh sessions receive corrected promp; cached sessions from old code would still follow the old protocol. This is inherent to session-based architecture — mitigated by `-FreshSession` flag availability.
2. **Malformed legal_state.json** (risk: LOW): The `catch` block logs a warning and skips the legal block. The rest of the system prompt assembles normally. Workers would lack legal-state knowledge but would still receive the role system_prompt content.
3. **Coder single header_prompt file** (risk: NONE): The `foreach` loop gracefully handles any number of files (0 to many). Confirmed working for coder role (only `10-state-reminder.md`).
4. **result.md optionality** (risk: LOW): The completion reminder marks result summaries as "optional but helpful." This is intentional per v2 protocol where the `.state` JSON (written by `Update-WorkerState.ps1`) is authoritative.
5. **Dead variable** (`$completeScriptPath`): Declared on `Send-ClaudeCommand.ps1` line 33, never used after the MANDATORY COMPLETION block was removed. Harmless — no functional impact. Cosmetic cleanup could remove it in a future pass.

---

## Summary

| Check | Verdict |
|-------|---------|
| 1. Build-SystemPrompt: default + role system_prompt + legal_state | PASS |
| 2. Build-WorkerPrompt: default header + role header_prompt + InjectNormal + task | PASS |
| 3. No forced Complete-ClaudeTask.ps1 / MANDATORY COMPLETION | PASS |
| 4. Default system prompt role-neutral (only --running/--exit as concrete examples) | PASS |
| 5. Tests cover boundary + still pass (27/27, parser clean) | PASS |
| Role profile + state-semantics consistency | PASS |
| Repair report accuracy | PASS |

**Overall Verdict: PASS** — The repair correctly implements all four goals from the exploration report (Option A). No functional bugs found. The two-layer prompt assembly (system + worker) now fully injects all role-specific template layers. The default system prompt correctly stays role-neutral and delegates role-specific state semantics to the legal_state block. All tests pass, the PowerShell parser reports zero errors, and the repair report accurately describes the changes.
