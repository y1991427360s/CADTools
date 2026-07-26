[CmdletBinding()]
param(
    [ValidateSet('Main', 'Bundle')]
    [string]$Mode = 'Main',
    [string]$ConsolePath = 'D:\Autodesk\CAD2018\AutoCAD 2018\accoreconsole.exe',
    [string]$TemplatePath = 'D:\Autodesk\CAD2018\AutoCAD 2018\Template\acad.dwt',
    [string]$AaBundlePath
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path -LiteralPath $ConsolePath)) { throw "AutoCAD console not found: $ConsolePath" }
if (-not (Test-Path -LiteralPath $TemplatePath)) { throw "AutoCAD template not found: $TemplatePath" }

$commands = if ($Mode -eq 'Main') {
    $mainCommands = @('ADDKEYWORD','BIAN','CONT','DIAGFRAME','EXCEL','FILLFRAMES','GG','GTX','GTY','HAO','HE','HEI','KUANG','LAN','LONG','NU','PAI','QSTXT','QW','RR','SHANG','SHOWBB','SJ','SSUO','SYAN','SYI','T','TXT','UU','WI','XIA','XIN','XJ','XSUO','XY','XYAN','XYI','Y','YAN','YOU','YS','YSDL','YSOOLS','YSRELOADAA','YSTOOLS','YYI','ZDML','ZDMLDEBUG','ZHONG','ZUO','ZYI')
    if ($AaBundlePath) {
        $aaCommands = @('AB','AF','AW','BIAN','C1','C2','CE','DB','DE','DE2','DF','FIVE','GE','GG','GTX','GTY','HAO','HE','HEI','HP','HUI','JACC','JZ','KAI','LAN','NU','QSTXT','QW','RR','SHANG','SJ','SYAN','T','UU','WI','XIA','XIN','XJ','XY','XYAN','Y','YAN','YSDL','YOU','ZDML','ZDMLDEBUG','ZHENG','ZHONG','ZI','ZUO','ZZ')
        @($mainCommands + $aaCommands | Sort-Object -Unique)
    } else {
        $mainCommands
    }
} else {
    @('BIAN','CONT','EXCEL','GG','GTX','GTY','HE','HEI','KUANG','LAN','LONG','NU','QSTXT','QW','RR','SHANG','SJ','SSUO','SYAN','SYI','T','TXT','UU','WI','XIA','XIN','XJ','XSUO','XY','XYAN','XYI','Y','YAN','YOU','YSDL','YYI','ZHONG','ZUO','ZYI')
}

$temp = Join-Path ([IO.Path]::GetTempPath()) ("cadtools-load-" + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $temp -Force | Out-Null
try {
    $resultPath = Join-Path $temp 'result.txt'
    $scriptPath = Join-Path $temp 'verify.scr'
    $entry = if ($Mode -eq 'Main') {
        Join-Path $Root 'YS-Tools\YS-Tools.lsp'
    } else {
        Get-ChildItem -LiteralPath $Root -File -Filter 'AA*.lsp' | Select-Object -First 1 -ExpandProperty FullName
    }
    if (-not $entry) { throw 'Compatibility bundle was not found' }
    if ($AaBundlePath -and -not (Test-Path -LiteralPath $AaBundlePath)) { throw "AA bundle was not found: $AaBundlePath" }
    $entryLisp = ([IO.Path]::GetFullPath($entry)).Replace('\', '/')
    $toolsLisp = ([IO.Path]::GetFullPath((Join-Path $Root 'YS-Tools'))).Replace('\', '/')
    $aaLisp = if ($AaBundlePath) { ([IO.Path]::GetFullPath($AaBundlePath)).Replace('\', '/') } else { '' }
    $resultLisp = ([IO.Path]::GetFullPath($resultPath)).Replace('\', '/')
    $symbols = ($commands | ForEach-Object { "C:$_" }) -join ' '
    $versionLine = if ($Mode -eq 'Main') {
        '(write-line (strcat "VERSION=" (if (boundp ''*ys-tools-version*) *ys-tools-version* "MISSING")) __f)'
    } else {
        '(write-line "VERSION=1.5.0" __f)'
    }
$script = @"
(setvar "SECURELOAD" 0)
(setenv "YS_TOOLS_PATH" "$toolsLisp")
(setenv "YS_AA_BUNDLE_PATH" "$aaLisp")
(setq __load1 (vl-catch-all-apply 'load (list "$entryLisp")))
(setq __load2 (vl-catch-all-apply 'load (list "$entryLisp")))
(setq __f (open "$resultLisp" "w"))
(if (vl-catch-all-error-p __load1)
  (write-line (strcat "LOAD1_ERROR=" (vl-catch-all-error-message __load1)) __f)
  (write-line "LOAD1=OK" __f))
(if (vl-catch-all-error-p __load2)
  (write-line (strcat "LOAD2_ERROR=" (vl-catch-all-error-message __load2)) __f)
  (write-line "LOAD2=OK" __f))
(foreach __s '($symbols)
  (write-line
    (strcat (vl-princ-to-string __s) "="
      (if (member (strcase (vl-princ-to-string __s)) (atoms-family 1)) "OK" "MISSING"))
    __f))
$versionLine
(close __f)
"@
    [IO.File]::WriteAllText($scriptPath, $script.Replace("`n", "`r`n"), [Text.Encoding]::GetEncoding(936))

    $stdoutPath = Join-Path $temp 'stdout.txt'
    $stderrPath = Join-Path $temp 'stderr.txt'
    $arguments = @('/i', "`"$TemplatePath`"", '/s', "`"$scriptPath`"", '/l', 'en-US')
    $process = Start-Process -FilePath $ConsolePath -ArgumentList $arguments -PassThru -WindowStyle Hidden -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
    $deadline = (Get-Date).AddSeconds(30)
    while (-not $process.HasExited -and -not (Test-Path -LiteralPath $resultPath) -and (Get-Date) -lt $deadline) {
        Start-Sleep -Milliseconds 200
        $process.Refresh()
    }
    if (-not (Test-Path -LiteralPath $resultPath)) {
        $stdout = if (Test-Path $stdoutPath) { Get-Content $stdoutPath -Raw } else { '' }
        $stderr = if (Test-Path $stderrPath) { Get-Content $stderrPath -Raw } else { '' }
        throw "AutoCAD did not create the verification result. stdout=$stdout stderr=$stderr"
    }
    if (-not $process.HasExited) {
        Stop-Process -Id $process.Id -Force
        $process.WaitForExit()
    }
    $result = [Text.Encoding]::GetEncoding(936).GetString([IO.File]::ReadAllBytes($resultPath)) -split "`r?`n"
    $loadErrors = $result | Where-Object { $_ -like 'LOAD*_ERROR=*' }
    foreach ($loadError in $loadErrors) { Write-Warning $loadError }
    $missing = $result | Where-Object { $_ -like '*=MISSING' }
    if ($missing) { throw "Missing commands: $($missing -join ', ')" }
    if ($Mode -eq 'Main' -and 'VERSION=1.5.0' -notin $result) { throw 'Loaded version is not 1.5.0' }
    if ('LOAD2=OK' -notin $result) { throw 'Repeated load did not complete successfully' }
    Write-Host "AutoCAD $Mode load test passed ($($commands.Count) commands)"
}
finally {
    $resolved = [IO.Path]::GetFullPath($temp)
    $systemTemp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
    if ($resolved.StartsWith($systemTemp, [StringComparison]::OrdinalIgnoreCase) -and (Test-Path -LiteralPath $resolved)) {
        Remove-Item -LiteralPath $resolved -Recurse -Force
    }
}
