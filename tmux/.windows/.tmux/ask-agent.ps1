# psmux invokes this from the source pane's copy-mode binding.
param(
    [Parameter(Mandatory)][ValidatePattern('^%[0-9]+$')][string]$Pane,
    [Parameter(Mandatory)][ValidateSet('0','1')][string]$Selected
)
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
if ($Selected -eq '0') {
    psmux.exe display-message 'ask-agent: nothing selected'
    return
}

function Quote-PowerShell([string]$Value) {
    return "'" + $Value.Replace("'", "''") + "'"
}

try {
    $bash = (Resolve-Path -LiteralPath (Join-Path (git.exe --exec-path) '../../../bin/bash.exe')).Path
    $helper = Join-Path $HOME '.config/tmux/ask-agent.sh'
    if ((psmux.exe display-message -p '#{pane_id} #{selection_present}') -ne "$Pane 1") {
        throw 'the selection moved before it could be copied'
    }
    # The server waits for copy-pipe. Its child only writes stdin, so it
    # can finish before the shared helper asks psmux to create the pane.
    $selection = [IO.Path]::GetTempFileName()
    $path = Quote-PowerShell $selection
    psmux.exe send-keys -t $Pane -X copy-pipe "[IO.File]::WriteAllText($path, [IO.StreamReader]::new([Console]::OpenStandardInput()).ReadToEnd())"
    if (!(Get-Item -LiteralPath $selection).Length) { throw 'nothing selected' }

    $root = [int](psmux.exe display-message -p -t $Pane '#{pane_pid}')
    $processes = Get-CimInstance Win32_Process -Property ProcessId,ParentProcessId,Name
    $pending = @($root)
    $tool = $null
    $claudeDir = $env:CLAUDE_CONFIG_DIR ?? (Join-Path $HOME '.claude')
    while ($pending.Count -gt 0) {
        foreach ($process in $processes.Where({ $_.ProcessId -in $pending })) {
            $record = Join-Path $claudeDir "sessions/$($process.ProcessId).json"
            if ($process.Name -in 'node.exe','claude.exe' -and (Test-Path -LiteralPath $record)) {
                $session = Get-Content -Raw -LiteralPath $record | ConvertFrom-Json
                $tool, $sid, $cwd = 'claude', $session.sessionId, $session.cwd
                break
            }
            if ($process.Name -eq 'codex.exe') {
                $tool, $sid = 'codex', 'choose'
                $cwd = psmux.exe display-message -p -t $Pane '#{pane_current_path}'
                break
            }
        }
        if ($tool) { break }
        $processes = $processes.Where({ $_.ProcessId -notin $pending })
        $pending = @($processes.Where({ $_.ParentProcessId -in $pending }) | ForEach-Object ProcessId)
    }
    if (!$tool) {
        throw 'no Claude Code or Codex session found in this pane'
    }

    $arguments = @($bash, $helper, 'run', $Pane, $tool, $sid, $cwd, $selection)
    $command = '& ' + (($arguments | ForEach-Object { Quote-PowerShell $_ }) -join ' ')
    $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($command))
    & $bash $helper open-answer $Pane "pwsh -NoProfile -EncodedCommand $encoded"
} catch {
    if ($selection -and (Test-Path -LiteralPath $selection)) { Remove-Item -LiteralPath $selection }
    psmux.exe display-message "ask-agent: $($_.Exception.Message)"
    throw
}
