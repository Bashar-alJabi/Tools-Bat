@echo off
setlocal EnableExtensions DisableDelayedExpansion
title PDF To Images
:: Local processing lives beside this BAT; only safe I/O and dependency lookup are shared.
set "TB_PS=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
set "TB_MODE=Interactive"
if /i "%~1"=="--defaults" set "TB_MODE=Defaults"
if /i "%~1"=="--check" set "TB_MODE=Check"
if /i "%~1"=="--help" set "TB_MODE=Help"
if not exist "%TB_PS%" exit /b 3
"%TB_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0PDF To Images.ps1" -Mode "%TB_MODE%"
set "TB_EXIT=%errorlevel%"
if not defined TB_NO_PAUSE pause
exit /b %TB_EXIT%
