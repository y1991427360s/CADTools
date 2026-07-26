[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string[]]$SupportPaths,
    [string]$ZwcadRegistryRoot = 'HKCU:\Software\ZWSOFT\ZWCAD'
)

$ErrorActionPreference = 'Stop'
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

function Get-FileSha256([string]$Path) { return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant() }

function Backup-File {
    param([string]$Path, [string]$BackupRoot, [string]$RelativePath, [switch]$Move)
    $destination = Join-Path $BackupRoot $RelativePath
    $parent = Split-Path -Parent $destination
    if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    if ($Move) { Move-Item -LiteralPath $Path -Destination $destination -Force }
    else { Copy-Item -LiteralPath $Path -Destination $destination -Force }
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
        throw "ZWCAD is running (PID $($process.Id)). Save drawings, close ZWCAD, and run the uninstaller again."
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

function Remove-ZwcadStartupFileEntry {
    param([string]$Path, [string]$TargetPath, [string]$BackupRoot)
    if (-not (Test-Path -LiteralPath $Path)) { return }
    $entries = @(Get-StartupFileEntries $Path)
    $updated = @($entries | Where-Object { -not (Test-SameStartupPath $_ $TargetPath) })
    if (($entries -join "`0") -ceq ($updated -join "`0")) { return }
    if ($PSCmdlet.ShouldProcess($Path, 'backup and remove YS-Tools from ZWCAD APPLOAD startup file')) {
        Backup-File $Path $BackupRoot (Join-Path 'zwcad-startup' (Split-Path -Leaf $Path))
        Write-BigEndianStartupFile $Path $updated
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

function Remove-ZwcadRegistryStartupEntry {
    param([string]$ProfilesRoot, [string]$TargetPath, [string]$BackupRoot)
    if (-not (Test-Path -LiteralPath $ProfilesRoot)) { return }
    foreach ($profile in Get-ChildItem -LiteralPath $ProfilesRoot) {
        $keyPath = Join-Path (Join-Path $ProfilesRoot $profile.PSChildName) 'Dialogs\Appload\Startup'
        if (-not (Test-Path -LiteralPath $keyPath)) { continue }
        $entries = @(Get-RegistryStartupEntries $keyPath)
        $updated = @($entries | Where-Object { -not (Test-SameStartupPath $_ $TargetPath) })
        if (($entries -join "`0") -ceq ($updated -join "`0")) { continue }
        if ($PSCmdlet.ShouldProcess($keyPath, 'backup and remove YS-Tools from ZWCAD APPLOAD startup registry')) {
            Backup-RegistryKey $keyPath $BackupRoot $profile.PSChildName
            Write-RegistryStartupEntries $keyPath $updated
        }
    }
}

function Remove-ZwcadStartupRegistration {
    param([object]$Info, [string]$TargetPath, [string]$BackupRoot)
    Remove-ZwcadStartupFileEntry (Join-Path $Info.DataRoot 'AppAutoLoad.app') $TargetPath $BackupRoot
    Remove-ZwcadStartupFileEntry (Join-Path $Info.DataRoot 'appload.dfs') $TargetPath $BackupRoot
    Remove-ZwcadRegistryStartupEntry $Info.ProfilesRoot $TargetPath $BackupRoot
}

function Remove-StartupBlock {
    param([string]$SupportPath, [string]$BackupRoot, [string]$FileName)
    $path = Join-Path $SupportPath $FileName
    if (-not (Test-Path -LiteralPath $path)) { return }
    $raw = $Latin1.GetString([IO.File]::ReadAllBytes($path))
    $start = $raw.IndexOf($StartMarker, [StringComparison]::Ordinal)
    if ($start -lt 0) { return }
    $end = $raw.IndexOf($EndMarker, $start, [StringComparison]::Ordinal)
    if ($end -lt 0) { throw "Startup marker is incomplete: $path" }
    $end += $EndMarker.Length
    if ($start -ge 2 -and $raw.Substring($start - 2, 2) -eq "`r`n") { $start -= 2 }
    elseif ($start -ge 1 -and $raw[$start - 1] -eq "`n") { $start -= 1 }
    if ($end -lt $raw.Length -and $raw.Substring($end).StartsWith("`r`n")) { $end += 2 }
    elseif ($end -lt $raw.Length -and $raw[$end] -eq "`n") { $end += 1 }
    $updated = $raw.Remove($start, $end - $start)
    if ($PSCmdlet.ShouldProcess($path, 'backup and remove YS-Tools startup block')) {
        Backup-File $path $BackupRoot $FileName
        [IO.File]::WriteAllBytes($path, $Latin1.GetBytes($updated))
    }
}

function Uninstall-OneTarget {
    param([string]$SupportPath)
    $support = [IO.Path]::GetFullPath($SupportPath)
    if (-not (Test-Path -LiteralPath $support)) { return }
    $zwcadInfo = Get-ZwcadInstallInfo $support
    if ($zwcadInfo) { Assert-ZwcadClosed $support }
    $installRoot = Join-Path $support 'YS-Tools'
    $manifestPath = Join-Path $installRoot 'install-manifest.json'
    $backupRoot = Join-Path $support "YS-Tools-backups\uninstall-$Timestamp"
    if ($zwcadInfo) {
        Remove-ZwcadStartupRegistration $zwcadInfo (Join-Path $installRoot 'YS-Tools.lsp') $backupRoot
    }
    if (Test-Path -LiteralPath $manifestPath) {
        $manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
        foreach ($entry in $manifest.files) {
            $path = Join-Path $support $entry.path
            if (-not (Test-Path -LiteralPath $path)) { continue }
            if ((Get-FileSha256 $path) -eq $entry.sha256) {
                if ($PSCmdlet.ShouldProcess($path, 'remove unmodified YS-Tools file')) { Remove-Item -LiteralPath $path -Force }
            } elseif ($PSCmdlet.ShouldProcess($path, 'move modified YS-Tools file to backup')) {
                Backup-File $path $backupRoot $entry.path -Move
            }
        }
        if ($PSCmdlet.ShouldProcess($manifestPath, 'remove install manifest')) { Remove-Item -LiteralPath $manifestPath -Force }
    }
    Remove-StartupBlock -SupportPath $support -BackupRoot $backupRoot -FileName 'acaddoc.lsp'
    if ($support -match '(?i)[\\/]ZWSOFT[\\/]ZWCAD[\\/]') {
        Remove-StartupBlock -SupportPath $support -BackupRoot $backupRoot -FileName 'acad.lsp'
    }
    foreach ($directory in @((Join-Path $installRoot 'modules'), (Join-Path $installRoot 'dcl'), $installRoot, (Join-Path $support '小命令'))) {
        if ((Test-Path -LiteralPath $directory) -and -not (Get-ChildItem -LiteralPath $directory -Force | Select-Object -First 1)) {
            if ($PSCmdlet.ShouldProcess($directory, 'remove empty directory')) { Remove-Item -LiteralPath $directory -Force }
        }
    }
    Write-Host "YS-Tools removed: $support"
}

if (-not $SupportPaths -or $SupportPaths.Count -eq 0) { $SupportPaths = Get-DefaultSupportPaths }
if (-not $SupportPaths -or $SupportPaths.Count -eq 0) { throw 'No CAD support directory found. Use -SupportPaths.' }
foreach ($path in $SupportPaths | Select-Object -Unique) { Uninstall-OneTarget $path }
