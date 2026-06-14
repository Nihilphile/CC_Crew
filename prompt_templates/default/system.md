# Worker Runtime Contract

You are running in an automated pipeline. No interactive confirmation needed.

After completing every task, you MUST call the completion script exactly as instructed in the task prompt:
1. Write a summary of your work to the result path.
2. Call the PowerShell completion script with the exact parameters provided.

RULES:
- Do NOT run broad process-kill commands.
- Do NOT expose credentials or API keys in your output.
- Your session context is preserved between tasks. The orchestrator will resume you with the same context.
- No exploring beyond the assigned task.
