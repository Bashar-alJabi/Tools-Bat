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


title Normalize Audio - FFmpeg

:: ============================================================
:: Normalize Video Audio using FFmpeg
::
:: Input files  : .\Input
:: Output files : .\Output
::
:: Video        : No re-encoding
:: Audio        : AAC 192k
:: Filter       : loudnorm
:: ============================================================


:: ------------------------------------------------------------
:: Set folders relative to this BAT file
:: ------------------------------------------------------------

set "SCRIPT_DIR=%~dp0"
set "INPUT_DIR=%SCRIPT_DIR%Input"
set "OUTPUT_DIR=%SCRIPT_DIR%Output"


:: ------------------------------------------------------------
:: Check FFmpeg
:: ------------------------------------------------------------

"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Check.ps1" -Name ffmpeg
if errorlevel 1 exit /b 3
:: ------------------------------------------------------------
:: Check Input folder
:: ------------------------------------------------------------

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

if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"


:: ------------------------------------------------------------
:: Count supported files
:: ------------------------------------------------------------

set /a FOUND=0

for %%F in (
    "%INPUT_DIR%\*.mp4"
    "%INPUT_DIR%\*.mov"
    "%INPUT_DIR%\*.mkv"
    "%INPUT_DIR%\*.avi"
    "%INPUT_DIR%\*.m4v"
    "%INPUT_DIR%\*.webm"
) do (
    if exist "%%~F" set /a FOUND+=1
)


:: ------------------------------------------------------------
:: No files found
:: ------------------------------------------------------------

if %FOUND% EQU 0 (
    echo.
    echo No supported video files were found in:
    echo "%INPUT_DIR%"
    echo.
    pause
    exit /b 0
)


:: ------------------------------------------------------------
:: Display settings
:: ------------------------------------------------------------

echo.
echo ============================================================
echo                   NORMALIZE AUDIO
echo ============================================================
echo.
echo Input:
echo "%INPUT_DIR%"
echo.
echo Output:
echo "%OUTPUT_DIR%"
echo.
echo Audio:
echo AAC 192k
echo.
echo Normalization:
echo loudnorm
echo.
echo Video:
echo Copy - No re-encoding
echo.
echo "Found %FOUND% video(s)."
echo.
echo ============================================================
echo                     PROCESSING
echo ============================================================
echo.


:: ------------------------------------------------------------
:: Counters
:: ------------------------------------------------------------

goto TB_PROCESS

:TB_PROCESS
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\ToolRunner.ps1" -Tool "Normalize Audio" -ToolDir "%~dp0."
goto TB_FINISH
:TB_DEFAULTS
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\ToolRunner.ps1" -Tool "Normalize Audio" -ToolDir "%~dp0." -Defaults
:TB_FINISH
set "TB_EXIT=%errorlevel%"
if not defined TB_NO_PAUSE pause
exit /b %TB_EXIT%
:TB_CHECK
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Check.ps1" -Name ffmpeg
exit /b %errorlevel%
