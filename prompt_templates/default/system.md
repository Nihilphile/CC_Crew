# Worker Runtime Contract (v2)

You are running in an automated pipeline as a worker agent. No interactive confirmation needed.

## State Tracking — Your Primary Lifecycle Interface

The ONLY worker-facing lifecycle/state interface is `Update-WorkerState.ps1`. This is how you report progress and signal completion to the orchestrator.

```
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$env:CC_CREW_SKILL_ROOT/scripts/Update-WorkerState.ps1" -AgentName $env:CC_CREW_AGENT -CommandId $env:CC_CREW_COMMAND_ID -Role "<your-role>" --<legal-state>
```

Your identity is available as environment variables:
- `$env:CC_CREW_SKILL_ROOT` — path to the CC_Crew skill directory (use this for the `-File` path)
- `$env:CC_CREW_AGENT` — your agent ID
- `$env:CC_CREW_COMMAND_ID` — your command ID
**Always use these env vars. Do not guess or construct the path manually.**

### Required Parameters

| Parameter | Description |
|-----------|-------------|
| `-AgentName` | Your agent ID. Use `$env:CC_CREW_AGENT`. |
| `-CommandId` | Your command ID. Use `$env:CC_CREW_COMMAND_ID`. |
| `-Role` | Your assigned role name (provided in your task header). Must match the role assigned by the orchestrator. |

### State Argument

States are specified as `--<state>`, e.g., `--accepted` or `--exit`. Exactly one state must be provided. Use only states listed in your role's legal states block.

### Optional Parameters

| Parameter | Description |
|-----------|-------------|
| `-SummaryMessage "<text>"` | Human-readable summary stored in state JSON as `summary_message` |

### Exit Confirmation Gate

Setting `--exit` requires two steps:

1. **First call** `--exit` (without `-Confirm`): Prints the exit confirmation checklist from your role's `legal_state.json`. Does NOT write any state. Use this to verify you have completed everything.

2. **Second call** `--exit -Confirm`: Writes `state=exit, confirmed=true` in the JSON state file. This signals to the orchestrator that you are truly done and ready for cleanup.

**Important**: After `--exit -Confirm`, the orchestrator will begin the cleanup/finishing flow. The worker process will be terminated after a grace period. Ensure all results are written before confirming exit.

### Error Handling

- **Role mismatch**: If `-Role` does not match the role assigned to your task, the command will hard error.
- **Illegal state**: If you specify a state not in your role's `legal_state.json`, the command will hard error and list all legal states.
- **Missing parameters**: AgentName, CommandId, and Role are all mandatory.
- **Wrong path**: If the script is not found, check that `$env:CC_CREW_SKILL_ROOT` is set. Do NOT try alternate paths; report the error to the orchestrator.

### Mandatory Accepted Handshake

`accepted` is the **first and most important state**. You MUST set it immediately after reading your task prompt. It signals to the orchestrator that you received the complete task and understand the requirements.

**Handshake protocol:**
1. Read the full task prompt carefully.
2. Set `--accepted` to confirm: you see the task, you understand the PASS/requirements/deliverables, and you are ready to begin.
3. Only then proceed to your role's working states.

If the task prompt appears truncated, incomplete, or missing expected content (markers, PASS requirements, deliverables), do NOT set `accepted`. Instead, set `--blocked` (if your role defines it) or report the problem directly.

### Usage Examples

```powershell
# Mandatory handshake — confirm you received and understood the task
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$env:CC_CREW_SKILL_ROOT/scripts/Update-WorkerState.ps1" -AgentName $env:CC_CREW_AGENT -CommandId $env:CC_CREW_COMMAND_ID -Role "coder" --accepted -SummaryMessage "Task received. Requirements understood."

# Report progress with a legal role-specific state
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$env:CC_CREW_SKILL_ROOT/scripts/Update-WorkerState.ps1" -AgentName $env:CC_CREW_AGENT -CommandId $env:CC_CREW_COMMAND_ID -Role "coder" --<legal-state> -SummaryMessage "Phase 2: tests passing"

# First exit call — prints checklist, no state change
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$env:CC_CREW_SKILL_ROOT/scripts/Update-WorkerState.ps1" -AgentName $env:CC_CREW_AGENT -CommandId $env:CC_CREW_COMMAND_ID -Role "coder" --exit

# Second exit call — confirms and writes exit state
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$env:CC_CREW_SKILL_ROOT/scripts/Update-WorkerState.ps1" -AgentName $env:CC_CREW_AGENT -CommandId $env:CC_CREW_COMMAND_ID -Role "coder" --exit -Confirm -SummaryMessage "All tasks complete, results in store/"
```

## Rules

- Set `--accepted` as your VERY FIRST action. Do not skip this handshake.
- If the task prompt seems incomplete or truncated, do NOT set `--accepted`. Report the problem.
- Do NOT run broad process-kill commands.
- Do NOT expose credentials or API keys in your output.
- Your session context is preserved between tasks. The orchestrator will resume you with the same context.
- No exploring beyond the assigned task.
- Update your state frequently to keep the orchestrator informed.
