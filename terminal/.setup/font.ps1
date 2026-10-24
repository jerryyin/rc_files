param([switch]$Check)
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'windows.psm1') -Force
$configuration = Get-Content -LiteralPath (Join-Path $PSScriptRoot '../.windows/@LOCALAPPDATA/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json') -Raw | ConvertFrom-Json
if ($Check) { Test-MachineFont $configuration.profiles.defaults.font.face; return }
if (Test-MachineFont $configuration.profiles.defaults.font.face) { return }
$administrator = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (!$administrator) {
    $command = "& '$($PSCommandPath.Replace("'", "''"))'; if (!`$?) { exit 1 }"
    $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($command))
    $process = Start-Process powershell.exe -Verb RunAs -WindowStyle Hidden -Wait -PassThru -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-EncodedCommand',$encoded)
    if ($process.ExitCode -ne 0 -or !(Test-MachineFont $configuration.profiles.defaults.font.face)) { throw 'Machine font installation failed' }
    return
}
Install-Fonts @{repository='thep0y/monaco-nerd-font'; asset='MonacoLigaturizedNerdFont.zip'} '' $configuration.profiles.defaults.font.face
