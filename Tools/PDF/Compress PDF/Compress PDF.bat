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


title PDF Compression - Ghostscript

:: ============================================================
:: Compress PDF files using Ghostscript
:: Input files : .\Input
:: Output files: .\Output
:: ============================================================

set "SCRIPT_DIR=%~dp0"
set "INPUT_DIR=%SCRIPT_DIR%Input"
set "OUTPUT_DIR=%SCRIPT_DIR%Output"

:: Check if Ghostscript is installed
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Check.ps1" -Name ghostscript
if errorlevel 1 exit /b 3
:: Check if Input folder exists
if not exist "%INPUT_DIR%" (
    echo.
    echo ERROR: Input folder was not found.
    echo.
    echo Expected:
    echo "%INPUT_DIR%"
    echo.
    pause
    exit /b 1
)

:: Create Output folder if it does not exist
if not exist "%OUTPUT_DIR%" (
    mkdir "%OUTPUT_DIR%"
)

:: ============================================================
:: Select compression preset
:: ============================================================

:MENU

cls
echo.
echo ============================================================
echo                    PDF COMPRESSION
echo ============================================================
echo.
echo Select compression level:
echo.
echo [1] Screen
echo     Smallest file size - Lower quality
echo.
echo [2] Ebook
echo     Best balance between size and quality
echo.
echo [3] Printer
echo     Higher quality - Suitable for printing
echo.
echo [4] Prepress
echo     Highest quality - Professional printing
echo.
echo [5] Default
echo     General purpose
echo.
echo ============================================================
echo.

set "CHOICE="
set /p "CHOICE=Enter your choice [1-5]: "
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Validate.ps1" -Variable CHOICE
if errorlevel 1 exit /b 2

if "%CHOICE%"=="1" (
    set "PRESET=/screen"
    set "PRESET_NAME=Screen"
    set "PRESET_DESCRIPTION=Smallest file size - Lower quality"
    goto CONFIRM
)

if "%CHOICE%"=="2" (
    set "PRESET=/ebook"
    set "PRESET_NAME=Ebook"
    set "PRESET_DESCRIPTION=Best balance between size and quality"
    goto CONFIRM
)

if "%CHOICE%"=="3" (
    set "PRESET=/printer"
    set "PRESET_NAME=Printer"
    set "PRESET_DESCRIPTION=Higher quality - Suitable for printing"
    goto CONFIRM
)

if "%CHOICE%"=="4" (
    set "PRESET=/prepress"
    set "PRESET_NAME=Prepress"
    set "PRESET_DESCRIPTION=Highest quality - Professional printing"
    goto CONFIRM
)

if "%CHOICE%"=="5" (
    set "PRESET=/default"
    set "PRESET_NAME=Default"
    set "PRESET_DESCRIPTION=General purpose"
    goto CONFIRM
)

echo.
echo Invalid choice. Please select a number from 1 to 5.
timeout /t 2 >nul
goto MENU


:: ============================================================
:: Confirm selected preset
:: ============================================================

:CONFIRM

cls
echo.
echo ============================================================
echo                    PDF COMPRESSION
echo ============================================================
echo.
echo Selected:
echo "%PRESET_NAME% - %PRESET_DESCRIPTION%"
echo.
echo "Ghostscript preset: %PRESET%"
echo.
echo "Input : %INPUT_DIR%"
echo "Output: %OUTPUT_DIR%"
echo.
echo ============================================================
echo.
choice /c YN /n /m "Continue? [Y/N]: "

if errorlevel 2 goto MENU
if errorlevel 1 goto PROCESS


:: ============================================================
:: Process PDF files
:: ============================================================

:PROCESS
goto TB_PROCESS

:TB_PROCESS
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\ToolRunner.ps1" -Tool "Compress PDF" -ToolDir "%~dp0."
goto TB_FINISH
:TB_DEFAULTS
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\ToolRunner.ps1" -Tool "Compress PDF" -ToolDir "%~dp0." -Defaults
:TB_FINISH
set "TB_EXIT=%errorlevel%"
if not defined TB_NO_PAUSE pause
exit /b %TB_EXIT%
:TB_CHECK
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Check.ps1" -Name ghostscript
exit /b %errorlevel%
