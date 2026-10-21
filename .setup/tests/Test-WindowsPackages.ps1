$ErrorActionPreference = 'Stop'
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('rc-package-test-' + [guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($fixture)
$request = Join-Path $fixture 'packages.json'
$global:RcTestInstalls = @()
$global:RcTestLaunches = @()
$global:RcTestResult = 0
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
    Write-Output 'PASS native package scopes, one elevation, hidden launch, installer arguments, outdated commands.'
} finally {
    Get-ChildItem -LiteralPath $fixture -File | Remove-Item -Force
    Remove-Item -LiteralPath $fixture
}
