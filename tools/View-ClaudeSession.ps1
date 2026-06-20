<#
.SYNOPSIS Convert a Claude Code JSONL session file to readable Markdown.
.PARAMETER SessionId Claude Code session UUID.
.PARAMETER SessionFile Direct path to .jsonl file.
.PARAMETER AgentId CC_Crew agent ID. Looks up session from agents.json.
.PARAMETER Group Agent group filter.
.PARAMETER Output Output .md path. Defaults to session-<id8>.md.
.PARAMETER NoThinking Skip thinking blocks.
.PARAMETER OnlyUser Only show user prompts, no assistant.
.PARAMETER ThinkOnly Thinking + text output only. Tool calls simplified to one-liner, results collapsed.
.EXAMPLE
.\View-ClaudeSession.ps1 -SessionId "f77e01c9-..."
.\View-ClaudeSession.ps1 -AgentId "real-game-worker-ux-smoke" -Group "nameless-game"
.\View-ClaudeSession.ps1 -SessionId "f77e01c9-..." -ThinkOnly
#>
param([string]$SessionId,[string]$SessionFile,[string]$AgentId,[string]$Group="",[string]$Output="",[switch]$NoThinking,[switch]$OnlyUser,[switch]$ThinkOnly)
$ErrorActionPreference="Stop"
$d=Split-Path -Parent $PSCommandPath
$r=Split-Path -Parent $d
if($AgentId -and !$SessionId){
  $a=Get-Content "$r\manager\agents.json" -Raw -Enc UTF8|ConvertFrom-Json
  $fid=if($Group){"$Group::$AgentId"}else{$AgentId}
  $fd=$null;
  foreach($k in $a.PSObject.Properties){if($k.Value.agent_id -eq $fid){$fd=$k.Value;break}}
  if(!$fd){foreach($k in $a.PSObject.Properties){if($k.Value.agent_id -match [regex]::Escape($AgentId)){$fd=$k.Value;break}}}
  if(!$fd){throw "Not found"}
  $SessionId=$fd.session_uuid
  Write-Host "Agent: $($fd.agent_id) -> $SessionId"
}
if(!$SessionFile -and $SessionId){
  $c=Get-ChildItem "$env:USERPROFILE\.claude\projects" -Dir -EA 0|Where-Object{Test-Path "$($_.FullName)\$SessionId.jsonl"}|ForEach-Object{"$($_.FullName)\$SessionId.jsonl"}
  if(!$c){throw "Session $SessionId not found"}
  $SessionFile=@($c)[0]
}
if(!$SessionFile -or !(Test-Path $SessionFile)){throw "File not found: $SessionFile"}
if(!$Output){$Output="session-$($SessionId.Substring(0,8)).md"}
Write-Host "Source: $SessionFile"
Write-Host "Output: $Output"
$ls=Get-Content $SessionFile -Enc UTF8
$ts=[System.Collections.ArrayList]::new()
$n=0
foreach($l in $ls){
  try{$j=$l|ConvertFrom-Json}catch{continue}
  switch($j.type){
    'queue-operation'{if($j.content){[void]$ts.Add(@{R="prompt";N=++$n;C=[string]$j.content;TS=$j.timestamp})}}
    'user'{if($j.message -and $j.message.role -eq 'user'){$c=if($j.message.content -is[string]){$j.message.content}elseif($j.message.content){$j.message.content|ConvertTo-Json -D 3}else{""};if($c.Trim().Length -gt 0){[void]$ts.Add(@{R="user";N=++$n;C=$c;TS=$j.timestamp})}}}
    'assistant'{if(!$OnlyUser -and $j.message -and $j.message.role -eq 'assistant'){$bl=@();foreach($b in $j.message.content){switch($b.type){'text'{$bl+=@{T="text";X=$b.text}}'thinking'{if(!$NoThinking){$bl+=@{T="thinking";X=$b.thinking}}}'tool_use'{$bl+=@{T="tool_use";N=$b.name;I=($b.input|ConvertTo-Json -D 3 -Compress)}}'tool_result'{$rr=if($b.content -is[string]){$b.content}else{($b.content|ConvertTo-Json -D 2 -Compress)};$bl+=@{T="tool_result";X=$rr}}default{$bl+=@{T=$b.type;R=($b|ConvertTo-Json -D 2 -Compress)}}}};if($bl.Count -gt 0){[void]$ts.Add(@{R="assistant";N=++$n;B=$bl;M=$j.message.model;TS=$j.timestamp})}}}
    'system'{if($j.content){[void]$ts.Add(@{R="system";N=++$n;C=[string]$j.content})}}
  }
}
Write-Host "$($ts.Count) turns"
$sb=[System.Text.StringBuilder]::new()
if($ThinkOnly){$modeLabel="ThinkOnly"}elseif($OnlyUser){$modeLabel="OnlyUser"}elseif($NoThinking){$modeLabel="NoThinking"}else{$modeLabel="Full"}
[void]$sb.Append("# CC_Crew Session ($modeLabel)`n`n**Session**: ``$SessionId``  `n**Turns**: $($ts.Count)`n`n---`n`n")
foreach($t in $ts){
  switch($t.R){
    'prompt'{
      $c=$t.C.Trim()
      [void]$sb.Append("## [$($t.N)] Task`n`n")
      if($c -match 'TASK:'){
        $p=$c.Substring(0,$c.IndexOf('TASK:'));$k=$c.Substring($c.IndexOf('TASK:'))
        if($p.Trim()){[void]$sb.Append("<details><summary>Preamble (role/header/InjectNormal)</summary>`n`n```````n$p```````n`n</details>`n`n")}
        [void]$sb.Append("```````n$k```````n`n")
      } else {
        $d=if($c.Length -gt 4000){$c.Substring(0,4000)+"`n... ($($c.Length-4000) more)"}else{$c}
        [void]$sb.Append("```````n$d```````n`n")
      }
    }
    'user'{
      $c=$t.C.Trim()
      [void]$sb.Append("## [$($t.N)] User`n`n<details><summary>$($c.Length) chars</summary>`n`n```````n")
      $d=if($c.Length -gt 4000){$c.Substring(0,4000)+"`n... ($($c.Length-4000) more)"}else{$c}
      [void]$sb.Append("$d`n```````n</details>`n`n")
    }
    'assistant'{
      [void]$sb.Append("## [$($t.N)] $(if($t.M){"($($t.M))"})`n`n")
      if($ThinkOnly){
        # ThinkOnly: text + thinking inline, tools as one-liner list, results collapsed
        $toolNames=@();$hasResults=$false
        foreach($b in $t.B){
          if($b.T -eq 'text'){[void]$sb.Append("$($b.X)`n`n")}
          elseif($b.T -eq 'thinking'){[void]$sb.Append("> 💭 *$($b.X)*`n`n")}
          elseif($b.T -eq 'tool_use'){$toolNames+="🔧 $($b.N)";$hasResults=$true}
        }
        if($toolNames.Count -gt 0){
          [void]$sb.Append("**Tools:** ")
          [void]$sb.Append(($toolNames -join ', '))
          [void]$sb.Append("`n`n")
        }
        if($hasResults){
          [void]$sb.Append("<details><summary>Tool Results</summary>`n`n")
          foreach($b in $t.B){
            if($b.T -eq 'tool_result'){
              $rr=if($b.X.Length -gt 2000){$b.X.Substring(0,2000)+"`n... ($($b.X.Length) total)"}else{$b.X}
              [void]$sb.Append("<details><summary>📋 Result</summary>`n`n```````n$rr```````n</details>`n`n")
            }
          }
          [void]$sb.Append("</details>`n`n")
        }
      } else {
        # Full mode: every block rendered
        foreach($b in $t.B){
          switch($b.T){
            'text'{[void]$sb.Append("$($b.X)`n`n")}
            'thinking'{[void]$sb.Append("> 💭 *$($b.X)*`n`n")}
            'tool_use'{[void]$sb.Append("**🔧 ``$($b.N)``**`n`n``````json`n$($b.I)`n```````n`n")}
            'tool_result'{
              $rr=if($b.X.Length -gt 2000){$b.X.Substring(0,2000)+"`n... ($($b.X.Length) total)"}else{$b.X}
              [void]$sb.Append("<details><summary>📋 Result</summary>`n`n```````n$rr```````n</details>`n`n")
            }
            default{[void]$sb.Append("<details><summary>$($b.T)</summary>`n`n```````n$($b.R)`n```````n</details>`n`n")}
          }
        }
      }
      [void]$sb.Append("---`n`n")
    }
    'system'{[void]$sb.Append("## [$($t.N)] System`n`n> $($t.C)`n`n")}
  }
}
Set-Content $Output -Val $sb.ToString() -Enc UTF8
Write-Host "Done: $Output ($($sb.Length) chars)"