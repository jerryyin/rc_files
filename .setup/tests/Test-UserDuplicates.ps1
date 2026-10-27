$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot '../packages.psm1') -Force -DisableNameChecking
$module = Get-Module packages
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('rc-duplicates-test-' + [guid]::NewGuid().ToString('N'))
$savedHome = $env:USERPROFILE
$savedLocal = $env:LOCALAPPDATA
$savedAppData = $env:APPDATA
try {
    $env:USERPROFILE = Join-Path $fixture 'user'
    $env:LOCALAPPDATA = Join-Path $env:USERPROFILE 'AppData/Local'
    $env:APPDATA = Join-Path $env:USERPROFILE 'AppData/Roaming'
    [void][IO.Directory]::CreateDirectory($env:LOCALAPPDATA)
    & $module {
        $script:Machine = $true
        $script:User = $true
        $script:UninstallResult = 0
        $script:Calls = @()
        $script:Appx = @()
        $script:MachineCommand = ''
        function script:winget {
            $script:Calls += ,$args
            if ($args -notcontains '--scope') { throw 'Every WinGet operation must choose its scope.' }
            $scope = $args[[Array]::IndexOf($args, '--scope') + 1]
            if ($args[0] -eq 'list') {
                $present = if ($scope -eq 'machine') { $script:Machine } else { $script:User }
                $global:LASTEXITCODE = if ($present) { 0 } else { -1978335212 }
            } else {
                if ($scope -ne 'user' -or !$script:Machine) { throw 'Only a duplicate user installation may be removed.' }
                $global:LASTEXITCODE = $script:UninstallResult
                if (!$script:UninstallResult) { $script:User = $false }
            }
        }
        function script:Get-Command {
            param($Name, $CommandType, [switch]$All, $ErrorAction)
            if ($script:MachineCommand) { return @{Source=$script:MachineCommand} }
            return @()
        }
        function script:Get-ItemProperty { param($Path, $LiteralPath, $ErrorAction) return @() }
        function script:Get-AppxPackage { param($Name, $ErrorAction) return $script:Appx }
        function script:Remove-AppxPackage {
            param($Package, $ErrorAction)
            if (!$script:Machine) { throw 'Store copy removed before replacement verification.' }
            $script:Appx = @()
        }
        function script:npm.cmd {
            if (($args[0] -ne 'uninstall') -or $args -notcontains '--prefix' -or $args -notcontains '--global') { throw 'Only the explicit user npm prefix may be changed.' }
            $prefix = $args[[Array]::IndexOf($args, '--prefix') + 1]
            if ($prefix -ne (Join-Path $env:APPDATA 'npm')) { throw 'Wrong npm prefix.' }
            Remove-Item -LiteralPath (Join-Path $prefix "node_modules/$($args[-1])/package.json")
            $global:LASTEXITCODE = 0
        }
    }
    $verify = { Assert-WindowsMachinePackage @{winget='Fixture.Tool'; npm=''; provisioned=''} }
    $machineCommand = Join-Path $fixture 'machine.cmd'
    [IO.File]::WriteAllText($machineCommand, "@exit /b 1`r`n")
    & $module { param($Path) $script:MachineCommand = $Path } $machineCommand
    $failed = $false
    try { Assert-WindowsMachinePackage @{winget='Fixture.Tool'; command='fixture'; npm=''} }
    catch { $failed = $_.Exception.Message -like '*Broken machine command*' }
    if (!$failed) { throw 'Machine registration alone must not authorize removal of a working user tool.' }
    [IO.File]::WriteAllText($machineCommand, "@exit /b 0`r`n")
    Assert-WindowsMachinePackage @{winget='Fixture.Tool'; command='fixture'; npm=''}
    & $module { $script:Machine = $false }
    $failed = $false
    try { Remove-WindowsUserPackage -Id 'Fixture.Tool' -VerifyMachine $verify }
    catch { $failed = $_.Exception.Message -like '*machine*' }
    if (!$failed -or !(& $module { $script:User })) { throw 'Missing machine replacement must preserve the user copy.' }
    & $module { $script:Machine = $true }
    Remove-WindowsUserPackage -Id 'Fixture.Tool' -VerifyMachine $verify
    if (& $module { $script:User }) { throw 'Verified machine installation must replace its user duplicate.' }
    Remove-WindowsUserPackage -Id 'Fixture.Tool' -VerifyMachine $verify
    if (@((& $module { ,$script:Calls }) | Where-Object { $_[0] -eq 'uninstall' }).Count -ne 1) { throw 'An unchanged rerun must not uninstall again.' }
    & $module { $script:User = $true; $script:UninstallResult = 17 }
    $failed = $false
    try { Remove-WindowsUserPackage -Id 'Fixture.Tool' -VerifyMachine $verify }
    catch { $failed = $_.Exception.Message -like '*17*' }
    if (!$failed) { throw 'Failed user uninstallation must stop setup.' }
    & $module { $script:UninstallResult = 0; $script:User = $false }
    & $module { $script:Appx = @(@{Name='Fixture.Store'; PackageFamilyName='Fixture.Store_family'; PackageFullName='Fixture.Store_1.0'; InstallLocation='C:\Program Files\WindowsApps\Fixture.Store'}) }
    Remove-WindowsUserPackage -Id 'Fixture.Tool' -AppxNames 'Fixture.Store' -VerifyMachine $verify
    if (@(& $module { $script:Appx }).Count) { throw 'Separate Store edition must be removed.' }
    $npmManifest = Join-Path $env:APPDATA 'npm/node_modules/@fixture/cli/package.json'
    [void][IO.Directory]::CreateDirectory((Split-Path $npmManifest))
    [IO.File]::WriteAllText($npmManifest, '{"version":"1.0.0"}')
    Remove-WindowsUserPackage -Npm '@fixture/cli' -VerifyMachine $verify
    if (Test-Path -LiteralPath $npmManifest) { throw 'User npm duplicate was not removed.' }
    & $module { $script:User = $true; $script:Calls = @() }
    $request = Join-Path $fixture 'packages.json'
    ConvertTo-Json -InputObject @(@{winget='Fixture.Tool'; command=''; npm=''; scope='machine'; provisioned=''}) | Set-Content -LiteralPath $request -Encoding UTF8
    & (Join-Path $PSScriptRoot '../windows.ps1') -Request $request -CleanupOnly
    if (& $module { $script:User }) { throw 'The cleanup entry point must remove duplicates without reinstalling or elevating.' }
    if (@((& $module { ,$script:Calls }) | Where-Object { $_[0] -eq 'install' }).Count) { throw 'Cleanup must never install packages.' }
    Write-Output 'PASS user duplicate removal, verified replacement, reruns, failures, npm prefixes and Store removal.'
} finally {
    $env:USERPROFILE = $savedHome
    $env:LOCALAPPDATA = $savedLocal
    $env:APPDATA = $savedAppData
    $resolved = [IO.Path]::GetFullPath($fixture)
    $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
    if (!$resolved.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase) -or (Split-Path $resolved -Leaf) -notlike 'rc-duplicates-test-*') { throw 'Unsafe fixture cleanup path' }
    if (Test-Path -LiteralPath $resolved) { Remove-Item -LiteralPath $resolved -Recurse -Force }
}
