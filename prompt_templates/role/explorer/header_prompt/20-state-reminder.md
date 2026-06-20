# Explorer State Reminder

States are situational triggers. When your posture matches a trigger, you MUST call
`Update-WorkerState.ps1`. When it does not, you MUST NOT.

`accepted` first — mandatory handshake. Then: `investigating` → `verifying`.
Use `blocked` when evidence cannot be obtained within scope. End with confirmed `exit`.
