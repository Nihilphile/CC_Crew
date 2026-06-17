# SessionParser.ps1 — Parse Claude Code JSONL into structured Turns and StateBlocks
# Exposes: ConvertFrom-ClaudeSession

function ConvertFrom-ClaudeSession {
    <#
    .SYNOPSIS Parse a Claude Code JSONL session into Turns and StateBlocks.
    .PARAMETER SessionId Claude session UUID.
    .PARAMETER SessionFile Direct path to .jsonl file.
    .OUTPUTS [PSCustomObject]@{ Meta, Turns, StateBlocks }
    #>
    param([string]$SessionId, [string]$SessionFile)

    # ---- Resolve file ----
    if (-not $SessionFile -and $SessionId) {
        $projRoot = Join-Path $env:USERPROFILE ".claude\projects"
        $candidates = Get-ChildItem -LiteralPath $projRoot -Directory -EA 0 |
            Where-Object { Test-Path (Join-Path $_.FullName "$SessionId.jsonl") } |
            ForEach-Object { Join-Path $_.FullName "$SessionId.jsonl" }
        if (-not $candidates) { throw "Session $SessionId not found" }
        $SessionFile = @($candidates)[0]
    }
    if (-not $SessionFile -or -not (Test-Path $SessionFile)) {
        throw "Session file not found: $SessionFile"
    }

    $lines = Get-Content -LiteralPath $SessionFile -Encoding UTF8

    # ===========================================
    # PASS 1: collect assistant turns + prompt
    # ===========================================
    $turns = [System.Collections.ArrayList]::new()
    $initialPrompt = ""

    foreach ($ln in $lines) {
        try { $entry = $ln | ConvertFrom-Json } catch { continue }
        if (-not $entry.type) { continue }

        if ($entry.type -eq 'queue-operation' -and -not $initialPrompt -and $entry.content) {
            $initialPrompt = [string]$entry.content
        }

        if ($entry.type -ne 'assistant' -or -not $entry.message -or $entry.message.role -ne 'assistant') {
            continue
        }

        $blocks = [System.Collections.ArrayList]::new()
        $hasError = $false

        foreach ($b in $entry.message.content) {
            if (-not $b.type) { continue }

            switch ($b.type) {
                'text' {
                    [void]$blocks.Add(@{ Kind="text"; Text=[string]$b.text })
                }
                'thinking' {
                    [void]$blocks.Add(@{ Kind="thinking"; Text=[string]$b.thinking })
                }
                'tool_use' {
                    $name = $b.name
                    $input = @{}
                    foreach ($p in $b.input.PSObject.Properties) {
                        $input[$p.Name] = [string]$p.Value
                    }

                    $stateName = $null
                    $stateConfirmed = $false
                    $stateSummary = ""
                    if ($name -match '^(Bash|PowerShell)$' -and $input['command'] -match 'Update-WorkerState\b') {
                        if ($input['command'] -match '--(\w+)') {
                            $stateName = $Matches[1]
                            if ($stateName -eq 'Confirm') { $stateName = 'exit' }
                        }
                        $stateConfirmed = $input['command'] -match '-Confirm'
                        if ($input['command'] -match '-SummaryMessage\s+"([^"]+)"') {
                            $stateSummary = $Matches[1]
                        }
                    }

                    [void]$blocks.Add(@{
                        Kind="tool_use"; Name=$name; Input=$input
                        IsState=($null -ne $stateName)
                        StateName=$stateName; StateConfirmed=$stateConfirmed
                        StateSummary=$stateSummary
                    })
                }
                'tool_result' {
                    $resultText = ""
                    if ($b.content -is [string]) { $resultText = [string]$b.content }
                    elseif ($b.content) { $resultText = ($b.content | ConvertTo-Json -Depth 3 -Compress) }
                    $isErr = $b.is_error -eq $true
                    [void]$blocks.Add(@{ Kind="tool_result"; Text=$resultText; IsError=$isErr })
                    if ($isErr) { $hasError = $true }
                }
                default {
                    [void]$blocks.Add(@{ Kind="other"; Name=$b.type; Raw=($b | ConvertTo-Json -Depth 2 -Compress) })
                }
            }
        }

        [void]$turns.Add([PSCustomObject]@{
            Index      = $turns.Count + 1
            Blocks     = $blocks
            HasError   = $hasError
            Model      = if ($entry.message.model) { [string]$entry.message.model } else { "" }
            StopReason = if ($entry.message.stop_reason) { [string]$entry.message.stop_reason } else { "" }
            Timestamp  = if ($entry.timestamp) { $entry.timestamp } else { "" }
        })
    }

    # ===========================================
    # PASS 2: build StateBlocks from state calls
    # ===========================================
    $stateBlocks = [System.Collections.ArrayList]::new()
    $currentBlock = $null
    $runIndex = 1
    $blockIndexTotal = 0

    foreach ($turn in $turns) {
        $stateBlock = $null
        foreach ($b in $turn.Blocks) {
            if ($b.Kind -eq 'tool_use' -and $b.IsState) {
                $stateBlock = $b
                break
            }
        }

        if ($stateBlock) {
            if ($currentBlock) {
                $currentBlock.EndTime = $turn.Timestamp
            }

            $blockIndexTotal++
            $currentBlock = [PSCustomObject]@{
                BlockIndex = $blockIndexTotal
                RunIndex   = $runIndex
                State      = $stateBlock.StateName
                Confirmed  = $stateBlock.StateConfirmed
                Summary    = $stateBlock.StateSummary
                StartTime  = $turn.Timestamp
                EndTime    = $null
                Turns      = [System.Collections.ArrayList]::new()
                Errors     = 0
                ToolCalls  = 0
            }

            # New run starts at each accepted after the first
            if ($stateBlock.StateName -eq "accepted" -and $stateBlocks.Count -gt 0) {
                $runIndex++
                $currentBlock.RunIndex = $runIndex
            }

            [void]$stateBlocks.Add($currentBlock)
        }

        if ($currentBlock) {
            [void]$currentBlock.Turns.Add($turn)
            if ($turn.HasError) { $currentBlock.Errors++ }
            foreach ($b in $turn.Blocks) {
                if ($b.Kind -eq 'tool_use') { $currentBlock.ToolCalls++ }
            }
        }
    }

    if ($currentBlock) {
        $currentBlock.EndTime = $turns[-1].Timestamp
    }

    # Freeze ArrayLists
    $blocksOut = foreach ($sb in $stateBlocks) {
        [PSCustomObject]@{
            BlockIndex = $sb.BlockIndex
            RunIndex   = $sb.RunIndex
            State      = $sb.State
            Confirmed  = $sb.Confirmed
            Summary    = $sb.Summary
            StartTime  = $sb.StartTime
            EndTime    = $sb.EndTime
            Turns      = @($sb.Turns)
            Errors     = $sb.Errors
            ToolCalls  = $sb.ToolCalls
        }
    }

    $meta = [PSCustomObject]@{
        SessionId     = $SessionId
        SessionFile   = $SessionFile
        TotalTurns    = $turns.Count
        TotalBlocks   = $stateBlocks.Count
        TotalRuns     = $runIndex
        InitialPrompt = $initialPrompt
    }

    [PSCustomObject]@{ Meta=$meta; Turns=@($turns); StateBlocks=@($blocksOut) }
}
