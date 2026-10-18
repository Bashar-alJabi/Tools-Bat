@echo off
setlocal EnableExtensions DisableDelayedExpansion
set "TB_PS=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
set "TB_SHARED=%~dp0..\..\_shared"
if not exist "%TB_PS%" exit /b 3
if /i "%~1"=="--help" (
    echo Put files in this tool's Input folder. Results are saved in Output.
    echo --check: dependency check. --defaults: process with documented defaults.
    exit /b 0
)
if /i "%~1"=="--check" goto TB_CHECK
if /i "%~1"=="--defaults" goto TB_DEFAULTS

title Video FPS Converter

:: ============================================================
:: Video FPS Converter
:: ============================================================

set "BASE=%~dp0"
set "INPUT=%BASE%Input"
set "OUTPUT=%BASE%Output"

:: ------------------------------------------------------------
:: Check FFmpeg
:: ------------------------------------------------------------

"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Check.ps1" -Name ffmpeg
if errorlevel 1 exit /b 3
:: ------------------------------------------------------------
:: Check Input folder
:: ------------------------------------------------------------

if not exist "%INPUT%" (
    echo.
    echo [ERROR] Input folder not found:
    echo "%INPUT%"
    echo.
    pause
    exit /b 1
)

:: ------------------------------------------------------------
:: Create Output folder
:: ------------------------------------------------------------

if not exist "%OUTPUT%" mkdir "%OUTPUT%"

:: ------------------------------------------------------------
:: FPS Selection
:: ------------------------------------------------------------

:MENU
cls
echo.
echo ============================================================
echo                   VIDEO FPS CONVERTER
echo ============================================================
echo.
echo  1. 24 FPS
echo  2. 25 FPS
echo  3. 30 FPS
echo  4. 50 FPS
echo  5. 60 FPS
echo.

set "CHOICE="
set /p "CHOICE=Select FPS [1-5]: "
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Validate.ps1" -Variable CHOICE
if errorlevel 1 exit /b 2

if "%CHOICE%"=="1" (
    set "FPS=24"
    goto START
)

if "%CHOICE%"=="2" (
    set "FPS=25"
    goto START
)

if "%CHOICE%"=="3" (
    set "FPS=30"
    goto START
)

if "%CHOICE%"=="4" (
    set "FPS=50"
    goto START
)

if "%CHOICE%"=="5" (
    set "FPS=60"
    goto START
)

echo.
echo [ERROR] Invalid selection.
timeout /t 2 >nul
goto MENU

:: ------------------------------------------------------------
:: Start Processing
:: ------------------------------------------------------------

:START
cls
echo.
echo ============================================================
echo                   VIDEO FPS CONVERTER
echo ============================================================
echo.
echo "Target FPS:     %FPS%"
echo Audio:          AAC
echo Resolution:     Preserved
echo Output Format:  MP4
echo.
echo Input:
echo "%INPUT%"
echo.
echo Output:
echo "%OUTPUT%"
echo.
echo ============================================================
echo.

goto TB_PROCESS

:TB_PROCESS
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\ToolRunner.ps1" -Tool "Video FPS Converter" -ToolDir "%~dp0."
goto TB_FINISH
:TB_DEFAULTS
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\ToolRunner.ps1" -Tool "Video FPS Converter" -ToolDir "%~dp0." -Defaults
:TB_FINISH
set "TB_EXIT=%errorlevel%"
if not defined TB_NO_PAUSE pause
exit /b %TB_EXIT%
:TB_CHECK
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Check.ps1" -Name ffmpeg
exit /b %errorlevel%
