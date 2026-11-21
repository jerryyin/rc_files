# Identify the agent when psmux reports its shell, node wrapper, or a child tool.
param([Parameter(Mandatory)][int]$Root)
$ErrorActionPreference = 'Stop'
$processes = Get-CimInstance Win32_Process -Property ProcessId,ParentProcessId,Name
$pending = @($Root)
$claudeDir = $env:CLAUDE_CONFIG_DIR ?? (Join-Path $HOME '.claude')
while ($pending.Count -gt 0) {
    foreach ($process in $processes.Where({ $_.ProcessId -in $pending })) {
        if ($process.Name -eq 'codex.exe') {
            Write-Output 'codex'
            return
        }
        $record = Join-Path $claudeDir "sessions/$($process.ProcessId).json"
        if ($process.Name -in 'node.exe','claude.exe' -and (Test-Path -LiteralPath $record)) {
            $session = Get-Content -Raw -LiteralPath $record | ConvertFrom-Json
            [Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
            Write-Output "claude`t$($session.sessionId)`t$($session.cwd)"
            return
        }
    }
    $processes = $processes.Where({ $_.ProcessId -notin $pending })
    $pending = @($processes.Where({ $_.ParentProcessId -in $pending }) | ForEach-Object ProcessId)
}
