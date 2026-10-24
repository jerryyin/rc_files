param([Parameter(Mandatory)][string]$Request, [switch]$Elevated)
$ErrorActionPreference = 'Stop'
$packages = ConvertFrom-Json ([IO.File]::ReadAllText($Request))
$administrator = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$machine = @($packages | Where-Object scope -eq 'machine')
if ($machine.Count -and !$administrator) {
    $machineRequest = Join-Path (Split-Path $Request) 'machine.json'
    ConvertTo-Json -Depth 10 -InputObject $machine | Set-Content -LiteralPath $machineRequest -Encoding UTF8
    $command = "& '$($PSCommandPath.Replace("'", "''"))' -Request '$($machineRequest.Replace("'", "''"))' -Elevated"
    $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($command))
    $process = Start-Process powershell.exe -Verb RunAs -WindowStyle Hidden -Wait -PassThru -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-EncodedCommand',$encoded)
    if ($process.ExitCode -ne 0) { throw "Native package installation failed: $($process.ExitCode)" }
    $packages = @($packages | Where-Object scope -ne 'machine')
}
if ($Elevated -and !$administrator) { throw 'Machine packages require administrator approval.' }
Import-Module (Join-Path $PSScriptRoot 'packages.psm1') -DisableNameChecking
foreach ($package in $packages) { Install-WindowsPackage $package }
