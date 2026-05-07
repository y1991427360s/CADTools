@echo off
chcp 936 >nul 2>&1
setlocal EnableDelayedExpansion

echo ============================================================
echo   YS-Tools v1.3 - §Ø??
echo ============================================================
echo.

set "UNINSTALL_OK=0"

:: ---- ???? AutoCAD ----
echo [1/3] ???? AutoCAD ???...
set "ACAD_SUPPORT=D:\Autodesk\CAD2018\AutoCAD 2018\Support"
if exist "%ACAD_SUPPORT%\YS-Tools" (
    rmdir /S /Q "%ACAD_SUPPORT%\YS-Tools"
    echo   ?????: %ACAD_SUPPORT%\YS-Tools
    set "UNINSTALL_OK=1"
) else (
    echo   ¦Ä??? AutoCAD ???????
)

:: ---- ???? ZWCAD ----
echo.
echo [2/3] ???? ZWCAD ???...
set "ZWCAD_SUPPORT=%APPDATA%\ZWSOFT\ZWCAD\2026\zh-CN\Support"
if exist "%ZWCAD_SUPPORT%\YS-Tools" (
    rmdir /S /Q "%ZWCAD_SUPPORT%\YS-Tools"
    echo   ?????: %ZWCAD_SUPPORT%\YS-Tools
    set "UNINSTALL_OK=1"
) else (
    :: ????????????·Ú
    for /d %%d in ("%APPDATA%\ZWSOFT\ZWCAD\*") do (
        if exist "%%d\Support\YS-Tools" (
            rmdir /S /Q "%%d\Support\YS-Tools"
            echo   ?????: %%d\Support\YS-Tools
            set "UNINSTALL_OK=1"
        )
        if exist "%%d\zh-CN\Support\YS-Tools" (
            rmdir /S /Q "%%d\zh-CN\Support\YS-Tools"
            echo   ?????: %%d\zh-CN\Support\YS-Tools
            set "UNINSTALL_OK=1"
        )
    )
    if "!UNINSTALL_OK!"=="0" (
        echo   ¦Ä??? ZWCAD ???????
    )
)

:: ---- ??? ----
echo.
echo [3/3] §Ø????...
if "%UNINSTALL_OK%"=="1" (
    echo ============================================================
    echo   YS-Tools v1.3 ??§Ø???
    echo   ?????????? AutoCAD/ZWCAD ???????????
    echo   ???: acaddoc.lsp ?§Ö?????????????????
    echo ============================================================
) else (
    echo ============================================================
    echo   ¦Ä????????? YS-Tools??
    echo ============================================================
)

echo.
pause
