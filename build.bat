@echo off
setlocal
cd /d %~dp0

REM Step 1: NSIS paths
set "SYSTEM_NSIS=C:\Program Files (x86)\NSIS\makensis.exe"
set "LOCAL_NSIS=%~dp0build_tools\NSIS\makensis.exe"

REM Step 2: Select NSIS compiler
if exist "%SYSTEM_NSIS%" (
    set "MAKENSIS=%SYSTEM_NSIS%"
    echo Using system NSIS compiler: %MAKENSIS%
) else if exist "%LOCAL_NSIS%" (
    set "MAKENSIS=%LOCAL_NSIS%"
    echo Using local NSIS compiler: %MAKENSIS%
) else (
    echo [ERROR] No NSIS compiler found!
    echo Please install NSIS system-wide or place makensis.exe in build_tools\NSIS.
    pause
    exit /b 1
)

REM Step 3: Clean Flutter build
echo Cleaning Flutter build...
call flutter clean
if %errorlevel% neq 0 (
    echo Flutter clean failed!
    pause
    exit /b
)

REM Step 4: Build Flutter Windows app
echo Building Flutter Windows app...
call flutter build windows --release
if %errorlevel% neq 0 (
    echo Flutter build failed!
    pause
    exit /b
)

REM Step 5: Prepare output folder
set "OUTPUT_DIR=%~dp0dist"
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

REM Step 6: Read Flutter version from pubspec.yaml
set "PUBSPEC=%~dp0pubspec.yaml"
for /f "tokens=2 delims=: " %%A in ('findstr "^version:" "%PUBSPEC%"') do set VERSION=%%A
set "VERSION=%VERSION: =%"
set "VERSION=%VERSION:+=-%"
set "FILENAME_VERSION=-%VERSION%"
echo TKubectl version: %VERSION%

REM Step 7: Generate NSIS installer
"%MAKENSIS%" /DVERSION="%FILENAME_VERSION%" "%~dp0installer.nsi"
if %errorlevel% neq 0 (
    echo NSIS build failed!
    pause
    exit /b
)

echo Done! Installer created at %OUTPUT_DIR%\TKubectl%FILENAME_VERSION%.exe
pause
