function Add-MachinePath([string]$Directory) {
    $path = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    if ($Directory -notin @($path -split ';')) {
        [Environment]::SetEnvironmentVariable('Path', "$Directory;$path", 'Machine')
    }
    $env:PATH = "$Directory;" + $env:PATH
}
# Install also upgrades a package WinGet correlates with the requested id. Correlation is unreliable
# when another id installed the command (OpenJS.NodeJS.20 versus OpenJS.NodeJS.LTS), so `upgrade`
# cannot be chosen from the command alone; the caller verifies minimum versions afterwards.
$current = @(-1978335189, -1978335135)  # UPDATE_NOT_APPLICABLE, PACKAGE_ALREADY_INSTALLED
function Install-WindowsPackage($package) {
    $env:PATH = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + $env:PATH
    if ($package.npm) {
        $prefix = Join-Path $env:ProgramFiles 'npm'
        & npm.cmd install --global --prefix $prefix ($package.npm + '@latest')
        if ($LASTEXITCODE -ne 0) { throw "npm failed for $($package.npm): $LASTEXITCODE" }
        $command = Join-Path $prefix ($package.command + '.cmd')
        if (!(Test-Path -LiteralPath (Join-Path $prefix "node_modules/$($package.npm)/package.json")) -or !(Test-Path -LiteralPath $command)) { throw "npm did not install $($package.command) into $prefix" }
        & $command --version
        if ($LASTEXITCODE -ne 0) { throw "Installed command failed: $command" }
        Add-MachinePath $prefix
        return
    }
    $arguments = @('install','--id',$package.winget,'--exact','--scope',$package.scope,'--source','winget','--accept-package-agreements','--accept-source-agreements','--disable-interactivity','--silent')
    if ($package.installer_type) { $arguments += @('--installer-type', $package.installer_type) }
    if ($package.scope -eq 'machine') {
        # Force a fresh install when only a per-user copy exists, rather than upgrading that copy.
        & winget list --id $package.winget --exact --scope machine --source winget --accept-source-agreements --disable-interactivity | Out-Null
        if ($LASTEXITCODE -notin @(0, -1978335212)) { throw "WinGet inventory failed for $($package.winget): $LASTEXITCODE" }
        if ($LASTEXITCODE -eq -1978335212 -or $package.provisioned) { $arguments += '--force' }
    }
    if ($package.arguments) { $arguments += @('--custom',$package.arguments) }
    & winget @arguments
    if ($LASTEXITCODE -ne 0 -and $current -notcontains $LASTEXITCODE) { throw "WinGet failed for $($package.winget): $LASTEXITCODE" }
    if ($package.provisioned) {
        if (!@(Get-AppxProvisionedPackage -Online | Where-Object DisplayName -eq $package.provisioned).Count) {
            throw "App was not provisioned for new users: $($package.provisioned)"
        }
    }
    if ($package.scope -eq 'machine') {
        foreach ($pattern in $package.search) {
            $expanded = [Environment]::ExpandEnvironmentVariables($pattern)
            if (!$expanded.StartsWith($env:ProgramFiles + '/', [StringComparison]::OrdinalIgnoreCase)) { continue }
            $found = Get-Item -Path $expanded -ErrorAction SilentlyContinue | Sort-Object FullName -Descending | Select-Object -First 1
            if ($found) { Add-MachinePath $found.DirectoryName; break }
        }
    }
}

Export-ModuleMember -Function *
