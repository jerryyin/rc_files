$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'windows.psm1') -Force
$configuration = Get-Content -LiteralPath (Join-Path $PSScriptRoot '../.windows/@LOCALAPPDATA/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json') -Raw | ConvertFrom-Json
Install-Fonts @{repository='thep0y/monaco-nerd-font'; asset='MonacoLigaturizedNerdFont.zip'} '' $configuration.profiles.defaults.font.face
