# Smoker State Reminder

States are situational triggers. When your posture matches a trigger, you MUST call
`Update-WorkerState.ps1`. When it does not, you MUST NOT.

`accepted` first — mandatory handshake. Then: `preparing` → `exercising` → `observing`.
Use `diagnosing` when a bug appears and you are narrowing the cause. Use `verifying`
for final checks and verdict. Use `blocked` when smoke cannot continue within scope.
End with confirmed `exit`.
