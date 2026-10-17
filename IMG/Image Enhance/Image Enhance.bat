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


title Image Enhance

set "INPUT=%~dp0Input"
set "OUTPUT=%~dp0Output"

"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Check.ps1" -Name magick
if errorlevel 1 exit /b 3
if not exist "%INPUT%" mkdir "%INPUT%"
if not exist "%OUTPUT%" mkdir "%OUTPUT%"

:MENU
cls
echo ============================================================
echo                     IMAGE ENHANCE
echo ============================================================
echo.
echo "Input : %INPUT%"
echo "Output: %OUTPUT%"
echo.
echo Select enhancement level:
echo.
echo [1] Light
echo [2] Medium
echo [3] Strong
echo [Q] Quit
echo.

set "CHOICE="
set /p "CHOICE=Enter choice: "
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Validate.ps1" -Variable CHOICE
if errorlevel 1 exit /b 2

if "%CHOICE%"=="1" (
    set "LEVEL=Light"
    set "SHARPEN=0x0.8+0.8+0.03"
    goto CONFIRM
)

if "%CHOICE%"=="2" (
    set "LEVEL=Medium"
    set "SHARPEN=0x1.2+1+0.05"
    goto CONFIRM
)

if "%CHOICE%"=="3" (
    set "LEVEL=Strong"
    set "SHARPEN=0x1.6+1+0.08"
    goto CONFIRM
)

if /i "%CHOICE%"=="Q" exit /b 0

echo.
echo Invalid choice.
pause
goto MENU


:CONFIRM
cls
echo ============================================================
echo                    ENHANCEMENT SETTINGS
echo ============================================================
echo.
echo "Level : %LEVEL%"
echo "Scale : 200%%"
echo.
echo Processing:
echo "  - Upscale image to 200%%"
echo   - Lanczos resize filter
echo   - Sharpen details
echo.
echo "Input : %INPUT%"
echo "Output: %OUTPUT%"
echo.

set "START="
set /p "START=Start enhancement? [Y/N]: "
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Validate.ps1" -Variable START
if errorlevel 1 exit /b 2

if /i not "%START%"=="Y" goto MENU

goto PROCESS


:PROCESS
goto TB_PROCESS

:TB_PROCESS
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\ToolRunner.ps1" -Tool "Image Enhance" -ToolDir "%~dp0."
goto TB_FINISH
:TB_DEFAULTS
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\ToolRunner.ps1" -Tool "Image Enhance" -ToolDir "%~dp0." -Defaults
:TB_FINISH
set "TB_EXIT=%errorlevel%"
if not defined TB_NO_PAUSE pause
exit /b %TB_EXIT%
:TB_CHECK
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Check.ps1" -Name magick
exit /b %errorlevel%
