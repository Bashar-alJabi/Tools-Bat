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

title Image Resize - ImageMagick

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
echo                      IMAGE RESIZE
echo                      ImageMagick
echo ============================================================
echo.
echo "Input : %INPUT%"
echo "Output: %OUTPUT%"
echo.
echo Select maximum dimensions:
echo.
echo [1] 1920 x 1080
echo [2] 1600 x 1600
echo [3] 1280 x 1280
echo [4] Custom dimensions
echo [Q] Quit
echo.

choice /C 1234Q /N /M "Select an option: "

if errorlevel 5 exit /b 0
if errorlevel 4 goto CUSTOM
if errorlevel 3 (set "WIDTH=1280" & set "HEIGHT=1280" & goto CONFIRM)
if errorlevel 2 (set "WIDTH=1600" & set "HEIGHT=1600" & goto CONFIRM)
if errorlevel 1 (set "WIDTH=1920" & set "HEIGHT=1080" & goto CONFIRM)

:: ============================================================
:: CUSTOM DIMENSIONS
:: ============================================================

:CUSTOM

echo.
set /P "WIDTH=Enter maximum width: "
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Validate.ps1" -Variable WIDTH
if errorlevel 1 exit /b 2
set /P "HEIGHT=Enter maximum height: "
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Validate.ps1" -Variable HEIGHT
if errorlevel 1 exit /b 2

if not defined WIDTH goto MENU
if not defined HEIGHT goto MENU

:: ============================================================
:: CONFIRM
:: ============================================================

:CONFIRM

cls
echo ============================================================
echo                      IMAGE RESIZE
echo ============================================================
echo.
echo "Maximum Width : %WIDTH% px"
echo "Maximum Height: %HEIGHT% px"
echo.
echo Aspect Ratio  : Preserved
echo Upscaling     : Disabled
echo.
echo Output folder:
echo "%OUTPUT%"
echo.
choice /C YN /N /M "Start resizing? [Y/N]: "

if errorlevel 2 goto MENU

:: ============================================================
:: START RESIZE
:: ============================================================

:START_RESIZE
goto TB_PROCESS

:TB_PROCESS
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\ToolRunner.ps1" -Tool "Image Resize" -ToolDir "%~dp0."
goto TB_FINISH
:TB_DEFAULTS
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\ToolRunner.ps1" -Tool "Image Resize" -ToolDir "%~dp0." -Defaults
:TB_FINISH
set "TB_EXIT=%errorlevel%"
if not defined TB_NO_PAUSE pause
exit /b %TB_EXIT%
:TB_CHECK
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Check.ps1" -Name magick
exit /b %errorlevel%
