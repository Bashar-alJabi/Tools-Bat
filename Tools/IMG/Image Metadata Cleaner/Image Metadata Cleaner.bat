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

title Image Metadata Cleaner - ImageMagick

set "BASE=%~dp0"
set "INPUT=%BASE%Input"
set "OUTPUT=%BASE%Output"

:: ============================================================
:: CHECK IMAGEMAGICK
:: ============================================================

"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Check.ps1" -Name magick
if errorlevel 1 exit /b 3
:: ============================================================
:: CHECK INPUT
:: ============================================================

if not exist "%INPUT%" (
    echo.
    echo [ERROR] Input folder was not found:
    echo "%INPUT%"
    echo.
    mkdir "%INPUT%" >nul 2>&1
    echo Input folder has been created.
    echo Add your images and run the tool again.
    echo.
    pause
    exit /b 1
)

if not exist "%OUTPUT%" mkdir "%OUTPUT%"

:: ============================================================
:: CONFIRM
:: ============================================================

:CONFIRM

cls
echo ============================================================
echo                 IMAGE METADATA CLEANER
echo                     ImageMagick
echo ============================================================
echo.
echo "Input : %INPUT%"
echo "Output: %OUTPUT%"
echo.
echo This tool removes image metadata such as:
echo.
echo - EXIF
echo - GPS / Location
echo - Camera information
echo - Date / Time metadata
echo - Software / Editing information
echo - Author / Copyright metadata
echo - Comments and other removable metadata
echo.
echo Image dimensions and visual content are preserved.
echo.
choice /C YN /N /M "Start metadata cleaning? [Y/N]: "

if errorlevel 2 exit /b 0

:: ============================================================
:: START CLEANING
:: ============================================================

:START_CLEANING
goto TB_PROCESS

:TB_PROCESS
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\ToolRunner.ps1" -Tool "Image Metadata Cleaner" -ToolDir "%~dp0."
goto TB_FINISH
:TB_DEFAULTS
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\ToolRunner.ps1" -Tool "Image Metadata Cleaner" -ToolDir "%~dp0." -Defaults
:TB_FINISH
set "TB_EXIT=%errorlevel%"
if not defined TB_NO_PAUSE pause
exit /b %TB_EXIT%
:TB_CHECK
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Check.ps1" -Name magick
exit /b %errorlevel%
