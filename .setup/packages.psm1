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

function Assert-WindowsMachinePackage($Package) {
    if ($Package.npm) {
        $prefix = Join-Path $env:ProgramFiles 'npm'
        if (!(Test-Path -LiteralPath (Join-Path $prefix "node_modules/$($Package.npm)/package.json"))) { throw "Missing machine npm package: $($Package.npm)" }
        & (Join-Path $prefix ($Package.command + '.cmd')) --version | Out-Host
        if ($LASTEXITCODE -ne 0) { throw "Broken machine npm command: $($Package.command)" }
        return
    }
    & winget list --id $Package.winget --exact --scope machine --source winget --accept-source-agreements --disable-interactivity | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Cannot verify machine package $($Package.winget): $LASTEXITCODE" }
    if ($Package.command) {
        $priorPath = $env:PATH
        try {
            $env:PATH = [Environment]::GetEnvironmentVariable('Path', 'Machine')
            $command = Get-Command $Package.command -CommandType Application -ErrorAction Stop | Select-Object -First 1
            if ($command.Source.StartsWith($env:USERPROFILE.TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase)) { throw "Machine PATH selects a user command: $($command.Source)" }
            & $command.Source --version | Out-Host
            if ($LASTEXITCODE -ne 0) { throw "Broken machine command: $($command.Source)" }
        } finally { $env:PATH = $priorPath }
    }
}

function Remove-WindowsUserPackage {
    param([string]$Id, [string]$Npm, [string[]]$AppxNames = @(), [Parameter(Mandatory)][scriptblock]$VerifyMachine)
    $homePrefix = [IO.Path]::GetFullPath($env:USERPROFILE).TrimEnd('\') + '\'
    if ($Npm) {
        $prefix = Join-Path $env:APPDATA 'npm'
        $manifest = Join-Path $prefix "node_modules/$Npm/package.json"
        if (!(Test-Path -LiteralPath $manifest)) { return }
        & $VerifyMachine
        & npm.cmd uninstall --global --prefix $prefix $Npm
        if ($LASTEXITCODE -ne 0 -or (Test-Path -LiteralPath $manifest)) { throw "User npm uninstall failed for $Npm (exit $LASTEXITCODE)" }
        & $VerifyMachine
        return
    }
    foreach ($name in $AppxNames) {
        foreach ($app in @(Get-AppxPackage -Name $name -ErrorAction Stop)) {
            & $VerifyMachine
            Remove-AppxPackage -Package $app.PackageFullName -ErrorAction Stop
            & $VerifyMachine
            if (@(Get-AppxPackage -Name $name -ErrorAction Stop).Count) { throw "Store copy still installed: $name" }
        }
    }
    & winget list --id $Id --exact --scope user --source winget --accept-source-agreements --disable-interactivity | Out-Null
    $found = $LASTEXITCODE -eq 0
    if (!$found -and $LASTEXITCODE -ne -1978335212) { throw "User package inventory failed for ${Id}: $LASTEXITCODE" }
    if ($found) {
        & $VerifyMachine
        $locations = @(Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\${Id}_*" -ErrorAction SilentlyContinue | ForEach-Object InstallLocation)
        & winget uninstall --id $Id --exact --scope user --source winget --silent --disable-interactivity
        if ($LASTEXITCODE -ne 0) { throw "User package uninstall failed for $Id (exit $LASTEXITCODE)." }
        & $VerifyMachine
        & winget list --id $Id --exact --scope user --source winget --accept-source-agreements --disable-interactivity | Out-Null
        if ($LASTEXITCODE -ne -1978335212) { throw "Could not confirm removal of user package ${Id}: $LASTEXITCODE" }
        $path = [Environment]::GetEnvironmentVariable('Path', 'User')
        $remaining = @($path -split ';' | Where-Object {
            $entry = [Environment]::ExpandEnvironmentVariables($_).TrimEnd('\')
            $obsolete = $false
            foreach ($location in $locations) {
                if (!$location) { continue }
                $root = [IO.Path]::GetFullPath($location).TrimEnd('\')
                if ($root.StartsWith($homePrefix, [StringComparison]::OrdinalIgnoreCase) -and
                    ($entry -ieq $root -or $entry.StartsWith($root + '\', [StringComparison]::OrdinalIgnoreCase)) -and
                    !(Test-Path -LiteralPath $entry)) { $obsolete = $true }
            }
            !$obsolete
        }) -join ';'
        if ($remaining -ne $path) { [Environment]::SetEnvironmentVariable('Path', $remaining, 'User') }
    }
}

Export-ModuleMember -Function *
