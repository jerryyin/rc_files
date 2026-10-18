$ErrorActionPreference = 'Stop'
$processes = @(Get-CimInstance Win32_Process -Property ProcessId,ParentProcessId,Name,CommandLine)
$parents = @{}
foreach ($process in $processes) { $parents[[int]$process.ProcessId] = [int]$process.ParentProcessId }
$ancestors = @{}
foreach ($process in $processes) {
    $isAi = $process.Name -match '^(codex|claude)(\.exe)?$' -or
        ($process.Name -eq 'node.exe' -and $process.CommandLine -match '(@openai[\\/]codex|@anthropic-ai[\\/]claude-code)')
    if (!$isAi) { continue }
    $current = [int]$process.ProcessId
    while ($current -and !$ancestors.ContainsKey($current)) {
        $ancestors[$current] = $true
        if (!$parents.ContainsKey($current)) { break }
        $current = $parents[$current]
    }
}
$ancestors.Keys | Sort-Object
