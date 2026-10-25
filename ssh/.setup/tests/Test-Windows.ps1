$ErrorActionPreference = 'Stop'
$entry = Join-Path $PSScriptRoot '../windows.ps1'
function Get-Service { param($Name, $ErrorAction) return @{Status='Stopped'; StartType='Disabled'} }
function Start-Process { throw 'A read-only credential check must not request elevation.' }
$failed = $false
try { & $entry -PrepareAgent -ReadyOnly } catch { $failed = $_.Exception.Message -like '*requires machine setup*' }
if (!$failed) { throw 'An unprepared SSH agent must require normal machine setup.' }
function Get-Service { param($Name, $ErrorAction) return @{Status='Running'; StartType='Automatic'} }
function Get-Item { param($LiteralPath, [switch]$Force, $ErrorAction) return $null }
if (& $entry -Check) { throw 'A missing private config link must require normal SSH setup, even with a ready agent.' }
function Get-Item {
    param($LiteralPath, [switch]$Force, $ErrorAction)
    return @{ LinkType='SymbolicLink'; Target=(Join-Path $env:USERPROFILE 'vault/ssh/config') }
}
& $entry -PrepareAgent -ReadyOnly
Write-Output 'PASS SSH readiness never changes services or requests elevation.'
Remove-Item Function:Get-Item
$temporary = [IO.Path]::GetTempFileName()
try {
    [IO.File]::WriteAllText($temporary, 'fixture key bytes')
    $env:RC_SSH_PATHS = ConvertTo-Json -InputObject @($temporary) -Compress
    & $entry -Protect
    $access = (Get-Item -LiteralPath $temporary).GetAccessControl()
    $identities = @($access.Access | ForEach-Object { $_.IdentityReference.Translate([Security.Principal.SecurityIdentifier]).Value })
    $sid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    if (!$access.AreAccessRulesProtected -or $identities.Count -ne 2 -or $identities -notcontains $sid -or $identities -notcontains 'S-1-5-18') { throw 'SSH key access must be restricted to the owner and SYSTEM.' }
    if ([IO.File]::ReadAllText($temporary) -ne 'fixture key bytes') { throw 'Permission repair changed key bytes.' }
    Write-Output 'PASS SSH key permissions preserve bytes and restrict access to the owner and SYSTEM.'
} finally { Remove-Item -LiteralPath $temporary -Force }
