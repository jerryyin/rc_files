$ErrorActionPreference = 'Stop'
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('rc-package-test-' + [guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($fixture)
$request = Join-Path $fixture 'packages.json'
$global:RcTestInstalls = @()
$global:RcTestLaunches = @()
$global:RcTestResult = 0
$savedProgramFiles = $env:ProgramFiles
function winget {
    $global:RcTestInstalls += ,$args
    $global:LASTEXITCODE = $global:RcTestResult
}
function Start-Process {
    param($FilePath, $Verb, $WindowStyle, [switch]$Wait, [switch]$PassThru, $ArgumentList)
    $global:RcTestLaunches += @{Verb=$Verb; Hidden=($WindowStyle -eq 'Hidden'); Wait=[bool]$Wait}
    return @{ExitCode=0}
}
try {
    $packages = @(
        @{winget='Fixture.One'; command='fixture-one'; scope='machine'; arguments=''; minimum=@()},
        @{winget='Fixture.Two'; command='fixture-two'; scope='machine'; arguments=''; minimum=@()},
        @{winget='Fixture.User'; command='fixture-user'; scope='user'; arguments='/console=1'; minimum=@()}
    )
    ConvertTo-Json -Depth 5 -InputObject $packages | Set-Content -LiteralPath $request -Encoding UTF8
    & (Join-Path $PSScriptRoot '../windows.ps1') -Request $request
    $administrator = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (!$administrator) {
        if ($global:RcTestLaunches.Count -ne 1 -or $global:RcTestLaunches[0].Verb -ne 'RunAs' -or !$global:RcTestLaunches[0].Hidden -or !$global:RcTestLaunches[0].Wait) { throw 'Machine requirements did not share one hidden, awaited elevation.' }
        $machine = ConvertFrom-Json ([IO.File]::ReadAllText((Join-Path $fixture 'machine.json')))
        if ($machine.Count -ne 2 -or @($machine | Where-Object scope -ne 'machine').Count) { throw 'Elevation received the wrong requirements.' }
    }
    if (@($global:RcTestInstalls | Where-Object { $_ -contains 'Fixture.User' -and $_ -contains '/console=1' }).Count -ne 1) { throw 'User package arguments were lost.' }
    ConvertTo-Json -Depth 5 -InputObject @($packages[-1]) | Set-Content -LiteralPath $request -Encoding UTF8
    $global:RcTestResult = 17
    $failed = $false
    try { & (Join-Path $PSScriptRoot '../windows.ps1') -Request $request } catch { $failed=$_.Exception.Message -like '*WinGet failed*17*' }
    if (!$failed) { throw 'A failed package installer must stop setup.' }
    $outdated = @{winget='Fixture.Outdated'; command='powershell'; scope='user'; arguments=''; minimum=@(99)}
    ConvertTo-Json -Depth 5 -InputObject @($outdated) | Set-Content -LiteralPath $request -Encoding UTF8
    foreach ($code in @(0, -1978335189, -1978335135)) {
        $global:RcTestInstalls = @()
        $global:RcTestResult = $code
        & (Join-Path $PSScriptRoot '../windows.ps1') -Request $request
        if ($global:RcTestInstalls.Count -ne 1 -or $global:RcTestInstalls[0][0] -ne 'install') { throw "An outdated existing command must be requested through install (exit $code)." }
    }
    $module = Get-Module packages
    & $module {
        $script:Calls = @()
        $script:ListResult = -1978335212
        $script:InstallResult = 0
        $script:Provisioned = @()
        $script:SharedPaths = @()
        function script:winget {
            $script:Calls += ,$args
            $global:LASTEXITCODE = if ($args[0] -eq 'list') { $script:ListResult } else { $script:InstallResult }
        }
        function script:Get-AppxProvisionedPackage { param([switch]$Online) return $script:Provisioned }
        function script:Add-MachinePath($Directory) { $script:SharedPaths += $Directory }
    }
    $shared = @{winget='Fixture.Shared'; scope='machine'; installer_type='wix'; search=@()}
    Install-WindowsPackage $shared
    $calls = & $module { ,$script:Calls }
    if ($calls.Count -ne 2 -or $calls[0] -notcontains 'machine' -or $calls[1] -notcontains '--force' -or $calls[1] -notcontains 'wix') { throw 'A user-only package must get a fresh machine installation with its selected installer type.' }
    & $module { $script:Calls=@(); $script:ListResult=0 }
    Install-WindowsPackage $shared
    if ((& $module { $script:Calls[-1] }) -contains '--force') { throw 'An existing machine installation should use its normal upgrade path.' }
    & $module { $script:ListResult=5 }
    $failed=$false
    try { Install-WindowsPackage $shared } catch { $failed=$_.Exception.Message -like '*inventory failed*5*' }
    if (!$failed) { throw 'Inventory failures cannot be treated as user-only installs.' }
    & $module { $script:ListResult=0 }
    $shared.provisioned='Fixture.Terminal'
    $failed=$false
    try { Install-WindowsPackage $shared } catch { $failed=$_.Exception.Message -like '*not provisioned*' }
    if (!$failed) { throw 'A successful installer exit cannot substitute for app provisioning.' }
    & $module { $script:Provisioned=@(@{DisplayName='Fixture.Terminal'}) }
    Install-WindowsPackage $shared
    $env:ProgramFiles=Join-Path $fixture 'Program Files'
    $vim=Join-Path $env:ProgramFiles 'Vim/vim.exe'
    [void][IO.Directory]::CreateDirectory((Split-Path $vim))
    [IO.File]::WriteAllText($vim, '')
    & $module { $script:InstallResult=-1978335189 }
    Install-WindowsPackage @{winget='Fixture.Vim'; scope='machine'; search=@('%ProgramFiles%/Vim/vim.exe')}
    if ((& $module { $script:SharedPaths[-1] }) -ne (Split-Path $vim)) { throw 'An up-to-date machine tool must still repair its missing PATH entry.' }
    & $module {
        function script:npm.cmd {
            $prefix=$args[[Array]::IndexOf($args, '--prefix') + 1]
            if ($prefix -ne (Join-Path $env:ProgramFiles 'npm')) { throw 'npm must explicitly select the shared prefix.' }
            [void][IO.Directory]::CreateDirectory((Join-Path $prefix 'node_modules/@fixture/cli'))
            [IO.File]::WriteAllText((Join-Path $prefix 'node_modules/@fixture/cli/package.json'), '{"version":"1.0.0"}')
            [IO.File]::WriteAllText((Join-Path $prefix 'fixture.cmd'), "@echo 1.0.0`r`n@exit /b 0`r`n")
            $global:LASTEXITCODE=0
        }
    }
    Install-WindowsPackage @{npm='@fixture/cli'; command='fixture'; scope='machine'}
    if ((& $module { $script:SharedPaths[-1] }) -ne (Join-Path $env:ProgramFiles 'npm')) { throw 'Shared npm commands must be published on the machine PATH.' }
    Write-Output 'PASS native package scopes, one elevation, installer selection, migration, failures, provisioning and shared npm commands.'
} finally {
    $env:ProgramFiles=$savedProgramFiles
    $resolved=[IO.Path]::GetFullPath($fixture)
    $tempRoot=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
    if (!$resolved.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase) -or (Split-Path $resolved -Leaf) -notlike 'rc-package-test-*') { throw 'Unsafe fixture cleanup path' }
    Remove-Item -LiteralPath $resolved -Recurse -Force
}
