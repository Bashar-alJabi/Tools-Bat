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


title Image Crop

:: ============================================================
:: CONFIGURATION
:: ============================================================

set "INPUT=%~dp0Input"
set "OUTPUT=%~dp0Output"

:: ============================================================
:: CHECK IMAGEMAGICK
:: ============================================================

"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Check.ps1" -Name magick
if errorlevel 1 exit /b 3
:: ============================================================
:: CREATE FOLDERS
:: ============================================================

if not exist "%INPUT%" mkdir "%INPUT%"
if not exist "%OUTPUT%" mkdir "%OUTPUT%"

:: ============================================================
:: MENU
:: ============================================================

:MENU

cls

echo ============================================================
echo                       IMAGE CROP
echo ============================================================
echo.
echo "Input : %INPUT%"
echo "Output: %OUTPUT%"
echo.
echo Select crop ratio:
echo.
echo [1] 1:1   - Square
echo [2] 4:5   - Portrait
echo [3] 16:9  - Landscape
echo [4] 9:16  - Vertical
echo [Q] Quit
echo.

set "CHOICE="
set /p "CHOICE=Enter choice: "
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Validate.ps1" -Variable CHOICE
if errorlevel 1 exit /b 2

if /i "%CHOICE%"=="1" (
    set "RATIO=1:1"
    set "WIDTH=1"
    set "HEIGHT=1"
    goto CONFIRM
)

if /i "%CHOICE%"=="2" (
    set "RATIO=4:5"
    set "WIDTH=4"
    set "HEIGHT=5"
    goto CONFIRM
)

if /i "%CHOICE%"=="3" (
    set "RATIO=16:9"
    set "WIDTH=16"
    set "HEIGHT=9"
    goto CONFIRM
)

if /i "%CHOICE%"=="4" (
    set "RATIO=9:16"
    set "WIDTH=9"
    set "HEIGHT=16"
    goto CONFIRM
)

if /i "%CHOICE%"=="Q" exit /b 0

echo.
echo Invalid choice.
pause
goto MENU

:: ============================================================
:: CONFIRM
:: ============================================================

:CONFIRM

cls

echo ============================================================
echo                       IMAGE CROP
echo ============================================================
echo.
echo "Crop Ratio: %RATIO%"
echo.
echo The image will be cropped from the center.
echo The original aspect ratio will not be stretched.
echo.
echo "Input : %INPUT%"
echo "Output: %OUTPUT%"
echo.

set "CONFIRM="
set /p "CONFIRM=Start cropping? [Y/N]: "
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Validate.ps1" -Variable CONFIRM
if errorlevel 1 exit /b 2

if /i not "%CONFIRM%"=="Y" goto MENU

:: ============================================================
:: PROCESS FILES
:: ============================================================

goto TB_PROCESS

:TB_PROCESS
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\ToolRunner.ps1" -Tool "Image Crop" -ToolDir "%~dp0."
goto TB_FINISH
:TB_DEFAULTS
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\ToolRunner.ps1" -Tool "Image Crop" -ToolDir "%~dp0." -Defaults
:TB_FINISH
set "TB_EXIT=%errorlevel%"
if not defined TB_NO_PAUSE pause
exit /b %TB_EXIT%
:TB_CHECK
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Check.ps1" -Name magick
exit /b %errorlevel%
