[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string[]]$SupportPaths,
    [string]$ZwcadRegistryRoot = 'HKCU:\Software\ZWSOFT\ZWCAD'
)

$ErrorActionPreference = 'Stop'
$Version = '1.5.0'
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$StartMarker = ';;; >>> YS-TOOLS AUTOLOAD >>>'
$EndMarker = ';;; <<< YS-TOOLS AUTOLOAD <<<'
$Latin1 = [Text.Encoding]::GetEncoding(28591)
$Timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'

function Get-DefaultSupportPaths {
    $paths = [Collections.Generic.List[string]]::new()
    $autoCad = Join-Path $env:APPDATA 'Autodesk\AutoCAD 2018\R22.0\chs\Support'
    if (Test-Path -LiteralPath $autoCad) { $paths.Add($autoCad) }
    $zwRoot = Join-Path $env:APPDATA 'ZWSOFT\ZWCAD'
    if (Test-Path -LiteralPath $zwRoot) {
        Get-ChildItem -LiteralPath $zwRoot -Directory | ForEach-Object {
            foreach ($relative in @('zh-CN\Support', 'Support')) {
                $candidate = Join-Path $_.FullName $relative
                if ((Test-Path -LiteralPath $candidate) -and -not $paths.Contains($candidate)) { $paths.Add($candidate) }
            }
        }
    }
    return $paths.ToArray()
}

function Get-RelativePath {
    param([string]$BasePath, [string]$Path)
    $base = [IO.Path]::GetFullPath($BasePath).TrimEnd('\') + '\'
    $full = [IO.Path]::GetFullPath($Path)
    return [Uri]::UnescapeDataString(([Uri]$base).MakeRelativeUri([Uri]$full).ToString()).Replace('/', '\')
}

function Get-FileSha256 {
    param([string]$Path)
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Backup-File {
    param([string]$Path, [string]$BackupRoot, [string]$RelativePath)
    $destination = Join-Path $BackupRoot $RelativePath
    $parent = Split-Path -Parent $destination
    if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    Copy-Item -LiteralPath $Path -Destination $destination -Force
}

function Get-ZwcadInstallInfo {
    param([string]$SupportPath)
    $support = [IO.Path]::GetFullPath($SupportPath).TrimEnd('\')
    $parts = $support.Split('\')
    if ($parts.Count -lt 3 -or $parts[-1] -ine 'Support') { return $null }
    $zwcadIndex = -1
    for ($index = 0; $index -lt $parts.Count; $index++) {
        if ($parts[$index] -ieq 'ZWCAD') { $zwcadIndex = $index }
    }
    if ($zwcadIndex -lt 0 -or $zwcadIndex + 1 -ge $parts.Count - 1) { return $null }
    $version = $parts[$zwcadIndex + 1]
    $locale = if ($zwcadIndex + 2 -lt $parts.Count - 1) { $parts[$zwcadIndex + 2] } else { $null }
    $registryBase = Join-Path $ZwcadRegistryRoot $version
    if ($locale) { $registryBase = Join-Path $registryBase $locale }
    return [pscustomobject]@{
        DataRoot = Split-Path -Parent $support
        ProfilesRoot = Join-Path $registryBase 'Profiles'
    }
}

function Test-IsRealZwcadSupport {
    param([string]$SupportPath)
    $realRoot = [IO.Path]::GetFullPath((Join-Path $env:APPDATA 'ZWSOFT\ZWCAD')).TrimEnd('\') + '\'
    $support = [IO.Path]::GetFullPath($SupportPath).TrimEnd('\') + '\'
    return $support.StartsWith($realRoot, [StringComparison]::OrdinalIgnoreCase)
}

function Assert-ZwcadClosed {
    param([string]$SupportPath)
    if ($WhatIfPreference -or -not (Test-IsRealZwcadSupport $SupportPath)) { return }
    $process = Get-Process -Name 'ZWCAD' -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($process) {
        throw "ZWCAD is running (PID $($process.Id)). Save drawings, close ZWCAD, and run the installer again."
    }
}

function Test-SameStartupPath {
    param([string]$Left, [string]$Right)
    $leftPath = $Left.Trim().Trim('"').Replace('/', '\')
    $rightPath = $Right.Trim().Trim('"').Replace('/', '\')
    try { $leftPath = [IO.Path]::GetFullPath($leftPath) } catch {}
    try { $rightPath = [IO.Path]::GetFullPath($rightPath) } catch {}
    return $leftPath.TrimEnd('\').Equals($rightPath.TrimEnd('\'), [StringComparison]::OrdinalIgnoreCase)
}

function Get-StartupFileEntries {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return @() }
    $bytes = [IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -ge 2 -and $bytes[0] -eq 0xfe -and $bytes[1] -eq 0xff) {
        $text = [Text.Encoding]::BigEndianUnicode.GetString($bytes, 2, $bytes.Length - 2)
    } elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xff -and $bytes[1] -eq 0xfe) {
        $text = [Text.Encoding]::Unicode.GetString($bytes, 2, $bytes.Length - 2)
    } else {
        $text = [Text.Encoding]::UTF8.GetString($bytes).TrimStart([char]0xfeff)
    }
    return @([regex]::Split($text, "`r`n|`n|`r") | Where-Object { $_ -ne '' })
}

function Write-BigEndianStartupFile {
    param([string]$Path, [string[]]$Entries)
    $text = if ($Entries.Count -gt 0) { ($Entries -join "`r`n") + "`r`n" } else { '' }
    $encoding = [Text.Encoding]::BigEndianUnicode
    $bytes = [byte[]]($encoding.GetPreamble() + $encoding.GetBytes($text))
    [IO.File]::WriteAllBytes($Path, $bytes)
}

function Set-ZwcadStartupFileEntry {
    param([string]$Path, [string]$TargetPath, [string]$StoredPath, [string]$BackupRoot)
    $entries = @(Get-StartupFileEntries $Path)
    $updated = [Collections.Generic.List[string]]::new()
    $found = $false
    foreach ($entry in $entries) {
        if (Test-SameStartupPath $entry $TargetPath) {
            if (-not $found) { $updated.Add($StoredPath); $found = $true }
        } else {
            $updated.Add($entry)
        }
    }
    if (-not $found) { $updated.Add($StoredPath) }
    if (($entries -join "`0") -ceq ($updated.ToArray() -join "`0")) { return }
    if ($PSCmdlet.ShouldProcess($Path, 'backup and update ZWCAD APPLOAD startup file')) {
        if (Test-Path -LiteralPath $Path) { Backup-File $Path $BackupRoot (Join-Path 'zwcad-startup' (Split-Path -Leaf $Path)) }
        Write-BigEndianStartupFile $Path $updated.ToArray()
    }
}

function Get-RegistryStartupEntries {
    param([string]$KeyPath)
    if (-not (Test-Path -LiteralPath $KeyPath)) { return @() }
    $properties = (Get-ItemProperty -LiteralPath $KeyPath).PSObject.Properties |
        Where-Object { $_.Name -match '^(\d+)Startup$' } |
        Sort-Object { [int]([regex]::Match($_.Name, '^\d+').Value) }
    return @($properties | ForEach-Object { [string]$_.Value })
}

function Test-AaBundlePath {
    param([string]$Path)
    if (-not $Path) { return $false }
    $clean = $Path.Trim().Trim('"').Replace('/', '\')
    return [IO.Path]::GetFileName($clean).Equals('AA整合版本.lsp', [StringComparison]::OrdinalIgnoreCase)
}

function Get-ZwcadAaBundlePath {
    param([object]$Info)
    if (Test-Path -LiteralPath $Info.ProfilesRoot) {
        foreach ($profile in Get-ChildItem -LiteralPath $Info.ProfilesRoot) {
            $keyPath = Join-Path (Join-Path $Info.ProfilesRoot $profile.PSChildName) 'Dialogs\Appload\Startup'
            foreach ($entry in @(Get-RegistryStartupEntries $keyPath)) {
                if ((Test-AaBundlePath $entry) -and (Test-Path -LiteralPath $entry)) {
                    return [IO.Path]::GetFullPath($entry)
                }
            }
        }
    }
    foreach ($name in 'appload.dfs', 'AppAutoLoad.app') {
        foreach ($entry in @(Get-StartupFileEntries (Join-Path $Info.DataRoot $name))) {
            $candidate = $entry.Replace('/', '\')
            if ((Test-AaBundlePath $candidate) -and (Test-Path -LiteralPath $candidate)) {
                return [IO.Path]::GetFullPath($candidate)
            }
        }
    }
    return $null
}

function Write-AaBundlePointer {
    param([string]$InstallRoot, [string]$BundlePath, [string]$SupportPath, [object]$Managed)
    if (-not $BundlePath) { return }
    $destination = Join-Path $InstallRoot 'aa-bundle.path'
    if ($PSCmdlet.ShouldProcess($destination, 'write AA bundle source pointer')) {
        if (-not (Test-Path -LiteralPath $InstallRoot)) { New-Item -ItemType Directory -Path $InstallRoot -Force | Out-Null }
        $gbk = [Text.Encoding]::GetEncoding(936)
        [IO.File]::WriteAllBytes($destination, $gbk.GetBytes($BundlePath + "`r`n"))
        $Managed.Add([pscustomobject]@{
            path = Get-RelativePath $SupportPath $destination
            sha256 = Get-FileSha256 $destination
        })
    }
}

function ConvertTo-NativeRegistryPath {
    param([string]$Path)
    if ($Path.StartsWith('HKCU:\', [StringComparison]::OrdinalIgnoreCase)) {
        return 'HKEY_CURRENT_USER\' + $Path.Substring(6)
    }
    throw "Unsupported registry path: $Path"
}

function Backup-RegistryKey {
    param([string]$KeyPath, [string]$BackupRoot, [string]$ProfileName)
    if (-not (Test-Path -LiteralPath $KeyPath)) { return }
    $destination = Join-Path $BackupRoot (Join-Path 'zwcad-startup\registry' ($ProfileName + '.reg'))
    $parent = Split-Path -Parent $destination
    if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    & reg.exe export (ConvertTo-NativeRegistryPath $KeyPath) $destination /y | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Failed to back up registry key: $KeyPath" }
}

function Write-RegistryStartupEntries {
    param([string]$KeyPath, [string[]]$Entries)
    if (-not (Test-Path -LiteralPath $KeyPath)) { New-Item -Path $KeyPath -Force | Out-Null }
    $key = Get-Item -LiteralPath $KeyPath
    $numKind = 'DWord'
    if ($key.GetValueNames() -contains 'NumStartup') { $numKind = $key.GetValueKind('NumStartup').ToString() }
    foreach ($name in @($key.GetValueNames() | Where-Object { $_ -match '^\d+Startup$' })) {
        Remove-ItemProperty -LiteralPath $KeyPath -Name $name
    }
    for ($index = 0; $index -lt $Entries.Count; $index++) {
        New-ItemProperty -LiteralPath $KeyPath -Name (($index + 1).ToString() + 'Startup') -Value $Entries[$index] -PropertyType String -Force | Out-Null
    }
    $numValue = if ($numKind -eq 'String') { [string]$Entries.Count } else { [int]$Entries.Count }
    New-ItemProperty -LiteralPath $KeyPath -Name 'NumStartup' -Value $numValue -PropertyType $numKind -Force | Out-Null
}

function Set-ZwcadRegistryStartupEntry {
    param([string]$ProfilesRoot, [string]$TargetPath, [string]$BackupRoot)
    if (-not (Test-Path -LiteralPath $ProfilesRoot)) {
        Write-Warning "ZWCAD profiles registry key was not found: $ProfilesRoot"
        return
    }
    foreach ($profile in Get-ChildItem -LiteralPath $ProfilesRoot) {
        $keyPath = Join-Path (Join-Path $ProfilesRoot $profile.PSChildName) 'Dialogs\Appload\Startup'
        $entries = @(Get-RegistryStartupEntries $keyPath)
        $updated = [Collections.Generic.List[string]]::new()
        $found = $false
        foreach ($entry in $entries) {
            if (Test-SameStartupPath $entry $TargetPath) {
                if (-not $found) { $updated.Add($TargetPath); $found = $true }
            } else {
                $updated.Add($entry)
            }
        }
        if (-not $found) { $updated.Add($TargetPath) }
        if (($entries -join "`0") -ceq ($updated.ToArray() -join "`0")) { continue }
        if ($PSCmdlet.ShouldProcess($keyPath, 'backup and update ZWCAD APPLOAD startup registry')) {
            Backup-RegistryKey $keyPath $BackupRoot $profile.PSChildName
            Write-RegistryStartupEntries $keyPath $updated.ToArray()
        }
    }
}

function Set-ZwcadStartupRegistration {
    param([object]$Info, [string]$TargetPath, [string]$BackupRoot)
    $appPath = Join-Path $Info.DataRoot 'AppAutoLoad.app'
    $dfsPath = Join-Path $Info.DataRoot 'appload.dfs'
    Set-ZwcadStartupFileEntry $appPath $TargetPath ($TargetPath.Replace('\', '/')) $BackupRoot
    Set-ZwcadStartupFileEntry $dfsPath $TargetPath $TargetPath $BackupRoot
    Set-ZwcadRegistryStartupEntry $Info.ProfilesRoot $TargetPath $BackupRoot
}

function Set-StartupBlock {
    param([string]$SupportPath, [string]$BackupRoot, [string]$FileName)
    $path = Join-Path $SupportPath $FileName
    $bytes = if (Test-Path -LiteralPath $path) { [IO.File]::ReadAllBytes($path) } else { [byte[]]@() }
    $raw = $Latin1.GetString($bytes)
    $start = $raw.IndexOf($StartMarker, [StringComparison]::Ordinal)
    $newLine = if ($raw.Contains("`r`n")) { "`r`n" } else { "`n" }
    $block = @(
        $StartMarker,
        '(if (findfile "YS-Tools\\YS-Tools.lsp")',
        '  (load "YS-Tools\\YS-Tools.lsp" nil)',
        ')',
        $EndMarker
    ) -join $newLine
    if ($start -ge 0) {
        $end = $raw.IndexOf($EndMarker, $start, [StringComparison]::Ordinal)
        if ($end -lt 0) { throw "Startup marker is incomplete: $path" }
        $end += $EndMarker.Length
        $updated = $raw.Substring(0, $start) + $block + $raw.Substring($end)
    } else {
        $updated = $raw + $newLine + $block + $newLine
    }
    if ($updated -eq $raw) { return }
    if ($PSCmdlet.ShouldProcess($path, 'backup and update YS-Tools startup block')) {
        if (Test-Path -LiteralPath $path) { Backup-File $path $BackupRoot $FileName }
        [IO.File]::WriteAllBytes($path, $Latin1.GetBytes($updated))
    }
}

function Install-OneTarget {
    param([string]$SupportPath)
    $support = [IO.Path]::GetFullPath($SupportPath)
    if (-not (Test-Path -LiteralPath $support)) { throw "CAD support directory does not exist: $support" }
    $zwcadInfo = Get-ZwcadInstallInfo $support
    if ($zwcadInfo) { Assert-ZwcadClosed $support }
    $installRoot = Join-Path $support 'YS-Tools'
    $smallRoot = Join-Path $support '小命令'
    $backupRoot = Join-Path $support "YS-Tools-backups\install-$Timestamp"
    $manifestPath = Join-Path $installRoot 'install-manifest.json'
    $oldManifest = if (Test-Path -LiteralPath $manifestPath) {
        Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
    } else { $null }

    $sources = [Collections.Generic.List[object]]::new()
    foreach ($name in @('YS-Tools.lsp', 'utils.lsp')) {
        $sources.Add([pscustomobject]@{ Source = Join-Path $PSScriptRoot $name; Destination = Join-Path $installRoot $name; Preserve = $false })
    }
    Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'modules') -File -Filter '*.lsp' | ForEach-Object {
        $sources.Add([pscustomobject]@{ Source = $_.FullName; Destination = Join-Path (Join-Path $installRoot 'modules') $_.Name; Preserve = $false })
    }
    Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'dcl') -File | ForEach-Object {
        $sources.Add([pscustomobject]@{ Source = $_.FullName; Destination = Join-Path (Join-Path $installRoot 'dcl') $_.Name; Preserve = $false })
    }
    $sources.Add([pscustomobject]@{ Source = Join-Path $PSScriptRoot 'config.lsp'; Destination = Join-Path $installRoot 'config.lsp'; Preserve = $true })
    $sources.Add([pscustomobject]@{ Source = Join-Path $ProjectRoot 'AA整合版本.lsp'; Destination = Join-Path $support 'AA整合版本.lsp'; Preserve = $false })
    foreach ($name in @('排列框PAI.LSP', '自动目录ZDML.lsp', '自动页码HAO.lsp', '芯原XY.lsp')) {
        $sources.Add([pscustomobject]@{ Source = Join-Path (Join-Path $ProjectRoot '小命令') $name; Destination = Join-Path $smallRoot $name; Preserve = $false })
    }

    $managed = [Collections.Generic.List[object]]::new()
    foreach ($item in $sources) {
        $relative = Get-RelativePath $support $item.Destination
        if ($item.Preserve -and (Test-Path -LiteralPath $item.Destination)) {
            if ($oldManifest) {
                $oldEntry = $oldManifest.files | Where-Object { $_.path -eq $relative } | Select-Object -First 1
                if ($oldEntry) { $managed.Add($oldEntry) }
            }
            Write-Host "Preserved user configuration: $($item.Destination)"
            continue
        }
        if ($PSCmdlet.ShouldProcess($item.Destination, 'install YS-Tools file')) {
            $parent = Split-Path -Parent $item.Destination
            if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
            Copy-Item -LiteralPath $item.Source -Destination $item.Destination -Force
            $managed.Add([pscustomobject]@{ path = $relative; sha256 = Get-FileSha256 $item.Destination })
        }
    }
    if ($zwcadInfo) {
        Write-AaBundlePointer $installRoot (Get-ZwcadAaBundlePath $zwcadInfo) $support $managed
    }
    Set-StartupBlock -SupportPath $support -BackupRoot $backupRoot -FileName 'acaddoc.lsp'
    if ($support -match '(?i)[\\/]ZWSOFT[\\/]ZWCAD[\\/]') {
        Set-StartupBlock -SupportPath $support -BackupRoot $backupRoot -FileName 'acad.lsp'
    }
    if ($zwcadInfo) {
        Set-ZwcadStartupRegistration $zwcadInfo (Join-Path $installRoot 'YS-Tools.lsp') $backupRoot
    }
    if ($PSCmdlet.ShouldProcess($manifestPath, 'write install manifest')) {
        if (-not (Test-Path -LiteralPath $installRoot)) { New-Item -ItemType Directory -Path $installRoot -Force | Out-Null }
        [pscustomobject]@{
            version = $Version
            installedAt = (Get-Date).ToString('o')
            supportPath = $support
            files = $managed
        } | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
    }
    Write-Host "YS-Tools v$Version installed: $support"
}

if (-not $SupportPaths -or $SupportPaths.Count -eq 0) { $SupportPaths = Get-DefaultSupportPaths }
if (-not $SupportPaths -or $SupportPaths.Count -eq 0) { throw 'No CAD support directory found. Use -SupportPaths.' }
foreach ($path in $SupportPaths | Select-Object -Unique) { Install-OneTarget $path }
