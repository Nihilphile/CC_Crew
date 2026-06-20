# ============================================================
# Truncation Detective — Test Suite
# 
# Usage: .\tests\truncation-detective.ps1
# 
# Runs a battery of tests to determine what exactly triggers
# the claude CLI prompt truncation around the "your" keyword.
# ============================================================
param(
    [switch]$TUI,           # Also test TUI mode
    [switch]$Quick          # Only run the 2 most critical tests
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

$skillRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$settings = Join-Path $skillRoot ".claude\worker-permissions.json"
$sysSmall = Join-Path $skillRoot "tests\_trunc_system.md"
$sysReal  = (Get-ChildItem "$skillRoot\run\truncation-test__sentinel-smoke\*.system.txt" | Select-Object -First 1).FullName

# Minimal system prompt for tests
@"
You are a truncation detector. Echo back EXACTLY what you see after COMPLETION in the prompt. Do nothing else.
"@ | Set-Content -LiteralPath $sysSmall -Encoding UTF8

$baseArgs = @(
    "--dangerously-skip-permissions",
    "--permission-mode","bypassPermissions",
    "--add-dir",$skillRoot,
    "--settings",$settings
)

$tests = @()

# === TEST CASES ===
# Each: [name, prompt, expected_sentinel, notes]

# T0: baseline — no your, no quotes
$tests += @{N="T0_baseline"; P=@"

COMPLETION — when done, call exit.
SENTINEL_ALPHA_001: mark.
"@; S="SENTINEL_ALPHA_001"; Note="Baseline: no your, no quotes"}

# T1: THE bug — double-quoted "your"  (original CC_Crew pattern)
$tests += @{N="T1_dblquote_your"; P=@"

COMPLETION — when done, call --exit -Confirm -SummaryMessage "your summary here".
SENTINEL_BRAVO_002: mark.
"@; S="SENTINEL_BRAVO_002"; Note="BUG PATTERN: double-quoted your"}

# T2: your without quotes
$tests += @{N="T2_bare_your"; P=@"

COMPLETION — when done, call --exit -Confirm -SummaryMessage your summary here.
SENTINEL_CHARLIE_003: mark.
"@; S="SENTINEL_CHARLIE_003"; Note="your without quotes"}

# T3: double-quote with OTHER word (not your)
$tests += @{N="T3_dblquote_other"; P=@"

COMPLETION — when done, call --exit -Confirm -SummaryMessage "not-your text here".
SENTINEL_DELTA_004: mark.
"@; S="SENTINEL_DELTA_004"; Note="Double-quote but not 'your'"}

# T4: COMPLETION with FULL real system.txt (9449 bytes)
$tests += @{N="T4_full_system"; P=@"

COMPLETION — when done, call --exit -Confirm -SummaryMessage "your summary here".
SENTINEL_ECHO_005: mark.
"@; S="SENTINEL_ECHO_005"; Note="Real 9449-byte system.txt with angle brackets"; SysFile=$sysReal}

if ($Quick) {
    $tests = @($tests[0], $tests[1])
}

# === RUN ===
$pass = 0; $fail = 0

foreach ($t in $tests) {
    $sf = if ($t.SysFile) { $t.SysFile } else { $sysSmall }
    Write-Host "`n=== $($t.N) : $($t.Note) ==="
    Write-Host "   Prompt: $($t.P.Length) chars, System: $((Get-Item $sf).Length) bytes"

    $args_full = $baseArgs + @("--system-prompt-file",$sf,"-p","--output-format","json",$t.P)
    $output = & claude $args_full 2>&1
    $jsonLine = ($output | Where-Object { $_ -match '"type":"result"' }) -join ""
    
    try {
        $j = $jsonLine | ConvertFrom-Json
        $r = $j.result
        $found = $r -match $t.S
        $yourFound = $r -match "your summary"
        
        if ($found) { 
            Write-Host "   SENTINEL: PASS ✅   your: $(if($yourFound){'visible'}else{'MISSING'})"
            $pass++ 
        } else { 
            Write-Host "   SENTINEL: FAIL ❌   your: $(if($yourFound){'visible'}else{'MISSING'})"
            $fail++ 
            Write-Host "   --- result ---"
            Write-Host $r.Substring(0, [Math]::Min(400, $r.Length))
        }
    } catch {
        Write-Host "   PARSE FAIL"
        $fail++
    }
}

Write-Host "`n============================================"
Write-Host "  SUMMARY: $pass PASS / $fail FAIL / $(($pass+$fail)) total"
Write-Host "============================================"

# === TUI test (manual) ===
if ($TUI) {
    Write-Host "`n=== TUI TEST (manual) ==="
    $tuiPrompt = $tests[1].P  # T1
    $tuiFile = Join-Path $skillRoot "tests\_trunc_tui_prompt.txt"
    Set-Content -LiteralPath $tuiFile -Value $tuiPrompt -Encoding UTF8
    Start-Process -FilePath "claude" -ArgumentList @(
        "--dangerously-skip-permissions",
        "--permission-mode","bypassPermissions",
        "--add-dir",$skillRoot,
        "--settings",$settings,
        "--system-prompt-file",$sysReal,
        (Get-Content -LiteralPath $tuiFile -Raw -Encoding UTF8)
    ) -WindowStyle Normal
    Write-Host "TUI launched. Check if SENTINEL visible past 'your summary here'."
}
