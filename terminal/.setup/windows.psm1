function Get-FontFiles($Font, [string]$Directory) {
    [void][IO.Directory]::CreateDirectory($Directory)
    $release = (Invoke-RestMethod -Uri ('https://api.github.com/repos/' + $Font.repository + '/releases/latest'))
    $asset = @($release.assets | Where-Object { $_.name -ceq $Font.asset })
    if ($asset.Count -ne 1) { throw "Latest font release is missing $($Font.asset)" }
    $archivePath = Join-Path $Directory 'font.zip'
    if ($asset[0].browser_download_url -notmatch '^https://') { throw 'Font downloads require HTTPS' }
    Invoke-WebRequest -UseBasicParsing -Uri $asset[0].browser_download_url -OutFile $archivePath
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [IO.Compression.ZipFile]::OpenRead($archivePath)
    try {
        foreach ($entry in $archive.Entries) {
            if ($entry.FullName -match '(^|[/\\])\.\.([/\\]|$)|^[/\\]|:') { throw 'Unsafe font archive entry' }
            if ($entry.Name -notmatch '\.ttf$') { continue }
            if ($entry.Name -notmatch '^[A-Za-z0-9._-]+\.ttf$') { throw 'Invalid font filename' }
            [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, (Join-Path $Directory $entry.Name), $true)
        }
    } finally { $archive.Dispose() }
    if (!@(Get-ChildItem -LiteralPath $Directory -Filter '*.ttf').Count) { throw 'Latest font archive contains no TrueType fonts' }
}

function Test-MachineFont([string]$PreferredFace) {
    $key = Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
    foreach ($entry in $key.PSObject.Properties) {
        if (!$entry.Name.StartsWith($PreferredFace + ' (', [StringComparison]::OrdinalIgnoreCase)) { continue }
        $file = Join-Path $env:SystemRoot ('Fonts/' + [IO.Path]::GetFileName($entry.Value))
        if (Test-Path -LiteralPath $file -PathType Leaf) { return $true }
    }
    return $false
}

function Install-Fonts($Font, [string]$BackupRoot, [string]$PreferredFace) {
    if (Test-MachineFont $PreferredFace) { return $PreferredFace }
    Add-Type -AssemblyName System.Drawing
    $target = Join-Path $env:SystemRoot 'Fonts'
    [void][IO.Directory]::CreateDirectory($target)
    $key = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
    if (!('DevenvFonts' -as [type])) { Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class DevenvFonts {
 [DllImport("gdi32.dll", CharSet=CharSet.Unicode)] public static extern int AddFontResourceEx(string path, uint flags, IntPtr reserved);
 [DllImport("user32.dll")] public static extern IntPtr SendMessageTimeout(IntPtr h, uint m, IntPtr w, IntPtr l, uint flags, uint timeout, out IntPtr result);
}
'@ }
    $staging = Join-Path ([IO.Path]::GetTempPath()) ('devenv-font-' + [guid]::NewGuid().ToString('N'))
    try {
        Get-FontFiles $Font $staging
        $collection = New-Object Drawing.Text.PrivateFontCollection
        try {
            foreach ($fontFile in Get-ChildItem -LiteralPath $staging -Filter '*.ttf') { $collection.AddFontFile($fontFile.FullName) }
            if ($collection.Families.Name -notcontains $PreferredFace) { throw 'Downloaded font does not contain the requested family' }
        } finally { $collection.Dispose() }
        foreach ($fontFile in Get-ChildItem -LiteralPath $staging -Filter '*.ttf') {
            $file = Join-Path $target $fontFile.Name
            Copy-Item -LiteralPath $fontFile.FullName -Destination $file -Force
            if ([DevenvFonts]::AddFontResourceEx($file, 0, [IntPtr]::Zero) -eq 0) { throw "Font registration failed: $file" }
            [void](New-ItemProperty -Path $key -Name ($PreferredFace + ' (' + $fontFile.BaseName + ') (TrueType)') -Value $fontFile.Name -PropertyType String -Force)
        }
    } finally {
        $resolved = [IO.Path]::GetFullPath($staging)
        $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
        if (!$resolved.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase) -or (Split-Path $resolved -Leaf) -notlike 'devenv-font-*') { throw 'Unsafe font cleanup path' }
        if (Test-Path -LiteralPath $resolved) { Remove-Item -LiteralPath $resolved -Recurse -Force }
    }
    $result = [IntPtr]::Zero
    [void][DevenvFonts]::SendMessageTimeout([IntPtr]0xffff, 0x001D, [IntPtr]::Zero, [IntPtr]::Zero, 2, 1000, [ref]$result)
    if (!(Test-MachineFont $PreferredFace)) { throw 'Font was not registered for all users' }
    return $PreferredFace
}


Export-ModuleMember -Function *
