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

title Image Conversion - ImageMagick

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
echo                    IMAGE CONVERTER
echo                    ImageMagick
echo ============================================================
echo.
echo "Input : %INPUT%"
echo "Output: %OUTPUT%"
echo.
echo Select output format:
echo.
echo [1] JPG
echo [2] PNG
echo [3] WebP
echo [4] TIFF
echo [5] BMP
echo [6] GIF
echo [7] AVIF
echo [Q] Quit
echo.

choice /C 1234567Q /N /M "Select an option: "

if errorlevel 8 exit /b 0
if errorlevel 7 (set "FORMAT=avif" & goto SETTINGS)
if errorlevel 6 (set "FORMAT=gif"  & goto SETTINGS)
if errorlevel 5 (set "FORMAT=bmp"  & goto SETTINGS)
if errorlevel 4 (set "FORMAT=tiff" & goto SETTINGS)
if errorlevel 3 (set "FORMAT=webp" & goto SETTINGS)
if errorlevel 2 (set "FORMAT=png"  & goto SETTINGS)
if errorlevel 1 (set "FORMAT=jpg"  & goto SETTINGS)

:: ============================================================
:: FORMAT SETTINGS
:: ============================================================

:SETTINGS

set "QUALITY=85"

if /I "%FORMAT%"=="jpg" (
    echo.
    set /P "QUALITY=JPG quality (1-100) [85]: "
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Validate.ps1" -Variable QUALITY
if errorlevel 1 exit /b 2
    if not defined QUALITY set "QUALITY=85"
)

if /I "%FORMAT%"=="webp" (
    echo.
    set /P "QUALITY=WebP quality (1-100) [85]: "
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Validate.ps1" -Variable QUALITY
if errorlevel 1 exit /b 2
    if not defined QUALITY set "QUALITY=85"
)

if /I "%FORMAT%"=="avif" (
    echo.
    set /P "QUALITY=AVIF quality (1-100) [85]: "
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Validate.ps1" -Variable QUALITY
if errorlevel 1 exit /b 2
    if not defined QUALITY set "QUALITY=85"
)

:: ============================================================
:: CONFIRM
:: ============================================================

:CONFIRM

cls
echo ============================================================
echo                    IMAGE CONVERTER
echo ============================================================
echo.
echo Input format : JPG / JPEG / PNG / WEBP / TIFF / BMP / GIF / AVIF
echo "Output format: %FORMAT%"
echo.

if /I "%FORMAT%"=="jpg" echo Quality: %QUALITY%
if /I "%FORMAT%"=="webp" echo Quality: %QUALITY%
if /I "%FORMAT%"=="avif" echo Quality: %QUALITY%

echo.
echo Output folder:
echo "%OUTPUT%"
echo.
choice /C YN /N /M "Start conversion? [Y/N]: "

if errorlevel 2 goto MENU

:: ============================================================
:: START CONVERSION
:: ============================================================

:START_CONVERSION
goto TB_PROCESS

:TB_PROCESS
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\ToolRunner.ps1" -Tool "Image Convert" -ToolDir "%~dp0."
goto TB_FINISH
:TB_DEFAULTS
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\ToolRunner.ps1" -Tool "Image Convert" -ToolDir "%~dp0." -Defaults
:TB_FINISH
set "TB_EXIT=%errorlevel%"
if not defined TB_NO_PAUSE pause
exit /b %TB_EXIT%
:TB_CHECK
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Check.ps1" -Name magick
exit /b %errorlevel%
