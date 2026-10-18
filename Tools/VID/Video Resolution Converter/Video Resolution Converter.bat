@echo off
setlocal EnableExtensions DisableDelayedExpansion
set "TB_PS=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
set "TB_SHARED=%~dp0..\..\..\System\Shared"
if not exist "%TB_PS%" exit /b 3
if /i "%~1"=="--help" (
    echo Put files in this tool's Input folder. Results are saved in Output.
    echo --check: dependency check. --defaults: process with documented defaults.
    exit /b 0
)
if /i "%~1"=="--check" goto TB_CHECK
if /i "%~1"=="--defaults" goto TB_DEFAULTS

title Video Resolution Converter

:: ============================================================
:: Video Resolution Converter
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

if not exist "%OUTPUT%" mkdir "%OUTPUT%"

:: ------------------------------------------------------------
:: Resolution Menu
:: ------------------------------------------------------------

:MENU
cls
echo.
echo ============================================================
echo              VIDEO RESOLUTION CONVERTER
echo ============================================================
echo.
echo  1. 4K       - 3840 x 2160
echo  2. 1080p    - 1920 x 1080
echo  3. 720p     - 1280 x 720
echo  4. 480p     - 854 x 480
echo.
set "CHOICE="
set /p "CHOICE=Select resolution [1-4]: "
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Validate.ps1" -Variable CHOICE
if errorlevel 1 exit /b 2

if "%CHOICE%"=="1" (
    set "WIDTH=3840"
    set "HEIGHT=2160"
    set "LABEL=4K"
    goto START
)

if "%CHOICE%"=="2" (
    set "WIDTH=1920"
    set "HEIGHT=1080"
    set "LABEL=1080p"
    goto START
)

if "%CHOICE%"=="3" (
    set "WIDTH=1280"
    set "HEIGHT=720"
    set "LABEL=720p"
    goto START
)

if "%CHOICE%"=="4" (
    set "WIDTH=854"
    set "HEIGHT=480"
    set "LABEL=480p"
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
echo              VIDEO RESOLUTION CONVERTER
echo ============================================================
echo.
echo "Target Resolution: %LABEL% (up to %WIDTH%x%HEIGHT%)"
echo Aspect Ratio:      Preserved
echo FPS:               Preserved
echo Audio:             AAC
echo Scaling:           High Quality
echo Output Format:     MP4
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
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\ToolRunner.ps1" -Tool "Video Resolution Converter" -ToolDir "%~dp0."
goto TB_FINISH
:TB_DEFAULTS
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\ToolRunner.ps1" -Tool "Video Resolution Converter" -ToolDir "%~dp0." -Defaults
:TB_FINISH
set "TB_EXIT=%errorlevel%"
if not defined TB_NO_PAUSE pause
exit /b %TB_EXIT%
:TB_CHECK
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Check.ps1" -Name ffmpeg
exit /b %errorlevel%
