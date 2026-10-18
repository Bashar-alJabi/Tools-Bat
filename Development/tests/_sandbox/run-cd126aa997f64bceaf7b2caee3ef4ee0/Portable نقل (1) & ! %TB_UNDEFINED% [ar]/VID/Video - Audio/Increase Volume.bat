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


title Increase Volume - FFmpeg

:: ============================================================
:: Increase Video Audio Volume using FFmpeg
::
:: Input files  : .\Input
:: Output files : .\Output
:: Video        : No re-encoding
:: Audio        : AAC 192k
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
:: Count input files
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
:: Volume menu
:: ------------------------------------------------------------

:MENU

cls

echo.
echo ============================================================
echo                    INCREASE VOLUME
echo ============================================================
echo.
echo "Found %FOUND% video(s)."
echo.
echo Select volume increase:
echo.
echo [1] +3 dB
echo     Slight increase
echo.
echo [2] +6 dB
echo     Clear increase
echo.
echo [3] +9 dB
echo     Strong increase
echo.
echo [4] +12 dB
echo     Very strong increase
echo.
echo [Q] Quit
echo.

choice /c 1234Q /n /m "Select an option: "

if errorlevel 5 goto QUIT
if errorlevel 4 (set "VOLUME=12dB" & set "VOLUME_LABEL=+12 dB" & set "VOLUME_DESC=Very strong increase" & goto CONFIRM)
if errorlevel 3 (set "VOLUME=9dB" & set "VOLUME_LABEL=+9 dB" & set "VOLUME_DESC=Strong increase" & goto CONFIRM)
if errorlevel 2 (set "VOLUME=6dB" & set "VOLUME_LABEL=+6 dB" & set "VOLUME_DESC=Clear increase" & goto CONFIRM)
if errorlevel 1 (set "VOLUME=3dB" & set "VOLUME_LABEL=+3 dB" & set "VOLUME_DESC=Slight increase" & goto CONFIRM)

goto MENU


:: ------------------------------------------------------------
:: Confirmation
:: ------------------------------------------------------------

:CONFIRM

cls

echo.
echo ============================================================
echo                    CONFIRM SETTINGS
echo ============================================================
echo.

echo Volume increase:
echo "   %VOLUME_LABEL%"
echo.

echo Description:
echo "   %VOLUME_DESC%"
echo.

echo Video:
echo    Copy - No re-encoding
echo.

echo Audio:
echo    AAC 192k
echo.

echo Input:
echo "   %INPUT_DIR%"
echo.

echo Output:
echo "   %OUTPUT_DIR%"
echo.

echo WARNING:
echo    Increasing volume may cause clipping or distortion
echo    if the original audio is already close to its maximum.
echo.

choice /c YN /n /m "Continue? [Y/N]: "

if errorlevel 2 goto MENU
if errorlevel 1 goto PROCESS

goto MENU


:: ------------------------------------------------------------
:: Processing
:: ------------------------------------------------------------

:PROCESS
goto TB_PROCESS

:TB_PROCESS
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\ToolRunner.ps1" -Tool "Increase Volume" -ToolDir "%~dp0."
goto TB_FINISH
:TB_DEFAULTS
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\ToolRunner.ps1" -Tool "Increase Volume" -ToolDir "%~dp0." -Defaults
:TB_FINISH
set "TB_EXIT=%errorlevel%"
if not defined TB_NO_PAUSE pause
exit /b %TB_EXIT%
:TB_CHECK
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Check.ps1" -Name ffmpeg
exit /b %errorlevel%
