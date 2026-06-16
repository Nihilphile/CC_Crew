# Coder State Reminder

States are situational triggers. When your posture matches a trigger, you MUST call
`Update-WorkerState.ps1`. When it does not, you MUST NOT.

`accepted` first — mandatory handshake. Then: `inspecting` → `coding` → `verifying`.
Use `questioning` only when you must surface decisions to the orchestrator before
continuing implementation. End with confirmed `exit`.
