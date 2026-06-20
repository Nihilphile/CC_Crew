# PowerShell Probe Rules

Selected normal marker: `V2_TEST_NORMAL_PS_91AF`

This reusable fragment defines tool-use rules. Run probes with `powershell.exe
-NoProfile` and capture the command, exit code, and relevant output. Treat a non-zero
exit code as evidence; do not suppress it or edit the runtime to make the probe pass.

