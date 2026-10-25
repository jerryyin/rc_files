param([switch]$PrepareAgent, [switch]$Protect, [switch]$Check, [switch]$ReadyOnly, [switch]$Elevated,
      [string]$VaultPath = (Join-Path $env:USERPROFILE 'vault'))
$ErrorActionPreference = 'Stop'
if ($PrepareAgent -or $Check) {
    $agent = Get-Service ssh-agent -ErrorAction SilentlyContinue
    $privatePath = Join-Path $env:USERPROFILE '.ssh/private.conf'
    $privateSource = [IO.Path]::GetFullPath((Join-Path $VaultPath 'ssh/config'))
    $link = Get-Item -LiteralPath $privatePath -Force -ErrorAction SilentlyContinue
    $linked = $link -and $link.LinkType -eq 'SymbolicLink' -and [IO.Path]::GetFullPath($link.Target) -eq $privateSource
    $ready = $agent -and $agent.Status -eq 'Running' -and $agent.StartType -eq 'Automatic' -and $linked
    if ($Check) { return [bool]$ready }
    if ($ready -and !$Elevated) { return }
    if ($ReadyOnly) { throw 'SSH agent or private config link requires machine setup; run rc_files setup for the ssh package.' }
    $administrator = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (!$administrator) {
        if ($Elevated) { throw 'SSH agent preparation requires administrator access.' }
        $command = "& '$($PSCommandPath.Replace("'", "''"))' -PrepareAgent -Elevated -VaultPath '$($VaultPath.Replace("'", "''"))'"
        $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($command))
        $process = Start-Process powershell.exe -Verb RunAs -WindowStyle Hidden -Wait -PassThru -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-EncodedCommand', $encoded)
        if ($process.ExitCode) { throw 'SSH agent preparation failed.' }
        return
    }
    if (!$agent) {
        $capability = Get-WindowsCapability -Online -Name 'OpenSSH.Client*' | Select-Object -First 1
        if (!$capability) { throw 'Windows OpenSSH Client capability is unavailable.' }
        Add-WindowsCapability -Online -Name $capability.Name | Out-Null
    }
    Set-Service ssh-agent -StartupType Automatic
    Start-Service ssh-agent
    if ((Get-Service ssh-agent).Status -ne 'Running') { throw 'SSH agent did not start.' }
    # SSH login sessions require links created with administrator privileges.
    if (!('SshConfigLinks' -as [type])) { Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class SshConfigLinks {
 [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
 [return: MarshalAs(UnmanagedType.I1)]
 public static extern bool CreateSymbolicLink(string link, string target, uint flags);
}
'@ }
    $sources = @{
        $privatePath = $privateSource
        (Join-Path $env:USERPROFILE '.ssh/config') = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../.ssh/config'))
    }
    foreach ($path in $sources.Keys) {
        $existing = Get-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
        if ($existing) {
            if ($existing.LinkType -ne 'SymbolicLink' -or [IO.Path]::GetFullPath($existing.Target) -ne $sources[$path]) {
                if ($path -eq $privatePath) { throw 'Reconcile the existing SSH private config link before preparing it.' }
                continue
            }
            Remove-Item -LiteralPath $path -Force
        }
        [void][IO.Directory]::CreateDirectory((Split-Path $path -Parent))
        if (![SshConfigLinks]::CreateSymbolicLink($path, $sources[$path], 0)) {
            throw (New-Object ComponentModel.Win32Exception([Runtime.InteropServices.Marshal]::GetLastWin32Error()))
        }
    }
} elseif ($Protect) {
    $sid = [Security.Principal.WindowsIdentity]::GetCurrent().User
    $system = New-Object Security.Principal.SecurityIdentifier('S-1-5-18')
    foreach ($path in (ConvertFrom-Json $env:RC_SSH_PATHS)) {
        $item = Get-Item -LiteralPath $path -Force
        $acl = if ($item.PSIsContainer) { New-Object Security.AccessControl.DirectorySecurity } else { New-Object Security.AccessControl.FileSecurity }
        if ($item.GetAccessControl().GetOwner([Security.Principal.SecurityIdentifier]) -ne $sid) { $acl.SetOwner($sid) }
        $acl.SetAccessRuleProtection($true, $false)
        foreach ($identity in @($sid, $system)) {
            $rule = if ($item.PSIsContainer) {
                New-Object Security.AccessControl.FileSystemAccessRule($identity, 'FullControl', 'ContainerInherit,ObjectInherit', 'None', 'Allow')
            } else { New-Object Security.AccessControl.FileSystemAccessRule($identity, 'FullControl', 'Allow') }
            $acl.AddAccessRule($rule)
        }
        $item.SetAccessControl($acl)
    }
} else { throw 'Select SSH agent preparation or permission protection.' }
