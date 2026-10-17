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

title Video Speed

:: ============================================================
:: Video Speed
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
:: Speed Selection
:: ------------------------------------------------------------

:MENU
cls
echo.
echo ============================================================
echo                       VIDEO SPEED
echo ============================================================
echo.
echo  1. 0.5x   - Half Speed
echo  2. 0.75x  - Slower
echo  3. 1.25x  - Slightly Faster
echo  4. 1.5x   - Faster
echo  5. 2x     - Double Speed
echo.

set "CHOICE="
set /p "CHOICE=Select speed [1-5]: "
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Validate.ps1" -Variable CHOICE
if errorlevel 1 exit /b 2

if "%CHOICE%"=="1" (
    set "SPEED=0.5"
    set "LABEL=0.5x"
    set "ATEMPO=0.5"
    goto START
)

if "%CHOICE%"=="2" (
    set "SPEED=0.75"
    set "LABEL=0.75x"
    set "ATEMPO=0.75"
    goto START
)

if "%CHOICE%"=="3" (
    set "SPEED=1.25"
    set "LABEL=1.25x"
    set "ATEMPO=1.25"
    goto START
)

if "%CHOICE%"=="4" (
    set "SPEED=1.5"
    set "LABEL=1.5x"
    set "ATEMPO=1.5"
    goto START
)

if "%CHOICE%"=="5" (
    set "SPEED=2"
    set "LABEL=2x"
    set "ATEMPO=2"
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
echo                       VIDEO SPEED
echo ============================================================
echo.
echo "Target Speed:    %LABEL%"
echo Audio:           AAC
echo Pitch:           Preserved
echo Resolution:      Preserved
echo Output Format:   MP4
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
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\ToolRunner.ps1" -Tool "Video Speed" -ToolDir "%~dp0."
goto TB_FINISH
:TB_DEFAULTS
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\ToolRunner.ps1" -Tool "Video Speed" -ToolDir "%~dp0." -Defaults
:TB_FINISH
set "TB_EXIT=%errorlevel%"
if not defined TB_NO_PAUSE pause
exit /b %TB_EXIT%
:TB_CHECK
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Check.ps1" -Name ffmpeg
exit /b %errorlevel%
