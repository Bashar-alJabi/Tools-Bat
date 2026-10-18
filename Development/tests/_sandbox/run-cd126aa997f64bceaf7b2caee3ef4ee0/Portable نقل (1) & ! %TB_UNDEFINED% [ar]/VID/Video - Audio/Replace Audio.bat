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


title Replace Audio - FFmpeg

:: ============================================================
:: Replace Audio in Video using FFmpeg
::
:: Input files  : .\Input
:: Output files : .\Output
::
:: Put:
::     1 Video file
::     1 Audio file
::
:: The original video audio is removed and replaced
:: with the new audio file.
:: ============================================================


:: ------------------------------------------------------------
:: Set folders
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
:: Find video
:: ------------------------------------------------------------

set "VIDEO="

for %%F in (
    "%INPUT_DIR%\*.mp4"
    "%INPUT_DIR%\*.mov"
    "%INPUT_DIR%\*.mkv"
    "%INPUT_DIR%\*.avi"
    "%INPUT_DIR%\*.m4v"
    "%INPUT_DIR%\*.webm"
) do (
    if exist "%%~F" if not defined VIDEO set "VIDEO=%%~F"
)


:: ------------------------------------------------------------
:: Find audio
:: ------------------------------------------------------------

set "AUDIO="

for %%F in (
    "%INPUT_DIR%\*.mp3"
    "%INPUT_DIR%\*.wav"
    "%INPUT_DIR%\*.m4a"
    "%INPUT_DIR%\*.aac"
    "%INPUT_DIR%\*.flac"
    "%INPUT_DIR%\*.ogg"
) do (
    if exist "%%~F" if not defined AUDIO set "AUDIO=%%~F"
)


:: ------------------------------------------------------------
:: Check files
:: ------------------------------------------------------------

if not defined VIDEO (
    echo.
    echo ERROR: No video file was found in:
    echo "%INPUT_DIR%"
    echo.
    pause
    exit /b 1
)

if not defined AUDIO (
    echo.
    echo ERROR: No audio file was found in:
    echo "%INPUT_DIR%"
    echo.
    pause
    exit /b 1
)


:: ------------------------------------------------------------
:: Set output file
:: ------------------------------------------------------------

goto TB_PROCESS

:TB_PROCESS
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\ToolRunner.ps1" -Tool "Replace Audio" -ToolDir "%~dp0."
goto TB_FINISH
:TB_DEFAULTS
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\ToolRunner.ps1" -Tool "Replace Audio" -ToolDir "%~dp0." -Defaults
:TB_FINISH
set "TB_EXIT=%errorlevel%"
if not defined TB_NO_PAUSE pause
exit /b %TB_EXIT%
:TB_CHECK
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Check.ps1" -Name ffmpeg
exit /b %errorlevel%
