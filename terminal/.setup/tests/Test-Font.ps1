$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot '../windows.psm1') -Force
$module = Get-Module windows
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ('rc-font-test-' + [guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($testRoot)
function Assert($Condition, $Message) { if (!$Condition) { throw $Message }; Write-Output "PASS $Message" }
function Save-Text($Path, $Text, $Backup) { [IO.File]::WriteAllText($Path, $Text) }
function Set-FixtureJson($Url, $Value) { & $module { param($v) $script:Release=$v } $Value }
function Set-FixtureFile($Url, $Value) { & $module { param($v) $script:Archive=$v } $Value }
& $module {
    function script:Invoke-RestMethod { param($Uri) return $script:Release }
    function script:Invoke-WebRequest { param($Uri, $OutFile, [switch]$UseBasicParsing) [IO.File]::WriteAllBytes($OutFile, $script:Archive) }
}
try {
    & $module {
        $script:FontRegistration=[pscustomobject]@{}
        $script:FontExists=$false
        function script:Get-ItemProperty {
            param($LiteralPath)
            if ($LiteralPath -notlike 'HKLM:*') { throw 'Machine font checks must not accept user registration.' }
            return $script:FontRegistration
        }
        function script:Test-Path { param($LiteralPath, $PathType) return $script:FontExists }
    }
    Assert (!(Test-MachineFont 'Fixture Nerd Font')) 'A user-visible font alone does not satisfy machine installation'
    & $module { $script:FontRegistration=[pscustomobject]@{'Fixture Nerd Font (regular) (TrueType)'='fixture.ttf'} }
    Assert (!(Test-MachineFont 'Fixture Nerd Font')) 'A font registry entry without its shared file is incomplete'
    & $module { $script:FontExists=$true }
    Assert (Test-MachineFont 'Fixture Nerd Font') 'A shared font with registration and file is reused'
    & $module { Remove-Item Function:Test-Path; Remove-Item Function:Get-ItemProperty }
    # Exercise release discovery and archive handling without OS registration.
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $fontSource = Join-Path $testRoot 'font-source'
    [void][IO.Directory]::CreateDirectory($fontSource)
    Save-Text (Join-Path $fontSource 'fixture.ttf') 'test font bytes' ''
    $fontZip = Join-Path $testRoot 'fixture.zip'
    [IO.Compression.ZipFile]::CreateFromDirectory($fontSource, $fontZip)
    $fixtureFont = [ordered]@{ repository='fixture/fonts'; asset='fonts.zip' }
    Set-FixtureJson 'https://api.github.com/repos/fixture/fonts/releases/latest' @{ assets=@(@{ name='fonts.zip'; browser_download_url='https://fixture.invalid/font.zip' }) }
    Set-FixtureFile 'https://fixture.invalid/font.zip' ([IO.File]::ReadAllBytes($fontZip))
    $fontOutput = Join-Path $testRoot 'font-output'
    Get-FontFiles $fixtureFont $fontOutput
    Assert ([IO.File]::ReadAllText((Join-Path $fontOutput 'fixture.ttf')) -ceq 'test font bytes') 'Font archive is selected from the latest upstream release'
    $fixtureFont.asset = 'absent.zip'
    $threw = $false
    try { Get-FontFiles $fixtureFont (Join-Path $testRoot 'bad-font') } catch { $threw = $true }
    Assert $threw 'Missing font family archive is reported instead of substituting another font'
    $fixtureFont.asset = 'fonts.zip'
    $unsafeZip = Join-Path $testRoot 'unsafe.zip'
    $zip = [IO.Compression.ZipFile]::Open($unsafeZip, [IO.Compression.ZipArchiveMode]::Create)
    try { [void]$zip.CreateEntry('../escape.ttf') } finally { $zip.Dispose() }
    Set-FixtureFile 'https://fixture.invalid/font.zip' ([IO.File]::ReadAllBytes($unsafeZip))
    $threw = $false
    try { Get-FontFiles $fixtureFont (Join-Path $testRoot 'unsafe-font') } catch { $threw = $true }
    Assert $threw 'Font archive entries cannot escape the staging directory'
} finally {
    $resolved = [IO.Path]::GetFullPath($testRoot)
    $expected = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
    if (!$resolved.StartsWith($expected, [StringComparison]::OrdinalIgnoreCase) -or (Split-Path $resolved -Leaf) -notlike 'rc-font-test-*') { throw 'Unsafe test cleanup path' }
    Remove-Item -LiteralPath $resolved -Recurse -Force
}
