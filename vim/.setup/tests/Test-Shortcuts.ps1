$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot '../windows.psm1') -Force
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('vim-shortcuts-test-' + [guid]::NewGuid().ToString('N'))
$savedLocal = $env:LOCALAPPDATA
$savedProfile = $env:USERPROFILE
try {
    $env:LOCALAPPDATA = Join-Path $fixture 'local'
    $env:USERPROFILE = Join-Path $fixture 'home'
    $desktop = Join-Path $fixture 'Desktop'
    $programs = Join-Path $fixture 'Programs'
    $backup = Join-Path $fixture 'backup'
    $oldVim = Join-Path $env:LOCALAPPDATA 'Programs/Vim/vim.exe'
    $newVim = Join-Path $fixture 'machine/Vim/vim.exe'
    $launcher = Join-Path $programs 'Vim.lnk'
    $shell = New-Object -ComObject WScript.Shell
    Set-VimShortcuts $oldVim $desktop $programs $backup
    Set-VimShortcuts $newVim $desktop $programs $backup
    if ($shell.CreateShortcut($launcher).TargetPath -ine $newVim) { throw 'The managed launcher must follow the new installation.' }
    $saved = Join-Path $backup 'vim-shortcuts/StartMenu/Vim.lnk'
    if (!(Test-Path -LiteralPath $saved) -or $shell.CreateShortcut($saved).TargetPath -ine $oldVim) { throw 'The old launcher must be backed up before changing its target.' }
    Set-VimShortcuts $newVim $desktop $programs $backup
    if ($shell.CreateShortcut($saved).TargetPath -ine $oldVim) { throw 'An unchanged rerun must preserve the original backup.' }
    $link = $shell.CreateShortcut($launcher)
    $link.TargetPath = Join-Path $env:LOCALAPPDATA 'Programs/Vim/vim91/vim.exe'
    $link.Save()
    Set-VimShortcuts $newVim $desktop $programs (Join-Path $fixture 'versioned-backup')
    if ($shell.CreateShortcut($launcher).TargetPath -ine $newVim) { throw 'Versioned Vim installation paths must also migrate.' }
    foreach ($custom in @(@{Target=$oldVim; Arguments='--clean'}, @{Target=(Join-Path $fixture 'custom/vim.exe'); Arguments=''})) {
        $link = $shell.CreateShortcut($launcher)
        $link.TargetPath = $custom.Target
        $link.Arguments = $custom.Arguments
        $link.Save()
        $failed = $false
        try { Set-VimShortcuts $newVim $desktop $programs $backup } catch { $failed = $_.Exception.Message -like '*Preserve existing custom*' }
        if (!$failed -or $shell.CreateShortcut($launcher).TargetPath -ine $custom.Target) { throw 'Custom shortcuts must remain untouched.' }
    }
    Write-Output 'PASS: Vim launcher migration, backup, unchanged rerun and custom shortcut preservation.'
} finally {
    $env:LOCALAPPDATA = $savedLocal
    $env:USERPROFILE = $savedProfile
    $resolved = [IO.Path]::GetFullPath($fixture)
    $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
    if (!$resolved.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase) -or (Split-Path $resolved -Leaf) -notlike 'vim-shortcuts-test-*') { throw 'Unsafe fixture cleanup path' }
    Remove-Item -LiteralPath $resolved -Recurse -Force
}
