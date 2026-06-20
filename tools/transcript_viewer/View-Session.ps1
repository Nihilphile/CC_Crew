# View-Session.ps1 — CLI entry point for transcript viewer
#
# Usage:
#   .\View-Session.ps1 -SessionId "f77e01c9-..." 
#   .\View-Session.ps1 -SessionId "f77e01c9-..." -Mode full
#   .\View-Session.ps1 -SessionId "f77e01c9-..." -Mode summary
#   .\View-Session.ps1 -SessionId "f77e01c9-..." -Run 3 -Block 5
#   .\View-Session.ps1 -AgentId "real-game-worker-ux-smoke" -Group "nameless-game"
<#
.SYNOPSIS View a Claude Code session transcript with state-block grouping.
.PARAMETER SessionId Claude session UUID.
.PARAMETER SessionFile Direct path to .jsonl file.
.PARAMETER AgentId CC_Crew agent ID (auto-resolves session UUID).
.PARAMETER Group Agent group filter.
.PARAMETER Mode summary (terminal table), detail (thinking+text+tools, no results), full (everything).
.PARAMETER Run Filter to a specific run.
.PARAMETER Block Filter to a specific block.
.PARAMETER Output Output file path. Defaults to session-<id8>.md. Use '-' for stdout.
.PARAMETER Open Open the output file after generation.
#>
param(
    [string]$SessionId,
    [string]$SessionFile,
    [string]$AgentId,
    [string]$Group = "",
    [ValidateSet("summary","detail","full")]
    [string]$Mode = "detail",
    [int]$Run = 0,
    [int]$Block = 0,
    [string]$Output = "",
    [switch]$Open
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $PSCommandPath
. (Join-Path $scriptDir "core\SessionParser.ps1")
. (Join-Path $scriptDir "core\SessionRenderer.ps1")

# Resolve agent → session
if ($AgentId -and -not $SessionId) {
    $skillRoot = Split-Path -Parent $scriptDir
    $ap = Join-Path $skillRoot "manager\agents.json"
    if (-not (Test-Path $ap)) { throw "agents.json not found: $ap" }
    $agents = Get-Content $ap -Raw -Enc UTF8 | ConvertFrom-Json
    $fid = if ($Group) { "$Group::$AgentId" } else { $AgentId }
    $fd = $null
    foreach ($k in $agents.PSObject.Properties) {
        if ($k.Value.agent_id -eq $fid) { $fd = $k.Value; break }
    }
    if (-not $fd) {
        foreach ($k in $agents.PSObject.Properties) {
            if ($k.Value.agent_id -match [regex]::Escape($AgentId)) { $fd = $k.Value; break }
        }
    }
    if (-not $fd) { throw "Agent '$AgentId' not found" }
    $SessionId = $fd.session_uuid
    if (-not $SessionId) { throw "Agent '$AgentId' has no session_uuid" }
    Write-Host "[VIEWER] Agent: $($fd.agent_id) -> Session: $SessionId"
}

# Parse
Write-Host "[VIEWER] Parsing session..."
$session = ConvertFrom-ClaudeSession -SessionId $SessionId -SessionFile $SessionFile
Write-Host "[VIEWER] $($session.Meta.TotalTurns) turns, $($session.Meta.TotalBlocks) blocks, $($session.Meta.TotalRuns) runs"

# Render
if ($Mode -eq "summary") {
    Write-SessionSummary -Session $session -Run $Run
} else {
    if (-not $Output) {
        $Output = "session-$($SessionId.Substring(0,8))-$Mode.md"
    }
    if ($Output -eq "-") {
        $md = ConvertTo-SessionMarkdown -Session $session -Mode $Mode -Run $Run -Block $Block -Output "$env:TEMP\_transcript.md"
        Get-Content "$env:TEMP\_transcript.md" -Encoding UTF8
    } else {
        ConvertTo-SessionMarkdown -Session $session -Mode $Mode -Run $Run -Block $Block -Output $Output
        Write-Host "[VIEWER] Written: $Output ($((Get-Item $Output).Length) bytes)"
        if ($Open) { Start-Process $Output }
    }
}
