param([Parameter(Mandatory)][string]$VimExe)
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'windows.psm1') -Force
$desktop = if ($env:RC_SETUP_REDIRECTED -eq '1') { Join-Path $env:USERPROFILE 'Desktop' } else { [Environment]::GetFolderPath('Desktop') }
$backup = if ($env:BACKUP_DIR) { $env:BACKUP_DIR } else { Join-Path $env:USERPROFILE ('.dotfiles-backup/' + (Get-Date -Format 'yyyyMMdd-HHmmss')) }
Set-VimShortcuts $VimExe $desktop (Join-Path $env:APPDATA 'Microsoft/Windows/Start Menu/Programs') $backup
