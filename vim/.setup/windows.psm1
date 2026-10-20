function Set-VimShortcuts([string]$VimExe, [string]$DesktopPath, [string]$ProgramsPath, [string]$BackupRoot) {
    $shell = New-Object -ComObject WScript.Shell
    $vimRoot = Split-Path ([IO.Path]::GetFullPath($VimExe)) -Parent
    $launcher = Join-Path $ProgramsPath 'Vim.lnk'
    if (Test-Path -LiteralPath $launcher) {
        $existing = $shell.CreateShortcut($launcher)
        if ($existing.TargetPath -ine $VimExe -or $existing.Arguments) { throw "Preserve existing custom Vim shortcut: $launcher" }
    }
    $candidates = @()
    if (Test-Path -LiteralPath $DesktopPath) {
        $candidates += @(Get-ChildItem -LiteralPath $DesktopPath -File -Filter '*.lnk' |
            Where-Object Name -match '^gVim( Easy| Read-only)? [0-9]+\.[0-9]+\.lnk$')
    }
    $folders = @(Get-ChildItem -LiteralPath $ProgramsPath -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match '^Vim [0-9]+\.[0-9]+$' -and !($_.Attributes -band [IO.FileAttributes]::ReparsePoint) })
    $names = @('gVim.lnk', 'gVim Easy.lnk', 'gVim Read-only.lnk', 'gVim Diff.lnk', 'Vim.lnk', 'Vim Read-only.lnk', 'Vim Diff.lnk', 'Help.lnk', 'Vim tutor.lnk', 'Uninstall.lnk')
    foreach ($folder in $folders) {
        $candidates += @(Get-ChildItem -LiteralPath $folder.FullName -File | Where-Object { $names -contains $_.Name -or $_.Name -eq 'Vim Online.url' })
    }
    $removed = 0
    foreach ($file in $candidates) {
        if ($file.Extension -eq '.url') {
            if ([IO.File]::ReadAllText($file.FullName) -notmatch '(?m)^URL=https://www\.vim\.org/?\r?$') { continue }
        } else {
            $shortcut = $shell.CreateShortcut($file.FullName)
            if ((Split-Path $shortcut.TargetPath -Parent) -ine $vimRoot) { continue }
        }
        $relative = if ($file.DirectoryName -ieq $DesktopPath) { 'Desktop/' + $file.Name } else { 'StartMenu/' + $file.Directory.Name + '/' + $file.Name }
        $backup = Join-Path $BackupRoot ('vim-shortcuts/' + $relative)
        [void][IO.Directory]::CreateDirectory((Split-Path $backup -Parent))
        Copy-Item -LiteralPath $file.FullName -Destination $backup
        Remove-Item -LiteralPath $file.FullName
        $removed++
    }
    foreach ($folder in $folders) {
        if (!@(Get-ChildItem -LiteralPath $folder.FullName -Force).Count) { Remove-Item -LiteralPath $folder.FullName }
    }
    if (!(Test-Path -LiteralPath $launcher)) {
        [void][IO.Directory]::CreateDirectory($ProgramsPath)
        $shortcut = $shell.CreateShortcut($launcher)
        $shortcut.TargetPath = $VimExe
        $shortcut.WorkingDirectory = $env:USERPROFILE
        $shortcut.Save()
    }
    Write-Host "Vim shortcuts: one terminal launcher; $removed extra shortcut(s) backed up and removed."
}


Export-ModuleMember -Function *
