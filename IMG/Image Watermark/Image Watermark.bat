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


title Image Watermark

set "INPUT=%~dp0Input"
set "OUTPUT=%~dp0Output"
set "WATERMARK_FOLDER=%~dp0Watermark"

"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Check.ps1" -Name magick
if errorlevel 1 exit /b 3
if not exist "%INPUT%" mkdir "%INPUT%"
if not exist "%OUTPUT%" mkdir "%OUTPUT%"
if not exist "%WATERMARK_FOLDER%" mkdir "%WATERMARK_FOLDER%"

:MENU
cls
echo ============================================================
echo                    IMAGE WATERMARK
echo ============================================================
echo.
echo "Input : %INPUT%"
echo "Output: %OUTPUT%"
echo.
echo Select watermark type:
echo.
echo [1] Text Watermark
echo [2] Logo Watermark
echo [Q] Quit
echo.

set "TYPE="
set /p "TYPE=Enter choice: "
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Validate.ps1" -Variable TYPE
if errorlevel 1 exit /b 2

if "%TYPE%"=="1" goto TEXT_SETUP
if "%TYPE%"=="2" goto LOGO_SETUP
if /i "%TYPE%"=="Q" exit /b 0

echo.
echo Invalid choice.
pause
goto MENU


:TEXT_SETUP
cls
echo ============================================================
echo                    TEXT WATERMARK
echo ============================================================
echo.

set "WATERMARK_TEXT="
set /p "WATERMARK_TEXT=Enter watermark text: "
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Validate.ps1" -Variable WATERMARK_TEXT
if errorlevel 1 exit /b 2

if not defined WATERMARK_TEXT (
    echo.
    echo Text cannot be empty.
    pause
    goto MENU
)

goto COMMON_SETUP


:LOGO_SETUP
cls
echo ============================================================
echo                    LOGO WATERMARK
echo ============================================================
echo.

set "LOGO="
set /a LOGO_COUNT=0

for %%F in (
    "%WATERMARK_FOLDER%\*.png"
    "%WATERMARK_FOLDER%\*.jpg"
    "%WATERMARK_FOLDER%\*.jpeg"
    "%WATERMARK_FOLDER%\*.webp"
    "%WATERMARK_FOLDER%\*.tif"
    "%WATERMARK_FOLDER%\*.tiff"
    "%WATERMARK_FOLDER%\*.bmp"
    "%WATERMARK_FOLDER%\*.gif"
    "%WATERMARK_FOLDER%\*.avif"
) do (
    if exist "%%~fF" (
        set /a LOGO_COUNT+=1
        set "LOGO=%%~fF"
    )
)

if %LOGO_COUNT% EQU 0 (
    echo No watermark image was found.
    echo.
    echo Place ONE image inside:
    echo.
    echo "%WATERMARK_FOLDER%"
    echo.
    echo The filename does not matter.
    echo.
    pause
    goto MENU
)

if %LOGO_COUNT% GTR 1 (
    echo Multiple watermark images were found.
    echo.
    echo Please keep only ONE image inside:
    echo.
    echo "%WATERMARK_FOLDER%"
    echo.
    pause
    goto MENU
)

echo Watermark image:
echo "%LOGO%"
echo.

goto COMMON_SETUP


:COMMON_SETUP
cls
echo ============================================================
echo                 WATERMARK COUNT
echo ============================================================
echo.
echo [1] One Watermark
echo [2] Two Watermarks
echo [3] Three Watermarks
echo [4] Four Watermarks
echo [5] Five Watermarks
echo [6] Six Watermarks
echo [7] Seven Watermarks
echo [8] Eight Watermarks
echo [9] Nine Watermarks
echo.

set "COUNT="
set /p "COUNT=Enter choice: "
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Validate.ps1" -Variable COUNT
if errorlevel 1 exit /b 2

if "%COUNT%"=="1" goto POSITION_1
if "%COUNT%"=="2" goto POSITION_2
if "%COUNT%"=="3" goto POSITION_3
if "%COUNT%"=="4" goto POSITION_4
if "%COUNT%"=="5" goto POSITION_5
if "%COUNT%"=="6" goto POSITION_6
if "%COUNT%"=="7" goto POSITION_7
if "%COUNT%"=="8" goto POSITION_8
if "%COUNT%"=="9" goto POSITION_9

echo.
echo Invalid choice.
pause

if "%TYPE%"=="1" goto TEXT_SETUP
goto LOGO_SETUP


:POSITION_1
call :GET_POSITION 1
if errorlevel 1 goto COMMON_SETUP
goto ROTATION_SETUP


:POSITION_2
call :GET_POSITION 1
if errorlevel 1 goto COMMON_SETUP
call :GET_POSITION 2
if errorlevel 1 goto COMMON_SETUP
goto ROTATION_SETUP


:POSITION_3
call :GET_POSITION 1
if errorlevel 1 goto COMMON_SETUP
call :GET_POSITION 2
if errorlevel 1 goto COMMON_SETUP
call :GET_POSITION 3
if errorlevel 1 goto COMMON_SETUP
goto ROTATION_SETUP


:POSITION_4
call :GET_POSITION 1
if errorlevel 1 goto COMMON_SETUP
call :GET_POSITION 2
if errorlevel 1 goto COMMON_SETUP
call :GET_POSITION 3
if errorlevel 1 goto COMMON_SETUP
call :GET_POSITION 4
if errorlevel 1 goto COMMON_SETUP
goto ROTATION_SETUP


:POSITION_5
call :GET_POSITION 1
if errorlevel 1 goto COMMON_SETUP
call :GET_POSITION 2
if errorlevel 1 goto COMMON_SETUP
call :GET_POSITION 3
if errorlevel 1 goto COMMON_SETUP
call :GET_POSITION 4
if errorlevel 1 goto COMMON_SETUP
call :GET_POSITION 5
if errorlevel 1 goto COMMON_SETUP
goto ROTATION_SETUP


:POSITION_6
call :GET_POSITION 1
if errorlevel 1 goto COMMON_SETUP
call :GET_POSITION 2
if errorlevel 1 goto COMMON_SETUP
call :GET_POSITION 3
if errorlevel 1 goto COMMON_SETUP
call :GET_POSITION 4
if errorlevel 1 goto COMMON_SETUP
call :GET_POSITION 5
if errorlevel 1 goto COMMON_SETUP
call :GET_POSITION 6
if errorlevel 1 goto COMMON_SETUP
goto ROTATION_SETUP


:POSITION_7
call :GET_POSITION 1
if errorlevel 1 goto COMMON_SETUP
call :GET_POSITION 2
if errorlevel 1 goto COMMON_SETUP
call :GET_POSITION 3
if errorlevel 1 goto COMMON_SETUP
call :GET_POSITION 4
if errorlevel 1 goto COMMON_SETUP
call :GET_POSITION 5
if errorlevel 1 goto COMMON_SETUP
call :GET_POSITION 6
if errorlevel 1 goto COMMON_SETUP
call :GET_POSITION 7
if errorlevel 1 goto COMMON_SETUP
goto ROTATION_SETUP


:POSITION_8
call :GET_POSITION 1
if errorlevel 1 goto COMMON_SETUP
call :GET_POSITION 2
if errorlevel 1 goto COMMON_SETUP
call :GET_POSITION 3
if errorlevel 1 goto COMMON_SETUP
call :GET_POSITION 4
if errorlevel 1 goto COMMON_SETUP
call :GET_POSITION 5
if errorlevel 1 goto COMMON_SETUP
call :GET_POSITION 6
if errorlevel 1 goto COMMON_SETUP
call :GET_POSITION 7
if errorlevel 1 goto COMMON_SETUP
call :GET_POSITION 8
if errorlevel 1 goto COMMON_SETUP
goto ROTATION_SETUP


:POSITION_9
call :GET_POSITION 1
if errorlevel 1 goto COMMON_SETUP
call :GET_POSITION 2
if errorlevel 1 goto COMMON_SETUP
call :GET_POSITION 3
if errorlevel 1 goto COMMON_SETUP
call :GET_POSITION 4
if errorlevel 1 goto COMMON_SETUP
call :GET_POSITION 5
if errorlevel 1 goto COMMON_SETUP
call :GET_POSITION 6
if errorlevel 1 goto COMMON_SETUP
call :GET_POSITION 7
if errorlevel 1 goto COMMON_SETUP
call :GET_POSITION 8
if errorlevel 1 goto COMMON_SETUP
call :GET_POSITION 9
if errorlevel 1 goto COMMON_SETUP
goto ROTATION_SETUP


:GET_POSITION
set "POSITION="
set "SELECTED_GRAVITY="

echo.
echo ------------------------------------------------------------
echo "Watermark %1 Position"
echo ------------------------------------------------------------
echo.
echo [1] Top Left
echo [2] Top Center
echo [3] Top Right
echo [4] Center Left
echo [5] Center
echo [6] Center Right
echo [7] Bottom Left
echo [8] Bottom Center
echo [9] Bottom Right
echo.

set /p "POSITION=Enter choice: "
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Validate.ps1" -Variable POSITION
if errorlevel 1 exit /b 2

if "%POSITION%"=="1" set "SELECTED_GRAVITY=northwest"
if "%POSITION%"=="2" set "SELECTED_GRAVITY=north"
if "%POSITION%"=="3" set "SELECTED_GRAVITY=northeast"
if "%POSITION%"=="4" set "SELECTED_GRAVITY=west"
if "%POSITION%"=="5" set "SELECTED_GRAVITY=center"
if "%POSITION%"=="6" set "SELECTED_GRAVITY=east"
if "%POSITION%"=="7" set "SELECTED_GRAVITY=southwest"
if "%POSITION%"=="8" set "SELECTED_GRAVITY=south"
if "%POSITION%"=="9" set "SELECTED_GRAVITY=southeast"

if not defined SELECTED_GRAVITY (
    echo.
    echo Invalid position.
    pause
    exit /b 1
)

if "%1"=="1" set "GRAVITY1=%SELECTED_GRAVITY%"
if "%1"=="2" set "GRAVITY2=%SELECTED_GRAVITY%"
if "%1"=="3" set "GRAVITY3=%SELECTED_GRAVITY%"
if "%1"=="4" set "GRAVITY4=%SELECTED_GRAVITY%"
if "%1"=="5" set "GRAVITY5=%SELECTED_GRAVITY%"
if "%1"=="6" set "GRAVITY6=%SELECTED_GRAVITY%"
if "%1"=="7" set "GRAVITY7=%SELECTED_GRAVITY%"
if "%1"=="8" set "GRAVITY8=%SELECTED_GRAVITY%"
if "%1"=="9" set "GRAVITY9=%SELECTED_GRAVITY%"

exit /b 0


:ROTATION_SETUP
cls
echo ============================================================
echo                    WATERMARK ROTATION
echo ============================================================
echo.
echo [1] Normal
echo [2] Tilt Left  (-8 degrees)
echo [3] Tilt Right (+8 degrees)
echo.

set "ROTATION_CHOICE="
set /p "ROTATION_CHOICE=Enter choice: "
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Validate.ps1" -Variable ROTATION_CHOICE
if errorlevel 1 exit /b 2

set "ROTATION=0"

if "%ROTATION_CHOICE%"=="1" set "ROTATION=0"
if "%ROTATION_CHOICE%"=="2" set "ROTATION=-8"
if "%ROTATION_CHOICE%"=="3" set "ROTATION=8"

if not "%ROTATION_CHOICE%"=="1" if not "%ROTATION_CHOICE%"=="2" if not "%ROTATION_CHOICE%"=="3" (
    echo.
    echo Invalid choice.
    pause
    goto COMMON_SETUP
)

goto SIZE_SETUP


:SIZE_SETUP
cls
echo ============================================================
echo                    WATERMARK SIZE
echo ============================================================
echo.

if "%TYPE%"=="1" goto TEXT_SIZE_SETUP
goto LOGO_SIZE_SETUP


:TEXT_SIZE_SETUP
echo Text size:
echo.
echo [1] Small  - 36
echo [2] Medium - 64
echo [3] Large  - 96
echo [4] Custom
echo.

set "SIZE_CHOICE="
set /p "SIZE_CHOICE=Enter choice: "
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Validate.ps1" -Variable SIZE_CHOICE
if errorlevel 1 exit /b 2

set "SIZE="

if "%SIZE_CHOICE%"=="1" set "SIZE=36"
if "%SIZE_CHOICE%"=="2" set "SIZE=64"
if "%SIZE_CHOICE%"=="3" set "SIZE=96"

if "%SIZE_CHOICE%"=="4" (
    set /p "SIZE=Enter font size: "
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Validate.ps1" -Variable SIZE
if errorlevel 1 exit /b 2
)

if not defined SIZE (
    echo.
    echo Invalid size.
    pause
    goto SIZE_SETUP
)

goto OPACITY_SETUP


:LOGO_SIZE_SETUP
echo Logo size relative to image width:
echo.
echo "[1] Small  - 15%%"
echo "[2] Medium - 25%%"
echo "[3] Large  - 35%%"
echo [4] Custom
echo.

set "SIZE_CHOICE="
set /p "SIZE_CHOICE=Enter choice: "
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Validate.ps1" -Variable SIZE_CHOICE
if errorlevel 1 exit /b 2

set "SIZE="

if "%SIZE_CHOICE%"=="1" set "SIZE=15"
if "%SIZE_CHOICE%"=="2" set "SIZE=25"
if "%SIZE_CHOICE%"=="3" set "SIZE=35"

if "%SIZE_CHOICE%"=="4" (
    set /p "SIZE=Enter logo size percentage: "
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Validate.ps1" -Variable SIZE
if errorlevel 1 exit /b 2
)

if not defined SIZE (
    echo.
    echo Invalid size.
    pause
    goto SIZE_SETUP
)

goto OPACITY_SETUP


:OPACITY_SETUP
echo.
set "OPACITY="
set /p "OPACITY=Enter opacity (10-100, default 60): "
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Validate.ps1" -Variable OPACITY
if errorlevel 1 exit /b 2

if not defined OPACITY set "OPACITY=60"

goto CONFIRM


:CONFIRM
cls
echo ============================================================
echo                   WATERMARK SETTINGS
echo ============================================================
echo.

if "%TYPE%"=="1" (
    echo Type    : Text
    echo "Text    : %WATERMARK_TEXT%"
) else (
    echo Type    : Logo
    echo "Logo    : %LOGO%"
)

echo.
echo "Count   : %COUNT%"
echo "Rotation: %ROTATION% degrees"
echo "Size    : %SIZE%"
echo "Opacity : %OPACITY%%%"
echo.
echo Positions:
echo.
echo "Watermark 1: %GRAVITY1%"
if %COUNT% GEQ 2 echo Watermark 2: %GRAVITY2%
if %COUNT% GEQ 3 echo Watermark 3: %GRAVITY3%
if %COUNT% GEQ 4 echo Watermark 4: %GRAVITY4%
if %COUNT% GEQ 5 echo Watermark 5: %GRAVITY5%
if %COUNT% GEQ 6 echo Watermark 6: %GRAVITY6%
if %COUNT% GEQ 7 echo Watermark 7: %GRAVITY7%
if %COUNT% GEQ 8 echo Watermark 8: %GRAVITY8%
if %COUNT% GEQ 9 echo Watermark 9: %GRAVITY9%

echo.
echo "Input : %INPUT%"
echo "Output: %OUTPUT%"
echo.

set "CONFIRM="
set /p "CONFIRM=Start watermarking? [Y/N]: "
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Validate.ps1" -Variable CONFIRM
if errorlevel 1 exit /b 2

if /i not "%CONFIRM%"=="Y" goto MENU

goto PROCESS


:PROCESS
goto TB_PROCESS

:TB_PROCESS
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\ToolRunner.ps1" -Tool "Image Watermark" -ToolDir "%~dp0."
goto TB_FINISH
:TB_DEFAULTS
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\ToolRunner.ps1" -Tool "Image Watermark" -ToolDir "%~dp0." -Defaults
:TB_FINISH
set "TB_EXIT=%errorlevel%"
if not defined TB_NO_PAUSE pause
exit /b %TB_EXIT%
:TB_CHECK
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TB_SHARED%\Check.ps1" -Name magick
exit /b %errorlevel%
