[CmdletBinding()]
param([Parameter(Mandatory=$true)][ValidateSet('CopyLine','CopyDirectory')][string]$Action)
$ErrorActionPreference = 'Stop'
$state = Get-Content -LiteralPath (Join-Path $env:LOCALAPPDATA 'PersonalDevenv/state.json') -Raw | ConvertFrom-Json
function Invoke-Mux([string[]]$Words, [switch]$Capture) {
    $output = & $state.psmuxExe @Words
    if ($LASTEXITCODE -ne 0) { throw "psmux failed (exit $LASTEXITCODE)" }
    if ($Capture) { return (($output -join [Environment]::NewLine).Trim()) }
}
if ($Action -eq 'CopyDirectory') {
    $path = Invoke-Mux @('display-message','-p','#{pane_current_path}') -Capture
    Invoke-Mux @('set-buffer',$path)
    Set-Clipboard -Value $path
    return
}
Invoke-Mux @('send-keys','C-a')
Start-Sleep -Milliseconds 100
Invoke-Mux @('copy-mode')
Invoke-Mux @('send-keys','-X','begin-selection')
Invoke-Mux @('send-keys','-X','-N','150','cursor-down')
Invoke-Mux @('send-keys','-X','end-of-line')
Invoke-Mux @('send-keys','-X','previous-word')
Invoke-Mux @('send-keys','-X','next-word-end')
Invoke-Mux @('send-keys','-X','copy-selection-and-cancel')
Invoke-Mux @('send-keys','C-e')
