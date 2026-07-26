$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$InstallScript = Join-Path $Root 'YS-Tools\install.ps1'
$UninstallScript = Join-Path $Root 'YS-Tools\uninstall.ps1'
$TestId = [Guid]::NewGuid().ToString('N')
$TempRoot = Join-Path ([IO.Path]::GetTempPath()) ("cadtools-installer-" + $TestId)
$ZwcadSupport = Join-Path $TempRoot 'ZWSOFT\ZWCAD\2026\zh-CN\Support'
$ZwcadDataRoot = Split-Path -Parent $ZwcadSupport
$ZwcadRegistryRoot = "HKCU:\Software\CADToolsInstallerTest\$TestId\ZWCAD"
$ZwcadProfilesRoot = Join-Path $ZwcadRegistryRoot '2026\zh-CN\Profiles'
$LegacyBundle = Join-Path $TempRoot 'legacy\AA整合版本.lsp'
$Supports = @($ZwcadSupport, (Join-Path $TempRoot 'utf8-support'))
$WhatIfSupport = Join-Path $TempRoot 'whatif-support'
$Marker = ';;; >>> YS-TOOLS AUTOLOAD >>>'
$OldBackslashEntries = @($LegacyBundle, 'C:\existing\second.lsp')
$OldSlashEntries = @($LegacyBundle.Replace('\', '/'), 'C:/existing/second.lsp')
$Profiles = @('CCESCLIENT', 'Default', '中望CAD 2026-Default')

function Assert($Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}

function Write-BigEndianFile([string]$Path, [string[]]$Entries) {
    $encoding = [Text.Encoding]::BigEndianUnicode
    $text = ($Entries -join "`r`n") + "`r`n"
    [IO.File]::WriteAllBytes($Path, [byte[]]($encoding.GetPreamble() + $encoding.GetBytes($text)))
}

function Read-BigEndianEntries([string]$Path) {
    $bytes = [IO.File]::ReadAllBytes($Path)
    Assert ($bytes[0] -eq 0xfe -and $bytes[1] -eq 0xff) "UTF-16 BE BOM missing: $Path"
    $text = [Text.Encoding]::BigEndianUnicode.GetString($bytes, 2, $bytes.Length - 2)
    return @([regex]::Split($text, "`r`n") | Where-Object { $_ -ne '' })
}

try {
    $original = @{}
    New-Item -ItemType Directory -Path $WhatIfSupport -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $WhatIfSupport 'acaddoc.lsp'), '; whatif sentinel', [Text.Encoding]::ASCII)
    $whatIfBytes = [IO.File]::ReadAllBytes((Join-Path $WhatIfSupport 'acaddoc.lsp'))
    & $InstallScript -SupportPaths $WhatIfSupport -WhatIf
    Assert (-not (Test-Path -LiteralPath (Join-Path $WhatIfSupport 'YS-Tools'))) 'WhatIf created an install directory'
    Assert (([IO.File]::ReadAllBytes((Join-Path $WhatIfSupport 'acaddoc.lsp')) -join ',') -eq ($whatIfBytes -join ',')) 'WhatIf modified acaddoc.lsp'

    foreach ($support in $Supports) {
        New-Item -ItemType Directory -Path $support -Force | Out-Null
        [IO.File]::WriteAllText((Join-Path $support 'acad.lsp'), "; user acad sentinel", [Text.Encoding]::ASCII)
    }
    New-Item -ItemType Directory -Path (Split-Path -Parent $LegacyBundle) -Force | Out-Null
    [IO.File]::WriteAllText($LegacyBundle, '(princ)', [Text.Encoding]::ASCII)
    Write-BigEndianFile (Join-Path $ZwcadDataRoot 'AppAutoLoad.app') $OldSlashEntries
    Write-BigEndianFile (Join-Path $ZwcadDataRoot 'appload.dfs') $OldBackslashEntries
    $originalAppAutoLoad = [IO.File]::ReadAllBytes((Join-Path $ZwcadDataRoot 'AppAutoLoad.app'))
    $originalApploadDfs = [IO.File]::ReadAllBytes((Join-Path $ZwcadDataRoot 'appload.dfs'))
    foreach ($profile in $Profiles) {
        $key = Join-Path (Join-Path $ZwcadProfilesRoot $profile) 'Dialogs\Appload\Startup'
        New-Item -Path $key -Force | Out-Null
        New-ItemProperty -LiteralPath $key -Name '1Startup' -Value $OldBackslashEntries[0] -PropertyType String | Out-Null
        New-ItemProperty -LiteralPath $key -Name '2Startup' -Value $OldBackslashEntries[1] -PropertyType String | Out-Null
        $kind = if ($profile -eq 'Default') { 'String' } else { 'DWord' }
        $value = if ($kind -eq 'String') { '2' } else { 2 }
        New-ItemProperty -LiteralPath $key -Name 'NumStartup' -Value $value -PropertyType $kind | Out-Null
    }
    [IO.File]::WriteAllText((Join-Path $Supports[0] 'acaddoc.lsp'), "; GBK 用户启动文件", [Text.Encoding]::GetEncoding(936))
    [IO.File]::WriteAllText((Join-Path $Supports[1] 'acaddoc.lsp'), "; UTF-8 用户启动文件", [Text.UTF8Encoding]::new($true))
    foreach ($support in $Supports) {
        $original[$support] = @{
            Acad = [IO.File]::ReadAllBytes((Join-Path $support 'acad.lsp'))
            Acaddoc = [IO.File]::ReadAllBytes((Join-Path $support 'acaddoc.lsp'))
        }
    }

    & $InstallScript -SupportPaths $Supports -ZwcadRegistryRoot $ZwcadRegistryRoot
    foreach ($support in $Supports) {
        $startup = [Text.Encoding]::GetEncoding(28591).GetString([IO.File]::ReadAllBytes((Join-Path $support 'acaddoc.lsp')))
        Assert (([regex]::Matches($startup, [regex]::Escape($Marker))).Count -eq 1) "startup marker count is not one: $support"
        $acadStartup = [Text.Encoding]::GetEncoding(28591).GetString([IO.File]::ReadAllBytes((Join-Path $support 'acad.lsp')))
        if ($support -eq $ZwcadSupport) {
            Assert (([regex]::Matches($acadStartup, [regex]::Escape($Marker))).Count -eq 1) "ZWCAD acad.lsp marker count is not one: $support"
        } else {
            Assert (([IO.File]::ReadAllBytes((Join-Path $support 'acad.lsp')) -join ',') -eq ($original[$support].Acad -join ',')) "acad.lsp was modified: $support"
        }
        Assert (Test-Path -LiteralPath (Join-Path $support 'YS-Tools\install-manifest.json')) "manifest missing: $support"
    }

    $targetPath = Join-Path $ZwcadSupport 'YS-Tools\YS-Tools.lsp'
    $pointerPath = Join-Path $ZwcadSupport 'YS-Tools\aa-bundle.path'
    Assert (Test-Path -LiteralPath $pointerPath) 'AA bundle pointer was not installed'
    $pointerValue = [Text.Encoding]::GetEncoding(936).GetString([IO.File]::ReadAllBytes($pointerPath)).Trim()
    Assert ($pointerValue -eq $LegacyBundle) 'AA bundle pointer does not target the APPLOAD bundle'
    foreach ($profile in $Profiles) {
        $key = Join-Path (Join-Path $ZwcadProfilesRoot $profile) 'Dialogs\Appload\Startup'
        $values = Get-ItemProperty -LiteralPath $key
        Assert ([int]$values.NumStartup -eq 3) "ZWCAD startup count is not three: $profile"
        Assert ($values.'1Startup' -eq $OldBackslashEntries[0]) "first ZWCAD startup entry changed: $profile"
        Assert ($values.'2Startup' -eq $OldBackslashEntries[1]) "second ZWCAD startup entry changed: $profile"
        Assert ($values.'3Startup' -eq $targetPath) "YS-Tools registry startup entry missing: $profile"
    }
    $appEntries = @(Read-BigEndianEntries (Join-Path $ZwcadDataRoot 'AppAutoLoad.app'))
    $dfsEntries = @(Read-BigEndianEntries (Join-Path $ZwcadDataRoot 'appload.dfs'))
    Assert ($appEntries.Count -eq 3 -and $appEntries[2] -eq $targetPath.Replace('\', '/')) 'AppAutoLoad.app entry missing or duplicated'
    Assert ($dfsEntries.Count -eq 3 -and $dfsEntries[2] -eq $targetPath) 'appload.dfs entry missing or duplicated'

    $customConfig = Join-Path $Supports[0] 'YS-Tools\config.lsp'
    [IO.File]::AppendAllText($customConfig, "`r`n;;; user customization", [Text.Encoding]::GetEncoding(936))
    $customHash = (Get-FileHash -LiteralPath $customConfig -Algorithm SHA256).Hash
    & $InstallScript -SupportPaths $Supports -ZwcadRegistryRoot $ZwcadRegistryRoot
    Assert ((Get-FileHash -LiteralPath $customConfig -Algorithm SHA256).Hash -eq $customHash) 'custom config was overwritten during upgrade'
    foreach ($profile in $Profiles) {
        $key = Join-Path (Join-Path $ZwcadProfilesRoot $profile) 'Dialogs\Appload\Startup'
        $values = Get-ItemProperty -LiteralPath $key
        Assert ([int]$values.NumStartup -eq 3) "repeat install duplicated registry startup entry: $profile"
    }
    Assert ((@(Read-BigEndianEntries (Join-Path $ZwcadDataRoot 'AppAutoLoad.app'))).Count -eq 3) 'repeat install duplicated AppAutoLoad.app entry'
    Assert ((@(Read-BigEndianEntries (Join-Path $ZwcadDataRoot 'appload.dfs'))).Count -eq 3) 'repeat install duplicated appload.dfs entry'

    & $UninstallScript -SupportPaths $Supports -ZwcadRegistryRoot $ZwcadRegistryRoot
    foreach ($support in $Supports) {
        Assert (([IO.File]::ReadAllBytes((Join-Path $support 'acad.lsp')) -join ',') -eq ($original[$support].Acad -join ',')) "acad.lsp changed after uninstall: $support"
        Assert (([IO.File]::ReadAllBytes((Join-Path $support 'acaddoc.lsp')) -join ',') -eq ($original[$support].Acaddoc -join ',')) "acaddoc.lsp did not round-trip: $support"
    }
    Assert (-not (Test-Path -LiteralPath $customConfig)) 'modified config was not moved out of the install directory'
    Assert (-not (Test-Path -LiteralPath $pointerPath)) 'AA bundle pointer remains after uninstall'
    Assert ((Get-ChildItem -LiteralPath (Join-Path $Supports[0] 'YS-Tools-backups') -Recurse -Filter 'config.lsp' | Measure-Object).Count -ge 1) 'modified config backup missing'
    foreach ($profile in $Profiles) {
        $key = Join-Path (Join-Path $ZwcadProfilesRoot $profile) 'Dialogs\Appload\Startup'
        $values = Get-ItemProperty -LiteralPath $key
        Assert ([int]$values.NumStartup -eq 2) "ZWCAD startup count was not restored: $profile"
        Assert ($values.'1Startup' -eq $OldBackslashEntries[0]) "first ZWCAD startup entry changed after uninstall: $profile"
        Assert ($values.'2Startup' -eq $OldBackslashEntries[1]) "second ZWCAD startup entry changed after uninstall: $profile"
        Assert ($null -eq $values.'3Startup') "YS-Tools registry startup entry remains after uninstall: $profile"
    }
    Assert (([IO.File]::ReadAllBytes((Join-Path $ZwcadDataRoot 'AppAutoLoad.app')) -join ',') -eq ($originalAppAutoLoad -join ',')) 'AppAutoLoad.app did not round-trip'
    Assert (([IO.File]::ReadAllBytes((Join-Path $ZwcadDataRoot 'appload.dfs')) -join ',') -eq ($originalApploadDfs -join ',')) 'appload.dfs did not round-trip'
    Write-Host 'installer round-trip test passed'
}
finally {
    $registryTestBase = "HKCU:\Software\CADToolsInstallerTest\$TestId"
    if (Test-Path -LiteralPath $registryTestBase) { Remove-Item -LiteralPath $registryTestBase -Recurse -Force }
    $resolvedTemp = [IO.Path]::GetFullPath($TempRoot)
    $systemTemp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
    if ($resolvedTemp.StartsWith($systemTemp, [StringComparison]::OrdinalIgnoreCase) -and (Test-Path -LiteralPath $resolvedTemp)) {
        Remove-Item -LiteralPath $resolvedTemp -Recurse -Force
    }
}
