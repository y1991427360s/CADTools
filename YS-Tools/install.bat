@echo off
chcp 936 >nul 2>&1
setlocal EnableDelayedExpansion
echo ============================================================
echo   YS-Tools v1.3 Installer
echo   AutoCAD 2018 + ZWCAD 2026
echo ============================================================
echo.
set "SRC_DIR=%~dp0"
for %%I in ("%SRC_DIR%..") do set "PROJECT_DIR=%%~fI\"
set "INSTALL_OK=0"
echo [1/4] Detecting AutoCAD...
set "ACAD_SUPPORT="
if exist "%APPDATA%\Autodesk\AutoCAD 2018\R22.0\chs\Support\" (
    set "ACAD_SUPPORT=%APPDATA%\Autodesk\AutoCAD 2018\R22.0\chs\Support\"
    echo   AutoCAD user support found.
)
if exist "D:\Autodesk\CAD2018\AutoCAD 2018\Support\" (
    if not defined ACAD_SUPPORT set "ACAD_SUPPORT=D:\Autodesk\CAD2018\AutoCAD 2018\Support\"
    echo   AutoCAD program support found.
)
if not defined ACAD_SUPPORT echo   AutoCAD not found.
echo.
echo [2/4] Detecting ZWCAD...
set "ZWCAD_SUPPORT="
if exist "%APPDATA%\ZWSOFT\ZWCAD\2026\zh-CN\Support\" (
    set "ZWCAD_SUPPORT=%APPDATA%\ZWSOFT\ZWCAD\2026\zh-CN\Support\"
    echo   ZWCAD 2026 found.
) else (
    for /d %%d in ("%APPDATA%\ZWSOFT\ZWCAD\*") do (
        if exist "%%d\zh-CN\Support\" (
            set "ZWCAD_SUPPORT=%%d\zh-CN\Support\"
            echo   ZWCAD found: %%d
        )
    )
)
if not defined ZWCAD_SUPPORT echo   ZWCAD not found.
echo.
echo [3/4] Installing files...
if defined ACAD_SUPPORT (
    echo   Installing to AutoCAD...
    if not exist "!ACAD_SUPPORT!YS-Tools" mkdir "!ACAD_SUPPORT!YS-Tools"
    copy /Y "%SRC_DIR%YS-Tools.lsp" "!ACAD_SUPPORT!YS-Tools\" >nul
    copy /Y "%SRC_DIR%config.lsp" "!ACAD_SUPPORT!YS-Tools\" >nul
    copy /Y "%SRC_DIR%utils.lsp" "!ACAD_SUPPORT!YS-Tools\" >nul
    if not exist "!ACAD_SUPPORT!YS-Tools\modules" mkdir "!ACAD_SUPPORT!YS-Tools\modules"
    copy /Y "%SRC_DIR%modules\*.lsp" "!ACAD_SUPPORT!YS-Tools\modules\" >nul
    if not exist "!ACAD_SUPPORT!YS-Tools\dcl" mkdir "!ACAD_SUPPORT!YS-Tools\dcl"
    copy /Y "%SRC_DIR%dcl\*.*" "!ACAD_SUPPORT!YS-Tools\dcl\" >nul
    if exist "%PROJECT_DIR%AA整合版本.lsp" copy /Y "%PROJECT_DIR%AA整合版本.lsp" "!ACAD_SUPPORT!" >nul
    if not exist "!ACAD_SUPPORT!小命令" mkdir "!ACAD_SUPPORT!小命令"
    if exist "%PROJECT_DIR%小命令\*.lsp" copy /Y "%PROJECT_DIR%小命令\*.lsp" "!ACAD_SUPPORT!小命令\" >nul
    if exist "%PROJECT_DIR%小命令\*.LSP" copy /Y "%PROJECT_DIR%小命令\*.LSP" "!ACAD_SUPPORT!小命令\" >nul
    echo   AutoCAD files copied.
    set "INSTALL_OK=1"
    echo   Updating acaddoc.lsp...
    copy /Y "%SRC_DIR%acad.lsp" "!ACAD_SUPPORT!acad.lsp" >nul
    findstr /C:"YS-Tools" "!ACAD_SUPPORT!acaddoc.lsp" >nul 2>&1
    if errorlevel 1 (
        type "%SRC_DIR%ys-acaddoc-snippet.lsp" >> "!ACAD_SUPPORT!acaddoc.lsp"
        echo   acaddoc.lsp updated.
    ) else (
        echo   acaddoc.lsp already configured.
    )
)
if defined ZWCAD_SUPPORT (
    echo   Installing to ZWCAD...
    if not exist "!ZWCAD_SUPPORT!YS-Tools" mkdir "!ZWCAD_SUPPORT!YS-Tools"
    copy /Y "%SRC_DIR%YS-Tools.lsp" "!ZWCAD_SUPPORT!YS-Tools\" >nul
    copy /Y "%SRC_DIR%config.lsp" "!ZWCAD_SUPPORT!YS-Tools\" >nul
    copy /Y "%SRC_DIR%utils.lsp" "!ZWCAD_SUPPORT!YS-Tools\" >nul
    if not exist "!ZWCAD_SUPPORT!YS-Tools\modules" mkdir "!ZWCAD_SUPPORT!YS-Tools\modules"
    copy /Y "%SRC_DIR%modules\*.lsp" "!ZWCAD_SUPPORT!YS-Tools\modules\" >nul
    if not exist "!ZWCAD_SUPPORT!YS-Tools\dcl" mkdir "!ZWCAD_SUPPORT!YS-Tools\dcl"
    copy /Y "%SRC_DIR%dcl\*.*" "!ZWCAD_SUPPORT!YS-Tools\dcl\" >nul
    if exist "%PROJECT_DIR%AA整合版本.lsp" copy /Y "%PROJECT_DIR%AA整合版本.lsp" "!ZWCAD_SUPPORT!" >nul
    if not exist "!ZWCAD_SUPPORT!小命令" mkdir "!ZWCAD_SUPPORT!小命令"
    if exist "%PROJECT_DIR%小命令\*.lsp" copy /Y "%PROJECT_DIR%小命令\*.lsp" "!ZWCAD_SUPPORT!小命令\" >nul
    if exist "%PROJECT_DIR%小命令\*.LSP" copy /Y "%PROJECT_DIR%小命令\*.LSP" "!ZWCAD_SUPPORT!小命令\" >nul
    echo   ZWCAD files copied.
    set "INSTALL_OK=1"
    echo   Updating acaddoc.lsp...
    copy /Y "%SRC_DIR%acad.lsp" "!ZWCAD_SUPPORT!acad.lsp" >nul
    if not exist "!ZWCAD_SUPPORT!acaddoc.lsp" type nul > "!ZWCAD_SUPPORT!acaddoc.lsp"
    findstr /C:"YS-Tools" "!ZWCAD_SUPPORT!acaddoc.lsp" >nul 2>&1
    if errorlevel 1 (
        type "%SRC_DIR%ys-acaddoc-snippet.lsp" >> "!ZWCAD_SUPPORT!acaddoc.lsp"
        echo   acaddoc.lsp updated.
    ) else (
        echo   acaddoc.lsp already configured.
    )
    set "ZWCAD_APPLOAD=%APPDATA%\ZWSOFT\ZWCAD\2026\zh-CN\appload.dfs"
    if exist "!ZWCAD_APPLOAD!" (
        echo   Checking appload.dfs...
        findstr /C:"YS-Tools.lsp" "!ZWCAD_APPLOAD!" >nul 2>&1
        if errorlevel 1 (
            echo   appload.dfs unchanged; acaddoc.lsp handles auto-load.
        ) else (
            echo   appload.dfs already references YS-Tools.
        )
    ) else (
        echo   appload.dfs not found; acaddoc.lsp handles auto-load.
    )
)
echo.
echo [4/4] Result...
if "!INSTALL_OK!"=="1" (
    echo ============================================================
    echo   YS-Tools v1.3 installed successfully!
    echo.
    echo   Usage:
    echo     1. Restart AutoCAD or ZWCAD
    echo     2. Type YS or YSOOLS to open toolbar
    echo ============================================================
) else (
    echo ============================================================
    echo   WARNING: No CAD software detected.
    echo   Please install manually.
    echo ============================================================
)
echo.
pause
