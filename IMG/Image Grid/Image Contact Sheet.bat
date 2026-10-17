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

title Image Contact Sheet - ImageMagick

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
:: MENU
:: ============================================================

:MENU

cls
echo ============================================================
echo                    IMAGE CONTACT SHEET
echo                    ImageMagick
echo ============================================================
echo.
echo "Input : %INPUT%"
echo "Output: %OUTPUT%"
echo.
echo Select number of columns:
echo.
echo [1] 3 Columns
echo [2] 4 Columns
echo [3] 5 Columns
echo [Q] Quit
echo.

choice /C 123Q /N /M "Select an option: "

if errorlevel 4 exit /b 0
if errorlevel 3 (set "COLUMNS=5" & goto CONFIRM)
if errorlevel 2 (set "COLUMNS=4" & goto CONFIRM)
if errorlevel 1 (set "COLUMNS=3" & goto CONFIRM)

:: ============================================================
:: CONFIRM
:: ============================================================

:CONFIRM

cls
echo ============================================================
echo                    IMAGE CONTACT SHEET
echo ============================================================
echo.
echo "Columns: %COLUMNS%"
echo.
echo Images will be arranged in a Grid.
echo File names will be displayed below each image.
echo.
echo Output:
echo "%OUTPUT%\contact-sheet.png"
echo.
choice /C YN /N /M "Create contact sheet? [Y/N]: "

if errorlevel 2 goto MENU

:: ============================================================
:: PREPARE FILE LIST
:: ============================================================

goto TB_PROCESS

:TB_PROCESS
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\ToolRunner.ps1" -Tool "Image Contact Sheet" -ToolDir "%~dp0."
goto TB_FINISH
:TB_DEFAULTS
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\ToolRunner.ps1" -Tool "Image Contact Sheet" -ToolDir "%~dp0." -Defaults
:TB_FINISH
set "TB_EXIT=%errorlevel%"
if not defined TB_NO_PAUSE pause
exit /b %TB_EXIT%
:TB_CHECK
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Check.ps1" -Name magick
exit /b %errorlevel%
