# V2 Prompt Assembly Exploration Report

**Agent:** v2-prompt-assembly-explorer-001  
**Role:** explorer  
**CommandId:** 20260616-015707-163  
**Date:** 2026-06-16  
**Scope:** Read-only investigation of the prompt assembly chain in Send-ClaudeCommand.ps1, triggered by reviewer smoke findings.

---

## Questions

| # | Question | Status |
|---|----------|--------|
| Q1 | What is the actual prompt assembly chain in Send-ClaudeCommand.ps1? Does default/system, role/system_prompt, legal_state, default/header, role/header_prompt, normal_prompt, and task prompt each enter generated files? | Answered |
| Q2 | Does the generated worker prompt still force Complete-ClaudeTask.ps1? Where in source, and what is the generated evidence? | Answered |
| Q3 | Can the missing prompt layers explain the reviewer smoke's verifying-state skip and missing Verification/Gaps sections? | Answered |
| Q4 | What is the minimal fix scope, with suggested implementation boundary? | Answered |
| Q5 | Can the explorer follow the state flow: running -> investigating -> verifying -> exit confirmed? | In progress |

---

## Confirmed Facts

### F1: System Prompt - Role system_prompt Is Never Injected

**Source:** `scripts/Send-ClaudeCommand.ps1`, lines 220-231.

```powershell
$templatesDir = Join-Path $skillRoot "prompt_templates\default"

function Build-SystemPrompt {
    $sysPath = Join-Path $templatesDir "system.md"
    if (Test-Path -LiteralPath $sysPath -PathType Leaf) {
        return (Get-Content -LiteralPath $sysPath -Raw -Encoding UTF8).Trim()
    }
    return ""
}
```

- The function reads **only** `prompt_templates/default/system.md`.
- It never reads `prompt_templates/role/$Role/system_prompt/*.md`.
- The role-specific system_prompt directory exists for all four roles (coder, explorer, reviewer, test) with 2-3 numbered `.md` files each, but they are **dead code in the prompt assembly path**.

**Evidence - Current explorer run system prompt** (`run/v2-prompt-assembly-explorer-001/run-command-20260616-015707-163.system.txt`):
Contains only the default "Worker Runtime Contract (v2)" - a generic document about Update-WorkerState.ps1 usage. No mention of explorer role boundary, explorer state semantics, or explorer delivery contract.

**Evidence - Reviewer smoke system prompt** (`run/v2-reviewer-smoke-001/run-command-20260616-015105-174.system.txt`):
Identical default system prompt. No reviewer role boundary, no reviewer state semantics, no reviewer delivery contract.

### F2: Worker Header - Role header_prompt Is Never Injected

**Source:** `scripts/Send-ClaudeCommand.ps1`, lines 233-241.

```powershell
function Build-WorkerPrompt {
    param([string]$UserPrompt)
    $headerPath = Join-Path $templatesDir "header.md"   # <-- defaults dir, NOT role
    $header = "[worker]\nYou are a $Role agent. Execute the task, then complete."
    if (Test-Path -LiteralPath $headerPath -PathType Leaf) {
        $header = (Get-Content -LiteralPath $headerPath -Raw -Encoding UTF8).Trim()
        $header = $header -replace '~~ROLE~~', $Role
    }
    ...
```

- Only `prompt_templates/default/header.md` is used (`[worker]\nYou are a ~~ROLE~~ agent. Execute the task, then complete.`).
- `prompt_templates/role/$Role/header_prompt/*.md` files exist but are **never read**.
- The role header_prompt files contain role-specific preambles and state reminders that would guide worker behavior.

### F3: InjectNormal Is Correctly Implemented

**Source:** `scripts/Send-ClaudeCommand.ps1`, lines 245-262.

```powershell
$injectBlock = ""
if ($InjectNormal) {
    $normalFile = Join-Path $skillRoot "prompt_templates\role\$Role\normal_prompt\$InjectNormal.md"
    ...
    $normalContent = (Get-Content -LiteralPath $normalFile -Raw -Encoding UTF8).Trim()
    ...
    $injectBlock = @"

INJECTED NORMAL PROMPT: $InjectNormal (role: $Role)
$normalContent
"@
}
```

- This is the **only** role template layer that works correctly.
- `-InjectNormal` is passed through from the manager (ClaudeTui.ps1 line 679) and read from the correct role directory.

### F4: Complete-ClaudeTask.ps1 Is FORCED Hardcoded in Every Generated Prompt

**Source:** `scripts/Send-ClaudeCommand.ps1`, lines 264-276.

```powershell
return @"
$header
Automated pipeline. No confirmation needed. No exploring beyond the task.

MANDATORY COMPLETION - after the task, do these steps:
1. Write a summary of what you did to: $resultPath
2. Call: powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$completeScriptPath" -AgentName "$AgentName" -CommandId "$commandId" -ResultPath "$resultPath" -DonePath "$donePath"
If task failed: add -State failed -ExitCode 1. Step 2 is non-negotiable.
$injectBlock
TASK:
$UserPrompt
"@
```

- `$completeScriptPath` is resolved at line 33: `Join-Path $skillRoot "scripts\Complete-ClaudeTask.ps1"`.
- This block appears **verbatim** in every generated prompt, no conditionals, no bypass.
- The hardcoded text `Step 2 is non-negotiable` creates a direct conflict with the v2 protocol where `Update-WorkerState --exit --Confirm` is the authoritative lifecycle signal.

**Generated evidence - Reviewer smoke prompt** (`run/v2-reviewer-smoke-001/run-command-20260616-015105-174.prompt.txt`, lines 5-8):
```
MANDATORY COMPLETION - after the task, do these steps:
1. Write a summary of what you did to: ...20260616-015105-174.result.md
2. Call: powershell.exe ... -File "...Complete-ClaudeTask.ps1" -AgentName "v2-reviewer-smoke-001" ...
If task failed: add -State failed -ExitCode 1. Step 2 is non-negotiable.
```

**Generated evidence - Current explorer prompt** (`run/v2-prompt-assembly-explorer-001/run-command-20260616-015707-163.prompt.txt`, lines 5-8):
Same pattern with explorer-specific paths.

### F5: Complete-ClaudeTask.ps1 Self-Declares DEPRECATED

**Source:** `scripts/Complete-ClaudeTask.ps1`, lines 177-183.

```powershell
# DEPRECATED (v2): .exit signal is no longer written by Complete-ClaudeTask.
# In v2, the worker lifecycle is managed via Update-WorkerState --exit --Confirm,
# which writes the .state JSON and .exit signal. The manager reads .state for
# the authoritative exit status. Complete-ClaudeTask is kept as a convenience
# stub for writing result/done files but is no longer required by the worker prompt.
# The manager's Sync-ReadState detects exit from .state JSON, not from .exit here.
```

- The completion script **itself** says it's deprecated and "no longer required by the worker prompt."
- But the **prompt builder still forces it** - a direct internal contradiction.

### F6: legal_state.json Is Never Injected Into Generated Prompts

- `Send-ClaudeCommand.ps1` has **zero references** to `legal_state.json`.
- The manager (ClaudeTui.ps1) validates that `legal_state.json` exists during preflight (line 673) but never passes its content to Send-ClaudeCommand.
- The worker's only knowledge of legal states comes from: (a) the *examples* in the default system prompt, which use generic states like `--implementing` and `--running`, and (b) the task prompt text itself.
- For the reviewer, the legal states are `running, inspecting, reviewing, verifying, blocked, exit` - but the worker never receives this list via the prompt assembly.

### F7: manifest.json Documents Intent That Code Does Not Fulfill

**Source:** `manifest.json`, line 42.

```json
"system_prompt": "prompt_templates/default/system.md + role system_prompt/*.md (--system-prompt-file, layered)"
```

The manifest explicitly documents layered system prompts (default + role). The code never implements the role layer. This is either a documentation-aspiration gap or an implementation that was planned but never completed.

### F8: The Reviewer Smoke State File Shows No verifying Entry

**Evidence:** `run/v2-reviewer-smoke-001/.20260616-015105-174.state` (final state only):
```json
{
    "state": "exit",
    "confirmed": true,
    "summary_message": "Focused review complete: PASS (with note)..."
}
```

- `Update-WorkerState.ps1` **overwrites** the state file on each call - only the last state persists.
- Without logging/timestamped state history, we cannot definitively prove the reviewer never called `--verifying` from the state file alone. However, the orchestrator's smoke report states the reviewer only went `running -> inspecting -> reviewing -> exit`, which the orchestrator would have observed from the `current_state` field in `agents.json`.

### F9: The Reviewer Smoke Result Lacks Required Sections

**Evidence:** `store/v2-reviewer-smoke-001/results/20260616-015105-174.result.md`

The reviewer delivery contract (`prompt_templates/role/reviewer/system_prompt/30-delivery-contract.md`) requires:
```markdown
# Review Report

## Findings
## Confirmed Fixed
## Verification
## Gaps
## Verdict
```

The actual result contains:
- `## Scope`
- `## Artifact Under Review`
- `## Findings`
- `## Verdict`
- `## Residual Risks`

**Missing:** `## Verification` and `## Gaps` sections. No `## Confirmed Fixed` section (though that may be inapplicable for a smoke test).

---

## Inferences

### I1: Missing Role System Prompt Causes Worker to Not Know State Semantics or Delivery Contract

The reviewer role's `20-state-semantics.md` defines what each state means and when to use it (e.g., "Set `verifying` before final checks, reproductions, or counterexample probes"). The `30-delivery-contract.md` mandates the `## Verification` and `## Gaps` report sections. Neither file reaches the worker.

**Inference confidence:** HIGH. Without these instructions in the system prompt, the worker relies solely on:
1. The default system prompt (generic Update-WorkerState reference with non-reviewer examples like `--implementing`).
2. The task prompt text (which did say "设置状态 verifying" but didn't define its semantics).
3. The InjectNormal `focused-review` block (which says "Identify missing verification separately from confirmed defects" but doesn't mandate report section headers).

A Claude agent without explicit role contract in system-level instructions would reasonably skip a state it doesn't understand the purpose of and structure output according to general good practices rather than a specific template.

### I2: Complete-ClaudeTask.ps1 Forcing Creates Protocol Confusion

The worker receives two competing completion signals:
1. **Hardcoded prompt:** "Step 2 is non-negotiable" -> call Complete-ClaudeTask.ps1.
2. **Default system prompt:** "The ONLY worker-facing lifecycle/state interface is Update-WorkerState.ps1" with exit confirmation gate.

**Inference confidence:** HIGH. The reviewer smoke worker called both Complete-ClaudeTask.ps1 (per the prompt mandate) AND Update-WorkerState --exit (per the system prompt). This dual protocol may have distracted from proper state sequencing (the worker focused on meeting the explicit "non-negotiable" step rather than the semantic state progression).

### I3: The Fix Is Localized to One File

All missing prompt layers converge on `Send-ClaudeCommand.ps1`:
- `Build-SystemPrompt` (line 225) -> add role system_prompt concatenation.
- `Build-WorkerPrompt` (line 233) -> add role header_prompt prepend; remove/conditionalize Complete-ClaudeTask block.
- The manager (ClaudeTui.ps1) and Update-WorkerState.ps1 do not need changes.

**Inference confidence:** HIGH. No other file in the chain touches prompt assembly.

### I4: The Role-Specific Delivery Contract Would Have Changed Reviewer Output

Had the reviewer received `30-delivery-contract.md` in its system prompt, it would have seen the explicit report template with `## Verification` and `## Gaps` sections. The Claude model is highly responsive to markdown template instructions at the system level.

**Inference confidence:** MEDIUM-HIGH. We cannot prove counterfactually, but the template is specific and unambiguous, and the model followed the task prompt's other directives (state setting, scope limitation) closely.

---

## Options

### Option A: Minimal Fix - Two Functions in Send-ClaudeCommand.ps1

**Scope:** `scripts/Send-ClaudeCommand.ps1` only.

1. **Modify `Build-SystemPrompt`** (lines 225-231) to:
   - Read `prompt_templates/default/system.md` (existing).
   - Read and concatenate all `prompt_templates/role/$Role/system_prompt/*.md` files sorted by filename.
   - Append them with a separator like `\n\n---\n\n`.

2. **Modify `Build-WorkerPrompt`** (lines 233-276) to:
   - Read and prepend `prompt_templates/role/$Role/header_prompt/*.md` files (sorted) before the default header, OR replace the default header with role header.
   - Remove the hardcoded MANDATORY COMPLETION block and replace with a reference to Update-WorkerState --exit --Confirm (matching the default system prompt).
   - Keep InjectNormal as-is (already working).

3. **Optionally:** Inject a compact summary of `legal_state.json` (legal states list + exit confirmation text) into the prompt so the worker knows its state vocabulary without needing to read the file.

**Implementation boundary:** Only the `Build-SystemPrompt` and `Build-WorkerPrompt` functions. No changes to:
- `ClaudeTui.ps1` (manager already passes Role; no new parameters needed)
- `Complete-ClaudeTask.ps1` (already self-deprecated)
- `Update-WorkerState.ps1` (unchanged)
- Any other script or template

**Estimated lines changed:** ~30-40 lines in one file.

### Option B: Remove Complete-ClaudeTask Dependency Entirely

Adds to Option A:
- Remove `$completeScriptPath` variable (line 33).
- Remove the MANDATORY COMPLETION block from `Build-WorkerPrompt` entirely.
- Keep `Complete-ClaudeTask.ps1` as a convenience script but stop injecting it.
- The worker prompt would only reference `Update-WorkerState --exit --Confirm` as the completion protocol.

**Risk:** Workers that don't yet understand the `--exit --Confirm` protocol might not know how to finish. Mitigation: the default system prompt already explains it thoroughly.

### Option C: Template-Driven Prompt Assembly (Refactor)

Replace the hardcoded prompt structure with a template-driven approach where:
- `prompt_templates/assembly.json` defines the assembly order and sources.
- The builder reads this assembly spec and concatenates accordingly.
- More flexible but higher implementation cost.

---

## Experiments

No destructive experiments were run. All evidence was gathered through read-only source analysis and prompt artifact inspection.

**Evidence sources read (25 files total):**
1. `scripts/Send-ClaudeCommand.ps1` - full file (673 lines).
2. `scripts/Complete-ClaudeTask.ps1` - full file (185 lines).
3. `scripts/Update-WorkerState.ps1` - full file (235 lines).
4. `scripts/ClaudeTui.ps1` - send handler (lines 620-750) and initialization.
5. `manifest.json` - full file.
6. `SKILL.md` - full file.
7. `prompt_templates/default/system.md` - full file.
8. `prompt_templates/default/header.md` - full file.
9. `prompt_templates/role/reviewer/system_prompt/10-role-boundary.md` - full file.
10. `prompt_templates/role/reviewer/system_prompt/20-state-semantics.md` - full file.
11. `prompt_templates/role/reviewer/system_prompt/30-delivery-contract.md` - full file.
12. `prompt_templates/role/reviewer/header_prompt/10-reviewer-preamble.md` - full file.
13. `prompt_templates/role/reviewer/header_prompt/20-state-reminder.md` - full file.
14. `prompt_templates/role/reviewer/normal_prompt/focused-review.md` - full file.
15. `prompt_templates/role/reviewer/legal_state.json` - full file.
16. `prompt_templates/role/explorer/system_prompt/10-role-boundary.md` - full file.
17. `prompt_templates/role/explorer/system_prompt/20-state-semantics.md` - full file.
18. `prompt_templates/role/explorer/system_prompt/30-delivery-contract.md` - full file.
19. `prompt_templates/role/explorer/header_prompt/10-explorer-preamble.md` - full file.
20. `prompt_templates/role/explorer/header_prompt/20-state-reminder.md` - full file.
21. `prompt_templates/role/explorer/normal_prompt/architecture-trace.md` - full file.
22. `prompt_templates/role/explorer/legal_state.json` - full file.
23. `run/v2-reviewer-smoke-001/run-command-20260616-015105-174.prompt.txt` - generated prompt.
24. `run/v2-reviewer-smoke-001/run-command-20260616-015105-174.system.txt` - generated system prompt.
25. `run/v2-reviewer-smoke-001/.20260616-015105-174.state` - final state.
26. `store/v2-reviewer-smoke-001/results/20260616-015105-174.result.md` - reviewer result.
27. `store/v2-reviewer-smoke-001/results/20260616-015105-174.done.json` - done file.
28. `store/v2-reviewer-smoke-001/status.json` - agent status.
29. `run/v2-prompt-assembly-explorer-001/run-command-20260616-015707-163.prompt.txt` - current explorer prompt.
30. `run/v2-prompt-assembly-explorer-001/run-command-20260616-015707-163.system.txt` - current explorer system prompt.
31. `docs/role-profiles/reviewer/README.md` - reviewer profile.
32. `manager/agents.json` - current agent registry.
33. `prompt_templates/roles.json` - role registry.

---

## Decision Inputs

### For the Orchestrator

1. **Root cause confirmed:** `Send-ClaudeCommand.ps1` does not inject `role/system_prompt/*.md` or `role/header_prompt/*.md` into generated prompts. Only `default/system.md`, `default/header.md`, and `InjectNormal` are active.

2. **Reviewer smoke findings explained:**
   - **Missing verifying state:** Role `20-state-semantics.md` (which defines when to use `verifying`) was never injected. The worker had no system-level instruction about the verifying phase.
   - **Missing report sections:** Role `30-delivery-contract.md` (which mandates `## Verification` and `## Gaps` sections) was never injected.
   - **Forced Complete-ClaudeTask.ps1:** Confirmed hardcoded in `Build-WorkerPrompt` lines 268-271, contradicting v2 documentation and the script's own deprecation notice.

3. **Recommended action:** Option A (modify only `Build-SystemPrompt` and `Build-WorkerPrompt` in `Send-ClaudeCommand.ps1`). This is a ~30-line change in one file and fixes all three gaps.

4. **Risk:** Low. The role template files already exist and are well-structured. The change is additive (role layers are appended/prepended to existing content). No existing behavior is removed except the Complete-ClaudeTask mandate.

5. **After fix, re-run reviewer smoke** to verify:
   - Worker enters all states including `verifying`.
   - Report includes `## Verification` and `## Gaps` sections.
   - Worker uses `Update-WorkerState --exit --Confirm` as completion protocol (not forced Complete-ClaudeTask).

---

## Explorer UX Notes

- The explorer task itself was generated with the same missing layers - the explorer's `system_prompt/20-state-semantics.md` and `30-delivery-contract.md` were not injected into my system prompt. I discovered these by reading them directly from disk as part of the investigation.
- Similarly, the explorer's `header_prompt/10-explorer-preamble.md` and `20-state-reminder.md` were not injected into my header. My header was simply `[worker]\nYou are a explorer agent. Execute the task, then complete.`
- The explorer's delivery contract mandates a report format with Questions, Confirmed Facts, Inferences, Options, Experiments, Decision Inputs - which I followed because the task prompt explicitly listed these requirements. A task without that list might not produce this format.
- State reporting worked correctly for `running` and `investigating`. Will attempt `verifying` next and `exit` per the legal_state.json flow.
- The Complete-ClaudeTask.ps1 requirement in my own prompt conflicts with this report's finding that it should not be forced.
