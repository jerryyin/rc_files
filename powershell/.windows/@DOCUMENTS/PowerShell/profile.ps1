# Native Windows tools. This profile never invokes WSL.
function vim {
    if ($env:WT_SESSION -or !($env:SSH_CONNECTION -or $env:SSH_CLIENT)) { & vim.exe @args; return }
    $previousTerminal = $env:WT_SESSION
    try {
        # Native Vim otherwise replaces a transparent background with console black over SSH.
        $env:WT_SESSION = 'vim-ssh'
        & vim.exe @args
    } finally { $env:WT_SESSION = $previousTerminal }
}
function psmux {
    if ($args.Count) { & psmux.exe @args; return }
    & psmux.exe has-session 2>$null
    if ($LASTEXITCODE -eq 0) { & psmux.exe attach-session }
    else { & psmux.exe new-session -A -s main }
}
function tmux { psmux @args }
function dev { & psmux.exe new-session -A -s main @args }
function ll { Get-ChildItem -Force @args }
function la { Get-ChildItem -Force @args }
Set-Alias -Name vi -Value vim
if (Get-Module PSReadLine) {
    Set-PSReadLineOption -EditMode Emacs
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
    Set-PSReadLineKeyHandler -Key Alt+LeftArrow -Function BackwardWord
    Set-PSReadLineKeyHandler -Key Alt+RightArrow -Function ForwardWord
}
function prompt {
    $esc = [string][char]27
    $location = Get-Location
    $folder = if ($location.Path -eq $HOME) { '~' } else { Split-Path $location.Path -Leaf }
    $branch = ''
    if ($location.Provider.Name -eq 'FileSystem') {
        # Report PowerShell's directory to Terminal and psmux.
        [Console]::Write($esc + ']9;9;"' + $location.Path + '"' + [char]7)
        $directory = $location.ProviderPath
        while ($directory -and !(Test-Path -LiteralPath (Join-Path $directory '.git'))) {
            $directory = Split-Path $directory -Parent
        }
        if ($directory) {
            $savedExitCode = $global:LASTEXITCODE
            $savedPreference = $ErrorActionPreference
            $ErrorActionPreference = 'Continue'
            try { $status = @(& git --no-optional-locks status --porcelain=v1 --branch 2>$null) }
            finally { $ErrorActionPreference = $savedPreference }
            if ($LASTEXITCODE -eq 0 -and $status.Count) {
                $branch = ' ' + (($status[0] -replace '^## ', '') -replace '\.\.\..*$', '')
                if ($status.Count -gt 1) { $branch += ' *' }
            }
            $global:LASTEXITCODE = $savedExitCode
        }
    }
    $esc + '[38;2;125;174;163m' + $folder + $esc + '[38;2;216;166;87m' + $branch + $esc + '[38;2;169;182;101m ' + [char]0x279c + $esc + '[0m '
}

# Only a terminal login may attach. SSH commands and shells inside psmux must
# finish loading their profile without starting another interactive client.
$sshLoginArguments = @([Environment]::GetCommandLineArgs() | Select-Object -Skip 1 |
    Where-Object { $_ -notin @('-NoLogo', '-NoExit', '-Login', '-Interactive') })
if ($env:SSH_CONNECTION -and $env:SSH_TTY -and $Host.Name -eq 'ConsoleHost' -and
    !$env:TMUX -and !$env:PSMUX_SESSION -and !$env:PSMUX_TARGET_SESSION -and
    !$sshLoginArguments.Count -and ![Console]::IsInputRedirected -and ![Console]::IsOutputRedirected -and
    (Get-Command psmux.exe -ErrorAction SilentlyContinue)) {
    dev
}
