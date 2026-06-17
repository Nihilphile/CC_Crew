# SessionRenderer.ps1 — Render parsed Turns/StateBlocks to text or Markdown
# Exposes: ConvertTo-SessionMarkdown, Write-SessionSummary

function ConvertTo-SessionMarkdown {
    param(
        $Session,
        [string]$Output,
        [ValidateSet("summary","detail","full")]
        [string]$Mode = "detail",
        [int]$Run = 0,
        [int]$Block = 0
    )

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.Append("# CC_Crew Session Transcript`n`n")
    [void]$sb.Append("**Session**: ``$($Session.Meta.SessionId)``  ")
    [void]$sb.Append("**Turns**: $($Session.Meta.TotalTurns)  ")
    [void]$sb.Append("**Blocks**: $($Session.Meta.TotalBlocks)  ")
    [void]$sb.Append("**Mode**: $Mode`n`n---`n`n")

    $blocks = $Session.StateBlocks
    if ($Run -gt 0) { $blocks = @($blocks | Where-Object { $_.RunIndex -eq $Run }) }
    if ($Block -gt 0) { $blocks = @($blocks | Where-Object { $_.BlockIndex -eq $Block }) }

    foreach ($blk in $blocks) {
        $timeStr = ""
        if ($blk.StartTime -and $blk.EndTime) {
            try {
                $s = [datetime]::Parse($blk.StartTime).ToString("HH:mm:ss")
                $e = [datetime]::Parse($blk.EndTime).ToString("HH:mm:ss")
                $timeStr = "$s -> $e"
            } catch {}
        }

        $stateTag = if ($blk.Confirmed) { "$($blk.State) [conf]" } else { $blk.State }
        [void]$sb.Append("## Block $($blk.BlockIndex): $stateTag  (Run $($blk.RunIndex))`n`n")
        [void]$sb.Append("*$timeStr  |  $($blk.Turns.Count) turns  |  $($blk.ToolCalls) tools  |  $($blk.Errors) errors*`n`n")
        if ($blk.Summary) { [void]$sb.Append("> $($blk.Summary)`n`n") }

        foreach ($turn in $blk.Turns) {
            foreach ($b in $turn.Blocks) {
                switch ($b.Kind) {
                    'text' {
                        if ($Mode -in @("summary","detail","full")) {
                            [void]$sb.Append("$($b.Text)`n`n")
                        }
                    }
                    'thinking' {
                        if ($Mode -in @("detail","full")) {
                            [void]$sb.Append("> [think] *$($b.Text)*`n`n")
                        }
                    }
                    'tool_use' {
                        if ($Mode -in @("detail","full")) {
                            if ($b.IsState) {
                                $tag = if ($b.StateConfirmed) { "--$($b.StateName) -Confirm" } else { "--$($b.StateName)" }
                                [void]$sb.Append("**[state] $tag**`n`n")
                            } else {
                                [void]$sb.Append("**[tool] $($b.Name)**`n`n")
                            }

                            if ($Mode -eq "full") {
                                $inputJson = @{}
                                foreach ($k in $b.Input.Keys) {
                                    if ($k -ne 'description') { $inputJson[$k] = $b.Input[$k] }
                                }
                                [void]$sb.Append("<details><summary>Params</summary>`n`n")
                                [void]$sb.Append("``````json`n$($inputJson | ConvertTo-Json -Depth 2)`n```````n</details>`n`n")
                            }
                        }
                    }
                    'tool_result' {
                        if ($Mode -eq "full") {
                            $d = if ($b.Text.Length -gt 2000) { $b.Text.Substring(0,2000) + "`n... ($($b.Text.Length) total)" } else { $b.Text }
                            $errTag = if ($b.IsError) { " ERROR" } else { "" }
                            [void]$sb.Append("<details><summary>Result$errTag</summary>`n`n")
                            [void]$sb.Append("```````n$d`n```````n</details>`n`n")
                        }
                    }
                }
            }
        }
        [void]$sb.Append("---`n`n")
    }

    $content = $sb.ToString()
    Set-Content -LiteralPath $Output -Value $content -Encoding UTF8
    return $content
}

function Write-SessionSummary {
    param($Session, [int]$Run = 0)

    $blocks = $Session.StateBlocks
    if ($Run -gt 0) { $blocks = @($blocks | Where-Object { $_.RunIndex -eq $Run }) }

    Write-Host ""
    Write-Host "Session: $($Session.Meta.SessionId)  |  $($Session.Meta.TotalTurns) turns  |  $($Session.Meta.TotalBlocks) blocks  |  $($Session.Meta.TotalRuns) runs"
    Write-Host ("{0,-3} {1,-3} {2,-18} {3,-10} {4,-6} {5,-4} {6,-8}" -f "#","Run","State","Time","Turns","Err","Tools")
    Write-Host ("{0,-3} {1,-3} {2,-18} {3,-10} {4,-6} {5,-4} {6,-8}" -f "-","-","-","-","-","-","-")

    foreach ($blk in $blocks) {
        $timeFmt = ""
        if ($blk.StartTime) {
            try { $timeFmt = [datetime]::Parse($blk.StartTime).ToString("HH:mm:ss") } catch {}
        }

        $stateTag = if ($blk.Confirmed) { "$($blk.State) [conf]" } else { $blk.State }

        $line = "{0,-3} {1,-3} {2,-18} {3,-10} {4,-6} {5,-4} {6,-8}" -f `
            $blk.BlockIndex, $blk.RunIndex, $stateTag, $timeFmt, `
            $blk.Turns.Count, $blk.Errors, $blk.ToolCalls
        Write-Host $line

        if ($blk.Summary) {
            Write-Host ("    -> {0}" -f $blk.Summary)
        }
    }
    Write-Host ""
}
