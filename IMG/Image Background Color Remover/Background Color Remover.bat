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


title Background Color Remover - ImageMagick

echo.
echo ==================================================
echo             BACKGROUND COLOR REMOVER
echo ==================================================
echo.

REM ==================================================
REM Paths
REM ==================================================

set "BASE=%~dp0"
set "INPUT=%BASE%Input"
set "OUTPUT=%BASE%Output"

REM ==================================================
REM Check ImageMagick
REM ==================================================

"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Check.ps1" -Name magick
if errorlevel 1 exit /b 3
REM ==================================================
REM Check Input
REM ==================================================

if not exist "%INPUT%" (
    echo ERROR: Input folder was not found.
    echo.
    echo Expected:
    echo "%INPUT%"
    echo.
    pause
    exit /b 1
)

REM ==================================================
REM Create Output
REM ==================================================

if not exist "%OUTPUT%" mkdir "%OUTPUT%"

REM ==================================================
REM Select Background Color
REM ==================================================

:COLOR_MENU

echo.
echo Select background color:
echo.
echo 1. White
echo 2. Black
echo 3. Custom Color
echo.

set "COLOR_CHOICE="
set /p "COLOR_CHOICE=Choose an option [1-3]: "
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Validate.ps1" -Variable COLOR_CHOICE
if errorlevel 1 exit /b 2

if "%COLOR_CHOICE%"=="1" (
    set "COLOR=white"
    goto FUZZ_MENU
)

if "%COLOR_CHOICE%"=="2" (
    set "COLOR=black"
    goto FUZZ_MENU
)

if "%COLOR_CHOICE%"=="3" (
    echo.
    set "COLOR="
    set /p "COLOR=Enter color (example: #00FF00): "
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Validate.ps1" -Variable COLOR
if errorlevel 1 exit /b 2

    if not defined COLOR (
        echo.
        echo ERROR: No color was entered.
        goto COLOR_MENU
    )

    goto FUZZ_MENU
)

echo.
echo Invalid choice.
goto COLOR_MENU

REM ==================================================
REM Select Fuzz
REM ==================================================

:FUZZ_MENU

echo.
echo Background color:
echo "   %COLOR%"
echo.
echo Select color tolerance:
echo.
echo "1. 5%%"
echo "2. 10%%"
echo "3. 20%%"
echo 4. Custom
echo.

set "FUZZ_CHOICE="
set /p "FUZZ_CHOICE=Choose an option [1-4]: "
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Validate.ps1" -Variable FUZZ_CHOICE
if errorlevel 1 exit /b 2

if "%FUZZ_CHOICE%"=="1" (
    set "FUZZ=5%%"
    goto PROCESS
)

if "%FUZZ_CHOICE%"=="2" (
    set "FUZZ=10%%"
    goto PROCESS
)

if "%FUZZ_CHOICE%"=="3" (
    set "FUZZ=20%%"
    goto PROCESS
)

if "%FUZZ_CHOICE%"=="4" (
    echo.
    set "FUZZ="
    set /p "FUZZ=Enter fuzz percentage (example: 12%%): "
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Validate.ps1" -Variable FUZZ
if errorlevel 1 exit /b 2

    if not defined FUZZ (
        echo.
        echo ERROR: No fuzz value was entered.
        goto FUZZ_MENU
    )

    goto PROCESS
)

echo.
echo Invalid choice.
goto FUZZ_MENU

REM ==================================================
REM Count Images
REM ==================================================

:PROCESS
goto TB_PROCESS

:TB_PROCESS
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\ToolRunner.ps1" -Tool "Background Color Remover" -ToolDir "%~dp0."
goto TB_FINISH
:TB_DEFAULTS
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\ToolRunner.ps1" -Tool "Background Color Remover" -ToolDir "%~dp0." -Defaults
:TB_FINISH
set "TB_EXIT=%errorlevel%"
if not defined TB_NO_PAUSE pause
exit /b %TB_EXIT%
:TB_CHECK
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Check.ps1" -Name magick
exit /b %errorlevel%
