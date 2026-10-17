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

title Image Compression - ImageMagick

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
:: SETTINGS
:: ============================================================

:MENU

cls
echo ============================================================
echo                   IMAGE COMPRESSION
echo                   ImageMagick
echo ============================================================
echo.
echo "Input : %INPUT%"
echo "Output: %OUTPUT%"
echo.
echo Select compression quality:
echo.
echo [1] High Quality       - Quality 90
echo [2] Balanced           - Quality 85
echo [3] Smaller Size       - Quality 80
echo [4] More Compression   - Quality 70
echo [Q] Quit
echo.

choice /C 1234Q /N /M "Select an option: "

if errorlevel 5 exit /b 0
if errorlevel 4 (set "QUALITY=70" & set "MODE=More Compression" & goto CONFIRM)
if errorlevel 3 (set "QUALITY=80" & set "MODE=Smaller Size" & goto CONFIRM)
if errorlevel 2 (set "QUALITY=85" & set "MODE=Balanced" & goto CONFIRM)
if errorlevel 1 (set "QUALITY=90" & set "MODE=High Quality" & goto CONFIRM)

:: ============================================================
:: CONFIRM
:: ============================================================

:CONFIRM

cls
echo ============================================================
echo                   IMAGE COMPRESSION
echo ============================================================
echo.
echo "Compression mode: %MODE%"
echo "Quality          : %QUALITY%"
echo.
echo Input formats:
echo JPG / JPEG / PNG / WEBP / TIFF / AVIF
echo.
echo Output folder:
echo "%OUTPUT%"
echo.
choice /C YN /N /M "Start compression? [Y/N]: "

if errorlevel 2 goto MENU

:: ============================================================
:: START COMPRESSION
:: ============================================================

:START_COMPRESSION
goto TB_PROCESS

:TB_PROCESS
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\ToolRunner.ps1" -Tool "Image Compression" -ToolDir "%~dp0."
goto TB_FINISH
:TB_DEFAULTS
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\ToolRunner.ps1" -Tool "Image Compression" -ToolDir "%~dp0." -Defaults
:TB_FINISH
set "TB_EXIT=%errorlevel%"
if not defined TB_NO_PAUSE pause
exit /b %TB_EXIT%
:TB_CHECK
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Check.ps1" -Name magick
exit /b %errorlevel%
