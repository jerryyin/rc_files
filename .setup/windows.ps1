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
# Install also upgrades a package WinGet correlates with the requested id. Correlation is unreliable
# when another id installed the command (OpenJS.NodeJS.20 versus OpenJS.NodeJS.LTS), so `upgrade`
# cannot be chosen from the command alone; the caller verifies minimum versions afterwards.
$current = @(-1978335189, -1978335135)  # UPDATE_NOT_APPLICABLE, PACKAGE_ALREADY_INSTALLED
foreach ($package in $packages) {
    $arguments = @('install','--id',$package.winget,'--exact','--scope',$package.scope,'--source','winget','--accept-package-agreements','--accept-source-agreements','--disable-interactivity')
    if ($package.arguments) { $arguments += @('--custom',$package.arguments) }
    & winget @arguments
    if ($LASTEXITCODE -ne 0 -and $current -notcontains $LASTEXITCODE) { throw "WinGet failed for $($package.winget): $LASTEXITCODE" }
}
