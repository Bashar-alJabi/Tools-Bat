@echo off
setlocal EnableExtensions DisableDelayedExpansion
title tOOls Bat - Start Here
set "TB_PS=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if not exist "%TB_PS%" (
    echo [ERROR] Windows PowerShell 5.1 is required.
    pause
    exit /b 3
)
if /i "%~1"=="--check" goto CHECK
if /i "%~1"=="--portable" goto PORTABLE
if /i "%~1"=="--help" (
    echo START_HERE checks all tools and offers verified downloads for missing programs.
    echo --check: check only. --portable: offer local copies of installed distributions.
    echo See START_HERE.md for offline setup, licenses and manual Ghostscript steps.
    exit /b 0
)
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0_shared\Setup.ps1"
goto FINISH
:PORTABLE
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0_shared\Setup.ps1" -MakePortable
goto FINISH
:CHECK
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0_shared\Setup.ps1" -CheckOnly
:FINISH
set "TB_EXIT=%errorlevel%"
if not defined TB_NO_PAUSE pause
exit /b %TB_EXIT%
