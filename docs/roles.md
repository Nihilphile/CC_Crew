# Role System (v2)

`-Role` selects a registered v2 role. Omitting `-Role` uses the `bare` role:
universal states only, no role-specific prompt injection. Every `send` validates
that the role has a parseable `legal_state.json` containing the mandatory
`accepted` and `exit` states.

For guidance on designing a project-independent role contract, prompt layers,
custom states, and smoke coverage, see [Creating Roles (v2)](role-creation-guide.md).

## CLI Commands

| Command | Description |
|---------|-------------|
| `role register <name> [-Force]` | Register with v2 directory structure. Creates `system_prompt/`, `header_prompt/`, `normal_prompt/`, and `legal_state.json` with states `accepted`, `rejected`, `exit`. `-Force` overwrites. |
| `role update <name> [-StateFile <path>]` | Update legal_state.json states from a file. Also ensures v2 structure exists. |
| `role list` | List all registered roles with structure type and legal states. |
| `role show <name>` | Show role details: legal_state.json, file lists per directory, normal_prompt templates. |
| `role unregister <name>` | Remove a role and its template directory. |

## v2 Role Structure

```
prompt_templates/role/<name>/
├── system_prompt/       ← Injected to --system-prompt-file (after default/system.md)
├── header_prompt/       ← Injected to task preamble (after default/header.md)
├── normal_prompt/       ← NOT auto-injected. Use send -InjectNormal <name>
└── legal_state.json     ← {"states":["accepted","rejected","exit"],"exit_confirmation":"..."}
```

All directories except `legal_state.json` are optional. The `bare` role has only
`legal_state.json` and is the default when no `-Role` is given.

## Universal States

Three states are available for every worker regardless of role:

| State | Semantics |
|-------|-----------|
| `accepted` | Mandatory handshake. First action after reading the complete task. |
| `rejected` | Task truncated or cannot proceed. Set instead of `accepted`, then `--exit -Confirm`. |
| `exit` | Two-step end-of-lifecycle. |

Workers must set `--accepted` or `--rejected` before any working state.

## Using a Role

```powershell
# Bare mode — universal states only, no role templates
& $tui send my-worker -Prompt "Read the plan and report findings"

# New agent — v2 role template layers injected
& $tui send my-explorer -Role explorer -Prompt "Investigate the assigned unknowns"

# With normal_prompt fragment
& $tui send my-explorer -Role explorer -Prompt "Trace the subsystem" -InjectNormal architecture-trace

# Mid-session role switch — same agent, different role, session preserved
& $tui send my-explorer -Role reviewer -Prompt "Review the prior evidence"
```

`-InjectNormal` is fully wired end-to-end: the normal prompt template content flows
from `ClaudeTui.ps1` → `Send-ClaudeCommand.ps1` → `Build-WorkerPrompt` → worker prompt.

## Worker State Tracking

Workers use `Update-WorkerState.ps1` to report progress. Worker identity is provided
via environment variables: `$env:CC_CREW_SKILL_ROOT`, `$env:CC_CREW_AGENT`,
`$env:CC_CREW_COMMAND_ID`. The orchestrator reads state from
`run/<agent>/.<command_id>.state` (JSON format).
See [role-system-design.md](role-system-design.md) for full details.

## Editing Default Templates

The default worker prompt is defined in `prompt_templates/default/`. Edit directly.

| File | Injected as | Purpose |
|------|------------|---------|
| `system.md` | `--system-prompt-file` (Layer 1) | Universal handshake protocol + Update-WorkerState usage |
| `header.md` | Task prompt preamble | `~~ROLE~~` replaced with actual role name (skipped for `bare`) |

## Role Storage and Git

Role directories under `prompt_templates/role/` are gitignored by default. They are
**local configuration** — each orchestrator/user maintains their own roles via
`role register`. If you need to share roles across collaborators or machines, use an
explicit documentation or repository strategy.
