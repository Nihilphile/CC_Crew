# Truncation Detective — pinpoint exactly what pattern triggers claude CLI truncation
Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

$workspace = "F:\AI_project\CC_Crew"
$settings = "F:\AI_project\CC_Crew\.claude\worker-permissions.json"
$sysFile = "F:\AI_project\CC_Crew\tests\_trunc_system.md"
$resultsDir = "F:\AI_project\CC_Crew\tests\_trunc_results"

New-Item -ItemType Directory -Force -Path $resultsDir | Out-Null

# Minimal system prompt: just tell it to echo
@"
You are a truncation detector. Your ONLY job: read the prompt you receive and echo back EXACTLY what you see after the word COMPLETION. Quote verbatim. Do nothing else. No tools. Just report what you received.
"@ | Set-Content -LiteralPath $sysFile -Encoding UTF8

Write-Host "System prompt written: $sysFile"
Write-Host "Test runner ready. Tests will be run individually."
Write-Host ""
Write-Host "prompt goes to: claude --system-prompt-file $sysFile -p --output-format json `$promptText"
