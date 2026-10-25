param([string]$RcRoot = ([IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))))
$ErrorActionPreference = 'Stop'
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Run this isolated link-provisioning check from an administrator PowerShell.'
}
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('rc-ssh-deployment-' + [guid]::NewGuid().ToString('N'))
$originalHome = $env:USERPROFILE
$python = (Get-Command py.exe -ErrorAction Stop).Source
$entry = Join-Path $PSScriptRoot '../windows.ps1'
$script:serviceChanges = 0
function Get-Service { param($Name, $ErrorAction) return @{Status='Running'; StartType='Automatic'} }
function Set-Service { param($Name, $StartupType) $script:serviceChanges++ }
function Start-Service { param($Name) $script:serviceChanges++ }
try {
    $env:USERPROFILE = Join-Path $fixture 'home'
    $vault = Join-Path $fixture 'vault'
    [void][IO.Directory]::CreateDirectory($env:USERPROFILE)
    & $python -3 -B (Join-Path $RcRoot '.setup') --package ssh --no-install --home $env:USERPROFILE
    if ($LASTEXITCODE) { throw 'Public SSH setup failed in the fresh home.' }
    & $entry -PrepareAgent -Elevated -VaultPath $vault
    $link = Join-Path $env:USERPROFILE '.ssh/private.conf'
    if ((Get-Item -LiteralPath $link -Force).LinkType -ne 'SymbolicLink' -or (Test-Path -LiteralPath (Join-Path $vault 'ssh/config'))) { throw 'Preparation must support a dangling private configuration link before the vault exists.' }
    if (!(& $entry -Check -VaultPath $vault)) { throw 'A missing vault must not make prepared SSH unavailable.' }
    $before = $script:serviceChanges
    & $entry -PrepareAgent -ReadyOnly -VaultPath $vault
    if ($script:serviceChanges -ne $before) { throw 'Repeated preparation changed service state.' }
    & $python -3 -B (Join-Path $RcRoot '.setup') credentials --package ssh --home $env:USERPROFILE --vault $vault
    if ($LASTEXITCODE) { throw 'Credential activation must work before the vault exists.' }
    [void][IO.Directory]::CreateDirectory((Join-Path $vault 'ssh'))
    $source = Join-Path $vault 'ssh/config'
    [IO.File]::WriteAllText($source, "Host fixture`n  HostName 192.0.2.40`n")
    foreach ($run in 1..2) {
        & $python -3 -B (Join-Path $RcRoot '.setup') credentials --package ssh --home $env:USERPROFILE --vault $vault
        if ($LASTEXITCODE) { throw 'Credential activation failed after the vault became available.' }
    }
    if ((Get-Item -LiteralPath $link -Force).LinkType -ne 'SymbolicLink') { throw 'Credential activation replaced the configuration link.' }
    [IO.File]::WriteAllText($link, 'edited through the installed link')
    if ([IO.File]::ReadAllText($source) -ne 'edited through the installed link') { throw 'Installed configuration edits did not reach the source.' }
    Write-Output 'PASS fresh Windows SSH setup before/after vault availability, repeated activation, and source-linked edits. Real keys and services were not used.'
} finally {
    $env:USERPROFILE = $originalHome
    $resolved = [IO.Path]::GetFullPath($fixture)
    $temporaryRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
    if (!$resolved.StartsWith($temporaryRoot, [StringComparison]::OrdinalIgnoreCase) -or (Split-Path $resolved -Leaf) -notlike 'rc-ssh-deployment-*') { throw 'Unsafe SSH test cleanup path.' }
    if (Test-Path -LiteralPath $resolved) { Remove-Item -LiteralPath $resolved -Recurse -Force }
}
