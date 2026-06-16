# Reviewer State Reminder

States are situational triggers. When your posture matches a trigger, you MUST call
`Update-WorkerState.ps1`. When it does not, you MUST NOT.

`accepted` first — mandatory handshake. Then: `inspecting` → `reviewing` → `verifying`.
Use `blocked` when review cannot complete within scope. End with confirmed `exit`.
