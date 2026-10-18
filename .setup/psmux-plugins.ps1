param([switch]$Update)
$ErrorActionPreference = 'Stop'
. (Join-Path $env:USERPROFILE '.psmux/plugins/ppm/ppm.ps1')
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
foreach ($spec in @(Get-DeclaredPlugins)) {
    if (!(Install-Plugin $spec)) { throw "PPM could not install $spec" }
}
if ($Update) {
    # PPM reports update failures as text instead of a failing exit status.
    $output = @(Update-AllPlugins *>&1)
    $output | Out-Host
    if (($output -join "`n") -match 'FAILED:') { throw 'PPM plugin update failed' }
}
