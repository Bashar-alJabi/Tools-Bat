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


title Merge Audio - FFmpeg

:: ============================================================
:: Merge Audio with Video using FFmpeg
::
:: Input files  : .\Input
:: Output files : .\Output
::
:: Put:
::     1 Video file
::     1 Audio file
::
:: The original video audio is kept and mixed
:: with the added audio.
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

set "OUTPUT_FILE=%OUTPUT_DIR%\merged.mp4"


:: ------------------------------------------------------------
:: Volume menu
:: ------------------------------------------------------------

:MENU

cls

echo.
echo ============================================================
echo                     MERGE AUDIO
echo ============================================================
echo.

echo Video:
echo "%VIDEO%"
echo.

echo Added audio:
echo "%AUDIO%"
echo.

echo Select volume for the added audio:
echo.

echo [1] Low
echo     Lower volume for the added audio
echo.
echo [2] Medium
echo     Balanced volume for the added audio
echo.
echo [3] High
echo     Higher volume for the added audio
echo.
echo [Q] Quit
echo.

choice /c 123Q /n /m "Select an option: "

if errorlevel 4 goto QUIT
if errorlevel 3 (
    set "AUDIO_VOLUME=0.75"
    set "VOLUME_LABEL=High"
    set "VOLUME_PERCENT=75%%"
    goto CONFIRM
)

if errorlevel 2 (
    set "AUDIO_VOLUME=0.50"
    set "VOLUME_LABEL=Medium"
    set "VOLUME_PERCENT=50%%"
    goto CONFIRM
)

if errorlevel 1 (
    set "AUDIO_VOLUME=0.25"
    set "VOLUME_LABEL=Low"
    set "VOLUME_PERCENT=25%%"
    goto CONFIRM
)

goto MENU


:: ------------------------------------------------------------
:: Confirmation
:: ------------------------------------------------------------

:CONFIRM

cls

echo.
echo ============================================================
echo                  CONFIRM SETTINGS
echo ============================================================
echo.

echo Video:
echo "%VIDEO%"
echo.

echo Original audio:
echo Kept
echo.

echo Added audio:
echo "%AUDIO%"
echo.

echo Added audio volume:
echo "%VOLUME_LABEL%"
echo "Volume: %VOLUME_PERCENT%"
echo.

echo Video:
echo Copy - No re-encoding
echo.

echo Audio:
echo AAC 192k
echo.

echo Output:
echo "%OUTPUT_FILE%"
echo.

echo ------------------------------------------------------------
echo.

choice /c YN /n /m "Continue? [Y/N]: "

if errorlevel 2 goto MENU
if errorlevel 1 goto PROCESS

goto MENU


:: ------------------------------------------------------------
:: Check existing output
:: ------------------------------------------------------------

:PROCESS
goto TB_PROCESS

:TB_PROCESS
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\ToolRunner.ps1" -Tool "Merge Audio" -ToolDir "%~dp0."
goto TB_FINISH
:TB_DEFAULTS
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\ToolRunner.ps1" -Tool "Merge Audio" -ToolDir "%~dp0." -Defaults
:TB_FINISH
set "TB_EXIT=%errorlevel%"
if not defined TB_NO_PAUSE pause
exit /b %TB_EXIT%
:TB_CHECK
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Check.ps1" -Name ffmpeg
exit /b %errorlevel%
