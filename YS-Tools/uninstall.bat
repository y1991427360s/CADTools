@echo off
chcp 936 >nul 2>&1
setlocal EnableDelayedExpansion

echo ============================================================
echo   YS-Tools v1.3 Uninstaller
echo   AutoCAD 2018 + ZWCAD 2026
echo ============================================================
echo.

set "REMOVED=0"

set "ACAD_SUPPORT=%APPDATA%\Autodesk\AutoCAD 2018\R22.0\chs\Support"
echo [1/3] Checking AutoCAD support directory...
if exist "%ACAD_SUPPORT%\YS-Tools" (
    rmdir /S /Q "%ACAD_SUPPORT%\YS-Tools"
    echo   Removed: %ACAD_SUPPORT%\YS-Tools
    set "REMOVED=1"
) else (
    echo   AutoCAD YS-Tools directory was not found.
)

set "ZWCAD_SUPPORT=%APPDATA%\ZWSOFT\ZWCAD\2026\zh-CN\Support"
echo.
echo [2/3] Checking ZWCAD support directory...
if exist "%ZWCAD_SUPPORT%\YS-Tools" (
    rmdir /S /Q "%ZWCAD_SUPPORT%\YS-Tools"
    echo   Removed: %ZWCAD_SUPPORT%\YS-Tools
    set "REMOVED=1"
) else (
    for /d %%d in ("%APPDATA%\ZWSOFT\ZWCAD\*") do (
        if exist "%%d\Support\YS-Tools" (
            rmdir /S /Q "%%d\Support\YS-Tools"
            echo   Removed: %%d\Support\YS-Tools
            set "REMOVED=1"
        )
        if exist "%%d\zh-CN\Support\YS-Tools" (
            rmdir /S /Q "%%d\zh-CN\Support\YS-Tools"
            echo   Removed: %%d\zh-CN\Support\YS-Tools
            set "REMOVED=1"
        )
    )
)
if "%REMOVED%"=="0" echo   ZWCAD YS-Tools directory was not found.

echo.
echo [3/3] Result...
if "%REMOVED%"=="1" (
    echo ============================================================
    echo   YS-Tools v1.3 was removed.
    echo   Please restart AutoCAD or ZWCAD.
    echo   Note: acaddoc.lsp may still contain startup entries.
    echo ============================================================
) else (
    echo ============================================================
    echo   No YS-Tools installation was found.
    echo ============================================================
)

echo.
pause
