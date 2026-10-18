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


title Video Compression - FFmpeg

echo.
echo ==================================================
echo              VIDEO COMPRESSION
echo ==================================================
echo.

:: ==================================================
:: Paths
:: ==================================================

set "BASE=%~dp0"
set "INPUT=%BASE%Input"
set "OUTPUT=%BASE%Output"

:: ==================================================
:: Check FFmpeg
:: ==================================================

"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Check.ps1" -Name ffmpeg
if errorlevel 1 exit /b 3
:: ==================================================
:: Check Input
:: ==================================================

if not exist "%INPUT%" (
    echo ERROR: Input folder was not found.
    echo.
    echo Expected:
    echo "%INPUT%"
    echo.
    pause
    exit /b 1
)

:: ==================================================
:: Create Output
:: ==================================================

if not exist "%OUTPUT%" mkdir "%OUTPUT%"

:: ==================================================
:: Check NVIDIA NVENC availability
:: ==================================================

set "USE_H264_NVENC=0"
set "USE_HEVC_NVENC=0"

:MENU

echo.
echo ==================================================
echo                COMPRESSION OPTIONS
echo ==================================================
echo.
echo [1] H.264 - Balanced
echo     Good quality + good compression
echo.
echo [2] H.264 - Smaller
echo     Stronger compression + smaller file
echo.
echo [3] H.264 - High Quality
echo     Higher quality + larger file
echo.
echo [4] H.265 / HEVC - Smaller
echo     Better compression + lower compatibility
echo.
echo [Q] Quit
echo.
echo ==================================================
echo.

set "CHOICE="
set /p "CHOICE=Select an option [1-4]: "
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Validate.ps1" -Variable CHOICE
if errorlevel 1 exit /b 2

if /I "%CHOICE%"=="Q" exit /b 0

if "%CHOICE%"=="1" goto OPTION_BALANCED
if "%CHOICE%"=="2" goto OPTION_SMALLER
if "%CHOICE%"=="3" goto OPTION_HIGH
if "%CHOICE%"=="4" goto OPTION_HEVC

echo.
echo Invalid option.
echo Please select 1, 2, 3, 4 or Q.
echo.
goto MENU


:: ==================================================
:: Option 1 - H.264 Balanced
:: ==================================================

:OPTION_BALANCED

set "MODE=H.264"
set "MODE_NAME=H.264 - Balanced"
set "CRF=23"
set "CQ=23"
set "AUDIO_BITRATE=128k"

goto CONFIRM


:: ==================================================
:: Option 2 - H.264 Smaller
:: ==================================================

:OPTION_SMALLER

set "MODE=H.264"
set "MODE_NAME=H.264 - Smaller"
set "CRF=26"
set "CQ=26"
set "AUDIO_BITRATE=128k"

goto CONFIRM


:: ==================================================
:: Option 3 - H.264 High Quality
:: ==================================================

:OPTION_HIGH

set "MODE=H.264"
set "MODE_NAME=H.264 - High Quality"
set "CRF=20"
set "CQ=20"
set "AUDIO_BITRATE=160k"

goto CONFIRM


:: ==================================================
:: Option 4 - H.265 / HEVC
:: ==================================================

:OPTION_HEVC

set "MODE=H.265"
set "MODE_NAME=H.265 / HEVC - Smaller"
set "CRF=26"
set "CQ=26"
set "AUDIO_BITRATE=128k"

goto CONFIRM


:: ==================================================
:: Confirmation
:: ==================================================

:CONFIRM

echo.
echo ==================================================
echo                  SELECTED MODE
echo ==================================================
echo.
echo Mode:
echo "   %MODE_NAME%"
echo.

if "%MODE%"=="H.264" (
    if "%USE_H264_NVENC%"=="1" (
        echo Encoder:
        echo    NVIDIA NVENC
        echo.
        echo Codec:
        echo    H.264 NVENC
        echo.
        echo Quality:
        echo "   CQ %CQ%"
        echo.
        echo Preset:
        echo    P5
    ) else (
        echo Encoder:
        echo    CPU
        echo.
        echo Codec:
        echo    H.264 x264
        echo.
        echo Quality:
        echo "   CRF %CRF%"
        echo.
        echo Preset:
        echo    Medium
    )
) else (
    if "%USE_HEVC_NVENC%"=="1" (
        echo Encoder:
        echo    NVIDIA NVENC
        echo.
        echo Codec:
        echo    H.265 / HEVC NVENC
        echo.
        echo Quality:
        echo "   CQ %CQ%"
        echo.
        echo Preset:
        echo    P5
    ) else (
        echo Encoder:
        echo    CPU
        echo.
        echo Codec:
        echo    H.265 / HEVC x265
        echo.
        echo Quality:
        echo "   CRF %CRF%"
        echo.
        echo Preset:
        echo    Medium
    )
)

echo.
echo Audio:
echo "   AAC %AUDIO_BITRATE%"
echo.
echo Output:
echo    MP4
echo.

set "CONFIRM="
set /p "CONFIRM=Start compression? [Y/N]: "
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Validate.ps1" -Variable CONFIRM
if errorlevel 1 exit /b 2

if /I "%CONFIRM%"=="Y" goto START_COMPRESSION
if /I "%CONFIRM%"=="N" goto MENU

echo.
echo Invalid option.
goto CONFIRM


:: ==================================================
:: Start Compression
:: ==================================================

:START_COMPRESSION
goto TB_PROCESS

:TB_PROCESS
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\ToolRunner.ps1" -Tool "Compress Video" -ToolDir "%~dp0."
goto TB_FINISH
:TB_DEFAULTS
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\ToolRunner.ps1" -Tool "Compress Video" -ToolDir "%~dp0." -Defaults
:TB_FINISH
set "TB_EXIT=%errorlevel%"
if not defined TB_NO_PAUSE pause
exit /b %TB_EXIT%
:TB_CHECK
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Check.ps1" -Name ffmpeg
exit /b %errorlevel%
